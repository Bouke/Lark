import Foundation
import Lark

public struct Schema {
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

    let targetNamespace: String?
    let nodes: [Node]

    public init(nodes: [Node]) {
        self.targetNamespace = nil
        self.nodes = nodes
    }

    init(deserialize node: XMLElement) throws {
        guard node.localName == "schema" && node.uri == NS_XS else {
            throw SchemaParseError.incorrectRootElement
        }
        targetNamespace = node.attribute(forName: "targetNamespace")?.stringValue

        var nodes = [Node]()
        for child in node.children ?? [] {
            guard let node = child as? XMLElement else {
                continue
            }
            guard node.uri == NS_XS else {
                throw SchemaParseError.incorrectNamespace
            }
            switch node.localName! {
            case "annotation", "attribute", "attributeGroup", "group", "include", "notation", "redefine":
                // silently ignore these unsupported top level elements
                break
            case "import":
                nodes.append(try .import(Import(deserialize: node)))
            case "simpleType":
                nodes.append(try .simpleType(SimpleType(deserialize: node)))
            case "complexType":
                nodes.append(try .complexType(ComplexType(deserialize: node)))
            case "element":
                nodes.append(try .element(Element(deserialize: node)))
            default:
                throw SchemaParseError.incorrectTopLevelElement(node.localName!)
            }
        }
        self.nodes = nodes
    }
}

extension Schema: Sequence {
    public func makeIterator() -> IndexingIterator<[Node]> {
        return nodes.makeIterator()
    }
}

extension Schema: Collection {
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
    public let schemaLocation: String?
}

extension Import {
    init(deserialize node: XMLElement) throws {
        guard let namespace = node.attribute(forLocalName: "namespace", uri: nil)?.stringValue else {
            throw SchemaParseError.importWithoutNamespace
        }
        self.namespace = namespace
        self.schemaLocation = node.attribute(forLocalName: "schemaLocation", uri: nil)?.stringValue
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
    public let nillable: Bool

    static func range(_ minOccurs: String?, _ maxOccurs: String?) -> CountableRange<Int>? {
        switch (minOccurs, maxOccurs) {
        case (.none, .none): return nil
        case (.none, "unbounded"?): return 1..<Int.max
        case (.none, let max?): return 1..<Int(max)!
        case (let min?, .none): return Int(min)!..<1
        case (let min?, "unbounded"?): return Int(min)!..<Int.max
        case (let min?, let max?): return Int(min)!..<Int(max)!
        }
    }
}

extension Element {
    init(deserialize node: XMLElement) throws {
        guard let localName = node.attribute(forLocalName: "name", uri: nil)?.stringValue else {
            throw SchemaParseError.elementWithoutName
        }
        guard let tns = node.targetNamespace else {
            throw SchemaParseError.elementWithoutTargetNamespace
        }
        name = QualifiedName(uri: tns, localName: localName)

        // Possible other content: unconstrained (raw XML), simpleType
        if let base = node.attribute(forLocalName: "type", uri: nil)?.stringValue {
            content = .base(try QualifiedName(type: base, inTree: node))
        } else if let complex = node.elements(forLocalName: "complexType", uri: NS_XS).first {
            content = .complex(try ComplexType(deserialize: complex))
        } else if let _ = node.elements(forLocalName: "simpleType", uri: NS_XS).first {
            throw SchemaParseError.elementContentNotSupported
        } else {
            // The default for xs:element/@type is ur-type, otherwise known as anyType.
            content = .base(QualifiedName(uri: NS_XS, localName: "anyType"))
        }

        occurs = Element.range(node.attribute(forLocalName: "minOccurs", uri: nil)?.stringValue,
                               node.attribute(forLocalName: "maxOccurs", uri: nil)?.stringValue)

        nillable = node.attribute(forLocalName: "nillable", uri: nil)?.stringValue ?? "false" == "true"
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
                throw SchemaParseError.restrictionWithoutBase
            }
            self.base = try QualifiedName(type: base, inTree: node)
            enumeration = try node.elements(forLocalName: "enumeration", uri: NS_XS).map {
                guard let value = $0.attribute(forLocalName: "value", uri: nil)?.stringValue else {
                    throw SchemaParseError.enumerationWithoutValue
                }
                return value
            }
            pattern = node.elements(forLocalName: "pattern", uri: NS_XS).first?.attribute(forName: "value")?.stringValue
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

        if let restriction = node.elements(forLocalName: "restriction", uri: NS_XS).first {
            content = try .restriction(Restriction(deserialize: restriction))
        } else if let list = node.elements(forLocalName: "list", uri: NS_XS).first {
            if let itemType = list.attribute(forLocalName: "itemType", uri: nil)?.stringValue {
                content = try .list(itemType: QualifiedName(type: itemType, inTree: list))
            } else if let simpleType = list.elements(forLocalName: "simpleType", uri: NS_XS).first {
                content = try .listWrapped(SimpleType(deserialize: simpleType))
            } else {
                throw SchemaParseError.simpleTypeContentNotSupported
            }
        } else {
            throw SchemaParseError.simpleTypeContentNotSupported
        }
    }
}


