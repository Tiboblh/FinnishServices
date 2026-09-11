local ticker = peripheral.find("Create_StockTicker")
local orders = {}
do -- get orders from server
    url = "http://vps-2ddc970b.vps.ovh.net:9142/api/deliver"
    headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer c48c42e49730405b65a1fe94e813a601b18273cab760fbfec02635d1457c8356"
    }
    local response = http.get(url, headers)
    if not response then
        error("Failed to fetch orders from server")
    end
    orders = textutils.unserializeJSON(response.readAll())
end

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

print(textutils.serialize(orders))