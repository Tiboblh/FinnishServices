---@diagnostic disable: need-check-nil
-- lua Shop Client
--  Please dont modify this, its a mess of spaghetti code.

-- importing the sha256 thing
local sha256 = require("ccryptolib.sha256")
-- var setup
local loggedIn = false --init
local savePath = "/luashop/login.sav" -- this should match the directory that the client is in.
local username = "DefaultUsername"
local token = "" -- init
local serveraddr = "http://vps-2ddc970b.vps.ovh.net:9142" -- server to contact for account and ordering, leave this alone.
local funds = 0 --init
local userData = {}
local cartContents = {}
local catalogContents = { -- this is testing stuff, will be set to empty for init later on, or just renamed idk
    { -- dirt
        id="minecraft:dirt", -- ID of item, for requesting internally
        name="Dirt", --actual name of item, displayed to user (MUST BE 16 CHARS OR LESS (12 or less for cart display))
        price=(1*64), -- price in spurs, the (0*64) block is added for cogs too to make easier
        description="brown substance from the earth", -- description of the item, might be displayed later?
        stock=272, -- ammount of stock available, if less than pack size it cannot be purchased.
        pack=16, --ammount purchased at a time, cannot be purchased in smaller increments
        locked=false -- determine if this item should be in catalog, but not returned to client (locked)
    },
    { -- cobblestone
        id="minecraft:cobblestone",
        name="Cobblestone",
        price=(2*64), -- 2 cogs, 0 spurs
        description="not tasty rocks, also from the earth.",
        stock=389,
        pack=32,
        locked=false
    },
    { -- iron ingot
        id="minecraft:iron_ingot",
        name="Iron Ingot",
        price=(2*64), -- 2 cogs, 0 spurs
        description="metal object of some kind",
        stock=131,
        pack=8,
        locked=false
    },
    { -- gold ingot
        id="minecraft:gold_ingot",
        name="Gold Ingot",
        price=(4*64), -- 4 cogs, 0 spurs
        description="mm butter",
        stock=42,
        pack=4,
        locked=false
    },
    { -- diamond
        id="minecraft:diamond",
        name="Diamond",
        price=(8*64), -- 8 cogs, 0 spurs
        description="veri shinyier rock",
        stock=12,
        pack=1,
        locked=false
    },
    { -- emerald
        id="minecraft:emerald",
        name="Emerald",
        price=(16*64), -- 16 cogs, 0 spurs
        description="green rock, villager liek",
        stock=12,
        pack=2,
        locked=false
    },
    { -- netherite ingot
        id="minecraft:netherite_ingot",
        name="Netherite Ingot",
        price=(32*64), -- 32 cogs, 0 spurs
        description="burnt butter",
        stock=3,
        pack=1,
        locked=false
    },
    { -- redstone
        id="minecraft:redstone",
        name="Redstone",
        price=(1*64), -- 1 cogs, 0 spurs
        description="red rock, makes things go",
        stock=128,
        pack=16,
        locked=false
    },
    { -- lapis lazuli
        id="minecraft:lapis_lazuli",
        name="Lapis Lazuli",
        price=(2*64), -- 2 cogs, 0 spurs
        description="blue rock, makes enchant go",
        stock=64,
        pack=8,
        locked=false
    },
    { -- andesite casing
        id="create:andesite_casing",
        name="Andesite Casing",
        price=(1*64), -- 1 cogs, 0 spurs
        description="used to encase things",
        stock=64,
        pack=8,
        locked=false
    },
    { -- brass casing
        id="create:brass_casing",
        name="Brass Casing",
        price=(2*64), -- 2 cogs, 0 spurs
        description="used to encase things but shinyer",
        stock=32,
        pack=4,
        locked=false
    },
    { -- copper casing
        id="create:copper_casing",
        name="Copper Casing",
        price=(1*64), -- 1 cogs, 0 spurs
        description="used to encase things",
        stock=64,
        pack=8,
        locked=false
    },
    { -- steak
        id="minecraft:cooked_beef",
        name="Steak",
        price=(1*64), -- 1 cogs, 0 spurs
        description="8 burger",
        stock=64,
        pack=8,
        locked=false
    },
    { -- bread
        id="minecraft:bread",
        name="Bread",
        price=(1*64), -- 1 cogs, 0 spurs
        description="4 burger",
        stock=64,
        pack=8,
        locked=false
    },
    { -- cake
        id="minecraft:cake",
        name="Cake",
        price=(2*64), -- 2 cogs, 0 spurs
        description="8 burger",
        stock=32,
        pack=4,
        locked=false
    },
    { -- cookie
        id="minecraft:cookie",
        name="Cookie",
        price=(1*64), -- 1 cogs, 0 spurs
        description="1 burger",
        stock=128,
        pack=16,
        locked=false
    },
    { -- golden apple
        id="minecraft:golden_apple",
        name="Gapple",
        price=(8*64), -- 8 cogs, 0 spurs
        description="8 burger, but shiny",
        stock=16,
        pack=2,
        locked=false
    },
    { -- enchanted golden apple
        id="minecraft:enchanted_golden_apple",
        name="E. Gapple",
        price=(32*64), -- 32 cogs, 0 spurs
        description="32 burger, but shinyer",
        stock=4,
        pack=1,
        locked=false
    },
    { -- wrench
        id="create:wrench",
        name="Create Wrench",
        price=(4*64), -- 4 cogs, 0 spurs
        description="used to wrench things",
        stock=16,
        pack=1,
        locked=false
    }
} 
local catalogContents_ = {}

