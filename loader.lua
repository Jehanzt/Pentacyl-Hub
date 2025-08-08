-- loader.lua
-- Run this first. It asks for a key, lets user join Discord (copies invite), saves key locally,
-- and loads mainscript.lua from GitHub raw if key is valid.
-- Works in exploit environments that support writefile/readfile; falls back to _G if not available.

-- ===== CONFIG =====
local DISCORD_INVITE = "https://discord.gg/N7MPYS4S5B" -- change to your invite
local KEY_RAW_URL    = "https://raw.githubusercontent.com/Jehanzt/Pentacyl-Hub/refs/heads/main/key.txt" -- raw file with current key (single line)
local MAIN_SCRIPT_URL= "https://raw.githubusercontent.com/Jehanzt/Pentacyl-Hub/refs/heads/main/mainscript.lua" -- raw main script
local LOCAL_KEY_FILE = "PentacylHub_key.txt" -- file saved locally (writefile/readfile)

-- ===== SERVICES =====
local HttpService = game:GetService("HttpService")
local StarterGui  = game:GetService("StarterGui")

-- ===== UTIL: safe file read/write =====
local function canReadFile()
    return type(readfile) == "function"
end
local function canWriteFile()
    return type(writefile) == "function"
end

local function saveKeyLocal(key)
    if canWriteFile() then
        pcall(function() writefile(LOCAL_KEY_FILE, tostring(key)) end)
    else
        -- fallback to global table
        _G.__Pentacyl_LocalKey = tostring(key)
    end
end

local function loadKeyLocal()
    if canReadFile() then
        local ok, content = pcall(function() return readfile(LOCAL_KEY_FILE) end)
        if ok and type(content) == "string" and content ~= "" then
            return content
        end
    else
        return _G.__Pentacyl_LocalKey
    end
    return nil
end

local function clearLocalKey()
    if canWriteFile() then
        pcall(function() delfile(LOCAL_KEY_FILE) end) -- some exploiters have delfile
        pcall(function() writefile(LOCAL_KEY_FILE, "") end)
    else
        _G.__Pentacyl_LocalKey = nil
    end
end

-- ===== FETCH remote key =====
local function fetchRemoteKey()
    local ok, res = pcall(function()
        return game:HttpGet(KEY_RAW_URL, true)
    end)
    if not ok or not res then return nil end
    -- extract first non-empty line
    for line in res:gmatch("([^\r\n]+)") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then return line end
    end
    return nil
end

-- ===== LOAD main script =====
local function loadMain()
    local ok, res = pcall(function()
        local code = game:HttpGet(MAIN_SCRIPT_URL, true)
        return loadstring(code)()
    end)
    if not ok then
        StarterGui:SetCore("SendNotification", {
            Title = "Pentacyl Loader",
            Text = "Failed to load main script: "..tostring(res),
            Duration = 5
        })
    end
end

