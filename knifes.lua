if getgenv().KNIFES_OMNI_LOADED then
    getgenv().KNIFES_OMNI_LOADED = false
    task.wait(0.2)
end
getgenv().KNIFES_OMNI_LOADED = true
getgenv().KNIFES_START_TIME = tick()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local PARENT = LP:WaitForChild("PlayerGui")

local Cfg = {
    MenuKey = Enum.KeyCode.RightShift,
    AimEnabled = false, AimKey = Enum.KeyCode.E, AimFOV = 150, AimSmooth = 6.13,
    AimPrediction = 0.14, AimVisibleOnly = true, AimAutoFire = false,
    NoSpreadEnabled = true, RapidFireEnabled = false,
    HitboxExpanderEnabled = false, HitboxSize = 15,
    KillAuraEnabled = false, KillAuraRange = 20,
    
    ESPEnabled = true, ESPBox = true, ESPName = true, ESPDistance = true,
    ESPHealth = true, ESPSkeleton = false, ESPTracers = false, ESPHeadDot = false,
    ChamsEnabled = true, ChamsFillColor = Color3.fromRGB(255, 60, 60),
    ChinaHat = false, HaloEnabled = false, FOVCircle = true,
    
    SpeedEnabled = false, SpeedValue = 25, JumpEnabled = false, JumpValue = 100,
    InfJumpEnabled = false, FlyEnabled = false, FlySpeed = 50, NoclipEnabled = false,
    
    SpinbotEnabled = false, SpinbotSpeed = 15, ScreenShakeEnabled = false,
    FlingAllEnabled = false, TelekinesisEnabled = false, TelekinesisRange = 20,
    EmotesEnabled = false, ChatSpamEnabled = false,
    
    Fullbright = false, Nightmode = false, AmbientLight = false, NoFog = false, NoShadows = false,
    GravityEnabled = false, GravityValue = 196.2, TimeEnabled = false, TimeValue = 14,
    SnowEnabled = false, AntiAFKEnabled = true,
    
    Brightness = 2, Exposure = 0, FogEnd = 1000,
    BloomIntensity = 1, BloomSize = 24, SunRaysIntensity = 0.25
}

local State = {
    FlyBV = nil, SpinPhase = 0, ShakeTick = 0, LastShot = 0,
    ESPCache = {}, SkelLines = {}, AnimTrack = nil, SnowEmitter = nil
}

local Theme = {
    bg = Color3.fromRGB(10, 10, 15), panel = Color3.fromRGB(18, 18, 25),
    elem = Color3.fromRGB(28, 32, 38), border = Color3.fromRGB(50, 50, 60),
    text = Color3.fromRGB(240, 240, 250), dim = Color3.fromRGB(150, 150, 160),
    red = Color3.fromRGB(255, 60, 60), white = Color3.fromRGB(255, 255, 255)
}

local F_Main = Enum.Font.GothamBold
local F_Med = Enum.Font.GothamMedium
local F_Code = Enum.Font.Code

local function Create(cls, props, parent)
    local inst = Instance.new(cls)
    for k, v in pairs(props or {}) do if k ~= "Parent" then pcall(function() inst[k] = v end) end end
    if parent then inst.Parent = parent end
    return inst
end
local function Corner(p, r) local c = Instance.new("UICorner", p) c.CornerRadius = UDim.new(0, r or 6) return c end
local function Stroke(p, col, th, tr) local s = Instance.new("UIStroke", p) s.Color = col or Theme.border s.Thickness = th or 1 s.Transparency = tr or 0 return s end
local function Tw(o, p, v, t) local tr = TweenService:Create(o, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quint), {[p] = v}) tr:Play() return tr end
local function GetHRP(p) local c = (p or LP).Character return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum(p) local c = (p or LP).Character return c and c:FindFirstChildOfClass("Humanoid") end
local function GetHead(p) local c = (p or LP).Character return c and c:FindFirstChild("Head") end

local Blur = Create("BlurEffect", { Size = 0, Enabled = false }, Lighting)

-- КАСТОМНЫЙ ПРИЦЕЛ (КРАСНЫЕ ПИЛЮЛИ)
local CrossGui = Create("ScreenGui", { Name = "KNIFES_CROSSHAIR", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999999 }, PARENT)
local CrossContainer = Create("Frame", { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.5, -20, 0.5, -20), BackgroundTransparency = 1 }, CrossGui)
local function CreatePill(rot)
    local pill = Create("Frame", { Size = UDim2.fromOffset(2, 8), Position = UDim2.new(0.5, -1, 0.5, -4), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 60, 60), BorderSizePixel = 0, Rotation = rot }, CrossContainer)
    Corner(pill, 1)
    local glow = Instance.new("UIStroke", pill)
    glow.Color = Color3.fromRGB(255, 60, 60)
    glow.Thickness = 3
    glow.Transparency = 0.5
    return pill
