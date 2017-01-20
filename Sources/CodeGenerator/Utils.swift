import Foundation

extension NSRegularExpression {
    func matches(`in` string: String, options: NSRegularExpression.MatchingOptions = []) -> [String] {
        let range = NSRange(location: 0, length: string.utf16.count)
        return self.matches(in: string, options: options, range: range).map {
            let start = String.UTF16Index($0.range.location)
            let end = String.UTF16Index($0.range.location + $0.range.length)
            return String(string.utf16[start..<end])!
        }
    }
}
