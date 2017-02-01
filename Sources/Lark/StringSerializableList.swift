import Foundation

public protocol StringSerializableList: XMLDeserializable, XMLSerializable, Sequence, Collection, ExpressibleByArrayLiteral {
    associatedtype Element: StringDeserializable, StringSerializable

    var _contents: [Element] { get }
    init(_: [Element])
}

/// XMLDeserializable
extension StringSerializableList {
    public init(deserialize element: XMLElement) throws {
        self.init(try element.stringValue!.components(separatedBy: " ").map(Element.init(string:)))
    }
}

/// XMLSerializable
extension StringSerializableList {
    public func serialize(_ element: XMLElement) throws {
        element.stringValue = try _contents.map { try $0.serialize() }.joined(separator: " ")
    }
}

/// Sequence
extension StringSerializableList {
    public func makeIterator() -> IndexingIterator<[Self.Element]> {
        return _contents.makeIterator()
    }
}

/// Collection
extension StringSerializableList {
    public var startIndex: Int {
        return _contents.startIndex
    }
    public var endIndex: Int {
        return _contents.endIndex
    }
    public func index(after i: Int) -> Int {
        return _contents.index(after: i)
    }
    public subscript(position: Int) -> Element {
        return _contents[position]
    }
}

/// ExpressibleByArrayLiteral
extension StringSerializableList {
    public init(arrayLiteral elements: Self.Element...) {
        self.init(elements)
    }
}

extension StringSerializableList where Element: Equatable {
    /// Returns `true` if these lists contain the same elements.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs._contents == rhs._contents
    }
}
