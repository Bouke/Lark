import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)

    init(_ value: T) {
        self = .success(value)
    }

    init(_ error: Error) {
        self = .failure(error)
    }

    func resolve() throws -> T {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
