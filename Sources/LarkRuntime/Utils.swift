import Foundation

extension XMLElement {
    public convenience init(prefix: String, localName: String, uri: String) throws {
        if prefix != "" {
            self.init(name: "\(prefix):\(localName)", uri: uri)
        } else {
            self.init(name: localName, uri: uri)
        }
    }

    public func createElement(localName: String, uri: String, stringValue: String? = nil) throws -> XMLElement {
        guard let prefix = resolvePrefix(forNamespaceURI: uri) else {
            throw XMLSerializationError.invalidNamespace(uri)
        }
        let element: XMLElement
        if prefix != "" {
            element = XMLElement(name: "\(prefix):\(localName)", uri: uri)
        } else {
            element = XMLElement(name: localName, uri: uri)
        }
        element.stringValue = stringValue
        return element
    }
}

extension XMLNode {
    static func attribute(prefix: String, localName: String, uri: String, stringValue value: String) -> XMLNode {
        if prefix != "" {
            return XMLNode.attribute(withName: "\(prefix):\(localName)", uri: uri, stringValue: value) as! XMLNode
        } else {
            return XMLNode.attribute(withName: localName, uri: uri, stringValue: value) as! XMLNode
        }
    }
}
