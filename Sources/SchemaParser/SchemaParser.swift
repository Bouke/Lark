import Foundation

public func parseWebServiceDescription(contentsOf url: URL) throws -> WebServiceDescription {
    var pending: Set<URL> = [url]
    var visited: Set<URL> = []

    var schema: [Schema.Node] = []
    var messages: [Message] = []
    var portTypes: [PortType] = []
    var bindings: [Binding] = []
    var services: [Service] = []

    while let url = pending.popFirst() {
        visited.insert(url)
        let xml = try XMLDocument(contentsOf: url, options: [])
        let webService = try WebServiceDescription(deserialize: xml.rootElement()!, relativeTo: url)
        for _import in webService.imports {
            if !visited.contains(_import.location) {
                pending.insert(_import.location)
            }
        }
        schema.append(contentsOf: webService.schema)
        messages.append(contentsOf: webService.messages)
        portTypes.append(contentsOf: webService.portTypes)
        bindings.append(contentsOf: webService.bindings)
        services.append(contentsOf: webService.services)
    }

    return WebServiceDescription(
        schema: Schema(nodes: schema),
        messages: messages,
        portTypes: portTypes,
        bindings: bindings,
        services: services)
}

public func parseSchema(contentsOf url: URL) throws -> Schema {
    let xml = try XMLDocument(contentsOf: url, options: [])
    return try Schema(deserialize: xml.rootElement()!)
}
