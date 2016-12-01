import Foundation

public struct XSD {
    public let elements: [Element]
    public let complexes: [Complex]

    init(deserialize node: XMLElement) throws {
        elements = try node
            .elements(forLocalName: "element", uri: NS_XSD)
            .map(Element.init(deserialize:))
        complexes = try node
            .elements(forLocalName: "complexType", uri: NS_XSD)
            .map(Complex.init(deserialize:))
    }
}

public struct Element {
    public enum Content {
        case base(QualifiedName)
        case complex(Complex)

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
            content = .complex(try Complex(deserialize: complex))
        } else {
            throw ParseError.unsupportedType
        }

        occurs = range(node.attribute(forLocalName: "minOccurs", uri: nil)?.stringValue,
                       node.attribute(forLocalName: "maxOccurs", uri: nil)?.stringValue)
    }
}

public struct Complex {
    public enum Content {
        public struct Sequence {
            public let elements: [Element]
        }
        case sequence(Sequence)
    }

    public let name: QualifiedName?
    public let content: Content
}

extension Complex {
    init(deserialize node: XMLElement) throws {
        guard let localName = node.attribute(forLocalName: "name", uri: nil)?.stringValue else {
            throw ParseError.noName
        }
        name = try QualifiedName(uri: targetNamespace(ofNode: node), localName: localName)

        if let sequence = node.elements(forLocalName: "sequence", uri: NS_XSD).first {
            content = .sequence(try Content.Sequence(deserialize: sequence))
        } else {
            throw ParseError.unsupportedType
        }
    }
}

extension Complex.Content.Sequence {
    init(deserialize node: XMLElement) throws {
        elements = try node.elements(forLocalName: "element", uri: NS_XSD).map(Element.init(deserialize:))
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
