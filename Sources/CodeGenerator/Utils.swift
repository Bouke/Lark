import Foundation

extension NSRegularExpression {
    func matches(`in` string: String, options: NSRegularExpression.MatchingOptions = []) -> [String] {
        let ranges: [Range<String.Index>] = matches(in: string, options: options)
        return ranges.map {
            String(string[$0])
        }
    }

    func matches(`in` string: String, options: NSRegularExpression.MatchingOptions = []) -> [Range<String.Index>] {
        let range = NSRange(location: 0, length: string.utf16.count)
        return self.matches(in: string, options: options, range: range).flatMap {
            return Range<String.Index>($0.range, in: string)
        }
    }
}
