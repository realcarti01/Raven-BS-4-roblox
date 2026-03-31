repeat task.wait(0.1) until game:IsLoaded() -- Wait for the game to load

local HttpRequest = request or http_request
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BASE_URL = "https://github.com/realcarti01/Raven-BS-4-roblox/raw/refs/heads/main/"
local RAW_BASE_URL = "https://raw.githubusercontent.com/realcarti01/Raven-BS-4-roblox/refs/heads/main"
local RavenBS = {}
RavenBS.__index = RavenBS

function RavenBS.new()
    local self = setmetatable({}, RavenBS)
    self.ConfigPath = "RavenBS/Config"
    self.LoadFontPath = "RavenBS"
    self.FontPath = "RavenBS/Font"
    self.GameName = ""
    self.ConfigName = "Default Config"
    self.SupportedGames = {
        Bladeball = {13772394625, 14915220621, 15144787112, 15234596844, 15264892126, 15185247558},
        Petsim99 = {8737899170},
        Skywars = {8542259458, 8542275097, 8592115909, 8768229691, 8951451142, 13246639586},
        Bridgeduels = {139566161526375},
        SurvivalGame = {11156779721},
        Bedwars = {6872265039, 6872274481, 8444591321, 8560631822},
        Booga = {11729688377}
    }
    self.IsInjected = false
    return self
end

function RavenBS:CheckExecutorSupport()
    if not (writefile and readfile and makefolder and isfolder) then
        Players.LocalPlayer:Kick("Executor is not supported, please use another executor for Raven BS!")
        return false
    end
    return true
end

function RavenBS:SetupDirectories()
    if not isfolder(self.FontPath) then
        makefolder(self.FontPath)
    end
    if not isfolder(self.ConfigPath) then
        makefolder(self.ConfigPath)
    end
end

function RavenBS:DownloadFonts()
    local fonts = {
        {name = "MCBold", url = BASE_URL .. "MCBold.otf", config = "MCBold.json"},
        {name = "MCReg", url = BASE_URL .. "MCReg.otf", config = "MCReg.json"}
    }

    for _, font in ipairs(fonts) do
        local success, response = pcall(function()
            return HttpRequest({
                Url = font.url,
                Method = "GET"
            }).Body
        end)

        if success then
            writefile(self.FontPath .. "/" .. font.name .. ".otf", response)
            self:WriteFontConfig(font.name, font.config)
        else
            print("Failed to download " .. font.name .. " font")
        end
    end
end

function RavenBS:WriteFontConfig(fontName, configFile)
    local config = {
        name = "Minecraft",
        faces = {{
            name = fontName == "MCBold" and "Bold" or "Regular",
            weight = 500,
            style = "normal",
            assetId = getcustomasset(self.FontPath .. "/" .. fontName .. ".otf")
        }}
    }
    writefile(self.LoadFontPath .. "/" .. configFile, HttpService:JSONEncode(config))
end

function RavenBS:DetectGame()
    for gameName, placeIds in pairs(self.SupportedGames) do
        if table.find(placeIds, game.PlaceId) then
            self.GameName = gameName
            self.ConfigName = "Raven BS" .. gameName .. ".json"
            return true
        end
    end
    print("Game is not supported")
    return false
end

function stringload(arg1)
    if shared.devtesting == true then
        loadstring(readfile(arg1))()
    else
        loadstring(game:HttpGet(arg1))()
    end
end

