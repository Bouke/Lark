import Foundation
import XCTest

extension XCTestCase {
    func expect(description: String? = nil, timeout: TimeInterval = 10, file: StaticString = #file, line: Int = #line, f: (XCTestExpectation) throws -> ()) rethrows {
        let future = expectation(description: description ?? "")
        try f(future)
        waitForExpectations(timeout: timeout)
    }
}
