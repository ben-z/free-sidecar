#! /bin/sh
# Script to uninstall the privileged helper

sudo launchctl unload /Library/LaunchDaemons/ben-z.free-sidecar-helper.plist
sudo rm /Library/LaunchDaemons/ben-z.free-sidecar-helper.plist
sudo rm /Library/PrivilegedHelperTools/ben-z.free-sidecar-helper
