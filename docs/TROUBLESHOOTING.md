# Troubleshooting

[README](../README.md) · [中文操作手册](README.zh-CN.md)

Inspect the system font registration in **administrator PowerShell**:

~~~powershell
$reg = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
Get-ItemPropertyValue $reg -Name 'Segoe UI Emoji (TrueType)'
Test-Path "$env:WINDIR\Fonts\seguiemj.ttf"
Get-ChildItem "$env:WINDIR\Fonts\Segoe.UI.Emoji.with.Twemoji.Flags.scoop-*.ttf" -ErrorAction SilentlyContinue
~~~

A stock Windows installation normally maps to seguiemj.ttf. This Bucket installs a versioned .scoop-*.ttf file and refuses to replace unknown prior customizations.

If flags remain letters, **restart Windows completely** before testing again. Application-level font fallback can differ.

If an update fails, note that Scoop uninstalls the old version before installing the new. Check the active mapping instead of assuming the old patched font remained installed.

If you installed another modification manually, first follow the [upstream troubleshooting guide](https://github.com/Chasmical/flag-emojis-for-windows/blob/main/TROUBLESHOOTING.md) to restore the previous state. Do not overwrite or delete the original Windows font. If cleanup detects conflicting registrations, stop and investigate.

When filing an issue, include the Windows/Scoop versions, command, complete error, original font mapping, and whether you installed another replacement. Do not upload proprietary Windows font binaries.
