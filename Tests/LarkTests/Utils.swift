import Foundation
import XCTest

//enum Result<T> {
//    case success(T)
//    case failure(Error)
//
//    init(_ value: T) {
//        self = .success(value)
//    }
//
//    init(_ error: Error) {
//        self = .failure(error)
//    }
//
//    func resolve() throws -> T {
//        switch self {
//        case .success(let value): return value
//        case .failure(let error): throw error
//        }
//    }
//}

extension XCTestCase {
    func expect(description: String? = nil, timeout: TimeInterval = 10, file: StaticString = #file, line: Int = #line, f: (XCTestExpectation) throws -> ()) rethrows {
        let future = expectation(description: description ?? "")
        try f(future)
        waitForExpectations(timeout: timeout)
    }
}
