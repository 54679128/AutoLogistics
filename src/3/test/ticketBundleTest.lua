require("_steup")
local ContainerStackM  = require("ContainerStack.ContainerStackM")
local Filter           = require("Filter")
local preDefinedFilter = require("preDefinedFilter")
local TransferTicketM  = require("ContainerStack.TransferTicketM")
local TicketBundle     = require("TicketBundle")


local left = ContainerStackM("left")
left:refresh()
local searchResult1 = left:search(preDefinedFilter.withName("minecraft:dirt"))
if not searchResult1 then
    error("Can't find any minecraft:dirt in left")
end
local searchResult2 = left:search(preDefinedFilter.withName("minecraft:glass"))
if not searchResult2 then
    error("Can't find any minecraft:glass in left")
end
local receipt1 = left:reserve(searchResult1)
if not receipt1 then
    error("Can't reserve resource by searchResult1")
end
local receipt2 = left:reserve(searchResult2)
if not receipt2 then
    error("Can't reserve resource by searchResult2")
end
local ticket1 = TransferTicketM(left, receipt1)
local ticket2 = TransferTicketM(left, receipt2)
local bundle = TicketBundle()
bundle:add(receipt1, ticket1)
bundle:add(receipt2, ticket2)
bundle:run("right")