end
local p1 = CreatePill(0)
local p2 = CreatePill(90)
local p3 = CreatePill(180)
local p4 = CreatePill(270)
p1.Position = UDim2.new(0.5, 0, 0.5, -8)
p2.Position = UDim2.new(0.5, 8, 0.5, 0)
p3.Position = UDim2.new(0.5, 0, 0.5, 8)
p4.Position = UDim2.new(0.5, -8, 0.5, 0)

task.spawn(function()
    local angle = 0
    while getgenv().KNIFES_OMNI_LOADED do
        angle = angle + 0.5
        CrossContainer.Rotation = angle
        task.wait(0.01)
    end
end)

local ScreenGui = Create("ScreenGui", { Name = "KNIFES_UI", ResetOnSpawn = false, DisplayOrder = 999998 }, PARENT)
local MainWin = Create("Frame", { Size = UDim2.fromOffset(850, 580), Position = UDim2.new(0.5, -425, 0.5, -290), BackgroundColor3 = Theme.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0 }, ScreenGui)
Corner(MainWin, 12)
Stroke(MainWin, Theme.red, 10, 0.7)
Stroke(MainWin, Theme.red, 3, 0.4)
Stroke(MainWin, Theme.white, 1, 0.6)

local Header = Create("Frame", { Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.2, BorderSizePixel = 0 }, MainWin)
Corner(Header, 12)
Create("TextLabel", { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(15, 0), BackgroundTransparency = 1, Text = "knifes.wtf | OMNI", TextColor3 = Theme.white, Font = F_Main, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left }, Header)

local CloseBtn = Create("TextButton", { Size = UDim2.fromOffset(45, 45), Position = UDim2.new(1, -45, 0, 0), BackgroundTransparency = 1, Text = "X", TextColor3 = Theme.dim, Font = F_Main, TextSize = 16, AutoButtonColor = false }, Header)
CloseBtn.MouseEnter:Connect(function() Tw(CloseBtn, "TextColor3", Theme.red, 0.15) end)
CloseBtn.MouseLeave:Connect(function() Tw(CloseBtn, "TextColor3", Theme.dim, 0.15) end)
CloseBtn.MouseButton1Click:Connect(function()
    Tw(MainWin, "Size", UDim2.fromOffset(0,0), 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    Blur.Enabled = false Blur.Size = 0
    task.delay(0.3, function() ScreenGui.Enabled = false end)
end)

local Dragging, DragStart, StartPos
Header.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = true DragStart = input.Position StartPos = MainWin.Position end end)
UIS.InputChanged:Connect(function(input) if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - DragStart MainWin.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end end)

local Sidebar = Create("Frame", { Size = UDim2.new(0, 160, 1, -55), Position = UDim2.fromOffset(10, 50), BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.4, BorderSizePixel = 0 }, MainWin)
Corner(Sidebar, 8)
local Content = Create("Frame", { Size = UDim2.new(1, -180, 1, -55), Position = UDim2.fromOffset(180, 50), BackgroundTransparency = 1 }, MainWin)

local Tabs = {"COMBAT", "VISUALS", "MOVEMENT", "TROLL", "WORLD", "MISC"}
local Pages, TabBtns, CurrentTab = {}, {}, "COMBAT"

