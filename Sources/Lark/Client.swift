import Alamofire
import Foundation
import Evergreen

open class Client {
    open let endpoint: URL

    public init(endpoint: URL) {
        self.endpoint = endpoint
    }

    public func call<T>(
        action: URL,
        serialize: (Envelope) throws -> Envelope,
        deserialize: @escaping (Envelope) throws -> T)
        -> Request<T>
    {
        let originalEnvelope = Envelope()
        // TODO: append soap headers
        do {
            let envelope = try serialize(originalEnvelope)

            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.addValue(action.absoluteString, forHTTPHeaderField: "SOAPAction")
            request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")

            let body = envelope.document.xmlData
            request.httpBody = body
            request.addValue("\(body.count)", forHTTPHeaderField: "Content-Length")

            return Request(
                request: Alamofire.request(request),
                responseDeserializer: { try deserialize($0) })
        } catch {
            fatalError("TODO: return failed Request")
        }
    }
}
