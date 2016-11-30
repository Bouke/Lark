import Foundation

let NS_WSDL = "http://schemas.xmlsoap.org/wsdl/"
let NS_XSD = "http://www.w3.org/2001/XMLSchema"

public enum ParseError: Error {
    case noName
    case unsupportedType
    case schemaNotFound
}

public func parse(WSDL root: XMLElement) throws {
    precondition(root.localName == "definitions" && root.uri == NS_WSDL)

    guard let schema = root
        .elements(forLocalName: "types", uri: NS_WSDL)
        .first?
        .elements(forLocalName: "schema", uri: NS_XSD)
        .first else {
        throw ParseError.schemaNotFound
    }
    print(try parse(XSD: schema))
}

public func parse(XSD root: XMLElement) throws -> XSD {
    precondition(root.localName == "schema" && root.uri == NS_XSD)

    return try root
        .elements(forLocalName: "element", uri: NS_XSD)
        .map(parseElement(node:))
}

