public enum Result<T> {
    case success(T)
    case failure(Error)

    public var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    public var isFailure: Bool {
        return !isSuccess
    }

    public var value: T? {
        switch self {
        case let .success(value): return value
        case .failure: return nil
        }
    }

    public var error: Error? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }

    public func resolve() throws -> T {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func map<U>(_ f: (T) throws -> U) -> Result<U> {
        do {
            return .success(try f(resolve()))
        } catch {
            return .failure(error)
        }
    }
}
