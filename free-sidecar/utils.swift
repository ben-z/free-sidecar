//
//  utils.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2019-10-26.
//  Copyright © 2019 Ben Zhang. All rights reserved.
//

import Foundation

// https://qiita.com/fromage-blanc/items/15731a1d3e6be1c5f56f
extension UnicodeScalar {
    var hexNibble:UInt8 {
        let value = self.value
        if 48 <= value && value <= 57 {
            return UInt8(value - 48)
        }
        else if 65 <= value && value <= 70 {
            return UInt8(value - 55)
        }
        else if 97 <= value && value <= 102 {
            return UInt8(value - 87)
        }
        fatalError("\(self) not a legal hex nibble")
    }
}
extension Data {
    init(hex:String) {
        let scalars = hex.unicodeScalars
        var bytes = Array<UInt8>(repeating: 0, count: (scalars.count + 1) >> 1)
        for (index, scalar) in scalars.enumerated() {
            var nibble = scalar.hexNibble
            if index & 1 == 0 {
                nibble <<= 4
            }
            bytes[index >> 1] |= nibble
        }
        self = Data(bytes)
    }
}

// https://stackoverflow.com/a/40089462
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

struct StringMatchResult {
    let matchedStr: String
    let range: NSRange
}

extension String
{
    func match(pattern: String) -> [[StringMatchResult]]
    {
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        {
            let string = self as NSString

            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map { match in
                let res: Array<String> = Array(repeating: "", count: match.numberOfRanges)
                return res.enumerated().map { (idx, _) in
                    return StringMatchResult(matchedStr: string.substring(with: match.range(at: idx)), range: match.range(at: idx))
                }
            }
        }

        return []
    }
}

let devices = ["iMac", "MacBookAir", "MacBookPro", "Macmini", "MacPro", "MacBook", "iPad"]

let hexDict = [
    "iMac": Data("iMac".utf8).hexEncodedString(options: [.upperCase]),
    "MacBook": Data("MacBook".utf8).hexEncodedString(options: [.upperCase]),
    "MacBookAir": Data("MacBookAir".utf8).hexEncodedString(options: [.upperCase]),
    "MacBookPro": Data("MacBookPro".utf8).hexEncodedString(options: [.upperCase]),
    "Macmini": Data("Macmini".utf8).hexEncodedString(options: [.upperCase]),
    "MacPro": Data("MacPro".utf8).hexEncodedString(options: [.upperCase]),
    "iPad": Data("iPad".utf8).hexEncodedString(options: [.upperCase]),
    ",": Data(",".utf8).hexEncodedString(options: [.upperCase]),
    " ": "00",
]

func hexToString(hex: String) -> String? {
    return String(data: Data(hex: hex), encoding: .ascii)
}

struct Model {
    let hex: String
    let str: String
    let type: String
    let model: Int
    let modelHex: String
    let modelHexRange: NSRange
    let version: Int
    let enabled: Bool
}

func dostuff2(sidecarCore: URL) -> [Model] {
    if let contents =  FileManager.default.contents(atPath: sidecarCore.path) {
        let hexStr = contents.hexEncodedString(options: [.upperCase])
        
        let devicesStr = devices.map{ hexDict[$0]! }.joined(separator: "|")
        let matched = hexStr.match(pattern: "(\(devicesStr))((?:(?!00)[0-9A-Z])+)\(hexDict[","]!)((?:(?!00)[0-9A-Z])+)\(hexDict[" "]!)")
        
        let models = matched.map({ res -> Model in
            let hex = res[0].matchedStr
            let type = hexToString(hex: res[1].matchedStr)!
            let modelHex = res[2].matchedStr
            let modelHexRange = res[2].range
            let model = Int(String(data: Data([UInt8](Data(hex: modelHex)).map { $0 & ~0xC0 }), encoding: .ascii)!)!
            let version = Int(hexToString(hex: res[3].matchedStr)!)!
            let enabled = [UInt8](Data(hex: modelHex))[0] & 0xC0 != 0
            let str = "\(type)\(model),\(version)"

            return Model(hex: hex, str: str, type: type, model: model, modelHex: modelHex, modelHexRange: modelHexRange, version: version, enabled: enabled)
        })
        
        print("matched: \(models.count)")
        
        return models
    }
    return []
}

func patch(model: Model, sidecarCore: URL) -> Bool {
    if (model.enabled) {
        return false
    }
    
    if let contents =  FileManager.default.contents(atPath: sidecarCore.path) {
        let hexStr = contents.hexEncodedString(options: [.upperCase])
        
        // Mask the model number
        let replacementModelHex = Data([UInt8](Data(hex: model.modelHex)).map { $0 | 0xC0 }).hexEncodedString(options: [.upperCase])
        
        // Generate a new string
        let replacementHexStr = (hexStr as NSString).replacingOccurrences(of: model.modelHex, with: replacementModelHex, range: model.modelHexRange)
        let replacementData = Data(hex: replacementHexStr)
        
        // Write to file
        do {
            try replacementData.write(to: sidecarCore)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    return false
}

func unpatch(model: Model, sidecarCore: URL) -> Bool {
    if (!model.enabled) {
        return false
    }
    
    if let contents =  FileManager.default.contents(atPath: sidecarCore.path) {
        let hexStr = contents.hexEncodedString(options: [.upperCase])
        
        // Un-mask the model number
        let replacementModelHex = Data([UInt8](Data(hex: model.modelHex)).map { $0 & ~0xC0 }).hexEncodedString(options: [.upperCase])
        
        // Generate a new string
        let replacementHexStr = (hexStr as NSString).replacingOccurrences(of: model.modelHex, with: replacementModelHex, range: model.modelHexRange)
        let replacementData = Data(hex: replacementHexStr)
        
        // Write to file
        do {
            try replacementData.write(to: sidecarCore)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    return false
}
