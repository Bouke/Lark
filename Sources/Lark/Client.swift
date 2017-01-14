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

    public func send(action: URL, parameters: [XMLElement], completionHandler: @escaping (Result<XMLElement>) -> Void) throws {
        let request = Envelope()
        for (key, value) in headers {
            let node = XMLElement(name: key.localName, uri: key.uri)
            node.setAttributesWith(["xmlns": key.uri])
            try value.serialize(node)
            request.header.addChild(node)
        }
        for parameter in parameters {
            request.body.addChild(parameter)
        }
        channel.send(action: action, request: request) { result in
            completionHandler(result.map { $0.body })
        }
    }

    public func call<T>(
        action: URL,
        serialize: (Envelope) throws -> Envelope,
        deserialize: @escaping (Envelope) throws -> T)
        -> Request<T>
    {
        let originalEnvelope = Envelope()
        do {
            let envelope = try serialize(originalEnvelope)

            //TODO: send request
            print(envelope)

            return Request(responseDeserializer: { envelope in
                //TODO: validate response
                do {
                    return .success(try deserialize(envelope))
                } catch {
                    return .failure(error)
                }
            })
        } catch {
            fatalError("TODO: return failed Request")
        }
    }
}

