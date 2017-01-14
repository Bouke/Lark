import Foundation

public struct Request<T> {
    var responseDeserializer: (Envelope) -> Result<T>

    @discardableResult
    public func response(
        completionHandler: ((Response<T>) -> Void)
        )
        -> Request
    {
        // TODO: call completionHandler
        return self
    }
}

public struct Response<T> {
    public var result: Result<T>
}
