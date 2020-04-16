//
//  ContentView.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2019-10-26.
//  Copyright © 2019 Ben Zhang. All rights reserved.
//

import SwiftUI
import os.log
import Promises

struct ModelButtonStyle: ButtonStyle {
    let isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        let borderColor = self.isEnabled ? Color.green : Color.orange
        let backgroundColor = configuration.isPressed ? Color.clear : borderColor

        return configuration.label
            .foregroundColor(configuration.isPressed ? Color.white : Color.black)
            .background(backgroundColor)
            .border(borderColor, width: 2)
            .cornerRadius(4)
            .padding(2)
    }
}

let SIDECARCORE_BACKUP_PATH = "~/Downloads/SidecarCore.bak"
let SIDECARCORE_WIP_PATH = "~/Downloads/SidecarCore"
let DISABLE_SIP_COMMAND = "csrutil disable"
let ENABLE_SIP_COMMAND = "csrutil enable"
let MOUNT_AS_RW_COMMAND = "sudo mount -uw /"
let SIGN_COMMAND = "sudo codesign -f -s - \(SYSTEM_SIDECARCORE_PATH)"

let systemVersion = SystemVersion()
let systemModel = Sysctl.model

private let queue = DispatchQueue(label: "work-queue")

struct ContentView: View {
    @State var selectedURL: URL?
    @State var models: [Model] = []
    @State private var backup: String = "cp \(SYSTEM_SIDECARCORE_PATH) \(SIDECARCORE_BACKUP_PATH)"
    @State private var system_to_downloads: String = "cp \(SYSTEM_SIDECARCORE_PATH) \(SIDECARCORE_WIP_PATH)"
    @State private var disable_sip: String = DISABLE_SIP_COMMAND
    @State private var enable_sip: String = ENABLE_SIP_COMMAND
    @State private var rw: String = MOUNT_AS_RW_COMMAND
    @State private var downloads_to_system: String = "cp \(SIDECARCORE_WIP_PATH) \(SYSTEM_SIDECARCORE_PATH)"
    @State private var sign: String = SIGN_COMMAND

    @State private var backupButtonText: String = "Backup"
    private let xcodeCLTPath = getXcodeCLTPath()
    private let xcodeCLTVersion = getXcodeCLTVersion()
    private let sipDisabled = isSIPDisabled()
    private let isSidecarCoreModified = hasAppleSignature(filePath: SYSTEM_SIDECARCORE_PATH)

