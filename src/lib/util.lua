-- 这里放各种简单的工具

local out = {}

--- ...
---@generic T
---@param tTable T
---@param visited table
---@return T
local function _copyTable(tTable, visited)
    assert(type(tTable) == "table", "Need Table")
    local result = {}
    local metaTable = getmetatable(tTable)
    -- 已复制，直接返回
    if visited[tTable] then
        return visited[tTable]
    end
    setmetatable(result, metaTable)
    visited[tTable] = result
    for k, v in pairs(tTable) do
        if type(v) == "table" then
            result[k] = _copyTable(v, visited)
        else
            result[k] = v
        end
    end
    return result
end

--- 注意，该工具不复制元表和函数：处理到他们时会直接引用原值。
---@generic T
---@param tTable T
---@return T
function out.copyTable(tTable)
    return _copyTable(tTable, {})
end

--- 生成随机字符串
---@param length number # 字符串长度
---@return string
function out.generateRandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+-="
    local result = {}
    for i = 1, length do
        local rand = math.random(1, #chars)
        table.insert(result, chars:sub(rand, rand))
    end
    return table.concat(result)
end

--- 获取任意表包含的元素数量
---@param tTable table
---@return number
function out.len(tTable)
    local i = 0
    for _, _ in pairs(tTable) do
        i = i + 1
    end
    return i
end

return out
