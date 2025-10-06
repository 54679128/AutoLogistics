local inventorys = table.pack(peripheral.find("inventory"))
local chests = { input = {}, left = {}, right = {}, buffer = {} }
local Buffer = require("buffer")

local function getLength(aTable)
    local i = 0
    for _, _ in pairs(aTable) do
        i = i + 1
    end
    return i
end

---接收一个或一组外设名，判断这些外设（只能是通用流体外设或通用物品外设）是否都为空
---@param peripheralNames string|table<number,string>
---@return boolean
local function isEmpty(peripheralNames)
    if type(peripheralNames) == "table" then
        for _, peripheralName in pairs(peripheralNames) do
            local unknowStorge = peripheral.wrap(peripheralName)
            if not unknowStorge then
                error(peripheralName .. "doesn't exsits")
            end
            if unknowStorge.tanks then
                local fluidTanks = unknowStorge.tanks()
                for _, fluidInfo in pairs(fluidTanks) do
                    if fluidInfo then
                        return false
                    end
                end
            end
            if unknowStorge.list then
                local itemList = unknowStorge.list()
                for _, itemInfo in pairs(itemList) do
                    if itemInfo then
                        return false
                    end
                end
            end
        end
        return true
    end
    if type(peripheralNames) == "string" then
        local itemList = peripheral.wrap(peripheralNames).list()
        for _, itemInfo in pairs(itemList) do
            if itemInfo then
                return false
            end
        end
        print("ture")
        return true
    end
    error("perppheralName is't a string or table", 2)
end

---返回一个或一系列容器中的原料名
---@param storges string|table
---@return unknown
local function getMaterials(storges)
    if type(storges) == "string" then
        storges = { storges }
    end
    return nil
end

---从缓存向一系列目标容器均匀转移物品
---@param name string
---@param buffer a54679128.Buffer
---@param target table{ccTweaked.peripherals.Inventory,...}
local function uniformToTarget(name, buffer, target)
    local itemTotalCount = 0
    local itemList = buffer:list()
    for slot, item in pairs(itemList) do
        if item.name ~= name then
            goto continue
        end
        itemTotalCount = itemTotalCount + item.count
        ::continue::
    end
    --计算每个容器应得到的原料数量
    local portion = itemTotalCount / getLength(target)
    for _, p in pairs(target) do
        buffer:output(peripheral.getName(p), name, portion)
    end
end

---获取一组通用库存外设的物品总数。你不必保证所有外设都是通用库存外设
---@param peripheralNames table<number,string>
---@return number
local function getItemCount(peripheralNames)
    local result = 0
    for _, peripheralName in pairs(peripheralNames) do
        local comStorge = peripheral.wrap(peripheralName)
        if not comStorge then
            error(peripheralName .. " does't exist", 3)
        end
        if comStorge.list then
            local itemList = comStorge.list()
            for _, itemInfo in pairs(itemList) do
                result = result + itemInfo.count
            end
        end
    end
    return result
end

---获取一组通用流体库存外设的物品总数。你不必保证所有外设都是通用流体库存外设
---@param peripheralNames table<number,string>
---@return number
local function getFulidCount(peripheralNames)
    local result = 0
    for _, peripheralName in pairs(peripheralNames) do
        local comStorge = peripheral.wrap(peripheralName)
        if not comStorge then
            error(peripheralName .. " does't exist", 3)
        end
        if comStorge.tanks then
            local fluidTanks = comStorge.tanks()
            for _, fluidInfo in pairs(fluidTanks) do
                result = result + fluidInfo.amount
            end
        end
    end
    return result
end

---用于判断指定的一个或一组输入是否准备好传输物品
---@param peripheralNames string|table<number,string>
local function waitForReady(peripheralNames)
    if type(peripheralNames) == "string" then
        peripheralNames = { peripheralNames }
    end
    while true do
        local itemLastCount = 0
        local itemNewCount = 0
        local fluidLastCount = 0
        local fluidNewCount = 0
        itemLastCount = getItemCount(peripheralNames)
        fluidLastCount = getFulidCount(peripheralNames)
        sleep(2)
        itemNewCount = getItemCount(peripheralNames)
        fluidNewCount = getFulidCount(peripheralNames)
        if itemLastCount == itemNewCount and fluidLastCount == fluidNewCount then
            break
        end
        print("isn't ready")
    end
    print("ready")
end

---将各个容器按特征分类
---@return table<string,table<number,string>>
local function classifyByFeatures()
    local aChests = {}
    -- 用名字分类
    for k, inventory in pairs(inventorys) do
        if k == "n" then
            goto continue
        end
        local peripheralType = peripheral.getName(inventory)
        local name = string.match(peripheralType, "^(.+)_%d+$")
        if not aChests[name] then
            aChests[name] = {}
        end
        table.insert(aChests[name], peripheral.getName(inventory))
        ::continue::
    end
    -- 用物品分类
    for k, inventory in pairs(inventorys) do
        if k == "n" then
            goto continue
        end
        local itemList = inventory.list()
        local blackList = {}
        for _, item in pairs(itemList) do
            local name = item.name
            if not aChests[name] then
                aChests[name] = {}
            end
            if not blackList[name] then
                table.insert(aChests[name], peripheral.getName(inventory))
                blackList[name] = true
            end
        end
        ::continue::
    end
    return aChests
