//
//  CompatibilityUtils.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2020-04-16.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log

enum CompatibilityStatus: String, Decodable {
    case works
    case doesNotWork
    case worksWithNote
}

struct MacCompatibility: Decodable {
    let model: String
    let macOS: SystemVersion
    let status: CompatibilityStatus
    let note: String?
}

struct Compatibility: Decodable {
    enum Syntax: String, Decodable {
        case compatv1
    }

    let syntax: Syntax
    let Mac: [MacCompatibility]
}

struct LinkableCompatibility: Decodable {
    struct SyntaxDict: Decodable {
        let syntax: Compatibility.Syntax
        let path: String
    }
    let syntaxes: [SyntaxDict]
}

enum OneOf<A, B> {
    case first(A)
    case second(B)
}

extension OneOf: Decodable where A: Decodable, B: Decodable {
    enum CodingKeys: CodingKey {}

    init(from decoder: Decoder) throws {
        do {
            let aValue = try A(from: decoder)
            self = .first(aValue)
        } catch {
            let bValue =  try B(from: decoder)
            self = .second(bValue)
        }
    }
}

func getCompatibilityData(url: URL, syntax: Compatibility.Syntax) -> Compatibility? {
    if let compatData = try? Data(contentsOf: url)
    {
        do {
            switch try JSONDecoder().decode(OneOf<Compatibility, LinkableCompatibility>.self, from: compatData) {
            case let .first(compatibility):
                return compatibility
            case let .second(linkable):
                if let path = linkable.syntaxes.first(where: { $0.syntax == syntax })?.path,
                    let url = URL(string: path, relativeTo: url)
                {
                    return getCompatibilityData(url: url, syntax: syntax)
                }
            }

        } catch {
            os_log(.error, log: log, "Error decoding compatibility data: %{public}s", error.localizedDescription)
        }
    }
    return nil
}
