# Free Sidecar

Unlocks [Sidecar](https://support.apple.com/en-ca/HT210380) for older, unsupported iPads and Macs.

This has been tested on Macbook Pro (Early 2015) running macOS 10.15 (19A602) (release version) and iPad Air 2 in wired mode.
Note that wireless mode may not work for all older devices.

[Download Free Sidecar](https://github.com/ben-z/free-sidecar/releases)


### Notes
1. Apple uses a simple "blacklist" on macOS to disable iPadOS 13/macOS Catalina devices from using Sidecar. To work around this, we simply need to edit the blacklist in `/System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore` (can be done with any hex editor of your choice).
2. This app is a UI for editing `SidecarCore`..
3. This app is sandboxed and does not need root access. I've left everything that needs root access for you to execute in the Terminal.

### Getting Started

1. Make a backup of SidecarCore (run this in Terminal):

```
cp /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore ~/Downloads/SidecarCore.bak
```

2. Copy SidecarCore from the System folder (run this in Terminal)

```
cp /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore ~/Downloads
```

3. Open [Free Sidecar](https://github.com/ben-z/free-sidecar/releases) (note that macOS may prevent you from running the app. In that case, open `System Preferences - Security & Privacy - General` and select `Open Anyway`) and choose the location of the SidecarCore file to be patched (~/Downloads/SidecarCore from step 2.

![Free Sidecar](docs/free-sidecar.png)

4. Click `Enable` to enable sidecar for the device:
    - Run `sysctl hw.model` in Terminal to find out your mac model. For iPad model, go [here](https://everymac.com/ultimate-mac-lookup/).
![Click Enable](docs/click-enable.png)

5. Disable System Integrity Protection
    1. Reboot into recovery mode (Press cmd-R when booting)
    2. Execute in Terminal in recovery mode:
    ```
    csrutils disable
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

```
sudo codesign -f -s - /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore
```

9. Reboot Into Recovery, re-enable System Integrity Protection:

```
csrutil enable
```

10. Reboot Into macOS, the patched devices should now work in wired mode.

### Contributing

Submit PRs and open issues!

### Inspirations

[SidecarPatcher](https://github.com/pookjw/SidecarPatcher) - This replaces a hex string that only exists in beta versions (thus does not work for the final release). [Free Sidecar](https://github.com/ben-z/free-sidecar/)
 uses partial device model string matching (details [here](https://github.com/ben-z/free-sidecar/blob/1390f561000ccfc6122bcae0b1fff1cd5da3b0f0/free-sidecar/utils.swift#L83-L91)) should work for future versions of macOS as well.
