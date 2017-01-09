import Foundation
import XCTest

@testable import SchemaParser
@testable import CodeGenerator

func XCTAssertCode(actual: [String], expected: [String], file: StaticString = #file, line: UInt = #line) {
    if actual == expected {
        return
    }
    XCTFail("Generated code did not match expectations", file: file, line: line)
    let toCharacters: ((String) -> [String]) = { $0.characters.map({ "\($0)" }) }
    let actual = toCharacters(actual.joined(separator: "\n"))
    let expected = toCharacters(expected.joined(separator: "\n"))
    let changes = simplediff(before: expected, after: actual)
    for change in changes {
        print(change.description, terminator: "")
    }
}
