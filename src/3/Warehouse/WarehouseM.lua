local Object           = require "lib.Object"
local ContainerScan    = require "ContainerStack.ContainerScan"
local log              = require "lib.log"
local ContainerStackM  = require "ContainerStack.ContainerStackM"
local TicketBundle     = require("TicketBundle")
local TransferTicketM  = require("ContainerStack.TransferTicketM")
local preDefinedFilter = require("preDefinedFilter")
local Filter           = require("Filter")

---@class a546.WarehouseM
---@field private storage table<string,a546.ContainerStackM>
local WarehouseM       = Object:extend()

---@cast WarehouseM +fun():a546.WarehouseM
function WarehouseM:new()
    self.storage = {}
end

--- 将一个容器设为仓库的可用库存
---@param peripheralName string
---@return boolean # 是否成功添加。如果失败，相关信息会记录在日志中。
function WarehouseM:addStorage(peripheralName)
    if not ContainerScan.isContainer(peripheralName) then
        log.warn(("Peripheral: %s doesn't exist or can't be warp"):format(peripheralName))
        return false
    end
    local newStorage = ContainerStackM(peripheralName)
    newStorage:refresh()
    self.storage[peripheralName] = newStorage
    return true
end

--- 将一个容器从仓库的可用库存中移除
---@param peripheralName string
---@return boolean|a546.ContainerStackM # 如果成功，则返回被移除的容器对应的 `ContainerStackM` ；否则会在日志中记录相关错误信息
function WarehouseM:removeStorage(peripheralName)
    if not self.storage[peripheralName] then
        log.warn(("Try to remove doesn't exist storage: %s"):format(peripheralName))
        return false
    end
    local temp = self.storage[peripheralName]
    self.storage[peripheralName] = nil
    return temp
end

--- 查找仓库中的资源并返回结果
---@param filter a546.Filter
---@return table<string,searchResult>
function WarehouseM:search(filter)
    log.trace(("Try search resource by %s"):format(filter.predicate))
    local result = {}
    for _, storage in pairs(self.storage) do
        local searchResult = storage:search(filter)
        result[storage.peripheralName] = searchResult
    end
    return result
end

--- 申请
---@param searchResult table<string,searchResult>
---@return a546.TicketBundle|nil
function WarehouseM:getTicket(searchResult)
    log.trace(("Someone try to get a ticket"))
    ---@type table<string,Receipt>
    local receiptBook = {}
    -- 预定资源
    for name, sr in pairs(searchResult) do
        if not self.storage[name] then
            log.warn(("Peripheral %s isn't in Warehouse"):format(name))
            goto continue
        end
        local receipt = self.storage[name]:reserve(sr)
        if not receipt then
            log.error(("Peripheral %s haven't enough resource"):format(name))
            return nil
        end
        receiptBook[name] = receipt
        ::continue::
    end
    local bundle = TicketBundle()
    for name, receipt in pairs(receiptBook) do
        local ticket = TransferTicketM(self.storage[name], receipt)
        bundle:add(receipt, ticket)
    end
    log.trace(("Someone get a ticket %s"):format(bundle))
    return bundle
end

--- 从容器内收取资源
---@param containers a546.ContainerStackM
---@param filter a546.Filter
function WarehouseM:input(containers, filter)
    local inputResourceType = containers:getResourceType()
    if not next(inputResourceType) then -- 不能存储任何资源，可能是容器没有初始化
        return
    end
    ---@type table<string,searchResult>
    local typeSearchResult = {}
    -- 使用提供的过滤器获取结果，再与用类型过滤器获取的结果求交集，得到一个按资源类型分类的搜索结果
    -- 上面纯傻逼，为什么不直接用filter:And(preDefinedFilter.withType(rType))？

    for rType, _ in pairs(inputResourceType) do
        local rTypeSearchResult = containers:search(filter:And(preDefinedFilter.withType(rType)))
        if not rTypeSearchResult then
            goto continue
        end
        typeSearchResult[rType] = rTypeSearchResult
        ::continue::
    end
    -- 使用上一步得到的资源类型预定资源并构造支票

    ---@type table<string,a546.TransferTicketM>
    local ticketPackage = {}
    for rType, sr in pairs(typeSearchResult) do
        local receipt = containers:reserve(sr)
        if not receipt then
            log.warn(("For some reason, can't reserve resource in container: %s"):format(containers.peripheralName))
            return
        end
        ticketPackage[rType] = TransferTicketM(containers, receipt)
    end
    -- 查询存储列表中是否有可以存贮这些资源的容器

    ---@type table<string,a546.ContainerStackM[]>
    local storage = {}
    for _, container in pairs(self.storage) do
        local storageResourceType = container:getResourceType()
        if not next(storageResourceType) then
            log.trace(("Storage: %s can't storage any resource"):format(container.peripheralName))
            goto continue
        end
        for rType, _ in pairs(storageResourceType) do
            if inputResourceType[rType] then
                storage[rType] = storage[rType] or {}
                table.insert(storage[rType], container)
            end
        end
        ::continue::
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
end

--- 向容器输出资源
---@param containers a546.ContainerStackM
---@param filter a546.Filter
function WarehouseM:output(containers, filter)
    local randomOutput = containers
    local searchResult = self:search(filter)
    if not searchResult then
        return
    end
    local ticket = self:getTicket(searchResult)
    if not ticket then
        return
    end
    log.trace(("Try to output resource to %s"):format(containers.peripheralName))
    ticket:run(containers.peripheralName)
end

return WarehouseM
