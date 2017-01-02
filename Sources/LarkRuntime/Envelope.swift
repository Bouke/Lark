import Foundation

let NS_SOAP = "http://schemas.xmlsoap.org/soap/envelope/"

struct Envelope {
    public let body: XMLElement

    init() {
        body = XMLElement.element(withName: "soap:Body", uri: NS_SOAP) as! XMLElement
    }

    init(deserialize document: XMLDocument) {
        let root = document.rootElement()!
        body = root.elements(forLocalName: "Body", uri: NS_SOAP).first!
    }

    func serialize() -> XMLDocument {
        let root = XMLElement.element(withName: "soap:Envelope", uri: NS_SOAP) as! XMLElement
        root.addNamespace(XMLElement.namespace(withName: "soap", stringValue: NS_SOAP) as! XMLNode)
        root.addChild(body)
        return XMLDocument(rootElement: root)
    }
}
