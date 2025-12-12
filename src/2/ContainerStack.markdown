# `ContainerStack` 模块文档

`ContainerStack` 是一个用于抽象和管理 Minecraft（通过 CC: Tweaked ）中外设容器（如箱子、储罐等）内物品与流体资源的 Lua 模块。它提供了一套完整的接口，用于扫描、缓存、锁定、解锁以及序列化容器状态。

---

## 类型定义

### `a546.ItemStack`

表示一个具体的物品栈信息。

- `count`: number —— 物品数量（对于流体则代表 amount）
- `displayName`: string | nil —— 显示名称
- `itemGroups`: `{displayName: string, id: string}[] | {}` —— 所属物品组
- `maxCount`: number | nil —— 最大堆叠数
- `name`: string —— 内部注册名
- `tags`: table\<string, boolean\> | nil —— 标签集合
- `nbt`: string | nil —— NBT 数据（用于区分相同物品的不同实例）

### `a546.Resource`

表示一种资源（物品或流体，以后也许会添加新类型）。

- `name`: string —— 资源名称
- `quantity`: number —— 数量
- `resourceType`: `"item"` | `"fluid"` | string —— 资源类型
- `nbt`: string | nil —— NBT 数据（仅对物品有意义）
- `detail`: nil | (fun(): a546.ItemStack | nil) —— 获取详细信息的函数

### `SlotOrName`

```lua
type SlotOrName = string | number
```

- 若为 **number**：表示物品槽位编号（从 1 开始）
- 若为 **string**：表示流体名称（如 `"water"`, `"lava"`）

### `LockReceipt`

```lua
type LockReceipt = string
```

由 `lock()` 或 `lockByCount()` 返回的唯一票据 ID，用于后续解锁操作。

---

## 类结构：`a546.ContainerStack`

### 字段说明

- `slots`: `table<SlotOrName, a546.Resource>`  
  当前容器中**可用**的资源缓存（键为槽位号或流体名）。
- `locks`: `table<LockReceipt, table<SlotOrName, a546.Resource>>`  
  已被**锁定**（不可用）的资源集合，按票据分组。
- `size`: `number | nil`  
  容器的物品槽总数；若仅为流体容器，则为 `nil`。
- `updateTime`: `number`  
  上次更新缓存的本地时间戳（通过 `os.epoch("local")` 获取）。
- `peripheralName`: `string`  
  关联的外设名称（如 `"left"`, `"minecraft:chest_0"` 等）。

---

## 静态方法

### `ContainerStack.isContainer(peripheralName: string): boolean`

判断指定外设是否为有效容器。

> **注意**：若外设不存在，会记录错误日志并返回 `false`。

---

## 实例方法

### 初始化与扫描

#### `:scan(peripheralName: string): ContainerStack | nil, errorMessage: string | nil`

- **功能**：完整扫描外设容器中的所有物品和流体，并初始化 `ContainerStack` 实例。
- **返回**：
  - 成功：返回自身（`self`）
  - 失败：返回 `nil` 和错误信息
- **适用场景**：首次创建容器缓存时使用。

#### `:scanBySlot(peripheralName: string, slot: number): ContainerStack | nil`

- **功能**：仅扫描指定槽位的物品（不处理流体）。
- **返回**：成功返回自身，失败返回 `nil`。
- **用途**：轻量级初始化，适用于只关心特定槽位的场景。

---

### 缓存更新

#### `:updata(slotOrName: SlotOrName | nil): boolean`

> ⚠️ 注意：方法名拼写为 `updata`（应为 `update`），但目前懒得改，观看者要是有时间可以考虑提PR。

- **功能**：
  - 若传入 `slotOrName`（数字或字符串）：仅更新该槽位/流体的缓存。
  - 若为 `nil`：调用 `:scan()` 全量更新。
- **返回**：操作是否成功。

---

### 资源访问

