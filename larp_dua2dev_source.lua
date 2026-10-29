local LoginTimestamp = os.time()

pcall(function()
    local vu = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if (method == "Kick" or method == "kick") and self == game:GetService("Players").LocalPlayer then
            return nil
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end)

local msg = "make by tungtung son son"

task.spawn(function()
    pcall(function()
        local chatEvents = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 3)
        if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
            chatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end)
end)

task.spawn(function()
    pcall(function()
        local textChatService = game:GetService("TextChatService")
        if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local generalChannel = textChatService.TextChannels:WaitForChild("RBXGeneral", 3)
            if generalChannel then
                generalChannel:SendAsync(msg)
            end
        end
    end)
end)

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local playerGui = Player:WaitForChild("PlayerGui")
local getParentGui = (gethui or function() return CoreGui end)

local function PlaySoundEffect(soundId, volume)
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. tostring(soundId)
        sound.Volume = volume or 0.5
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
        task.delay(3, function() if sound and sound.Parent then sound:Destroy() end end)
    end)
end

local FastPrompt = {
    Enabled = false,
    Original = setmetatable({}, {__mode = "k"}),
    AddConn = nil,
    ShownConn = nil,
}
_G.FastPromptEnabled = false

local function MakePromptInstant(prompt)
    if not prompt:IsA("ProximityPrompt") then return end
    if FastPrompt.Original[prompt] == nil then
        FastPrompt.Original[prompt] = prompt.HoldDuration
    end
    if prompt.HoldDuration ~= 0 then prompt.HoldDuration = 0 end
end

local function SetFastPrompt(state)
    FastPrompt.Enabled = state and true or false
    _G.FastPromptEnabled = FastPrompt.Enabled

    if FastPrompt.AddConn then FastPrompt.AddConn:Disconnect() FastPrompt.AddConn = nil end
    if FastPrompt.ShownConn then FastPrompt.ShownConn:Disconnect() FastPrompt.ShownConn = nil end

    if FastPrompt.Enabled then

        FastPrompt.AddConn = workspace.DescendantAdded:Connect(function(d)
            if FastPrompt.Enabled and d:IsA("ProximityPrompt") then
                pcall(MakePromptInstant, d)
            end
        end)

        FastPrompt.ShownConn = ProximityPromptService.PromptShown:Connect(function(prompt)
            if FastPrompt.Enabled then pcall(MakePromptInstant, prompt) end
        end)

        task.spawn(function()
            local n = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if not FastPrompt.Enabled then return end
                if d:IsA("ProximityPrompt") then pcall(MakePromptInstant, d) end
                n += 1
                if n % 300 == 0 then task.wait() end
            end
        end)
    else

        for prompt, orig in pairs(FastPrompt.Original) do
            if prompt.Parent then pcall(function() prompt.HoldDuration = orig end) end
            FastPrompt.Original[prompt] = nil
        end
    end
end

pcall(function()
    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
        if not FastPrompt.Enabled then return end
        if FastPrompt.Original[prompt] ~= nil then return end
        pcall(function()
            MakePromptInstant(prompt)
            if fireproximityprompt then fireproximityprompt(prompt) end
        end)
    end)
end)

local function SendRobloxNotification(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Tungtung Hub",
            Text = text or "",
            Duration = duration or 3
        })
    end)
    PlaySoundEffect(4590662766, 0.4)
end

local function safeDestroy(name, parent)
    if parent then
        local g = parent:FindFirstChild(name)
        if g then g:Destroy() end
    end
end

safeDestroy("TUNGTUNG_hub_Core", getParentGui())
safeDestroy("AutoTypingOverlay", playerGui)
safeDestroy("Tungtung", playerGui)

local SaveFileName = "TungtungNgonNgu.json"

local function saveLang(tbl)
    pcall(function()
        if writefile then
            writefile(SaveFileName, HttpService:JSONEncode(tbl))
        end
    end)
end

local function loadLang()
    local data = {lang = "vn"}
    pcall(function()
        if readfile and isfile and isfile(SaveFileName) then
            local raw = readfile(SaveFileName)
            local ok, dec = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(dec) == "table" and dec.lang then
                data = dec
            end
        end
    end)
    return data
end

local savedData = loadLang()
_G.CurrentLang = _G.CurrentLang or (savedData.lang and savedData.lang:upper()) or "VN"
if _G.CurrentLang ~= "VN" and _G.CurrentLang ~= "EN" then _G.CurrentLang = "VN" end

local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "AutoTypingOverlay"
loadingGui.IgnoreGuiInset = true
loadingGui.ResetOnSpawn = false
loadingGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.Position = UDim2.new(0, 0, 0, 0)
bg.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
bg.BackgroundTransparency = 0
bg.BorderSizePixel = 0
bg.Parent = loadingGui

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -30, 1, -30)
textLabel.Position = UDim2.new(0, 15, 0, 15)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(255, 40, 50)
textLabel.Font = Enum.Font.Code
textLabel.TextSize = 13.5
textLabel.TextXAlignment = Enum.TextXAlignment.Left
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.TextWrapped = true
textLabel.Text = ""
textLabel.Parent = bg

local barCard = Instance.new("Frame")
barCard.AnchorPoint = Vector2.new(0.5, 0.5)
barCard.Size = UDim2.new(0, 320, 0, 65)
barCard.Position = UDim2.new(0.5, 0, 0.5, 0)
barCard.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
barCard.BackgroundTransparency = 1
barCard.BorderSizePixel = 0
barCard.Visible = false
barCard.Parent = bg

Instance.new("UICorner", barCard).CornerRadius = UDim.new(0, 10)

local barCardStroke = Instance.new("UIStroke", barCard)
barCardStroke.Thickness = 1.5
barCardStroke.Color = Color3.fromRGB(220, 30, 40)
barCardStroke.Transparency = 1

local barTitle = Instance.new("TextLabel", barCard)
barTitle.Size = UDim2.new(1, -20, 0, 20)
barTitle.Position = UDim2.new(0, 10, 0, 8)
barTitle.BackgroundTransparency = 1
barTitle.Font = Enum.Font.GothamBold
barTitle.TextSize = 12
barTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
barTitle.TextXAlignment = Enum.TextXAlignment.Left
barTitle.Text = "LOADING TUNGTUNG HUB..."
barTitle.TextTransparency = 1

local percentLabel = Instance.new("TextLabel", barCard)
percentLabel.Size = UDim2.new(1, -20, 0, 20)
percentLabel.Position = UDim2.new(0, 10, 0, 8)
percentLabel.BackgroundTransparency = 1
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextSize = 12
percentLabel.TextColor3 = Color3.fromRGB(255, 40, 50)
percentLabel.TextXAlignment = Enum.TextXAlignment.Right
percentLabel.Text = "0%"
percentLabel.TextTransparency = 1

local barTrack = Instance.new("Frame", barCard)
barTrack.Size = UDim2.new(1, -20, 0, 10)
barTrack.Position = UDim2.new(0, 10, 0, 38)
barTrack.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
barTrack.BorderSizePixel = 0
barTrack.BackgroundTransparency = 1
Instance.new("UICorner", barTrack).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame", barTrack)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 30, 40)
barFill.BorderSizePixel = 0
barFill.BackgroundTransparency = 1
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

local textContents = {
[[
[NETWORK] Connecting to data node...
[NETWORK] Node found: 192.168.4.12
[NETWORK] Sending handshake request...
[AUTH] Session key granted.
[DOWNLOAD] Retrieving user memory package...
[DOWNLOAD] Chunk 1/10 complete (6.2 MB)
[DOWNLOAD] Chunk 2/10 complete (12.4 MB)
[DOWNLOAD] Chunk 3/10 complete (18.7 MB)
[DOWNLOAD] Chunk 4/10 complete (24.9 MB)
[DOWNLOAD] Chunk 5/10 complete (31.1 MB)
[DOWNLOAD] Chunk 6/10 complete (46.5 MB)
[DOWNLOAD] Chunk 7/10 complete (48.2 MB)
[DOWNLOAD] Chunk 8/10 complete (56.1 MB)
[DOWNLOAD] Chunk 9/10 complete (62.6 MB)
[DOWNLOAD] Chunk 10/10 complete (87.6 MB)
[CHECKSUM] Validating... OK
[INFO] Data download complete.
[INFO] Transferring to volatile storage...
[INFO] Transfer finished. Ready for execution.
[Wait] Waiting area to run data...
[DATA] Loading data from player.
[DATA] Loading functions...
[SECURITY] Anti-Kick & Anti-AFK initialized.
]],

[[
[DOWNLOAD] :: ░░░░░░░░░░░░░░░░░░░    →   0%
[DOWNLOAD] :: █░░░░░░░░░░░░░░░░░░    →   1%
[DOWNLOAD] :: ██░░░░░░░░░░░░░░░░░    →   14%
[DOWNLOAD] :: ███░░░░░░░░░░░░░░░░    →   27%
[DOWNLOAD] :: ████░░░░░░░░░░░░░░░    →   41%
[DOWNLOAD] :: ██████░░░░░░░░░░░░░    →   56%
[DOWNLOAD] :: ████████░░░░░░░░░░░    →   63%
[DOWNLOAD] :: █████████░░░░░░░░░░    →   71%
[DOWNLOAD] :: ███████████░░░░░░░░    →   82%
[DOWNLOAD] :: ████████████░░░░░░░    →   88%
[DOWNLOAD] :: ████████████░░░░░░░    →   89%
[DOWNLOAD] :: ████████████░░░░░░░    →   92%
[DOWNLOAD] :: ████████████░░░░░░░    →   93%
[DOWNLOAD] :: ████████████░░░░░░░    →   94%
[DOWNLOAD] :: ██████████████░░░░░    →   95%
[DOWNLOAD] :: ████████████████░░░    →   96%
[DOWNLOAD] :: █████████████████░░    →   97%
[DOWNLOAD] :: ██████████████████░    →   98%
[DOWNLOAD] :: ███████████████████    →   100%
]],

[[
[LOADING]: 0101001010010101011010101010010111100101010100101010010101011010101
101010100101010010011010101010010111100101010100101010010101011010101
10101010010101001010101101010101001011110010101010010101001010101
101010100101010010101011010101010111100101010100101010010101011010101
101010100101010010101011010101010010111100101010100101010010101011010101
101010100101010010101011010101010011100101010100101010010101011010101
10101010010101011010101010010111100101010100101010010101011010101
1010101001010100101010110101010100101111010100101010010101011010101
0010111011010001011001101011110111010011001011010110101011101101101101
01010100101010101001101010101010011011011010010001011011010110
0011001001010101010101001110101010101110101101010101101010
0101001010010101011010101010010111100101010100101010010101011010101
101010100101010010011010101010010111100101010100101010010101011010101
10101010010101001010101101010101001011110010101010010101001010101
1010101001010100101010110101010101111
]],

[[
Tungtung/lua Script Gui
[STATUS] Injection completed successfully!
[EXECUTE] Launching Tungtung Hub V2.0...
]]
}

