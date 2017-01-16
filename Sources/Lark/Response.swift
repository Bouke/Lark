import Alamofire
import Foundation

public struct Response<T> {
    public let request: DataRequest
    public let response: DataResponse<Envelope>
    public let result: Alamofire.Result<T>
}