#### `:getContext(): table<SlotOrName, a546.Resource>`

- 返回当前**可用资源**（不包含锁定部分）的深拷贝。

#### `:getResource(lockReceipt: LockReceipt): table<SlotOrName, a546.Resource> | nil`

- 返回指定票据对应的**锁定资源**副本。

#### `:getLock(): table<string, table<...>>` （仅用于调试）

- 返回整个 `locks` 表的深拷贝。

---

### 资源锁定（事务预留）

#### `:lock(index: SlotOrName | SlotOrName[]): LockReceipt`

- **功能**：将指定槽位或流体**整体移入锁定区**（不再属于可用资源）。
- **参数**：可为单个或多个 `SlotOrName`。
- **返回**：唯一（短时间内）的 `LockReceipt` 票据。

**示例**：

```lua
local receipt = container:lock({1, "minecraft:water, 3"})
```

```lua
local receipt = container:lock("minecraft:water")
```

#### `:lockByCount(index: {slotOrName: SlotOrName, countOrAmount: number}[]): LockReceipt`

- **功能**：按**数量**锁定资源（部分锁定），原槽位数量相应减少。
- **要求**：请求的数量 ≤ 当前可用数量，否则抛出错误。
- **返回**：`LockReceipt`

**示例**：

```lua
local receipt = container:lockByCount({
  {slotOrName = 1, countOrAmount = 10},
  {slotOrName = "lava", countOrAmount = 500}
})
```

---

### 解锁与释放

#### `:unLock(lockReceipt: LockReceipt)`

- **功能**：将票据对应的锁定资源**归还**到可用资源中（自动合并同名资源）。
- **行为**：
  - 若票据不存在，记录警告但不报错。
  - 归还后改票据**失效**。

#### `:abolishLock(lockReceipt: LockReceipt)`

- **功能**：直接**丢弃**指定票据及其锁定的资源（不归还！）。
- **用途**：取消预留、超时释放等场景。

---

### 序列化与持久化

#### `:saveAsFile(outFile: string)`

- 将当前 `ContainerStack` 实例保存为文件（使用 `textutils.serialise`）。
- **注意**：会临时移除 `detail` 函数（因其不可序列化）。

#### `:reloadFromFile(reloadFile: string)`

- 从文件加载并恢复 `ContainerStack` 状态。
- **自动重建** `detail` 函数（通过闭包绑定 `peripheralName`）。

---

## 使用示例

```lua
local ContainerStack = require("ContainerStack")

-- 创建并扫描一个箱子
local chest = ContainerStack()
local success, err = chest:scan("left")
if not success then error(err) end

-- 锁定第1槽的64个物品和500mB水
local receipt = chest:lockByCount({
  {slotOrName = 1, countOrAmount = 64},
  {slotOrName = "water", countOrAmount = 500}
})

-- ... 执行某些操作

-- 验证锁定是否仍有效（容器未被外部修改）
if chest:isAvailable(receipt) then
  -- 可安全使用这些资源
  print("Resources are still available!")
end

-- 最终释放资源（归还）
chest:unLock(receipt)
```

---

## 注意事项

- **缓存时效性**：`slots` 是**快照缓存**，不代表实时状态。可以尝试在关键操作前调用 `:updata()` 或 `:scan()` 刷新；或是在操作失败后用这两个方法更新缓存。
- **NBT支持**：就像`getItemDetail`函数，物品的 NBT 会被记录。虽然这个nbt不包含任何可用信息，但可用于区分物品。
- **流体容器**：若容器**仅支持流体**（无 `list` 方法），则 `size` 为 `nil`。
- **错误处理**：多数方法在非法操作时会 `error()`，建议在外层使用 `pcall` 捕获。

---

## 依赖

- `lib.Object`：用于类继承
- `lib.log`：日志输出（默认输出到 `log.txt`）
- `lib.util`：提供 `copyTable` 和 `generateRandomString`

---