local function ShowToast(msg, duration)
    task.spawn(function()
        pcall(function()
            local gui = getParentGui():FindFirstChild("TUNGTUNG_hub_Core")
            if not gui then return end
            local old = gui:FindFirstChild("Tungtung_Toast")
            if old then old:Destroy() end

            local toast = Instance.new("TextLabel")
            toast.Name = "Tungtung_Toast"
            toast.AnchorPoint = Vector2.new(0.5, 0)
            toast.Size = UDim2.new(0, 260, 0, 34)
            toast.Position = UDim2.new(0.5, 0, 0, -50)
            toast.BackgroundColor3 = Color3.fromRGB(12, 3, 5)
            toast.TextColor3 = Color3.fromRGB(255, 255, 255)
            toast.Font = Enum.Font.GothamBold
            toast.TextSize = 12
            toast.TextWrapped = true
            toast.Text = msg
            toast.ZIndex = 100
            toast.Parent = gui
            Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)
            local st = Instance.new("UIStroke", toast)
            st.Thickness = 1.5
            st.Color = Color3.fromRGB(0, 255, 100)

            toast:TweenPosition(UDim2.new(0.5, 0, 0, 12), "Out", "Quad", 0.25, true)
            task.wait(duration or 2)
            if toast.Parent then
                toast:TweenPosition(UDim2.new(0.5, 0, 0, -50), "In", "Quad", 0.25, true)
                task.wait(0.3)
                toast:Destroy()
            end
        end)
    end)
end

local OriginalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    GlobalShadows = Lighting.GlobalShadows
}

local ScreenGui = Instance.new("ScreenGui", getParentGui())
ScreenGui.Name = "TUNGTUNG_hub_Core"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local LangPack = {
    VN = {
        Title = "Tungtung Hub V2.0", SubTitle = "SCRIPT TUNGTUNG HUB",
        Tag1 = "Trang chủ", Tag2 = "Bầu trời", Tag3 = "Hiệu ứng FE", Tag4 = "Giải trí", Tag5 = "Người chơi", Tag6 = "NPC", Tag7 = "Máy chủ", Tag8 = "Công cụ", Tag9 = "Giao diện", Tag10 = "Thế giới", Tag11 = "Ngôn ngữ", Tag12 = "Thông tin", Tag13 = "Khác",
        HeaderSidebar = "Mục Lục", HeaderContent = "Danh sách script", SearchPlaceholder = "Tìm Script...",

        BtnRejoin = "Tham gia lại máy chủ", BtnServerHop = "Chuyển máy chủ", BtnLowServer = "Tìm máy chủ ít người", BtnVipServer = "Máy chủ VIP (1 người)",

        BtnGodMode = "Chế độ thần thánh", BtnInvis = "Vô hình", BtnInvisLoading = "ĐANG TẢI...", BtnNoFog = "Xóa sương mù (Client)", BtnFullbright = "Nhìn trong bóng tối (Client)", BtnNoclip = "Xuyên tường", BtnFly = "Bay", BtnSpeed = "Tốc độ", BtnInfJump = "Nhảy vô hạn", PlaceholderJump = " Nhập lực nhảy...", BtnAirStand = "Đứng trên không", BtnCamUnlock = "Bẻ khóa camera", BtnHumanoidState = "Trạng thái Humanoid", BtnFlash = "The Flash",
        BtnAnimSpeed = "Animation siêu tốc", BtnFling = "Đá bay",
        BtnEntAnim = "Animation siêu tốc", BtnEntFling = "Đá bay", BtnFakeLag = "Trễ giả",
        BtnHitbox = "Hitbox người chơi", BtnInfYield = "Vô hạn", BtnTeleport = "Dịch chuyển đến người", BtnSpectate = "Theo dõi người chơi", BtnBringPlayers = "Gom người chơi (Client)", BtnPlayerEsp = "Định vị người chơi (Client)",
        BtnKillPlayer = "tiêu diệt người chơi (Đá Bay)",
        BtnNpcEsp = "Định vị NPC (Client)", BtnBringNpcs = "Gom tất cả NPC (Client)", BtnPrompt = "Tương tác nhanh",
        BtnGetTpTool = "Dụng cụ TP", BtnDupeTool = "Nhân đôi dụng cụ (Client)", BtnDropTools = "thả cộng cụ",
        BtnXray = "X-ray (Client)", BtnDisco = "Disco + Tacos Music (Client)", BtnRespawn = "Hồi sinh tại chỗ chết", BtnWorldScan = "quan xác thế giới",

        ProfDisplay = "Tên hiển thị", ProfUser = "Tên tài khoản", ProfUserId = "ID Roblox", ProfPlaceId = "ID game", ProfMap = "Bản đồ", ProfLogin = "Đăng nhập lúc", ProfLoading = "Đang tải...", ProfCopied = "Đã sao chép: ", ProfRobux = "Số Robux", ProfCreated = "Ngày tạo tài khoản", ProfNA = "Không đọc được",

        NotifEnabled = "Đã bật: ", NotifDisabled = "Đã tắt: ", NotifThemeSet = "Giao diện: ", NotifJumpPowerSet = "Lực nhảy đã đổi thành: ", NotifLangChanged = "Ngôn ngữ đã đổi sang: Tiếng Việt",

        ColorRainbow = "Cầu vồng mượt", ColorRainbowFast = "Cầu vồng siêu tốc", ColorRainbowFlash = "Cầu vồng nhấp nháy",
        ColorRainbowPastel = "Cầu vồng Pastel", ColorRainbowNeon = "Cầu vồng Neon sáng", ColorRainbowDark = "Cầu vồng huyền bí",
        ColorRainbowIce = "Cầu vồng Băng lạnh", ColorRainbowFire = "Cầu vồng Lửa ấm",

        ColorGreen = "Xanh lá", ColorGreenV2 = "Xanh lá v2", ColorGreenV3 = "Xanh lá v3", ColorMint = "Xanh Mint", ColorLime = "Xanh lá chuối", ColorEmerald = "Xanh ngọc bảo",
        ColorRed = "Đỏ tươi", ColorRedV2 = "Đỏ v2", ColorRedV3 = "Đỏ v3", ColorDarkRed = "Đỏ thẫm", ColorCrimson = "Đỏ huyết dụ",
        ColorBlue = "Xanh dương", ColorBlueV2 = "Xanh dương v2", ColorCyan = "Xanh ngọc (Cyan)", ColorIceBlue = "Xanh băng", ColorSkyBlue = "Xanh bầu trời", ColorNavy = "Xanh hải quân",
        ColorPurple = "Tím", ColorPurpleV2 = "Tím v2", ColorMagenta = "Tím hồng (Magenta)", ColorLavender = "Tím hoa oải hương", ColorViolet = "Tím đậm",
        ColorYellow = "Vàng", ColorLemon = "Vàng chanh", ColorOrange = "Cam", ColorDarkOrange = "Cam cháy", ColorGold = "Vàng hoàng gia",
        ColorPink = "Hồng", ColorHotPink = "Hồng đậm", ColorRose = "Hồng hoa hồng",
        ColorBrown = "Nâu gỗ", ColorGray = "Xám kim loại", ColorWhite = "Trắng tinh", ColorBlack = "Đen tuyền"
    },
    EN = {
        Title = "Tungtung Hub V2.0", SubTitle = "SCRIPT TUNGTUNG HUB",
        Tag1 = "Home", Tag2 = "Sky", Tag3 = "FE Effects", Tag4 = "Entertainment", Tag5 = "Player", Tag6 = "NPC", Tag7 = "Server", Tag8 = "Tool", Tag9 = "UI Themes", Tag10 = "World", Tag11 = "Language", Tag12 = "Profile", Tag13 = "Other",
        HeaderSidebar = "Menu", HeaderContent = "Script List", SearchPlaceholder = "Search script...",

        BtnRejoin = "Rejoin Server", BtnServerHop = "Server Hop", BtnLowServer = "Low Player Server", BtnVipServer = "VIP Server (1 Player)",

        BtnGodMode = "God Mode", BtnInvis = "Invisible", BtnInvisLoading = "LOADING...", BtnNoFog = "No Fog (Client)", BtnFullbright = "Fullbright (Client)", BtnNoclip = "Noclip", BtnFly = "Fly", BtnSpeed = "Speed", BtnInfJump = "Infinite Jump", PlaceholderJump = " Enter jump power...", BtnAirStand = "Air Stand", BtnCamUnlock = "Camera Unlock", BtnHumanoidState = "Humanoid State", BtnFlash = "The Flash",
        BtnAnimSpeed = "Fast Animation", BtnFling = "Fling",
        BtnEntAnim = "Fast Animation", BtnEntFling = "Fling", BtnFakeLag = "Fake Lag",
        BtnHitbox = "Player Hitbox", BtnInfYield = "Infinite Yield", BtnTeleport = "Teleport Tool", BtnSpectate = "Spectate Player", BtnBringPlayers = "Bring Players (Client)", BtnPlayerEsp = "Player ESP (Client)",
        BtnKillPlayer = "kill player (fling)",
        BtnNpcEsp = "NPC ESP (Client)", BtnBringNpcs = "Bring All NPCs (Client)", BtnPrompt = "Fast Interact",
        BtnGetTpTool = "Get TP Tool", BtnDupeTool = "Dupe Tool (Client)", BtnDropTools = "Drop tools",
        BtnXray = "X-ray (Client)", BtnDisco = "Disco + Tacos Music (Client)", BtnRespawn = "Respawn At Death Spot", BtnWorldScan = "World Scan",

        ProfDisplay = "Display name", ProfUser = "Username", ProfUserId = "Roblox ID", ProfPlaceId = "Game ID", ProfMap = "Map", ProfLogin = "Logged in at", ProfLoading = "Loading...", ProfCopied = "Copied: ", ProfRobux = "Robux", ProfCreated = "Account created", ProfNA = "Unavailable",

        NotifEnabled = "Enabled: ", NotifDisabled = "Disabled: ", NotifThemeSet = "Theme: ", NotifJumpPowerSet = "Jump power set to: ", NotifLangChanged = "Language changed to: English",

        ColorRainbow = "Smooth Rainbow", ColorRainbowFast = "Fast Rainbow", ColorRainbowFlash = "Flash Rainbow",
        ColorRainbowPastel = "Pastel Rainbow", ColorRainbowNeon = "Bright Neon Rainbow", ColorRainbowDark = "Dark Rainbow",
        ColorRainbowIce = "Ice Cold Rainbow", ColorRainbowFire = "Warm Fire Rainbow",

        ColorGreen = "Green", ColorGreenV2 = "Green v2", ColorGreenV3 = "Green v3", ColorMint = "Mint Green", ColorLime = "Lime Green", ColorEmerald = "Emerald Green",
        ColorRed = "Bright Red", ColorRedV2 = "Red v2", ColorRedV3 = "Red v3", ColorDarkRed = "Dark Red", ColorCrimson = "Crimson Red",
        ColorBlue = "Blue", ColorBlueV2 = "Blue v2", ColorCyan = "Cyan", ColorIceBlue = "Ice Blue", ColorSkyBlue = "Sky Blue", ColorNavy = "Navy Blue",
        ColorPurple = "Purple", ColorPurpleV2 = "Purple v2", ColorMagenta = "Magenta", ColorLavender = "Lavender", ColorViolet = "Dark Violet",
        ColorYellow = "Yellow", ColorLemon = "Lemon Yellow", ColorOrange = "Orange", ColorDarkOrange = "Dark Orange", ColorGold = "Royal Gold",
        ColorPink = "Pink", ColorHotPink = "Hot Pink", ColorRose = "Rose Pink",
        ColorBrown = "Brown", ColorGray = "Metallic Gray", ColorWhite = "Pure White", ColorBlack = "Dark Black"
    }
}

