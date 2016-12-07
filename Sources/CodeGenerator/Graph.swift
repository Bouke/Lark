import SchemaParser

struct Graph {
    enum Node {
        case operation(QualifiedName)
        case message(QualifiedName)
        case element(QualifiedName)
        case type(QualifiedName)
    }

    let nodes: Set<Node>
    typealias Edge = (from: Node, to: Node)
    let edges: [Edge]

    init(wsdl: WSDL) throws {
        var nodes = Set<Node>(baseTypes.keys.map { .type($0) })
        var edges: [(from: Node, to: Node)] = []

        nodes.formUnion(wsdl.portTypes
            .flatMap { $0.operations }
            .map { .operation($0.name) }
        )
        edges.append(contentsOf: wsdl.portTypes
            .flatMap { $0.operations }
            .flatMap { [($0.name, $0.inputMessage), ($0.name, $0.outputMessage)] }
            .map { (from: .operation($0), to: .message($1)) }
        )

        nodes.formUnion(wsdl.messages.map { .message($0.name) })
        edges.append(contentsOf: wsdl.messages
            .flatMap { message in
                message.parts.map { part in
                    (from: .message(message.name), to: .element(part.element))
                }
            }
        )

        nodes.formUnion(wsdl.schema.flatMap { node in
            switch node {
            case let .element(element): return .element(element.name)
            case let .simpleType(simple): return .type(simple.name!)
            case let .complexType(complex): return .type(complex.name!)
            default: return nil
            }
        })


        // todo: should add node's content (recursive)
        edges.append(contentsOf: wsdl.schema.flatMap { (node) -> [Edge] in
            switch node {
            case let .element(element): return Graph.createEdges(from: .element(element.name), to: element)
            case let .simpleType(simple): return Graph.createEdges(from: .type(simple.name!), to: simple)
            case let .complexType(complex): return Graph.createEdges(from: .type(complex.name!), to: complex)
            default: fatalError("unsupported node \(node)")
            }
        })

        self.nodes = nodes
        self.edges = edges

        try verify()
    }

    func edges(to: Node) -> Set<Node> {
        return Set(edges.filter { $0.to == to }.map { $0.from })
    }

    func edges(from: Node) -> Set<Node> {
        return Set(edges.filter { $0.from == from }.map { $0.to })
    }

    static func createEdges(from: Node, to simple: SimpleType) -> [Edge] {
        switch simple.content {
        case let .restriction(restriction): return [Edge(from: from, to: .type(restriction.base))]
        case let .list(itemType: itemType): return [Edge(from: from, to: .type(itemType))]
        case let .listWrapped(wrapped): return createEdges(from: from, to: wrapped)
        }
    }

    static func createEdges(from: Node, to complex: ComplexType) -> [Edge] {
        switch complex.content {
        case let .sequence(sequence): return sequence.elements.flatMap { createEdges(from: from, to: $0) }
        case .empty: return []
        }
    }

    static func createEdges(from: Node, to element: Element) -> [Edge] {
        switch element.content {
        case let .base(base):
            return [Edge(from: from, to: .type(base))]
        case let .complex(complex):
            return createEdges(from: from, to: complex)
        }
    }


    func verify() throws {
        var missing = Set<Node>()
        for edge in edges {
            if !nodes.contains(edge.from) {
                missing.insert(edge.from)
            }
            if !nodes.contains(edge.to) {
                missing.insert(edge.to)
            }
        }
        if missing.count > 0 {
            throw GeneratorError.missingNodes(missing)
        }
    }
}

extension Graph.Node: Equatable, Hashable {
    static func ==(lhs: Graph.Node, rhs: Graph.Node) -> Bool {
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

extension Graph.Node: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case let .operation(qname): return ".operation(\(qname.debugDescription))"
        case let .message(qname): return ".message(\(qname.debugDescription))"
        case let .element(qname): return ".element(\(qname.debugDescription))"
        case let .type(qname): return ".type(\(qname.debugDescription))"
        }
    }
}
