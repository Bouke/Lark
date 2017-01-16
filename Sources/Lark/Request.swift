import Alamofire
import Foundation

public class Request<T> {
    let request: DataRequest
    let responseDeserializer: (Envelope) throws -> T

    public init(request: DataRequest, responseDeserializer: @escaping (Envelope) throws -> T) {
        self.request = request
        self.responseDeserializer = responseDeserializer
    }

    @discardableResult
    public func response(
        completionHandler: @escaping ((Response<T>) -> Void))
        -> Request
    {
        request
            .validate(contentType: ["text/xml"])
            .validate(statusCode: 200...200) // todo: write custom validator for SoapFault
            .response(responseSerializer: EnvelopeDeserializer()) { originalResponse in

                // TODO: replace `Response<>` with `DataResponse<>`?
                let response = Response(
                    request: self.request,
                    response: originalResponse,
                    result: originalResponse.result.map { try self.responseDeserializer($0) }
                )
                completionHandler(response)
            }
        return self
    }
}