local TAB_COUNT = 13

_G.ThemeMode = _G.ThemeMode or "Static"
_G.StaticColor = _G.StaticColor or Color3.fromRGB(200, 15, 25)
_G.SkyMode = "Normal"
_G.SkyStaticColor = nil
_G.SkyKey = nil
_G.SkyToken = _G.SkyToken or 0

local DiscoActive = false
local DiscoThread = nil

local RainbowModes = {
    Rainbow      = {0.005, function(h) return Color3.fromHSV(h, 0.9, 1) end},
    RainbowFast  = {0.025, function(h) return Color3.fromHSV(h, 1, 1) end},
    RainbowFlash = {0.1,   function(h) return Color3.fromHSV(h, 1, 1) end},
    RainbowPastel= {0.004, function(h) return Color3.fromHSV(h, 0.45, 1) end},
    RainbowNeon  = {0.008, function(h) return Color3.fromHSV(h, 1, 1) end},
    RainbowDark  = {0.005, function(h) return Color3.fromHSV(h, 0.9, 0.4) end},
    RainbowIce   = {0.006, function(h) return Color3.fromHSV(0.45 + (h * 0.3), 0.85, 1) end},
    RainbowFire  = {0.006, function(h) return Color3.fromHSV(h * 0.16, 1, 1) end},
}

local RegistryUIStrokes = {}
local RegistryThemeDots = {}
local DotGlow = setmetatable({}, {__mode = "k"})

local function ApplyThemeBorder(object, thickness)
    local stroke = Instance.new("UIStroke", object)
    stroke.Thickness = thickness or 1.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    table.insert(RegistryUIStrokes, stroke)
    return stroke
end

local function RegisterDot(dot, glow)
    if glow then DotGlow[dot] = glow end
    table.insert(RegistryThemeDots, dot)
end

do
    local hue = 0
    RunService.Heartbeat:Connect(function(dt)
        local currentColor = _G.StaticColor
        local cfg = RainbowModes[_G.ThemeMode]
        if cfg then
            hue = (hue + cfg[1] * dt * 60) % 1
            currentColor = cfg[2](hue)
        end

        for i = #RegistryUIStrokes, 1, -1 do
            local stroke = RegistryUIStrokes[i]
            if stroke and stroke.Parent then stroke.Color = currentColor else table.remove(RegistryUIStrokes, i) end
        end

        for i = #RegistryThemeDots, 1, -1 do
            local dot = RegistryThemeDots[i]
            if dot and dot.Parent then
                local c = currentColor
                if dot:GetAttribute("IsActiveToggle") == true then
                    c = Color3.fromRGB(0, 255, 100)
                end
                dot.BackgroundColor3 = c

                local glow = DotGlow[dot]
                if glow then glow.Color = c end
            else
                table.remove(RegistryThemeDots, i)
            end
        end
    end)
end

do
    local skyHue = 0
    RunService.Heartbeat:Connect(function(dt)
        local cfg = RainbowModes[_G.SkyMode]
        if not cfg or DiscoActive then return end
        skyHue = (skyHue + cfg[1] * dt * 60) % 1
        local c = cfg[2](skyHue)
        Lighting.OutdoorAmbient = c
        Lighting.Ambient = c
        Lighting.FogColor = c
    end)
end

local MENU_W, MENU_H = 490, 310

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, MENU_W, 0, MENU_H)
MainFrame.Position = UDim2.new(0.5, -MENU_W / 2, 0.5, -MENU_H / 2)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BackgroundTransparency = 0.02
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 18)
ApplyThemeBorder(MainFrame, 1.8)

do
    local grad = Instance.new("UIGradient", MainFrame)
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 4, 7)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 1, 2)),
    })
end

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, -16, 0, 48)
TopBar.Position = UDim2.new(0, 8, 0, 8)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 3, 6)
TopBar.BackgroundTransparency = 0.25
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)
ApplyThemeBorder(TopBar, 1.2)

local AvatarImage = Instance.new("ImageLabel", TopBar)
AvatarImage.Size = UDim2.new(0, 34, 0, 34)
AvatarImage.Position = UDim2.new(0, 10, 0, 7)
AvatarImage.BackgroundColor3 = Color3.fromRGB(15, 4, 6)
AvatarImage.BorderSizePixel = 0
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)
do
    local ring = Instance.new("UIStroke", AvatarImage)
    ring.Thickness = 1.6
    ring.Color = Color3.fromRGB(235, 200, 205)
    ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local UserAvatarAssetId = ""
task.spawn(function()
    pcall(function()
        UserAvatarAssetId = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        AvatarImage.Image = UserAvatarAssetId
    end)
end)

local TitleMenu = Instance.new("TextLabel", TopBar)
TitleMenu.Size = UDim2.new(0, 175, 0, 20)
TitleMenu.Position = UDim2.new(0, 52, 0, 5)
TitleMenu.BackgroundTransparency = 1
TitleMenu.Font = Enum.Font.GothamBold
TitleMenu.TextSize = 15
TitleMenu.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleMenu.TextXAlignment = Enum.TextXAlignment.Left

local TitleGradient = Instance.new("UIGradient", TitleMenu)
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(150, 0, 12)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 45, 55)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(255, 190, 195)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 45, 55)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(150, 0, 12)),
})
RunService.Heartbeat:Connect(function(dt)
    if TitleGradient.Parent then
        TitleGradient.Rotation = (TitleGradient.Rotation + 45 * dt) % 360
    end
end)

local SubTitleMenu = Instance.new("TextLabel", TopBar)
SubTitleMenu.Size = UDim2.new(0, 175, 0, 12)
SubTitleMenu.Position = UDim2.new(0, 52, 0, 27)
SubTitleMenu.BackgroundTransparency = 1
SubTitleMenu.Font = Enum.Font.GothamBold
SubTitleMenu.TextSize = 8.5
SubTitleMenu.TextColor3 = Color3.fromRGB(150, 70, 78)
SubTitleMenu.TextXAlignment = Enum.TextXAlignment.Left

local SearchFrame = Instance.new("Frame", TopBar)
SearchFrame.Size = UDim2.new(0, 130, 0, 28)
SearchFrame.Position = UDim2.new(1, -178, 0, 10)
SearchFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
SearchFrame.BorderSizePixel = 0
Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0, 10)
ApplyThemeBorder(SearchFrame, 1.2)

local SearchBox = Instance.new("TextBox", SearchFrame)
SearchBox.Size = UDim2.new(1, -16, 1, 0)
SearchBox.Position = UDim2.new(0, 10, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Font = Enum.Font.GothamBold
SearchBox.TextSize = 10.5
SearchBox.TextColor3 = Color3.fromRGB(235, 235, 235)
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.PlaceholderText = "Tìm Script..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(105, 105, 112)
SearchBox.Text = ""
SearchBox.ClearTextOnFocus = false

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -40, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(26, 4, 8)
CloseBtn.BackgroundTransparency = 0.2
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(255, 105, 125)
CloseBtn.Text = "✕"
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)
ApplyThemeBorder(CloseBtn, 1.2)

local SidebarFrame = Instance.new("Frame", MainFrame)
SidebarFrame.Size = UDim2.new(0, 128, 1, -72)
SidebarFrame.Position = UDim2.new(0, 8, 0, 64)
SidebarFrame.BackgroundColor3 = Color3.fromRGB(20, 3, 5)
SidebarFrame.BackgroundTransparency = 0.3
SidebarFrame.BorderSizePixel = 0
Instance.new("UICorner", SidebarFrame).CornerRadius = UDim.new(0, 14)
ApplyThemeBorder(SidebarFrame, 1.2)

local SidebarHeader = Instance.new("TextLabel", SidebarFrame)
SidebarHeader.Size = UDim2.new(1, -20, 0, 22)
SidebarHeader.Position = UDim2.new(0, 12, 0, 6)
SidebarHeader.BackgroundTransparency = 1
SidebarHeader.Font = Enum.Font.GothamBold
SidebarHeader.TextSize = 10.5
SidebarHeader.TextColor3 = Color3.fromRGB(235, 225, 225)
SidebarHeader.TextXAlignment = Enum.TextXAlignment.Left

local SidebarLine = Instance.new("Frame", SidebarFrame)
SidebarLine.Size = UDim2.new(1, -20, 0, 1)
SidebarLine.Position = UDim2.new(0, 10, 0, 30)
SidebarLine.BackgroundColor3 = Color3.fromRGB(110, 25, 32)
SidebarLine.BackgroundTransparency = 0.4
SidebarLine.BorderSizePixel = 0

local Sidebar = Instance.new("ScrollingFrame", SidebarFrame)
Sidebar.Size = UDim2.new(1, -8, 1, -40)
Sidebar.Position = UDim2.new(0, 4, 0, 36)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 0
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding = UDim.new(0, 6)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -152, 1, -72)
ContentFrame.Position = UDim2.new(0, 144, 0, 64)
ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 3, 5)
ContentFrame.BackgroundTransparency = 0.3
ContentFrame.BorderSizePixel = 0
Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 14)
ApplyThemeBorder(ContentFrame, 1.2)

local ContentHeader = Instance.new("TextLabel", ContentFrame)
ContentHeader.Size = UDim2.new(1, -24, 0, 22)
ContentHeader.Position = UDim2.new(0, 14, 0, 6)
ContentHeader.BackgroundTransparency = 1
ContentHeader.Font = Enum.Font.GothamBold
ContentHeader.TextSize = 10.5
ContentHeader.TextColor3 = Color3.fromRGB(235, 225, 225)
ContentHeader.TextXAlignment = Enum.TextXAlignment.Left

local ContentLine = Instance.new("Frame", ContentFrame)
ContentLine.Size = UDim2.new(1, -24, 0, 1)
ContentLine.Position = UDim2.new(0, 12, 0, 30)
ContentLine.BackgroundColor3 = Color3.fromRGB(110, 25, 32)
ContentLine.BackgroundTransparency = 0.4
ContentLine.BorderSizePixel = 0

