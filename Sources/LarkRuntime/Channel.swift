import Foundation
import Evergreen

open class Channel {
    open let transport: Transport
    open let logger = Evergreen.getLogger("Lark.Channel")

    public init(transport: Transport) {
        self.transport = transport
    }

    func send(action: URL, request: Envelope) throws -> Envelope {
        let serialized = request.serialize()
        logger.debug("Sending request: \(serialized.xmlString)")
        let response: Data
        do {
            response = try transport.send(action: action, message: serialized.xmlData)
        } catch HTTPTransportError.notOk(let (_, response)) {
            let document = try XMLDocument(data: response, options: 0)
            let envelope = Envelope(deserialize: document)
            let faultNode = envelope.body.elements(forLocalName: "Fault", uri: NS_SOAP).first!
            let fault = try Fault(deserialize: faultNode)
            throw fault
        }
        let doc = try! XMLDocument(data: response, options: 0)
        logger.debug("Received response: \(doc.xmlString)")
        return Envelope(deserialize: doc)
    }
}
