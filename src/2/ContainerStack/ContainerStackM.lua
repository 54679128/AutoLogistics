local Object          = require "lib.Object"
local ContainerScan   = require "ContainerStack.ContainerScan"
local ResourceManager = require "ContainerStack.ResourceManager"
local log             = require "lib.log"

---@class a546.ContainerStackM
local ContainerStackM = Object:extend()

---@cast ContainerStackM +fun(peripheralName:string):a546.ContainerStackM
function ContainerStackM:new(peripheralName)
    self.peripheralName = peripheralName
    self.updateTime = os.epoch("local")
    self.resourceManager = ResourceManager()
end

--- 刷新内部资源缓存，使其与实际容器内容同步
---@return boolean success
function ContainerStackM:refresh()
    local resources = ContainerScan.scan(self.peripheralName)
    if not resources then
        log.warn(("Can't scan peripheral %s"):format(self.peripheralName))
        return false
    end
    self.resourceManager:update(resources)
    return true
end

--- 根据过滤器检查容器内部是否有符合要求的资源
---@param filter any
---@return searchResult|nil searchResult
function ContainerStackM:search(filter)
    return self.resourceManager:search(filter)
end

--- 请求向该容器预定一批资源
---@param searchResult searchResult
---@return Receipt|nil
function ContainerStackM:reserve(searchResult)
    return self.resourceManager:Order(searchResult)
end

--- 清理过期票据
function ContainerStackM:cleanupExpiration()
    self.resourceManager:cleanupExpiration()
end

--- 检查票据是否可用/存在
---@param receipt Receipt
---@return boolean
function ContainerStackM:isAvailable(receipt)
    return self.resourceManager:isAvailable(receipt)
end

--- 尝试取消预定，将资源释放回可用库存。取消预订后，该票据将失效
---@param receipt Receipt
function ContainerStackM:release(receipt)
    self.resourceManager:release(receipt)
end

--- 尝试删除错误或已消耗的预定记录
---@param receipt Receipt
function ContainerStackM:consume(receipt)
    self.resourceManager:consume(receipt)
end

--- 获取预留的资源信息
---@param receipt Receipt
---@return searchResult|nil
function ContainerStackM:getReserve(receipt)
    return self.resourceManager:getReserve(receipt)
end

return ContainerStackM

-- 如果你认为是这样，那么就是这样
