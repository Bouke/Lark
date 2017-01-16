import Alamofire
import Foundation

extension Result {
    public func resolve() throws -> Value {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func map<T>(_ f: (Value) throws -> T) -> Result<T> {
        do {
            return .success(try f(resolve()))
        } catch {
            return .failure(error)
        }
    }
}

extension DataRequest {
    @discardableResult
    func responseSOAP(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (_ response: DataResponse<Envelope>) -> Void)
        -> Self
    {
        return response(queue: queue, responseSerializer: EnvelopeDeserializer(), completionHandler: completionHandler)
    }
}
