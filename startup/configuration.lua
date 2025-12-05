local configurationFileName = "_steup.lua"
local testPathFeature = "test"

--- 寻找测试文件夹路径
---@param dir string
---@return table
local function searchTest(dir)
    local result = {}
    if not fs.exists(dir) then
        error(("path %s doesn't exists"):format(dir))
    end
    if dir:find(testPathFeature) then
        table.insert(result, dir)
    end
    local list = fs.list(dir)
    for i = 1, #list do
        local path = fs.combine(dir, list[i])
        if not fs.isDir(path) then
            goto continue
        end
        for _, v in pairs(searchTest(path)) do
            table.insert(result, v)
        end
        ::continue::
    end

    return result
end

local testPath = searchTest("")
for _, path in pairs(testPath) do
    local steupPath = fs.combine(path, configurationFileName)
    if fs.exists(steupPath) then
        fs.delete(steupPath)
    end
    fs.copy(fs.combine("resource", configurationFileName), steupPath)
end
