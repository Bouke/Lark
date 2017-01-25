import Foundation

public func parseWebServiceDefinition(contentsOf url: URL) throws -> WebServiceDescription {
    let xml = try XMLDocument(contentsOf: url, options: 0)
    return try WebServiceDescription(deserialize: xml.rootElement()!, relativeTo: url)
}

public func parseXSD(contentsOf url: URL) throws -> XSD {
    let xml = try XMLDocument(contentsOf: url, options: 0)
    return try XSD(deserialize: xml.rootElement()!)
}