local ScrollList = Instance.new("ScrollingFrame", ContentFrame)
ScrollList.Size = UDim2.new(1, -12, 1, -38)
ScrollList.Position = UDim2.new(0, 6, 0, 34)
ScrollList.BackgroundTransparency = 1
ScrollList.BorderSizePixel = 0
ScrollList.ScrollBarThickness = 2
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(150, 25, 35)
ScrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)

do
    local pad = Instance.new("UIPadding", ScrollList)
    pad.PaddingTop = UDim.new(0, 3)
    pad.PaddingLeft = UDim.new(0, 3)
    pad.PaddingRight = UDim.new(0, 5)
    pad.PaddingBottom = UDim.new(0, 6)
end

local GridSetup = Instance.new("UIListLayout", ScrollList)
GridSetup.FillDirection = Enum.FillDirection.Horizontal
GridSetup.Wraps = true
GridSetup.SortOrder = Enum.SortOrder.LayoutOrder
GridSetup.HorizontalAlignment = Enum.HorizontalAlignment.Left
GridSetup.VerticalAlignment = Enum.VerticalAlignment.Top
GridSetup.Padding = UDim.new(0, 7)

local TOGGLE_SIZE = 54
local ToggleBtn = Instance.new("ImageButton", ScreenGui)
ToggleBtn.Name = "Tungtung_ToggleBtn"
ToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
ToggleBtn.Size = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE)
ToggleBtn.Position = UDim2.new(0, 16 + TOGGLE_SIZE / 2, 0.5, 0)
ToggleBtn.Image = "rbxthumb://type=Asset&id=126708738665606&w=420&h=420"
ToggleBtn.ScaleType = Enum.ScaleType.Crop
ToggleBtn.AutoButtonColor = false
ToggleBtn.BackgroundColor3 = Color3.fromRGB(10, 3, 5)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Visible = false
ToggleBtn.Draggable = true
ToggleBtn.Active = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 12)

do
    local bezel = Instance.new("UIStroke", ToggleBtn)
    bezel.Name = "Bezel"
    bezel.Thickness = 4
    bezel.Color = Color3.fromRGB(62, 54, 56)
    bezel.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

do
    local inner = Instance.new("Frame", ToggleBtn)
    inner.Name = "InnerRing"
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.BackgroundTransparency = 1
    inner.BorderSizePixel = 0
    inner.Active = false
    Instance.new("UICorner", inner).CornerRadius = UDim.new(0, 12)
    local st = ApplyThemeBorder(inner, 1.5)
    st.Transparency = 0.05
end

local STREAK_SPEED = 120
local function MakeStaticStreak(stroke, baseAlpha, peakAlpha)
    local g = Instance.new("UIGradient", stroke)
    g.Rotation = 45
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,    baseAlpha),
        NumberSequenceKeypoint.new(0.3,  baseAlpha),
        NumberSequenceKeypoint.new(0.45, peakAlpha),
        NumberSequenceKeypoint.new(0.55, peakAlpha),
        NumberSequenceKeypoint.new(0.7,  baseAlpha),
        NumberSequenceKeypoint.new(1,    baseAlpha),
    })
    RunService.Heartbeat:Connect(function(dt)
        if g.Parent then
            g.Rotation = (g.Rotation + STREAK_SPEED * dt) % 360
        end
    end)
    return g
end

do

    local ring = Instance.new("Frame", ToggleBtn)
    ring.Name = "GlowRing"
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring.Size = UDim2.new(1, 8, 1, 8)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Active = false
    Instance.new("UICorner", ring).CornerRadius = UDim.new(0, 16)
    local thin = ApplyThemeBorder(ring, 2.5)
    MakeStaticStreak(thin, 0.72, 0.1)

    local halo = Instance.new("Frame", ToggleBtn)
    halo.Name = "GlowHalo"
    halo.AnchorPoint = Vector2.new(0.5, 0.5)
    halo.Position = UDim2.new(0.5, 0, 0.5, 0)
    halo.Size = UDim2.new(1, 8, 1, 8)
    halo.BackgroundTransparency = 1
    halo.BorderSizePixel = 0
    halo.Active = false
    Instance.new("UICorner", halo).CornerRadius = UDim.new(0, 16)
    local soft = ApplyThemeBorder(halo, 8)
    MakeStaticStreak(soft, 0.95, 0.55)
end

do
    local downInfo = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local popInfo = TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local small = UDim2.new(0, TOGGLE_SIZE * 0.78, 0, TOGGLE_SIZE * 0.78)
    local normal = UDim2.new(0, TOGGLE_SIZE, 0, TOGGLE_SIZE)
    local pressed = false
    ToggleBtn.MouseButton1Down:Connect(function()
        pressed = true
        TweenService:Create(ToggleBtn, downInfo, {Size = small}):Play()
    end)
    local function pop()
        if not pressed then return end
        pressed = false
        TweenService:Create(ToggleBtn, popInfo, {Size = normal}):Play()
    end
    ToggleBtn.MouseButton1Up:Connect(pop)
    ToggleBtn.MouseLeave:Connect(pop)
    ToggleBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pop()
        end
    end)
end

local isOpen = false
local menuBusy = false
local function ToggleMenu()
    if menuBusy then return end
    menuBusy = true
    PlaySoundEffect(6026987522, 0.4)
    if isOpen then
        MainFrame:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Quart", 0.25, true)
        task.wait(0.25)
        MainFrame.Visible = false
    else
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame:TweenSize(UDim2.new(0, MENU_W, 0, MENU_H), "Out", "Back", 0.3, true)
        task.wait(0.3)
    end
    isOpen = not isOpen
    menuBusy = false
end

ToggleBtn.MouseButton1Click:Connect(ToggleMenu)
CloseBtn.MouseButton1Click:Connect(ToggleMenu)

do
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            local screen = ScreenGui.AbsoluteSize
            local ax = startPos.X.Scale * screen.X + startPos.X.Offset + d.X
            local ay = startPos.Y.Scale * screen.Y + startPos.Y.Offset + d.Y
            ax = math.clamp(ax, -MENU_W + 80, screen.X - 80)
            ay = math.clamp(ay, 0, screen.Y - 60)
            MainFrame.Position = UDim2.new(0, ax, 0, ay)
        end
    end)
end

local CreatedTabs = {}
local CurrentActiveTag = 1

local function CreateTag(id)
    local t = Instance.new("TextButton", Sidebar)
    t.Size = UDim2.new(1, -6, 0, 36)
    t.LayoutOrder = id
    t.BackgroundColor3 = Color3.fromRGB(6, 2, 3)
    t.BackgroundTransparency = 0.3
    t.BorderSizePixel = 0
    t.AutoButtonColor = false
    t.TextColor3 = Color3.fromRGB(215, 205, 205)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 11
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextTruncate = Enum.TextTruncate.AtEnd
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 12)

    local pad = Instance.new("UIPadding", t)
    pad.PaddingLeft = UDim.new(0, 26)
    pad.PaddingRight = UDim.new(0, 6)

    local st = Instance.new("UIStroke", t)
    st.Name = "TabStroke"
    st.Thickness = 1
    st.Color = Color3.fromRGB(95, 75, 78)
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Transparency = 1

    local bar = Instance.new("Frame", t)
    bar.Name = "Bar"
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.Size = UDim2.new(0, 4, 0, 20)
    bar.Position = UDim2.new(0, -16, 0.5, 0)
    bar.BackgroundColor3 = Color3.fromRGB(230, 20, 30)
    bar.BorderSizePixel = 0
    bar.Visible = false
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    RegisterDot(bar)

    CreatedTabs[id] = t
    return t
end

for i = 1, TAB_COUNT do CreateTag(i) end

local function ClearScroll()
    for _, v in pairs(ScrollList:GetChildren()) do
        if v:IsA("Frame") or v:IsA("TextButton") or v:IsA("TextBox") then v:Destroy() end
    end
end

local BTN_BG = Color3.fromRGB(6, 2, 3)
local BTN_BG_PRESS = Color3.fromRGB(48, 7, 12)

local function AddBtn(text, func, isToggle, initialState)
    local btnFrame = Instance.new("Frame", ScrollList)
    btnFrame.AutomaticSize = Enum.AutomaticSize.X
    btnFrame.Size = UDim2.new(0, 0, 0, 34)
    btnFrame.BackgroundColor3 = BTN_BG
    btnFrame.BackgroundTransparency = 0.05
    btnFrame.BorderSizePixel = 0
    Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(1, 0)
    local limit = Instance.new("UISizeConstraint", btnFrame)
    limit.MaxSize = Vector2.new(300, 34)
    ApplyThemeBorder(btnFrame, 1.2)

    local dot = Instance.new("Frame", btnFrame)
    dot.Size = UDim2.new(0, 9, 0, 9)
    dot.Position = UDim2.new(0, 13, 0.5, -4.5)
    dot.BackgroundColor3 = Color3.fromRGB(230, 20, 30)
    dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local glow = Instance.new("UIStroke", dot)
    glow.Name = "Glow"
    glow.Thickness = 3
    glow.Transparency = 0.65
    glow.Color = Color3.fromRGB(230, 20, 30)
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    if isToggle then dot:SetAttribute("IsActiveToggle", initialState or false) end
    RegisterDot(dot, glow)

    local btn = Instance.new("TextButton", btnFrame)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.Position = UDim2.new(0, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(235, 232, 232)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    local btnPad = Instance.new("UIPadding", btn)
    btnPad.PaddingLeft = UDim.new(0, 31)
    btnPad.PaddingRight = UDim.new(0, 17)

    local pressInfo = TweenInfo.new(0.12)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btnFrame, pressInfo, {BackgroundColor3 = BTN_BG_PRESS}):Play()
    end)
    local function release()
        TweenService:Create(btnFrame, pressInfo, {BackgroundColor3 = BTN_BG}):Play()
    end
    btn.MouseButton1Up:Connect(release)
    btn.MouseLeave:Connect(release)

    local currentState = initialState or false
    btn.MouseButton1Click:Connect(function()
        PlaySoundEffect(6026987522, 0.3)
        if isToggle then
            currentState = not currentState
            dot:SetAttribute("IsActiveToggle", currentState)
            local txt = LangPack[_G.CurrentLang]
            local stateStr = currentState and (txt.NotifEnabled .. text) or (txt.NotifDisabled .. text)
            SendRobloxNotification("Tungtung Hub", stateStr, 2)
            func(currentState, btn, dot)
        else
            func(btn, dot)
        end
    end)
    return btnFrame, dot
end

local function HighlightTab(activeId)
    for id, tabBtn in pairs(CreatedTabs) do
        local bar = tabBtn:FindFirstChild("Bar")
        local st = tabBtn:FindFirstChild("TabStroke")
        if id == activeId then
            tabBtn.BackgroundTransparency = 0.05
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            if bar then bar.Visible = true end
            if st then st.Transparency = 0.2 end
        else
            tabBtn.BackgroundTransparency = 0.3
            tabBtn.TextColor3 = Color3.fromRGB(215, 205, 205)
            if bar then bar.Visible = false end
            if st then st.Transparency = 1 end
        end
    end
