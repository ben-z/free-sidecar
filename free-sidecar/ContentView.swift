//
//  ContentView.swift
//  free-sidecar
//
//  Created by Ben Zhang on 2019-10-26.
//  Copyright © 2019 Ben Zhang. All rights reserved.
//

import SwiftUI

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

struct ContentView: View {
    @State var selectedURL: URL?
    @State var models: [Model] = []
    @State private var backup: String = "cp /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore ~/Downloads/SidecarCore.bak"
    @State private var system_to_downloads: String = "cp /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore ~/Downloads"
    @State private var disable_sip: String = "csrutil disable"
    @State private var enable_sip: String = "csrutil enable"
    @State private var rw: String = "sudo mount -uw /"
    @State private var downloads_to_system: String = "sudo cp ~/Downloads/SidecarCore /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore"
    @State private var sign: String = "sudo codesign -f -s - /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore"

    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    Text("Free Sidecar")
                        .font(.title)
                    Button(action: {
                        if NSWorkspace.shared.open(URL(string: "https://github.com/ben-z/free-sidecar")!) {
                            print("default browser was successfully opened")

                        }
                    }) {
                        Text("Reference: https://github.com/ben-z/free-sidecar")
                    }
                }
                VStack {
                    Text("Follow the steps below to enable/disable Sidecar on your system.")
                    Text("(Use this at your own risk.)")
                }.padding()
                VStack {
                    Text("1. Make a backup of SidecarCore (run this in Terminal):")
                    TextField("", text: $backup)
                        .font(.system(size: 10, design: .monospaced))
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
                                print("Clicked \(model.str)!")
                                if (model.enabled) {
                                    print("Un-patching successful? \(unpatch(model: model, sidecarCore: self.selectedURL!))")
                                } else {
                                    print("Patching successful? \(patch(model: model, sidecarCore: self.selectedURL!))")
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
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
