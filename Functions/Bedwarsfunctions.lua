--[[
██████╗ █████╗ ██╗ ██╗███████╗███╗ ██╗ ██████╗ ██╗ ██╗
██╔══██╗██╔══██╗██║ ██║██╔════╝████╗ ██║ ██╔══██╗██║ ██║
██████╔╝███████║██║ ██║█████╗ ██╔██╗ ██║ ██████╔╝███████║
██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝ ██║╚██╗██║ ██╔══██╗╚════██║
██║ ██║██║ ██║ ╚████╔╝ ███████╗██║ ╚████║ ██████╔╝ ██║
╚═╝ ╚═╝╚═╝ ╚═╝ ╚═══╝ ╚══════╝╚═╝ ╚═══╝ ╚═════╝ ╚═╝
Author: realcarti01
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local collectionService = game:GetService("CollectionService")
local Camera = workspace.CurrentCamera

-- Sword Animations (custom feature)
local SwordAnimations = {
    ['Remade'] = {
        {CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.05},
        {CFrame = CFrame.new(0.69, -0.71, 0.6) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.05}
    },
    ['New'] = {
        {CFrame = CFrame.new(0.69, -1.7, 0.6) * CFrame.Angles(math.rad(295), math.rad(55), math.rad(290)), Time = 0.069},
        {CFrame = CFrame.new(0.7, -1.8, 0.65) * CFrame.Angles(math.rad(200), math.rad(60), math.rad(1)), Time = 0.069}
    },
    ['Old'] = {
        {CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(220), math.rad(100), math.rad(100)), Time = 0.25},
        {CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)), Time = 0.25}
    }
}

-- Wrapped API Functions
local function IsAlive(plr)
    plr = plr or LocalPlayer
    return API.Player.getHealth(plr) > 0.11 and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
end

local function GetClosest()
    local entity = API.Entity.getNearestEntity(math.huge)
    return entity and entity.Player
end

local function GetClosestTeamCheck(distance)
    local entities = API.Entity.getEntitiesInRange(distance or math.huge)
    local myTeam = API.Player.getTeam()
    
    local Target, lowestHealth = nil, math.huge
    for _, entity in ipairs(entities) do
        if entity.Team ~= myTeam and entity.Health < lowestHealth then
            lowestHealth = entity.Health
            Target = entity.Player
        end
    end
    return Target
end

local function GetMatchState()
    return API.Utility.getMatchState()
end

local function GetQueueType()
    return API.Utility.getQueueType()
end

-- Loop Manager (custom utility)
local LoopManager = {}
LoopManager.__index = LoopManager

function LoopManager.new()
    return setmetatable({tasks = {}}, LoopManager)
end

function LoopManager:AddTask(id, callback, delay, priority)
    if self.tasks[id] then self:RemoveTask(id) end
    self.tasks[id] = {
        callback = callback,
        connection = RunService.Heartbeat:Connect(function(dt)
            pcall(callback, dt)
        end)
    }
end

function LoopManager:RemoveTask(id)
    if self.tasks[id] then
        self.tasks[id].connection:Disconnect()
        self.tasks[id] = nil
    end
end

function LoopManager:Destroy()
    for id in pairs(self.tasks) do self:RemoveTask(id) end
end

-- Monster/Entity detection
local function ClosestEntity(distance)
    local closest, minDist = nil, distance
    for _, v in ipairs(collectionService:GetTagged('Monster')) do
        if v.PrimaryPart and IsAlive(LocalPlayer) then
            local mag = (v.PrimaryPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if mag < minDist then
                minDist, closest = mag, v
            end
        end
    end
    return closest
end

-- Rotation Helper
local function rotateTo(position)
    local hroot = LocalPlayer.Character.HumanoidRootPart
    local newcf = CFrame.lookAt(hroot.Position, Vector3.new(position.X, hroot.Position.Y, position.Z))
    if newcf == newcf then hroot.CFrame = newcf end
end

-- GUI Helper
local function isNotHoveringOverGui()
    local mousepos = game:GetService("UserInputService"):GetMouseLocation() - Vector2.new(0, 36)
    for _, v in pairs(LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y)) do
        if v.Active then return false end
    end
    return true
end

-- Kit Detection
local RavenEquippedKit = "none"
local function RavenGameInfo(Info, Info2)
    if Info.Bedwars ~= Info2.Bedwars then
        RavenEquippedKit = Info.Bedwars.kit ~= "none" and Info.Bedwars.kit or ""
    end
end
API.Controllers.ClientHandlerStore.changed:connect(RavenGameInfo)
RavenGameInfo(API.Controllers.ClientHandlerStore:getState(), {})

return {
    SwordAnimations = SwordAnimations,
    IsAlive = IsAlive,
    GetClosest = GetClosest,
    GetClosestTeamCheck = GetClosestTeamCheck,
    GetMatchState = GetMatchState,
    GetQueueType = GetQueueType,
    LoopManager = LoopManager,
    ClosestEntity = ClosestEntity,
    rotateTo = rotateTo,
    isNotHoveringOverGui = isNotHoveringOverGui,
    RavenEquippedKit = RavenEquippedKit,
}
