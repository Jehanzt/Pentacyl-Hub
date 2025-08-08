-- mainscript.lua
-- Pentacyl Hub - Local-only Rayfield UI with troll features
-- This script is intended to be loaded by loader.lua after key validation.
-- Personalize PERSONAL_NAME at top if you want.

-- CONFIG
local PERSONAL_NAME = "Jehanz" -- displayed in welcome
local NOTIFY_IMAGE = 4483362458

-- Load Rayfield (graceful fail)
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then
    warn("Rayfield failed to load. The hub cannot initialize.")
    return
end

-- Create window
local Window = Rayfield:CreateWindow({
   Name = "Pentacyl Hub - Troll Edition",
   Icon = 0,
   LoadingTitle = "Loading Pentacyl Hub",
   LoadingSubtitle = "by Pentacyl/Jehanzt",
   ShowText = "Pentacyl",
   Theme = "Default",
   ToggleUIKeybind = "K",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "PentacylHub",
      FileName = "LocalConfig"
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local UIS = game:GetService("UserInputService")

-- Tabs
local PlayerTab = Window:CreateTab("Player", 4483362458)
local TrollTab   = Window:CreateTab("Troll", 4483362458)
local SettingsTab= Window:CreateTab("Settings", 4483362458)

-- STATE
local hasInfiniteJump = false
local spinSelf = false

-- Personal welcome
Rayfield:Notify({
    Title = "Welcome " .. (PERSONAL_NAME or LocalPlayer.Name),
    Content = "Pentacyl Hub (Local) ready. Use K to toggle UI.",
    Duration = 5,
    Image = NOTIFY_IMAGE
})

-- ===== Player Tab (self) =====
PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(val)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.WalkSpeed = val end) end
    end
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(val)
        hasInfiniteJump = val
        if val then
            if not _G.__Pentacyl_InfJumpConn then
                _G.__Pentacyl_InfJumpConn = UIS.JumpRequest:Connect(function()
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum:ChangeState("Jumping") end) end
                end)
            end
        else
            if _G.__Pentacyl_InfJumpConn then
                _G.__Pentacyl_InfJumpConn:Disconnect()
                _G.__Pentacyl_InfJumpConn = nil
            end
        end
    end
})

PlayerTab:CreateButton({
    Name = "Spin Self (toggle)",
    Callback = function()
        if spinSelf then
            spinSelf = false
            return
        end
        spinSelf = true
        spawn(function()
            while spinSelf do
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    pcall(function()
                        char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(45), 0)
                    end)
                end
                task.wait(0.03)
            end
        end)
    end
})

-- ===== Troll functions (targeted, client-only manipulations) =====
local function findPlayerByName(name)
    if not name or name == "" then return nil end
    for _,p in pairs(Players:GetPlayers()) do
        if p.Name:lower() == name:lower() then return p end
    end
    for _,p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1,#name) == name:lower() then return p end
    end
    return nil
end

