import Foundation
import XCTest

@testable import Lark

extension XMLDeserializable {
    init(deserialize xmlString: String) throws {
        let element = try XMLElement(xmlString: xmlString)
        self = try Self(deserialize: element)
    }
}

class TypesTests: XCTestCase {

    //MARK: Signed integers

    func testInt8() {
        test(value: Int8(-128), expected: "<test>-128</test>")
        test(value: Int8(0), expected: "<test>0</test>")
        test(value: Int8(127), expected: "<test>127</test>")
        testFails(try Int8(deserialize: "<test>abc</test>"))
        testFails(try Int8(deserialize: "<test>128</test>"))
        testFails(try Int8(deserialize: "<test/>"))
    }

    func testInt16() {
        test(value: Int16(-1234), expected: "<test>-1234</test>")
        test(value: Int16(0), expected: "<test>0</test>")
        test(value: Int16(1234), expected: "<test>1234</test>")
    }

    func testInt32() {
        test(value: Int32(-1234), expected: "<test>-1234</test>")
        test(value: Int32(0), expected: "<test>0</test>")
        test(value: Int32(1234), expected: "<test>1234</test>")
    }

    func testInt64() {
        test(value: Int64(-1234), expected: "<test>-1234</test>")
        test(value: Int64(0), expected: "<test>0</test>")
        test(value: Int64(1234), expected: "<test>1234</test>")
    }

    //MARK: Unsigned integers

    func testUInt8() {
        test(value: UInt8(0), expected: "<test>0</test>")
        test(value: UInt8(127), expected: "<test>127</test>")
    }

    func testUInt16() {
        test(value: UInt16(0), expected: "<test>0</test>")
        test(value: UInt16(1234), expected: "<test>1234</test>")
    }

    func testUInt32() {
        test(value: UInt32(0), expected: "<test>0</test>")
        test(value: UInt32(1234), expected: "<test>1234</test>")
    }

    func testUInt64() {
        test(value: UInt64(0), expected: "<test>0</test>")
        test(value: UInt64(1234), expected: "<test>1234</test>")
    }

    //MARK: Numeric types

    func testBool() {
        test(value: Bool(true), expected: "<test>true</test>")
        test(value: Bool(false), expected: "<test>false</test>")
        test(serialized: "<test>1</test>", expected: Bool(true))
        test(serialized: "<test>0</test>", expected: Bool(false))
    }

    func testFloat() {
        test(value: Float(0), expected: "<test>0.0</test>")
        test(value: Float(0.0), expected: "<test>0.0</test>")
        test(value: Float(-12.34), expected: "<test>-12.34</test>")
        test(value: Float(12.34), expected: "<test>12.34</test>")
        test(value: Float(-1234), expected: "<test>-1234.0</test>")
        test(value: Float(1234), expected: "<test>1234.0</test>")
    }

    func testDouble() {
        test(value: Double(0), expected: "<test>0.0</test>")
        test(value: Double(0.0), expected: "<test>0.0</test>")
        test(value: Double(-12.34), expected: "<test>-12.34</test>")
        test(value: Double(12.34), expected: "<test>12.34</test>")
        test(value: Double(-1234), expected: "<test>-1234.0</test>")
        test(value: Double(1234), expected: "<test>1234.0</test>")
    }

    func testInt() {
        test(value: Int(-1234), expected: "<test>-1234</test>")
        test(value: Int(0), expected: "<test>0</test>")
        test(value: Int(1234), expected: "<test>1234</test>")
    }

    func testDecimal() {
        test(value: Decimal(0), expected: "<test>0</test>")
        test(value: Decimal(0.0), expected: "<test>0</test>")
        test(value: Decimal(-12.34), expected: "<test>-12.34</test>")
        test(value: Decimal(12.34), expected: "<test>12.34</test>")
        test(value: Decimal(-1234), expected: "<test>-1234</test>")
        test(value: Decimal(1234), expected: "<test>1234</test>")
    }

    //MARK: Other types

    func testString() {
        test(value: "foo", expected: "<test>foo</test>")
        test(value: "foo\nbar", expected: "<test>foo\nbar</test>")
        test(value: "\"bar\"", expected: "<test>\"bar\"</test>")
    }

    func testURL() {
        test(value: URL(string: "http://swift.org")!, expected: "<test>http://swift.org</test>")
        test(value: URL(string: "ssh://github.com")!, expected: "<test>ssh://github.com</test>")
    }

    func testData() {
        test(value: Data(base64Encoded: "deadbeef")!, expected: "<test>deadbeef</test>")
        test(value: Data(), expected: "<test></test>")
    }

    func testDate() {
        test(value: Date(timeIntervalSinceReferenceDate: 0), expected: "<test>2001-01-01T01:00:00+01:00</test>")
        // test other timezone identifiers
        test(serialized: "<test>2001-01-01T00:00:00Z</test>", expected: Date(timeIntervalSinceReferenceDate: 0))
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


/// Asserts that the given xml cannot be deserialized
///
/// - Parameters:
///   - deserialization: statement that will be executed
///   - file: (set automatically)
///   - line: (set automatically)
func testFails<T>(_ deserialization: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) where T: XMLSerializable, T: XMLDeserializable, T: Equatable {
    do {
        _ = try deserialization()
        XCTFail("Deserialization should have failed", file: file, line: line)
    } catch { }
}
