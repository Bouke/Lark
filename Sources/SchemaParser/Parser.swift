import Foundation

let NS_WSDL = "http://schemas.xmlsoap.org/wsdl/"
let NS_XSD = "http://www.w3.org/2001/XMLSchema"
let NS_SOAP = "http://schemas.xmlsoap.org/wsdl/soap/"
let NS_SOAP12 = "http://schemas.xmlsoap.org/wsdl/soap12/"

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

    return try root
        .elements(forLocalName: "element", uri: NS_XSD)
        .map(parseElement(node:))
}