end

local Noclip = {
    Enabled = false,
    Parts = setmetatable({}, {__mode = "k"}),
    StepConn = nil,
    CharConn = nil,
    AddConn = nil,
}

local function NoclipRegister(part)
    if part:IsA("BasePart") and Noclip.Parts[part] == nil then
        Noclip.Parts[part] = part.CanCollide
    end
end

local function NoclipBind(char)
    if Noclip.AddConn then Noclip.AddConn:Disconnect() Noclip.AddConn = nil end
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do NoclipRegister(d) end
    Noclip.AddConn = char.DescendantAdded:Connect(function(d)
        if Noclip.Enabled then NoclipRegister(d) end
    end)
end

local function NoclipRestore()
    for part, orig in pairs(Noclip.Parts) do
        if part.Parent then pcall(function() part.CanCollide = orig end) end
        Noclip.Parts[part] = nil
    end
end

local function SetNoclip(state)
    Noclip.Enabled = state and true or false
    _G.NoclipStatus = Noclip.Enabled

    if Noclip.Enabled then
        NoclipBind(Player.Character)
        if not Noclip.StepConn then
            Noclip.StepConn = RunService.Stepped:Connect(function()
                for part in pairs(Noclip.Parts) do
                    if part.Parent and part.CanCollide then part.CanCollide = false end
                end
            end)
        end
        if not Noclip.CharConn then
            Noclip.CharConn = Player.CharacterAdded:Connect(function(char)
                table.clear(Noclip.Parts)
                NoclipBind(char)
            end)
        end
    else
        if Noclip.StepConn then Noclip.StepConn:Disconnect() Noclip.StepConn = nil end
        if Noclip.CharConn then Noclip.CharConn:Disconnect() Noclip.CharConn = nil end
        if Noclip.AddConn then Noclip.AddConn:Disconnect() Noclip.AddConn = nil end
        NoclipRestore()
    end
end

local FLING_POWER = 25000
local Fling = {
    Sources = {},
    Running = false,
    HbConn = nil,
    RsConn = nil,
    SavedVel = Vector3.zero,
    Applied = false,
    Hum = nil,
}

local function FlingSetStates(hum, enabled)
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, enabled)
    end)
end

local function FlingStop()
    if not Fling.Running then return end
    Fling.Running = false
    if Fling.HbConn then Fling.HbConn:Disconnect() Fling.HbConn = nil end
    if Fling.RsConn then Fling.RsConn:Disconnect() Fling.RsConn = nil end

    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            local v = Fling.Applied and Fling.SavedVel or hrp.AssemblyLinearVelocity
            if v.Magnitude > 500 then v = Vector3.zero end
            hrp.AssemblyLinearVelocity = v
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    Fling.Applied = false
    FlingSetStates(Fling.Hum, true)
    Fling.Hum = nil
end

local function FlingStart()
    if Fling.Running then return end
    Fling.Running = true
    local angle = 0

    Fling.HbConn = RunService.Heartbeat:Connect(function()
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum) or hum.Health <= 0 then return end

        if Fling.Hum ~= hum then
            FlingSetStates(Fling.Hum, true)
            Fling.Hum = hum
            FlingSetStates(hum, false)
        end

        if not Fling.Applied then
            Fling.SavedVel = hrp.AssemblyLinearVelocity
        end
        angle = (angle + 1.7) % (math.pi * 2)
        hrp.AssemblyLinearVelocity = Vector3.new(math.cos(angle), 0.35, math.sin(angle)) * FLING_POWER
        hrp.AssemblyAngularVelocity = Vector3.zero
        Fling.Applied = true
    end)

    Fling.RsConn = RunService.RenderStepped:Connect(function()
        if not Fling.Applied then return end
        Fling.Applied = false
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Fling.SavedVel
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function SetFling(source, state)
    Fling.Sources[source] = state and true or nil
    if next(Fling.Sources) ~= nil then FlingStart() else FlingStop() end
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if _G.NoFogStatus then
                Lighting.FogStart = 9e9
                Lighting.FogEnd = 9e9
            end
            if _G.FullbrightStatus then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 786303
                Lighting.GlobalShadows = false

                if _G.SkyMode == "Normal" and not DiscoActive then
                    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
                end
            end
        end)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if _G.JumpStatus and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
        Player.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

local TacosSound = SoundService:FindFirstChild("Tungtung_TacosMusic")
if not TacosSound then
    TacosSound = Instance.new("Sound")
    TacosSound.Name = "Tungtung_TacosMusic"
    TacosSound.SoundId = "rbxassetid://142376088"
    TacosSound.Volume = 1
    TacosSound.Looped = true
    TacosSound.Parent = SoundService
end

local function RestoreLightingColors()
    Lighting.Ambient = OriginalLighting.Ambient
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    Lighting.ColorShift_Top = OriginalLighting.ColorShift_Top
    Lighting.ColorShift_Bottom = OriginalLighting.ColorShift_Bottom
    Lighting.FogColor = OriginalLighting.FogColor
end

local function ToggleDiscoSystem(state)
    DiscoActive = state
    if DiscoThread then
        pcall(task.cancel, DiscoThread)
        DiscoThread = nil
    end
    if DiscoActive then
        if not TacosSound.IsPlaying then TacosSound:Play() end
        DiscoThread = task.spawn(function()
            local hue = 0
            while DiscoActive do
                hue = (hue + 0.04) % 1
                local c = Color3.fromHSV(hue, 1, 1)
                Lighting.Ambient = c
                Lighting.OutdoorAmbient = c
                Lighting.FogColor = c
                Lighting.ColorShift_Top = c
                Lighting.ColorShift_Bottom = c
                task.wait(0.02)
            end
        end)
    else
        if TacosSound.IsPlaying then TacosSound:Stop() end
        RestoreLightingColors()

        if _G.SkyMode == "Static" and _G.SkyStaticColor then
            Lighting.OutdoorAmbient = _G.SkyStaticColor
            Lighting.Ambient = _G.SkyStaticColor
            Lighting.FogColor = _G.SkyStaticColor
        end
    end
end

local HiddenSkyObjects = {}

local function HideGameSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if (v:IsA("Sky") or v:IsA("Atmosphere")) and not string.find(v.Name, "Tungtung_") then
            table.insert(HiddenSkyObjects, v)
            v.Parent = nil
        end
    end
end

local function RestoreGameSky()
    for _, v in ipairs(HiddenSkyObjects) do
        pcall(function() v.Parent = Lighting end)
    end
    table.clear(HiddenSkyObjects)
end

local function ResetSkyEffects()
    _G.SkyToken = _G.SkyToken + 1
    _G.Sky666Active = false
    _G.SkyMode = "Normal"
    _G.SkyStaticColor = nil
    _G.SkyKey = nil

    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") and string.find(v.Name, "Tungtung_") then v:Destroy() end
    end
    RestoreGameSky()

    Lighting.ClockTime = OriginalLighting.ClockTime
    if not DiscoActive then
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.FogColor = OriginalLighting.FogColor
    end

    task.spawn(function()
        local n = 0
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Texture") and v.Name == "Avatar666Texture" then v:Destroy() end
            n += 1
            if n % 300 == 0 then task.wait() end
        end
    end)
end

local function MakeEmptySky(name)
    local sky = Instance.new("Sky")
    sky.Name = name
    sky.SkyboxBk = "" sky.SkyboxDn = "" sky.SkyboxFt = ""
    sky.SkyboxLf = "" sky.SkyboxRt = "" sky.SkyboxUp = ""
    sky.Parent = Lighting
end

local function ApplySkyColor(color, mode, key)
    ResetSkyEffects()
    HideGameSky()
    _G.SkyMode = mode or "Static"
    _G.SkyStaticColor = color
    _G.SkyKey = key
    MakeEmptySky("Tungtung_CustomSky")

    if _G.SkyMode == "Static" and color and not DiscoActive then
        Lighting.OutdoorAmbient = color
        Lighting.Ambient = color
        Lighting.FogColor = color
    end

end

local function Enable666Sky(key)
    ResetSkyEffects()
    HideGameSky()
    _G.Sky666Active = true
    _G.SkyMode = "Static"
    _G.SkyStaticColor = Color3.fromRGB(0, 0, 0)
    _G.SkyKey = key
    Lighting.ClockTime = 0
    Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    MakeEmptySky("Tungtung_Sky666")

    local token = _G.SkyToken
    task.spawn(function()
        if UserAvatarAssetId == "" then return end
        local n = 0
        for _, obj in pairs(workspace:GetDescendants()) do
            if _G.SkyToken ~= token then return end
            if obj:IsA("BasePart") and not obj:IsDescendantOf(workspace.Terrain) then
                local model = obj:FindFirstAncestorOfClass("Model")
                if not (model and model:FindFirstChildOfClass("Humanoid")) then
                    pcall(function()
                        for _, face in pairs(Enum.NormalId:GetEnumItems()) do
                            local tex = Instance.new("Texture")
                            tex.Name = "Avatar666Texture"
                            tex.Texture = UserAvatarAssetId
                            tex.Face = face
                            tex.Parent = obj
                        end
                    end)
                end
            end
            n += 1
            if n % 150 == 0 then task.wait() end
        end
    end)
end

_G.PlayerEspStatus = false
_G.NpcEspStatus = false

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if _G.PlayerEspStatus then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        if not p.Character:FindFirstChild("Tungtung_PlayerESP") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "Tungtung_PlayerESP"
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.Parent = p.Character
                        end
                    end
                end
            else
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("Tungtung_PlayerESP") then
                        p.Character.Tungtung_PlayerESP:Destroy()
                    end
                end
            end
        end)
    end
end)

local NpcHighlights = {}
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if _G.NpcEspStatus then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(v) then
                        if not v:FindFirstChild("Tungtung_NpcESP") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "Tungtung_NpcESP"
                            hl.FillColor = Color3.fromRGB(0, 255, 100)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.Parent = v
                            table.insert(NpcHighlights, hl)
                        end
                    end
                end
            else
                if #NpcHighlights > 0 then
                    for _, hl in ipairs(NpcHighlights) do
                        if hl and hl.Parent then hl:Destroy() end
                    end
                    table.clear(NpcHighlights)
                end
            end
        end)
    end
end)

local MapName = nil
task.spawn(function()
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if ok and info and info.Name then
        MapName = info.Name
    else
        MapName = game.Name ~= "" and game.Name or "N/A"
    end
end)

local function GetRequest()
    return request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
end

local function FormatTime(dt)
    return dt:FormatLocalTime("DD/MM/YYYY HH:mm:ss", _G.CurrentLang == "VN" and "vi-vn" or "en-us")
end

local CreatedText, CreatedExact
do
    local ok, dt = pcall(function() return DateTime.fromUnixTimestamp(os.time() - Player.AccountAge * 86400) end)
    if ok then CreatedText = FormatTime(dt):sub(1, 10) .. " (~)" end
