# KnowSky404 Scoop Bucket：中文操作手册

[返回首页](../README.md)

本仓库是用于 Windows 工具与字体的个人 Scoop Bucket。首个收录包为 [Flag Emojis for Windows](https://github.com/Chasmical/flag-emojis-for-windows)。

## 添加 Bucket

先安装 [Scoop](https://scoop.sh)，然后在**普通 PowerShell** 中执行：

~~~powershell
scoop bucket add KnowSky404 https://github.com/KnowSky404/scoop-bucket
scoop bucket list
scoop info KnowSky404/flag-emojis-for-windows
~~~

如果之前使用 `knowsky` 添加过此 Bucket，请先移除旧的 Bucket 条目，再使用上面的命令重新添加。移除 Bucket 不会卸载已从中安装的软件包。

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
scoop install -g KnowSky404/flag-emojis-for-windows
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
scoop bucket rm KnowSky404
~~~

## 自动更新与注意事项

- Actions 每天检查上游发布并创建 Draft PR，不直接合并。
- 只有维护者审核合并后，scoop update 才会获取新版 Manifest。
- 仓库默认 GITHUB_TOKEN 为只读；仅更新 Job 申请 contents / pull-requests 写权限。已开启 Actions 创建 PR，不保存额外 PAT，脚本不批准或合并 PR。
- 依据 [GitHub 当前文档](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)，GITHUB_TOKEN 创建或更新 PR 可产生**等待人工批准的 CI**。审核提交后点击 **Approve workflows to run**；若没有运行记录，按[贡献指南](CONTRIBUTING.md#reviewing-bot-prs-and-running-ci)对该分支手动 dispatch CI，确认 headSha 和 PR 最新提交一致且所有必需检查通过后再人工合并。
- main 的 Ruleset 要求 PR、分支保持最新及三个实际 CI 检查通过；无绕过权限，不要求无法由单人满足的第二位审核者。Dependabot 每周提出 Actions 依赖更新，不自动合并。
- 更新器检查稳定版标签、官方 ZIP 名称和 URL、Release Digest 与独立下载校验。无新版不提交；已有 PR 不重复创建；遗留分支只有与完整提案一致才恢复 PR 创建，否则报错，绝不强推。限流、网络或权限错误需解决后重试。
- 目前仅 Flag Emojis 自动更新；普通新增清单由 CI 自动发现、验证 Schema 和各架构下载哈希，不需要复制字体钩子或重构 CI。
- 如果 Edge、Zed 显示仍异常，先重启，再检查字体映射和第三方替换冲突。
- 初始字体生命周期脚本还未在你的真实 Windows 环境运行验证，首次使用建议先在可回滚的测试环境验收。

[故障排查](TROUBLESHOOTING.md) · [贡献指南](CONTRIBUTING.md)

## 安全边界与恢复

安装只接受原始映射或与当前版本源文件一致的同名受管字体；不会仅凭文件名前缀信任其他替换。卸载从旧版本目录识别版本，校验文件归属，在恢复原始映射后卸载 GDI 资源并发送有超时限制的字体变更通知。注册表失败时保留文件并报错；安装失败会尽力恢复原映射、卸载本次资源并清理本次新文件，不能保证所有系统副作用自动回滚。

原始文件存在并不证明其来自可信 Windows 安装。若怀疑原生字体曾被覆盖，应先用 Windows 系统修复恢复可信原件，绝不覆盖或删除 seguiemj.ttf。文件锁定可能留下 Windows Fonts 中的版本化副本；重启后确认映射不引用它且内容确属本包再处理。恢复完成前保留 Scoop 版本目录；scoop cleanup 会删除旧包目录，不会清除系统目录中锁定的副本。

Windows Update 可能恢复原始映射。先检查映射、原件和受管文件，不要盲目覆盖其他软件的改动。scoop update 只刷新 Scoop/清单；只有管理员执行 scoop update -g flag-emojis-for-windows 才升级已安装字体。清单版本没有变化时，普通 update 不会重新安装；具体恢复流程见[故障排查](TROUBLESHOOTING.md)。

CI 只使用 Mock 注册表/文件系统与无 P/Invoke 的托管原生 API 替身，不修改 Runner 系统字体。真实安装、升级中断、回滚、锁定、重启显示与 Windows Update 恢复仍需[隔离 Windows 验收](TROUBLESHOOTING.md#isolated-windows-acceptance)，不能以 CI 通过宣称这些已证明。[交付证据](../VERIFICATION.md)列出实际运行与未验证事项。
