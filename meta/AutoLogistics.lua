---@meta
---@module 'AutoLogistics'

-- ================================================================
-- 类型别名
-- ================================================================

--- 资源预定票据
---@alias Receipt string

--- 传输锁票据
---@alias LockReceipt string

--- 槽位或名称（数字 = 物品槽位，字符串 = 流体名）
---@alias SlotOrName string|number

--- 搜索结果：槽位/名称 -> {名称, 数量}
---@alias searchResult table<SlotOrName, {name: string, quantity: number}>

--- TransferTicketM 构造时的传输控制回调
---@alias TransferControlCallBack fun(tc: a546.TransferControl)

--- 单条指令的执行结果
---@alias TransferResult { transferResource: number, errMessage: nil|string }

-- ================================================================
-- 数据类
-- ================================================================

--- 物品详细信息（来自 getItemDetail）
---@class a546.ItemStack
---@field count    number                 物品数量（流体则为 amount）
---@field displayName string|nil           显示名称
---@field itemGroups {displayName: string, id: string}[]|{}
---@field maxCount number|nil              最大堆叠数
---@field name     string                  注册名
---@field tags     table<string, boolean>|nil
---@field nbt      string|nil

--- 资源描述（物品或流体）
---@class a546.Resource
---@field name         string                         资源名称
---@field quantity     number                         资源数量
---@field resourceType "item"|"fluid"|string          资源种类
---@field nbt          string|nil                     NBT 数据（可用于区分相同物品）
---@field detail       nil|(fun(): a546.ItemStack|nil) 获取物品详情的回调

--- 传输指令的元信息
---@class a546.CommandInfo
---@field command     a546.TransferCommandBase         传输指令实例
---@field slotOrName  SlotOrName                       源槽位或流体名
---@field name        string                           资源名称
---@field quantity    number                           传输数量

-- ================================================================
-- 第一层：传输指令相关
-- ================================================================

--- 传输指令基类
---@class a546.TransferCommandBase : Object
---@field commandType           string   指令种类标识
---@field handler               function 回调函数
---@field sourcePeripheralName  string   源外设名
---@field targetPeripheralName  string   目标外设名
local TransferCommandBase = {}

--- 注册指令类型和回调
---@param commandType string
---@param handler function
function TransferCommandBase:register(commandType, handler) end

--- 创建指令实例
---@param sourcePeripheralName string
---@param targetPeripheralName string
function TransferCommandBase:new(sourcePeripheralName, targetPeripheralName) end

--- 指令调用器：管理并批量执行传输指令
---@class a546.CommandInvoker
---@field commands a546.TransferCommandBase[]
local CommandInvoker = {}

--- 构造一个空的指令调用器
---@cast CommandInvoker +fun(): a546.CommandInvoker
function CommandInvoker:new() end

--- 向指令组中添加指令
---@param command a546.TransferCommandBase
function CommandInvoker:addCommand(command) end

--- 清除所有指令
function CommandInvoker:clear() end

--- 批量执行所有指令（按加入顺序）
---@return table<number, TransferResult>
function CommandInvoker:processAll() end

--- 流体传输指令
---@class a546.TransferFluid : a546.TransferCommandBase
---@field limit     number      传输上限
---@field fluidName string|nil  流体名称（nil 表示任意）
local TransferFluid = {}

---@cast TransferFluid +fun(source: string, target: string, limit?: number, fluidName?: string): a546.TransferFluid
function TransferFluid:new(source, target, limit, fluidName) end

--- 物品全量传输指令（将容器内所有物品转移到目标）
---@class a546.TransferItems : a546.TransferCommandBase
local TransferItems = {}

---@cast TransferItems +fun(sourcePeripheralName: string, targetPeripheralName: string): a546.TransferItems
function TransferItems:new(sourcePeripheralName, targetPeripheralName) end

--- 槽位到容器传输指令
---@class a546.TransferSlotToInventory : a546.TransferCommandBase
---@field sourceSlot number      源槽位
---@field limit      number|nil  传输上限
local TransferSlotToInventory = {}

