local Object           = require("lib.Object")
local ContainerStackM  = require("ContainerStack.ContainerStackM")
local util             = require("lib.util")
local TicketBundle     = require("TicketBundle")
local TransferTicketM  = require("ContainerStack.TransferTicketM")
local log              = require("lib.log")
local Filter           = require("Filter")
local preDefinedFilter = require("preDefinedFilter")

---@class a546.Warehouse
---@field package inputContainerList table<string,a546.ContainerStackM>
---@field package outputContainerList table<string,{container:a546.ContainerStackM,filter:a546.Filter}>
---@field package storageContainerList table<string,a546.ContainerStackM>
local Warehouse        = Object:extend()

---@cast Warehouse +fun():a546.Warehouse
function Warehouse:new()
    self.inputContainerList = {}
    self.outputContainerList = {}
    self.storageContainerList = {}
end

---@alias ContainerType
---| "input"
---| "output"
---| "storage"

local CONTAINER_TYPE = {
    input = {
        name = "inputContainerList",
        ---@param peripheralName string
        ---@param warehouse a546.Warehouse
        insert = function(peripheralName, warehouse)
            warehouse.inputContainerList[peripheralName] = ContainerStackM(peripheralName)
        end
    },
    output = {
        name = "outputContainerList",
        ---@param peripheralName string
        ---@param warehouse a546.Warehouse
        ---@param filter? a546.Filter
        insert = function(peripheralName, warehouse, filter)
            if not filter then
                filter = Filter(function(resource)
                    return true
                end)
            end
            warehouse.outputContainerList[peripheralName] = {
                container = ContainerStackM(peripheralName),
                filter =
                    filter
            }
        end
    },
    storage = {
        name = "storageContainerList",
        ---@param peripheralName string
        ---@param warehouse a546.Warehouse
        insert = function(peripheralName, warehouse)
            local storage = ContainerStackM(peripheralName)
            storage:refresh()
            warehouse.storageContainerList[peripheralName] = storage
        end
    }
}

--- 向仓库中添加容器
---@param peripheralName string
---@param containerType ContainerType
---@param filter? a546.Filter 仅在containerType为"output"时有用
---@return boolean
function Warehouse:add(peripheralName, containerType, filter)
    if not CONTAINER_TYPE[containerType] then
        return false
    end
    CONTAINER_TYPE[containerType].insert(peripheralName, self, filter)
    log.trace(("Add %s to type %s"):format(peripheralName, containerType))
    return true
end

--- 从仓库中移除容器
---@param peripheralName string
---@param containerType ContainerType
---@return boolean
function Warehouse:remove(peripheralName, containerType)
    if not CONTAINER_TYPE[containerType] then
        return false
    end
    local listName = CONTAINER_TYPE[containerType].name
    if not self[listName][peripheralName] then
        return false
    end
    self[listName][peripheralName] = nil
    return true
end

--- 查找仓库中的资源并返回结果
---@param filter a546.Filter
---@return table<string,searchResult>
function Warehouse:search(filter)
    log.trace(("Try search resource by %s"):format(filter.predicate))
    local result = {}
    for _, storage in pairs(self.storageContainerList) do
        local searchResult = storage:search(filter)
        result[storage.peripheralName] = searchResult
    end
    return result
end

--- 申请
---@param searchResult table<string,searchResult>
---@return a546.TicketBundle|nil
function Warehouse:getTicket(searchResult)
    log.trace(("Someone try to get a ticket"))
    ---@type table<string,Receipt>
    local receiptBook = {}
    -- 预定资源
    for name, sr in pairs(searchResult) do
        if not self.storageContainerList[name] then
            log.warn(("Peripheral %s isn't in Warehouse"):format(name))
            goto continue
        end
        local receipt = self.storageContainerList[name]:reserve(sr)
        if not receipt then
            log.error(("Peripheral %s haven't enough resource"):format(name))
            return nil
        end
        receiptBook[name] = receipt
        ::continue::
    end
    local bundle = TicketBundle()
    for name, receipt in pairs(receiptBook) do
        local ticket = TransferTicketM(self.storageContainerList[name], receipt)
        bundle:add(receipt, ticket)
    end
    log.trace(("Someone get a ticket %s"):format(bundle))
    return bundle
end

