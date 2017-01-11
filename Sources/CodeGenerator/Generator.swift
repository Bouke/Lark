import Foundation
import SchemaParser
import LarkRuntime

enum GeneratorError: Error {
    case missingTypes(Set<QualifiedName>)
    case messageNotFound(QualifiedName)
    case missingNodes(Set<WSDL.Node>)
    case noSOAP11Port
    case rpcNotSupported
    case notImplemented
}


public enum Type {
    case element(QualifiedName)
    case type(QualifiedName)
}

extension Type {
    var element: QualifiedName? {
        if case let .element(name) = self {
            return name
        } else {
            return nil
        }
    }
}

extension Type: Equatable, Hashable {
    public static func ==(lhs: Type, rhs: Type) -> Bool {
        switch(lhs, rhs) {
        case let (.element(lhs), .element(rhs)): return lhs == rhs
        case let (.type(lhs), .type(rhs)): return lhs == rhs
        default: return false
        }
    }

    public var hashValue: Int {
        switch self {
        case let .element(qname): return qname.hashValue
        case let .type(qname): return qname.hashValue
        }
    }
}

extension Type: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .element(qname): return ".element(\(qname.debugDescription))"
        case let .type(qname): return ".type(\(qname.debugDescription))"
        }
    }
}

public typealias Identifier = String
public typealias TypeMapping = [Type: Identifier]
public typealias Types = [Type: SwiftMetaType]

enum ElementHierarchy {
    typealias Node = Type
    typealias Edge = (from: Node, to: Node)
    typealias Graph = CodeGenerator.Graph<Node>
}


public func generate(wsdl: WSDL, service: Service) throws -> String {
    // Verify service has a SOAP 1.1 port.
    guard let port = service.ports.first(where: { if case .soap11 = $0.address { return true } else { return false } }) else {
        throw GeneratorError.noSOAP11Port
    }

    // Verify that the binding is document/literal.
    let binding = wsdl.bindings.first { $0.name == port.binding }!
    guard binding.operations.first(where: { $0.style == .rpc || $0.input == .encoded || $0.output == .encoded }) == nil else {
        throw GeneratorError.rpcNotSupported
    }

    // Verify that all the types can be satisfied.
    try wsdl.verify()

    let types = try generateTypes(inSchema: wsdl.schema)

    var clients = [SwiftClientClass]()
    for service in wsdl.services {
        clients.append(service.toSwift(wsdl: wsdl, types: types))
    }

    return SwiftCodeGenerator.generateCode(for: Array(types.values), clients)
}


