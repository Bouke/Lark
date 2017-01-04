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

    var traverse: AnyIterator<Node> {
        var remaining = nodes
        var seen = Set<Node>()
        return AnyIterator {
            guard let next = remaining.first(where: { node in self.edges(from: node).isSubset(of: seen) }) else {
                if remaining.count != 0 { fatalError("Did not traverse complete graph") }
                return nil
            }
            remaining.remove(next)
            seen.insert(next)
            return next
        }
    }
}
