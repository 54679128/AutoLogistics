local log = require("lib.log")
local Object = require("lib.Object")
local util = require("lib.util")
local ContainerStack = require("ContainerStack")

---@alias resourceName string
---@alias peripheralName string
---@alias quantity number

---@class a546.WarehouseManager
---@field lockKey table
---@field containerIndex table<string,a546.ContainerStack>
---@field resourceIndex table<resourceName,table<peripheralName,quantity>>
---@field inputInterface table<peripheralName,a546.ContainerStack>
---@field outputInterface table<peripheralName,boolean>
---@field remindInterface table<peripheralName,a546.ContainerStack>
local WarehouseManager = Object:extend()

function WarehouseManager:new()
    self.lockKey = {}
    self.containerIndex = {}
    self.resourceIndex = {}
end

--- 将容器作为存储容器加入仓库
---@param peripheralName string
---@return boolean success
---@deprecated
function WarehouseManager:addAsContainer(peripheralName)
    if not ContainerStack.isContainer(peripheralName) then
        log.warn(("Peripheral %s isn't container"):format(peripheralName))
        return false
    end
    local container = ContainerStack()
    container:scan(peripheralName)
    self.containerIndex[peripheralName] = container
    local resourceList = container:getContext()
    -- 计算资源总量

    -- 缓存资源总量
    ---@type table<resourceName,quantity>
    local tempResource = {}
    for _, resource in pairs(resourceList) do
        if not tempResource[resource.name] then
            tempResource[resource.name] = 0
        end
        tempResource[resource.name] = tempResource[resource.name] + resource.quantity
    end
    -- 将得到的资源总量写入缓存表中
    for name, quantity in pairs(tempResource) do
        if not self.resourceIndex[name] then
            self.resourceIndex[name] = {}
        end
        self.resourceIndex[name][peripheralName] = quantity
    end
    return true
end

--- 将某个存储用容器移出仓库
---@param peripheralName string
---@return boolean success
---@deprecated
function WarehouseManager:removeContainer(peripheralName)
    if not self.containerIndex[peripheralName] then
        log.warn(("Try to remove unist container %s"):format("peripheralName"))
        return false
    end
    self.containerIndex[peripheralName] = nil
    -- 更新资源缓存表
    for _, peripheralTable in pairs(self.resourceIndex) do
        if peripheralTable[peripheralName] then
            peripheralTable[peripheralName] = nil
        end
    end
    return true
end

--- 将某个容器作为仓库的输入接口
---@param peripheralName string
---@return boolean success
---@deprecated
function WarehouseManager:addAsInputInterface(peripheralName)
    if not self.containerIndex[peripheralName] then
        log.warn(("Peripheral %s isn't container"):format("peripheralName"))
        return false
    end
    local inputContainer = ContainerStack()
    inputContainer:scan(peripheralName)
    self.inputInterface[peripheralName] = inputContainer
    return true
end

--- 将某个容器作为仓库的输出接口
---@param peripheralName string
---@return boolean success
---@deprecated
function WarehouseManager:addAsOutputInterface(peripheralName)
    if not self.containerIndex[peripheralName] then
        log.warn(("Peripheral %s isn't container"):format("peripheralName"))
        return false
    end
    self.outputInterface[peripheralName] = true
    return true
end

--- 将某个容器作为仓库的保持接口
---@param peripheralName string
---@return boolean success
---@deprecated
function WarehouseManager:addAsRemindInterface(peripheralName)
    if not self.containerIndex[peripheralName] then
        log.warn(("Peripheral %s isn't container"):format("peripheralName"))
        return false
    end
    local remindContainer = ContainerStack()
    remindContainer:scan(peripheralName)
    self.inputInterface[peripheralName] = remindContainer
    return true
end

return WarehouseManager
