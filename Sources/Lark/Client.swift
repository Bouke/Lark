import Alamofire
import Foundation
import Evergreen

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
    
    open func callAsync<T>(
        action: URL,
        serialize: (Envelope) throws -> Envelope,
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
        serialize: (Envelope) throws -> Envelope)
        -> DataRequest
    {
        let originalEnvelope = Envelope()
        do {
            for header in headers {
                originalEnvelope.header.addChild(try header.serialize())
            }
            
            let envelope = try serialize(originalEnvelope)
            
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.addValue(action.absoluteString, forHTTPHeaderField: "SOAPAction")
            request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            let body = envelope.document.xmlData
            request.httpBody = body
            request.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")
            
            return sessionManager.request(request)
                .validate(contentType: ["text/xml"])
                .validate(statusCode: 200...200) // todo: write custom validator for SoapFault
        } catch {
            // todo: move into custom serializer
            fatalError("TODO: return failed Request")
        }
    }
}
