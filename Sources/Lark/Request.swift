import Alamofire
import Foundation

public struct Request<T> {
    var request: DataRequest
    var responseDeserializer: (Envelope) throws -> T

    @discardableResult
    public func response(
        completionHandler: @escaping ((Response<T>) -> Void))
        -> Request
    {
        request
            .validate(contentType: ["text/xml"])
            .validate(statusCode: 200...200) // todo: write custom validator for SoapFault
            .response(responseSerializer: EnvelopeDeserializer()) { originalResponse in
                let response = Response(
                    request: self,
                    result: originalResponse.result.map { try self.responseDeserializer($0) }
                )
                completionHandler(response)
            }
        return self
    }
}
