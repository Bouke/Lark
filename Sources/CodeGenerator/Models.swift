import Foundation
import SchemaParser

// MARK:- SOAP Types

indirect enum SwiftType {
    case identifier(Identifier)
    case optional(SwiftType)
    case array(SwiftType)

    init(type: String, element: Element) {
        switch (element.occurs?.startIndex, element.occurs?.endIndex) {
        case (0?, 1?): self = .optional(.identifier(type))
        case (nil, nil), (1?, 1?): self = .identifier(type)
        default: self = .array(.identifier(type))
        }
    }
}

struct SwiftProperty {
    let name: String
    let type: SwiftType
    let element: Element
}

public protocol SwiftMetaType: LinesOfCodeConvertible {
    var name: Identifier { get }
}

public class SwiftTypeClass: SwiftMetaType {
    public let name: Identifier
    let base: SwiftTypeClass?
    let protocols: [String]
    let properties: [SwiftProperty]
    let nestedTypes: [SwiftMetaType]
    let members: [LinesOfCodeConvertible]

    init(name: String, base: SwiftTypeClass? = nil, protocols: [String] = [], properties: [SwiftProperty] = [], nestedTypes: [SwiftMetaType] = [], members: [LinesOfCodeConvertible] = []) {
        self.name = name
        self.base = base
        self.protocols = protocols
        self.properties = properties
        self.nestedTypes = nestedTypes
        self.members = members
    }
}

public struct SwiftEnum: SwiftMetaType {
    public let name: Identifier
    let rawType: SwiftType
    let cases: [String: String]
}

public struct SwiftParameter {
    let name: Identifier
    let type: SwiftType
}


// MARK:- SOAP Client

public struct SwiftClientClass: SwiftMetaType {
    public let name: Identifier
    let methods: [ServiceMethod]
    let port: Service.Port
}

struct ServiceMethod {
    typealias Message = (element: QualifiedName, type: Identifier)

    let name: Identifier
    let input: Message
    let output: Message
    let action: URL?

    init(operation: PortType.Operation, input: Message, output: Message, action: URL?) {
        name = operation.name.localName.toSwiftPropertyName()
        self.input = input
        self.output = output
        self.action = action
    }
}