public struct ComplexType: NamedType {
    public enum Content {
        public struct Sequence {
            public let elements: [Element]

            init(deserialize node: XMLElement) throws {
                elements = try node.elements(forLocalName: "element", uri: NS_XS).map(Element.init(deserialize:))
            }
        }
        case sequence(Sequence)

        public struct ComplexContent {
            public enum Content {
                public enum Content {
                    case sequence(Sequence)

                    init(deserialize node: XMLElement) throws {
                        if let sequence = node.elements(forLocalName: "sequence", uri: NS_XS).first {
                            self = .sequence(try .init(deserialize: sequence))
                        } else {
                            // there's a few others (e.g. choice)
                            throw SchemaParseError.complexContentContentNotSupported
                        }
                    }
                }

                case restriction(Content)
                case `extension`(Content)
            }
            public let base: QualifiedName
            public let content: Content

            init(deserialize node: XMLElement) throws {
                if let restriction = node.elements(forLocalName: "restriction", uri: NS_XS).first {
                    base = try .init(type: restriction.attribute(forName: "base")!.stringValue!, inTree: node)
                    content = .restriction(try .init(deserialize: restriction))
                } else if let `extension` = node.elements(forLocalName: "extension", uri: NS_XS).first {
                    base = try .init(type: `extension`.attribute(forName: "base")!.stringValue!, inTree: node)
                    content = .`extension`(try .init(deserialize: `extension`))
                } else {
                    // should not happen, restriction and extension are the only valid content types
                    throw SchemaParseError.invalidComplexContentContent
                }
            }
        }
        case complex(ComplexContent)
        case empty
    }

    public let name: QualifiedName?
    public let content: Content

    init(deserialize node: XMLElement) throws {
        name = try .name(ofElement: node)

        if let _ = node.elements(forLocalName: "simpleContent", uri: NS_XS).first {
            throw SchemaParseError.complexTypeContentNotSupported
        } else if let complexContent = node.elements(forLocalName: "complexContent", uri: NS_XS).first {
            content = .complex(try .init(deserialize: complexContent))
        } else if let _ = node.elements(forLocalName: "group", uri: NS_XS).first {
            throw SchemaParseError.complexTypeContentNotSupported
        } else if let _ = node.elements(forLocalName: "all", uri: NS_XS).first {
            throw SchemaParseError.complexTypeContentNotSupported
        } else if let _ = node.elements(forLocalName: "choice", uri: NS_XS).first {
            throw SchemaParseError.complexTypeContentNotSupported
        } else if let sequence = node.elements(forLocalName: "sequence", uri: NS_XS).first {
            content = .sequence(try Content.Sequence(deserialize: sequence))
        } else {
            content = .empty
        }
    }
}

public enum SchemaParseError: Error {
    case incorrectRootElement
    case incorrectNamespace
    case incorrectTopLevelElement(String)
    case importWithoutNamespace
    case importWithoutSchemaLocation
    case elementWithoutName
    case elementWithoutTargetNamespace
    case elementContentNotSupported
    case restrictionWithoutBase
    case enumerationWithoutValue
    case simpleTypeContentNotSupported
    case complexTypeContentNotSupported
    case invalidComplexContentContent
    case complexContentContentNotSupported
}

extension SchemaParseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .incorrectRootElement:
            return "incorrect root element. The root element of the Schema should be (\(NS_XS))type."
        case .incorrectNamespace:
            return "incorrect namespace of root type, should have the namespace \(NS_XS)."
        case .incorrectTopLevelElement(let localName):
            return "incorrect top level element '\(localName)'."
        case .importWithoutNamespace:
            return "schema import must have a target namespace."
        case .importWithoutSchemaLocation:
            return "schema import must have a schema location."
        case .elementWithoutName:
            return "schema element must have a name."
        case .elementWithoutTargetNamespace:
            return "schema element must have a target namespace."
        case .elementContentNotSupported:
            return "schema element has content that is not (yet) supported."
        case .restrictionWithoutBase:
            return "schema restriction must have a base type."
        case .enumerationWithoutValue:
            return "schema enumeration must have a value."
        case .simpleTypeContentNotSupported:
            return "schema simpleType has content that is not (yet) supported."
        case .complexTypeContentNotSupported:
            return "schema complexType has content that is not (yet) supported."
        case .invalidComplexContentContent:
            return "schema complexContent has invalid content."
        case .complexContentContentNotSupported:
            return "schema complexContent {restriction,extension} has unsupported content."
        }
    }
}
