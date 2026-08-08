sha256 = require("ccryptolib.sha256")

local payload = {
    username = "mudkip",
    password = sha256.digest("password125")
}
local url = "http://localhost:9142/api/login"
local headers = {
    ["Content-Type"] = "application/json"
}

local response = http.post(url, payload, headers)

if response then
    local content = response.readAll()
    print(content)
    response.close()
else
    print("Request failed")
end