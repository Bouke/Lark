import SchemaParser

struct Graph<T: Hashable> {
    typealias Node = T
    var nodes: Set<Node>

    typealias Edge = (from: T, to: T)
    var edges: [Edge]

    init(nodes: Set<Node>? = nil, edges: [Edge] = []) {
        self.nodes = nodes ?? Set(edges.flatMap { [$0.from, $0.to] })
        self.edges = edges
    }

    mutating func insertEdge(_ edge: Edge) {
        nodes.insert(edge.from)
        nodes.insert(edge.to)
        edges.append(edge)
    }

    var connectedNodes: Set<Node> {
        return nodes.intersection(edges.flatMap { [$0.from, $0.to] })
    }

    func edges(to: Node) -> Set<Node> {
        return Set(edges.filter { $0.to == to }.map { $0.from })
    }

    func edges(from: Node) -> Set<Node> {
        return Set(edges.filter { $0.from == from }.map { $0.to })
    }
}


extension WSDL {
    enum Node {
        case operation(QualifiedName)
        case message(QualifiedName)
        case element(QualifiedName)
        case type(QualifiedName)
    }

    typealias Graph = CodeGenerator.Graph<Node>
    typealias Edge = (from: Node, to: Node)
    
    func createGraph() throws -> Graph {
        var nodes = Set<Node>()
        var edges: [Edge] = []

        nodes.formUnion(portTypes
            .flatMap { $0.operations }
            .map { .operation($0.name) }
        )
        edges.append(contentsOf: portTypes
            .flatMap { $0.operations }
            .flatMap { [($0.name, $0.inputMessage), ($0.name, $0.outputMessage)] }
            .map { (from: .operation($0), to: .message($1)) }
        )

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

        // todo: should add node's content (recursive)
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

        return Graph(nodes: nodes, edges: edges)
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
        case .empty: return []
        }
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
        case let (.operation(lhs), .operation(rhs)): return lhs == rhs
        case let (.message(lhs), .message(rhs)): return lhs == rhs
        case let (.element(lhs), .element(rhs)): return lhs == rhs
        case let (.type(lhs), .type(rhs)): return lhs == rhs
        default: return false
        }
    }

    var hashValue: Int {
        switch self {
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
        case let .operation(qname): return ".operation(\(qname.debugDescription))"
        case let .message(qname): return ".message(\(qname.debugDescription))"
        case let .element(qname): return ".element(\(qname.debugDescription))"
        case let .type(qname): return ".type(\(qname.debugDescription))"
        }
    }
}
