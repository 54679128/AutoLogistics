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

local cache = setmetatable({}, { __mode = "kv" })
--- 返回一个表的只读代理
---@generic T:table
---@param theTable T
---@return T
function out.readOnly(theTable)
    if cache[theTable] then
        return cache[theTable]
    end
    local proxy = {}
    local pMetaTable = {}

    cache[theTable] = proxy -- 缓存真实表
    cache[proxy] = proxy    -- 缓存只读代理

    pMetaTable.__index = function(t, k)
        local v = theTable[k]
        if type(v) == "table" then
            return out.readOnly(v)
        elseif type(v) == "function" then
            return function(firstParam, ...)
                -- local meta = getmetatable(firstParam)
                -- while meta do
                --     if meta == proxy then
                --         return v(theTable, ...)
                --     end
                --     meta = getmetatable(meta)
                -- end
                if firstParam == proxy then
                    return v(theTable, ...)
                else
                    return v(firstParam, ...)
                end
            end
        else
            return v
        end
    end
    pMetaTable.__newindex = function(t, k, v)
        error(("Can't set table: %s, key: %s to value: %s"):format(tostring(theTable), tostring(k), tostring(v)), 2)
    end
    pMetaTable.__len = function(t)
        return #theTable
    end
    pMetaTable.__pairs = function()
        return function(_, oldValue)
            local key, newValue = next(theTable, oldValue)
            if type(newValue) == "table" then
                return key, out.readOnly(newValue)
            else
                return key, newValue
            end
        end, nil, nil
    end
    pMetaTable.__call = function(_, ...)
        return theTable(...)
    end
    local originMetaTable = getmetatable(theTable)
    if originMetaTable then
        pMetaTable.__metatable = out.readOnly(getmetatable(theTable))
    else
        pMetaTable.__metatable = {}
    end
    setmetatable(proxy, pMetaTable)
    return proxy
end

return out