for i, t in ipairs(Tabs) do
    local btn = Create("TextButton", { Size = UDim2.new(1, -10, 0, 32), Position = UDim2.fromOffset(5, 5 + (i-1)*36), BackgroundColor3 = Theme.elem, BackgroundTransparency = 0.5, BorderSizePixel = 0, Text = t, TextColor3 = Theme.dim, Font = F_Main, TextSize = 12, AutoButtonColor = false }, Sidebar)
    Corner(btn, 6)
    TabBtns[t] = btn
    local page = Create("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, Visible = false }, Content)
    Create("UIListLayout", { Padding = UDim.new(0, 6) }, page) Pages[t] = page
    btn.MouseButton1Click:Connect(function()
        CurrentTab = t
        for name, p in pairs(Pages) do p.Visible = (name == t) end
        for name, b in pairs(TabBtns) do
            b.BackgroundColor3 = (name == t) and Theme.red or Theme.elem
            b.TextColor3 = (name == t) and Theme.white or Theme.dim
            b.BackgroundTransparency = (name == t) and 0.1 or 0.5
        end
    end)
end

local function AddSection(text, parent) Create("TextLabel", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.red, Font = F_Main, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, parent or Pages[CurrentTab]) end
local function AddToggle(text, getter, setter, parent)
    local btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.elem, BackgroundTransparency = 0.5, BorderSizePixel = 0, Text = "  " .. text, TextColor3 = Theme.white, Font = F_Med, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, parent or Pages[CurrentTab])
    Corner(btn, 6)
    local ind = Create("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(1, -20, 0.5, -4), BackgroundColor3 = getter() and Theme.red or Theme.border }, btn)
    Corner(ind, 4)
    btn.MouseEnter:Connect(function() Tw(btn, "BackgroundTransparency", 0.3, 0.15) end)
    btn.MouseLeave:Connect(function() Tw(btn, "BackgroundTransparency", 0.5, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        local s = not getter() setter(s) Tw(ind, "BackgroundColor3", s and Theme.red or Theme.border, 0.15)
    end)
end
local function AddSlider(text, min, max, getter, setter, parent)
    local btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.elem, BackgroundTransparency = 0.5, BorderSizePixel = 0, Text = "  " .. text .. ": " .. tostring(getter()), TextColor3 = Theme.white, Font = F_Med, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, parent or Pages[CurrentTab])
    Corner(btn, 6)
    btn.MouseEnter:Connect(function() Tw(btn, "BackgroundTransparency", 0.3, 0.15) end)
    btn.MouseLeave:Connect(function() Tw(btn, "BackgroundTransparency", 0.5, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        local v = getter() + math.floor((max - min) / 10)
        if v > max then v = min end
        setter(v) btn.Text = "  " .. text .. ": " .. tostring(v)
    end)
end
local function AddButton(text, color, callback)
    local btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = color, BackgroundTransparency = 0.2, BorderSizePixel = 0, Text = "  " .. text, TextColor3 = Theme.white, Font = F_Main, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, Pages[CurrentTab])
    Corner(btn, 6)
    btn.MouseEnter:Connect(function() Tw(btn, "BackgroundTransparency", 0, 0.15) end)
    btn.MouseLeave:Connect(function() Tw(btn, "BackgroundTransparency", 0.2, 0.15) end)
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
end

-- ВЫПАДАЮЩЕЕ МЕНЮ WORLD
local SubWorld = Create("Frame", { Size = UDim2.fromOffset(300, 420), Position = UDim2.new(0.5, -150, 0.5, -210), BackgroundColor3 = Theme.bg, BorderSizePixel = 1, BorderColor3 = Theme.red, Visible = false, ZIndex = 1000 }, ScreenGui)
Corner(SubWorld, 8)
local SubTitle = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.panel, Text = "World Ambience", TextColor3 = Theme.white, Font = F_Main, TextSize = 14, ZIndex = 1001 }, SubWorld)
Corner(SubTitle, 8)
local SubClose = Create("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = "X", TextColor3 = Theme.red, Font = F_Main, TextSize = 14, ZIndex = 1001 }, SubWorld)
SubClose.MouseButton1Click:Connect(function() SubWorld.Visible = false end)

local SubList = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -40), Position = UDim2.fromOffset(10, 35), BackgroundTransparency = 1, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 1001 }, SubWorld)
Create("UIListLayout", { Padding = UDim.new(0, 5) }, SubList)

AddSection("LIGHTING", SubList)
AddSlider("Brightness", 0, 5, function() return Cfg.Brightness end, function(v) Cfg.Brightness = v end, SubList)
AddSlider("Exposure", -5, 5, function() return Cfg.Exposure end, function(v) Cfg.Exposure = v end, SubList)
AddToggle("Fullbright", function() return Cfg.Fullbright end, function(v) Cfg.Fullbright = v end, SubList)
AddToggle("Nightmode", function() return Cfg.Nightmode end, function(v) Cfg.Nightmode = v end, SubList)
AddSlider("Time of Day", 0, 24, function() return Cfg.TimeValue end, function(v) Cfg.TimeValue = v end, SubList)

AddSection("FOG", SubList)
AddToggle("Remove Fog", function() return Cfg.NoFog end, function(v) Cfg.NoFog = v end, SubList)
AddSlider("Fog End", 100, 10000, function() return Cfg.FogEnd end, function(v) Cfg.FogEnd = v end, SubList)

AddSection("EFFECTS", SubList)
AddSlider("Bloom Intensity", 0, 5, function() return Cfg.BloomIntensity end, function(v) Cfg.BloomIntensity = v end, SubList)
AddSlider("Bloom Size", 0, 50, function() return Cfg.BloomSize end, function(v) Cfg.BloomSize = v end, SubList)
AddSlider("Sun Rays", 0, 1, function() return Cfg.SunRaysIntensity end, function(v) Cfg.SunRaysIntensity = v end, SubList)

AddSection("PHYSICS", SubList)
AddToggle("Change Gravity", function() return Cfg.GravityEnabled end, function(v) Cfg.GravityEnabled = v end, SubList)
AddSlider("Gravity Value", 10, 500, function() return Cfg.GravityValue end, function(v) Cfg.GravityValue = v end, SubList)