function RavenBS:LoadModules()
    local modulePath = shared.devtesting and "Raven-BS-4-roblox" or RAW_BASE_URL
    local strings = {
        api = "https://raw.githubusercontent.com/realcarti01/Bedwars-API/refs/heads/main/BedwarsAPI.lua",
        functions = modulePath .. "/Functions/" .. self.GameName .. "functions.lua",
        gui = modulePath .. "/GUI/RavenGUI.lua",
        buttons = modulePath .. "/Functions/Buttonfunctions.lua",
        games = modulePath .. "/Games/" .. self.GameName .. ".lua"
    }
    
    print("[RavenBS Loader] Loading API from:", strings.api)
    print("[RavenBS Loader] Loading functions from:", strings.functions)
    
    -- Try to load API, but make it optional
    local apiLoaded = false
    local apiSuccess, apiResult = pcall(function()
        if shared.devtesting then
            local apiCode = readfile(strings.api)
            if apiCode and #apiCode > 0 then
                API = loadstring(apiCode)()
                if API then apiLoaded = true end
            end
        else
            local apiCode = game:HttpGet(strings.api)
            if apiCode and #apiCode > 0 then
                API = loadstring(apiCode)()
                if API then apiLoaded = true end
            end
        end
    end)
    
    if not apiLoaded then
        warn("[RavenBS Loader] API loading failed or not available - using minimal fallback")
        warn("[RavenBS Loader] API path:", strings.api)
        API = {} -- Minimal fallback API
    else
        print("[RavenBS Loader] API loaded successfully")
    end
    
    -- Load functions (required)
    local funcSuccess, funcResult = pcall(function()
        if shared.devtesting then
            local funcCode = readfile(strings.functions)
            if not funcCode then error("Failed to read functions file") end
            module = loadstring(funcCode)()
            if not module then error("Failed to execute functions code") end
        else
            local funcCode = game:HttpGet(strings.functions)
            if not funcCode then error("Failed to get functions from GitHub") end
            module = loadstring(funcCode)()
            if not module then error("Failed to execute functions code") end
        end
    end)
    
    if not funcSuccess then
        error("[RavenBS CRITICAL] Failed to load game functions: " .. tostring(funcResult))
        return nil
    end
    
    print("[RavenBS Loader] Core modules loaded successfully")
    
    if shared.devtesting then
        local guiCode = readfile(strings.gui)
        if not guiCode then error("Failed to read GUI file") end
        lib = loadstring(guiCode)()
        if not lib then error("Failed to execute GUI code") end
        
        local buttonCode = readfile(strings.buttons)
        if not buttonCode then error("Failed to read buttons file") end
        buttons = loadstring(buttonCode)()
        if not buttons then error("Failed to execute buttons code") end
        
        local gameCode = readfile(strings.games)
        if not gameCode then error("Failed to read game file") end
        loadstring(gameCode)()
    else
        local guiCode = game:HttpGet(strings.gui)
        if not guiCode then error("Failed to get GUI from GitHub") end
        lib = loadstring(guiCode)()
        if not lib then error("Failed to execute GUI code") end
        
        local buttonCode = game:HttpGet(strings.buttons)
        if not buttonCode then error("Failed to get buttons from GitHub") end
        buttons = loadstring(buttonCode)()
        if not buttons then error("Failed to execute buttons code") end
        
        local gameCode = game:HttpGet(strings.games)
        if not gameCode then error("Failed to get game file from GitHub") end
        loadstring(gameCode)()
    end
    
    print("[RavenBS Loader] All modules loaded successfully")
    return lib
end


function RavenBS:Initialize()
    if shared.RavenBSInjected then
        error("RavenBS is already injected!")
    end

    if not self:CheckExecutorSupport() then
        warn("[RavenBS] Executor not supported")
        return nil
    end

    self:SetupDirectories()
    self:DownloadFonts()

    if self:DetectGame() then
        print("[RavenBS] Game detected:", self.GameName)
        shared.RavenConfigName = "RavenBS/Config/" .. self.ConfigName
        shared.RavenBSInjected = true
        local result = self:LoadModules()
        if not result then
            error("[RavenBS CRITICAL] LoadModules returned nil!")
            return nil
        end
        print("[RavenBS] Initialization complete!")
        return result
    else
        warn("[RavenBS] Game not supported")
        return nil
    end
end

local raven = RavenBS.new()
print("[RavenBS Loader] Initializing RavenBS...")
local lib = raven:Initialize()

if not lib then
    error("[RavenBS CRITICAL] lib is nil! Initialization failed.")
    return
end

print("[RavenBS Loader] lib loaded successfully:", lib ~= nil)
local teleportactive = false
spawn(function()
    repeat task.wait(0.1) until LocalPlayer ~= nil
    LocalPlayer.OnTeleport:Connect(function()
        if shared.RavenBSInjected and teleportactive ~= true then --prevents multiple injections when testing
            teleportactive = true
            if shared.devtesting then 
                queue_on_teleport('loadstring(readfile("Raven-BS-4-roblox/Raven BS Loader.lua"))()')
            else
                queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/realcarti01/Raven-BS-4-roblox/refs/heads/main/Raven%20BS%20Loader.lua"))()')
            end
        end
    end)
end)
return lib
