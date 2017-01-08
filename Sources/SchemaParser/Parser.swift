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
    case bindingOperationIncomplete
    case incorrectRootElement
}


public func parseWSDL(contentsOf url: URL) throws -> WSDL {
    let xml = try XMLDocument(contentsOf: url, options: 0)
    return try WSDL(deserialize: xml.rootElement()!, relativeTo: url)
}


public func parseXSD(contentsOf url: URL) throws -> XSD {
    let xml = try XMLDocument(contentsOf: url, options: 0)
    return try XSD(deserialize: xml.rootElement()!)
}

func importSchema(url: URL) throws -> XMLElement {
    return try XMLDocument(contentsOf: url, options: 0).rootElement()!
}