CurrentTab = "COMBAT"
AddSection("AIMBOT")
AddToggle("Enable Aimbot (Hold E)", function() return Cfg.AimEnabled end, function(v) Cfg.AimEnabled = v end)
AddToggle("Visible Only", function() return Cfg.AimVisibleOnly end, function(v) Cfg.AimVisibleOnly = v end)
AddToggle("Auto Fire", function() return Cfg.AimAutoFire end, function(v) Cfg.AimAutoFire = v end)
AddSlider("FOV", 10, 500, function() return Cfg.AimFOV end, function(v) Cfg.AimFOV = v end)
AddSlider("Smoothness", 1, 20, function() return math.floor(Cfg.AimSmooth) end, function(v) Cfg.AimSmooth = v end)
AddSlider("Prediction", 1, 50, function() return math.floor(Cfg.AimPrediction*100) end, function(v) Cfg.AimPrediction = v/100 end)

AddSection("EXPLOITS")
AddToggle("No Spread", function() return Cfg.NoSpreadEnabled end, function(v) Cfg.NoSpreadEnabled = v end)
AddToggle("Rapid Fire", function() return Cfg.RapidFireEnabled end, function(v) Cfg.RapidFireEnabled = v end)
AddToggle("Hitbox Expander", function() return Cfg.HitboxExpanderEnabled end, function(v) Cfg.HitboxExpanderEnabled = v end)
AddSlider("Hitbox Size", 5, 30, function() return Cfg.HitboxSize end, function(v) Cfg.HitboxSize = v end)
AddToggle("Kill Aura", function() return Cfg.KillAuraEnabled end, function(v) Cfg.KillAuraEnabled = v end)
AddSlider("Aura Range", 5, 50, function() return Cfg.KillAuraRange end, function(v) Cfg.KillAuraRange = v end)

CurrentTab = "VISUALS"
AddSection("ESP")
AddToggle("Enable ESP", function() return Cfg.ESPEnabled end, function(v) Cfg.ESPEnabled = v end)
AddToggle("Box", function() return Cfg.ESPBox end, function(v) Cfg.ESPBox = v end)
AddToggle("Name", function() return Cfg.ESPName end, function(v) Cfg.ESPName = v end)
AddToggle("Distance", function() return Cfg.ESPDistance end, function(v) Cfg.ESPDistance = v end)
AddToggle("Health", function() return Cfg.ESPHealth end, function(v) Cfg.ESPHealth = v end)
AddToggle("Skeleton", function() return Cfg.ESPSkeleton end, function(v) Cfg.ESPSkeleton = v end)
AddToggle("Tracers", function() return Cfg.ESPTracers end, function(v) Cfg.ESPTracers = v end)
AddToggle("Head Dot", function() return Cfg.ESPHeadDot end, function(v) Cfg.ESPHeadDot = v end)

AddSection("CHAMS & EXTRAS")
AddToggle("Enemy Chams", function() return Cfg.ChamsEnabled end, function(v) Cfg.ChamsEnabled = v end)
AddToggle("China Hat", function() return Cfg.ChinaHat end, function(v) Cfg.ChinaHat = v end)
AddToggle("Halo", function() return Cfg.HaloEnabled end, function(v) Cfg.HaloEnabled = v end)
AddToggle("FOV Circle", function() return Cfg.FOVCircle end, function(v) Cfg.FOVCircle = v end)

CurrentTab = "MOVEMENT"
AddSection("MOVEMENT")
AddToggle("Speed Hack", function() return Cfg.SpeedEnabled end, function(v) Cfg.SpeedEnabled = v end)
AddSlider("Speed Value", 16, 200, function() return Cfg.SpeedValue end, function(v) Cfg.SpeedValue = v end)
AddToggle("Jump Power", function() return Cfg.JumpEnabled end, function(v) Cfg.JumpEnabled = v end)
AddSlider("Jump Value", 50, 500, function() return Cfg.JumpValue end, function(v) Cfg.JumpValue = v end)
AddToggle("Infinite Jump", function() return Cfg.InfJumpEnabled end, function(v) Cfg.InfJumpEnabled = v end)
AddToggle("Fly (WASD)", function() return Cfg.FlyEnabled end, function(v) Cfg.FlyEnabled = v end)
AddSlider("Fly Speed", 10, 200, function() return Cfg.FlySpeed end, function(v) Cfg.FlySpeed = v end)
AddToggle("Noclip", function() return Cfg.NoclipEnabled end, function(v) Cfg.NoclipEnabled = v end)

