import Foundation

extension XMLElement {
    public convenience init(prefix: String, localName: String, uri: String) {
        if prefix != "" {
            self.init(name: "\(prefix):\(localName)", uri: uri)
        } else {
            self.init(name: localName, uri: uri)
        }
    }

    func addNamespace(uri: String) -> String {
        for i in 1..<Int.max {
            let prefix = "ns\(i)"
            if resolveNamespace(forName: prefix) == nil {
                let namespace = XMLNode.namespace(withName: prefix, stringValue: uri) as! XMLNode
                addNamespace(namespace)
                return prefix
            }
        }
        fatalError()
    }

    func resolveOrAddPrefix(forNamespaceURI uri: String) -> String {
        if let prefix = resolvePrefix(forNamespaceURI: uri) {
            return prefix
        }
        return addNamespace(uri: uri)
    }

    public func createElement(localName: String, uri: String, stringValue: String? = nil) throws -> XMLElement {
        let prefix = resolveOrAddPrefix(forNamespaceURI: uri)
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
