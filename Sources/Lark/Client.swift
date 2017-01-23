import Alamofire
import Foundation

//TODO:- client documentation
open class Client {

    /// URL of the server to send the HTTP messages.
    open let endpoint: URL

    /// `Alamofire.SessionManager` that manages the the underlying `URLSession`.
    open let sessionManager: SessionManager

    /// SOAP headers that will be added on every outgoing `Envelope` (message).
    open var headers: [HeaderSerializable] = []

    /// Instantiates a `Client`.
    ///
    /// - Parameters:
    ///   - endpoint: URL of the server to send the HTTP messages.
    ///   - sessionManager: an `Alamofire.SessionManager` that manages the
    ///     the underlying `URLSession`.
    public init(
        endpoint: URL,
        sessionManager: SessionManager = SessionManager())
    {
        self.endpoint = endpoint
        self.sessionManager = sessionManager
    }


    /// Synchronously call a method on the server.
    ///
    /// - Parameters:
    ///   - action: name of the action to call.
    ///   - serialize: closure that will be called to serialize the request parameters.
    ///   - deserialize: closure that will be called to deserialize the reponse message.
    /// - Returns: the server's response.
    /// - Throws: errors that might occur when serializing, deserializing or in
    ///   the communication with the server. Also it might throw a `Fault` if the
    ///   server was unable to process the request.
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

    /// Asynchronously call a method on the server.
    ///
    /// - Parameters:
    ///   - action: name of the action to call.
    ///   - serialize: closure that will be called to serialize the request parameters.
    ///   - deserialize: closure that will be called to deserialize the reponse message.
    ///   - completionHandler: closure that will be called when a response has
    ///     been received and deserialized. If an error occurs, the closure will
    ///     be called with a `Result.failure(Error)` value.
    /// - Returns: an `Alamofire.DataRequest` instance for chaining additional
    ///   response handlers and to facilitate logging.
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

    /// Perform the request and validate the response.
    ///
    /// - Parameters:
    ///   - action: name of the action to call.
    ///   - serialize: closure that will be called to serialize the request parameters.
    /// - Returns: an `Alamofire.DataRequest` instance on which a deserializer 
    ///   can be chained.
    func request(
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
