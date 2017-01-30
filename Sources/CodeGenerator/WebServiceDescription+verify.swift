import Foundation
import SchemaParser
import Lark

extension WebServiceDescription {
    enum Node {
        case service(QualifiedName)
        case binding(QualifiedName)
        case port(QualifiedName)
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

    /// Verifies whether all type references are valid. It will construct a 
    /// graph having edges for all references and nodes for all types. The set
    /// of missing nodes is calculated by comparing the actual nodes with the
    /// references nodes. The set of base XML Schema types are subtracted. If
    /// the remaining set of missing nodes is greater then 0, an error will be
    /// thrown.
    ///
    /// - Throws: WebServiceDescriptionVerifyError.missingNodes(Set<Node>)
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

        nodes.formUnion(portTypes.map { .port($0.name) })
        edges.append(contentsOf: portTypes
            .flatMap { portType in
                portType.operations.flatMap { operation in
                    [(from: .port(portType.name), to: .message(operation.inputMessage)),
                     (from: .port(portType.name), to: .message(operation.outputMessage))]
                }
            }
        )

        nodes.formUnion(messages.map { .message($0.name) })
        edges.append(contentsOf: messages
            .flatMap { message -> [Edge] in
                message.parts.flatMap { part -> Edge? in
                    if let element = part.element {
                        return (from: .message(message.name), to: .element(element))
                    } else if let type = part.type {
                        return (from: .message(message.name), to: .type(type))
                    } else {
                        return nil
                    }
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
        missing.subtract(baseNodes)
        if missing.count > 0 {
            throw WebServiceDescriptionVerifyError.missingNodes(missing)
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

extension WebServiceDescription.Node: Equatable, Hashable {
    static func ==(lhs: WebServiceDescription.Node, rhs: WebServiceDescription.Node) -> Bool {
        switch(lhs, rhs) {
        case let (.service(lhs), .service(rhs)): return lhs == rhs
        case let (.binding(lhs), .binding(rhs)): return lhs == rhs
        case let (.port(lhs), .port(rhs)): return lhs == rhs
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
        case let .message(qname): return qname.hashValue
        case let .element(qname): return qname.hashValue
        case let .type(qname): return qname.hashValue
        }
    }
}

extension WebServiceDescription.Node: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case let .service(qname): return ".service(\(qname.debugDescription))"
        case let .binding(qname): return ".binding(\(qname.debugDescription))"
        case let .port(qname): return ".port(\(qname.debugDescription))"
        case let .message(qname): return ".message(\(qname.debugDescription))"
        case let .element(qname): return ".element(\(qname.debugDescription))"
        case let .type(qname): return ".type(\(qname.debugDescription))"
        }
    }
}

enum WebServiceDescriptionVerifyError: Error {
    case missingNodes(Set<WebServiceDescription.Node>)
}

extension WebServiceDescriptionVerifyError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .missingNodes(nodes):
            return "WSDL is incomplete. WSDL contains references to the following missing nodes: \(nodes)."
        }
    }
}
