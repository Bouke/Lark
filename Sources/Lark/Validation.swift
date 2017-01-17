import Alamofire
import Foundation


extension DataRequest {
    func validateSOAP() -> Self {
        return validate { _, response, data in
            switch response.statusCode {
            case 200: return .success
            case 500:
                do {
                    let document = try XMLDocument(data: data!, options: 0)
                    let envelope = Envelope(document: document)
                    let fault = try Fault(deserialize: envelope.body.elements(forLocalName: "Fault", uri: NS_SOAP).first!)
                    return .failure(fault)
                } catch {
                    return .failure(error)
                }
            default:
                fatalError("Unexpected status code \(response.statusCode). Verify that validate(statusCode:) is called before this validation.")
            }
        }
    }
}


public struct Fault: Error, CustomStringConvertible, XMLDeserializable, XMLSerializable {
    let faultcode: String // TODO: should be QualifiedName (from SchemaParser module)
    let faultstring: String
    let faultactor: URL?
    let detail: [XMLNode]

    public init(faultcode: String, faultstring: String, faultactor: URL?, detail: [XMLNode]) {
        self.faultcode = faultcode
        self.faultstring = faultstring
        self.faultactor = faultactor
        self.detail = detail
    }

    public init(deserialize element: XMLElement) throws {
        faultcode = element.elements(forName: "faultcode").first!.stringValue!
        faultstring = element.elements(forName: "faultstring").first!.stringValue!
        faultactor = nil //element.elements(forName: "faultactor").first.map(URL.init(deserialize:))
        detail = element.elements(forName: "detail").first?.children ?? []
    }

    public func serialize(_ element: XMLElement) throws {
        element.addChild(XMLElement(name: "faultcode", stringValue: faultcode))
        element.addChild(XMLElement(name: "faultstring", stringValue: faultstring))
        element.addChild(XMLElement(name: "faultactor", stringValue: faultactor?.absoluteString))

        let detailNode = XMLElement(name: "detail")
        for child in detail {
            detailNode.addChild(child)
        }
    }

    public var description: String {
        let actor = faultactor?.absoluteString ?? "nil"
        let detail = self.detail.map({ $0.xmlString }).joined(separator: ", ")
        return "Fault(code=\(faultcode), actor=\(actor), string=\(faultstring), detail=\(detail))"
    }
}
