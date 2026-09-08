
while true do
    local event, key = os.pullEvent("key")
    local keyName = keys.getName(key)
    print(event .. " " .. keyName)
end
