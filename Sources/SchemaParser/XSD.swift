import Foundation
import LarkRuntime

public struct XSD {
    public enum Node {
//        case include
        case `import`(Import)
//        case redefine
//        case annotation
        case simpleType(SimpleType)
        case complexType(ComplexType)
//        case group
//        case attributeGroup
        case element(Element)
//        case attribute
//        case notation

        public var element: Element? {
            guard case let .element(element) = self else { return nil }
            return element
        }

        public var simpleType: SimpleType? {
            guard case let .simpleType(simpleType) = self else { return nil }
            return simpleType
        }

        public var complexType: ComplexType? {
            guard case let .complexType(complexType) = self else { return nil }
            return complexType
        }
    }

    let nodes: [Node]

    public init(nodes: [Node]) {
        self.nodes = nodes
    }

    init(deserialize node: XMLElement) throws {
        guard node.localName == "schema" && node.uri == NS_XSD else {
            throw ParseError.incorrectRootElement
        }

        nodes = try (node.children ?? [])
            .flatMap { $0 as? XMLElement }
            .flatMap { child -> Node? in
                guard child.uri == NS_XSD else {
                    throw ParseError.invalidNamespace
                }

                switch child.localName {
                case "import"?: return try .import(Import(deserialize: child))
                case "simpleType"?: return try .simpleType(SimpleType(deserialize: child))
                case "complexType"?: return try .complexType(ComplexType(deserialize: child))
                case "element"?: return try .element(Element(deserialize: child))
                default: return nil
                }
            }
    }
}

extension XSD: Sequence {
    public func makeIterator() -> IndexingIterator<[Node]> {
        return nodes.makeIterator()
    }
}

extension XSD: Collection {
    public typealias Index = Int
    public var startIndex: Index {
        return nodes.startIndex
    }
    public var endIndex: Index {
        return nodes.endIndex
    }
    public func index(after i: Index) -> Index {
        return nodes.index(after: i)
    }
    public subscript(position: Index) -> Node {
        return nodes[position]
    }
}

public struct Import {
    public let namespace: String
    public let schemaLocation: String
}

extension Import {
    init(deserialize node: XMLElement) throws {
        guard let namespace = node.attribute(forLocalName: "namespace", uri: nil)?.stringValue else {
            throw ParseError.unsupportedImport
        }
        self.namespace = namespace

        guard let schemaLocation = node.attribute(forLocalName: "schemaLocation", uri: nil)?.stringValue else {
            throw ParseError.unsupportedImport
        }
        self.schemaLocation = schemaLocation
    }
}

public struct Element {
    public enum Content {
        case base(QualifiedName)
        case complex(ComplexType)

        public var name: QualifiedName? {
            switch self {
            case let .base(base): return base
            case let .complex(complex): return complex.name
            }
        }
    }

    public let name: QualifiedName
    public let content: Content
    public let occurs: CountableRange<Int>?
}

extension Element {
    init(deserialize node: XMLElement) throws {
        guard let localName = node.attribute(forLocalName: "name", uri: nil)?.stringValue else {
            throw ParseError.noName
        }
        name = try QualifiedName(uri: targetNamespace(ofNode: node), localName: localName)

        if let base = node.attribute(forLocalName: "type", uri: nil)?.stringValue {
            content = .base(try QualifiedName(type: base, inTree: node))
        } else if let complex = node.elements(forLocalName: "complexType", uri: NS_XSD).first {
            content = .complex(try ComplexType(deserialize: complex))
        } else {
            throw ParseError.unsupportedType
        }

        occurs = range(node.attribute(forLocalName: "minOccurs", uri: nil)?.stringValue,
                       node.attribute(forLocalName: "maxOccurs", uri: nil)?.stringValue)
    }
}

public protocol NamedType {
    var name: QualifiedName? { get }
}

public struct SimpleType: NamedType {
    public struct Restriction {
        public let base: QualifiedName
        public let enumeration: [String]
        public let pattern: String?

        public init(base: QualifiedName, enumeration: [String], pattern: String?) {
            self.base = base
            self.enumeration = enumeration
            self.pattern = pattern
        }

        init(deserialize node: XMLElement) throws {
            guard let base = node.attribute(forLocalName: "base", uri: nil)?.stringValue else {
                throw ParseError.unsupportedType
            }
            self.base = try QualifiedName(type: base, inTree: node)
            enumeration = try node.elements(forLocalName: "enumeration", uri: NS_XSD).map {
                guard let value = $0.attribute(forLocalName: "value", uri: nil)?.stringValue else {
                    throw ParseError.unsupportedType
                }
                return value
            }
            pattern = node.elements(forLocalName: "pattern", uri: NS_XSD).first?.attribute(forName: "value")?.stringValue
        }
    }

