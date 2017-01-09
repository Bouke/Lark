import Foundation
import SchemaParser


extension WSDL {
    enum Node {
        case service(QualifiedName)
        case binding(QualifiedName)
        case port(QualifiedName)
        case operation(QualifiedName)
        case message(QualifiedName)
        case element(QualifiedName)
        case type(QualifiedName)

        var element: QualifiedName? {
            if case let .element(name) = self {
                return name
            } else {
                return nil
            }
        }
    }

    typealias Graph = CodeGenerator.Graph<Node>
    typealias Edge = (from: Node, to: Node)

    public func verify() throws {
        var nodes = Set<Node>()
        var edges: [Edge] = []

        nodes.formUnion(services.map { .service($0.name) })
        edges.append(contentsOf: services
            .flatMap { service in
                service.ports.map { port in
                    (from: .service(service.name), to: .binding(port.binding))
                }
            }
        )

        nodes.formUnion(bindings.map { .binding($0.name) })
        edges.append(contentsOf: bindings.map { (from: .binding($0.name), to: .port($0.type)) })
        edges.append(contentsOf: bindings
            .flatMap { binding in
                binding.operations.map { operation in
                    (from: .binding(binding.name), to: .operation(operation.name))
                }
            }
        )

        nodes.formUnion(portTypes.map { .port($0.name) })
        edges.append(contentsOf: portTypes
            .flatMap { portType in
                portType.operations.flatMap { operation in
                    [(from: .port(portType.name), to: .operation(operation.name)),
                     (from: .port(portType.name), to: .message(operation.inputMessage)),
                     (from: .port(portType.name), to: .message(operation.outputMessage))]
                }
            }
        )

//        nodes.formUnion(portTypes
//            .flatMap { $0.operations }
//            .map { .operation($0.name) }
//        )
//        edges.append(contentsOf: portTypes
//            .flatMap { $0.operations }
//            .flatMap { [($0.name, $0.inputMessage), ($0.name, $0.outputMessage)] }
//            .map { (from: .operation($0), to: .message($1)) }
//        )

        nodes.formUnion(messages.map { .message($0.name) })
        edges.append(contentsOf: messages
            .flatMap { message in
                message.parts.map { part in
                    (from: .message(message.name), to: .element(part.element))
                }
            }
        )

        nodes.formUnion(schema.flatMap { node in
            switch node {
            case let .element(element): return .element(element.name)
            case let .simpleType(simple): return .type(simple.name!)
            case let .complexType(complex): return .type(complex.name!)
            default: return nil
            }
        })

        edges.append(contentsOf: schema.flatMap { (node) -> [Edge] in
            switch node {
            case let .element(element): return createEdges(from: .element(element.name), to: element)
            case let .simpleType(simple): return createEdges(from: .type(simple.name!), to: simple)
            case let .complexType(complex): return createEdges(from: .type(complex.name!), to: complex)
            default: fatalError("unsupported node \(node)")
            }
        })

        var missing = Set<Node>()
        for edge in edges {
            if !nodes.contains(edge.from) {
                missing.insert(edge.from)
            }
            if !nodes.contains(edge.to) {
                missing.insert(edge.to)
            }
        }
        let baseNodes = baseTypes.keys.map { Node.type($0) }
        if missing.subtracting(baseNodes).count > 0 {
            throw GeneratorError.missingNodes(missing)
        }
    }

    func createEdges(from: Node, to simple: SimpleType) -> [Edge] {
        switch simple.content {
        case let .restriction(restriction): return [Edge(from: from, to: .type(restriction.base))]
        case let .list(itemType: itemType): return [Edge(from: from, to: .type(itemType))]
        case let .listWrapped(wrapped): return createEdges(from: from, to: wrapped)
        }
    }

    func createEdges(from: Node, to complex: ComplexType) -> [Edge] {
        switch complex.content {
        case let .sequence(sequence): return sequence.elements.flatMap { createEdges(from: from, to: $0) }
        case let .complex(complexContent): return createEdges(from: from, to: complexContent)
        case .empty: return []
        }
    }

    func createEdges(from: Node, to complex: ComplexType.Content.ComplexContent) -> [Edge] {
        var edges: [Edge] = [(from, .type(complex.base))]
        let content: ComplexType.Content.ComplexContent.Content.Content
        switch complex.content {
        case let .restriction(restriction): content = restriction
        case let .extension(`extension`): content = `extension`
        }
        switch content {
        case let .sequence(sequence): edges.append(contentsOf: sequence.elements.flatMap { createEdges(from: from, to: $0) })
        }
        return edges
    }

    func createEdges(from: Node, to element: Element) -> [Edge] {
        switch element.content {
        case let .base(base):
            return [Edge(from: from, to: .type(base))]
        case let .complex(complex):
            return createEdges(from: from, to: complex)
        }
    }
}

extension WSDL.Node: Equatable, Hashable {
    static func ==(lhs: WSDL.Node, rhs: WSDL.Node) -> Bool {
        switch(lhs, rhs) {
        case let (.service(lhs), .service(rhs)): return lhs == rhs
        case let (.binding(lhs), .binding(rhs)): return lhs == rhs
        case let (.port(lhs), .port(rhs)): return lhs == rhs
        case let (.operation(lhs), .operation(rhs)): return lhs == rhs
        case let (.message(lhs), .message(rhs)): return lhs == rhs
        case let (.element(lhs), .element(rhs)): return lhs == rhs
        case let (.type(lhs), .type(rhs)): return lhs == rhs
        default: return false
        }
    }

    var hashValue: Int {
        switch self {
        case let .service(qname): return qname.hashValue
        case let .binding(qname): return qname.hashValue
        case let .port(qname): return qname.hashValue
        case let .operation(qname): return qname.hashValue
        case let .message(qname): return qname.hashValue
        case let .element(qname): return qname.hashValue
        case let .type(qname): return qname.hashValue
        }
    }
}

extension WSDL.Node: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case let .service(qname): return ".service(\(qname.debugDescription))"
        case let .binding(qname): return ".binding(\(qname.debugDescription))"
        case let .port(qname): return ".port(\(qname.debugDescription))"
        case let .operation(qname): return ".operation(\(qname.debugDescription))"
        case let .message(qname): return ".message(\(qname.debugDescription))"
        case let .element(qname): return ".element(\(qname.debugDescription))"
        case let .type(qname): return ".type(\(qname.debugDescription))"
        }
    }
}
