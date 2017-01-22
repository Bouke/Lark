import XCTest

@testable import CodeGenerator
@testable import Lark
@testable import SchemaParser

class SwiftTypeTests: XCTestCase {
    let NS = "http://tempuri.org/"
    let STRING = QualifiedName(uri: NS_XSD, localName: "string")

    func qname(_ name: String) -> QualifiedName {
        return QualifiedName(uri: NS, localName: name)
    }

    func testOptional() {
        let element = Element(name: qname("foo"), content: .base(STRING), occurs: 0..<1, nillable: false)
        let type = SwiftType(type: "String", element: element)
        XCTAssertEqual(type, SwiftType.optional(.identifier("String")))
    }

    func testNillableIdentifer() {
        let element = Element(name: qname("foo"), content: .base(STRING), occurs: 1..<1, nillable: true)
        let type = SwiftType(type: "String", element: element)
        XCTAssertEqual(type, SwiftType.nillable(.identifier("String")))
    }

    func testNillableArray() {
        let element = Element(name: qname("foo"), content: .base(STRING), occurs: 0..<Int.max, nillable: true)
        let type = SwiftType(type: "String", element: element)
        XCTAssertEqual(type, SwiftType.nillable(.array(.identifier("String"))))
    }
}
