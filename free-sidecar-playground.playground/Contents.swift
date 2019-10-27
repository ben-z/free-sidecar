import UIKit
import Foundation
import SwiftUI
import PlaygroundSupport


var str = "Hello, playground"

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

let hexDict = [
    "iPad": Data("iPad".utf8).hexEncodedString(options: [.upperCase]),
    ",": Data(",".utf8).hexEncodedString(options: [.upperCase]),
    " ": "00",
]


["1","2","3"][0]

Button(action: {}) {
    Text("Default padding")
}
.padding()
.background(Color.yellow)

String(123)
