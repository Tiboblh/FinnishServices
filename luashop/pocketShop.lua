local cogChar = "§"; local spurChar = "¤"
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
local clientVersion = 1.0
local protocolVersion = 1.0
local loggedIn = false; local currentShop = ""; local username = ""; local token = ""; local funds = 0; local userData = {}; local cartContents = {}; local catalogContents = {}; currentWindow = "" 
local serveraddr = "http://vps-2ddc970b.vps.ovh.net:9142"
local termX, termY = term.getSize()
local mainTerm = term.current()
local statusBarWindow = window.create(term.current(),1,termY,termX,1)

--get token, or define the setting if it doesnt exist
local tokenExists = pcall(settings.getDetails, "luashop.token")
if not tokenExists then
    settings.define("luashop.token",{description="the token to login to luashop (do not share this)",default="no token",type="string"})
    settings.save()
end
token = settings.get("luashop.token")
if (token == "no token") or (not token) or (token == "") then
    token = ""
end
local menuStuffs = { -- menuAssets lives on with a different name because i aint feel like hardcoding stuff
    -- types: dialog; just skipped with an enter press, input; you press a key to continue, typing; typing an input then enter to continue,
    -- and a caption can be included for inputs too by the way
    -- 
    test = {
        dialog = {
            title = "-=<test menu>=-", titleSide = "center", titleLine = true, -- title line is a horizontal line drawn a line below the title
            type = "dialog", content = {"This is a test dialog.", "a second line! (woah)"},
            exitKey = {keys.enter, "Enter"}
        },
        input = {
            title = "-=<Test Answering>=-", titleSide = "left", titleLine = true,
            type = "input", content = {"What's the answer?",{keys.y, "Yes"},{keys.n, "No"}, {keys.three, "Three"}} -- should return the keys.something for what was selected, so return keys.y if y was pressed
        },
        typing = {
            title = "-=<Test Typing>=-", titleSide = "right", titleLine = false,
            type = "typing", content = {"Please type something"}, sensitive = false -- return the inputted text
        }
    },
    main = {
        loggedOut = {
            title = "luashop", titleSide = "center", titleLine = true,
            type = "input", content = {
                "",
                {keys.r,"register"},
                {keys.l,"login"},
                {keys.e,"exit"}
            }
        },
        loggedIn = {
            title = "luashop", titleSide = "center", titleLine = true,
            type = "input", content = {
                "",
                {keys.c,"catalog"},
                {keys.o,"options"},
                {keys.l,"logout"},
                {keys.e,"exit"}
            }
        }
    },
    register = {
        {
            title = "register", titleSide = "center", titleLine = true,
            type = "typing",
            content = {"username:"}
        },
        {
            title = "register", titleSide = "center", titleLine = true,
            type = "typing", sensitive = true,
            content = {"password:"}
        },
        {
            title = "register", titleSide = "center", titleLine = true,
            type = "typing",
            content = {"frogport address:"}
        },
        {
            title = "register", titleSide = "center", titleLine = true,
            type = "input",
            content = {"use public frogports?", {keys.y,"yes"},{keys.n,"no"}}
        },
    },
    login = {
        {
            title = "login", titleSide = "center", titleLine = true,
            type = "typing",
            content = {"username:"}
        },
        {
            title = "login", titleSide = "center", titleLine = true,
            type = "typing", sensitive = true,
            content = {"password:"}
        }
    },
    
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
        statusBarWindow.setCursorPos(1,1)
        if username then statusBarWindow.write(username) else statusBarWindow.write("no user") end
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
        if not status then -- print current funds
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
            local outputStr = cogs .. cogChar .. "|" .. spurs .. spurChar
            statusBarWindow.setCursorPos(termX - (#outputStr + 5),1)
            statusBarWindow.write(outputStr)
        else

        end
    end
}

function renderMenu(menu) -- but cooler
    local result = ""
    local function renderTitle(titlestr,side,line)
            if side == "left" then term.setCursorPos(2,1) term.write(titlestr) end
            if side == "center" then term.setCursorPos(math.floor(termX/2) - math.floor(#titlestr/2),1) term.write(titlestr) end
            if side == "right" then term.setCursorPos(termX - (#titlestr + 1),1) term.write(titlestr) end
            if line then term.setCursorPos(1,2) for i = 1, termX do term.write("=") end end
    end
    local function renderDialog(content,exitKey)
        local curLine = 3 --starting line, after title and it's line
        local startingCol = 2 --starting col for left alignment.
        for _, item in ipairs(content) do
            if type(item) == "string" then
                local text = item
                local col = startingCol
                while #text > 0 do
                    local charsToWrite = math.min(termX - 2, #text)
                    term.setCursorPos(col, curLine)
                    term.write(text:sub(1, charsToWrite))
                    text = text:sub(charsToWrite + 1)
                    col = startingCol
                    curLine = curLine + 1
                end
            elseif type(item) == "table" then
                if item[1] then
                    local text = item[2]
                    local col = startingCol
                    while #text > 0 do
                        local charsToWrite = math.min(termX - 2, #text)
                        term.setCursorPos(col, curLine)
                        term.write(text:sub(1, charsToWrite))
                        text = text:sub(charsToWrite + 1)
                        col = startingCol
                        curLine = curLine + 1
                    end
                end
            end
        end
        term.setCursorPos(math.floor(termX/2 - (#("Press" .. " [" .. exitKey[2] .. "].") /2)),termY-1)
        term.write("Press" .. "[" .. exitKey[2] .. "]")
        waitForKey(exitKey[1])
        clearScreen()
        result = "dialog result"
    end
    local function renderInput(content)
        local curLine = 3 -- starting line, after title and its line
        local startingCol = 2 -- starting col for left alignment.
        local validKeys = {}
        statusBar.question()
        for _, item in ipairs(content) do
            if type(item) == "string" then
                local text = item
                local col = startingCol
                while #text > 0 do
                    local charsToWrite = math.min(termX - 2, #text)
                    term.setCursorPos(col, curLine)
                    term.write(text:sub(1, charsToWrite))
                    text = text:sub(charsToWrite + 1)
                    col = startingCol
                    curLine = curLine + 1
                end
            elseif type(item) == "table" then
                if item[1] then
                    local label = " [" .. keys.getName(item[1]) .. "]: " .. tostring(item[2])
                    local text = label
                    local col = startingCol
                    while #text > 0 do
                        local charsToWrite = math.min(termX - 2, #text)
                        term.setCursorPos(col, curLine)
                        term.write(text:sub(1, charsToWrite))
                        text = text:sub(charsToWrite + 1)
                        col = startingCol
                        curLine = curLine + 1
                    end
                    validKeys[item[1]] = true
                end
            end
        end

        if next(validKeys) then
            local selected = nil
            while not selected do
                local _, key = os.pullEvent("key")
                if validKeys[key] then
                    selected = key
                end
            end
            sleep(0.1)
            clearScreen()
            statusBar.idle()
            result = selected
        end
    end
    local function renderTyping(content,sensitive)
        local curLine = 3 -- starting line, after title and its line
        local startingCol = 2 -- starting col for left alignment.
        statusBar.question()
        for _, item in ipairs(content) do
            if type(item) == "string" then
                local text = item
                local col = startingCol
                while #text > 0 do
                    local charsToWrite = math.min(termX - 2, #text)
                    term.setCursorPos(col, curLine)
                    term.write(text:sub(1, charsToWrite))
                    text = text:sub(charsToWrite + 1)
                    col = startingCol
                    curLine = curLine + 1
                end
            elseif type(item) == "table" then
                if item[1] then
                    local label = " [" .. keys.getName(item[1]) .. "]: " .. tostring(item[2])
                    local text = label
                    local col = startingCol
                    while #text > 0 do
                        local charsToWrite = math.min(termX - 2, #text)
                        term.setCursorPos(col, curLine)
                        term.write(text:sub(1, charsToWrite))
                        text = text:sub(charsToWrite + 1)
                        col = startingCol
                        curLine = curLine + 1
                    end
                end
            end
        end
        local input = ""
        term.setCursorPos(startingCol, curLine)
        term.setBackgroundColor(colors.white); term.setTextColor(colors.black)
        local curX, curY = term.getCursorPos(); term.setCursorPos(1,curY); for i = 1, termX do term.write(" ") end; term.setCursorPos(curX,curY)
        if sensitive then  input = read("*") else  input = read() end
        term.setBackgroundColor(colors.black); term.setTextColor(colors.white)
        sleep(0.1)
        result = input
        clearScreen()
        statusBar.idle()
    end
    -- handle nonexistent menu data
    if not menu then clearScreen(); error("menu data is missing", 2) end
    if not menu.titleSide then menu.titleSide = "center" end
    if not menu.titleLine then menu.titleLine = true end
    if not menu.title then menu.title = "missing title, please fix" end
    if not menu.exitKey then menu.exitKey = keys.enter end
    if not menu.sensitive then menu.sensitive = false end

    renderTitle(menu.title,menu.titleSide,menu.titleLine)
    if not menu then error("menu data is missing", 2) end
    if menu.type == "dialog" then renderDialog(menu.content,menu.exitKey)
    elseif menu.type == "input" then renderInput(menu.content)
    elseif menu.type == "typing" then renderTyping(menu.content)
    else error("an invalid menu type was called",2) end
    return result
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

function clearScreen(hideStatusBar)
    term.clear()
    term.setCursorPos(1, 1)
    if not hideStatusBar then
        statusBarWindow.setVisible(false)
        statusBarWindow.setVisible(true) 
    end
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
        statusBar.loading()
        local url = serveraddr .. "/api/user_info"
        local headers = {["Authorization"] = "Bearer " .. token}
        local response = http.get(url, headers)
        clearScreen()
        if response then
            statusBar.idle()
            local body = response.readAll()
            local data = textutils.unserializeJSON(body)
            
            if type(data) == "table" then

                return data
            end
        end
        statusBar.idle()
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

                -- Prefer JSON: valid JSON arrays can also look like Lua tables, but
                -- JSON booleans/null are not Lua values and can silently lose entries.
                local ok, parsed = pcall(textutils.unserializeJSON, body)
                if ok and type(parsed) == "table" then
                    data = parsed
                end

                -- Some server versions return a Lua table literal instead of JSON.
                if not data then
                    ok, parsed = pcall(function()
                        local compile = loadstring or load
                        local fn = compile("return " .. body)
                        return fn and fn()
                    end)
                    if ok and type(parsed) == "table" then
                        data = parsed
                    end
                end

                if type(data) == "table" then
                    for _, key in ipairs({"catalog", "items", "products", "entries", "data"}) do
                        if type(data[key]) == "table" then
                            data = data[key]
                            break
                        end
                    end

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

function register()
    local username, password, address, public = renderMenu(menuStuffs.register[1]),renderMenu(menuStuffs.register[2]),renderMenu(menuStuffs.register[3]),renderMenu(menuStuffs.register[4])
    if public == keys.y then public = true elseif public == keys.n then public = false end
    local response = contactServer("register",{username=username,password=str2hexa(sha256.digest(password)),home_address=address,use_public_frogports=public})
    token = response.token; saveToken()
    username = response.username; statusBar.username()
    loggedIn = true
    userData = response
    main()
end

function login()
    local username, password = renderMenu(menuStuffs.login[1]),renderMenu(menuStuffs.login[2])
    password = str2hexa(sha256.digest(password))
    local response = contactServer("login",{username=username,password=password})
    token = response.token; saveToken()
    username = response.username; statusBar.username()
    loggedIn = true
    userData = response
    main()
end

function exit()
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    clearScreen(true)
    error("", 0)
end

function catalog()
    local tileX, tileY = math.floor(termX/13), math.floor((termY-2)/4)
    local catalogData = contactServer("catalog_fetch")
    catalogContents = type(catalogData) == "table" and catalogData or {}
    local shops = {{id=1,name="luashop",owner="mud + tibo"},{id=3,name="sandvich",owner="lemob"},{id=3,name="three",owner="three"}}
    local currPage = 1
    funds = userData["balance"]
    
    local function renderTitle(title)
        title = tostring(title or "")
        term.setCursorPos(math.floor(termX/2) - math.floor(#title/2), 1)
        term.write(title)
        term.setCursorPos(1, 2)
        for i = 1, termX do term.write("=") end
    end

    local function getCatalogPage(page)
        local pageSize = tileX*tileY
        page = tonumber(page) or 1
        if page < 1 then
            page = 1
        end
        
        local totalItems = #catalogContents
        if totalItems == 0 then
            return {}
        end

        local startIndex = (page - 1) * pageSize + 1
        if startIndex > totalItems then
            return {}
        end

        local endIndex = math.min(startIndex + pageSize - 1, totalItems)
        local pageItems = {}
        for i = startIndex, endIndex do
            pageItems[#pageItems + 1] = catalogContents[i]
        end
        return pageItems
    end

    local function getMatchingCatalogEntry(entry) 
        for index, item in catalogContents do 
            if entry == item then 
                return index
            end
        end
    end

    local function renderItems(items, highlighted)
        local compact = false
        if termX<30 then compact = true end
        clearScreen()
        renderTitle("catalog")
        function renderFull(things,highlight) 
            local pageSize = math.floor((termY-3)/2)
            local currPage = getCatalogPage(currPage)
            local currItem = 1
            local PriceStr = ""
            for index, item in ipairs(things) do 
                if currItem > pageSize then break end
                local y1 = 3 + (currItem - 1) * 2
                local y2 = y1 + 1
                local priceStr = "[" .. math.floor(item.price/64) .. cogChar .. " " .. item.price - math.floor(item.price/64) .. spurChar .. "]"
                local currHighlight
                if index == highlight then currHighlight = true end
                term.setCursorPos(1,y1); if currHighlight then term.setTextColor(colors.yellow) else term.setTextColor(colors.white) end; term.write(item.name); if currHighlight then term.setTextColor(colors.yellow) else term.setTextColor(colors.lightGray) end; term.setCursorPos(termX - #priceStr,y1); term.write(" " .. priceStr)
                term.setCursorPos(2,y2); term.setTextColor(colors.gray); term.write(item.description)
                currItem = currItem + 1
            end
            term.setTextColor(colors.white)
        end
        function renderCompact(things, highlight) 
            local pageSize = math.floor((termY-3))
            local currPage = getCatalogPage(currPage)
            local currItem = 1
            local PriceStr = ""
            for index, item in ipairs(things) do 
                if currItem > pageSize then break end
                local y1 = 3 + (currItem - 1)
                local priceStr = "[" .. math.floor(item.price/64) .. cogChar .. " " .. item.price - math.floor(item.price/64) .. spurChar .. "]"
                local currHighlight
                if index == highlight then currHighlight = true end
                term.setCursorPos(1,y1); if currHighlight then term.setTextColor(colors.yellow) else term.setTextColor(colors.white) end; term.write(item.name); if currHighlight then term.setTextColor(colors.yellow) else term.setTextColor(colors.lightGray) end; term.setCursorPos(termX - #priceStr,y1); term.write(" " .. priceStr)
                currItem = currItem + 1
            end
            term.setTextColor(colors.white)
        end
        if compact then renderCompact(items, highlighted) else renderFull(items, highlighted) end
    end
    local function shopSelect() 
        renderTitle("shops")
        term.setCursorPos(1,3)
        local selectChars = {"1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
        local selectKeys = {keys.one,keys.two,keys.three,keys.four,keys.five,keys.six,keys.seven,keys.eight,keys.nine,keys.a,keys.b,keys.c,keys.d,keys.e,keys.f,keys.h,keys.i,keys.j,keys.k,keys.l,keys.m,keys.n,keys.o,keys.p,keys.q,keys.r,keys.s,keys.t,keys.u,keys.v,keys.w,keys.x,keys.y,keys.z}
        local curItem = 1
        local curX = 1
        for num, shop in ipairs(shops) do 
            if curItem > termY then curX = curX + floor(termX/2) end
            term.setCursorPos(curX,curItem)
            term.write("[" .. selectChars[num] .. "] " .. shop.name)
            curItem = curItem + 1
        end
    end

    shopSelect()
    local currentPageData = getCatalogPage(currPage)
    local selected = math.min(1, #currentPageData)
    while true do
        renderItems(currentPageData, selected)
        term.setCursorPos(1,1)

        local _, key = os.pullEvent("key")
        if #currentPageData > 0 then
            if key == keys.down then
                selected = math.min(selected + 1, #currentPageData)
            elseif key == keys.up then
                selected = math.max(selected - 1, 1)
            end
        end
        if key == keys.enter then
            break
        end
    end
end


function initLogin()
        if (token == "") or not token then username = "no user"; statusBar.username(); return false end
        local serverResponse = contactServer("user_info")
        if serverResponse and serverResponse ~= nil then
            clearScreen()
            funds = serverResponse["balance"]
            username = serverResponse["username"]
            userData = serverResponse
            loggedIn = true
            statusBar.username()
            statusBar.balance()
            statusBar.idle()
        elseif serverResponse == nil then
            ohno("server did not respond", "check connection or token")
        end
    end

function init()
    clearScreen()
    statusBar.init()
    statusBar.idle()
    if token or #token>1 then
        initLogin()
    end
end

function main()
    local currentOption
    if not loggedIn then
        currentOption = renderMenu(menuStuffs.main.loggedOut)
        if currentOption == keys.r then register()
        elseif currentOption == keys.l then login()
        elseif currentOption == keys.e then exit()
        end
    elseif loggedIn then
        currentOption = renderMenu(menuStuffs.main.loggedIn)
        if currentOption == keys.c then catalog()
        elseif currentOption == keys.o then options()
        elseif currentOption == keys.e then exit()
        end
    end
end

function ohno(text1,text2) -- func for when a bad happens
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
init()
main()
exit() --only here for proper render cleanup