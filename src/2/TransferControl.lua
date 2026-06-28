local Object                  = require("lib.Object")
local TransferSlotToInventory = require("1.commands.TransferSlotToInventory")
local log                     = require("lib.log")
local TransferSlotToSlot      = require("1.commands.TransferSlotToSlot")
local TransferFluid           = require("1.commands.TransferFluid")
local util                    = require("lib.util")

---@class a546.CommandInfo
---@field command a546.TransferCommandBase
---@field slotOrName number|string
---@field name string
---@field quantity number

---@class a546.TransferControl:Object
---@overload fun(resourceList:searchResult, commandStorageList:table, source:string, target:string):a546.TransferControl
local out                     = Object:extend()

---@param resourceList searchResult
---@param commandStorageList a546.TransferCommandBase[]
---@param source string 原容器名
---@param target string 目标容器名
---@protected
function out:new(resourceList, commandStorageList, source, target)
    ---@private
    self.resourceList = resourceList
    ---@private
    self.command = commandStorageList
    ---@private
    self.source = source
    ---@private
    self.target = target
end

--- 自动放入目标容器，不在意目标槽位和源槽位资源数量
---@param slot integer
function out:to(slot)
    if not self.resourceList[slot] then
        log.error(("Attempt to allocate non-existence resource: slot %d."):format(slot))
        return
    end
    ---@type a546.CommandInfo
    local tempStruct = {
        command = TransferSlotToInventory(self.source, self.target, slot),
        slotOrName = slot,
        name = self.resourceList[slot].name,
        quantity = self.resourceList[slot].quantity
    }
    table.insert(self.command, tempStruct)
    self.resourceList[slot] = nil
end

--- 详细分配资源去向，可以指定目标槽位和具体数量
---@param slot integer
---@param targetSlot integer
---@param quantity? integer
function out:toSlot(slot, targetSlot, quantity)
    if not self.resourceList[slot] then
        log.error(("Attempt to allocate non-existence resource: slot %d."):format(slot))
        return
    end
    if quantity and quantity <= 0 then
        log.error(("Attempt to allocate not legal quantity: %d"):format(quantity))
        return
    end
    if quantity and self.resourceList[slot].quantity < quantity then
        log.error(("Ask %d resource but only have %d resource"):format(quantity, self.resourceList[slot].quantity))
        return
    end
    ---@type a546.CommandInfo
    local tempStruct = {
        command = TransferSlotToSlot(self.source, slot, self.target, targetSlot, quantity),
        slotOrName = slot,
        name = self.resourceList[slot].name,
        quantity = quantity or self.resourceList[slot].quantity
    }
    table.insert(self.command, tempStruct)
    if not quantity or quantity == self.resourceList[slot].quantity then
        self.resourceList[slot] = nil
    elseif self.resourceList[slot].quantity > quantity then
        self.resourceList[slot].quantity = self.resourceList[slot].quantity - quantity
    end
end

function out:defaultAllocate()
    for slotOrName, resource in pairs(self.resourceList) do
        if type(slotOrName) == "number" then
            ---@type a546.CommandInfo
            local tempStruct = {
                command = TransferSlotToInventory(self.source, self.target, slotOrName),
                slotOrName = slotOrName,
                name = resource.name,
                quantity = resource.quantity
            }
            table.insert(self.command, tempStruct)
        else
            ---@cast slotOrName string
            ---@type a546.CommandInfo
            local tempStruct = {
                command = TransferFluid(self.source, self.target, resource.quantity, slotOrName),
                slotOrName = slotOrName,
                name = resource.name,
                quantity = resource.quantity
            }
            table.insert(self.command, tempStruct)
        end
    end
    self.resourceList = {}
end

--- 获取资源列表
---@return searchResult
function out:getResourceList()
    local proxy = util.readOnly(self.resourceList)
    return proxy
end

return out
