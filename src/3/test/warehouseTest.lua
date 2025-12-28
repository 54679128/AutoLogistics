require("_steup")

local WarehouseM = require("Warehouse.WarehouseM")
local runtimeW = require("Warehouse.runtimeW")
local preDefineInterface = require("Warehouse.preDefineInterface")

local input = {
    ["sophisticatedbackpacks:backpack_2"] = true
}

local output = {
    ["sophisticatedbackpacks:backpack_3"] = true
}

local noContainer = {
    back = true
}

local testWarehouse = WarehouseM()
for _, peripheralName in pairs(peripheral.getNames()) do
    if input[peripheralName] then
        goto continue
    end
    if output[peripheralName] then
        goto continue
    end
    if noContainer[peripheralName] then
        goto continue
    end
    testWarehouse:addStorage(peripheralName)
    ::continue::
end

local testInput = preDefineInterface.input(testWarehouse, "sophisticatedbackpacks:backpack_2", nil)
local testOutput = preDefineInterface.output(testWarehouse, "sophisticatedbackpacks:backpack_3", nil, nil)

local testRun = runtimeW(testWarehouse)
testRun:addInterface(testInput)
testRun:addInterface(testOutput)
testRun:run()
