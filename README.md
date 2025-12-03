# 📦 AutoLogistics — ComputerCraft 自动物品与流体调度系统

> 一个模块化物流框架，专为 **CC: Tweaked** 环境设计，支持物品/流体转移、智能搜索、安全提取与未来配方自动化。

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)  
*适用于 Minecraft 1.20.1 + CC: Tweaked*

---

## 快速开始

### 1. 安装

将整个 `src/` 目录复制到你的 ComputerCraft 计算机或海龟的任意位置。

```?
your_computer/
├── src/
│   ├── _steup.lua
│   ├── CommandInvoker.lua
│   ├── commands/
│   ├── lib/
│   └── ...
└── your_script.lua
```

### 2. 基础用法示例

由于该项目的第二层还未完善，所以这里的示例几乎不可能在实际生存中用到。

```lua
-- src\2\test\your_script.lua
require("_steup")  -- 配置模块搜索路径

local WarehouseManager = require("WarehouseManager")
local wm = WarehouseManager()

-- 添加容器外设
wm:add("left")   -- 左侧箱子
wm:add("right")  -- 右侧箱子

-- 搜索所有钻石（最多64个）
local results = wm:search(require("preDefinedFilter").withName("minecraft:diamond"), 64)

-- 获取3秒内有效的提取凭证
local extractor = wm:output(results)

-- 将找到的钻石转移到某个容器，这里假设计算机或海龟顶部有容器
extractor("top")
```

---

## 🔧 核心模块说明

| 模块 | 用途 |
|------|------|
| `WarehouseManager` | 仓库主控制器，负责索引、搜索、安全输出 |
| `CommandInvoker` | 批量执行转移命令（如整箱搬运、槽对槽移动） |
| `Filter` + `preDefinedFilter` | 构建物品筛选条件（支持 AND/OR/NOT 组合） |
| `ContainerStack` | 容器快照模型，用于缓存与比较物品状态 |
| `commands/` | 内置命令：<br> • `TransferItems`（整箱转移）<br> • `TransferSlotToInventory`（槽→容器）<br> • `TransferSlotToSlot`（槽→槽）<br> • `TransferFluid`（流体转移） |

---

## 🛠️ 扩展：添加自定义命令

参考 `src/Example.lua`：

```lua
local base = require("src.TransferCommandBase")

local function myWorker(cmd)
    -- 实现你的逻辑
    return true, "success"
end

---@class MyCommand:a546.TransferCommandBase
local MyCommand = base:extend()
MyCommand:register("MyCmd", myWorker)

function MyCommand:new(param1, param2)
    self.super.new(self, "source", "target")  -- 调用父类构造
    self.param1 = param1
    self.param2 = param2
end

return MyCommand
```

然后在脚本中使用：

```lua
local invoker = require("CommandInvoker")()
invoker:addCommand(MyCommand("value1", "value2"))
invoker:processAll()
```

---

## ⚠️ 注意事项

- **超时机制**：`WarehouseManager:output()` 返回的提取函数**仅在3秒内有效且只能调用一次**。
- **路径依赖**：大部分测试文件和模块依赖 `_steup.lua` 配置模块搜索路径，如果出现找不到模块的问题，可以看看这个文件。
- **日志文件**：默认输出到 `log.txt`，可通过在模块中加上 `require("lib.log").outfile = "mylog.txt"` 修改。
- **流体单位**：ComputerCraft 中 1 桶 = 1000 B，我觉得这不必多说。

---

## 🧪 测试

项目包含多个测试脚本（位于根目录）：

- `invTest.lua`：物品容器转移测试
- `fluidTest.lua`：流体转移测试
- `slotToInvTest.lua` / `slotToSlotTest.lua`：槽位级转移测试

运行前请按注释准备测试环境（两侧放置容器并填充物品/流体）。

---

## 📜 许可证

本项目采用 [MIT License](LICENSE)。  
日志库 (`lib/log.lua`) 和 OOP 基类 (`lib/Object.lua`) 衍自 [rxi/classic](https://github.com/rxi/classic)，同样遵循 MIT。

---

## 🙌 贡献与反馈

本项目仍在持续开发中。如果你有兴趣参与，欢迎通过 Issue 或 Pull Request 提交改进。