-- ===== UI BUILD =====
local function buildUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PentacylLoaderGUI"
    ScreenGui.ResetOnSpawn = false
    -- prefer CoreGui so exploits show it; fallback to PlayerGui
    if game:GetService("CoreGui") then
        ScreenGui.Parent = game:GetService("CoreGui")
    else
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local frame = Instance.new("Frame", ScreenGui)
    frame.Size = UDim2.new(0, 360, 0, 220)
    frame.Position = UDim2.new(0.5, -180, 0.5, -110)
    frame.Active = true
    frame.Draggable = true
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    frame.Name = "LoaderFrame"

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,40)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "🔒 Pentacyl Loader"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20

    local info = Instance.new("TextLabel", frame)
    info.Size = UDim2.new(1,-20,0,48)
    info.Position = UDim2.new(0,10,0,40)
    info.BackgroundTransparency = 1
    info.TextWrapped = true
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.TextColor3 = Color3.fromRGB(200,200,200)
    info.Font = Enum.Font.SourceSans
    info.TextSize = 14
    info.Text = "Join the Discord server to get the daily key, and type /getkey. Press Join to copy the invite. Enter key below and press Submit."

    local keyBox = Instance.new("TextBox", frame)
    keyBox.Size = UDim2.new(1,-20,0,30)
    keyBox.Position = UDim2.new(0,10,0,92)
    keyBox.PlaceholderText = "Enter key here..."
    keyBox.Text = ""
    keyBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
    keyBox.TextColor3 = Color3.fromRGB(255,255,255)
    keyBox.Font = Enum.Font.SourceSans

    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1,-20,0,20)
    status.Position = UDim2.new(0,10,0,128)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(200,200,200)
    status.Font = Enum.Font.SourceSans
    status.TextSize = 14
    status.Text = "Status: waiting..."

    local submit = Instance.new("TextButton", frame)
    submit.Size = UDim2.new(0.48, -12, 0, 34)
    submit.Position = UDim2.new(0,10,0,152)
    submit.Text = "✅ Submit Key"
    submit.Font = Enum.Font.GothamBold
    submit.TextSize = 16
    submit.BackgroundColor3 = Color3.fromRGB(0,150,0)
    submit.TextColor3 = Color3.fromRGB(255,255,255)

    local join = Instance.new("TextButton", frame)
    join.Size = UDim2.new(0.48, -12, 0, 34)
    join.Position = UDim2.new(0.52, 2, 0, 152)
    join.Text = "📩 Join Discord"
    join.Font = Enum.Font.GothamBold
    join.TextSize = 16
    join.BackgroundColor3 = Color3.fromRGB(0,100,200)
    join.TextColor3 = Color3.fromRGB(255,255,255)

    local clearBtn = Instance.new("TextButton", frame)
    clearBtn.Size = UDim2.new(1,-20,0,28)
    clearBtn.Position = UDim2.new(0,10,0,190)
    clearBtn.Text = "Clear saved key"
    clearBtn.Font = Enum.Font.SourceSans
    clearBtn.TextSize = 14
    clearBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    clearBtn.TextColor3 = Color3.fromRGB(255,255,255)

    -- BUTTON LOGIC
    join.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(DISCORD_INVITE) end)
        StarterGui:SetCore("SendNotification", {
            Title = "Invite Copied",
            Text = "Discord invite copied to clipboard.",
            Duration = 4
        })
    end)

    submit.MouseButton1Click:Connect(function()
        local entered = tostring(keyBox.Text or "")
        if entered == "" then
            status.Text = "Status: please enter a key"
            return
        end
        status.Text = "Status: checking key..."
        local remoteKey = fetchRemoteKey()
        if not remoteKey then
            status.Text = "Status: failed to fetch remote key"
            return
        end
        if entered == remoteKey then
            saveKeyLocal(entered)
            status.Text = "Status: key valid — loading..."
            task.wait(0.4)
            ScreenGui:Destroy()
            loadMain()
        else
            status.Text = "Status: invalid key"
        end
    end)

    clearBtn.MouseButton1Click:Connect(function()
        clearLocalKey()
        StarterGui:SetCore("SendNotification", {
            Title = "Pentacyl",
            Text = "Saved key cleared.",
            Duration = 3
        })
    end)

    return ScreenGui, keyBox, status
end

-- ===== AUTO FLOW =====
local function main()
    local saved = loadKeyLocal()
    local remote = fetchRemoteKey()
    if saved and remote and saved == remote then
        -- saved key valid; load main script
        loadMain()
        return
    end

    -- build UI and let user submit
    local gui = buildUI()
    -- also update status if remote fetch failed
    if not fetchRemoteKey() then
        -- update status label in UI (if exists)
        for _,child in ipairs(gui:GetDescendants()) do
            if child:IsA("TextLabel") and child.Text:match("Status:") then
                child.Text = "Status: failed to fetch key (check URL)"
                break
            end
        end
    end
end

-- run
pcall(main)