CurrentTab = "TROLL"
AddSection("TROLLS")
AddToggle("Spinbot", function() return Cfg.SpinbotEnabled end, function(v) Cfg.SpinbotEnabled = v end)
AddSlider("Spin Speed", 1, 50, function() return Cfg.SpinbotSpeed end, function(v) Cfg.SpinbotSpeed = v end)
AddToggle("Screen Shake", function() return Cfg.ScreenShakeEnabled end, function(v) Cfg.ScreenShakeEnabled = v end)
AddToggle("Fling All", function() return Cfg.FlingAllEnabled end, function(v) Cfg.FlingAllEnabled = v end)
AddToggle("Telekinesis", function() return Cfg.TelekinesisEnabled end, function(v) Cfg.TelekinesisEnabled = v end)
AddSlider("Tele Range", 5, 50, function() return Cfg.TelekinesisRange end, function(v) Cfg.TelekinesisRange = v end)
AddToggle("Emotes (Dance)", function() return Cfg.EmotesEnabled end, function(v) Cfg.EmotesEnabled = v end)
AddToggle("Chat Spam", function() return Cfg.ChatSpamEnabled end, function(v) Cfg.ChatSpamEnabled = v end)

CurrentTab = "WORLD"
AddSection("ENVIRONMENT")
local WorldBtn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.red, BackgroundTransparency = 0.2, BorderSizePixel = 0, Text = "  Ambience Settings  >", TextColor3 = Theme.white, Font = F_Main, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, Pages["WORLD"])
Corner(WorldBtn, 6)
WorldBtn.MouseButton1Click:Connect(function() SubWorld.Visible = not SubWorld.Visible end)
AddToggle("Snow Particles", function() return Cfg.SnowEnabled end, function(v) Cfg.SnowEnabled = v end)

CurrentTab = "MISC"
AddSection("UTILITIES")
AddToggle("Anti-AFK", function() return Cfg.AntiAFKEnabled end, function(v) Cfg.AntiAFKEnabled = v end)
AddButton("Server Hop", Theme.red, function()
    local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, srv in ipairs(Servers.data) do if srv.playing < srv.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP) break end end
end)
AddButton("Rejoin Server", Theme.red, function() TeleportService:Teleport(game.PlaceId, LP) end)
AddButton("PANIC (Disable All)", Theme.red, function()
    for k, v in pairs(Cfg) do if type(v) == "boolean" then Cfg[k] = false end end
    if State.FlyBV then State.FlyBV:Destroy() State.FlyBV = nil end
    local hum = GetHum() if hum then hum.WalkSpeed = 16 hum.JumpPower = 50 end
    Workspace.Gravity = 196.2
    ScreenGui.Enabled = false Blur.Enabled = false
end)

CurrentTab = "COMBAT"

-- ═══ ВИЗУАЛЬНЫЙ ХИТБОКС ═══
task.spawn(function()
    while getgenv().KNIFES_OMNI_LOADED do
        task.wait(0.1)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                local hrp = GetHRP(plr)
                if hrp then
                    local hitbox = hrp:FindFirstChild("KNIFES_VISUAL_HB")
                    if Cfg.HitboxExpanderEnabled then
                        if not hitbox then
                            hitbox = Instance.new("Part")
                            hitbox.Name = "KNIFES_VISUAL_HB"
                            hitbox.Shape = Enum.PartType.Ball
                            hitbox.Size = Vector3.new(Cfg.HitboxSize, Cfg.HitboxSize, Cfg.HitboxSize)
                            hitbox.Material = Enum.Material.Neon
                            hitbox.Color = Color3.fromRGB(255, 0, 0)
                            hitbox.Transparency = 0.5
                            hitbox.CanCollide = false
                            hitbox.Massless = true
                            hitbox.CanQuery = false
                            hitbox.CanTouch = false
                            
                            local stroke = Instance.new("SelectionBox")
                            stroke.Name = "HB_Stroke"
                            stroke.Adornee = hitbox
                            stroke.LineThickness = 0.05
                            stroke.Color3 = Color3.fromRGB(255, 255, 255)
                            stroke.SurfaceTransparency = 0.8
                            stroke.Parent = hitbox

                            local weld = Instance.new("Weld")
                            weld.Part0 = hrp
                            weld.Part1 = hitbox
                            weld.Parent = hitbox
                            
                            hitbox.Parent = hrp
                        else
                            hitbox.Size = Vector3.new(Cfg.HitboxSize, Cfg.HitboxSize, Cfg.HitboxSize)
                        end
                    else
                        if hitbox then hitbox:Destroy() end
                    end
                end
            end
        end
    end
end)

