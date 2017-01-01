import Foundation
import SchemaParser

enum GeneratorError: Error {
    case missingTypes(Set<QualifiedName>)
    case messageNotFound(QualifiedName)
    case missingNodes(Set<WSDL.Node>)
}

typealias TypeMapping = [WSDL.Node: Identifier]
typealias Types = [WSDL.Node: SwiftMetaType]

enum ElementHierarchy {
    typealias Node = WSDL.Node
    typealias Edge = (from: Node, to: Node)
    typealias Graph = CodeGenerator.Graph<Node>
}

struct ClassHierarchy {
    typealias Node = String
    typealias Edge = (from: Node, to: Node)
    typealias Graph = CodeGenerator.Graph<Node>
}

public func generate(wsdl: WSDL, service: Service, binding: Binding) throws -> String {
    // This graph is only used for verification.
    // TODO: deprecate this graph, or restrict usage. We used it to calculate "connectedNodes",
    // but it introduces a lot of complexity. Simple replace it with the HierarchyGraph.
    let graph = try wsdl.createGraph()
    let connectedNodes = graph.connectedNodes

    // Assign unique names to all nodes. First, elements are given a name. Sometimes
    // elements have the same name as their implementing types, and we give give preference
    // to elements.

    // We'll build the classes from top-to-bottom. So build the inheritance hierarchy
    // of the classes.

    // Note that we could collapse elements having only a base type. At the moment we handle
    // this using inheritance.

    var mapping = baseTypes.dictionary { (WSDL.Node.type($0), $1) }
    var scope = Set<String>()
    var hierarchy = ElementHierarchy.Graph()

    let elements = wsdl.schema.flatMap { $0.element }.dictionary { ($0.name, $0) }
    let complexes = wsdl.schema.flatMap { $0.complexType }.dictionary { ($0.name!, $0) }
    let simples = wsdl.schema.flatMap { $0.simpleType }.dictionary { ($0.name!, $0) }

    for case let .element(name) in connectedNodes {
        let className = name.localName.toSwiftTypeName()
        guard !scope.contains(className) else {
            fatalError("Element name must be unique")
        }
        mapping[.element(name)] = className
        scope.insert(className)

        switch elements[name]!.content {
        case let .base(base): hierarchy.insertEdge((.element(name), .type(base)))
        case .complex: hierarchy.nodes.insert(.element(name))
        }
    }

    // TODO: add these nodes to hierarchy as well.
    for case let .type(node) in connectedNodes {
        let className: String
        let baseName = node.localName.toSwiftTypeName()
        if !scope.contains(baseName) {
            className = baseName
        } else if !scope.contains("\(baseName)Type") {
            className = "\(baseName)Type"
        } else {
            className = (2...Int.max).lazy.map { "\(baseName)Type\($0)" }.first { !scope.contains($0) }!
        }
        mapping[.type(node)] = className
        scope.insert(className)
    }

    for case let .simpleType(type) in wsdl.schema {
        switch type.content {
        case let .list(itemType: itemType): hierarchy.insertEdge((.type(type.name!), .type(itemType)))
        default: break
        }
    }

    var types: [WSDL.Node: SwiftMetaType] = [:]
    for node in hierarchy.traverse {
        switch node {
        case let .element(name):
            types[node] = elements[name]!.toSwift(mapping: mapping, types: types)
        case let .type(name):
            if let complex = complexes[name] {
                types[node] = complex.toSwift(mapping: mapping, types: types)
            } else if let simple = simples[name] {
                types[node] = simple.toSwift(mapping: mapping, types: types)
            } else {
                fallthrough
            }
        default:
            fatalError("unsupported type")
        }
    }

    var clients = [SwiftClientClass]()
    for service in wsdl.services {
        clients.append(service.toSwift(wsdl: wsdl))
    }

    return SwiftCodeGenerator.generateCode(for: Array(types.values), clients)
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
