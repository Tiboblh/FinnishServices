---@diagnostic disable: need-check-nil
-- lua Shop Client
-- evil thing by tibo and mudkip

local sha256 = {}
local function ror(value, bits)
    return bit32.rrotate(value, bits)
end
local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}
local function sha256_digest(data)
    local msg = {string.byte(data or "", 1, #data)}
    msg[#msg + 1] = 0x80
    while (#msg % 64) ~= 56 do
        msg[#msg + 1] = 0x00
    end

    local bitlen = (#data or 0) * 8
    local bitlen_hi = math.floor(bitlen / 4294967296)
    local bitlen_lo = bitlen % 4294967296

    for i = 7, 0, -1 do
        msg[#msg + 1] = bit32.rshift((bitlen_hi or 0), i * 8) % 256
    end
    for i = 7, 0, -1 do
        msg[#msg + 1] = bit32.rshift(bitlen_lo, i * 8) % 256
    end

    local words = {}
    for i = 1, #msg, 4 do
        local a = msg[i] or 0
        local b = msg[i + 1] or 0
        local c = msg[i + 2] or 0
        local d = msg[i + 3] or 0
        words[#words + 1] = (a * 16777216) + (b * 65536) + (c * 256) + d
    end

    local h0 = 0x6a09e667
    local h1 = 0xbb67ae85
    local h2 = 0x3c6ef372
    local h3 = 0xa54ff53a
    local h4 = 0x510e527f
    local h5 = 0x9b05688c
    local h6 = 0x1f83d9ab
    local h7 = 0x5be0cd19

    for chunk = 1, #words, 16 do
        local w = {}
        for i = 0, 15 do
            w[i + 1] = words[chunk + i] or 0
        end

        for i = 17, 64 do
            local s0 = bit32.bxor(bit32.bxor(ror(w[i - 15], 7), ror(w[i - 15], 18)), bit32.rshift(w[i - 15], 3))
            local s1 = bit32.bxor(bit32.bxor(ror(w[i - 2], 17), ror(w[i - 2], 19)), bit32.rshift(w[i - 2], 10))
            w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % 4294967296
        end

        local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
        for i = 1, 64 do
            local S1 = bit32.bxor(bit32.bxor(ror(e, 6), ror(e, 11)), ror(e, 25))
            local ch = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g))
            local temp1 = (h + S1 + ch + K[i] + w[i]) % 4294967296
            local S0 = bit32.bxor(bit32.bxor(ror(a, 2), ror(a, 13)), ror(a, 22))
            local maj = bit32.bxor(bit32.bxor(bit32.band(a, b), bit32.band(a, c)), bit32.band(b, c))
            local temp2 = (S0 + maj) % 4294967296

            h = g
            g = f
            f = e
            e = (d + temp1) % 4294967296
            d = c
            c = b
            b = a
            a = (temp1 + temp2) % 4294967296
        end

        h0 = (h0 + a) % 4294967296
        h1 = (h1 + b) % 4294967296
        h2 = (h2 + c) % 4294967296
        h3 = (h3 + d) % 4294967296
        h4 = (h4 + e) % 4294967296
        h5 = (h5 + f) % 4294967296
        h6 = (h6 + g) % 4294967296
        h7 = (h7 + h) % 4294967296
    end

    local function emit32(value)
        return string.char(
            bit32.rshift(value, 24) % 256,
            bit32.rshift(value, 16) % 256,
            bit32.rshift(value, 8) % 256,
            value % 256
        )
    end

    return emit32(h0) .. emit32(h1) .. emit32(h2) .. emit32(h3) .. emit32(h4) .. emit32(h5) .. emit32(h6) .. emit32(h7)
end
sha256.digest = sha256_digest
sha256.sha256 = sha256_digest
sha256.hash = sha256_digest
sha256.hexdigest = function(data)
    local bytes = sha256_digest(data)
    local hex = {}
    for i = 1, #bytes do
        hex[#hex + 1] = string.format("%02x", string.byte(bytes, i, i))
    end
    return table.concat(hex)
end

-- var setup
local clientVersion = 0.1
local protocolVersion = 0.1
local cogChar = "c"; local spurChar = "s"
local loggedIn = false; currentShop = ""; local connected = false; local username = ""; local token = ""; local funds = 0; local userData = {}; local cartContents = {}; local catalogContents = {}; currentWindow = "" 
local serveraddr = "http://vps-2ddc970b.vps.ovh.net:9142"
local termX, termY = term.getSize()
local unused = nil --dummy var to redirect junk stuff
local mainTerm = term.current()



--window definitions
local statusBarWindow = window.create(term.current(),1,termY,termX,1)

local tabList = {{id=1,name="Initial Tab",window = tabWin1}}
local currentTab = 1

--get token, or define the setting if it doesnt exist
local tokenExists, unused = pcall(settings.getDetails("luashop.token"))
if not tokenExists then
    settings.define("luashop.token",{description="the token to login to luashop (do not share this)",default="no token",type="string"})
    settings.save()
elseif tokenExists then
    token = settings.get("luashop.token")
    if (token == "no token") or (not token) then
        token = ""
    end
end

local menuStuffs = { -- menuAssets lives on with a different name because i aint feel like hardcoding stuff
    -- types: dialog; just skipped with an enter press, input; you press a key to continue, typing; typing an input then enter to continue,
    -- multi; content will be a table of types and contents
    -- and a caption can be included for inputs too by the way
    -- 
    testDialog = {
        title = "-=<test menu>=-", titleSide = "center", titleLine = true, -- title line is a horizontal line drawn a line below the title
        type = "dialog", content = {"This is a test dialog.", "a second line! (woah)"},
        exitKey = {keys.enter, "Enter"}
    },
    testInput = {
        title = "-=<Test Answering>=-", titleSide = "left", titleLine = true,
        type = "input", content = {{keys.y, "Yes"},{keys.n, "No"}, {keys.three, "Three"}} -- should return the keys.something for what was selected, so return keys.y if y was pressed
    },
    testTyping = {
        title = "-=<Test Typing>=-", titleSide = "right", titleLine = false,
        type = "typing", content = {"Please type something"} -- return the inputted text
    },
    testMulti = {
        title = "-=<many test (woah)>=-", titleSide = "left", titleLine = true,
        type = "multi", 
        content = {
            {caption="test input",type="input",content={{keys.y, "Yes"},{keys.n, "No"}, {keys.three, "Three"}}},
            {type = "typing", content = {"Please type something"}},
            {type = "dialog", content = {"This is a test dialog.", "a second line! (woah)"}}
        }
    }
}

local optionsFuncs = {
    changeUsername = function ()
        clearScreen() -- same as change pass func but for username
        print("-<Username Change>-")
        io.write("New Username: ")
        local newuser = read()
        contactServer("modify_user", {username = newuser})
        runOptions()
    end,
    changePassword = function ()
        clearScreen() -- same as change user func but for password
        print("-<Username Change>-")
        io.write("New Password: ")
        local newpass = read("*")
        contactServer("modify_user", {password = str2hexa(sha256.digest(newpass))})
        runOptions()
    end,
    changeAddress = function ()
        clearScreen() -- this should give a text prompt that requests a new address, sends it to server to update
        print("-<Address Change>-")
        io.write("New Address: ")
        local newaddr = read()
        contactServer("modify_user", {homeaddress = newaddr})
        runOptions()
    end,
    togglePubFrogports = function ()
        clearScreen() -- this function should send a reqeust to the server to toggle Public Frogports, and then reload the options menu
        userData = contactServer("user_info")
        contactServer("modify_user", {use_public_frogports = not userData["use_public_frogports"]})
        userData = contactServer("user_info")
        runOptions()
    end,
}


local statusBar = {
    init = function()
        statusBarWindow.setBackgroundColor(colors.gray)
        statusBarWindow.setTextColor(colors.white)
        statusBarWindow.clear()
        statusBarWindow.setCursorPos(1,1)
        local str_p1 = ""
        if username == "" or not username then
            str_p1 = "loading..."
        end
        statusBarWindow.write(str_p1)
        statusBarWindow.setCursorPos((termX - 4),1)
        statusBarWindow.blit("[...]","01110","77777")
    end,
    username = function()
        statusBarWindow.setCursorPos(1,1)
        clearstr = ""
        for i = 1, (termX - 4) do
            clearstr = clearstr .. " "
        end
        statusBarWindow.write(clearstr)
        statusBarWindow.write(username)
    end,
    loading = function ()
        statusBarWindow.setCursorPos((termX - 4),1)
        statusBarWindow.blit("[...]","01110","77777")
    end,
    error = function ()
        statusBarWindow.setCursorPos((termX - 4),1)
        statusBarWindow.blit("[ X ]","00e00","77777")
    end,
    question = function ()
        statusBarWindow.setCursorPos((termX - 4),1)
        statusBarWindow.blit("[ ? ]","00400","77777")
    end,
    exclamation = function ()
        statusBarWindow.setCursorPos((termX - 4),1)
        statusBarWindow.blit("[ ! ]","00400","77777")
    end,
    idle = function ()
        statusBarWindow.setCursorPos((termX - 4),1)
        statusBarWindow.blit("[---]","08880","77777")
    end,
    balance = function (status)
        if not status then
            local cogs = math.floor((funds or 0) / 64)
            local spurs = (funds or 0) % 64

                do -- fancy format cogs
                    local n = cogs
                    if n >= 100000 then
                        cogs = "99999"
                    else
                        local s = tostring(n)
                        while #s < 5 do
                            s = "0" .. s
                        end
                        cogs = s
                    end
                end
                do -- fancy format the spurs too
                    local n = spurs
                    local s = tostring(n)
                    while #s < 2 do
                        s = "0" .. s
                    end
                    spurs = s
                end
            
            statusBarWindow.setCursorPos((termX - (#outputStr + 1)),1)
            
        else

        end
    end
}

function renderMenu(menu) -- but cooler
    function renderTitle(titlestr,side,line)
            if side == "left" then term.setCursorPos(2,1) term.write(titlestr) end
            if side == "center" then term.setCursorPos(math.floor(termX/2) - math.floor(#titlestr/2),1) term.write(titlestr) end
            if side == "right" then term.setCursorPos(termX - (#titlestr + 1),1) term.write(titlestr) end
            if line then term.setCursorPos(1,2) for i = 1, termX do term.write("=") end end
    end
    function renderDialog(content)
        
    end
    function renderInput(content)

    end
    function renderTyping(content)

    end
    function renderMulti(content)
        
    end
    -- handle nonexistent menu data
    if not menu.titleSide then menu.titleSide = "center" end
    if not menu.titleLine then menu.titleLine = true end
    if not menu.title then menu.title = "missing title, please fix" end

    renderTitle(menu.title,menu.titleSide,menu.titleLine)
    --if menu.type == "dialog" then renderDialog(menu.content) end
    --if menu.type == "input" then renderInput(menu.content) end
    --if menu.type == "typing" then renderTyping(menu.content) end
    --if menu.type == "multi" then renderMulti(menu.content) end
 end

function waitForKey(checkFor)
    local resolve = false
    while not resolve do
        local _, pressedKey = os.pullEvent("key")
        local key = pressedKey
        if key == checkFor then
            resolve = true
        end
    end
end

function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

function str2hexa(s)
    return (string.gsub(s, ".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end

function saveToken()
    if token then
        settings.set("luashop.token",token)
        settings.save()
    end
end

function contactServer(mode, data)
    if mode == "login" then
        local url = serveraddr .. "/api/login"
        local headers = {["Content-Type"] = "application/json"}
        local payload = data
        clearScreen()
        print("Contacting server (logging in)...")
        connectionDone = false
        local response = http.post(url, textutils.serialiseJSON(payload), headers)
        clearScreen()
        if response then
            connectionDone = true
            local body = response.readAll and response.readAll() or response
            local parsed = textutils.unserializeJSON(body)
            if type(parsed) == "table" then
                return parsed
            end
            if type(body) == "table" then
                return body
            end
        end
        error("The server did not respond with user data. perhaps you typed a wrong username or password? (or you're offline?)", 2)
        if not(data.username or data.password) then
            error("missing one or more components to login")
        end
    elseif mode == "register" then
        local url = serveraddr .. "/api/register"
        local headers = { ["Content-Type"] = "application/json" }
        local payload = data
        clearScreen()
        print("Contacting server (registering)...")
        local response = http.post(url, textutils.serialiseJSON(payload), headers)
        clearScreen()
        if response then
            local body = response.readAll()
            response.close()

            if type(body) == "string" then
                body = body:match("^%s*(.-)%s*$")
                if body:sub(1, 7) == "return " then
                    body = body:sub(8)
                end

                local ok, parsed = pcall(function()
                    local compile = loadstring or load
                    local fn = compile("return " .. body)
                    if fn then
                        return fn()
                    end
                    return nil
                end)
                if ok and type(parsed) == "table" then
                    return parsed
                end

                local jsonParsed = textutils.unserializeJSON(body)
                if type(jsonParsed) == "table" then
                    return jsonParsed
                end
            end

            if type(body) == "table" then
                return body
            end
        end
        error("The server did not respond. perhaps you input an already taken username?")
    elseif mode == "user_info" then
        local url = serveraddr .. "/api/user_info"
        local headers = {["Authorization"] = "Bearer " .. token}
        clearScreen()
        print("Contacting server (fetching user data)...")
        local response = http.get(url, headers)
        clearScreen()
        if response then
            local body = response.readAll()
            if type(body) == "string" and body:sub(1, 7) == "return " then
                body = body:sub(8)
            end
            local data = textutils.unserializeJSON(body)
            if type(data) == "table" then
                return data
            end
        end
        return nil
    elseif mode == "catalog_fetch" then
        local url = serveraddr .. "/api/catalog"
        local headers = { ["Authorization"] = "Bearer " .. token }
        clearScreen()
        print("Contacting Server (catalog fetch)...")
        local response = http.get(url, headers)
        clearScreen()
        if response then
            local body = response.readAll()
            if type(body) == "string" then
                body = body:match("^%s*(.-)%s*$")
                if body:sub(1, 7) == "return " then
                    body = body:sub(8)
                end

                local data = nil

                -- Try to parse a Lua table literal first (common when server returns a literal export)
                local ok, parsed = pcall(function()
                    local fn = load("return " .. body, "catalog_response", "t", _G)
                    if fn then
                        return fn()
                    end
                    return nil
                end)
                if ok and type(parsed) == "table" then
                    data = parsed
                end

                -- Fallback to JSON if the server sent real JSON instead.
                if not data then
                    data = textutils.unserializeJSON(body)
                end

                if type(data) == "table" then
                    local rawFile = fs.open("catalog_raw.json", "w")
                    if rawFile then
                        rawFile.write(body)
                        rawFile.close()
                    end

                    local catalogFile = fs.open("catalog.txt", "w")
                    if catalogFile then
                        catalogFile.write(textutils.serialize(data))
                        catalogFile.close()
                    end

                    return data
                end
            end
        end
    elseif mode == "modify_user" then
        local url = serveraddr .. "/api/user_info"

        local headers = {
            ["Authorization"] = "Bearer " .. token,
            ["X-USER-CHANGE"] = "True",
            ["Content-Type"] = "application/json"
        }

        local payload = textutils.serialiseJSON(data)

        clearScreen()

        print("Contacting Server (updating user)...")

        local response = http.post(url, payload, headers)

        if not response then
            print("Failed to contact server.")
            waitForKey(keys.enter)
            clearScreen()
            return
        end

        local body = response.readAll()
        response.close()

        local responsedata = textutils.unserialiseJSON(body)

        if not responsedata then
            error("Invalid JSON response from server.")
            waitForKey(keys.enter)
            clearScreen()
            return
        end

        if responsedata.error then
            error("Server error: " .. tostring(responsedata.error), 2)
            waitForKey(keys.enter)
            clearScreen()
            return
        end

        if responsedata.token then
            token = responsedata.token
        end

        if responsedata.username then
            username = responsedata.username
        end

        if responsedata.balance ~= nil then
            funds = responsedata.balance
        end

        saveToken()
        clearScreen()
    elseif mode == "checkout" then
        if not data then error("No cart provided for order.") end
        local url = serveraddr .. "/api/order"
        local headers = {["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. token}
        local payload = {items={},notes=""}
        local cart = data
        clearScreen()
        io.write(" Please input a note for the order. (none is okay too!)")
        term.setCursorPos(2,3)
        io.write("notes: ")
        payload.notes = read()
        clearScreen()
        for _, t, i in ipairs(cart) do
            local it = {id = t.id, qty = t.count}
            table.insert(payload.items, it)
        end
        print("contacting server (checkout)...")
        local response = http.post(url, textutils.serialiseJSON(payload), headers)
        clearScreen()
        if not response then
            print("Error: Failed to connect to server, no valid response.")
            debug.debug()
        else
            local contents = response.readAll()
            local responsedata = textutils.unserialiseJSON(contents)
            if responsedata then
                main()
            else
                print("Error: Invalid response from server")
            end
        end
    elseif mode == "getOrders" then
        local url = serveraddr .. "/api/orders"
        local headers = {["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. token}
        clearScreen()
        print("Contacting server (get order history)...")
        local response = http.get(url, headers)
        local result

        if response then
            local body = response.readAll()
            response.close()
            result = textutils.unserialiseJSON(body)
            if result then
                return result
            else
                return body
            end
        else
            error("Failed to connect to server, no valid response.", 2)
        end

        waitForKey(keys.enter)
        clearScreen()
        return result
    end
end

function login()
    clearScreen()
    print(" -<Log in>-")
    io.write("  Username: ")
    local username_input = read()
    print()
    io.write("  Password: ")
    local password_input = read("*")

    local payload = {
        username = username_input,
        password = str2hexa(sha256.digest(password_input))
    }
    local serverResponse = contactServer("login", payload)
    username = username_input
    loggedIn = true
    token = serverResponse["token"]
    if token == nil then
        loggedIn = false
        username = ""
        clearScreen()
        print("Token is nil for some reason when tryna login; uh")
        print("go exit yes press enter") -- maybe i SHOULDNT have smth this stupidly worded, but i aint gonna change it -mudkip
        waitForKey(keys.enter)
        exit()
    end
    saveToken()
    main()
end

function logout()
    clearScreen()
    local confirmed = renderMenu("logOutConfirm")
    if confirmed ~= true then
        return
    end

    print("You have been logged out.")
    print("Press [Enter] to continue.")
    waitForKey(keys.enter)
    username = ""
    token = ""
    funds = 0
    userData = {}
    fs.delete(savePath) -- delete the login.sav file to remove token.
    loggedIn = false
    main()
end

function register()
    clearScreen()
    print("-<Register>-")
    print("Username: ")
    local username_input = read()
    print("Password: ")
    local password_input = read("*")
    print("Home Frogport Address: ")
    local home_addr_input = read()
    print ("Use public frogports? [Y/N]")
    local public_frogport_input = nil
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.y then
            public_frogport_input = true
            break
        elseif key == keys.n then
            public_frogport_input = false
            break
        end
    end
    local payload = {
        username = username_input,
        password = str2hexa(sha256.digest(password_input)),
        home_address = home_addr_input,
        use_public_frogports = public_frogport_input
    }
    local response = contactServer("register", payload)
    username = response["username"] or username_input
    funds = response["balance"] or 0
    token = response["token"] or error("server gave no token after registre, account was created though? (try loggin in seperately)",2)
    loggedIn = true
    saveToken()
    main()
end

function exit()
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    clearScreen()
    error("", 0)
end

function checkoutFunc()
    clearScreen()
    local function calculateTotal(cart)
        local total = 0
        for _, entry in ipairs(cart) do
            local item = nil
            for _, catalogItem in ipairs(catalogContents) do
                if catalogItem.id == entry.id then
                    item = catalogItem
                    break
                end
            end
            if item then
                total = total + (item.price * entry.count)
            end
        end
        return total
    end
    local function calcItemCount(cart)
        local output = {}
        local seen = {}
        for _, entry in ipairs(cart) do
            if seen[entry.id] then
                seen[entry.id].count = seen[entry.id].count + entry.count
            else
                local item = nil
                for _, catalogItem in ipairs(catalogContents) do
                    if catalogItem.id == entry.id then
                        item = catalogItem
                        break
                    end
                end
                local pac = 1
                if item.pack then
                    pac = item.pack
                else
                    pac = 1
                end
                local itemCopy = {
                    id = entry.id,
                    name = item and item.name or entry.name,
                    count = entry.count * pac
                }
                seen[entry.id] = itemCopy
                output[#output + 1] = itemCopy
            end
        end
        return output
    end
    local total = calculateTotal(cartContents)
    local visualCart = calcItemCount(cartContents)
    local totalCogs = math.floor(total / 64)
    local totalSpurs = total % 64
    do -- fancy format total cogs
        local n = totalCogs
        if n >= 1000000 then
            totalCogs = "999999+"
        else
            local s = tostring(n)
            while #s < 7 do
                s = "0" .. s
            end
            totalCogs = s
        end
    end
    do -- fancy format total spurs
        local n = totalSpurs
        local s = tostring(n)
        while #s < 2 do
            s = "0" .. s
        end
        totalSpurs = s
    end
end

function initLogin()
        local serverResponse = contactServer("user_info")
        if serverResponse and serverResponse ~= nil then
            clearScreen()
            funds = serverResponse["balance"]
            username = serverResponse["username"]
            userData = serverResponse
            loggedIn = true
            statusBar.username()
            statusBar.idle()
        elseif serverResponse == nil then
           error("server didn't respond with anything, perhaps its down or your token is invalid?\ntry running \"  set luashop.token \"\"  \" to reset it.",2) 
        end
end

function init()
    clearScreen()
    statusBar.init()
    if token ~= "" then
        initLogin()
    end
end

function main()
    -- debug.debug()
    renderMenu(menuStuffs.testDialog)
end

function ohno(text1,text2)
    term.redirect(mainTerm)
    statusBarWindow.setVisible(false)
    term.setBackgroundColor(colors.blue); term.setTextColor(colors.white); term.clear()
    local function centerX(termW, str)
        local x = math.floor((termW - #str) / 2) + 1
        if x < 1 then x = 1 end
        return x
    end
    term.setCursorPos(centerX(termX, "a bad hapende"),2); term.write("a bad hapende")
    term.setCursorPos(centerX(termX, text1), math.floor(termY/2)); term.write(text1)
    term.setCursorPos(centerX(termX, text2), math.floor(termY/2)+1); term.write(text2)
    waitForKey(keys.enter)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    clearScreen()
    exit()
end
--exec start
-- debug.debug()
init()
main()
term.write("#")
waitForKey(keys.enter)
clearScreen()