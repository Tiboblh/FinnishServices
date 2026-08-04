-- Luma Shop Client
--  Please dont modify this, its a mess of spaghetti code.

-- importing the sha256 thing
local sha256 = require("ccryptolib.sha256")
-- var setup
local loggedIn = false --init
local savePath = "/lumashop/login.sav" -- this should match the directory that the client is in.
local modemstatus = 0 -- init
local modemSide = nil -- init
local username = "DefaultUsername"
local token = "" -- init, will read from login.sav or grab from server when logging in on launch
local serveraddr = "127.0.0.1:9142" -- server to contact for account and ordering, leave this alone.

-- string sets, easier to modify like this
local menuAssets = {
    MainMenu = {
        keybinds = {{"L", "login"}, {"R", "register"}, {"E", "sleep(0.1); return 0"}, {"H", "MainHelp"}},
        text = {" -<Luma Shop Client (No User)>-",
                "  [L] Login",
                "  [R] Register",
                "  [H] Help",
                "  [E] Exit"}
    },
    loggedInMenu = {
        keybinds = {{"C", "catalog"}, {"O", "options"}, {"L", "logout"}, {"E", "sleep(0.1); return 0"}, {"H", "optionsHelp"}},
        text = {" -<Luma Shop Client (" .. tostring(username) .. ")>-",
                "  [C] Catalog", 
                "  [O] Options",
                "  [L] Logout",
                "  [H] Help",
                "  [E] Exit"}
    },
    logOutConfirm = {
        keybinds = {{"Y", "confirmLogout"}, {"N", "cancelLogout"}},
        text = {" -<Luma Shop Client (" .. tostring(username) .. ")>-",
                "  Are you sure you want to log out?",
                "  [Y] Yes",
                "  [N] No"}
    }
}

local menuActions = {
    ["login"] = function() return login(false) end,
    ["register"] = function() return register() end,
    ["catalog"] = function() return catalog() end,
    ["options"] = function() return openOptionsMenu() end,
    ["logout"] = function() return logout() end,
    ["cancelLogout"] = function() return main() end,
    ["confirmLogout"] = function() return true end,
    ["MainHelp"] = function() return renderMenu("MainHelp") end,
    ["loginHelp"] = function() return renderMenu("loginHelp") end,
    ["registerHelp"] = function() return renderMenu("registerHelp") end,
    ["orderHelp"] = function() return renderMenu("orderHelp") end,
    ["checkoutHelp"] = function() return renderMenu("checkoutHelp") end,
    ["optionsHelp"] = function() return renderMenu("optionsHelp") end,
}

function waitForEnter()
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.enter then
            return
        end
    end
end

local modemTypes = {
    modem = 1,
    modem_wireless = 2,
    modem_ender = 3,
}

function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

for _, side in ipairs(peripheral.getNames()) do
    local typeName = peripheral.getType(side)
    local modemType = modemTypes[typeName]

    if modemType and modemType > modemstatus then
        modemstatus = modemType
        modemSide = side
    end
end
if modemSide then
    peripheral.find("modem", function(name, modem)
        if name == modemSide then
            return true
        end
    end)
end

if fs.exists(savePath) then -- check for previous login, and if found read token from it
    local file = fs.open(savePath, "r")
    if file then
        local fileContents = file.readAll()
        file.close()

        token = tostring(fileContents)
        if token == "fakeToken1" then
            loggedIn = true
        end
    end
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
    if type(data) ~= "table" then
        error("Internal error: data to contact server must be a table, not a " .. type(data))
    end

    if mode == "login" then
        url = "http://" .. serveraddr .. "/api/login"
    end
    if mode == "register" then
        url = "http://" .. serveraddr .. "/api/register"
    end
    if mode == "catalog" then
        error("Catalog not implemented on server.")

    else
        error("Internal error: unknown mode for contacting server: " .. tostring(mode))
    end

    return 0
end

clearScreen() -- clear screen before we do anything

if modemstatus == 0 then
    error("no modem, please connect a wireless or ender one to use luma shop")
elseif modemstatus == 1 then
    print("You are using a wired modem. by continuing, you must be connected to the luma shop server via cable.")
    print("Press [Enter] to continue.")
    waitForEnter()
elseif modemstatus == 2 then
    print("You are using a wireless modem, expect connection issues if not close enough to the server.")
    print("Press [Enter] to continue.")
    waitForEnter()
    main()
elseif modemstatus == 3 then
    main()
end

function renderMenu(menuName)
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
        menu.text[1] = " -<Luma Shop Client (" .. tostring(username) .. ")>-"
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

function login(boot)
    if boot then
        if token == "fakeToken1" then
            loggedIn = true
            username = "Fake User"
            main()
        end
    else
        clearScreen()
        print("user account stuff isn't yet implemented, so you will be \"signed in\" as a fake user.")
        print("press [Enter] to continue")
        username = "Fake User"
        loggedIn = true
        token = "fakeToken1"
        saveToken()
        waitForEnter()
        main()
    end
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
    fs.delete(savePath) -- delete the login.sav file to remove token.
    loggedIn = false
    main()
end

function register()
    clearScreen()
    print("user account stuff isn't yet implemented, so you will be \"registered\" as a fake user.")
    print("press [Enter] to continue")
    waitForEnter()
    username = "Fake User"
    loggedIn = true
    main()
end

function main() -- yep, main is THIS simple
    clearScreen()
    if loggedIn then
        renderMenu("loggedInMenu")
    else
        renderMenu("MainMenu")
    end
end

function catalog()
    clearScreen()
    print("Catalog is not yet implemented.")
    waitForEnter()
    main()
end

function openOptionsMenu()
    clearScreen()
    print("Options are not yet implemented.")
    waitForEnter()
    main()
end


-- here is where main is actually run :o
login(true) -- check for login.sav and log in if found
main()
clearScreen()