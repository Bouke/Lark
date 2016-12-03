import Foundation

public class Client {
    var channel = Channel()

    func send<Request: XMLSerializable, Response: XMLDeserializable>(input: Request, output: (Response) -> ()) throws {
        let request = Envelope(body: XMLElement.element(withName: "echo") as! XMLElement)
        request.body.addNamespace(XMLElement.namespace(withName: "bouke", stringValue: NS) as! XMLNode)
        try input.serialize(request.body)
        print(try request.serialize())

        channel.send(request: request, response: { output(Response(element: $0.body)) })
    }
}

public class Channel {
    let transport = Transport()

    func send(request: Envelope, response callback: (Envelope) -> ()) {
        //        let response = transport.send(message: request.serialize().xmlData)
        //        let doc = try! XMLDocument(data: response, options: 0)
        let doc = try! XMLDocument(xmlString: "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><soap11env:Envelope xmlns:soap11env=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:tns=\"tns\"><soap11env:Body><tns:echoResponse><tns:echoResult><tns:string>Hello</tns:string><tns:string>Hello</tns:string><tns:string>Hello</tns:string><tns:string>Hello</tns:string><tns:string>Hello</tns:string></tns:echoResult></tns:echoResponse></soap11env:Body></soap11env:Envelope>", options: 0)
        callback(Envelope(deserialize: doc))
    }
}

class Transport {
    func send(message: Data, response callback: (Data) -> ()) {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:5000/soap/someservice")!)
        request.httpBody = message
        request.httpMethod = "POST"
        var response: URLResponse? = nil

        let data = try! NSURLConnection.sendSynchronousRequest(request, returning: &response)
        precondition((response as! HTTPURLResponse).statusCode == 200)
        callback(data)
    }
}

struct Envelope {
    public let body: XMLElement
}

let NS_SOAP = "http://schemas.xmlsoap.org/soap/envelope/"

extension Envelope {
    func serialize() -> XMLDocument {
        let root = XMLElement.element(withName: "soap:Envelope", uri: NS_SOAP) as! XMLElement
        root.addNamespace(XMLElement.namespace(withName: "soap", stringValue: NS_SOAP) as! XMLNode)

        let body = XMLElement.element(withName: "soap:Body", uri: NS_SOAP) as! XMLElement
        root.addChild(body)

        body.addChild(self.body)

        return XMLDocument(rootElement: root)
    }

    init(deserialize document: XMLDocument) {
        let root = document.rootElement()!
        body = root.elements(forLocalName: "Body", uri: NS_SOAP).first!.children!.flatMap({ $0 as? XMLElement }).first!
    }
}