-- string sets, easier to modify like this
local menuAssets = {
    MainMenu = {
        keybinds = {{"L", "login"}, {"R", "register"}, {"E", "sleep(0.1); return 0"}},
        text = {" -<lua Shop Client (No User)>-",
                "  [L] Login",
                "  [R] Register",
                "  [E] Exit"}
    },
    loggedInMenu = {
        keybinds = {{"C", "catalog"}, {"O", "options"}, {"L", "logout"}, {"E", "sleep(0.1); return 0"}},
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
            "  [F] Toggle Public frogports ( currently " .. tostring(userData["use_public_frogports"]) .. ")",
            "  [B] Back"
        }
    }
}

local optionsFuncs = {
    changeUsername = function ()
        clearScreen() -- same as change pass func but for username
        print("Not Implemented")
        print("[Enter]: Back/Exit]")
        waitForEnter()
    end,
    changePassword = function ()
        clearScreen() -- this may not actually be implemented, token related nonsense. (it just dodes same as change address but for pass)
        print("Not Implemented")
        print("[Enter]: Back/Exit]")
        waitForEnter()
    end,
    changeAddress = function ()
        clearScreen() -- this should give a text prompt that requests a new address, sends it to server to update
        print("Not Implemented")
        print("[Enter]: Back/Exit]")
        waitForEnter()
    end,
    togglePubFrogports = function ()
        clearScreen() -- this function should send a reqeust to the server to toggle Public Frogports, and then reload the options menu
        print("Not Implemented")
        print("[Enter]: Back/Exit]")
        waitForEnter()
    end
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
    ["options"] = function() return renderMenu("options") end,
    ["changeUsername"] = function() return optionsFuncs.changeUsername() end,
    ["changePassword"] = function() return optionsFuncs.changePassword() end,
    ["changeAddress"] = function() return optionsFuncs.changeAddress() end,
    ["togglePubFrogports"] = function() return optionsFuncs.togglePubFrogports() end
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

function getCatalogPageIndexes(page)
    local pageSize = 14
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
    if mode ~= "user_info" and not data then
        error("data must be provided for mode: " .. tostring(mode))
    end

    if mode == "login" then
        local url = serveraddr .. "/api/login"
        local headers = {["Content-Type"] = "application/json"}
        local payload = data
        local response = http.post(url, textutils.serialiseJSON(payload), headers)
        
        if response then
            local data = textutils.unserializeJSON(response)
            return data
        else
            error("The server did not respond with user data. perhaps you typed a wrong username or password?")
        end
        if not(data.username or data.password) then
            error("missing one or more components to login")
        end
    elseif mode == "register" then
        local url = serveraddr .. "/api/register"
        local headers = {["Content-Type"] = "application/json"}
        local payload = data
        local response = http.post(url, textutils.serialiseJSON(payload), headers)
        
        if response then
            local data = response
            return data
        else
            error("The server did not respond. perhaps you input an already taken username?")
        end
        if not(data.username or data.password or data.home_address or data.use_public_frogports) then
            error("missing one or more components to register")
        end
    elseif mode == "user_info" then
        local url = serveraddr .. "/api/user_info"
        local headers = {["Authorization"] = "Bearer " .. token}
        local response = http.get(url, headers)
        if response then
            local body = response.readAll()
            local data = textutils.unserializeJSON(body)
            if type(data) == "table" then
                return data
            end
        end
        return nil
    elseif mode == "catalog_fetch" then
        local url = serveraddr .. "/api/catalog"
        local headers = {["Authorization"] = "Bearer " .. token}
        local response = http.get(url, headers)
        if response then
            local body = response.readAll()
            local data = textutils.unserializeJSON(body)
            if type(data) == "table" then
                return data
            end
        end
    else
        error("unknown mode for contacting server: " .. tostring(mode))
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
    end

    clearScreen()

    for i = 1, #menu.text do
        print(menu.text[i])
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
    print("-<Log in>-")
    
    print("Username: ")
    local username_input = read()
    print("Password: ")
    local password_input = read("*")

    local payload = {
        username = username_input,
        password = str2hexa(sha256.digest(password_input))
    }
    local serverResponse = contactServer("login", payload)
    username = username_input
    loggedIn = true
    token = serverResponse["token"]
    saveToken()
    waitForEnter()
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
    username = username_input
    funds = 0
    token = ""
    loggedIn = true
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

function catalog()
    clearScreen()
    term.setCursorPos(1,1)
    -- local catalogContents = contactServer("catalog_fetch")
    local cogs = math.floor(funds / 64)
    local spurs = funds % 64
    local curpage = 1
    local totalpage = math.ceil(#catalogContents / 14) -- 14 things per page
    local itemNameX = 3 -- just some misc constants
    local itemStartY = 5 -- just some misc constants
    local itemPriceX = 21 -- just some misc constants
    local itemStockX = 31 -- just some misc constants
    local itemPackX = 41 -- just some misc constants
    local selectedItemIndex = 1 -- init, first item of catalog by default
    local selectedPanel = 0 -- catalog by default, 1 for cart
    checkout = false -- init, not checking out by default
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
        print(' [S]: Shops [O]: Options    | ' .. cogs .. "c | " .. spurs .. "s |  -<Cart>-")
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
            print(item.pack)
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

    drawCatalogPage()

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
    


    waitForEnter()
    main()
end

function exit()
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
                -- contactServer("checkout", cartContents) -- this is commented out for now, till server has this implemented
                clearScreen()
                print("Since the server doesnt have checkout implemented, just imagine that you got your items delivered and balance reduced by combined price of your order.")
                print("")
                print("[Enter]: exit/back")
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



-- program start
clearScreen() -- clear screen before we do anything
if fs.exists(savePath) then -- check for previous login, and if found read token from it and attempt to login
    local file = fs.open(savePath, "r")
    if file then
        local fileContents = file.readAll()
        file.close()

        token = tostring(fileContents)
        local serverResponse = contactServer("user_info")
        if serverResponse then
            funds = serverResponse["balance"]
            username = serverResponse["username"]
            userData = serverResponse
            loggedIn = true

        end

    end
end
main()
clearScreen()