-- ═══ ЛОГИКА ═══
RunService.Heartbeat:Connect(function()
    Lighting.Brightness = Cfg.Brightness
    Lighting.ExposureCompensation = Cfg.Exposure
    Lighting.ClockTime = Cfg.TimeEnabled and Cfg.TimeValue or (Cfg.Nightmode and 0 or 14)
    Lighting.FogEnd = Cfg.NoFog and 100000 or Cfg.FogEnd
    
    if Cfg.Fullbright then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    else
        Lighting.Ambient = Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
    
    if Cfg.GravityEnabled then Workspace.Gravity = Cfg.GravityValue end
    
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity = Cfg.BloomIntensity
    bloom.Size = Cfg.BloomSize
    
    local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
    rays.Intensity = Cfg.SunRaysIntensity
    
    local hum = GetHum()
    if hum then
        if Cfg.SpeedEnabled then hum.WalkSpeed = Cfg.SpeedValue end
        if Cfg.JumpEnabled then hum.JumpPower = Cfg.JumpValue end
        if Cfg.NoclipEnabled then for _, p in ipairs(LP.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end
    
    if Cfg.KillAuraEnabled then
        local myHRP = GetHRP()
        if myHRP then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then local h, hrp = GetHum(p), GetHRP(p) if h and hrp and h.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= Cfg.KillAuraRange then h.Health = 0 end end end end
    end
    
    if Cfg.TelekinesisEnabled then
        local myHRP = GetHRP()
        if myHRP then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then local hrp = GetHRP(p) if hrp and (hrp.Position - myHRP.Position).Magnitude <= Cfg.TelekinesisRange then pcall(function() hrp.CFrame = myHRP.CFrame * CFrame.new(0,3,-2) end) end end end end
    end
    
    if Cfg.FlingAllEnabled then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then local hrp = GetHRP(p) if hrp then pcall(function() hrp:SetNetworkOwner(LP) end) hrp.AssemblyLinearVelocity = Vector3.new(math.random(-2000,2000), 2000, math.random(-2000,2000)) end end end end
end)

if getrawmetatable and setreadonly and hookfunction then
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Cfg.RapidFireEnabled and method == "Activate" and self:IsA("Tool") then
            for i = 1, 3 do oldNamecall(self, ...) end return
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

UIS.JumpRequest:Connect(function() if Cfg.InfJumpEnabled then local h = GetHum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

local ESPGui = Create("ScreenGui", { Name = "ESP", ResetOnSpawn = false }, PARENT)
local SkelGui = Create("ScreenGui", { Name = "Skel", ResetOnSpawn = false }, PARENT)
local TracerGui = Create("ScreenGui", { Name = "Tracer", ResetOnSpawn = false }, PARENT)

local function InitESP(p)
    if p == LP or State.ESPCache[p] then return end
    local hl = Create("Highlight", { Enabled = false }, ESPGui)
    local box = Create("Frame", { BackgroundColor3 = Theme.red, BorderSizePixel = 0, Visible = false }, ESPGui)
    local name = Create("TextLabel", { BackgroundTransparency = 1, TextColor3 = Theme.white, Font = F_Main, TextSize = 11, Visible = false }, ESPGui)
    local dist = Create("TextLabel", { BackgroundTransparency = 1, TextColor3 = Theme.dim, Font = F_Main, TextSize = 10, Visible = false }, ESPGui)
    local hp = Create("Frame", { BackgroundColor3 = Theme.white, BorderSizePixel = 0, Visible = false }, ESPGui)
    local tracer = Create("Frame", { BackgroundColor3 = Theme.red, BorderSizePixel = 0, Visible = false }, TracerGui)
    local headDot = Create("Frame", { BackgroundColor3 = Theme.white, BorderSizePixel = 0, Visible = false }, ESPGui)
    State.ESPCache[p] = {hl=hl, box=box, name=name, dist=dist, hp=hp, tracer=tracer, headDot=headDot}
end
for _, p in ipairs(Players:GetPlayers()) do InitESP(p) end
Players.PlayerAdded:Connect(InitESP)

local Bones = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}

RunService.RenderStepped:Connect(function(dt)
    if Cfg.AimEnabled and UIS:IsKeyDown(Cfg.AimKey) then
        local cam = Workspace.CurrentCamera
        local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        local best, bd = nil, Cfg.AimFOV
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local head, hum, hrp = GetHead(p), GetHum(p), GetHRP(p)
                if head and hum and hum.Health > 0 and hrp then
                    local targetPos = head.Position
                    if Cfg.AimPrediction and Cfg.AimPrediction > 0 then targetPos = targetPos + (Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z) * Cfg.AimPrediction) end
                    local sp, on = cam:WorldToViewportPoint(targetPos)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bd then
                            local visible = true
                            if Cfg.AimVisibleOnly then
                                local rp = RaycastParams.new()
                                rp.FilterDescendantsInstances = {LP.Character, cam}
                                rp.FilterType = Enum.RaycastFilterType.Exclude
                                local ray = Workspace:Raycast(cam.CFrame.Position, (head.Position - cam.CFrame.Position), rp)
                                visible = (ray == nil or ray.Instance:IsDescendantOf(p.Character))
                            end
                            if visible then bd = d best = targetPos end
                        end
                    end
                end
            end
        end
        if best then
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, best), 1 / Cfg.AimSmooth)
            if Cfg.AimAutoFire and tick() - State.LastShot > 0.1 then State.LastShot = tick() if mouse1click then pcall(mouse1click) end end
        end
    end

    for _, l in ipairs(State.SkelLines) do l:Destroy() end State.SkelLines = {}
    local cam = Workspace.CurrentCamera local vp = cam.ViewportSize
    
    for plr, obj in pairs(State.ESPCache) do
        if plr.Character then
            local head, hum, hrp = GetHead(plr), GetHum(plr), GetHRP(plr)
            if head and hum and hrp and hum.Health > 0 then
                obj.hl.Adornee = plr.Character obj.hl.FillColor = Cfg.ChamsFillColor obj.hl.OutlineColor = Theme.white obj.hl.Enabled = Cfg.ChamsEnabled
                local sp, on = cam:WorldToViewportPoint(head.Position)
                if Cfg.ESPEnabled and on and sp.Z > 0 then
                    local d = (hrp.Position - cam.CFrame.Position).Magnitude
                    local h = math.clamp(1000/d, 20, 500) local w = h * 0.5
                    obj.box.Position = UDim2.new(0, sp.X - w/2, 0, sp.Y - h/2) obj.box.Size = UDim2.fromOffset(w, h) obj.box.Visible = Cfg.ESPBox
                    obj.name.Position = UDim2.new(0, sp.X - 50, 0, sp.Y - h/2 - 12) obj.name.Size = UDim2.fromOffset(100, 12) obj.name.Text = plr.Name obj.name.Visible = Cfg.ESPName
                    obj.dist.Position = UDim2.new(0, sp.X - 50, 0, sp.Y - h/2 - 24) obj.dist.Size = UDim2.fromOffset(100, 12) obj.dist.Text = "["..math.floor(d).."m]" obj.dist.Visible = Cfg.ESPDistance
                    obj.hp.Position = UDim2.new(0, sp.X - w/2 - 6, 0, sp.Y - h/2) obj.hp.Size = UDim2.new(0, 2, hum.Health/hum.MaxHealth, 0) obj.hp.Visible = Cfg.ESPHealth
                    obj.headDot.Position = UDim2.new(0, sp.X - 2, 0, sp.Y - h/2 - 4) obj.headDot.Size = UDim2.fromOffset(4, 4) obj.headDot.Visible = Cfg.ESPHeadDot
                    if Cfg.ESPTracers then
                        local origin = Vector2.new(vp.X/2, vp.Y) local dx, dy = sp.X - origin.X, sp.Y - origin.Y
                        obj.tracer.Position = UDim2.fromOffset(origin.X, origin.Y) obj.tracer.Size = UDim2.fromOffset(math.sqrt(dx*dx+dy*dy), 1) obj.tracer.Rotation = math.deg(math.atan2(dy, dx)) obj.tracer.Visible = true
                    else obj.tracer.Visible = false end
                else obj.box.Visible = false obj.name.Visible = false obj.dist.Visible = false obj.hp.Visible = false obj.tracer.Visible = false obj.headDot.Visible = false end
                
                if Cfg.ESPSkeleton and on and hum.RigType == Enum.HumanoidRigType.R15 then
                    for _, b in ipairs(Bones) do
                        local p1, p2 = plr.Character:FindFirstChild(b[1]), plr.Character:FindFirstChild(b[2])
                        if p1 and p2 then
                            local s1, o1 = cam:WorldToViewportPoint(p1.Position) local s2, o2 = cam:WorldToViewportPoint(p2.Position)
                            if o1 and o2 and s1.Z > 0 and s2.Z > 0 then
                                local dx, dy = s2.X - s1.X, s2.Y - s1.Y
                                table.insert(State.SkelLines, Create("Frame", { Size = UDim2.fromOffset(math.sqrt(dx*dx+dy*dy), 1), Position = UDim2.fromOffset(s1.X, s1.Y), Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = Theme.white, BorderSizePixel = 0 }, SkelGui))
                            end
                        end
                    end
                end
            else obj.hl.Enabled = false obj.box.Visible = false obj.name.Visible = false obj.dist.Visible = false obj.hp.Visible = false obj.tracer.Visible = false obj.headDot.Visible = false end
        end
    end
    if Cfg.SpinbotEnabled then State.SpinPhase += dt * Cfg.SpinbotSpeed local hrp = GetHRP() if hrp then hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, State.SpinPhase, 0) end end
    if Cfg.ScreenShakeEnabled then State.ShakeTick += dt * 50 cam.CFrame = cam.CFrame * CFrame.new(math.sin(State.ShakeTick)*0.5, math.cos(State.ShakeTick*1.3)*0.5, 0) end
