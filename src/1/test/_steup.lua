-- steup不是setup的错误拼写

local function insertPath(path)
    package.path = ("%s;%s"):format(path, package.path)
end
-- 配置lua寻找模块的路径
local scriptSrcPath = debug.getinfo(1, "S").source:sub(2):match("(.*src[/\\])")
insertPath(scriptSrcPath .. "?.lua")
insertPath(scriptSrcPath .. "1/?.lua")
insertPath(scriptSrcPath .. "1/?/?.lua")
