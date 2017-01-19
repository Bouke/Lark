import Foundation

public struct QualifiedName {
    public enum Error: Swift.Error {
        case invalidNamespacePrefix
    }

    public let uri: String
    public let localName: String

    public init(uri: String, localName: String) {
        self.uri = uri
        self.localName = localName
    }
}

extension QualifiedName: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "(\(uri))\(localName)"
    }
}

extension QualifiedName: Equatable {
    public static func ==(lhs: QualifiedName, rhs: QualifiedName) -> Bool {
        return lhs.uri == rhs.uri && lhs.localName == rhs.localName
    }
}

extension QualifiedName: Hashable {
    public var hashValue: Int {
        return uri.hashValue % 17 + localName.hashValue
    }
}

extension QualifiedName {
    public init(type: String, inTree tree: XMLElement) throws {
        if type.contains(":") {
            guard let namespace = tree.resolveNamespace(forName: type) else {
                throw Error.invalidNamespacePrefix
            }
            uri = namespace.stringValue!
        } else {
            guard let tns = tree.targetNamespace else {
                throw Error.invalidNamespacePrefix
            }
            uri = tns
        }
        localName = XMLElement(name: type).localName!
    }
}
