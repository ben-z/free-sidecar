//
//  ProcessUtils.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2020-04-16.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation
import os.log

func readToEOF(pipe: Pipe) -> String {
    let data = pipe.fileHandleForReading.readDataToEndOfFile();
    return String(decoding: data, as: UTF8.self)
}

func copyFile(from: String, to: String) -> (Process, Pipe, Pipe) {
    os_log(.debug, log: log, "copyFile: %{public}s -> %{public}s", from, to)

    let task = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/bin/cp")
    task.arguments = [from, to]
    task.standardOutput = outputPipe
    task.standardError = errorPipe

    return (task, outputPipe, errorPipe)
}
