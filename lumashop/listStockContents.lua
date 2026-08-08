local savePath = "/lumashop/catalog.sav"
local stockTicker = peripheral.find("Create_StockTicker")
if not stockTicker then
    error("Create_StockTicker peripheral not found")
end
local stockData = stockTicker.stock() -- this returns a table of all items in stock, as shown in following example comments
--{
--    {
--      name = "minecraft:stone",
--      count = 100,
--    },
--    {
--      name = "minecraft:dirt",
--      count = 50,
--    },
--}

local catalogContents = {}

if not fs.exists("/lumashop") then
    fs.makeDir("/lumashop")
end

if fs.exists(savePath) then
    local handle = fs.open(savePath, "r")
    if handle then
        local contents = handle.readAll()
        handle.close()
        catalogContents = textutils.unserialize(contents) or {}
    end
end

local function findCatalogEntry(id)
    for _, entry in ipairs(catalogContents) do
        if entry.id == id or entry.name == id then
            return entry
        end
    end
    return nil
end

for _, stockItem in ipairs(stockData) do
    local entry = findCatalogEntry(stockItem.name)
    if not entry then
        table.insert(catalogContents, {
            id = stockItem.name,
            name = stockItem.name,
            price = 0,
            pack = 1,
            description = "",
            locked = true,
            count = stockItem.count,
        })
    end
end

local handle = fs.open(savePath, "w")
handle.write(textutils.serialize(catalogContents))
handle.close()
