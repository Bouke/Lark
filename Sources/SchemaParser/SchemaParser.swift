import Foundation

public func parseWSDL(contentsOf url: URL) throws -> WSDL {
    let xml = try XMLDocument(contentsOf: url, options: 0)
    return try WSDL(deserialize: xml.rootElement()!, relativeTo: url)
}

public func parseXSD(contentsOf url: URL) throws -> XSD {
    let xml = try XMLDocument(contentsOf: url, options: 0)
    return try XSD(deserialize: xml.rootElement()!)
}
