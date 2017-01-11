import Foundation
import Evergreen

open class Client {
    open let channel: Channel
    open let logger = Evergreen.getLogger("Lark.Client")
    open var headers: [(QualifiedName, XMLSerializable)] = []

    public init(channel: Channel) {
        self.channel = channel
    }

    public convenience init(endpoint: URL) {
        self.init(channel: Channel(transport: HTTPTransport(endpoint: endpoint)))
    }

    public func send(action: URL, parameters: [XMLElement]) throws -> XMLElement {
        let request = Envelope()
        for header in headers {
            let node = XMLElement(name: header.0.localName, uri: header.0.uri)
            node.setAttributesWith(["xmlns": header.0.uri])
            try header.1.serialize(node)
            request.header.addChild(node)
        }
        for parameter in parameters {
            request.body.addChild(parameter)
        }
        return try channel.send(action: action, request: request).body
    }
}

