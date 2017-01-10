import Foundation
import Evergreen

open class Client {
    open let channel: Channel
    open let logger = Evergreen.getLogger("Lark.Client")

    public init(channel: Channel) {
        self.channel = channel
    }

    public convenience init(endpoint: URL) {
        self.init(channel: Channel(transport: HTTPTransport(endpoint: endpoint)))
    }

    public func send(action: URL, parameters: [XMLElement]) throws -> XMLElement {
        let request = Envelope()
        for parameter in parameters {
            request.body.addChild(parameter)
        }
        return try channel.send(action: action, request: request).body
    }
}