    public indirect enum Content {
        case restriction(Restriction)
        case list(itemType: QualifiedName)
        case listWrapped(SimpleType)
//        case list
//        case union
    }

    public let name: QualifiedName?
    public let content: Content
}

extension SimpleType {
    init(deserialize node: XMLElement) throws {
        name = try .name(ofElement: node)

        if let restriction = node.elements(forLocalName: "restriction", uri: NS_XSD).first {
            content = try .restriction(Restriction(deserialize: restriction))
        } else if let list = node.elements(forLocalName: "list", uri: NS_XSD).first {
            if let itemType = list.attribute(forLocalName: "itemType", uri: nil)?.stringValue {
                content = try .list(itemType: QualifiedName(type: itemType, inTree: list))
            } else if let simpleType = list.elements(forLocalName: "simpleType", uri: NS_XSD).first {
                content = try .listWrapped(SimpleType(deserialize: simpleType))
            } else {
                throw ParseError.unsupportedType
            }
        } else {
            throw ParseError.unsupportedType
        }
    }
}


public struct ComplexType: NamedType {
    public enum Content {
        public struct Sequence {
            public let elements: [Element]
        }
        case sequence(Sequence)

        public struct ComplexContent {
            public enum Content {
                public enum Content {
                    case sequence(Sequence)
                }

                case restriction(Content)
                case `extension`(Content)
            }
            public let base: QualifiedName
            public let content: Content
        }
        case complex(ComplexContent)
        case empty
    }

    public let name: QualifiedName?
    public let content: Content
}

extension ComplexType {
    init(deserialize node: XMLElement) throws {
        name = try .name(ofElement: node)

        if let _ = node.elements(forLocalName: "simpleContent", uri: NS_XSD).first {
            throw ParseError.unsupportedType
        } else if let complexContent = node.elements(forLocalName: "complexContent", uri: NS_XSD).first {
            content = .complex(try .init(deserialize: complexContent))
        } else if let _ = node.elements(forLocalName: "group", uri: NS_XSD).first {
            throw ParseError.unsupportedType
        } else if let _ = node.elements(forLocalName: "all", uri: NS_XSD).first {
            throw ParseError.unsupportedType
        } else if let _ = node.elements(forLocalName: "choice", uri: NS_XSD).first {
            throw ParseError.unsupportedType
        } else if let sequence = node.elements(forLocalName: "sequence", uri: NS_XSD).first {
            content = .sequence(try Content.Sequence(deserialize: sequence))
        } else {
            content = .empty
        }
    }
}

extension ComplexType.Content.Sequence {
    init(deserialize node: XMLElement) throws {
        elements = try node.elements(forLocalName: "element", uri: NS_XSD).map(Element.init(deserialize:))
    }
}

extension ComplexType.Content.ComplexContent {
    init(deserialize node: XMLElement) throws {
        if let restriction = node.elements(forLocalName: "restriction", uri: NS_XSD).first {
            base = try .init(type: restriction.attribute(forName: "base")!.stringValue!, inTree: node)
            content = .restriction(try .init(deserialize: restriction))
        } else if let `extension` = node.elements(forLocalName: "extension", uri: NS_XSD).first {
            base = try .init(type: `extension`.attribute(forName: "base")!.stringValue!, inTree: node)
            content = .`extension`(try .init(deserialize: `extension`))
        } else {
            throw ParseError.unsupportedType
        }
    }
}

extension ComplexType.Content.ComplexContent.Content.Content {
    init(deserialize node: XMLElement) throws {
        if let sequence = node.elements(forLocalName: "sequence", uri: NS_XSD).first {
            self = .sequence(try .init(deserialize: sequence))
        } else {
            throw ParseError.unsupportedType
        }
    }
}

func range(_ minOccurs: String?, _ maxOccurs: String?) -> CountableRange<Int>? {
    switch (minOccurs, maxOccurs) {
    case (.none, .none): return nil
    case (.none, "unbounded"?): return 1..<Int.max
    case (.none, let max?): return 1..<Int(max)!
    case (let min?, .none): return Int(min)!..<1
    case (let min?, "unbounded"?): return Int(min)!..<Int.max
    case (let min?, let max?): return Int(min)!..<Int(max)!
    }
}
