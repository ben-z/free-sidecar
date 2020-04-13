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

func makeGrepTask(pattern: String) -> (Process, Pipe, Pipe) {
    let task = Process()
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    task.executableURL = URL(fileURLWithPath: "/usr/bin/grep")
    task.arguments = [pattern]
    task.standardOutput = outputPipe
    task.standardError = errorPipe

    return (task, outputPipe, errorPipe)
}

func getXcodeCLTVersion() -> String? {
    let (getPkgInfoTask, getPkgInfoTaskOut, getPkgInfoTaskErr) = makeGetPackageInfoTask(pkgId: "com.apple.pkg.Xcode")
    let (grepTask, grepTaskOut, grepTaskErr) = makeGrepTask(pattern: "version")

    grepTask.standardInput = getPkgInfoTaskOut

    do {
        try getPkgInfoTask.run()
        try grepTask.run()
    } catch {
        return nil
    }

    getPkgInfoTask.waitUntilExit()
    grepTask.waitUntilExit()

    getPkgInfoTask.terminationStatus
    grepTask.terminationStatus

    if getPkgInfoTask.terminationStatus != 0 || grepTask.terminationStatus != 0 {
        print(readToEOF(pipe: getPkgInfoTaskErr))
        print(readToEOF(pipe: grepTaskErr))
        return nil
    }

    return readToEOF(pipe: grepTaskOut).trimmingCharacters(in: .whitespacesAndNewlines)
}


let xcodeCLTPath = getXcodeCLTPath()
let xcodeCLTVersion = getXcodeCLTVersion()

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

