import Alamofire
import Foundation


open class Client {
    open let endpoint: URL
    open let sessionManager: SessionManager
    open var headers: [HeaderSerializable] = []

    public init(
        endpoint: URL,
        sessionManager: SessionManager = SessionManager())
    {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
    }
    
    open func call<T>(
        action: URL,
        serialize: @escaping (Envelope) throws -> Envelope,
        deserialize: @escaping (Envelope) throws -> T)
        throws -> T
    {
        let semaphore = DispatchSemaphore(value: 0)
        var response: DataResponse<T>!
        request(action: action, serialize: serialize).responseSOAP(queue: DispatchQueue.global(qos: .default)) {
            response = DataResponse(
                request: $0.request,
                response: $0.response,
                data: $0.data,
                result: $0.result.map { try deserialize($0) },
                timeline: $0.timeline)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .distantFuture)
        return try response.result.resolve()
    }

    open func callAsync<T>(
        action: URL,
        serialize: @escaping (Envelope) throws -> Envelope,
        deserialize: @escaping (Envelope) throws -> T,
        completionHandler: @escaping (Result<T>) -> Void)
        -> DataRequest
    {
        return request(action: action, serialize: serialize).responseSOAP {
            do {
                completionHandler(.success(try deserialize($0.result.resolve())))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    open func request(
        action: URL,
        serialize: @escaping (Envelope) throws -> Envelope)
        -> DataRequest
    {
        let call = Call(
            endpoint: endpoint,
            action: action,
            serialize: serialize,
            headers: headers)
        return sessionManager.request(call)
            .validate(contentType: ["text/xml"])
            .validate(statusCode: [200, 500])
            .validateSOAP()
    }
}


struct Call: URLRequestConvertible {
    let endpoint: URL
    let action: URL
    let serialize: (Envelope) throws -> Envelope
    let headers: [HeaderSerializable]

    func asURLRequest() throws -> URLRequest {
        let envelope = try serialize(Envelope())

        for header in headers {
            envelope.header.addChild(try header.serialize())
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue(action.absoluteString, forHTTPHeaderField: "SOAPAction")
        request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let body = envelope.document.xmlData
        request.httpBody = body
        request.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")

        return request
    }
}


extension DataRequest {
    @discardableResult
    func responseSOAP(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (_ response: DataResponse<Envelope>) -> Void)
        -> Self
    {
        return response(queue: queue, responseSerializer: EnvelopeDeserializer(), completionHandler: completionHandler)
    }
}
