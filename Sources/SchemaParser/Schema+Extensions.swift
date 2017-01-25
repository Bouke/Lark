import Foundation

extension Element: Equatable {
    public static func ==(lhs: Element, rhs: Element) -> Bool {
        return lhs.name == rhs.name && lhs.content == rhs.content
    }
}

extension Element: Hashable {
    public var hashValue: Int {
        return name.hashValue
    }
}

extension Element.Content: Equatable {
    public static func ==(lhs: Element.Content, rhs: Element.Content) -> Bool {
        switch (lhs, rhs) {
        case let (.base(lhs), .base(rhs)): return lhs == rhs
        case let (.complex(lhs), .complex(rhs)): return lhs == rhs
        default: return false
        }
    }
}

extension ComplexType: Equatable {
    public static func ==(lhs: ComplexType, rhs: ComplexType) -> Bool {
        return lhs.name == rhs.name && lhs.content == rhs.content
    }
}

extension ComplexType.Content: Equatable {
    public static func ==(lhs: ComplexType.Content, rhs: ComplexType.Content) -> Bool {
        switch (lhs, rhs) {
        case let (.sequence(lhs), .sequence(rhs)): return lhs == rhs
        case (.empty, .empty): return true
        default: return false
        }
    }
}

extension ComplexType.Content.Sequence: Equatable {
    public static func ==(lhs: ComplexType.Content.Sequence, rhs: ComplexType.Content.Sequence) -> Bool {
        return lhs.elements == rhs.elements
    }
}
