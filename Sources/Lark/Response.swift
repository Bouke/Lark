import Alamofire
import Foundation

public struct Response<T> {
    public let request: Request<T>
    public let result: Alamofire.Result<T>
}
