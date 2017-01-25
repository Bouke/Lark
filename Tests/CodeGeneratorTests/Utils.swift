import Foundation
import XCTest

@testable import SchemaParser
@testable import CodeGenerator

func deserialize(_ input: String) throws -> Schema {
    let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Inputs").appendingPathComponent(input)
    return try parseSchema(contentsOf: url)
}

func readlines(_ input: String) throws -> [String] {
    let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Inputs").appendingPathComponent(input)
    return Array(try String(contentsOf: url).components(separatedBy: "\n").dropLast())
}

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
