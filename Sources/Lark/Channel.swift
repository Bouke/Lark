import Foundation
import Evergreen

open class Channel {
    open let transport: Transport
    open let logger = Evergreen.getLogger("Lark.Channel")

    public init(transport: Transport) {
        self.transport = transport
    }

    open func send(action: URL, request: Envelope, completionHandler: @escaping (Result<Envelope>) -> Void) {
        logger.debug("Sending request: \(request.document.xmlString)")
        transport.send(action: action, message: request.document.xmlData) { result in
            do {
                do {
                    let response = try result.resolve()
                    let doc = try XMLDocument(data: response, options: 0)
                    self.logger.debug("Received response: \(doc.xmlString)")
                    completionHandler(.success(Envelope(document: doc)))
                } catch HTTPTransportError.notOk(let (_, response)) {
                    let document = try XMLDocument(data: response, options: 0)
                    let envelope = Envelope(document: document)
                    let faultNode = envelope.body.elements(forLocalName: "Fault", uri: NS_SOAP).first!
                    let fault = try Fault(deserialize: faultNode)
                    completionHandler(.failure(fault))
                }
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
