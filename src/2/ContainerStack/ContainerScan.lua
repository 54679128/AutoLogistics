local log = require "lib.log"

local out = {}

--- 将list的返回值转换为a546.Resource所要求的格式
---@param slot number
---@param itemInfo ccTweaked.peripherals.inventory.item
---@param peripheralName string
---@return a546.Resource
local function createItemResourceFormat(slot, itemInfo, peripheralName)
    ---@type a546.Resource
    local result = {
        name = itemInfo.name,
        quantity = itemInfo.count,
        resourceType = "item",
        nbt = itemInfo.nbt,
        detail = function()
            local per = peripheral.wrap(peripheralName)
            if not per then
                log.warn(("Peripheral %s doesn't exist"):format(peripheralName))
                return nil
            end
            return per.getItemDetail(slot)
        end
    }
    return result
end

--- 将tanks的返回值转换为a546.Resource所要求的格式
---@param fluidInfo {name:string,amount:number}
---@return a546.Resource
local function createFluidResourceFormat(fluidInfo)
    ---@type a546.Resource
    local result = {
        name = fluidInfo.name,
        quantity = fluidInfo.amount,
        resourceType = "fluid"
    }
    return result
end

--- 判断输入外设名所代表的外设是否为一个容器。
---@param peripheralName string
---@return boolean
function out.isContainer(peripheralName)
    local per = peripheral.wrap(peripheralName)
    local errMessage
    if not per then
        errMessage = ("Peripheral %s doesn't exist"):format(peripheralName)
        log.error(errMessage)
        return false
    end
    -- 物品容器
    if per.list and per.pullItems and per.pushItems then
        return true
    end
    -- 流体容器
    if per.tanks and per.pushFluid and per.pullFluid then
        return true
    end
    return false
end

--- 检测容器内容
---@param peripheralName string
---@return table<SlotOrName,a546.Resource>|nil
function out.scan(peripheralName)
    if not out.isContainer(peripheralName) then
        log.warn(("Peripheral %s isn't container"):format(peripheralName))
        return nil
    end
    local result = {}
    local per = peripheral.wrap(peripheralName)
    -- 经过了检查，所以per不可能为nil
    ---@cast per -nil
    if per.list then
        local list = per.list()
        for slot, itemInfo in pairs(list) do
            result[slot] = createItemResourceFormat(slot, itemInfo, peripheralName)
        end
    end
    if per.tanks then
        local tank = per.tanks()
        for _, fluidInfo in pairs(tank) do
            result[fluidInfo.name] = createFluidResourceFormat(fluidInfo)
        end
    end
    return result
end

return out