---@cast TransferSlotToInventory +fun(sourcePeripheralName: string, targetPeripheralName: string, sourceSlot: number, limit?: number): a546.TransferSlotToInventory
function TransferSlotToInventory:new(sourcePeripheralName, targetPeripheralName, sourceSlot, limit) end

--- 槽位到槽位传输指令
---@class a546.TransferSlotToSlot : a546.TransferCommandBase
---@field sourceSlot number      源槽位
---@field targetSlot number      目标槽位
---@field limit      number|nil  传输上限
local TransferSlotToSlot = {}

---@cast TransferSlotToSlot +fun(sourcePeripheralName: string, sourceSlot: number, targetPeripheralName: string, targetSlot: number, limit?: number): a546.TransferSlotToSlot
function TransferSlotToSlot:new(sourcePeripheralName, sourceSlot, targetPeripheralName, targetSlot, limit) end

-- ================================================================
-- 第二层：过滤器
-- ================================================================

--- 资源过滤器
---@class a546.Filter
---@field predicate fun(resource: a546.Resource): boolean, number?  谓词函数：是否选取 + 可选数量
---@field name      string                                          过滤器名称
local Filter = {}

---@cast Filter +fun(predicate: (fun(resource: a546.Resource): boolean, number?), name?: string): a546.Filter
function Filter:new(predicate, name) end

--- 逻辑与（AND）
---@param filter a546.Filter
---@return a546.Filter
function Filter:And(filter) end

--- 逻辑或（OR）
---@param filter a546.Filter
---@return a546.Filter
function Filter:Or(filter) end

--- 逻辑非（NOT）
---@return a546.Filter
function Filter:Not() end

--- 预定义过滤器工厂模块
---@class preDefinedFilterModule
local preDefinedFilter = {}

--- 按名称过滤
---@param name string
---@return a546.Filter
function preDefinedFilter.withName(name) end

--- 按种类过滤
---@param resourceType "item"|"fluid"|string
---@return a546.Filter
function preDefinedFilter.withType(resourceType) end

--- 按堆叠数量过滤
---@param quantity number
---@return a546.Filter
function preDefinedFilter.withQuantity(quantity) end

--- 按标签过滤
---@param tag string
---@return a546.Filter
function preDefinedFilter.withTag(tag) end

--- 按 NBT 过滤
---@param nbt string
---@return a546.Filter
function preDefinedFilter.withNbt(nbt) end

--- 按显示名称过滤
---@param displayName string
---@return a546.Filter
function preDefinedFilter.withDisplayName(displayName) end

--- 按总数过滤（限制选取总量）
---@param limit number
---@return a546.Filter
function preDefinedFilter.withTotalQuantity(limit) end

-- ================================================================
-- 第二层：容器扫描
-- ================================================================

--- 容器扫描模块
---@class containerScanModule
local ContainerScan = {}

--- 判断外设是否为容器
---@param peripheralName string
---@return boolean
function ContainerScan.isContainer(peripheralName) end

--- 扫描容器内容
---@param peripheralName string
---@return table<SlotOrName, a546.Resource>|nil resources     扫描到的资源表
---@return table<"item"|"fluid"|string, boolean>|nil resourceType 容器支持的类型
function ContainerScan.scan(peripheralName) end

-- ================================================================
-- 第二层：资源管理与容器栈
-- ================================================================

--- 资源管理器：管理容器的可用/预留资源
---@class a546.ResourceManager
---@field private resources        table<SlotOrName, a546.Resource>
---@field private reserveResources table<Receipt, table<SlotOrName, a546.Resource>>
---@field private createdAt        table<Receipt, number>
local ResourceManager = {}

---@cast ResourceManager +fun(): a546.ResourceManager
function ResourceManager:new() end

--- 清除所有过期票据
function ResourceManager:cleanupExpiration() end

--- 更新可用资源列表
---@param resources table<SlotOrName, a546.Resource>
function ResourceManager:update(resources) end

--- 根据过滤器查找可用资源
---@param filter a546.Filter
---@return searchResult|nil
function ResourceManager:search(filter) end

--- 预定一批资源
---@param searchResult searchResult
---@return Receipt|nil  成功返回票据，否则 nil
function ResourceManager:Order(searchResult) end

