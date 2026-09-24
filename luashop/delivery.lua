local ticker = peripheral.find("Create_StockTicker")
local orders = {}
local AUTH_TOKEN = "Bearer c48c42e49730405b65a1fe94e813a601b18273cab760fbfec02635d1457c8356"
local API_BASE = "http://vps-2ddc970b.vps.ovh.net:9142"

local function logDebug(message)
    print("[delivery] " .. tostring(message))
end

local function readResponseBody(response, label)
    if not response then
        return nil, label .. " returned no response object"
    end

    local ok, result = pcall(function()
        return response.readAll()
    end)

    if not ok then
        return nil, label .. " failed to read body: " .. tostring(result)
    end

    return result, nil
end

function fetchOrders() -- get orders from server
    local url = API_BASE .. "/api/deliver"
    local headers = {
        ["Authorization"] = AUTH_TOKEN
    }

    logDebug("Fetching orders from " .. url)
    local response = http.get(url, headers)
    if not response then
        logDebug("Failed to fetch orders from server: http.get returned nil")
        return false
    end

    local body, err = readResponseBody(response, "fetchOrders")
    if err then
        logDebug(err)
        return false
    end

    logDebug("Orders response: " .. tostring(body))

    local decoded = textutils.unserializeJSON(body)
    if type(decoded) ~= "table" then
        logDebug("Failed to decode order JSON. Raw payload: " .. tostring(body))
        return false
    end

    orders = decoded
    logDebug("Loaded " .. tostring(#orders) .. " order(s)")
    return true
end

local function canFulfill(order)
    if not order then
        logDebug("canFulfill received nil order")
        return false
    end

    if type(order.items) ~= "table" then
        logDebug("Order " .. tostring(order.id) .. " has invalid item list")
        return false
    end

    local stock = ticker.stock(true)
    local available = {}

    for _, item in ipairs(stock) do
        if item and item.name then
            available[item.name] = (available[item.name] or 0) + (item.count or 0)
        end
    end

    -- Check every order line
    for _, requested in ipairs(order.items) do
        local itemName = requested["itemID"]
        local amount = requested["quantity"]
        local inStock = available[itemName] or 0

        if inStock < amount then
            logDebug("Order " .. tostring(order.id) .. " cannot be fulfilled: " .. tostring(itemName) .. " needs " .. tostring(amount) .. ", has " .. tostring(inStock))
            return false
        end
    end

    return true
end

local function requestOrder(order)
    if not order then
        logDebug("requestOrder called with nil order")
        return false
    end

    logDebug("Processing order " .. tostring(order.id) .. " for " .. tostring(order.address))

    if not canFulfill(order) then
        logDebug("Order for " .. tostring(order.address) .. " cannot be fulfilled due to insufficient stock.")
        return false
    end

    local filters = {}

    for _, requested in ipairs(order.items) do
        filters[#filters + 1] = {
            name = requested["itemID"],
            _requestCount = requested["quantity"]
        }
    end

    local ok, err = pcall(function()
        ticker.requestFiltered(order.address, table.unpack(filters))
    end)

    if not ok then
        logDebug("Failed to request stock for order " .. tostring(order.id) .. ": " .. tostring(err))
        return false
    end

    logDebug("Order requested for " .. tostring(order.address))
    return true
end

while true do
    local ok = fetchOrders()
    if not ok then
        logDebug("Skipping order processing because fetchOrders failed")
    else
        for _, order in ipairs(orders) do
            if requestOrder(order) then
                local url = API_BASE .. "/api/deliver"
                local payload = textutils.serialiseJSON({satisfied = {order.id}})
                local headers = {
                    ["content-type"] = "application/json",
                    ["content-length"] = tostring(#payload),
                    ["authorization"] = AUTH_TOKEN
                }

                logDebug("Sending delivery confirmation for order " .. tostring(order.id) .. ": " .. payload)
                local response, err = http.post(url, payload, headers)
                if not response then
                    logDebug("Failed to mark order " .. tostring(order.id) .. " as delivered on server")
                    logDebug("HTTP error: " .. err)
                    logDebug("Request headers: " .. textutils.serializeJSON(headers))
                    logDebug("Request payload: " .. payload)
                else
                    local status = response.getResponseCode and response.getResponseCode() or "unknown"
                    local body, err = readResponseBody(response, "deliver confirmation")
                    if err then
                        logDebug("Order " .. tostring(order.id) .. " delivery confirmation failed: " .. err)
                    else
                        logDebug("Order " .. tostring(order.id) .. " server response: status=" .. tostring(status) .. " body=" .. tostring(body))
                    end
                end
            end
        end
    end
    sleep(15) -- wait 15 seconds before checking for new orders again
end