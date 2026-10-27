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

## Recovery boundaries

The hooks trust the original Windows font only after checking that its file exists; they cannot authenticate its origin or detect an already modified `seguiemj.ttf`. If the original is suspect, use Windows' supported system repair/servicing process to restore it first. Do not copy an arbitrary font over it.

A failed install attempts to restore the previously observed original mapping, unload only its newly registered GDI resource and remove only its newly copied file. If the registry cannot be read/restored, the font file is retained and an explicit warning identifies its path. Preserve the Scoop version directory and record the mapping/error before doing anything else. Do not assume a failed command made no changes. Unknown active replacements, files whose hashes differ, and concurrent mapping changes are rejected.

A failed upgrade may leave `seguiemj.ttf` active because the old uninstall ran first. The patched old version is not automatically reinstalled. A locked owned file may remain after a successful mapping restoration. After restarting, inspect the active mapping and compare any leftover file against the corresponding retained package source before considering manual deletion of that specific versioned copy. Never delete `seguiemj.ttf`, use a wildcard deletion in Windows Fonts, or run `scoop cleanup` before preserving recovery evidence. Cleanup only removes old Scoop package directories, not system-font leftovers.

Windows Update may reset the mapping. If it is `seguiemj.ttf`, the original exists and the retained versioned file matches the package source, an explicitly chosen elevated `scoop update -g flag-emojis-for-windows --force` can rerun the uninstall/install lifecycle for the same version. Inspect `scoop help update` for your Scoop version first. If another mapping is active or the original is missing/suspect, investigate/repair instead of forcing an install. This recovery procedure remains subject to isolated Windows acceptance.

中文：先记录映射、错误和残留文件，保留旧 Scoop 版本目录。升级失败可能已恢复原版映射，不代表旧补丁仍然有效。锁定文件重启后需确认未被引用且内容与旧包源一致，才能人工处理指定的版本化文件，禁止通配符删除。Windows Update 后先检查；仅在原始映射和可信原件均正常时考虑管理员强制重装同版本。原件来源、真实 GDI 行为和恢复流程仍需隔离环境验证。

## Isolated Windows acceptance

Not executed by CI or on a developer machine. Use a disposable Windows VM/Sandbox with a snapshot and explicitly authorized font changes. Record Windows build, Scoop commit, package version, before/after mapping, font-file hashes, command output and post-restart display results. Do not redistribute the Windows font binaries.

- Verify per-user and non-admin global installs reject before any font mutation.
- Start with a trusted stock `seguiemj.ttf`; record its hash. Install globally, confirm the versioned copy, mapping, GDI visibility and notification, restart and test flags plus ordinary emoji in multiple applications. Confirm the original hash is unchanged.
- Repeat install and uninstall; test reinstalling the same version. Confirm mapping restoration and that only matching owned copies are candidates for removal.
- Test old-to-new update in an isolated fixture, with Scoop's update-scoped new version different from the old directory. Interrupt after old uninstall; inject copy, registration and registry failures. Observe the original mapping and retained recovery files; do not presume rollback to the patched old version.
- Test a locked font file, missing original, unknown third-party mapping, matching-prefix foreign file, mismatched owned file and Windows Update resetting the mapping. Confirm each refusal/preservation/warning, then test the documented restart and recovery procedures.
- Test Scoop cleanup only after collecting recovery evidence. Confirm that it does not remove an active Windows font or the original file. Verify any leftover versioned Windows Fonts copies separately.

中文验收要求：仅在可丢弃、有快照且明确允许修改字体的 Windows 中进行，记录系统/Scoop 版本、原件哈希、映射、错误、锁定和重启显示。覆盖普通安装拒绝、全局安装、重复安装、旧卸载先于新安装、失败恢复、未知替换、文件锁定、Windows Update 与 cleanup。未取得这些记录前，不宣称系统字体安装或回滚已验证。
