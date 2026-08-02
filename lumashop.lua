-- var setup
local loggedIn = false
local savePath = "/lumashop/login.sav"
local modemstatus = 0
local modemSide = nil

-- string sets, easier to modify like this
local menuAssets = {
    loggedInMenu = {
        keybinds = {{"C", "catalog()"}, {"O", "openOptionsMenu()"}, {"E", "return 0"}},
        " -<Luma Shop Client>-",
        "  [C] Catalog",
        "  [O] Options",
        "  [E] Exit"
    }
}



local function waitForEnter()
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

if fs.exists(savePath) then -- check if user has logged in
    local file = fs.open(savePath, "r")
    if file then
        local data = file.readAll()
        file.close()

        local saved = textutils.unserialize(data)

        if type(saved) == "table" then
            local hasUser = saved.username ~= nil or saved.user ~= nil
            local hasPass = saved.pass ~= nil or saved.password ~= nil

            if hasUser and hasPass then
                loggedIn = true
            end
        end
    end
end

clearScreen() -- clear screen before we do anything

if modemstatus == 0 then
    error("no modem, please connect a wireless or ender one to use luma shop")
elseif modemstatus == 1 then
    print("You are using a wired modem. by continuing, you must be connected to the luma shop server via cable.")
    print("Press [Enter] to continue.")
    waitForEnter()
elseif modemstatus == 2 then
    print("You are using a wireless modem, expect a worse experience or connection issues.")
    print("Press [Enter] to continue.")
    waitForEnter()
    main()
elseif modemstatus == 3 then
    main()
end

function main()
    if loggedIn then
        clearScreen()
        print("\n")
        print(" -<Luma Shop Client>-")
        print()
    else
        clearScreen()
        print(" -<Luma Shop Client>-")
        print()
    end
end

function catalog()
    clearScreen()
    print("Catalog is not yet implemented.")
    waitForEnter()
    main()
end

if main() == "exit" then
    return 0
end