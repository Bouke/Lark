import Foundation

public enum ParseError: Error {
    case noName
    case unsupportedType
    case schemaNotFound
    case unsupportedPortAddress
    case invalidNamespace
    case invalidNamespacePrefix
    case noTargetNamespace
    case unsupportedImport
    case unsupportedOperation
}

public func parse(WSDL root: XMLElement) throws -> WSDL {
    precondition(root.localName == "definitions" && root.uri == NS_WSDL)
    return try WSDL(deserialize: root)
}

public func parse(XSD root: XMLElement) throws -> XSD {
    precondition(root.localName == "schema" && root.uri == NS_XSD)
    return try XSD(deserialize: root)
}
