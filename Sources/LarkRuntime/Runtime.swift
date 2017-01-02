import Foundation

public protocol XMLDeserializable {
    init(deserialize: XMLElement) throws
}

public protocol XMLSerializable {
    func serialize(_ element: XMLElement) throws
}

public enum XMLDeserializationError: Error {
    case noElementWithName(String)
}

public enum XMLSerializationError: Error {
    case invalidNamespace(String)
}

public class Fault: Error, CustomStringConvertible {
    let faultcode: String // TODO: should be QualifiedName (from SchemaParser module)
    let faultstring: String
    let faultactor: URL?
    let detail: XMLElement?

    init(deserialize element: XMLElement) throws {
        faultcode = element.elements(forName: "faultcode").first!.stringValue!
        faultstring = element.elements(forName: "faultstring").first!.stringValue!
        faultactor = nil //element.elements(forName: "faultactor").first.map(URL.init(deserialize:))
        detail = element.elements(forName: "detail").first
    }

    public var description: String {
        let actor = faultactor?.absoluteString ?? "nil"
        let detail = self.detail?.xmlString ?? "nil"
        return "Fault(code=\(faultcode), actor=\(actor), string=\(faultstring), detail=\(detail))"
    }
}
