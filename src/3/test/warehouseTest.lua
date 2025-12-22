require("_steup")

local Warehouse = require("Warehouse")

local input = {
    ["sophisticatedbackpacks:backpack_2"] = true
}

local output = {
    ["sophisticatedbackpacks:backpack_3"] = true
}

local noContainer = {
    back = true
}

local testWarehouse = Warehouse()

for peripheralName, _ in pairs(input) do
    testWarehouse:add(peripheralName, "input")
end

for peripheralName, _ in pairs(output) do
    testWarehouse:add(peripheralName, "output")
end

for _, peripheralName in pairs(peripheral.getNames()) do
    if noContainer[peripheralName] then
        goto continue
    end
    if output[peripheralName] then
        goto continue
    end
    if input[peripheralName] then
        goto continue
    end
    testWarehouse:add(peripheralName, "storage")
    ::continue::
end

testWarehouse:run()