end
task.spawn(pcall, function()
    local req = GetRequest()
    if not req then return end
    local res = req({Url = "https://users.roproxy.com/v1/users/" .. Player.UserId, Method = "GET"})
    local body = HttpService:JSONDecode(res.Body)
    if body and body.created then
        CreatedText = FormatTime(DateTime.fromIsoDate(body.created))
        CreatedExact = true
    end
end)

local function ReadRobux()
    local found
    pcall(function()
        for _, d in ipairs(CoreGui:GetDescendants()) do
            if d:IsA("TextLabel") then
                local path = (d.Name .. (d.Parent and d.Parent.Name or "")):lower()
                if path:find("robux") or path:find("currency") then
                    local digits = d.Text:gsub("[,%.%s]", "")
                    if digits:match("^%d+$") then found = d.Text return end
                end
            end
        end
    end)
    return found
end

local function HopServer(sortOrder, pick, notFoundMsg)
    pcall(function()
        local req = GetRequest()
        if not req then return end
        local url = "https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100"
        local res = req({Url = url, Method = "GET"})
        local body = HttpService:JSONDecode(res.Body)
        if body and body.data then
            local target = pick(body.data)
            if target then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, target, Player)
            elseif notFoundMsg then
                SendRobloxNotification("Tungtung Hub", notFoundMsg, 2)
            end
        end
    end)
end

local CAM_MIN_ZOOM = 0.5
local CAM_MAX_ZOOM = 100000
local CAM_START_ZOOM = 15
local CamUnlock = {Enabled = false, Orig = nil, Min = CAM_MIN_ZOOM, Token = 0}
_G.CamUnlockStatus = false

local function CamUnlockApply()
    pcall(function()
        if Player.CameraMode ~= Enum.CameraMode.Classic then Player.CameraMode = Enum.CameraMode.Classic end

        if Player.CameraMaxZoomDistance ~= CAM_MAX_ZOOM then Player.CameraMaxZoomDistance = CAM_MAX_ZOOM end
        if Player.CameraMinZoomDistance ~= CamUnlock.Min then Player.CameraMinZoomDistance = CamUnlock.Min end
    end)
end

local function SetCamUnlock(state)
    CamUnlock.Enabled = state and true or false
    _G.CamUnlockStatus = CamUnlock.Enabled
    CamUnlock.Token += 1
    pcall(function() RunService:UnbindFromRenderStep("Tungtung_CamUnlock") end)

    if CamUnlock.Enabled then
        CamUnlock.Orig = {
            Mode = Player.CameraMode,
            Min = Player.CameraMinZoomDistance,
            Max = Player.CameraMaxZoomDistance,
        }

        CamUnlock.Min = CAM_START_ZOOM

        RunService:BindToRenderStep("Tungtung_CamUnlock", Enum.RenderPriority.Camera.Value - 1, CamUnlockApply)
        local token = CamUnlock.Token
        task.delay(0.8, function()
            if CamUnlock.Enabled and CamUnlock.Token == token then CamUnlock.Min = CAM_MIN_ZOOM end
        end)
    else
        local o = CamUnlock.Orig
        if o then
            pcall(function()
                Player.CameraMode = o.Mode
                Player.CameraMinZoomDistance = o.Min
                Player.CameraMaxZoomDistance = o.Max
            end)
        end
        CamUnlock.Orig = nil
        CamUnlock.Min = CAM_MIN_ZOOM
    end
end

local LoadTag = {}

local function UpdateHeaders()
    local text = LangPack[_G.CurrentLang]
    TitleMenu.Text = text.Title
    SearchBox.PlaceholderText = text.SearchPlaceholder or "Tìm Script..."
    SubTitleMenu.Text = text.SubTitle
    SidebarHeader.Text = text.HeaderSidebar
    ContentHeader.Text = text.HeaderContent
end

