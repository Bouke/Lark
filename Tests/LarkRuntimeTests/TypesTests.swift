import Foundation
import XCTest

@testable import LarkRuntime

class TypesTests: XCTestCase {
    func testString() {
        test(value: "foo", serialized: "<test>foo</test>")
        test(value: "foo\nbar", serialized: "<test>foo\nbar</test>")
        test(value: "\"bar\"", serialized: "<test>\"bar\"</test>")
    }

    func testInt() {
        test(value: Int(-1234), serialized: "<test>-1234</test>")
        test(value: Int(0), serialized: "<test>0</test>")
        test(value: Int(1234), serialized: "<test>1234</test>")
    }

    func testUInt64() {
        test(value: UInt64(0), serialized: "<test>0</test>")
        test(value: UInt64(1234), serialized: "<test>1234</test>")
    }

    func testInt64() {
        test(value: Int64(-1234), serialized: "<test>-1234</test>")
        test(value: Int64(0), serialized: "<test>0</test>")
        test(value: Int64(1234), serialized: "<test>1234</test>")
    }

    func testDecimal() {
        test(value: Decimal(0), serialized: "<test>0</test>")
        test(value: Decimal(0.00), serialized: "<test>0</test>")
        test(value: Decimal(-12.34), serialized: "<test>-12.34</test>")
        test(value: Decimal(12.34), serialized: "<test>12.34</test>")
        test(value: Decimal(-1234), serialized: "<test>-1234</test>")
        test(value: Decimal(1234), serialized: "<test>1234</test>")
    }
}

func test<T>(value: T, serialized: String, file: StaticString = #file, line: UInt = #line) where T: XMLSerializable, T: XMLDeserializable, T: Equatable {
    do {
        let element = XMLElement(name: "test")
        try value.serialize(element)
        XCTAssertEqual(element.xmlString, serialized, file: file, line: line)
        let deserialized = try T(deserialize: element)
        XCTAssertEqual(deserialized, value, file: file, line: line)
    } catch {
        XCTFail("Failed with error: \(error)", file: file, line: line)
    }
}
