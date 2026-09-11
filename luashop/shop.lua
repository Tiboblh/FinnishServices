---@diagnostic disable: need-check-nil
-- lua Shop Client
--  evil thing by tibo and mudkip

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
local clientVersion = 0.1 -- left side is major ver, 0 since still dev/beta, right side is patch, i start it at 1 since this is patch that adds in verision
local protocolVersion = 0.1 -- same idea as version
local loggedIn = false --init
local savePath = "/luashop/login.sav" -- if you want, change this, but its recomended to leave dis alone 
local username = "" -- `username == token is in fact true, bc this is just init`
local token = "" -- init, no change ples
local serveraddr = "http://vps-2ddc970b.vps.ovh.net:9142" -- server to contact for account and ordering, leave this alone.
local funds = 0 --init
local userData = {}
local cartContents = {}
local pocket = false
local offline = false -- leave this off, its for development when internet isnt available (and is prob broken lmao)
local catalogContents = {}

-- string sets, easier to modify like this
local menuAssets = {
    MainMenu = {
        keybinds = {{"L", "login"}, {"R", "register"}, {"E", "exit"}},
        text = {" -<lua Shop Client (No User)>-",
                "  [L] Login",
                "  [R] Register",
                "  [E] Exit"}
    },
    loggedInMenu = {
        keybinds = {{"C", "catalog"}, {"O","options"}, {"L", "logout"}, {"E", "exit"}},
        text = {" -<lua Shop Client (" .. tostring(username) .. ")>-",
                "  [C] Catalog", 
                "  [O] Options",
                "  [L] Logout",
                "  [E] Exit"}
    },
    logOutConfirm = {
        keybinds = {{"Y", "confirmLogout"}, {"N", "cancelLogout"}},
        text = {" -<lua Shop Client (" .. tostring(username) .. ")>-",
                "  Are you sure you want to log out?",
                "  [Y] Yes",
                "  [N] No"}
    },
    options = {
        keybinds = {{"U", "changeUsername"}, {"P", "changePassword"}, {"A", "changeAddress"}, {"F", "togglePubFrogports"}, {"B", "cancelLogout"}},
        text = {
            " -<Options (" .. tostring(username) ..")>-",
            "  [U] Change Username",
            "  [P] Change Password",
            "  [A] Change Address",
            "  [F] Toggle Public frogports ( currently " .. tostring(userData["use_public_frogports"]) .. " )",
            "  [B] Back"
        }
    }
}

runOptions = function ()
        clearScreen()
        userData = contactServer("user_info")
        renderMenu("options")
    end

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

local menuActions = {
    ["login"] = function() return login() end,
    ["register"] = function() return register() end,
    ["catalog"] = function() return catalog() end,
    ["logout"] = function() return logout() end,
    ["cancelLogout"] = function() return main() end,
    ["confirmLogout"] = function() return true end,
    ["MainMenu"] = function() return renderMenu("MainMenu") end,
    ["loggedInMenu"] = function() return renderMenu("loggedInMenu") end,
    ["options"] = function() return runOptions() end,
    ["changeUsername"] = function() return optionsFuncs.changeUsername() end,
    ["changePassword"] = function() return optionsFuncs.changePassword() end,
    ["changeAddress"] = function() return optionsFuncs.changeAddress() end,
    ["togglePubFrogports"] = function() return optionsFuncs.togglePubFrogports() end,
    ["getOrderHistory"] = function() return optionsFuncs.getOrderHistory() end,
    ["exit"] = function() return exit() end
}

function waitForEnter()
    local resolve = false
    while not resolve do
        local _, pressedKey = os.pullEvent("key")
        local key = pressedKey
        if key == keys.enter then
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

