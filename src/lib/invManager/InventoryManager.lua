---@module "InventoryManager"

local Object = require("lib.Object")
local expect = require("cc.expect")
local MaterialEntry = require("lib.invManager.MaterialEntry")

---@class a546.InventoryManager:Object
---@field storages table<string,a546.MaterialEntry>
local InventoryManager = Object:extend()

---@cast InventoryManager +fun():a546.InventoryManager
function InventoryManager:new()
    self.storages = {}
end

--- 向记录中添加一项 MaterialEntry
---@param peripheralName string
---@param materialItem a546.MaterialEntry
function InventoryManager:add(peripheralName, materialItem)
    expect.expect(1, peripheralName, "string")
    if not materialItem.is or (not materialItem:is(MaterialEntry)) then
        --expect.expect(1, materialItem, "MaterialEntry")
        error(("otherMaterialEntry must be an instance of MaterialEntry"), 2)
    end
    self.storages[peripheralName] = materialItem
end

--- 根据外设名从表中获取对应的 MaterialEntry
---@param peripheralName string
---@return boolean # 是否获取成功
---@return string|a546.MaterialEntry # 如果获取成功，返回 MaterialEntry ；否则返回错误信息
function InventoryManager:get(peripheralName)
    expect.expect(1, peripheralName, "string")
    if not self.storages[peripheralName] then
        return false, ("peripheral %s does't exist"):format(peripheralName)
    end
    return true, self.storages[peripheralName]
end

--- 根据外设名从表中移除一项
---@param peripheralName string
function InventoryManager:remove(peripheralName)
    self.storages[peripheralName] = nil
end

--- 字面意思，返回内部字段
---@return table<string, a546.MaterialEntry>
function InventoryManager:getAll()
    return self.storages
end

--- 更新表中某项
---@param peripheralName string
---@param materialItem a546.MaterialEntry
---@param mode? a546.InventoryManager.mergeMode 默认为 add 。
function InventoryManager:update(peripheralName, materialItem, mode)
    -- 参数检查
    expect.expect(1, peripheralName, "string")
    if not materialItem.is or (not materialItem:is(MaterialEntry)) then
        error(("materialItem must be an instance of MaterialEntry"), 2)
    end
    -- 处理
    -- 该外设不存在
    if not self.storages[peripheralName] then
        self.storages[peripheralName] = textutils.unserialise(textutils.serialise(materialItem,
            { allow_repetitions = true }))
        return
    end
    -- 外设存在
    self.storages[peripheralName]:merge(materialItem, mode)
end

return InventoryManager