end)

task.spawn(function()
    while getgenv().KNIFES_OMNI_LOADED do
        task.wait(1)
        local hum = GetHum()
        if hum and hum:FindFirstChildOfClass("Animator") then
            local animator = hum:FindFirstChildOfClass("Animator")
            if Cfg.EmotesEnabled then
                if not State.AnimTrack then State.AnimTrack = animator:LoadAnimation(Create("Animation", {AnimationId = "rbxassetid://507771019"})) end
                if not State.AnimTrack.IsPlaying then State.AnimTrack:Play() end
            elseif State.AnimTrack and State.AnimTrack.IsPlaying then State.AnimTrack:Stop() end
        end
    end
end)

task.spawn(function()
    while getgenv().KNIFES_OMNI_LOADED do
        task.wait(2)
        if Cfg.ChatSpamEnabled then pcall(function() local tcs = game:GetService("TextChatService") if tcs.ChatVersion == Enum.ChatVersion.TextChatService then tcs.TextChannels.RBXGeneral:SendAsync("knifes.wtf on top") end end) end
    end
end)

LP.Idled:Connect(function() if Cfg.AntiAFKEnabled then VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end end)

task.spawn(function()
    while getgenv().KNIFES_OMNI_LOADED do
        task.wait(0.2)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    local hat = head:FindFirstChild("KNIFES_ChinaHat")
                    if Cfg.ChinaHat then
                        if not hat then
                            hat = Instance.new("Part") hat.Name = "KNIFES_ChinaHat" hat.Size = Vector3.new(1, 1, 1) hat.Material = Enum.Material.Neon hat.Color = Color3.fromRGB(255, 60, 60) hat.CanCollide = false hat.Massless = true hat.CanQuery = false
                            local mesh = Instance.new("SpecialMesh") mesh.MeshId = "rbxassetid://1033714" mesh.Scale = Vector3.new(2, 1.5, 2) mesh.Parent = hat
                            local weld = Instance.new("Weld") weld.Part0 = head weld.Part1 = hat weld.C0 = CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.rad(45), 0) weld.Parent = hat
                            hat.Parent = head
                        end
                    elseif hat then hat:Destroy() end
                    
                    local halo = head:FindFirstChild("KNIFES_Halo")
                    if Cfg.HaloEnabled then
                        if not halo then
                            halo = Instance.new("Part") halo.Name = "KNIFES_Halo" halo.Size = Vector3.new(1, 1, 1) halo.Material = Enum.Material.Neon halo.Color = Color3.fromRGB(255, 255, 255) halo.CanCollide = false halo.Massless = true halo.CanQuery = false
                            local mesh = Instance.new("SpecialMesh") mesh.MeshType = Enum.MeshType.FileMesh mesh.MeshId = "rbxassetid://3270017" mesh.Scale = Vector3.new(2, 0.2, 2) mesh.Parent = halo
                            local weld = Instance.new("Weld") weld.Part0 = head weld.Part1 = halo weld.C0 = CFrame.new(0, 1.5, 0) weld.Parent = halo
                            halo.Parent = head
                        end
                    elseif halo then halo:Destroy() end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Cfg.FlyEnabled then
        local hrp = GetHRP()
        if hrp then
            if not State.FlyBV then State.FlyBV = Instance.new("BodyVelocity", hrp) State.FlyBV.MaxForce = Vector3.new(1e5,1e5,1e5) end
            local cam = Workspace.CurrentCamera local move = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then move = move.Unit * Cfg.FlySpeed end
            State.FlyBV.Velocity = move
        end
    elseif State.FlyBV then State.FlyBV:Destroy() State.FlyBV = nil end
