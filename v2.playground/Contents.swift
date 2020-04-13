import Cocoa
import Foundation
import Promises

struct SystemVersion {
    let major: Int
    let minor: Int
    let patch: Int
    let build: String?

    init() {
        let v = ProcessInfo().operatingSystemVersion
        major = v.majorVersion
        minor = v.minorVersion
        patch = v.patchVersion
        // https://twitter.com/ingeration/status/1076240776915574785
        build = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist")?["ProductBuildVersion"] as? String

        
    }
}

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String;

let systemVersion = SystemVersion()

let systemModel = Sysctl.model

func readToEOF(pipe: Pipe) -> String {
    let data = pipe.fileHandleForReading.readDataToEndOfFile();
    return String(decoding: data, as: UTF8.self)
}

func getXcodeCLTPath() -> String? {
    let task = Process()
    let outputPipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
    task.arguments = ["--print-path"]
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

    return readToEOF(pipe: outputPipe).trimmingCharacters(in: .whitespacesAndNewlines)
}

func makeGetPackageInfoTask(pkgId: String) -> (Process, Pipe, Pipe) {
    let task = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/usr/sbin/pkgutil")
    task.arguments = ["--pkg-info=" + pkgId]
    task.standardOutput = outputPipe
    task.standardError = errorPipe

    return (task, outputPipe, errorPipe)
}

func getXcodeCLTVersion() -> String? {
    let (xcTask, xcOut, xcErr) = makeGetPackageInfoTask(pkgId: "com.apple.pkg.Xcode")
    let (cltTask, cltOut, cltErr) = makeGetPackageInfoTask(pkgId: "com.apple.pkg.CLTools_Executables")

    do {
        try xcTask.run()
        try cltTask.run()
    } catch {
        return nil
    }

    xcTask.waitUntilExit()
    cltTask.waitUntilExit()

    let outPipe: Pipe

    switch (xcTask.terminationStatus, cltTask.terminationStatus) {
    case (0, _):
        outPipe = xcOut
    case (_, 0):
        outPipe = cltOut
    default:
        print("No Xcode CLT version info:")
        print(readToEOF(pipe: xcErr))
        print(readToEOF(pipe: cltErr))
        return nil
    }

    let output = readToEOF(pipe: outPipe)
    if let versionRange = output.range(of: #"version: (\d+\.)+(\d)+"#, options: .regularExpression) {
        let lowerBound = output.index(versionRange.lowerBound, offsetBy: "version: ".count)
        return String(output[lowerBound..<versionRange.upperBound])
    } else {
        return nil
    }
}

if let xcodeCLTPath = getXcodeCLTPath(), let xcodeCLTVersion = getXcodeCLTVersion() {
    if xcodeCLTVersion.compare("11.4", options: .numeric) != .orderedAscending {
        print("Xcode Command Line Tools is up-to-date")
    } else {
        print("Xcode Command Line Tools is out-of-date")
    }
} else {
    print("Xcode Command Line Tools is not installed")
}

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

switch isSIPDisabled() {
case true:
    print("SIP is disabled")
case false:
    print("SIP is enabled")
default:
    print("Error checking SIP status")
}

func hasAppleSignature(filePath: String) -> Bool? {
    let task = Process()
    let outputPipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
    task.arguments = ["-dv", "--verbose=4", filePath]
    // codesign uses stderr for its output
    task.standardError = outputPipe

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
    return output.contains("Authority=Software Signing")
        && output.contains("Authority=Apple Code Signing Certification Authority")
        && output.contains("Authority=Apple Root CA")
}

switch hasAppleSignature(filePath: "/System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore") {
case true:
    print("SidecarCore is unmodified")
case false:
    print("SidecarCore is modified")
    // TODO: Check if the modification is free-sidecar-compatible
default:
    print("Error checking the integrity of SidecarCore")
}


//struct SomeError: Error {}
//let promise = Promise<String>(on: .main) { fulfill, reject in
//  // Called asynchronously on the dispatch queue specified.
//  if true {
//    // Resolve with a value.
//    fulfill("Hello world.")
//  } else {
//    // Resolve with an error.
//    reject(SomeError())
//  }
//}
//
//do {
//    try await(promise)
//} catch {
//    print("caught error: \(error)")
//}

// Conclusion from below: task.run() throws not when the process exit code is nonzero, but when the task
//   configuration is faulty
//func testProcess() -> (Pipe, Pipe)? {
//    let task = Process()
//    let outputPipe = Pipe()
//    let errorPipe = Pipe()
//
//    task.executableURL = Bundle.main.url(forResource: "random-script", withExtension: "sh")
//    task.standardOutput = outputPipe
//    task.standardError = errorPipe
//
//    do {
//        try task.run()
//
//        return (outputPipe, errorPipe)
//    } catch {
//        print(error)
//        return nil
//    }
//}
//
//if let pipes = testProcess() {
//    let (outputPipe, errorPipe) = pipes
//
//    print("obtained the pipes")
//
//    print(String(decoding: outputPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self))
//    print(String(decoding: errorPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self))
//}

