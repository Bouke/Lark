import Foundation

public func parseWebServiceDefinition(contentsOf url: URL) throws -> WebServiceDescription {
    let xml = try XMLDocument(contentsOf: url, options: 0)
    return try WebServiceDescription(deserialize: xml.rootElement()!, relativeTo: url)
}

public func parseSchema(contentsOf url: URL) throws -> Schema {
    let xml = try XMLDocument(contentsOf: url, options: 0)
    return try Schema(deserialize: xml.rootElement()!)
}
