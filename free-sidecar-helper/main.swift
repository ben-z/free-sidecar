//
//  main.swift
//  free-sidecar-helper
//
//  Created by Ben Zhang on 2020-04-14.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log

let log = OSLog(subsystem: (Bundle.main.bundleIdentifier ?? "bundle") + ".helper", category: "default")

os_log(.debug, log: log, "Hello, World!")

func isSIPDisabled() -> Bool? {
    let task = Process()
    let outputPipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/usr/bin/csrutil")
    task.arguments = ["status"]
    task.standardOutput = outputPipe

    do {
        try task.run()
    } catch {
        // task launched unsuccessfully
        return nil
    }

    task.waitUntilExit()
    if task.terminationStatus != 0 {
        return nil
    }

    let output = readToEOF(pipe: outputPipe)
    if let range = output.range(of: #"enabled|disabled"#, options: .regularExpression) {
        return output[range.lowerBound..<range.upperBound] == "disabled"
    } else {
        return nil
    }
}

let isDisabledStr: String
if let isDisabled = isSIPDisabled() {
    isDisabledStr = String(isDisabled)
} else {
    isDisabledStr = "error"
}

os_log(.info, log: log, "isSIPDisabled: %{public}s", isDisabledStr)

func lsVarDbSudo() -> String? {
    let task = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/bin/ls")
    task.arguments = ["/var/db/sudo"]
    task.standardOutput = outputPipe
    task.standardError = errorPipe

    do {
        try task.run()
    } catch {
        // task launched unsuccessfully
        os_log(.error, log: log, "task launch failed")
        return nil
    }

    task.waitUntilExit()
    if task.terminationStatus != 0 {
        os_log(.error, log: log, "ls failed")
    }

    return readToEOF(pipe: task.terminationStatus == 0 ? outputPipe : errorPipe)
}

if let str = lsVarDbSudo() {
    os_log(.info, log: log, "%{public}s", str)
}

os_log(.debug, log: log, "Done")

FreeSidecarHelperDelegate().run()
