local log = require("lib.log")
local O = require("lib.Object")
local util = require("lib.util")

-- 票据有效时间，单位为秒
local ReceiptExpirationTime = 10

---@alias Receipt string
---@alias searchResult table<SlotOrName,{name:string,quantity:number}>

---@class a546.ResourceManager
---@field resources table<SlotOrName,a546.Resource>
---@field reserveResources table<Receipt,table<SlotOrName,a546.Resource>>
---@field createdAt table<Receipt,number>
local ResourceManager = O:extend()

---@cast ResourceManager +fun():a546.ResourceManager
function ResourceManager:new()
    self.resources = {}
    self.reserveResources = {}
    self.createdAt = {}
end

--- 清除所有过期的票据
function ResourceManager:cleanupExpiration()
    for receipt, _ in pairs(self.createdAt) do
        if not self:isAvailable(receipt) then
            self:release(receipt)
        end
    end
end

--- 更新可用资源列表
---@param resources table<SlotOrName,a546.Resource>
function ResourceManager:update(resources)
    self.resources = resources
end

--- 根据过滤器查找可用资源
---@param filter a546.Filter
---@return searchResult|nil searchResult
function ResourceManager:search(filter)
    ---@type searchResult|table
    local result = {}
    for slotOrName, resource in pairs(self.resources) do
        if not filter.predicate(resource) then
            goto continue
        end
        result[slotOrName] = { name = resource.name, quantity = resource.quantity }
        ::continue::
    end
    if not next(result) then
        return nil
    end
    return result
end

--- 请求预定一批资源
---@param searchResult searchResult
---@return Receipt|nil # 如果预定成功，返回票据；否则返回nil
function ResourceManager:Order(searchResult)
    -- 检查请求是否有效
    for slotOrName, resourceInfo in pairs(searchResult) do
        -- 检查资源是否存在
        if not self.resources[slotOrName] then
            log.warn(("Try to order doesn't exist resource %s"):format(textutils.serialise(resourceInfo)))
            return nil
        end
        -- 检查资源名是否与请求相符
        if self.resources[slotOrName].name ~= resourceInfo.name then
            log.warn(("Try to order doesn't exist resource %s"):format(textutils.serialise(resourceInfo)))
            return nil
        end
        -- 检查资源是否有足够的数量
        if self.resources[slotOrName].quantity < resourceInfo.quantity then
            log.warn(("There are not enough requests to fulfill the order %s"):format(textutils.serialise(resourceInfo)))
            return nil
        end
    end
    -- 生成唯一票据并记录创建时间
    local receipt = util.generateRandomString(math.random(10, 30))
    self.createdAt[receipt] = os.epoch("local")
    -- 将请求的资源从可用资源转移到预留资源中
    self.reserveResources[receipt] = {}
    for slotOrName, resourceInfo in pairs(searchResult) do
        local reserveResource = util.copyTable(self.resources[slotOrName])
        reserveResource.quantity = resourceInfo.quantity
        if (self.resources[slotOrName].quantity - resourceInfo.quantity) == 0 then
            self.resources[slotOrName] = nil
        else
            self.resources[slotOrName].quantity = self.resources[slotOrName].quantity - resourceInfo.quantity
        end
        self.reserveResources[receipt][slotOrName] = reserveResource
    end
    return receipt
end

--- 检查票据是否可用/存在
---@param receipt Receipt
---@return boolean
function ResourceManager:isAvailable(receipt)
    -- 检查票据是否存在
    if not self.createdAt[receipt] then
        log.warn(("Receipt %s doesn't exist"):format(receipt))
        return false
    end
    -- 检查票据是否过期
    local expirationTime = self.createdAt[receipt] + ReceiptExpirationTime * 1000
    if expirationTime < os.epoch("local") then
        return false
    end
    return true
end

--- 取消预定，将资源释放回可用库存
---@param receipt Receipt
function ResourceManager:release(receipt)
    local processTable = self.reserveResources[receipt]
    -- 票据不存在
    if not processTable then
        local errMessage = ("Try to release doesn't exist resource. Receipt: %s"):format(receipt)
        log.warn(errMessage)
        -- error(errMessage)
        return
    end
    -- 合并操作
    for i, v in pairs(processTable) do
        if not self.resources[i] then
            self.resources[i] = v
            --processTable[i] = nil 最后会丢弃整个表，在这里设置毫无意义
            goto continue
        end
        self.resources[i].quantity = self.resources[i].quantity + v.quantity
        ::continue::
    end
    -- 处理完毕，丢弃
    self.reserveResources[receipt] = nil
    self.createdAt[receipt] = nil
end

--- 删除错误或已消耗的预定记录
---@param receipt Receipt
---@param detail? {slotOrName:SlotOrName,quantity:number} 该参数允许你精细的指定什么资源应该消耗多少
function ResourceManager:consume(receipt, detail)
    --- 进行一些检查，以确保消耗不会出错
    ---@return boolean
    local function check()
        if not self.reserveResources[receipt] then
            log.warn(("Try to delete doesn't exist receipt %s"):format(receipt))
            return false
        end
        if not detail then
            return true
        end
        --[[
        if not (detail.quantity and detail.slotOrName) then
            log.warn(("Consume except detail: {slotOrName:number|string,quantity:number}, but get: {slotOrName:%s,quantity:%s}")
                :format(type(detail.slotOrName), type(detail.quantity)))
            return false
        end
        if type(detail.quantity) ~= "number" then
            log.warn(("Param detail.quantity should be number, but get: %s"):format(type(detail.quantity)))
        end
        ]]
        if not self.reserveResources[receipt][detail.slotOrName] then
            log.warn(("Try to delete doesn't exist resource, receipt: %s; resourceIndex: %s"):format(receipt,
                tostring(detail.slotOrName)))
            return false
        end
        if self.reserveResources[receipt][detail.slotOrName].quantity < detail.quantity then
            log.warn(("Try to delete too much resource, receipt: %s; resourceIndex: %s; try to delete quantity: %s")
                :format(receipt,
                    tostring(detail.slotOrName), tostring(detail.quantity)))
            return false
        end
        return true
    end
    --- 默认情况下消耗支票
    ---@param receipt Receipt
    local function normalConsume(receipt)
        self.reserveResources[receipt] = nil
        self.createdAt[receipt] = nil
    end
    --- 精细的消耗对应支票中的资源
    ---@param receipt Receipt
    ---@param detail {slotOrName:SlotOrName,quantity:number}
    local function detailConsume(receipt, detail)
        self.reserveResources[receipt][detail.slotOrName].quantity = self.reserveResources[receipt][detail.slotOrName]
            .quantity - detail.quantity
    end
    -- 主逻辑
    if not check() then
        return
    end
    if not detail then
        normalConsume(receipt)
    else
        detailConsume(receipt, detail)
    end
end

--- 获取预留的资源信息
---@param receipt Receipt
---@return searchResult|nil
function ResourceManager:getReserve(receipt)
    if not self:isAvailable(receipt) then
        log.warn(("Try to access unavailable receipt %s"):format(receipt))
        return nil
    end
    ---@type searchResult
    local result = {}
    for slotOrName, resource in pairs(self.reserveResources[receipt]) do
        result[slotOrName] = { name = resource.name, quantity = resource.quantity }
    end
    return result
end

return ResourceManager
