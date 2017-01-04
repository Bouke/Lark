import Foundation

let NS_SOAP = "http://schemas.xmlsoap.org/soap/envelope/"

public struct Envelope {
    let document: XMLDocument

    init() {
        let root = XMLElement.element(withName: "soap:Envelope", uri: NS_SOAP) as! XMLElement
        root.addNamespace(XMLElement.namespace(withName: "soap", stringValue: NS_SOAP) as! XMLNode)
        let body = XMLElement.element(withName: "soap:Body", uri: NS_SOAP) as! XMLElement
        root.addChild(body)
        document = XMLDocument(rootElement: root)
        document.version = "1.1"
        document.characterEncoding = "utf-8"
        document.isStandalone = true
    }

    init(document: XMLDocument) {
        self.document = document
    }

    var body: XMLElement {
        return document.rootElement()!.elements(forLocalName: "Body", uri: NS_SOAP).first!
    }
}
