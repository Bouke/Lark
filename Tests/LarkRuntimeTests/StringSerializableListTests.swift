import Foundation
import XCTest

@testable import LarkRuntime

fileprivate struct _Foo: StringSerializableList {
    enum Item: String, StringSerializable, StringDeserializable {
        case bar, baz
        init(string: String) throws {
            self.init(rawValue: string)!
        }
        func serialize() throws -> String {
            return rawValue
        }
    }
    var _contents: [Item]
    init(_ contents: [Item]) {
        self._contents = contents
    }
}

class StringSerializableListTests: XCTestCase {
    func testDeserialize() throws {
        let xml = XMLElement(name: "list", stringValue: "bar baz")
        let actual = try _Foo(deserialize: xml)
        let expected: _Foo = [.bar, .baz]
        XCTAssert(actual == expected)
    }

    func testSerialize() throws {
        let list = _Foo([.bar, .baz])
        let actual = XMLElement(name: "list")
        try list.serialize(actual)
        let expected = XMLElement(name: "list", stringValue: "bar baz")
        XCTAssertEqual(actual.xmlString, expected.xmlString)
    }
}