end

---按特征展示分类结果
---@param featureTable table 使用classifyByFeatures函数得到
---@see classifyByFeatures
local function displayClassificationByFeatures(featureTable)
    parallel.waitForAny(function()
        for characterized, talee in pairs(featureTable) do
            textutils.slowPrint("These containers:")
            for _, inventory in pairs(talee) do
                textutils.slowPrint(inventory)
            end
            textutils.slowPrint("Characterized by: " .. characterized)
        end
    end, function()
        os.pullEvent("key_up")
        term.clear()
        term.setCursorPos(1, 2)
    end)
end

---comment
---@param featureTable table {input = ...,buffer = ...,output = {1 = {...},2={...},...}}
local function configureInputAndOutput(featureTable)
    local outputIndex = 0
    local out = {}
    local feature = {}
    for characteristic, _ in pairs(featureTable) do
        table.insert(feature, characteristic)
    end
    local operations = {
        input = function()
            print("Choose input feature: ")
            local choice = read(nil, feature)
            out["input"] = featureTable[choice]
            return choice
        end,
        buffer = function()
            print("Choose buffer feature: ")
            local choice = read(nil, feature)
            out["buffer"] = featureTable[choice]
            return choice
        end,
        output = function()
            print("Choose output feature: ")
            local choice = read(nil, feature)
            if not out["output"] then
                out["output"] = {}
            end
            print("Need custom name?(y/n)")
            local ans = read(nil, { "y", "n" })
            if string.lower(ans) == "y" then
                local customName = read(nil);
                (out["output"])[customName] = featureTable[choice];
            else
                table.insert(out["output"], featureTable[choice])
            end
            return choice
        end
    }
    while true do
        print("Set input/output/buffer: ")
        local operationsType = read(nil, { "input", "buffer", "output", "exit" })
        if operationsType == "exit" then
            if out["input"] == nil then
                printError("Must have input")
                goto continue
            elseif out["buffer"] == nil then
                printError("Must have buffer")
                goto continue
            elseif out["output"] == nil then
                printError("Must have output")
                goto continue
            end
            break
        end
        if not operations[operationsType] then
            printError("error")
            goto continue
        end
        operations[operationsType]()
        ::continue::
    end
    return out
end

local function saveConfiguredFile(configuredTable)
    local file = io.open("ItemAllocationConfigured.txt", "w+")
    if not file then
        error("can't save configure")
    end
    file:write(textutils.serialise(configuredTable, { allow_repetitions = true }))
    file:close()
end

local function configurationFileExist()
    local file = io.open("ItemAllocationConfigured.txt", "r")
    if file then
        return true
    end
    return false
end

---均匀分配
---@param buffer a54679128.Buffer
---@param output table
local function uniformAllocation(buffer, output)
    local List = buffer:list()
    local outputNum = 0
    local outputList = {}
    -- 暂时只考虑output不包含流体容器的情况
    for _, dable in pairs(output) do
        for _, name in pairs(dable) do
            table.insert(outputList, name)
        end
        outputNum = outputNum + getLength(dable)
    end
    for _, outputName in pairs(outputList) do
        for name, info in pairs(List) do
            buffer:output(outputName, name, info.num / outputNum)
        end
    end
end

--配置输入输出
---@alias ConTable { input: string, buffer: string, output: table }
local configuredTable
if not configurationFileExist() then
    local featureTable = classifyByFeatures()
    displayClassificationByFeatures(featureTable)
    ---@cast configuredTable ConTable
    configuredTable = configureInputAndOutput(featureTable)
    saveConfiguredFile(configuredTable)
    print("Configuration completed, you can remove the items previously used for configuration from the container")
else
    -- 如果已经存在配置文件，调用
    local file = io.open("ItemAllocationConfigured.txt", "r")
    if file then
        file:seek("set")
        ---@cast configuredTable ConTable
        configuredTable = textutils.unserialise(file:read("a"))
    end
end

while true do
    if not configuredTable then
        error("unknown error")
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    local bufferContainer = Buffer:asBuffer(configuredTable.buffer)
    if not isEmpty(configuredTable.input) then
        waitForReady(configuredTable.input)
        bufferContainer:input(configuredTable.input)
        -- 我希望getMaterials能返回所有的原料，但是我对于返回一个表还是返回一系列值有点烦恼
        -- 决定了，让buffer模块自己返回一个表
        local materialList = bufferContainer:list()
        for _, name in pairs(materialList) do
            print(name)
        end
        -- 之后是策略部分，提供buffer对象和一系列输出对象，让策略自行决定如何分配
        -- 现在，我只写一个简单的均匀分配
        --uniformToTarget(secondMaterialName, bufferContainer, tempSecond)
        uniformAllocation(bufferContainer, configuredTable.output)
    end
    sleep(2)
end
