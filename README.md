# Custom-logistics
为 CC:Tweaked 的计算机提供自定义物流的能力。

## 简介
该项目旨在实现 Minecraft 中 CC:Tweaked 计算机对物品的自定义物流管理，通过缓存和分配机制，实现物品在不同容器之间的高效流转。

主要功能包括：
- 物品缓存管理
- 物品均匀分配到目标容器
- 输入输出配置与分类
- 物流状态等待与检测

## 文件结构与模块说明
- `src/ItemAllocation.lua`: 主逻辑文件，包含物品分配、缓存转移、容器状态检测等功能。
- `src/buffer.lua`: 缓存模块，实现缓存容器的创建、物品输出、列表展示及大小查询等功能。

## 使用说明
### 前提条件
- 安装 [CC:Tweaked](https://www.computercraft.info) 模组。
- 确保你的 Minecraft 环境支持 Lua 编程，并已部署相关外设设备。

### 配置与运行
1. 将本项目文件上传到你的 CC:Tweaked 计算机。
2. 编辑配置文件以指定输入、输出容器及缓存容器。
3. 运行主程序 `ItemAllocation.lua` 开始物流处理。

### 示例
以下是一个简单的调用示例：
```lua
-- 假设已配置好输入、输出及缓存容器
local featureTable = classifyByFeatures() -- 分类容器
configureInputAndOutput(featureTable) -- 配置输入输出
uniformToTarget("example_item", Buffer, targetContainers) -- 均匀分配物品
```

## API 文档
### `buffer:asBuffer(inventory)`
将一个容器作为缓存容器使用。

### `buffer:output(toName, itemName, count)`
从缓存中输出指定数量的物品到目标容器。

### `buffer:list()`
列出缓存容器中的所有物品。

### `buffer:size()`
获取缓存容器的容量。

### `uniformToTarget(name, buffer, target)`
将缓存中的物品均匀分配到一组目标容器。

## 贡献指南
欢迎提交 Pull Request 来改进本项目。请遵循以下步骤：
1. Fork 本仓库。
2. 创建新分支。
3. 提交更改。
4. 发起 Pull Request。

## 许可证
本项目遵循 MIT 许可证，请参见 [LICENSE](LICENSE) 文件。