LoadTag[1] = function()
    ClearScroll() HighlightTab(1) UpdateHeaders() local text = LangPack[_G.CurrentLang]
    AddBtn(text.BtnGodMode, function() loadstring(game:HttpGet("https://pastefy.app/plXEGzy8/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnInvis, function(btn)
        btn.Text = text.BtnInvisLoading
        task.spawn(function() pcall(function() loadstring(game:HttpGet("https://pastefy.app/N7OhsEzA/raw", true))() end) end)
        task.wait(1)
        btn.Text = text.BtnInvis
        ToggleMenu()
    end, false)
    AddBtn(text.BtnNoFog, function(state)
        _G.NoFogStatus = state
        if not state then
            Lighting.FogStart = OriginalLighting.FogStart
            Lighting.FogEnd = OriginalLighting.FogEnd
        end
    end, true, _G.NoFogStatus)
    AddBtn(text.BtnFullbright, function(state)
        _G.FullbrightStatus = state
        if not state then
            Lighting.Brightness = OriginalLighting.Brightness
            Lighting.ClockTime = OriginalLighting.ClockTime
            Lighting.GlobalShadows = OriginalLighting.GlobalShadows
            Lighting.FogEnd = OriginalLighting.FogEnd
            if _G.SkyMode == "Normal" and not DiscoActive then
                Lighting.Ambient = OriginalLighting.Ambient
            end
        end
    end, true, _G.FullbrightStatus)
    AddBtn(text.BtnNoclip, function(state) SetNoclip(state) end, true, Noclip.Enabled)
    AddBtn(text.BtnFly, function() loadstring(game:HttpGet("https://pastefy.app/YQTPy1Fm/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnSpeed, function() loadstring(game:HttpGet("https://pastefy.app/lzKknJTZ/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnInfJump, function(state) _G.JumpStatus = state end, true, _G.JumpStatus)

    local JumpInputFrame = Instance.new("Frame", ScrollList)
    JumpInputFrame.Size = UDim2.new(0, 150, 0, 34)
    JumpInputFrame.BackgroundTransparency = 1
    local JumpInput = Instance.new("TextBox", JumpInputFrame)
    JumpInput.Size = UDim2.new(1, 0, 1, 0)
    JumpInput.Position = UDim2.new(0, 0, 0, 0)
    JumpInput.BackgroundColor3 = BTN_BG
    JumpInput.BackgroundTransparency = 0.05
    JumpInput.BorderSizePixel = 0
    JumpInput.PlaceholderText = text.PlaceholderJump
    JumpInput.PlaceholderColor3 = Color3.fromRGB(140, 120, 122)
    JumpInput.TextColor3 = Color3.new(1, 1, 1)
    JumpInput.Font = Enum.Font.GothamBold
    JumpInput.TextSize = 10.5
    JumpInput.Text = ""
    Instance.new("UICorner", JumpInput).CornerRadius = UDim.new(1, 0)
    ApplyThemeBorder(JumpInput, 1.2)
    JumpInput.FocusLost:Connect(function()
        local val = tonumber(JumpInput.Text)
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if val and hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
            SendRobloxNotification("Tungtung Hub", text.NotifJumpPowerSet .. val, 2)
        end
    end)
    AddBtn(text.BtnAirStand, function() loadstring(game:HttpGet("https://pastefy.app/YaGjnt4Y/raw", true))() end, false)
    AddBtn(text.BtnCamUnlock, function(state) SetCamUnlock(state) end, true, _G.CamUnlockStatus)
    AddBtn(text.BtnHumanoidState, function() loadstring(game:HttpGet("https://pastefy.app/cFRMspqN/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnFlash, function() loadstring(game:HttpGet("https://pastefy.app/yXPvznQE/raw?v=1&t=", true))() end, false)
end

LoadTag[2] = function()
    ClearScroll() HighlightTab(2) UpdateHeaders() local text = LangPack[_G.CurrentLang]

    local function RefreshSkyTab()
        local pos = ScrollList.CanvasPosition
        if CurrentActiveTag == 2 then
            LoadTag[2]()
            ScrollList.CanvasPosition = pos
        end
    end

    local function CreateSkySelector(btnText, color, modeType)
        local key = btnText
        AddBtn(btnText .. " (Client)", function(state)
            if state then
                ApplySkyColor(color, modeType, key)
            else
                ResetSkyEffects()
            end
            task.defer(RefreshSkyTab)
        end, true, _G.SkyKey == key)
    end

    AddBtn("666 (Client)", function(state)
        if state then
            Enable666Sky("666")
        else
            ResetSkyEffects()
        end
        task.defer(RefreshSkyTab)
    end, true, _G.SkyKey == "666")

    CreateSkySelector(text.ColorRainbow, nil, "Rainbow")
    CreateSkySelector(text.ColorRainbowFast, nil, "RainbowFast")
    CreateSkySelector(text.ColorRainbowFlash, nil, "RainbowFlash")
    CreateSkySelector(text.ColorRainbowPastel, nil, "RainbowPastel")
    CreateSkySelector(text.ColorRainbowNeon, nil, "RainbowNeon")
    CreateSkySelector(text.ColorRainbowDark, nil, "RainbowDark")
    CreateSkySelector(text.ColorRainbowIce, nil, "RainbowIce")
    CreateSkySelector(text.ColorRainbowFire, nil, "RainbowFire")

    CreateSkySelector(text.ColorGreen, Color3.fromRGB(0, 180, 0), "Static")
    CreateSkySelector(text.ColorGreenV2, Color3.fromRGB(0, 255, 100), "Static")
    CreateSkySelector(text.ColorGreenV3, Color3.fromRGB(50, 205, 50), "Static")
    CreateSkySelector(text.ColorMint, Color3.fromRGB(152, 255, 152), "Static")
    CreateSkySelector(text.ColorLime, Color3.fromRGB(191, 255, 0), "Static")
    CreateSkySelector(text.ColorEmerald, Color3.fromRGB(80, 200, 120), "Static")

    CreateSkySelector(text.ColorRed, Color3.fromRGB(255, 30, 40), "Static")
    CreateSkySelector(text.ColorRedV2, Color3.fromRGB(220, 0, 0), "Static")
    CreateSkySelector(text.ColorRedV3, Color3.fromRGB(255, 60, 60), "Static")
    CreateSkySelector(text.ColorDarkRed, Color3.fromRGB(139, 0, 0), "Static")
    CreateSkySelector(text.ColorCrimson, Color3.fromRGB(220, 20, 60), "Static")

    CreateSkySelector(text.ColorBlue, Color3.fromRGB(0, 100, 255), "Static")
    CreateSkySelector(text.ColorBlueV2, Color3.fromRGB(0, 230, 255), "Static")
    CreateSkySelector(text.ColorCyan, Color3.fromRGB(0, 255, 255), "Static")
    CreateSkySelector(text.ColorIceBlue, Color3.fromRGB(175, 238, 238), "Static")
    CreateSkySelector(text.ColorSkyBlue, Color3.fromRGB(135, 206, 235), "Static")
    CreateSkySelector(text.ColorNavy, Color3.fromRGB(0, 0, 128), "Static")

    CreateSkySelector(text.ColorPurple, Color3.fromRGB(140, 0, 200), "Static")
    CreateSkySelector(text.ColorPurpleV2, Color3.fromRGB(190, 60, 255), "Static")
    CreateSkySelector(text.ColorMagenta, Color3.fromRGB(255, 0, 255), "Static")
    CreateSkySelector(text.ColorLavender, Color3.fromRGB(230, 230, 250), "Static")
    CreateSkySelector(text.ColorViolet, Color3.fromRGB(138, 43, 226), "Static")

    CreateSkySelector(text.ColorYellow, Color3.fromRGB(255, 255, 0), "Static")
    CreateSkySelector(text.ColorLemon, Color3.fromRGB(255, 247, 0), "Static")
    CreateSkySelector(text.ColorOrange, Color3.fromRGB(255, 130, 0), "Static")
    CreateSkySelector(text.ColorDarkOrange, Color3.fromRGB(255, 69, 0), "Static")
    CreateSkySelector(text.ColorGold, Color3.fromRGB(255, 215, 0), "Static")

    CreateSkySelector(text.ColorPink, Color3.fromRGB(255, 120, 180), "Static")
    CreateSkySelector(text.ColorHotPink, Color3.fromRGB(255, 20, 147), "Static")
    CreateSkySelector(text.ColorRose, Color3.fromRGB(255, 102, 102), "Static")

    CreateSkySelector(text.ColorBrown, Color3.fromRGB(139, 69, 19), "Static")
    CreateSkySelector(text.ColorGray, Color3.fromRGB(128, 128, 128), "Static")
    CreateSkySelector(text.ColorWhite, Color3.fromRGB(255, 255, 255), "Static")
    CreateSkySelector(text.ColorBlack, Color3.fromRGB(30, 30, 30), "Static")
end

LoadTag[3] = function()
    ClearScroll() HighlightTab(3) UpdateHeaders() local text = LangPack[_G.CurrentLang]
    AddBtn(text.BtnAnimSpeed, function() loadstring(game:HttpGet("https://pastefy.app/lbVyHe4J/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnFling, function(state)
        _G.FlingStatus = state
        SetFling("fx", state)
    end, true, _G.FlingStatus)
end

LoadTag[4] = function()
    ClearScroll() HighlightTab(4) UpdateHeaders() local text = LangPack[_G.CurrentLang]
    AddBtn(text.BtnEntAnim, function() loadstring(game:HttpGet("https://pastefy.app/lbVyHe4J/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnEntFling, function(state)
        _G.EntertainmentFling = state
        SetFling("ent", state)
    end, true, _G.EntertainmentFling)
    AddBtn(text.BtnFakeLag, function() loadstring(game:HttpGet("https://pastefy.app/NBHt0P6E/raw?v=1&t=", true))() end, false)
end

LoadTag[5] = function()
    ClearScroll() HighlightTab(5) UpdateHeaders() local text = LangPack[_G.CurrentLang]
    AddBtn(text.BtnHitbox, function() loadstring(game:HttpGet("https://pastefy.app/cc6VQvdi/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnInfYield, function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Edgeiy/InfiniteYield/master/source"))() end, false)
    AddBtn(text.BtnTeleport, function() loadstring(game:HttpGet("https://pastefy.app/Sjc6pLeE/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnSpectate, function() loadstring(game:HttpGet("https://pastefy.app/tz5XTGmf/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnKillPlayer, function() loadstring(game:HttpGet("https://pastefy.app/VKHasvm5/raw?&v=1&t=" .. tick(), true))() end, false)
    AddBtn(text.BtnBringPlayers, function()
        local pRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if pRoot then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.CFrame = pRoot.CFrame * CFrame.new(0, 0, -4)
                end
            end
            SendRobloxNotification("Tungtung Hub", "Đã gom người chơi!", 2)
        end
    end, false)
    AddBtn(text.BtnPlayerEsp, function(state) _G.PlayerEspStatus = state end, true, _G.PlayerEspStatus)
end

LoadTag[6] = function()
    ClearScroll() HighlightTab(6) UpdateHeaders() local text = LangPack[_G.CurrentLang]
    AddBtn(text.BtnNpcEsp, function(state) _G.NpcEspStatus = state end, true, _G.NpcEspStatus)
    AddBtn(text.BtnBringNpcs, function()
        local pRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if pRoot then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(v) then
                    local npcRoot = v:FindFirstChild("HumanoidRootPart")
                    if npcRoot then npcRoot.CFrame = pRoot.CFrame * CFrame.new(0, 0, -5) end
                end
            end
            SendRobloxNotification("Tungtung Hub", "Đã gom tất cả NPC!", 2)
        end
    end, false)
    AddBtn(text.BtnPrompt, function(state) SetFastPrompt(state) end, true, FastPrompt.Enabled)
end

LoadTag[7] = function()
    ClearScroll() HighlightTab(7) UpdateHeaders() local text = LangPack[_G.CurrentLang]

    AddBtn(text.BtnRejoin, function()
        SendRobloxNotification("Tungtung Hub", "Đang kết nối lại...", 2)
        pcall(function()
            if #Players:GetPlayers() <= 1 then
                TeleportService:Teleport(game.PlaceId, Player)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
            end
        end)
    end, false)

    AddBtn(text.BtnServerHop, function()
        SendRobloxNotification("Tungtung Hub", "Đang tìm máy chủ mới...", 2)
        HopServer("Desc", function(list)
            for _, s in ipairs(list) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then return s.id end
            end
        end)
    end, false)

    AddBtn(text.BtnLowServer, function()
        SendRobloxNotification("Tungtung Hub", "Đang tìm máy chủ ít người...", 2)
        HopServer("Asc", function(list)
            for _, s in ipairs(list) do
                if s.playing > 0 and s.id ~= game.JobId then return s.id end
            end
        end)
    end, false)

    AddBtn(text.BtnVipServer, function()
        SendRobloxNotification("Tungtung Hub", "Đang tìm máy chủ VIP...", 2)
        HopServer("Asc", function(list)
            for _, s in ipairs(list) do
                if s.playing == 1 and s.id ~= game.JobId then return s.id end
            end
            for _, s in ipairs(list) do
                if s.playing < 3 and s.id ~= game.JobId then return s.id end
            end
        end, "Không tìm thấy server 1 người!")
    end, false)
end

LoadTag[8] = function()
    ClearScroll() HighlightTab(8) UpdateHeaders() local text = LangPack[_G.CurrentLang]
    AddBtn(text.BtnGetTpTool, function()
        local t = Instance.new("Tool")
        t.Name = "TP 🍉"
        t.RequiresHandle = false
        t.Parent = Player.Backpack
        t.Activated:Connect(function()
            local hit = Mouse.Hit
            if hit and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
                PlaySoundEffect(6026987522, 0.4)
            end
        end)
        SendRobloxNotification("Tungtung Hub", "Đã lấy dụng cụ TP!", 2)
    end, false)
    AddBtn(text.BtnDupeTool, function()
        local character = Player.Character
        local backpack = Player.Backpack
        if character then
            local currentTool = character:FindFirstChildOfClass("Tool")
            if currentTool then
                currentTool:Clone().Parent = backpack
                SendRobloxNotification("Tungtung Hub", "Đã nhân đôi dụng cụ!", 2)
            end
        end
    end, false)
    AddBtn(text.BtnDropTools, function() loadstring(game:HttpGet("https://pastefy.app/bA6kORwX/raw?v=1&t=", true))() end, false)
end

LoadTag[9] = function()
    ClearScroll() HighlightTab(9) UpdateHeaders() local text = LangPack[_G.CurrentLang]
    local function CreateColorSelector(btnText, color, modeType)
        AddBtn(btnText, function()
            if modeType then
                _G.ThemeMode = modeType
            else
                _G.ThemeMode = "Static"
                _G.StaticColor = color
            end
            SendRobloxNotification("Tungtung Hub", text.NotifThemeSet .. btnText, 2)
        end, false)
    end

    CreateColorSelector(text.ColorRainbow, nil, "Rainbow")
    CreateColorSelector(text.ColorRainbowFast, nil, "RainbowFast")
    CreateColorSelector(text.ColorRainbowFlash, nil, "RainbowFlash")
    CreateColorSelector(text.ColorRainbowPastel, nil, "RainbowPastel")
    CreateColorSelector(text.ColorRainbowNeon, nil, "RainbowNeon")
    CreateColorSelector(text.ColorRainbowDark, nil, "RainbowDark")
    CreateColorSelector(text.ColorRainbowIce, nil, "RainbowIce")
    CreateColorSelector(text.ColorRainbowFire, nil, "RainbowFire")

    CreateColorSelector(text.ColorGreen, Color3.fromRGB(0, 180, 0), nil)
    CreateColorSelector(text.ColorGreenV2, Color3.fromRGB(0, 255, 100), nil)
    CreateColorSelector(text.ColorGreenV3, Color3.fromRGB(50, 205, 50), nil)
    CreateColorSelector(text.ColorMint, Color3.fromRGB(152, 255, 152), nil)
    CreateColorSelector(text.ColorLime, Color3.fromRGB(191, 255, 0), nil)
    CreateColorSelector(text.ColorEmerald, Color3.fromRGB(80, 200, 120), nil)

    CreateColorSelector(text.ColorRed, Color3.fromRGB(255, 30, 40), nil)
    CreateColorSelector(text.ColorRedV2, Color3.fromRGB(220, 0, 0), nil)
    CreateColorSelector(text.ColorRedV3, Color3.fromRGB(255, 60, 60), nil)
    CreateColorSelector(text.ColorDarkRed, Color3.fromRGB(139, 0, 0), nil)
    CreateColorSelector(text.ColorCrimson, Color3.fromRGB(220, 20, 60), nil)

    CreateColorSelector(text.ColorBlue, Color3.fromRGB(0, 100, 255), nil)
    CreateColorSelector(text.ColorBlueV2, Color3.fromRGB(0, 230, 255), nil)
    CreateColorSelector(text.ColorCyan, Color3.fromRGB(0, 255, 255), nil)
    CreateColorSelector(text.ColorIceBlue, Color3.fromRGB(175, 238, 238), nil)
    CreateColorSelector(text.ColorSkyBlue, Color3.fromRGB(135, 206, 235), nil)
    CreateColorSelector(text.ColorNavy, Color3.fromRGB(0, 0, 128), nil)

    CreateColorSelector(text.ColorPurple, Color3.fromRGB(140, 0, 200), nil)
    CreateColorSelector(text.ColorPurpleV2, Color3.fromRGB(190, 60, 255), nil)
    CreateColorSelector(text.ColorMagenta, Color3.fromRGB(255, 0, 255), nil)
    CreateColorSelector(text.ColorLavender, Color3.fromRGB(230, 230, 250), nil)
    CreateColorSelector(text.ColorViolet, Color3.fromRGB(138, 43, 226), nil)

    CreateColorSelector(text.ColorYellow, Color3.fromRGB(255, 255, 0), nil)
    CreateColorSelector(text.ColorLemon, Color3.fromRGB(255, 247, 0), nil)
    CreateColorSelector(text.ColorOrange, Color3.fromRGB(255, 130, 0), nil)
    CreateColorSelector(text.ColorDarkOrange, Color3.fromRGB(255, 69, 0), nil)
    CreateColorSelector(text.ColorGold, Color3.fromRGB(255, 215, 0), nil)

    CreateColorSelector(text.ColorPink, Color3.fromRGB(255, 120, 180), nil)
    CreateColorSelector(text.ColorHotPink, Color3.fromRGB(255, 20, 147), nil)
    CreateColorSelector(text.ColorRose, Color3.fromRGB(255, 102, 102), nil)

    CreateColorSelector(text.ColorBrown, Color3.fromRGB(139, 69, 19), nil)
    CreateColorSelector(text.ColorGray, Color3.fromRGB(128, 128, 128), nil)
    CreateColorSelector(text.ColorWhite, Color3.fromRGB(255, 255, 255), nil)
    CreateColorSelector(text.ColorBlack, Color3.fromRGB(30, 30, 30), nil)
end

LoadTag[10] = function()
    ClearScroll() HighlightTab(10) UpdateHeaders() local text = LangPack[_G.CurrentLang]
    AddBtn(text.BtnXray, function() loadstring(game:HttpGet("https://pastefy.app/dZBZckua/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnDisco, function(state)
        ToggleDiscoSystem(state)
    end, true, DiscoActive)
    AddBtn(text.BtnRespawn, function() loadstring(game:HttpGet("https://pastefy.app/tE5mPYcB/raw?v=1&t=", true))() end, false)
    AddBtn(text.BtnWorldScan, function() loadstring(game:HttpGet("https://pastefy.app/wtwhO5vE/raw?v=1&t=", true))() end, false)
end

local function ApplyLanguage(code)
    _G.CurrentLang = code
    saveLang({lang = string.lower(code)})
    SendRobloxNotification("Tungtung Hub", LangPack[code].NotifLangChanged, 2)
    for id, tabBtn in pairs(CreatedTabs) do
        tabBtn.Text = LangPack[code]["Tag" .. id] or ("Tab " .. id)
    end
    LoadTag[CurrentActiveTag]()
end

LoadTag[11] = function()
    ClearScroll() HighlightTab(11) UpdateHeaders()
    AddBtn("Tiếng Việt (VN)", function() ApplyLanguage("VN") end, false)
    AddBtn("English (EN)", function() ApplyLanguage("EN") end, false)
end

LoadTag[12] = function()
    ClearScroll() HighlightTab(12) UpdateHeaders() local text = LangPack[_G.CurrentLang]

    local function AddInfo(label, value)
        local frame = Instance.new("Frame", ScrollList)
        frame.Size = UDim2.new(0, 154, 0, 36)
        frame.BackgroundColor3 = BTN_BG
        frame.BackgroundTransparency = 0.05
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
        ApplyThemeBorder(frame, 1.2)

        local current = value
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1, -20, 1, 0)
        btn.Position = UDim2.new(0, 10, 0, 0)
        btn.BackgroundTransparency = 1
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.TextColor3 = Color3.fromRGB(235, 232, 232)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextWrapped = true
        btn.Text = label .. ": " .. tostring(value)
        btn.MouseButton1Click:Connect(function()
            PlaySoundEffect(6026987522, 0.3)
            local ok = pcall(function()
                local copyFn = setclipboard or toclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
                assert(copyFn, "no clipboard")
                copyFn(tostring(current))
            end)
            local shown = tostring(current)
            if #shown > 28 then shown = shown:sub(1, 28) .. "..." end
            if ok then
                ShowToast("✔ " .. text.ProfCopied .. shown, 2)
                SendRobloxNotification("Tungtung Hub", text.ProfCopied .. shown, 2)
            else
                ShowToast("✘ " .. (_G.CurrentLang == "VN" and "Không sao chép được" or "Copy failed"), 2)
            end
        end)
        return btn, function(v)
            current = v
            if btn.Parent then btn.Text = label .. ": " .. tostring(v) end
        end
    end

    AddInfo(text.ProfDisplay, Player.DisplayName)
    AddInfo(text.ProfUser, Player.Name)
    AddInfo(text.ProfUserId, Player.UserId)
    AddInfo(text.ProfPlaceId, game.PlaceId)
    local _, setMap = AddInfo(text.ProfMap, MapName or text.ProfLoading)
    AddInfo(text.ProfLogin, FormatTime(DateTime.fromUnixTimestamp(LoginTimestamp)))
    local _, setCreated = AddInfo(text.ProfCreated, CreatedText or text.ProfLoading)
    AddInfo(text.ProfRobux, ReadRobux() or text.ProfNA)

    task.spawn(function()
        local t0 = os.clock()
        while os.clock() - t0 < 8 and not (MapName and CreatedExact) do
            task.wait(0.2)
        end
        if MapName then setMap(MapName) end
        if CreatedText then setCreated(CreatedText) end
    end)
end

LoadTag[13] = function()
    ClearScroll() HighlightTab(13) UpdateHeaders()
    AddBtn("Tống hợp longhihi hub", function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/longhihilonghihi-hub/ScriptTongHop-/refs/heads/main/MainTongHop.lua"))()
        end)
    end, false)
    AddBtn("MADE BY ELAINA SKID 😂", function()
        pcall(function()
            loadstring(game:HttpGet'https://pastefy.app/K2RDuzrf/raw')()
        end)
    end, false)
    AddBtn("Oie Hub", function()
        pcall(function()
            loadstring(game:HttpGet("https://pastefy.app/CdWSUT1H/raw"))()
        end)
    end, false)
    AddBtn("Hoang.tt Hub", function()
        pcall(function()
            loadstring(game:HttpGet("https://voidedx.vercel.app/api/raw?id=vx_2aajo7ct"))()
        end)
    end, false)
end

local UGLY_COLORS = {
    Color3.fromRGB(255, 0, 255),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(255, 128, 0),
    Color3.fromRGB(0, 120, 255),
}
local function Uglify(o)
    if o:IsA("UICorner") then
        o.CornerRadius = UDim.new(0, 0)
    elseif o:IsA("UIGradient") and o.Parent and o.Parent:IsA("GuiObject") then
        o:Destroy()
    elseif o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        o.Font = Enum.Font.Arcade
        o.TextColor3 = Color3.fromRGB(255, 255, 0)
    elseif o:IsA("Frame") and o.BackgroundTransparency < 1 then
        o.BackgroundTransparency = 0
        o.BackgroundColor3 = UGLY_COLORS[math.random(1, #UGLY_COLORS)]
    end
end
for _, d in ipairs(MainFrame:GetDescendants()) do pcall(Uglify, d) end
MainFrame.DescendantAdded:Connect(function(d) task.defer(pcall, Uglify, d) end)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
MainFrame.BackgroundTransparency = 0

for id, btn in pairs(CreatedTabs) do
    btn.Text = LangPack[_G.CurrentLang]["Tag" .. id] or ("Tab " .. id)
    btn.MouseButton1Click:Connect(function()
        PlaySoundEffect(6026987522, 0.3)
        CurrentActiveTag = id
        SearchBox.Text = ""
        if LoadTag[id] then
            LoadTag[id]()
        end
    end)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = string.lower(SearchBox.Text)
    for _, item in pairs(ScrollList:GetChildren()) do
        if item:IsA("Frame") then
            local btn = item:FindFirstChildOfClass("TextButton")
            if btn then
                item.Visible = (searchText == "") or (string.find(string.lower(btn.Text), searchText, 1, true) ~= nil)
            end
        end
    end
end)

local function TypeText(prefix, content, charsPerSec)
    local total = utf8.len(content) or #content
    local duration = total / charsPerSec
    local elapsed, lastSound = 0, 0
    while elapsed < duration do
        elapsed += RunService.Heartbeat:Wait()
        local n = math.min(total, math.floor(total * elapsed / duration))
        local cut = (utf8.offset(content, n + 1) or (#content + 1)) - 1
        textLabel.Text = prefix .. string.sub(content, 1, cut)
        if elapsed - lastSound >= 0.09 then
            lastSound = elapsed
            PlaySoundEffect(9114223178, 0.12)
        end
    end
    textLabel.Text = prefix .. content
end

local function DynamicSpeed(content)
    local total = utf8.len(content) or #content
    return math.clamp(total * 0.4, 90, 650)
end

task.spawn(function()
    pcall(function()
        local picked = Random.new():NextInteger(1, 3)
        local chosen = textContents[picked]
        TypeText("", chosen, DynamicSpeed(chosen))
        task.wait(0.2)

        barCard.Visible = true
        local fade = TweenInfo.new(0.3)
        TweenService:Create(barCard, fade, {BackgroundTransparency = 0}):Play()
        TweenService:Create(barCardStroke, fade, {Transparency = 0}):Play()
        TweenService:Create(barTitle, fade, {TextTransparency = 0}):Play()
        TweenService:Create(percentLabel, fade, {TextTransparency = 0}):Play()
        TweenService:Create(barTrack, fade, {BackgroundTransparency = 0}):Play()
        TweenService:Create(barFill, fade, {BackgroundTransparency = 0}):Play()

        for p = 1, 100 do
            percentLabel.Text = p .. "%"
            barFill.Size = UDim2.new(p / 100, 0, 1, 0)
            task.wait(0.012)
        end
        task.wait(0.2)

        local finalText = textContents[4]
        TypeText(textLabel.Text .. "\n", finalText, math.clamp(DynamicSpeed(finalText), 40, 120))
        task.wait(0.4)

        local out = TweenInfo.new(0.4)
        TweenService:Create(bg, out, {BackgroundTransparency = 1}):Play()
        TweenService:Create(textLabel, out, {TextTransparency = 1}):Play()
        TweenService:Create(barCard, out, {BackgroundTransparency = 1}):Play()
        TweenService:Create(barCardStroke, out, {Transparency = 1}):Play()
        TweenService:Create(barTitle, out, {TextTransparency = 1}):Play()
        TweenService:Create(percentLabel, out, {TextTransparency = 1}):Play()
        TweenService:Create(barTrack, out, {BackgroundTransparency = 1}):Play()
        TweenService:Create(barFill, out, {BackgroundTransparency = 1}):Play()

        task.wait(0.4)
    end)

    if loadingGui and loadingGui.Parent then loadingGui:Destroy() end

    ToggleBtn.Visible = true
    LoadTag[1]()
    ToggleMenu()
    SendRobloxNotification("Tungtung Hub", "Khởi chạy thành công V2.0!", 3)
end)
{BackgroundTransparency = 1}):Play()

        task.wait(0.4)
    end)

    if loadingGui and loadingGui.Parent then loadingGui:Destroy() end

    ToggleBtn.Visible = true
    LoadTag[1]()
    ToggleMenu()
    SendRobloxNotification("Tungtung Hub", "Khởi chạy thành công V2.0!", 3)
end)