func generateTypes(inSchema schema: XSD) throws -> Types {
    var mapping: TypeMapping = baseTypes.dictionary { (Type.type($0), $1) }
    var scope = Set<String>()
    var hierarchy = ElementHierarchy.Graph()

    // Assign unique names to all nodes. First, elements are given a name. Sometimes
    // elements have the same name as their implementing types, and we give give preference
    // to elements.

    // We'll build the classes from top-to-bottom. So build the inheritance hierarchy
    // of the classes.

    // Note that we could collapse elements having only a base type. At the moment we handle
    // this using inheritance.

    let elements = schema.flatMap { $0.element }.dictionary { ($0.name, $0) }
    let complexes = schema.flatMap { $0.complexType }.dictionary { ($0.name!, $0) }
    let simples = schema.flatMap { $0.simpleType }.dictionary { ($0.name!, $0) }

    for element in elements.values {
        let className = element.name.localName.toSwiftTypeName()
        guard !scope.contains(className) else {
            fatalError("Element name must be unique")
        }
        mapping[.element(element.name)] = className
        scope.insert(className)

        switch element.content {
        case let .base(base): hierarchy.insertEdge((.element(element.name), .type(base)))
        case .complex: hierarchy.nodes.insert(.element(element.name))
        }
    }

    let namedTypes: [NamedType] = complexes.values.map({ $0 as NamedType }) + simples.values.map({ $0 as NamedType })
    for type in namedTypes {
        let className: String
        let baseName = type.name!.localName.toSwiftTypeName()
        if !scope.contains(baseName) {
            className = baseName
        } else if !scope.contains("\(baseName)Type") {
            className = "\(baseName)Type"
        } else {
            className = (2...Int.max).lazy.map { "\(baseName)Type\($0)" }.first { !scope.contains($0) }!
        }
        mapping[.type(type.name!)] = className
        scope.insert(className)
    }

    // Note that a complexType can also have
    // a base type, but that's currently not implemented.
    for case let .complexType(type) in schema {
        switch type.content {
        case let .complex(complex): hierarchy.insertEdge((.type(type.name!), .type(complex.base)))
        case .sequence(_): fallthrough // TODO: inspect nested types as well
        case .empty: hierarchy.nodes.insert(.type(type.name!))
        }
    }

    // Add simpleType's base type.
    for case let .simpleType(type) in schema {
        switch type.content {
        case let .list(itemType: itemType): hierarchy.insertEdge((.type(type.name!), .type(itemType)))
        case .listWrapped: hierarchy.nodes.insert(.type(type.name!))
        case .restriction: hierarchy.nodes.insert(.type(type.name!))
        }
    }

    var types: Types = baseTypes.dictionary { (.type($0), SwiftBuiltin(name: $1)) }
    for node in hierarchy.traverse {
        switch node {
        case let .element(name):
            types[node] = elements[name]!.toSwift(mapping: mapping, types: types)
        case let .type(name):
            if baseTypes[name] != nil {
                continue
            } else if let complex = complexes[name] {
                types[node] = complex.toSwift(mapping: mapping, types: types)
            } else if let simple = simples[name] {
                types[node] = try simple.toSwift(mapping: mapping, types: types)
            } else {
                throw GeneratorError.missingTypes([name])
            }
        }
    }

    return types
}

extension XSD {
    public func generateCode() throws -> [LineOfCode] {
        let types = try generateTypes(inSchema: self)
        return Array(types.values).flatMap { $0.toLinesOfCode(at: Indentation(chars: "    ")) }
    }
}

// todo: cleanup
let baseTypes: [QualifiedName: Identifier] = [
    QualifiedName(uri: NS_XSD, localName: "byte"): "Int8",
    QualifiedName(uri: NS_XSD, localName: "unsignedByte"): "UInt8",
    QualifiedName(uri: NS_XSD, localName: "short"): "Int16",
    QualifiedName(uri: NS_XSD, localName: "unsignedShort"): "UInt16",
    QualifiedName(uri: NS_XSD, localName: "int"): "Int32",
    QualifiedName(uri: NS_XSD, localName: "unsignedInt"): "UInt32",
    QualifiedName(uri: NS_XSD, localName: "long"): "Int64",
    QualifiedName(uri: NS_XSD, localName: "unsignedLong"): "UInt64",

    QualifiedName(uri: NS_XSD, localName: "boolean"): "Bool",
    QualifiedName(uri: NS_XSD, localName: "float"): "Float",
    QualifiedName(uri: NS_XSD, localName: "double"): "Double",
    QualifiedName(uri: NS_XSD, localName: "integer"): "Int", // undefined size
    QualifiedName(uri: NS_XSD, localName: "decimal"): "Decimal",

    QualifiedName(uri: NS_XSD, localName: "string"): "String",
    QualifiedName(uri: NS_XSD, localName: "anyURI"): "URL",
    QualifiedName(uri: NS_XSD, localName: "base64Binary"): "Data",
    QualifiedName(uri: NS_XSD, localName: "dateTime"): "Date",
    QualifiedName(uri: NS_XSD, localName: "duration"): "TimeInterval",
    QualifiedName(uri: NS_XSD, localName: "QName"): "QualifiedName",
    QualifiedName(uri: NS_XSD, localName: "anyType"): "Any",
]
