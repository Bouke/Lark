import Foundation

extension XMLElement {

    /// Creates an XMLElement with the given namespace prefix.
    ///
    /// - Note:
    ///   The prefix is not validated and cannot be an empty string.
    /// - Parameters:
    ///   - prefix: namespace prefix
    ///   - localName: element name
    ///   - uri: namespace URI
    public convenience init(prefix: String, localName: String, uri: String) {
        precondition(prefix != "", "Prefix cannot be an empty string")
        self.init(name: "\(prefix):\(localName)", uri: uri)
    }

    /// Creates a unique prefix for the given namespace.
    ///
    /// - Note:
    ///   Doesn't verify whether there is already a prefix for this namespace.
    ///   Use `resolveOrAddPrefix(forNamespaceURI:)` instead.
    /// - Parameter uri: namespace URI
    /// - Returns: namespace prefix
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

    /// Returns the prefix for the given namespace.
    ///
    /// If no prefix exists for the given namespace, a new prefix will be
    /// created.
    ///
    /// - Parameter uri: namespace URI
    /// - Returns: namespace prefix
    func resolveOrAddPrefix(forNamespaceURI uri: String) -> String {
        if let prefix = resolvePrefix(forNamespaceURI: uri) {
            return prefix
        }
        return addNamespace(uri: uri)
    }

    /// Creates a child node with a local name, adds a prefix automatically.
    /// The child node is appended to `self`.
    ///
    /// - Parameters:
    ///   - localName: element name
    ///   - uri: namespace URI that will be used to lookup the correct prefix
    ///   - stringValue: optional element value
    /// - Returns: the child element
    public func createChildElement(localName: String, uri: String, stringValue: String? = nil) -> XMLElement {
        let prefix = resolveOrAddPrefix(forNamespaceURI: uri)
        let element: XMLElement
        if prefix != "" {
            element = XMLElement(name: "\(prefix):\(localName)", uri: uri)
        } else {
            element = XMLElement(name: localName, uri: uri)
        }
        element.stringValue = stringValue
        addChild(element)
        return element
    }

    /// Returns the element's target namespace.
    ///
    /// The elements target namespace might be inherited from any (grand)
    /// parent in the tree.
    public var targetNamespace: String? {
        if let tns = self.attribute(forName: "targetNamespace")?.stringValue {
            return tns
        }
        guard let parent = parent as? XMLElement else {
            return nil
        }
        return parent.targetNamespace
    }
}

extension XMLNode {
    /// Creates an attribute XMLNode with the given namespace prefix.
    ///
    /// - Note:
    ///   The prefix is not validated and cannot be an empty string.
    /// - Parameters:
    ///   - prefix: optional namespace prefix
    ///   - localName: attribute name
    ///   - uri: namespace URI
    ///   - value: attribute value
    /// - Returns: attribute XMLNode
    public static func attribute(prefix: String? = nil, localName: String, uri: String, stringValue value: String) -> XMLNode {
        precondition(prefix != "", "Prefix cannot be an empty string")
        if let prefix = prefix {
            return XMLNode.attribute(withName: "\(prefix):\(localName)", uri: uri, stringValue: value) as! XMLNode
        } else {
            return XMLNode.attribute(withName: localName, uri: uri, stringValue: value) as! XMLNode
        }
    }
}
