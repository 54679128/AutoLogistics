# 📦 AutoLogistics — ComputerCraft 自动物品与流体调度系统
  
> 一个模块化物流框架，专为 **CC: Tweaked** 环境设计，支持物品/流体转移、安全提取。将来将尝试支持智能搜索、配方自动化、远程物品传输。
>
> 这是一个高度实验性的项目，尚未完成，API 可能随时变动，不建议在重要存档中使用。

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)  
*适用于 Minecraft 1.20.1 + CC: Tweaked*

---

## 🧪 当前状态

- 基础转移系统`src/1`部分已经可以工作，且在可预见的未来内不会有什么更改；
- 安全转移模块（`TransferTicket`）已可工作，但可能会有不影响使用的修改；
- 多容器管理（`WarehouseManager`）、筛选器（`Filter`）仍在开发中
- 尚无安装脚本，无完整文档，测试用例不完善
- 计划支持：远程传输、配方解析、多仓库交流等

> 作者注：制作时参考了另一个项目：[SIGILS](https://github.com/cc-tweaked/CC-Tweaked/discussions/1998)，你可以去看看。

---

## 如何试用（仅限开发者/爱好者）

### 1. 环境配置

将 `src/`、`resource/`、`startup` 目录复制到你的 ComputerCraft 计算机或海龟的根目录下。或使用安装脚本（暂时还没有😔）。

### 2. 运行测试

`src/`每个已经制作完成的功能模块都有对应的测试，这些测试都存放在名为`test`的文件夹下，像是`src/1/test/invTest.lua`。有时你需要根据测试文件的提示更改测试环境（通常是移动容器物品、移除或添加外设）。大部分的测试程序都称不上“自动”，你需要根据程序提示来判断输出是否合理；甚至有些测试文件需要你熟知源码才能判断输出是否合法。我会尝试解决这些问题，如果有能力，可以像这个仓库提相关PR.

---

## 🔧 核心模块说明

需要注意的是：这些说明大多是AI生成的，我只是稍微改动了一部分。我很难总结这些模块的作用，我是根据实际需求写出了这些模块。

| 模块 | 用途 |
|------|------|
|`TransferTicket`|提供在两个容器之间安全（不报错，自动处理目标容器满、源容器资源不存在、外设不存在等错误）转移资源的方法|
| `WarehouseManager` | 管理着多个容器 |
| `CommandInvoker` | 批量执行转移命令（如整箱搬运、槽对槽移动）。注意，这个模块不会处理或抛出任何错误 |
| `Filter` + `preDefinedFilter` | 构建物品筛选条件（支持 AND/OR/NOT 组合），未完成 |
| `ContainerStack` | 容器快照模型，用于保存与锁定物品信息（注意，这里的锁定只是逻辑上的，你仍然可以从容器内拿走任何你想要的东西） |
| `commands/` | 内置命令：<br> • `TransferItems`（整箱转移）<br> • `TransferSlotToInventory`（槽→容器）<br> • `TransferSlotToSlot`（槽→槽）<br> • `TransferFluid`（流体转移） <br> 你可以根据`src/1/commands/Example.lua`文件内的内容添加自己的指令。|

---

## ⚠️ 注意事项

- **路径依赖**：大部分测试文件和模块依赖 `_steup.lua` 配置模块搜索路径，如果出现找不到模块的问题，可以看看这个文件。
- **日志文件**：默认输出到 `log.txt`，可通过在模块中加上 `require("lib.log").outfile = "yourLog.txt"` 修改。
- **流体单位**：ComputerCraft 中 1 桶 = 1000 B，我觉得这不必多说。

---

## 📜 许可证

本项目采用 [MIT License](LICENSE)。  
日志库 (`lib/log.lua`) 和 OOP 基类 (`lib/Object.lua`) 衍自 [rxi/classic](https://github.com/rxi/classic)，同样遵循 MIT。

---

## 如果你仍想参与……

尽管项目未完成，但如果你：

- 对 CC: Tweaked 物流系统感兴趣
- 愿意阅读/调试实验性代码
- 想一起讨论设计方向

欢迎通过 Issue 提出想法，或提交 PR 帮助完善测试、文档、错误处理等！  
（哪怕只是指出“这里看不懂”，也很有价值🐢）
