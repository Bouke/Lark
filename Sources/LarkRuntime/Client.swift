import Foundation
import Evergreen

public enum HTTPTransportError: Error {
    case notOk(Int, Data)
    case invalidMimeType(String?)
}


open class Client {
    open let channel = Channel()
    open let logger = Evergreen.getLogger("Lark.Client")

    public init() {
    }

    public func send(parameters: [XMLElement]) throws -> XMLElement {
        let request = Envelope()
        for parameter in parameters {
            request.body.addChild(parameter)
        }
        return try channel.send(request: request).body
    }
}

open class Channel {
    open let transport = HTTPTransport()
    open let logger = Evergreen.getLogger("Lark.Channel")

    func send(request: Envelope) throws -> Envelope {
        let serialized = request.serialize()
        logger.debug("Sending request: \(serialized.xmlString)")
        let response = try transport.send(message: serialized.xmlData)
        let doc = try! XMLDocument(data: response, options: 0)
        logger.debug("Received response: \(doc.xmlString)")
        return Envelope(deserialize: doc)
    }
}

open class HTTPTransport {
    open let logger = Evergreen.getLogger("Lark.HTTPTransport")

    func send(message: Data) throws -> Data {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8000")!)
        request.httpBody = message
        request.httpMethod = "POST"
        logger.debug("Request: " + request.debugDescription)

        var response: URLResponse? = nil
        let data = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
        guard let httpResponse = response as? HTTPURLResponse else {
            fatalError("Expected HTTPURLResponse")
        }
        logger.debug("Response: " + response.debugDescription)
        logger.debug("Response body: " + (String(data: data, encoding: .utf8) ?? "Failed to decode the body as UTF-8 for logging"))
        guard httpResponse.statusCode == 200 else {
            throw HTTPTransportError.notOk(httpResponse.statusCode, data)
        }
        guard httpResponse.mimeType == "text/xml" else {
            throw HTTPTransportError.invalidMimeType(httpResponse.mimeType)
        }
        return data
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
