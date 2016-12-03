import Foundation

open class Client {
    var channel = Channel()

    public init() {
    }

    public func send(parameters: [XMLElement], output: (XMLElement) throws -> ()) throws {
        let request = Envelope()
        for parameter in parameters {
            request.body.addChild(parameter)
        }
        print(request.serialize())
        try channel.send(request: request, response: { try output($0.body) })
    }
}

public class Channel {
    let transport = HTTPTransport()

    func send(request: Envelope, response callback: (Envelope) throws -> ()) rethrows {
        try transport.send(message: request.serialize().xmlData) { response in
            let doc = try! XMLDocument(data: response, options: 0)
            let envelope = Envelope(deserialize: doc)
            try callback(envelope)
        }

//        let doc = try! XMLDocument(xmlString: "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><soap11env:Envelope xmlns:soap11env=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:tns=\"tns\"><soap11env:Body><tns:echoResponse><tns:echoResult><tns:string>Hello</tns:string><tns:string>Hello</tns:string><tns:string>Hello</tns:string><tns:string>Hello</tns:string><tns:string>Hello</tns:string></tns:echoResult></tns:echoResponse></soap11env:Body></soap11env:Envelope>", options: 0)
//        try callback(Envelope(deserialize: doc))
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
