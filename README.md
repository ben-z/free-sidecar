# Free Sidecar 

[![](https://img.shields.io/github/downloads/ben-z/free-sidecar/total)](https://github.com/ben-z/free-sidecar/releases)
[![](https://img.shields.io/badge/macOS->=10.15%20Catalina-brightgreen)](#)
[![](https://img.shields.io/badge/iPadOS->=13-brightgreen)](#)

Unlocks [Sidecar](https://support.apple.com/en-ca/HT210380) for older, unsupported iPads and Macs (supports all iPads running iPadOS and Macs running macOS Catalina or newer).

[Download the lastest version](https://github.com/ben-z/free-sidecar/releases/latest/download/free-sidecar.zip)

**Full list of supported iPads (running iPadOS):** iPad Air 2, iPad Air (3rd generation), iPad (5th generation), iPad (6th generation), iPad (7th generation), iPad Mini 4, iPad Mini (5th generation), iPad Pro 9.7-inch, iPad Pro 10.5-inch, iPad Pro 11-inch, iPad Pro 12.9-inch (1st generation), iPad Pro 12.9-inch (2nd generation), iPad Pro 12.9-inch (3rd generation)

**List of supported Macs (running macOS Catalina or newer):** iMac: Late 2012 or newer, iMac Pro, Mac Pro: Late 2013 or newer, Mac Mini: Late 2012 or newer, MacBook: Early 2015 or newer, MacBook Air: Mid 2012 or newer, MacBook Pro: Mid 2012 or newer

### Notes
1. Apple uses a simple "blacklist" on macOS to disable iPadOS 13/macOS Catalina devices from using Sidecar. To work around this, we simply need to edit the blacklist in `/System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore` (can be done with any hex editor of your choice).
1. This app is a UI for editing `SidecarCore`.
1. This app is sandboxed and does NOT need root access. I've left everything that needs root access for you to execute in the Terminal.
1. This app works on all versions of iPadOS and macOS Catalina, including upcoming releases (assuming Apple doesn't change how they blacklist devices—in which case this app will be a no-op).
1. **macOS Catalina 10.15.4 introduced a change that broke self-signed frameworks, which we are using. If you are on 10.15.4+, you need to go through one extra step (added as a substep under step 8 below).**
1. The entire process includes 2 restarts into the recovery partition and should take around 5-15 minutes.
1. Wireless mode may not work for all older devices.

### Getting Started

1. Make a backup of SidecarCore (run this in Terminal):

```
cp /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore ~/Downloads/SidecarCore.bak
```

2. Copy SidecarCore from the System folder (run this in Terminal)

```
cp /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore ~/Downloads
```

3. Open [Free Sidecar](https://github.com/ben-z/free-sidecar/releases) (note that macOS may prevent you from running the app. In that case, open `System Preferences - Security & Privacy - General` and select `Open Anyway`) and choose the location of the SidecarCore file to be patched (~/Downloads/SidecarCore from step 2).

![Free Sidecar](docs/free-sidecar.png)

4. Click `Enable` to enable sidecar for the corresponding device. This will modify the `SidecarCore` that you've selected in step 3 (you will be replacing the system `SidecarCore` with this file in step 7):
    - Run `sysctl hw.model` in Terminal to find out your mac model. For iPad model, go [here](https://everymac.com/ultimate-mac-lookup/).
![Click Enable](docs/click-enable.png)

5. Disable System Integrity Protection. This will allow us to mount `/` as read-write and modify `SidecarCore` under the `/System` directory.
    1. Reboot into recovery mode (Press cmd-R when booting)
    2. Execute in Terminal in recovery mode:
    ```
    csrutil disable
    ```
    3. Reboot into macOS

6. Mount system volume as read-write (in Terminal):

```
sudo mount -uw /
```

7. Copy the patched SidecarCore back into SidecarCore.framework (in Terminal):

```
sudo cp ~/Downloads/SidecarCore /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore
```

8. Sign the patched SidecarCore (in Terminal):
    * If you see an error in this step, make sure you have xcode command-line tools installed (`xcode-select --install`, see [#3]) or updated (through App Store, see [#2]).
    * Don't restart your computer until you complete this step properly (or revert the backup file)! Many people have run into issues with this ([#28], [#22]).
    * **macOS Catalina 10.15.4+ users: [Add `amfi_get_out_of_my_way=0x1` to NVRAM boot flags](https://github.com/ben-z/free-sidecar/issues/59#issuecomment-603953953), then skip step 9.**

```
sudo codesign -f -s - /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore
```

9. (Optional, but recommended **(but [not recommended][#59] for macOS Catalina 10.15.4)**) Reboot Into Recovery, re-enable System Integrity Protection:

```
csrutil enable
```

10. Reboot Into macOS, the patched devices should now work in wired mode.

### Troubleshooting

1. "The iPad picture quality is sub-optimal!"

    Try using wired connection. For older Macs without hardware HEVC encoder/decoders, it may need extra bandwidth to transmit the screen.
     
1. "Error 32002"

    This happens on wireless connection for some models. Try using a wire instead. (Some people have reported that wired isn't working either on some older models e.g. [MacbookPro 2012](https://www.reddit.com/r/MacOSBeta/comments/dnxxc7/psa_enable_sidecar_on_older_devices_works_for/f5l64ni?utm_source=share&utm_medium=web2x))
    
1. "None of my apps open anymore, They keep crashing!"
    
    You probably forgot to do step 8. If you can use the Terminal, do steps 5,6 and 8 again. If you can't use the Terminal (it keeps crashing), boot into [single user mode](http://osxdaily.com/2018/10/29/boot-single-user-mode-mac/) and do steps 6 and 8 after doing step 5 in Recovery Mode.

1. "In the code-signing step, I'm getting `the codesign_allocate helper tool cannot be found or used`."

    Make sure you have the latest Xcode comandline tools! See issues [#2] and [#3].

1. General questions to consider before opening an issue:
    1. Did you try wired mode?
    1. Does your device show up in Finder's sidebar?
    1. Did you click "trust" in Finder under the device tab?
    1. Did you try unlocking your iPad before connecting?
    1. Did you try restarting both devices and connecting again?
    1. [Try these](https://github.com/ben-z/free-sidecar/issues/39#issuecomment-582487691)

1. "My question isn't listed"
    
    Search in [issues](https://github.com/ben-z/free-sidecar/issues) or open a new one! Note that I can only fix things that are specific to Free Sidecar (enable/disable sidecar for certain devices). Most usability issues with Sidecar can only be addressed by Apple.
    
1. "I want to revert to the original `SidecarCore`"
    
    Hope you still have the backup file from step 1! (`~/Downloads/SidecarCore.bak`). Disable System Integrity Protection (step 5), mount the system volume as read-write (step 6) and run the following command in Terminal:
    
    ```
    sudo cp ~/Downloads/SidecarCore.bak /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore
    ```
    
    Then re-enable System Integrity Protection (step 9). Your system should be in the same state as before you applied the patch!

### Contributing

Submit PRs and open issues!

### Inspirations

[SidecarPatcher](https://github.com/pookjw/SidecarPatcher) - ~This replaces a hex string that only exists in beta versions (and apparently some official releases?) (thus does not work for me in the final release).~ (Update: SidecarPatcher has updated its patch method to be the same as Free Sidecar. Now the two projects can be used interchangeably :tada:). [Free Sidecar](https://github.com/ben-z/free-sidecar/)
 uses partial device model string matching (details [here](https://github.com/ben-z/free-sidecar/blob/1390f561000ccfc6122bcae0b1fff1cd5da3b0f0/free-sidecar/utils.swift#L83-L91)) and should work for future versions of macOS as well.


[#2]: https://github.com/ben-z/free-sidecar/issues/2
[#3]: https://github.com/ben-z/free-sidecar/issues/3
[#22]: https://github.com/ben-z/free-sidecar/issues/22
[#28]: https://github.com/ben-z/free-sidecar/issues/28
[#59]: https://github.com/ben-z/free-sidecar/issues/59
