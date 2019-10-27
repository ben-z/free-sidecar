# Free Sidecar

Unlocks [Sidecar](https://support.apple.com/en-ca/HT210380) for older, unsupported iPads and Macs.

This has been tested on Macbook Pro (Early 2015) and iPad Air 2 in wired mode.
Note that wireless mode may not work for all older devices.

[Download Free Sidecar](#TODO)

### Getting Started

1. Make a backup of SidecarCore (run this in Terminal):

```
cp /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore ~/Downloads/SidecarCore.bak
```

2. Copy SidecarCore from the System folder (run this in Terminal)

```
cp /System/Library/PrivateFrameworks/SidecarCore.framework/Versions/A/SidecarCore ~/Downloads
```

3. Open [Free Sidecar](#TODO) and choose the location of the SidecarCore file to be patched (~/Downloads/SidecarCore from step 2.

![Free Sidecar](docs/free-sidecar.png)

4. Click `Enable` to enable sidecar for the device:

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
