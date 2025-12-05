---@module "MaterialEntry"

local Object = require("lib.Object")
local expect = require("cc.expect")

---@class a546.MaterialEntry:Object
---@field materials table<string,{materialType:"item"|"fluid"|string,materialCount:number}>
local MaterialEntry = Object:extend()

---@cast MaterialEntry +fun():a546.MaterialEntry
function MaterialEntry:new()
    self.context = {}
end

--- 返回该项中对应种类原料总数
---@return number totalItemCount
---@return number totalFluidCount
function MaterialEntry:getTotalCount()
    local totalFluidCount = 0
    local totalItemCount = 0
    for _, info in pairs(self.context) do
        if info.materialType == "item" then
            totalItemCount = totalItemCount + info.materialCount
        else
            totalFluidCount = totalFluidCount + info.materialCount
        end
    end
    return totalItemCount, totalFluidCount
end

--- 判空
---@return boolean
function MaterialEntry:isEmpty()
    return next(self.context) == nil
end

--- 检查是否包含某个材料
---@param materialName string
---@return boolean
function MaterialEntry:contains(materialName)
    return self.context[materialName] ~= nil
end

--- 获取所有材料名称
---@return string[]
function MaterialEntry:getAllMaterials()
    local result = {}
    for name in pairs(self.context) do
        table.insert(result, name)
    end
    return result
end

--- 向表中添加一条记录，如果原先存在名称相同的记录，则最初的记录会被抛弃。
---@param materialName string
---@param materialType "item"|"fluid"|string
---@param materialCount number
function MaterialEntry:set(materialName, materialType, materialCount)
    expect.expect(1, materialName, "string")
    expect.expect(2, materialType, "string")
    expect.expect(3, materialCount, "number")
    ---@diagnostic disable-next-line: missing-parameter
    expect.range(materialCount, 0)
    self.context[materialName] = { materialType = materialType, materialCount = materialCount }
end

--- 根据原料名称从表中提取该记录相关信息（也就是种类和数量)。
--- 在参数不为 string 时抛出错误。
---@param materialName string
---@return boolean success 该记录是否存在
---@return { materialType: string|"fluid"|"item", materialCount: number }|nil
function MaterialEntry:get(materialName)
    expect.expect(1, materialName, "string")
    if not self.context[materialName] then
        return false
    end
    return true, self.context[materialName]
end

---@alias a546.InventoryManager.mergeMode
---| "set" 设置冲突记录的值为参数项的记录值。
---| "add" 设置冲突记录的值为两者之和。
---| "remove" 设置冲突记录的值为原值减去参数项记录的值。

--- 将当前表与 otherMaterialEntry 合并，anotherMaterialItem 可在合并后抛弃。
---@param otherMaterialEntry a546.MaterialEntry
---@param mode? a546.InventoryManager.mergeMode 默认为 add 。
function MaterialEntry:merge(otherMaterialEntry, mode)
    -- 参数验证
    if not otherMaterialEntry.is or (not otherMaterialEntry:is(MaterialEntry)) then
        error(("otherMaterialEntry is't MaterialEntry"), 2)
    end
    local validMode = { set = true, add = true, remove = true }
    if not validMode[mode] then
        error(("mode must be set or add or remove, but get %s"):format(tostring(mode)))
    end
    -- 参数处理
    mode = mode or "add"
    -- 处理
    for materialName, MaterialContext in pairs(otherMaterialEntry.context) do
        local existing = self.context[materialName]

        if not existing then
            -- otherMaterialEntry 有而 self 没有的记录
            -- self.context[materialName] = textutils.unserialise(textutils.serialise(MaterialContext))
            self.context[materialName] = {
                materialType = MaterialContext.materialType,
                materialCount = MaterialContext.materialCount
            }
        else
            -- 两者都有的记录
            -- 根据 mode 判断怎么处理

            -- 不能为不存在的键分配值，但可以修改现有的值
            -- 我是初学者，所以我写了这个注释防止以后我忘掉
            local finalValue
            if mode == "set" then
                finalValue = MaterialContext.materialCount
            elseif mode == "add" then
                finalValue = self.context[materialName].materialCount + MaterialContext.materialCount
            elseif mode == "remove" then
                finalValue = self.context[materialName].materialCount - MaterialContext.materialCount
            end
            -- 运算检查，理论上没有任何一种原料的量可以为负数。
            -- 不过也许某些mod有这种想法？不过我还没见到。
            if finalValue < 0 then
                error(("materialCount can't be negative after operation: %s"):format(materialName), 2)
            end
            self.context[materialName].materialCount = finalValue
        end
    end
end

return MaterialEntry
