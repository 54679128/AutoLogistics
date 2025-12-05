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

return out