local function chooseTarget(name)
    if not name or name == "" or name:lower() == "random" then
        local pool = {}
        for _,p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(pool, p) end end
        if #pool == 0 then return nil end
        return pool[math.random(1,#pool)]
    else
        return findPlayerByName(name)
    end
end

local function spinTarget(target, dur)
    if not target or not target.Character then return end
    spawn(function()
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local stop = tick() + (dur or 5)
        while tick() < stop do
            pcall(function() hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(60), 0) end)
            task.wait(0.03)
        end
    end)
end

local function launchTarget(target, extra)
    if not target or not target.Character then return end
    pcall(function()
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Velocity = Vector3.new(0, 180 + (extra and extra.force or 0), 0) end
    end)
end

local function teleportRandomTarget(target)
    if not target or not target.Character then return end
    pcall(function()
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local offset = Vector3.new(math.random(-50,50), math.random(5,40), math.random(-50,50))
        hrp.CFrame = hrp.CFrame + offset
    end)
end

local function invisibleTarget(target, dur)
    if not target or not target.Character then return end
    spawn(function()
        local desc = target.Character:GetDescendants()
        for _,v in ipairs(desc) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                pcall(function() v.Transparency = 1 end)
            elseif v:IsA("Decal") then
                pcall(function() v.Transparency = 1 end)
            end
        end
        task.wait(dur or 6)
        for _,v in ipairs(desc) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                pcall(function() v.Transparency = 0 end)
            elseif v:IsA("Decal") then
                pcall(function() v.Transparency = 0 end)
            end
        end
    end)
end

local function soundSpamTarget(target, dur)
    if not target or not target.Character then return end
    spawn(function()
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for i=1, math.max(3, math.floor(dur or 5)) do
            local s = Instance.new("Sound", hrp)
            s.SoundId = "rbxassetid://138186576"
            s.Volume = 3
            pcall(function() s:Play() end)
            Debris:AddItem(s, 6)
            task.wait(0.6)
        end
    end)
end

local function freezeTarget(target, dur)
    if not target or not target.Character then return end
    spawn(function()
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local prevWS = hum.WalkSpeed
        local prevJP = hum.JumpPower
        pcall(function() hum.WalkSpeed = 0; if hum.JumpPower then hum.JumpPower = 0 end end)
        task.wait(dur or 5)
        pcall(function() hum.WalkSpeed = prevWS or 16; if prevJP then hum.JumpPower = prevJP end end)
    end)
end

local function weirdWalkTarget(target, dur)
    if not target or not target.Character then return end
    spawn(function()
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local orig = hum.WalkSpeed
        local t0 = tick()
        while tick() - t0 < (dur or 6) do
            pcall(function() hum.WalkSpeed = 6 + math.abs(math.sin(tick()*6) * 30) end)
            task.wait(0.06)
        end
        pcall(function() hum.WalkSpeed = orig end)
    end)
end

local function invertControlsTarget(target, dur)
    if not target or not target.Character then return end
    spawn(function()
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local start = tick()
        while tick() - start < (dur or 5) do
            local f = Instance.new("BodyVelocity")
            f.MaxForce = Vector3.new(20000, 0, 20000)
            f.Velocity = -hrp.CFrame.LookVector * 10
            f.Parent = hrp
            Debris:AddItem(f, 0.12)
            task.wait(0.18)
        end
    end)
end

-- ===== Troll Tab Buttons (target chosen in Settings tab) =====
-- Settings: simple target name input
SettingsTab:CreateInput({
    Name = "Target Name (or Random)",
    PlaceholderText = "Type username or 'Random'",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        Window.Flags = Window.Flags or {}
        Window.Flags["TargetName"] = { Value = txt }
        Rayfield:Notify({Title="Target", Content="Target set to: "..tostring(txt), Duration = 2})
    end
})

local function getWindowTarget()
    local t = Window.Flags and Window.Flags["TargetName"] and Window.Flags["TargetName"].Value or ""
    return chooseTarget(t)
end

local function chooseTarget(name)
    if not name or name == "" or name:lower() == "random" then
        local pool = {}
        for _,p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(pool, p) end end
        if #pool == 0 then return nil end
        return pool[math.random(1,#pool)]
    else
        return findPlayerByName(name)
    end
end

local function mkTrollButton(label, fn)
    TrollTab:CreateButton({
        Name = label,
        Callback = function()
            local target = getWindowTarget()
            if not target then
                Rayfield:Notify({Title="Pentacyl", Content="No valid target", Duration=2})
                return
            end
            fn(target)
            Rayfield:Notify({Title="Pentacyl", Content=label.." used on "..target.Name, Duration=2})
        end
    })
end

mkTrollButton("Spin Target", function(t) spinTarget(t, 6) end)
mkTrollButton("Launch Target", function(t) launchTarget(t, {}) end)
mkTrollButton("Teleport Randomly", function(t) teleportRandomTarget(t) end)
mkTrollButton("Make Invisible", function(t) invisibleTarget(t, 6) end)
mkTrollButton("Sound Spam", function(t) soundSpamTarget(t, 6) end)
mkTrollButton("Freeze Target", function(t) freezeTarget(t, 5) end)
mkTrollButton("Weird Walk", function(t) weirdWalkTarget(t, 6) end)
mkTrollButton("Invert Controls", function(t) invertControlsTarget(t, 5) end)

-- ===== Extra: hotkey T -> select nearest player (fills Settings flag) =====
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.T then
        local nearest, nd = nil, math.huge
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local d = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if d < nd then nd = d; nearest = p end
            end
        end
        if nearest then
            Window.Flags = Window.Flags or {}
            Window.Flags["TargetName"] = { Value = nearest.Name }
            Rayfield:Notify({Title="Pentacyl", Content="Nearest target: "..nearest.Name, Duration = 2})
        end
    end
end)

print("[Pentacyl Hub] loaded (local mainscript)")
