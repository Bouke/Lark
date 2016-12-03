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

extension Complex: Equatable {
    public static func ==(lhs: Complex, rhs: Complex) -> Bool {
        return lhs.name == rhs.name && lhs.content == rhs.content
    }
}

extension Complex.Content: Equatable {
    public static func ==(lhs: Complex.Content, rhs: Complex.Content) -> Bool {
        switch (lhs, rhs) {
        case let (.sequence(lhs), .sequence(rhs)): return lhs == rhs
        case (.empty, .empty): return true
        default: return false
        }
    }
}

extension Complex.Content.Sequence: Equatable {
    public static func ==(lhs: Complex.Content.Sequence, rhs: Complex.Content.Sequence) -> Bool {
        return lhs.elements == rhs.elements
    }
}