end)

local fovGui = Create("ScreenGui", { Name = "FOV", ResetOnSpawn = false, DisplayOrder = 999998 }, PARENT)
local fovCircle = Create("Frame", { Size = UDim2.fromOffset(0,0), Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, BorderSizePixel = 1, BorderColor3 = Color3.fromRGB(255, 255, 255), Visible = false }, fovGui)
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1,0)
RunService.RenderStepped:Connect(function() if Cfg.AimEnabled and Cfg.FOVCircle then fovCircle.Visible = true fovCircle.Size = UDim2.fromOffset(Cfg.AimFOV * 2, Cfg.AimFOV * 2) else fovCircle.Visible = false end end)

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Cfg.MenuKey then
        if MainWin.Visible then
            Tw(MainWin, "Size", UDim2.fromOffset(0,0), 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            Blur.Enabled = false Blur.Size = 0
            task.delay(0.3, function() MainWin.Visible = false end)
        else
            MainWin.Visible = true
            Tw(MainWin, "Size", UDim2.fromOffset(850, 580), 0.4, Enum.EasingStyle.Back)
            Blur.Enabled = true Blur.Size = 15
        end
    end
end)

Pages["COMBAT"].Visible = true
TabBtns["COMBAT"].BackgroundColor3 = Theme.red
TabBtns["COMBAT"].TextColor3 = Theme.white
