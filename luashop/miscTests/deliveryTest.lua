local ticker = peripheral.find("Create_StockTicker")
io.write("addr:")

local order = {
    address = read(),
}
print()
io.write("items:")
order.items = textutils.unserialize(read())

local function canFulfill(order)
    local stock = ticker.stock(true)
    local available = {}

    for _, item in ipairs(stock) do
        available[item.name] = (available[item.name] or 0) + item.count
    end

    -- Check every order line
    for _, requested in ipairs(order.items) do
        local itemName = requested[1]
        local amount = requested[2]
        local inStock = available[itemName] or 0

        if inStock < amount then
            return false
        end
    end

    return true
end

local function requestOrder(order)
    if not canFulfill(order) then
        print("Request cancelled")
        return false
    end

    local filters = {}

    for _, requested in ipairs(order.items) do
        filters[#filters + 1] = {
            name = requested[1],
            _requestCount = requested[2]
        }
    end

    ticker.requestFiltered(order.address, table.unpack(filters))
    print("Order requested for " .. order.address)

    return true
end

requestOrder(order)
