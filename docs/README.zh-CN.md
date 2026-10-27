# KnowSky Scoop Bucket：中文操作手册

[返回首页](../README.md)

本仓库是用于 Windows 工具与字体的个人 Scoop Bucket。首个收录包为 [Flag Emojis for Windows](https://github.com/Chasmical/flag-emojis-for-windows)。

## 添加 Bucket

先安装 [Scoop](https://scoop.sh)，然后在**普通 PowerShell** 中执行：

~~~powershell
scoop bucket add knowsky https://github.com/KnowSky404/scoop-bucket
scoop bucket list
scoop info knowsky/flag-emojis-for-windows
~~~

## 安装国旗 Emoji 字体

这是修改系统 Segoe UI Emoji 映射的字体，不是普通便携软件。使用**管理员 PowerShell**，先确认并备份原版字体：

~~~powershell
$reg = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
Get-ItemPropertyValue $reg -Name 'Segoe UI Emoji (TrueType)'
Test-Path "$env:WINDIR\Fonts\seguiemj.ttf"
Copy-Item "$env:WINDIR\Fonts\seguiemj.ttf" "$env:USERPROFILE\Desktop\seguiemj-original.ttf"
~~~

首次安装时，映射通常应为 seguiemj.ttf。如果已经换成其他第三方字体，本包会拒绝覆盖，请先调查。

~~~powershell
scoop install -g knowsky/flag-emojis-for-windows
~~~

**安装后重启 Windows**。然后在 Edge、Zed 等应用中测试 🇯🇵 🇨🇳 🇺🇸 🇰🇷 😀 🎉 🐱。显示效果仍取决于应用字体回退机制。

## 更新与卸载

普通 PowerShell 中更新 Bucket 清单：

~~~powershell
scoop update
~~~

管理员 PowerShell 中更新系统字体：

~~~powershell
scoop update -g flag-emojis-for-windows
~~~

管理员 PowerShell 中卸载并恢复原始字体映射：

~~~powershell
scoop uninstall -g flag-emojis-for-windows
~~~

升级和卸载后都需要重启。Scoop 在升级过程中会**先运行旧版本的卸载脚本，再安装新版本**；如果新版本安装失败，可能只恢复到 Windows 原版字体，不保证回到补丁旧版本。

检查映射和残留文件：

~~~powershell
$reg = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
Get-ItemPropertyValue $reg -Name 'Segoe UI Emoji (TrueType)'
Get-ChildItem "$env:WINDIR\Fonts\Segoe.UI.Emoji.with.Twemoji.Flags.scoop-*.ttf" -ErrorAction SilentlyContinue
~~~

如果字体文件仍被锁定，需重启后确认文件已不再被引用再删除。**不要删除原生的 seguiemj.ttf**。

全部卸载后，在普通终端移除 Bucket：

~~~powershell
scoop bucket rm knowsky
~~~

## 自动更新与注意事项

- Actions 每天检查上游发布并创建 Draft PR，不直接合并。
- 只有维护者审核合并后，scoop update 才会获取新版 Manifest。
- GITHUB_TOKEN 创建的 PR 可能不会自动触发 CI，需要手动运行相关 Workflow。
- 如果 Edge、Zed 显示仍异常，先重启，再检查字体映射和第三方替换冲突。
- 初始字体生命周期脚本还未在你的真实 Windows 环境运行验证，首次使用建议先在可回滚的测试环境验收。

[故障排查](TROUBLESHOOTING.md) · [贡献指南](CONTRIBUTING.md)
