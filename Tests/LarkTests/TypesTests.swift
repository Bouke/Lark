import Foundation
import XCTest

@testable import Lark

class TypesTests: XCTestCase {
    func testString() {
        test(value: "foo", expected: "<test>foo</test>")
        test(value: "foo\nbar", expected: "<test>foo\nbar</test>")
        test(value: "\"bar\"", expected: "<test>\"bar\"</test>")
    }

    func testBool() {
        test(value: Bool(true), expected: "<test>true</test>")
        test(value: Bool(false), expected: "<test>false</test>")
        test(serialized: "<test>1</test>", expected: Bool(true))
        test(serialized: "<test>0</test>", expected: Bool(false))
    }

    func testInt() {
        test(value: Int(-1234), expected: "<test>-1234</test>")
        test(value: Int(0), expected: "<test>0</test>")
        test(value: Int(1234), expected: "<test>1234</test>")
    }

    func testInt32() {
        test(value: Int32(-1234), expected: "<test>-1234</test>")
        test(value: Int32(0), expected: "<test>0</test>")
        test(value: Int32(1234), expected: "<test>1234</test>")
    }

    func testUInt64() {
        test(value: UInt64(0), expected: "<test>0</test>")
        test(value: UInt64(1234), expected: "<test>1234</test>")
    }

    func testInt64() {
        test(value: Int64(-1234), expected: "<test>-1234</test>")
        test(value: Int64(0), expected: "<test>0</test>")
        test(value: Int64(1234), expected: "<test>1234</test>")
    }

    func testDecimal() {
        test(value: Decimal(0), expected: "<test>0</test>")
        test(value: Decimal(0.0), expected: "<test>0</test>")
        test(value: Decimal(-12.34), expected: "<test>-12.34</test>")
        test(value: Decimal(12.34), expected: "<test>12.34</test>")
        test(value: Decimal(-1234), expected: "<test>-1234</test>")
        test(value: Decimal(1234), expected: "<test>1234</test>")
    }

    func testDouble() {
        test(value: Double(0), expected: "<test>0.0</test>")
        test(value: Double(0.0), expected: "<test>0.0</test>")
        test(value: Double(-12.34), expected: "<test>-12.34</test>")
        test(value: Double(12.34), expected: "<test>12.34</test>")
        test(value: Double(-1234), expected: "<test>-1234.0</test>")
        test(value: Double(1234), expected: "<test>1234.0</test>")
    }

    func testData() {
        test(value: Data(base64Encoded: "deadbeef")!, expected: "<test>deadbeef</test>")
        test(value: Data(), expected: "<test></test>")
    }
}


/// Asserts that the given serialization deserializes into the expected value
///
/// - Parameters:
///   - serialized: String XML element
///   - expected: T expected value
///   - file: (set automatically)
///   - line: (set automatically)
func test<T>(serialized: String, expected: T, file: StaticString = #file, line: UInt = #line) where T: XMLSerializable, T: XMLDeserializable, T: Equatable {
    do {
        let element = try XMLElement(xmlString: serialized)
        let actual = try T(deserialize: element)
        XCTAssertEqual(actual, expected, file: file, line: line)
    } catch {
        XCTFail("Failed with error: \(error)", file: file, line: line)
    }
}


/// Asserts that the given value serializes into the expected serialization, and deserializes back to the original value
///
/// - Parameters:
///   - value: T value to test
///   - expected: String expected XML serialization
///   - file: (set automatically)
///   - line: (set automatically)
func test<T>(value: T, expected: String, file: StaticString = #file, line: UInt = #line) where T: XMLSerializable, T: XMLDeserializable, T: Equatable {
    do {
        let element = XMLElement(name: "test")
        try value.serialize(element)
        XCTAssertEqual(element.xmlString, expected, file: file, line: line)
        let deserialized = try T(deserialize: element)
        XCTAssertEqual(deserialized, value, file: file, line: line)
    } catch {
        XCTFail("Failed with error: \(error)", file: file, line: line)
    }
}