--- 随机刷新仓库内某个超过十秒未刷新的库存
---@private
function Warehouse:randomRefresh()
    ---@type a546.ContainerStackM[]
    local container = {}
    for _, v in pairs(self.storageContainerList) do
        if v.updateTime - os.epoch("local") < -10000 then
            table.insert(container, v)
        end
    end
    if #container < 1 then
        log.warn(("Try to refresh a storage,but have't any container that meet the criteria"))
        return
    end
    local randomIndex = math.random(#container)
    log.trace(("Try to refresh %s"):format(container[randomIndex].peripheralName))
    container[randomIndex]:refresh()
end

--- 随机向某个输出接口输出物品
---@private
function Warehouse:output()
    ---@type {container:a546.ContainerStackM,filter:a546.Filter}[]
    local container = {}
    for _, v in pairs(self.outputContainerList) do
        table.insert(container, v)
    end
    if #container < 1 then
        log.warn(("Try to find a outputContainer to output,but have't any output"))
        return
    end
    local randomIndex = math.random(#container)
    local randomOutput = container[randomIndex]
    local searchResult = self:search(randomOutput.filter)
    if not searchResult then
        return
    end
    local ticket = self:getTicket(searchResult)
    if not ticket then
        return
    end
    log.trace(("Try to output resource to %s"):format(randomOutput.container.peripheralName))
    ticket:run(randomOutput.container.peripheralName)
end

--- 随机从某个输入接口获取资源
---@private
function Warehouse:input()
    -- 预处理相关数据，检查是否符合要求
    ---@type a546.ContainerStackM[]
    local inputContainer = {}
    for _, v in pairs(self.inputContainerList) do
        table.insert(inputContainer, v)
    end
    if #inputContainer < 1 then
        log.warn(("Try to find a inputContainer to input,but have't any input"))
        return
    end
    -- 随机选一个输入接口作为处理对象
    local randomInputIndex = math.random(#inputContainer)
    local randomInput = inputContainer[randomInputIndex]
    randomInput:refresh()
    -- 获取该输入中存在的资源类型并分别构造支票

    ---@type table<string,a546.TransferTicketM>
    local ticketPackage = {}
    local inputResourceType = randomInput:getResourceType()
    if not next(inputResourceType) then -- 这说明该接口中没有存储任何资源
        return
    end
    for resourceType, _ in pairs(inputResourceType) do
        local tempSearchResult = randomInput:search(preDefinedFilter.withType(resourceType))
        if tempSearchResult then
            local receipt = randomInput:reserve(tempSearchResult)
            if not receipt then
                log.warn(("For some reason, can't reserve resource in input: %s"):format(randomInput.peripheralName))
                return
            end
            ticketPackage[resourceType] = TransferTicketM(randomInput, receipt)
        end
    end
    -- 查询存储列表中是否有可以存贮这些资源的容器
    ---@type table<string,a546.ContainerStackM[]>
    local storage = {}
    for _, container in pairs(self.storageContainerList) do
        local storageResourceType = container:getResourceType()
        if not next(storageResourceType) then
            log.trace(("Storage: %s can't storage any resource"):format(container.peripheralName))
        end
        for rType, _ in pairs(storageResourceType) do
            if inputResourceType[rType] then
                storage[rType] = storage[rType] or {}
                table.insert(storage[rType], container)
            end
        end
    end
    -- 检查是否有可以存储输入接口中资源的存储容器，如果没有，删除之前构造的相应支票；如果有，尝试随机选一个并使用支票
    for rType, ticket in pairs(ticketPackage) do -- 注意，有些模组的容器（精妙存储系列）会在没有安装储罐升级的情况下提供通用流体外设方法
        if not storage[rType] then
            ticketPackage[rType] = nil
            goto continue
        end
        local randomStorage = storage[rType][math.random(#storage[rType])] -- 随机选一个存储容器
        ticket:use(randomStorage.peripheralName)
        ::continue::
    end
    --[[
    local t = randomInput:search(Filter(function(resource)
        return true
    end))
    local i = 0
    while t and i < maxTry do
        ---@type a546.ContainerStackM[]
        local storage = {}
        for _, v in pairs(self.storageContainerList) do
            table.insert(storage, v)
        end
        if #storage < 1 then
            return
        end
        local randomStorageIndex = math.random(#storage)
        ---@cast t -nil
        local receipt = randomInput:reserve(t)
        if not receipt then
            return
        end
        local ticket = TransferTicketM(randomInput, receipt)
        ticket:use(storage[randomStorageIndex].peripheralName)
        randomInput:refresh()
        t = randomInput:search(Filter(function(resource)
            return true
        end))
        i = i + 1
    end
    ]]
end

-- 开启仓库事件循环
function Warehouse:run()
    local refreshInterval = 4
    local outputInterval = 1
    local inputInterval = 1.9

    local lastRefresh = os.epoch("local")
    local lastOutput = os.epoch("local")
    local lastInput = os.epoch("local")

    while true do
        -- 启动定时器
        os.startTimer(0)
        local eventData = { os.pullEvent("timer") }
        if os.epoch("local") - lastRefresh > refreshInterval * 1000 then
            log.trace("Refresh")
            self:randomRefresh()
            lastRefresh = os.epoch("local")
            log.trace("Refresh end")
        end
        if os.epoch("local") - lastOutput > outputInterval * 1000 then
            log.trace("Output")
            self:output()
            lastOutput = os.epoch("local")
            log.trace("Output end")
        end
        if os.epoch("local") - lastInput > inputInterval * 1000 then
            log.trace("Input")
            self:input()
            lastInput = os.epoch("local")
            log.trace("Input end")
        end
    end
end

return Warehouse