function getCatalogPageIndexes(page, size)
    local pageSize = 1
    if not size then
        pageSize = 14
    else
        pageSize = size
    end
    if pocket then
        pageSize = 7
    end
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
    local indexes = {}
    for i = startIndex, endIndex do
        indexes[#indexes + 1] = i
    end
    return indexes
end

function saveToken()
    local file = fs.open(savePath, "w")
    if file then
        file.write(tostring(token))
        file.close()
        return true
    end
    return false
end

function contactServer(mode, data)
    if mode == "login" then
        local url = serveraddr .. "/api/login"
        local headers = {["Content-Type"] = "application/json"}
        local payload = data
        clearScreen()
        print("Contacting server (logging in)...")
        local response = http.post(url, textutils.serialiseJSON(payload), headers)
        clearScreen()
        if response then
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
        local url = serveraddr .. "/api/catalog?format=lua"
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

                -- The server can return Lua source for this endpoint when ?format=lua is used.
                -- Try parsing it as Lua first, then fall back to JSON if needed.
                local ok, data = pcall(function()
                    local compile = loadstring or load
                    local fn = compile("return " .. body)
                    if fn then
                        return fn()
                    end
                    return nil
                end)
                if ok and type(data) == "table" then
                    return data
                end

                local jsonData = textutils.unserializeJSON(body)
                if type(jsonData) == "table" then
                    return jsonData
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
            waitForEnter()
            clearScreen()
            return
        end

        local body = response.readAll()
        response.close()

        local responsedata = textutils.unserialiseJSON(body)

        if not responsedata then
            error("Invalid JSON response from server.")
            waitForEnter()
            clearScreen()
            return
        end

        if responsedata.error then
            error("Server error: " .. tostring(responsedata.error), 2)
            waitForEnter()
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

        waitForEnter()
        clearScreen()
        return result
    end
end

function renderMenu(menuName)
    sleep(0.1)
    local menu = menuAssets[menuName]
    if not menu then
        return nil
    end

    if type(menu.text) ~= "table" then
        return nil
    end

    if type(menu.keybinds) ~= "table" then
        return nil
    end

    if menuName == "loggedInMenu" then
        menu.text[1] = " -<lua Shop Client (" .. tostring(username) .. ")>-"
    end

    if menuName == "options" then
        menu.text[1] = " -<Options (" .. tostring(username) ..")>-"
    end

    if menuName == "options" then
        menu.text[5] = "  [F] Toggle Public frogports ( currently " .. tostring(userData["use_public_frogports"]) .. " )"
        menu.text[6] = "  [H] Order History"
        menu.text[7] = "  [B] Back"
    end

    clearScreen()

    for i = 1, #menu.text do
        print(menu.text[i])
    end

    if menuName == "options" then
        term.setTextColor(colors.white)
    end

    while true do
        local event, key = os.pullEvent("key")
        if event ~= "key" then
            -- Ignore non-key events
        else
            local keyName = keys.getName(key)
            if keyName then
                keyName = string.upper(keyName)
            end

            for _, bind in ipairs(menu.keybinds) do
                local bindKey = tostring(bind[1] or "")
                local bindAction = bind[2]

                if string.upper(bindKey) == keyName then
                    if bindAction == "sleep(0.1); return 0" then
                        sleep(0.1)
                        return 0
                    end

                    local actionFn = menuActions[bindAction]
                    if actionFn then
                        return actionFn()
                    end

                    local fn, err = load(bindAction, "menu_action", "t", _G)
                    if fn then
                        return fn()
                    else
                        print(err)
                        waitForEnter()
                        return nil
                    end
                end
            end
        end
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
        waitForEnter()
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
    waitForEnter()
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

function main() -- yep, main is THIS simple
    clearScreen()
    cartContents = {} -- reset cart contents on main menu return
    if loggedIn then
        renderMenu("loggedInMenu")
    else
        renderMenu("MainMenu")
    end
end

function catalog() -- all this does is decide which catalog to load bc i aint repeating this check everywhere (am lazy)
    if pocket then mobileCatalog() else desktopCatalog() end
end

function desktopCatalog()
    clearScreen()
    term.setCursorPos(1,1)
    local cogs = math.floor(funds / 64)
    local spurs = funds % 64
    local curpage = 1
    local itemNameX = 3 -- just some misc constants
    local itemStartY = 5 -- just some misc constants
    local itemPriceX = 21 -- just some misc constants
    local itemStockX = 31 -- just some misc constants
    local itemPackX = 41 -- just some misc constants
    local selectedItemIndex = 1 -- init, first item of catalog by default
    local selectedPanel = 0 -- catalog by default, 1 for cart (THIS NEVER GOT USED LMAO)
    local checkout = false -- init, not checking out by default
    catalogContents = contactServer("catalog_fetch")
    local totalpage = math.ceil(#catalogContents / 14) -- 14 things per page
    if not catalogContents or catalogContents == nil then
        error("catalog contents from server is empty, please contact mudkip/tiboblh",2)
    end
    clearScreen()
    local cartStartX = 48
    local cartStartY = 2
    visualCart = {}
    do -- fancy format cogs
        local n = cogs
        if n >= 1000000 then
            cogs = "999999+"
        else
            local s = tostring(n)
            while #s < 7 do
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
    
    -- go ahead and check how many items there are for this page, and display them
    local pageIndexes = getCatalogPageIndexes(curpage)

    local function drawCatalogPage()
        clearScreen()
        term.setCursorPos(1, 1)
        print(' [S]: Shops                 | ' .. cogs .. "c | " .. spurs .. "s |  -<Cart>-")
        term.setCursorPos(1, 2)
        print("---------------------------------------------|")
        term.setCursorPos(1, 3)
        print("              -<Catalog Items>-              |")
        term.setCursorPos(1, 4)
        print(" Item             | Price   | Stock   | Pack |")
        for i = 5, 19 do -- vertical lin shenanigans
            term.setCursorPos(46, i)
            print("|")
        end
        term.setCursorPos(46,17)
        print("|")
        term.setCursorPos(46, 18)
        print("|-------------")
        term.setCursorPos(46, 19)
        print("| 0000c | 00s")
        term.setCursorPos(1,20)
        io.write("Page "..curpage.."/"..totalpage.." [C]: Checkout [E]: Exit             |  -<Total>-")
        

        pageIndexes = getCatalogPageIndexes(curpage)
        if selectedItemIndex > #pageIndexes then
            selectedItemIndex = #pageIndexes
        end
        if selectedItemIndex < 1 then
            selectedItemIndex = 1
        end

        for count, idx in ipairs(pageIndexes) do -- render the actual item info n stuff
            local item = catalogContents[idx]
            term.setCursorPos(itemNameX, itemStartY + count - 1)
            print(item.name)
            term.setCursorPos(itemPriceX - 2, itemStartY + count - 1)
            print("|")
            term.setCursorPos(itemPriceX , itemStartY + count - 1)
            local itemCogs = math.floor(item.price / 64)
            local itemSpurs = item.price % 64
            -- format cogs and spurs to fixed 2-char fields
            local cogField
            if itemCogs > 99 then
                cogField = "++" -- too many cogs to display in 2 chars
            else
                cogField = string.format("%02d", itemCogs)
            end
            local spurField = string.format("%02d", itemSpurs)
            -- final strings include one space at start and one between cogs and spurs
            local pricestr = cogField .. "c " .. spurField .. "s"
            print(pricestr)
            term.setCursorPos(itemStockX - 2, itemStartY + count - 1)
            print("|")
            term.setCursorPos(itemStockX, itemStartY + count - 1)
            print(item.stock)
            term.setCursorPos(itemPackX - 2, itemStartY + count - 1)
            print("|")
            term.setCursorPos(itemPackX, itemStartY + count - 1)
            if item.pack ~= nil then print(item.pack) else print("1?") end
        end

        term.setCursorPos(1, selectedItemIndex + 4)
        io.write(">")
    end

    local function redrawCart(contents)
        local cartY = 2
        -- Clear cart area
        for i = 4, 16 do
            term.setCursorPos(48, i)
            io.write("            ")
        end
        -- Draw cart items (up to 7 items)
        for i = 1, math.min(8, #contents) do
            local entry = contents[i]
            local itemStr1 = string.sub(entry.name, 1, 12)
            term.setCursorPos(48, cartY + (i*2) - 2)
            io.write(itemStr1)
            local itemStr2 = " x" .. entry.count
            term.setCursorPos(48, cartY + (i*2) - 1)
            io.write(itemStr2)
        end
    end

    local function redrawTotal(newTotal)
        local cogs = math.floor(newTotal / 64)
        local spurs = newTotal % 64
        local cogsStr = string.format("%04d", cogs)
        local spursStr = string.format("%02d", spurs)
        term.setCursorPos(48, 19)
        io.write(cogsStr .. "c | " .. spursStr .. "s")
    end

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
                if item.pack ~= nil then
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
    visualCart = calcItemCount(cartContents)
    drawCatalogPage()
    redrawCart(visualCart)
    redrawTotal(calculateTotal(cartContents))

    while not checkout do
        local event, key = os.pullEvent("key")
        if event == "key" then
            local keyName = keys.getName(key)
            if keyName == "up" then -- go up
                if selectedItemIndex > 1 then
                    term.setCursorPos(1, selectedItemIndex + 4)
                    io.write(" ")
                    selectedItemIndex = selectedItemIndex - 1
                    term.setCursorPos(1, selectedItemIndex + 4)
                    io.write(">")
                elseif curpage > 1 then
                    curpage = curpage - 1
                    local prevPageIndexes = getCatalogPageIndexes(curpage)
                    selectedItemIndex = #prevPageIndexes
                    drawCatalogPage()
                end
            elseif keyName == "down" then -- go down
                if selectedItemIndex < #pageIndexes then
                    term.setCursorPos(1, selectedItemIndex + 4)
                    io.write(" ")
                    selectedItemIndex = selectedItemIndex + 1
                    term.setCursorPos(1, selectedItemIndex + 4)
                    io.write(">")
                else
                    local nextPageIndexes = getCatalogPageIndexes(curpage + 1)
                    if #nextPageIndexes > 0 then
                        curpage = curpage + 1
                        selectedItemIndex = 1
                        drawCatalogPage()
                    end
                end
            elseif keyName == "enter" then -- select (add 2 cart)
                local catalogIndex = pageIndexes[selectedItemIndex]
                if catalogIndex then
                    local item = catalogContents[catalogIndex]
                    local existing = nil
                    for _, entry in ipairs(cartContents) do
                        if entry.id == item.id then
                            existing = entry
                            break
                        end
                    end
                    if existing then
                        existing.count = existing.count + 1
                    else
                        cartContents[#cartContents + 1] = {
                            id = item.id,
                            name = item.name,
                            count = 1
                        }
                    end
                end
                drawCatalogPage()
                visualCart = calcItemCount(cartContents)
                redrawCart(visualCart)
                redrawTotal(calculateTotal(cartContents))
            elseif keyName == "leftCtrl" then
                local catalogIndex = pageIndexes[selectedItemIndex]
                if catalogIndex then
                    local item = catalogContents[catalogIndex]
                    local existing = nil
                    for idx, entry in ipairs(cartContents) do
                        if entry.id == item.id then
                            existing = idx
                            break
                        end
                    end
                    if existing then
                        if cartContents[existing].count > 1 then
                            cartContents[existing].count = cartContents[existing].count - 1
                        else
                            table.remove(cartContents, existing)
                        end
                    end
                end
                drawCatalogPage()
                visualCart = calcItemCount(cartContents)
                redrawCart(visualCart)
                redrawTotal(calculateTotal(cartContents))
            elseif keyName == "c" then -- checkout
                checkout = true
            elseif keyName == "e" then -- exit
                sleep(0.1)
                clearScreen()
                main()
                return
            elseif keyName == "o" then -- options
                renderMenu("options")
            elseif keyname == "s" then --shopList
                print("Shop list not yet implemented.")
                waitForEnter()
            end
        end
    end
    checkoutFunc()
end

function mobileCatalog() -- ill finish this in a later update or something, its rather broken and im lazy
    clearScreen()
    local cogs = math.floor(funds / 64)
    local spurs = funds % 64
    local curpage = 1
    local totalpage = math.ceil(#catalogContents / 7) -- 7 things per page (2 line per items)
    local itemNameX = 1 -- just some misc constants
    local itemStartY = 2 -- just some misc constants 2
    local itemPriceX = 21 -- just some misc constants 3
    local itemStockX = 31 -- just some misc constants 4
    local itemPackX = 41 -- just some misc constants 5
    local selectedItemIndex = 1 -- init, first item of catalog by default
    local panel = 0 -- catalog by default, 1 for shops, 2 for cart (this may actually use this variable :o)
    local checkout = false -- init, not checking out by default obviously
    --catalogContents = contactServer("catalog_fetch") -- cant use this yet, tibo needs to implement the full format on server side
    clearScreen()
    local cartStartX = 48
    local cartStartY = 2
    visualCart = {}
    do -- fancy format cogs
        local n = cogs
        if n >= 1000 then
            cogs = "999+"
        else
            local s = tostring(n)
            while #s < 7 do
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
    
    -- go ahead and check how many items there are for this page, and display them
    local pageIndexes = getCatalogPageIndexes(curpage)
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
                local itemCopy = {
                    id = entry.id,
                    name = item and item.name or entry.name,
                    count = entry.count * item.pack
                }
                seen[entry.id] = itemCopy
                output[#output + 1] = itemCopy
            end
        end
        return output
    end
    local function drawCatalogPage()
        clearScreen()
        term.setCursorPos(1, 1)
        
        local cartLen = 0
        for i in ipairs(cartContents) do
            cartLen = cartLen + 1
        end
        
        term.setTextColor(40)
        io.write("[Catalog]")
        term.setTextColor(1)
        io.write(" [Shops] [Cart (" .. cartLen .. ")]")
        term.setCursorPos(1, selectedItemIndex + 4)
        io.write(">")
        

        pageIndexes = getCatalogPageIndexes(curpage)
        if selectedItemIndex > #pageIndexes then
            selectedItemIndex = #pageIndexes
        end
        if selectedItemIndex < 1 then
            selectedItemIndex = 1
        end

        for count, idx in ipairs(pageIndexes) do -- render the actual item info n stuff
            local item = catalogContents[idx]
            term.setCursorPos(itemNameX, itemStartY + count - 1)
            print(item.name)

            local itemCogs = math.floor(item.price / 64)
            local itemSpurs = item.price % 64
            -- format cogs and spurs to fixed 2-char fields
            local cogField
            if itemCogs > 99999 then
                cogField = "a lot" -- too many cogs to display in 2 chars
            else
                cogField = string.format("%02d", itemCogs)
            end
            local spurField = string.format("%02d", itemSpurs)
            local pricestr = cogField .. "c " .. spurField .. "s"
            local numInCart = 0
            if calcItemCount(cartContents) ~= {} then
                return tostring(calcItemCount(cartContents)[item.id])
            else
                return "0"
            end
            local itemStr2 = pricestr .. " / " .. tostring(item.pack) .. numInCart
            print(itemStr2)
        end

        
    end

    local function redrawCart(contents)
        local cartY = 2
        -- Clear cart area
        for i = 4, 16 do
            term.setCursorPos(48, i)
            io.write("            ")
        end
        -- Draw cart items (up to 7 items)
        for i = 1, math.min(8, #contents) do
            local entry = contents[i]
            local itemStr1 = string.sub(entry.name, 1, 12)
            term.setCursorPos(48, cartY + (i*2) - 2)
            io.write(itemStr1)
            local itemStr2 = " x" .. entry.count
            term.setCursorPos(48, cartY + (i*2) - 1)
            io.write(itemStr2)
        end
    end

    local function redrawTotal(newTotal)
        local cogs = math.floor(newTotal / 64)
        local spurs = newTotal % 64
        local cogsStr = string.format("%04d", cogs)
        local spursStr = string.format("%02d", spurs)
        term.setCursorPos(48, 19)
        io.write(cogsStr .. "c | " .. spursStr .. "s")
    end

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

    
    visualCart = calcItemCount(cartContents)
    drawCatalogPage()
    local panelChange = false
    while not checkout do
        if panelChange then
            clearScreen()
            sleep(0.1)
            panelChange = false
        end
        local event, key = os.pullEvent("key")
        if panel == 0 then -- catalog
            if event == "key" then
                local keyName = keys.getName(key)
                if keyName == "up" then -- go up
                    if selectedItemIndex > 1 then
                        term.setCursorPos(1, selectedItemIndex + 4)
                        io.write(" ")
                        selectedItemIndex = selectedItemIndex - 1
                        term.setCursorPos(1, selectedItemIndex + 4)
                        io.write(">")
                    elseif curpage > 1 then
                        curpage = curpage - 1
                        local prevPageIndexes = getCatalogPageIndexes(curpage)
                        selectedItemIndex = #prevPageIndexes
                        drawCatalogPage()
                    end
                elseif keyName == "down" then -- go down
                    if selectedItemIndex < #pageIndexes then
                        term.setCursorPos(1, selectedItemIndex + 4)
                        io.write(" ")
                        selectedItemIndex = selectedItemIndex + 1
                        term.setCursorPos(1, selectedItemIndex + 4)
                        io.write(">")
                    else
                        local nextPageIndexes = getCatalogPageIndexes(curpage + 1)
                        if #nextPageIndexes > 0 then
                            curpage = curpage + 1
                            selectedItemIndex = 1
                            drawCatalogPage()
                        end
                    end
                elseif keyName == "enter" then -- select (add 2 cart)
                    local catalogIndex = pageIndexes[selectedItemIndex]
                    if catalogIndex then
                        local item = catalogContents[catalogIndex]
                        local existing = nil
                        for _, entry in ipairs(cartContents) do
                            if entry.id == item.id then
                                existing = entry
                                break
                            end
                        end
                        if existing then
                            existing.count = existing.count + 1
                        else
                            cartContents[#cartContents + 1] = {
                                id = item.id,
                                name = item.name,
                                count = 1
                            }
                        end
                    end
                    drawCatalogPage()
                    visualCart = calcItemCount(cartContents)
                elseif keyName == "leftCtrl" then -- remove item
                    local catalogIndex = pageIndexes[selectedItemIndex]
                    if catalogIndex then
                        local item = catalogContents[catalogIndex]
                        local existing = nil
                        for idx, entry in ipairs(cartContents) do
                            if entry.id == item.id then
                                existing = idx
                                break
                            end
                        end
                        if existing then
                                table.remove(cartContents, existing)
                        end
                    end
                    drawCatalogPage()
                    visualCart = calcItemCount(cartContents)
                    redrawCart(visualCart)
                    redrawTotal(calculateTotal(cartContents))
                
                elseif keyName == "e" then -- exit
                    sleep(0.1)
                    clearScreen()
                    main()
                    return
                elseif keyName == "o" then -- options
                    renderMenu("options")
                elseif keyName == "rightBracket" then --shopList
                    panelChange = true
                    panel = 1
                end
            end
        elseif panel == 1 then -- shops
            if event == "key" then
                local keyName = keys.getName(key)
                if keyName == "leftBracket" then 
                    panelChange = true
                    panel = 0
                elseif keyName == "rightBracket" then -- goto cart 
                    panelChange = true
                    panel = 2
                end
            end
        elseif panel == 2 then -- cart/checkout?
            return 0
        end
    end
    checkoutFunc()
end

function exit()
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
    function printOrder()
        for i, item in ipairs(visualCart) do
            local itemstr = " " .. item.name .. " x " .. item.count
            if i <= 18 then
                term.setCursorPos(1, i + 1)
                io.write(itemstr)
            elseif i <= 36 then
                term.setCursorPos(21, i - 17)
                io.write(itemstr)
            elseif i <= 54 then
                term.setCursorPos(41, i - 35)
                io.write(itemstr)
            else
                return
            end
        end
    end
    term.setCursorPos(1,1)
    io.write("-<Checkout>-")
    term.setCursorPos(1,20)
    io.write("[Y]: Purchase  [N]: Cancel  [E]: Exit  Total: " .. totalCogs .. "c " .. totalSpurs .. "s")
    printOrder()
    local done = false
    while not done do
        local event, key = os.pullEvent("key")
        if event and key then
            if key == keys.y then
                contactServer("checkout", cartContents)
                waitForEnter()
                done = true
            elseif key == keys.n then
                clearScreen()
                cartContents = {}
                catalog()
                done = true
            elseif key == keys.e then
                done = true
                clearScreen()
                exit()
            end
        end
    end
    main()
end

function initLogin()
    if fs.exists(savePath) then -- check for previous login, and if found read token from it and attempt to login
    local file = fs.open(savePath, "r")
    if file then
        local fileContents = file.readAll()
        file.close()

        token = tostring(fileContents)
        clearScreen()
        print("Connecting...")
        local serverResponse = contactServer("user_info")
        if serverResponse and serverResponse ~= nil then
            clearScreen()
            funds = serverResponse["balance"]
            username = serverResponse["username"]
            userData = serverResponse
            loggedIn = true
            initLoginDone = true
        elseif serverResponse == nil then
           error("server didn't respond with anything.",2) 
        end
    end
    end
end

-- program start
local termX, termY = term.getSize() -- check if pocket computer, for now just error out if so a bit further down
if termX == 30 then
    pocket = true
end
if not offline then
    if pocket then
        clearScreen()
        io.write("This program cannot run on a pocket computer.")
        sleep(1.5)
        exit()
    end
    clearScreen() -- clear screen before we do anything
    initLogin()
    if not fs.exists(savePath) then
        local file = fs.open(savePath, "w")
        if file then
            file.write("")
            file.close()
        end 
    end
    main()
    waitForEnter()
    clearScreen()
else
    if pocket then
        clearScreen()
        io.write("This program cannot run on a pocket computer.")
        sleep(1.5)
        exit()
    end
    username = "offlineUser"; funds = 5923; loggedIn = true -- set dummy vars, ONLY FOR DEV-ING
    clearScreen()
    main()
    clearScreen()
end