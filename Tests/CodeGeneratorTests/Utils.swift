import Foundation
import XCTest

@testable import SchemaParser
@testable import CodeGenerator

func fixture(_ input: String) -> URL {
    return URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Inputs").appendingPathComponent(input)
}

func deserialize(_ input: String) throws -> Schema {
    let url = fixture(input)
    return try parseSchema(contentsOf: url)
}

func deserializeWebServiceDescription(_ input: String) throws -> WebServiceDescription {
    let url = fixture(input)
    return try parseWebServiceDescription(contentsOf: url)
}

func readlines(_ input: String) throws -> [String] {
    let url = fixture(input)
    return Array(try String(contentsOf: url).components(separatedBy: "\n").dropLast())
}

func readlines(_ url: URL) throws -> [String] {
    return Array(try String(contentsOf: url).components(separatedBy: "\n").dropLast())
}

func XCTAssertCode(definitionFile: URL, expectedCodeFile: URL, file: StaticString = #file, line: UInt = #line) {
    do {
        let webService = try parseWebServiceDescription(contentsOf: definitionFile)
        let expected = try readlines(expectedCodeFile)
        let actual = try generate(webService: webService, service: webService.services.first!).components(separatedBy: "\n")
        XCTAssertCode(actual: actual, expected: expected)
    } catch {
        XCTFail("Error was thrown; \(error)", file: file, line: line)
    }
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
