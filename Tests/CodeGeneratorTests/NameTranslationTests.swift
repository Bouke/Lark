@testable import CodeGenerator
import Foundation
import XCTest

class NameTranslationTests: XCTestCase {
    func testCamelCase() {
        XCTAssertEqual("HTTP".toSwiftPropertyName(), "http")
        XCTAssertEqual("HelloWorld".toSwiftPropertyName(), "helloWorld")
        XCTAssertEqual("PreHTTPAuthentication".toSwiftPropertyName(), "preHTTPAuthentication")
    }

    func testInvalidCharacters() {
//        XCTAssertEqual("PULL-REQUEST".toSwiftPropertyName(), "pullRequest")
//        XCTAssertEqual("PULL_REQUEST".toSwiftPropertyName(), "pullRequest")
    }
}
