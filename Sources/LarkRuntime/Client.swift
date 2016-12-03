import Foundation
import Evergreen

var logger = Evergreen.getLogger("Lark")

open class Client {
    var channel = Channel()

    public init() {
    }

    public func send(parameters: [XMLElement], output: (XMLElement) throws -> ()) throws {
        let request = Envelope()
        for parameter in parameters {
            request.body.addChild(parameter)
        }
        try channel.send(request: request, response: { try output($0.body) })
    }
}

public class Channel {
    let transport = HTTPTransport()

    func send(request: Envelope, response callback: (Envelope) throws -> ()) rethrows {
        let serialized = request.serialize()
        logger.debug("Sending request: \(serialized.xmlString)")
        try transport.send(message: serialized.xmlData) { response in
            let doc = try! XMLDocument(data: response, options: 0)
            logger.debug("Received response: \(doc.xmlString)")
            let envelope = Envelope(deserialize: doc)
            try callback(envelope)
        }
    }
}

class HTTPTransport {
    func send(message: Data, response callback: (Data) throws -> ()) rethrows {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8000")!)
        request.httpBody = message
        request.httpMethod = "POST"
        var response: URLResponse? = nil

        let data = try! NSURLConnection.sendSynchronousRequest(request, returning: &response)
        precondition((response as! HTTPURLResponse).statusCode == 200)
        try callback(data)
    }
}

struct Envelope {
    public let body: XMLElement

    init() {
        body = XMLElement.element(withName: "soap:Body", uri: NS_SOAP) as! XMLElement
    }
}

let NS_SOAP = "http://schemas.xmlsoap.org/soap/envelope/"

extension Envelope {
    func serialize() -> XMLDocument {
        let root = XMLElement.element(withName: "soap:Envelope", uri: NS_SOAP) as! XMLElement
        root.addNamespace(XMLElement.namespace(withName: "soap", stringValue: NS_SOAP) as! XMLNode)
        root.addChild(body)
        return XMLDocument(rootElement: root)
    }

    init(deserialize document: XMLDocument) {
        let root = document.rootElement()!
        body = root.elements(forLocalName: "Body", uri: NS_SOAP).first!
    }
}