    var body: some View {
        ScrollView {
            VStack {
                Group {
                    VStack {
                        Text("Free Sidecar")
                            .font(.title)
                        Button(action: {
                            if NSWorkspace.shared.open(URL(string: "https://github.com/ben-z/free-sidecar")!) {
                                os_log(.debug, log: log, "Default browser was successfully opened")
                            }
                        }) {
                            Text("Reference: https://github.com/ben-z/free-sidecar")
                        }
                    }.padding()
                }
                Group {
                    VStack {
                        Text("System Version: \(systemVersion.description)")
                        Text("System Model: \(systemModel)")
//                        (Can't access from Sandbox):
//                        Text({
//                            guard xcodeCLTPath != nil, let version = xcodeCLTVersion else {
//                                return "Xcode Command Line Tools is not installed"
//                            }
//
//                            if version.compare("11.4", options: .numeric) != .orderedAscending {
//                                return "Xcode Command Line Tools is up-to-date"
//                            } else {
//                                return "Xcode Command Line Tools is out-of-date"
//                            }
//                        }())
                        Text({
                            switch sipDisabled {
                            case true:
                                return "SIP is disabled"
                            case false:
                                return "SIP is enabled"
                            default:
                                return "Error checking SIP status"
                            }
                        }())
                        Text({
                            switch isSidecarCoreModified {
                            case true:
                                return "SidecarCore is unmodified"
                            case false:
                                return "SidecarCore is modified"
                            // TODO: Check if the modification is free-sidecar-compatible
                            default:
                                return "Error checking the integrity of SidecarCore"
                            }
                        }())
                    }.padding()
                    VStack {
                        Text("Follow the steps below to enable/disable Sidecar on your system.")
                        Text("(Use this at your own risk.)")
                    }.padding()
                }
                Group {
                    VStack {
                        Text("1. Make a backup of SidecarCore (run this in Terminal):")
                        TextField("", text: $backup)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
//                        Can't access the Downloads folder directly in sandbox. But here's a sample of what to do when we want ot run a command
//                        Button(action: {
//                            queue.async {
//                                self.backupButtonText = "Backing up..."
//                                let (task, _, errPipe) = copyFile(from: SYSTEM_SIDECARCORE_PATH, to: SIDECARCORE_BACKUP_PATH)
//
//                                do {
//                                    try task.run()
//                                } catch {
//                                    print("Backup command failed. Error: ", error.localizedDescription)
//                                    self.backupButtonText = "Error"
//                                    return
//                                }
//
//                                task.waitUntilExit()
//
//                                if (task.terminationStatus == 0) {
//                                    print("Backup successful")
//                                    self.backupButtonText = "Success"
//                                } else {
//                                    print("Backup failed, stderr:", readToEOF(pipe: errPipe))
//                                    self.backupButtonText = "Error"
//                                }
//                            }
//                        }) {
//                            Text(backupButtonText)
//                        }
                    }.padding()
                    VStack {
                        Text("2. Copy SidecarCore from the System folder (run this in Terminal):")
                        TextField("", text: $system_to_downloads)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                    }.padding()
                    VStack {
                        Text("3. Choose the location of the SidecarCore file to be patched (~/Downloads/SidecarCore from step 2:")
                        if selectedURL != nil {
                            Text("Selected: \(selectedURL!.absoluteString)")
                        } else {
                            Text("No selection")
                        }
                        Button(action: {
                            let panel = NSOpenPanel()
                            DispatchQueue.main.async {
                                let result = panel.runModal()
                                if result == .OK {
                                    self.selectedURL = panel.url
                                    self.models = dostuff2(sidecarCore: panel.url!);
                                }
                            }
                        }) {
                            Text("Select SidecarCore")
                        }
                    }.padding()
                    VStack {
                        Text("4. Click \"Enable\" to enable sidecar for the device:")
                        if (selectedURL != nil) {
                            List(models, id: \.hex) { model in
                                Button(action: {
                                    os_log(.debug, log: log, "Clicked %{public}s!", model.str)
                                    if (model.enabled) {
                                        let unpatched = unpatch(model: model, sidecarCore: self.selectedURL!)
                                        os_log(.debug, log: log, "Un-patching successful? %{public}s", String(unpatched))
                                    } else {
                                        let patched = patch(model: model, sidecarCore: self.selectedURL!)
                                        os_log(.debug, log: log, "Patching successful? %{public}s", String(patched))
                                    }
                                    self.models = dostuff2(sidecarCore: self.selectedURL!)
                                }) {
                                    Text(model.enabled ? "\(model.str) enabled" : "Enable \(model.str)")
                                        .padding()
                                }
                                .buttonStyle(ModelButtonStyle(isEnabled: model.enabled))
                            }.frame(minHeight: 300)
                        } else {
                            Text("Select a SidecarCore first")
                        }
                    }.padding()
                    VStack {
                        Text("5. Disable System Integrity Protection:")
                        Text("5.1. Reboot into recovery mode (Press cmd-R when booting)")
                        Text("5.2. Execute in Terminal in recovery mode:")
                        TextField("", text: $disable_sip)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                        Text("5.3. Reboot into macOS")
                    }.padding()
                    VStack {
                        Text("6. Mount system volume as read-write (in Terminal):")
                        TextField("", text: $rw)
                           .font(.system(size: 10, design: .monospaced))
                           .padding(.leading, 20)
                           .padding(.trailing, 20)
                    }.padding()
                    VStack {
                        Text("7. Copy the patched SidecarCore back into SidecarCore.framework (in Terminal):")
                        TextField("", text: $downloads_to_system)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                    }.padding()
                    VStack {
                        Text("8. Sign the patched SidecarCore (in Terminal):")
                        TextField("", text: $sign)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            .padding(.bottom)
                        Text("9. Reboot Into Recovery, re-enable System Integrity Protection:")
                        TextField("", text: $enable_sip)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            .padding(.bottom)
                        Text("10. Reboot Into macOS, the patched devices should now work in wired mode.")
                    }.padding()
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
