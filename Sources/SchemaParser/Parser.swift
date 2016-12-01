import Foundation

public enum ParseError: Error {
    case noName
    case unsupportedType
    case schemaNotFound
    case unsupportedPortAddress
    case invalidNamespacePrefix
    case noTargetNamespace
}

public func parse(WSDL root: XMLElement) throws -> WSDL {
    precondition(root.localName == "definitions" && root.uri == NS_WSDL)
    return try WSDL(deserialize: root)
}

public func parse(XSD root: XMLElement) throws -> XSD {
    precondition(root.localName == "schema" && root.uri == NS_XSD)
    return try XSD(deserialize: root)
}