--- 检查票据是否可用
---@param receipt Receipt
---@return boolean
function ResourceManager:isAvailable(receipt) end

--- 取消预定，释放资源回可用库存
---@param receipt Receipt
function ResourceManager:release(receipt) end

--- 消耗已预定的资源
---@param receipt Receipt
---@param detail? { slotOrName: SlotOrName, quantity: number }  精细指定消耗
function ResourceManager:consume(receipt, detail) end

--- 获取预留资源信息
---@param receipt Receipt
---@return searchResult|nil
function ResourceManager:getReserve(receipt) end

--- 容器栈管理器：封装单个容器的扫描、搜索、预定等操作
---@class a546.ContainerStackM
---@field peripheralName string
---@field updateTime      number
local ContainerStackM = {}

---@cast ContainerStackM +fun(peripheralName: string): a546.ContainerStackM
function ContainerStackM:new(peripheralName) end

--- 刷新内部缓存
---@return boolean success
function ContainerStackM:refresh() end

--- 获取容器可存储的资源类型
---@return table<string, boolean>
function ContainerStackM:getResourceType() end

--- 根据过滤器搜索资源
---@param filter a546.Filter
---@return searchResult|nil
function ContainerStackM:search(filter) end

--- 预定一批资源
---@param searchResult searchResult
---@return Receipt|nil
function ContainerStackM:reserve(searchResult) end

--- 清理过期票据
function ContainerStackM:cleanupExpiration() end

--- 检查票据是否可用
---@param receipt Receipt
---@return boolean
function ContainerStackM:isAvailable(receipt) end

--- 取消预定
---@param receipt Receipt
function ContainerStackM:release(receipt) end

--- 消耗预定记录
---@param receipt Receipt
---@param detail? { slotOrName: SlotOrName, quantity: number }
function ContainerStackM:consume(receipt, detail) end

--- 获取预留资源信息
---@param receipt Receipt
---@return searchResult|nil
function ContainerStackM:getReserve(receipt) end

--- 传输控制器：将搜索结果转换为具体传输指令
---@class a546.TransferControl : Object
local TransferControl = {}

---@overload fun(resourceList: searchResult, commandStorageList: table, source: string, target: string): a546.TransferControl
function TransferControl:new(resourceList, commandStorageList, source, target) end

--- 将指定槽位资源分配到目标容器（不限制目标槽位）
---@param slot integer
function TransferControl:to(slot) end

--- 将指定槽位资源分配到目标容器指定槽位
---@param slot       integer
---@param targetSlot integer
---@param quantity?  integer
function TransferControl:toSlot(slot, targetSlot, quantity) end

--- 将剩余未分配资源全部按默认方式分配
function TransferControl:defaultAllocate() end

--- 获取剩余未分配的资源列表（只读）
---@return searchResult
function TransferControl:getResourceList() end

--- 传输票据：封装一次资源预定 + 传输操作
---@class a546.TransferTicketM
local TransferTicketM = {}

---@cast TransferTicketM +fun(containerStack: a546.ContainerStackM, receipt: Receipt, transferControl?: TransferControlCallBack): a546.TransferTicketM
function TransferTicketM:new(containerStack, receipt, transferControl) end

--- 检查票据是否仍然有效
---@return boolean
function TransferTicketM:isAvailable() end

--- 使用票据执行传输（票据只能使用一次）
---@param targetPeripheralName string
---@return boolean
function TransferTicketM:use(targetPeripheralName) end

-- ================================================================
-- 模块主表（require("AutoLogistics") 的返回值）
-- ================================================================

---@class AutoLogistics
---@field CommandInvoker        a546.CommandInvoker
---@field TransferFluid         a546.TransferFluid
---@field TransferItems         a546.TransferItems
---@field TransferSlotToInventory a546.TransferSlotToInventory
---@field TransferSlotToSlot    a546.TransferSlotToSlot
---@field Filter                a546.Filter
---@field preDefinedFilter      preDefinedFilterModule
---@field ContainerScan         containerScanModule
---@field ContainerStackM       a546.ContainerStackM
---@field ResourceManager       a546.ResourceManager
---@field TransferTicketM       a546.TransferTicketM
local M = {}

return M
