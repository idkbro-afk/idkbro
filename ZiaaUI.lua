-- ================================================================
--   ZiaaUI  |  Custom Loader Library  |  v2.0
--   3-panel animated UI  |  JNKIE key system (safe, no auto-kick)
--   Features: particles, ripple, shimmer, pulse, typewriter,
--             notifications, animated progress, sound, theme engine
-- ================================================================

local ZiaaUI       = {}
ZiaaUI.__index     = ZiaaUI

-- ── Services ──────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local SoundService     = game:GetService("SoundService")

local PLAYER = Players.LocalPlayer

-- ================================================================
--   DEFAULT CONFIG
-- ================================================================
ZiaaUI.Appearance = {
    Title       = "Ziaa Hub",
    Subtitle    = "Script Hub",
    Icon        = "rbxassetid://73396715275394",
    Version     = "v1.0.0",
    LoadingText = "Initializing...",
}

ZiaaUI.Links = {
    Discord = "",
    GetKey  = "",
    Website = "",
}

ZiaaUI.Storage = {
    FileName = "ZiaaUI_key",
}

ZiaaUI.Theme = {
    -- Primary accent
    Accent         = Color3.fromRGB(124, 58,  237),
    AccentHover    = Color3.fromRGB(139, 92,  246),
    AccentDim      = Color3.fromRGB(55,  20,  110),
    AccentGlow     = Color3.fromRGB(80,  30,  160),

    -- Backgrounds
    Background     = Color3.fromRGB(13,  10,  20 ),
    Panel          = Color3.fromRGB(17,  13,  27 ),
    PanelAlt       = Color3.fromRGB(21,  16,  33 ),
    Header         = Color3.fromRGB(23,  17,  36 ),
    HeaderAlt      = Color3.fromRGB(28,  20,  44 ),

    -- Borders
    Border         = Color3.fromRGB(55,  35,  95 ),
    BorderHover    = Color3.fromRGB(90,  60,  150),
    BorderDim      = Color3.fromRGB(35,  22,  60 ),

    -- Inputs
    Input          = Color3.fromRGB(24,  18,  40 ),
    InputFocus     = Color3.fromRGB(32,  22,  55 ),
    InputHover     = Color3.fromRGB(28,  20,  46 ),

    -- Text
    Text           = Color3.fromRGB(228, 218, 248),
    TextDim        = Color3.fromRGB(130, 110, 172),
    TextMuted      = Color3.fromRGB(75,  58,  105),
    TextAccent     = Color3.fromRGB(180, 145, 255),

    -- States
    Success        = Color3.fromRGB(34,  197, 94 ),
    SuccessDim     = Color3.fromRGB(20,  100, 55 ),
    Error          = Color3.fromRGB(239, 68,  68 ),
    ErrorDim       = Color3.fromRGB(120, 30,  30 ),
    Warning        = Color3.fromRGB(251, 191, 36 ),
    WarningDim     = Color3.fromRGB(120, 88,  12 ),
    Info           = Color3.fromRGB(56,  189, 248),

    -- Misc
    Online         = Color3.fromRGB(34,  197, 94 ),
    Divider        = Color3.fromRGB(40,  26,  70 ),
    Shadow         = Color3.fromRGB(0,   0,   0  ),
    White          = Color3.new(1, 1, 1),
    Black          = Color3.new(0, 0, 0),
}

ZiaaUI.Shop = {
    Enabled    = false,
    Title      = "Get Premium",
    Subtitle   = "Instant delivery • 24/7 support",
    ButtonText = "Buy",
    Link       = "",
}

ZiaaUI.Changelog = {}
ZiaaUI.Sounds    = { Enabled = true }

-- ================================================================
--   INTERNAL STATE
-- ================================================================
local _gui         = nil
local _keyBox      = nil
local _statusLbl   = nil
local _unlocked    = false
local _junkie      = {}
local _notifStack  = {}
local _connections = {}
local _particles   = {}
local _alive       = true

-- ================================================================
--   SOUND ENGINE
-- ================================================================
local Sounds = {}

local function CreateSound(id, volume, pitch)
    if not ZiaaUI.Sounds.Enabled then return nil end
    local s = Instance.new("Sound")
    s.SoundId  = "rbxassetid://" .. tostring(id)
    s.Volume   = volume or 0.3
    s.PlaybackSpeed = pitch or 1
    s.RollOffMaxDistance = 0
    s.Parent   = SoundService
    return s
end

Sounds.Click   = CreateSound(6042053626, 0.25, 1.2)
Sounds.Success = CreateSound(4590662766, 0.4,  1.0)
Sounds.Error   = CreateSound(5135363755, 0.3,  0.9)
Sounds.Hover   = CreateSound(6042053626, 0.1,  1.8)
Sounds.Notify  = CreateSound(4590662766, 0.2,  1.3)
Sounds.Type    = CreateSound(6042053626, 0.08, 2.0)

local function PlaySound(sound)
    if sound and ZiaaUI.Sounds.Enabled then
        local ok = pcall(function() sound:Play() end)
    end
end

-- ================================================================
--   TWEEN ENGINE
-- ================================================================
local TI = {
    Fast    = TweenInfo.new(0.15, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    Normal  = TweenInfo.new(0.25, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    Slow    = TweenInfo.new(0.4,  Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    Spring  = TweenInfo.new(0.5,  Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    Sine    = TweenInfo.new(0.6,  Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut),
    Elastic = TweenInfo.new(0.7,  Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),
    Bounce  = TweenInfo.new(0.5,  Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    Linear  = TweenInfo.new(0.3,  Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
}

local function tw(obj, goal, info)
    if not obj or not obj.Parent then return end
    local t = TweenService:Create(obj, info or TI.Normal, goal)
    t:Play()
    return t
end

local function twCustom(obj, goal, dur, style, dir)
    local ti = TweenInfo.new(dur or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    return tw(obj, goal, ti)
end

-- ================================================================
--   INSTANCE FACTORY
-- ================================================================
local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(obj, r)
    return mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, obj)
end

local function stroke(obj, col, thick, trans)
    return mk("UIStroke", {
        Color        = col or Color3.new(1,1,1),
        Thickness    = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

local function gradient(obj, c0, c1, rot)
    return mk("UIGradient", {
        Color    = ColorSequence.new(c0, c1),
        Rotation = rot or 90,
    }, obj)
end

local function gradientCS(obj, cs, rot)
    return mk("UIGradient", { Color = cs, Rotation = rot or 90 }, obj)
end

local function padding(obj, l, r, t, b)
    return mk("UIPadding", {
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
    }, obj)
end

local function listLayout(obj, dir, sort, pad)
    return mk("UIListLayout", {
        FillDirection = dir  or Enum.FillDirection.Vertical,
        SortOrder     = sort or Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, pad or 0),
    }, obj)
end

local function textLabel(props, parent)
    local defaults = {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Font                   = Enum.Font.GothamMedium,
        TextSize               = 13,
        TextColor3             = ZiaaUI.Theme.Text,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 15,
        RichText               = true,
    }
    for k, v in pairs(props) do defaults[k] = v end
    return mk("TextLabel", defaults, parent)
end

local function frame(props, parent)
    local defaults = {
        BackgroundColor3 = ZiaaUI.Theme.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }
    for k, v in pairs(props) do defaults[k] = v end
    return mk("Frame", defaults, parent)
end

local function imageLabel(props, parent)
    local defaults = {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 15,
    }
    for k, v in pairs(props) do defaults[k] = v end
    return mk("ImageLabel", defaults, parent)
end

-- ================================================================
--   UTILITY FUNCTIONS
-- ================================================================
local function GetExecutor()
    if identifyexecutor then
        local name, ver = identifyexecutor()
        return name or "Unknown"
    elseif syn           then return "Synapse X"
    elseif KRNL_LOADED   then return "KRNL"
    elseif fluxus        then return "Fluxus"
    elseif getexecutorname then return getexecutorname()
    else                      return "Unknown"
    end
end

local function GetDevice()
    if RunService:IsStudio() then return "Studio" end
    local ua = game:GetService("UserInputService"):GetPlatform()
    if ua == Enum.Platform.Windows then return "Windows PC"
    elseif ua == Enum.Platform.OSX  then return "Mac"
    elseif ua == Enum.Platform.IOS  then return "iOS"
    elseif ua == Enum.Platform.Android then return "Android"
    else return "PC" end
end

local function GetHWID()
    local ok, v = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and tostring(v) or "N/A"
end

local function GetPing()
    -- estimate via tick delta
    local start = tick()
    task.wait()
    return math.floor((tick() - start) * 1000)
end

local function GetFPS()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    return fps
end

local function ReadSavedKey()
    if readfile then
        local ok, v = pcall(readfile, ZiaaUI.Storage.FileName .. ".txt")
        if ok and v and v ~= "" then return v end
    end
    return nil
end

local function WriteSavedKey(k)
    if writefile then
        pcall(writefile, ZiaaUI.Storage.FileName .. ".txt", k)
    end
end

local function DeleteSavedKey()
    if delfile then pcall(delfile, ZiaaUI.Storage.FileName .. ".txt") end
end

local function OpenURL(url)
    if url == "" or not url then return end
    if syn and syn.request then
        pcall(syn.request, { Url = url, Method = "GET" })
    elseif http_request then
        pcall(http_request, { Url = url, Method = "GET" })
    elseif request then
        pcall(request, { Url = url, Method = "GET" })
    end
end

local months = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}

local function FormatTime(t)
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

local function FormatDate(t)
    return string.format("%s %02d, %04d", months[t.month], t.day, t.year)
end

-- ================================================================
--   JNKIE VALIDATION  (NEVER called on load, only on button press)
-- ================================================================
local function JnkieValidate(key)
    local cfg = _junkie
    if not cfg.Service or cfg.Service == "" then
        return false, "Key service not configured."
    end
    if not key or key:match("^%s*$") then
        return false, "Please enter a key."
    end

    local url  = "https://api.jnkie.com/v2/validate"
    local body = HttpService:JSONEncode({
        key        = key,
        service    = cfg.Service,
        identifier = tostring(cfg.Identifier or ""),
        provider   = cfg.Provider or cfg.Service,
        hwid       = GetHWID(),
    })

    local ok, res = pcall(function()
        return HttpService:RequestAsync({
            Url     = url,
            Method  = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"]   = "ZiaaUI/2.0",
            },
            Body = body,
        })
    end)

    if not ok then
        return false, "Network error — check your connection."
    end
    if not res or not res.Body then
        return false, "Empty response from server."
    end

    local data
    local parseOk = pcall(function()
        data = HttpService:JSONDecode(res.Body)
    end)

    if not parseOk or not data then
        return false, "Server returned invalid JSON."
    end

    if data.valid == true or data.success == true then
        return true, data.message or "Access granted!"
    else
        return false, data.message or data.error or "Invalid or expired key."
    end
end

-- ================================================================
--   ANIMATION HELPERS
-- ================================================================

-- Typewriter effect on a TextLabel
local function Typewriter(lbl, text, speed)
    speed = speed or 0.03
    lbl.Text = ""
    for i = 1, #text do
        if not _alive then break end
        lbl.Text = text:sub(1, i)
        PlaySound(Sounds.Type)
        task.wait(speed)
    end
end

-- Shimmer sweep on any frame
local function AddShimmer(parent, zIndex)
    local shimmer = mk("Frame", {
        Size                   = UDim2.new(0, 60, 1, 0),
        Position               = UDim2.new(-0.2, 0, 0, 0),
        BackgroundColor3       = Color3.new(1,1,1),
        BackgroundTransparency = 0.82,
        BorderSizePixel        = 0,
        ZIndex                 = zIndex or 20,
        ClipsDescendants       = false,
    }, parent)
    gradient(shimmer,
        Color3.new(1,1,1):Lerp(Color3.new(1,1,1), 0),
        Color3.new(1,1,1),
        80
    )
    task.spawn(function()
        while shimmer.Parent and _alive do
            shimmer.Position = UDim2.new(-0.2, 0, 0, 0)
            twCustom(shimmer, { Position = UDim2.new(1.2, 0, 0, 0) }, 1.4, Enum.EasingStyle.Quad)
            task.wait(4)
        end
    end)
    return shimmer
end

-- Pulse scale on a frame (uses BackgroundTransparency trick for glow)
local function AddPulse(obj, col, minT, maxT, speed)
    minT  = minT  or 0
    maxT  = maxT  or 0.6
    speed = speed or 0.9
    task.spawn(function()
        while obj.Parent and _alive do
            twCustom(obj, { BackgroundTransparency = maxT }, speed, Enum.EasingStyle.Sine)
            task.wait(speed)
            twCustom(obj, { BackgroundTransparency = minT }, speed, Enum.EasingStyle.Sine)
            task.wait(speed)
        end
    end)
end

-- Ripple effect on click
local function AddRipple(btn, parent, col)
    btn.MouseButton1Down:Connect(function(x, y)
        PlaySound(Sounds.Click)
        local abs = parent.AbsolutePosition
        local rx  = x - abs.X
        local ry  = y - abs.Y
        local rip = mk("Frame", {
            Size                   = UDim2.new(0, 0, 0, 0),
            Position               = UDim2.new(0, rx, 0, ry),
            AnchorPoint            = Vector2.new(0.5, 0.5),
            BackgroundColor3       = col or Color3.new(1,1,1),
            BackgroundTransparency = 0.7,
            BorderSizePixel        = 0,
            ZIndex                 = 30,
        }, parent)
        corner(rip, 100)
        local size  = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
        twCustom(rip, {
            Size                   = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
        }, 0.5, Enum.EasingStyle.Quad)
        task.delay(0.55, function()
            if rip and rip.Parent then rip:Destroy() end
        end)
    end)
end

-- Floating particle system
local function SpawnParticles(parent, count, accent)
    accent = accent or ZiaaUI.Theme.Accent
    for i = 1, count do
        task.spawn(function()
            task.wait(math.random() * 3)
            while parent.Parent and _alive do
                local size = math.random(2, 5)
                local p = mk("Frame", {
                    Size                   = UDim2.new(0, size, 0, size),
                    Position               = UDim2.new(math.random(), 0, 1, 0),
                    BackgroundColor3       = accent,
                    BackgroundTransparency = math.random(50, 80) / 100,
                    BorderSizePixel        = 0,
                    ZIndex                 = 3,
                }, parent)
                corner(p, size)
                local targetX = math.random() * 1
                local dur     = math.random(4, 8)
                twCustom(p, {
                    Position               = UDim2.new(targetX, 0, -0.05, 0),
                    BackgroundTransparency = 1,
                }, dur, Enum.EasingStyle.Sine)
                task.wait(dur)
                if p and p.Parent then p:Destroy() end
                task.wait(math.random(1, 3))
            end
        end)
    end
end

-- Animated accent line (sweeps in on load)
local function AnimatedLine(parent, yPos, col)
    col = col or ZiaaUI.Theme.Accent
    local line = mk("Frame", {
        Size             = UDim2.new(0, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, yPos),
        BackgroundColor3 = col,
        BorderSizePixel  = 0,
        ZIndex           = 16,
    }, parent)
    gradient(line, ZiaaUI.Theme.AccentHover, ZiaaUI.Theme.AccentDim, 0)
    task.delay(0.2, function()
        twCustom(line, { Size = UDim2.new(1, 0, 0, 1) }, 0.6, Enum.EasingStyle.Quad)
    end)
    return line
end

-- Progress bar animation
local function AnimatedProgressBar(parent, xPos, yPos, w, h, col)
    local bg = mk("Frame", {
        Size             = UDim2.new(0, w, 0, h),
        Position         = UDim2.new(0, xPos, 0, yPos),
        BackgroundColor3 = ZiaaUI.Theme.Border,
        BorderSizePixel  = 0,
        ZIndex           = 16,
        ClipsDescendants = true,
    }, parent)
    corner(bg, h // 2)

    local fill = mk("Frame", {
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = col or ZiaaUI.Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 17,
    }, bg)
    corner(fill, h // 2)
    gradient(fill, ZiaaUI.Theme.AccentHover, ZiaaUI.Theme.AccentDim, 0)
    AddShimmer(fill, 18)

    return bg, fill, function(pct)
        twCustom(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.4, Enum.EasingStyle.Quad)
    end
end

-- ================================================================
--   NOTIFICATION SYSTEM
-- ================================================================
local _notifContainer = nil
local _notifCount     = 0

local function CreateNotifContainer(sg)
    _notifContainer = mk("Frame", {
        Name                   = "NotifContainer",
        Size                   = UDim2.new(0, 300, 1, 0),
        Position               = UDim2.new(1, -310, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 100,
    }, sg)
    listLayout(_notifContainer, Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder, 8)
    mk("UIPadding",{ PaddingTop=UDim.new(0,16), PaddingRight=UDim.new(0,0) }, _notifContainer)
end

local function Notify(title, message, notifType, duration)
    if not _notifContainer then return end
    notifType = notifType or "info"
    duration  = duration  or 4

    _notifCount = _notifCount + 1
    local T = ZiaaUI.Theme

    local accentCol = ({
        success = T.Success,
        error   = T.Error,
        warning = T.Warning,
        info    = T.Info,
        key     = T.Accent,
    })[notifType] or T.Accent

    local icon = ({
        success = "✓",
        error   = "✗",
        warning = "⚠",
        info    = "ℹ",
        key     = "⚿",
    })[notifType] or "•"

    local n = mk("Frame", {
        Size             = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 100,
        LayoutOrder      = _notifCount,
        ClipsDescendants = true,
    }, _notifContainer)
    corner(n, 10)
    stroke(n, T.Border, 1)

    -- left accent strip
    local strip = mk("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentCol,
        BorderSizePixel  = 0,
        ZIndex           = 101,
    }, n)
    corner(strip, 2)

    -- icon circle
    local iconCircle = mk("Frame", {
        Size             = UDim2.new(0, 30, 0, 30),
        Position         = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = accentCol,
        BackgroundTransparency = 0.8,
        BorderSizePixel  = 0,
        ZIndex           = 101,
    }, n)
    corner(iconCircle, 15)

    textLabel({
        Text       = icon,
        TextSize   = 14,
        Font       = Enum.Font.GothamBold,
        TextColor3 = accentCol,
        Size       = UDim2.new(1,0,1,0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 102,
    }, iconCircle)

    -- title
    textLabel({
        Text       = title,
        TextSize   = 13,
        Font       = Enum.Font.GothamBold,
        TextColor3 = T.Text,
        Position   = UDim2.new(0, 52, 0, 12),
        Size       = UDim2.new(1, -60, 0, 16),
        ZIndex     = 101,
    }, n)

    -- message
    textLabel({
        Text       = message,
        TextSize   = 11,
        Font       = Enum.Font.Gotham,
        TextColor3 = T.TextDim,
        Position   = UDim2.new(0, 52, 0, 30),
        Size       = UDim2.new(1, -60, 0, 30),
        TextWrapped= true,
        ZIndex     = 101,
    }, n)

    -- progress bar at bottom
    local _, _, setProgress = AnimatedProgressBar(n, 0, 69, 300, 3, accentCol)

    -- slide in
    n.Position = UDim2.new(1.1, 0, 0, 0)
    PlaySound(Sounds.Notify)
    tw(n, { Position = UDim2.new(0, 0, 0, 0) }, TI.Spring)

    -- progress countdown
    task.spawn(function()
        local steps = 60
        for i = steps, 0, -1 do
            if not n.Parent then break end
            setProgress(i / steps)
            task.wait(duration / steps)
        end
        if n and n.Parent then
            tw(n, { Position = UDim2.new(1.1, 0, 0, 0) }, TI.Normal)
            task.wait(0.3)
            n:Destroy()
        end
    end)

    return n
end

ZiaaUI.Notify = Notify

-- ================================================================
--   BUILD GUI
-- ================================================================
local function Build()
    local T = ZiaaUI.Theme
    local A = ZiaaUI.Appearance
    local S = ZiaaUI.Shop

    -- ── ScreenGui ────────────────────────────────────────────────
    local sg = mk("ScreenGui", {
        Name           = "ZiaaUI_v2",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder   = 999,
    })
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok then sg.Parent = PLAYER:WaitForChild("PlayerGui") end
    _gui = sg

    CreateNotifContainer(sg)

    -- ── Backdrop ─────────────────────────────────────────────────
    local backdrop = mk("Frame", {
        Size                   = UDim2.new(1,0,1,0),
        BackgroundColor3       = T.Shadow,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 1,
        ClipsDescendants       = true,
    }, sg)

    -- Radial glow behind window
    local bgGlow = mk("ImageLabel", {
        Size                   = UDim2.new(0, 700, 0, 500),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Image                  = "rbxassetid://6401145371",
        ImageColor3            = T.AccentDim,
        ImageTransparency      = 0.85,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 2,
    }, backdrop)

    SpawnParticles(backdrop, 20, T.Accent)

    -- ── LOADING SCREEN ───────────────────────────────────────────
    local loader = mk("Frame", {
        Size             = UDim2.new(0, 320, 0, 160),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 50,
        ClipsDescendants = true,
    }, sg)
    corner(loader, 14)
    stroke(loader, T.Border, 1.5)
    gradient(loader, T.HeaderAlt, T.Panel, 135)

    -- top glow on loader
    local loaderGlow = mk("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 51,
    }, loader)
    gradient(loaderGlow, T.AccentHover, T.AccentDim, 0)

    -- logo in loader
    imageLabel({
        Size       = UDim2.new(0, 40, 0, 40),
        Position   = UDim2.new(0.5, 0, 0, 20),
        AnchorPoint= Vector2.new(0.5, 0),
        Image      = A.Icon,
        ZIndex     = 51,
    }, loader)

    textLabel({
        Text       = A.Title,
        TextSize   = 18,
        Font       = Enum.Font.GothamBlack,
        TextColor3 = T.Accent,
        Position   = UDim2.new(0.5, 0, 0, 68),
        AnchorPoint= Vector2.new(0.5, 0),
        Size       = UDim2.new(1, -20, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 51,
    }, loader)

    local loadingLbl = textLabel({
        Text       = A.LoadingText,
        TextSize   = 11,
        Font       = Enum.Font.Gotham,
        TextColor3 = T.TextDim,
        Position   = UDim2.new(0.5, 0, 0, 94),
        AnchorPoint= Vector2.new(0.5, 0),
        Size       = UDim2.new(1, -20, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 51,
    }, loader)

    -- Loading bar
    local _, loadFill, setLoadProgress = AnimatedProgressBar(loader, 20, 120, 280, 4, T.Accent)

    -- Animate loading sequence
    loader.Position = UDim2.new(0.5, 0, 0.6, 0)
    loader.BackgroundTransparency = 1
    tw(loader, { Position = UDim2.new(0.5,0,0.5,0), BackgroundTransparency = 0 }, TI.Spring)
    tw(backdrop, { BackgroundTransparency = 0.45 }, TI.Slow)
    tw(bgGlow,   { ImageTransparency = 0.7 }, TI.Slow)

    local loadSteps = {
        { text = "Loading ZiaaUI...",    pct = 0.2 },
        { text = "Fetching user info...", pct = 0.45 },
        { text = "Preparing panels...",  pct = 0.7 },
        { text = "Ready!",               pct = 1.0 },
    }
    for _, step in ipairs(loadSteps) do
        task.wait(0.35)
        if not _alive then break end
        loadingLbl.Text = step.text
        setLoadProgress(step.pct)
    end
    task.wait(0.3)

    -- Dismiss loader
    tw(loader, { Position = UDim2.new(0.5,0,0.42,0), BackgroundTransparency = 1 }, TI.Normal)
    task.wait(0.3)
    loader:Destroy()

    -- ── MAIN WINDOW ──────────────────────────────────────────────
    local WIN_W = 860
    local WIN_H = 440

    local win = mk("Frame", {
        Size             = UDim2.new(0, WIN_W, 0, WIN_H),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Background,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        ClipsDescendants = true,
    }, sg)
    corner(win, 12)
    stroke(win, T.Border, 1.5)

    -- Top glow strip
    local topStrip = mk("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 11,
    }, win)
    gradientCS(topStrip,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0,   T.AccentHover),
            ColorSequenceKeypoint.new(0.5, T.Accent),
            ColorSequenceKeypoint.new(1,   T.AccentDim),
        }), 0)

    -- Slide in from below
    win.Position               = UDim2.new(0.5, 0, 0.6, 0)
    win.BackgroundTransparency = 1
    tw(win, { Position = UDim2.new(0.5,0,0.5,0), BackgroundTransparency = 0 }, TI.Spring)

    -- ── DRAG ─────────────────────────────────────────────────────
    local dragging, dStart, wStart = false, nil, nil
    win.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dStart   = i.Position
            wStart   = win.Position
        end
    end)
    local conn = UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            win.Position = UDim2.new(
                wStart.X.Scale, wStart.X.Offset + d.X,
                wStart.Y.Scale, wStart.Y.Offset + d.Y
            )
        end
    end)
    table.insert(_connections, conn)
    local conn2 = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(_connections, conn2)

    -- ── COLUMN CONTAINER ─────────────────────────────────────────
    local cols = mk("Frame", {
        Size                   = UDim2.new(1,0,1,-2),
        Position               = UDim2.new(0,0,0,2),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 10,
    }, win)
    listLayout(cols, Enum.FillDirection.Horizontal, Enum.SortOrder.LayoutOrder, 1)

    -- ── HELPERS ──────────────────────────────────────────────────
    local function CloseButton(parent, zIdx)
        local btn = mk("TextButton", {
            Text                   = "×",
            TextSize               = 18,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.TextDim,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0, 32, 0, 32),
            Position               = UDim2.new(1, -36, 0.5, 0),
            AnchorPoint            = Vector2.new(0, 0.5),
            ZIndex                 = zIdx or 20,
        }, parent)
        btn.MouseEnter:Connect(function()
            tw(btn, { TextColor3 = T.Error, TextSize = 20 }, TI.Fast)
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, { TextColor3 = T.TextDim, TextSize = 18 }, TI.Fast)
        end)
        btn.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click)
            tw(win, { Position = UDim2.new(0.5,0,0.6,0), BackgroundTransparency = 1 }, TI.Normal)
            tw(backdrop, { BackgroundTransparency = 1 }, TI.Fast)
            task.wait(0.3)
            _alive = false
            for _, c in ipairs(_connections) do c:Disconnect() end
            sg:Destroy()
        end)
        return btn
    end

    local function PanelHeader(parent, title, pulse, layoutH)
        layoutH = layoutH or 44
        local hdr = mk("Frame", {
            Size             = UDim2.new(1, 0, 0, layoutH),
            BackgroundColor3 = T.Header,
            BorderSizePixel  = 0,
            ZIndex           = 15,
        }, parent)
        gradient(hdr, T.HeaderAlt, T.Header, 180)

        -- Animated bottom line
        local bline = mk("Frame", {
            Size             = UDim2.new(0, 0, 0, 1),
            Position         = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 16,
        }, hdr)
        gradient(bline, T.AccentHover, T.AccentDim, 0)
        task.delay(0.15, function()
            twCustom(bline, { Size = UDim2.new(1, 0, 0, 1) }, 0.55, Enum.EasingStyle.Quad)
        end)

        -- Pulse dot
        if pulse then
            local dot = mk("Frame", {
                Size             = UDim2.new(0, 7, 0, 7),
                Position         = UDim2.new(0, 14, 0.5, 0),
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                ZIndex           = 16,
            }, hdr)
            corner(dot, 4)
            AddPulse(dot, T.Accent, 0, 0.65, 1.0)
        end

        textLabel({
            Text       = title,
            TextSize   = 13,
            Font       = Enum.Font.GothamBold,
            TextColor3 = T.Text,
            Position   = UDim2.new(0, pulse and 28 or 14, 0.5, 0),
            AnchorPoint= Vector2.new(0, 0.5),
            Size       = UDim2.new(1, -60, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 16,
        }, hdr)

        CloseButton(hdr, 17)
        return hdr
    end

    local function StyledButton(parent, text, yPos, primary, xOff, wOff)
        xOff = xOff or 14
        wOff = wOff or -28
        local bgCol  = primary and T.Accent or T.Input
        local bg = mk("Frame", {
            Size             = UDim2.new(1, wOff, 0, 40),
            Position         = UDim2.new(0, xOff, 0, yPos),
            BackgroundColor3 = bgCol,
            BorderSizePixel  = 0,
            ZIndex           = 16,
            ClipsDescendants = true,
        }, parent)
        corner(bg, 9)

        if primary then
            gradient(bg, T.AccentHover, T.AccentDim, 160)
            AddShimmer(bg, 17)
        else
            stroke(bg, T.Border, 1)
        end

        local btn = mk("TextButton", {
            Text                   = text,
            TextSize               = 14,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = primary and T.White or T.Text,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1,0,1,0),
            ZIndex                 = 18,
        }, bg)

        AddRipple(btn, bg, primary and Color3.new(1,1,1) or T.Accent)

        btn.MouseEnter:Connect(function()
            PlaySound(Sounds.Hover)
            tw(bg,  { BackgroundColor3 = primary and T.AccentHover or T.InputHover }, TI.Fast)
            tw(btn, { TextColor3 = primary and T.White or T.TextAccent }, TI.Fast)
        end)
        btn.MouseLeave:Connect(function()
            tw(bg,  { BackgroundColor3 = bgCol }, TI.Fast)
            tw(btn, { TextColor3 = primary and T.White or T.Text }, TI.Fast)
        end)
        btn.MouseButton1Down:Connect(function()
            tw(bg,  { Size = UDim2.new(1, wOff-4, 0, 38), Position = UDim2.new(0, xOff+2, 0, yPos+1) }, TI.Fast)
        end)
        btn.MouseButton1Up:Connect(function()
            tw(bg,  { Size = UDim2.new(1, wOff, 0, 40), Position = UDim2.new(0, xOff, 0, yPos) }, TI.Fast)
        end)

        return bg, btn
    end

    local function InfoRow(parent, labelText, value, yPos, valueColor)
        textLabel({
            Text       = labelText,
            TextSize   = 9,
            Font       = Enum.Font.GothamBold,
            TextColor3 = T.TextMuted,
            Position   = UDim2.new(0, 14, 0, yPos),
            Size       = UDim2.new(1, -14, 0, 11),
            ZIndex     = 16,
        }, parent)
        local vLbl = textLabel({
            Text       = value,
            TextSize   = 13,
            Font       = Enum.Font.GothamSemibold,
            TextColor3 = valueColor or T.Text,
            Position   = UDim2.new(0, 14, 0, yPos + 13),
            Size       = UDim2.new(1, -14, 0, 16),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex     = 16,
        }, parent)
        return vLbl
    end

    local function Separator(parent, yPos)
        local s = mk("Frame", {
            Size             = UDim2.new(1, -24, 0, 1),
            Position         = UDim2.new(0, 12, 0, yPos),
            BackgroundColor3 = T.Divider,
            BorderSizePixel  = 0,
            ZIndex           = 15,
        }, parent)
        gradient(s, T.AccentDim, T.Background, 0)
        return s
    end

    local function Badge(parent, text, xPos, yPos, col)
        col = col or T.Accent
        local bg = mk("Frame", {
            Size             = UDim2.new(0, 0, 0, 16),
            Position         = UDim2.new(0, xPos, 0, yPos),
            BackgroundColor3 = col,
            BackgroundTransparency = 0.8,
            AutomaticSize    = Enum.AutomaticSize.X,
            BorderSizePixel  = 0,
            ZIndex           = 17,
        }, parent)
        corner(bg, 4)
        padding(bg, 5, 5, 0, 0)
        textLabel({
            Text       = text,
            TextSize   = 9,
            Font       = Enum.Font.GothamBold,
            TextColor3 = col,
            Size       = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex     = 18,
        }, bg)
        return bg
    end

    -- ================================================================
    --   LEFT PANEL — User Info
    -- ================================================================
    local LEFT_W = 212
    local left   = mk("Frame", {
        Size             = UDim2.new(0, LEFT_W, 1, 0),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        LayoutOrder      = 1,
    }, cols)

    PanelHeader(left, "User Info", true)

    -- Avatar section
    local RING = 74
    local ring = mk("Frame", {
        Size             = UDim2.new(0, RING, 0, RING),
        Position         = UDim2.new(0.5, 0, 0, 54),
        AnchorPoint      = Vector2.new(0.5, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 16,
    }, left)
    corner(ring, RING // 2)
    gradient(ring, T.AccentHover, T.AccentDim, 135)

    -- Spin glow on ring
    task.spawn(function()
        local a = 0
        while ring.Parent and _alive do
            a = (a + 1.2) % 360
            local t = (math.sin(math.rad(a)) + 1) / 2
            ring.BackgroundColor3 = T.Accent:Lerp(T.AccentHover, t)
            task.wait(0.03)
        end
    end)

    local avatarInner = mk("Frame", {
        Size             = UDim2.new(1, -4, 1, -4),
        Position         = UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 17,
    }, ring)
    corner(avatarInner, (RING-4) // 2)

    imageLabel({
        Size       = UDim2.new(1,0,1,0),
        Image      = "https://www.roblox.com/headshot-thumbnail/image?userId="
            .. tostring(PLAYER.UserId) .. "&width=150&height=150&format=png",
        BackgroundColor3 = T.Input,
        ZIndex     = 18,
    }, avatarInner)
    corner(mk("Frame",{ Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=19 }, avatarInner), (RING-4)//2)

    -- Online dot
    local onlineDot = mk("Frame", {
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(0.5, RING//2 - 5, 0, 54 + RING - 10),
        BackgroundColor3 = T.Online,
        BorderSizePixel  = 0,
        ZIndex           = 20,
    }, left)
    corner(onlineDot, 6)
    stroke(onlineDot, T.Panel, 2)
    AddPulse(onlineDot, T.Online, 0, 0.4, 1.2)

    -- Username
    textLabel({
        Text       = "Welcome, " .. PLAYER.Name,
        TextSize   = 13,
        Font       = Enum.Font.GothamBold,
        TextColor3 = T.TextAccent,
        Position   = UDim2.new(0.5, 0, 0, 138),
        AnchorPoint= Vector2.new(0.5, 0),
        Size       = UDim2.new(1, -16, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 16,
    }, left)

    -- Display name below
    textLabel({
        Text       = "@" .. PLAYER.Name,
        TextSize   = 10,
        Font       = Enum.Font.Gotham,
        TextColor3 = T.TextMuted,
        Position   = UDim2.new(0.5, 0, 0, 156),
        AnchorPoint= Vector2.new(0.5, 0),
        Size       = UDim2.new(1, -16, 0, 13),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 16,
    }, left)

    Separator(left, 177)

    -- Executor row
    local execVal = InfoRow(left, "EXECUTOR", GetExecutor(), 185)
    execVal.TextColor3 = T.TextAccent

    Separator(left, 220)

    -- Device row
    InfoRow(left, "DEVICE", GetDevice(), 228)

    Separator(left, 263)

    -- HWID row
    textLabel({
        Text       = "HWID",
        TextSize   = 9,
        Font       = Enum.Font.GothamBold,
        TextColor3 = T.TextMuted,
        Position   = UDim2.new(0, 14, 0, 271),
        Size       = UDim2.new(1, -14, 0, 11),
        ZIndex     = 16,
    }, left)

    textLabel({
        Text       = string.rep("•", 16),
        TextSize   = 13,
        Font       = Enum.Font.Code,
        TextColor3 = T.TextDim,
        Position   = UDim2.new(0, 14, 0, 284),
        Size       = UDim2.new(1, -54, 0, 16),
        ZIndex     = 16,
    }, left)

    local hwid    = GetHWID()
    local copyBg  = mk("Frame", {
        Size             = UDim2.new(0, 32, 0, 26),
        Position         = UDim2.new(1, -44, 0, 278),
        BackgroundColor3 = T.Input,
        BorderSizePixel  = 0,
        ZIndex           = 16,
    }, left)
    corner(copyBg, 7)
    stroke(copyBg, T.Border, 1)

    local copyBtn = mk("TextButton", {
        Text                   = "⎘",
        TextSize               = 15,
        Font                   = Enum.Font.GothamBold,
        TextColor3             = T.TextDim,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1,0,1,0),
        ZIndex                 = 17,
    }, copyBg)
    copyBtn.MouseEnter:Connect(function()
        tw(copyBg, { BackgroundColor3 = T.Border }, TI.Fast)
        tw(copyBtn, { TextColor3 = T.Accent }, TI.Fast)
    end)
    copyBtn.MouseLeave:Connect(function()
        tw(copyBg, { BackgroundColor3 = T.Input }, TI.Fast)
        tw(copyBtn, { TextColor3 = T.TextDim }, TI.Fast)
    end)
    copyBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click)
        if setclipboard then
            setclipboard(hwid)
            tw(copyBg, { BackgroundColor3 = T.SuccessDim }, TI.Fast)
            copyBtn.Text = "✓"
            copyBtn.TextColor3 = T.Success
            task.wait(1.5)
            tw(copyBg, { BackgroundColor3 = T.Input }, TI.Normal)
            copyBtn.Text = "⎘"
            copyBtn.TextColor3 = T.TextDim
        end
    end)

    Separator(left, 313)

    -- Ping & FPS row
    textLabel({
        Text       = "PERFORMANCE",
        TextSize   = 9,
        Font       = Enum.Font.GothamBold,
        TextColor3 = T.TextMuted,
        Position   = UDim2.new(0, 14, 0, 321),
        Size       = UDim2.new(1, -14, 0, 11),
        ZIndex     = 16,
    }, left)

    local pingLbl = textLabel({
        Text       = "Ping: --ms",
        TextSize   = 11,
        Font       = Enum.Font.Code,
        TextColor3 = T.Text,
        Position   = UDim2.new(0, 14, 0, 334),
        Size       = UDim2.new(1, -14, 0, 13),
        ZIndex     = 16,
    }, left)

    local fpsLbl = textLabel({
        Text       = "FPS: --",
        TextSize   = 11,
        Font       = Enum.Font.Code,
        TextColor3 = T.Text,
        Position   = UDim2.new(0, 14, 0, 349),
        Size       = UDim2.new(1, -14, 0, 13),
        ZIndex     = 16,
    }, left)

    Separator(left, 370)

    -- Clock
    local clockLbl = textLabel({
        Text       = "--:--:--",
        TextSize   = 16,
        Font       = Enum.Font.Code,
        TextColor3 = T.Accent,
        Position   = UDim2.new(0, 26, 0, 378),
        Size       = UDim2.new(1, -40, 0, 20),
        ZIndex     = 16,
    }, left)

    local dateLbl = textLabel({
        Text       = "--- --, ----",
        TextSize   = 10,
        Font       = Enum.Font.Gotham,
        TextColor3 = T.TextDim,
        Position   = UDim2.new(0, 26, 0, 400),
        Size       = UDim2.new(1, -40, 0, 13),
        ZIndex     = 16,
    }, left)

    -- Clock icon dot
    local clockDot = mk("Frame", {
        Size             = UDim2.new(0, 8, 0, 8),
        Position         = UDim2.new(0, 12, 0, 385),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 16,
    }, left)
    corner(clockDot, 4)
    AddPulse(clockDot, T.Accent, 0, 0.5, 0.8)

    -- Live update loop
    task.spawn(function()
        while sg.Parent and _alive do
            local t = os.date("*t")
            clockLbl.Text = FormatTime(t)
            dateLbl.Text  = FormatDate(t)
            task.wait(1)
        end
    end)

    -- FPS + Ping update loop
    task.spawn(function()
        while sg.Parent and _alive do
            local fps  = 0
            local ok2, v = pcall(function()
                return math.floor(1 / RunService.RenderStepped:Wait())
            end)
            fps = ok2 and v or 0

            local ping = 0
            local ok3, v2 = pcall(function()
                return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            ping = ok3 and math.floor(v2) or 0

            fpsLbl.Text  = "FPS: " .. tostring(fps)
            pingLbl.Text = "Ping: " .. tostring(ping) .. "ms"

            local fpsCol  = fps  > 50  and T.Success or (fps  > 25  and T.Warning or T.Error)
            local pingCol = ping < 80  and T.Success or (ping < 150 and T.Warning or T.Error)
            fpsLbl.TextColor3  = fpsCol
            pingLbl.TextColor3 = pingCol

            task.wait(2)
        end
    end)

    -- ================================================================
    --   CENTER PANEL — Key System
    -- ================================================================
    local CENTER_W = 436
    local center   = mk("Frame", {
        Size             = UDim2.new(0, CENTER_W, 1, 0),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        LayoutOrder      = 2,
        ClipsDescendants = true,
    }, cols)

    PanelHeader(center, A.Title .. "  –  " .. A.Version, false)

    -- Hub logo
    imageLabel({
        Size       = UDim2.new(0, 32, 0, 32),
        Position   = UDim2.new(0.5, 0, 0, 52),
        AnchorPoint= Vector2.new(0.5, 0),
        Image      = A.Icon,
        ZIndex     = 16,
    }, center)

    -- Title
    textLabel({
        Text       = "Enter your key to continue",
        TextSize   = 16,
        Font       = Enum.Font.GothamBold,
        TextColor3 = T.Accent,
        Position   = UDim2.new(0.5, 0, 0, 90),
        AnchorPoint= Vector2.new(0.5, 0),
        Size       = UDim2.new(1, -28, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 16,
    }, center)

    -- Subtitle
    textLabel({
        Text       = "Your key is linked to your HWID",
        TextSize   = 11,
        Font       = Enum.Font.Gotham,
        TextColor3 = T.TextMuted,
        Position   = UDim2.new(0.5, 0, 0, 113),
        AnchorPoint= Vector2.new(0.5, 0),
        Size       = UDim2.new(1, -28, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 16,
    }, center)

    -- Input wrapper
    local inpWrap = mk("Frame", {
        Size             = UDim2.new(1, -28, 0, 46),
        Position         = UDim2.new(0, 14, 0, 134),
        BackgroundColor3 = T.Input,
        BorderSizePixel  = 0,
        ZIndex           = 16,
        ClipsDescendants = true,
    }, center)
    corner(inpWrap, 10)
    local inpStroke = stroke(inpWrap, T.Border, 1)

    -- Key icon inside input
    textLabel({
        Text       = "⚿",
        TextSize   = 18,
        Font       = Enum.Font.GothamBold,
        TextColor3 = T.TextMuted,
        Position   = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint= Vector2.new(0, 0.5),
        Size       = UDim2.new(0, 42, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 17,
    }, inpWrap)

    _keyBox = mk("TextBox", {
        PlaceholderText        = "Paste your key here...",
        Text                   = "",
        TextSize               = 14,
        Font                   = Enum.Font.GothamMedium,
        TextColor3             = T.Text,
        PlaceholderColor3      = T.TextDim,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, -52, 1, 0),
        Position               = UDim2.new(0, 42, 0, 0),
        ClearTextOnFocus       = false,
        ZIndex                 = 17,
        TextXAlignment         = Enum.TextXAlignment.Left,
    }, inpWrap)

    _keyBox.Focused:Connect(function()
        tw(inpWrap, { BackgroundColor3 = T.InputFocus }, TI.Fast)
        tw(inpStroke, { Color = T.Accent, Thickness = 1.5 }, TI.Fast)
    end)
    _keyBox.FocusLost:Connect(function()
        tw(inpWrap, { BackgroundColor3 = T.Input }, TI.Fast)
        tw(inpStroke, { Color = T.Border, Thickness = 1 }, TI.Fast)
    end)

    -- Status label
    _statusLbl = textLabel({
        Text       = "",
        TextSize   = 11,
        Font       = Enum.Font.Gotham,
        TextColor3 = T.TextDim,
        Position   = UDim2.new(0.5, 0, 0, 188),
        AnchorPoint= Vector2.new(0.5, 0),
        Size       = UDim2.new(1, -28, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex     = 16,
    }, center)

    local function SetStatus(msg, col)
        _statusLbl.TextTransparency = 1
        _statusLbl.Text             = msg
        _statusLbl.TextColor3       = col or T.TextDim
        tw(_statusLbl, { TextTransparency = 0 }, TI.Fast)
    end

    -- Get Key button
    local getKeyBg, getKeyBtn = StyledButton(center, "  Get Key", 208, false)
    getKeyBtn.MouseButton1Click:Connect(function()
        PlaySound(Sounds.Click)
        OpenURL(ZiaaUI.Links.GetKey)
        SetStatus("Opening key page in browser...", T.Info)
    end)

    -- Redeem Key button  ← SAFE: no HTTP on load
    local redeemBg, redeemBtn = StyledButton(center, "  Redeem Key", 256, true)
    redeemBtn.MouseButton1Click:Connect(function()
        if _unlocked then
            SetStatus("Already unlocked!", T.Success)
            PlaySound(Sounds.Success)
            return
        end

        local key = (_keyBox.Text or ""):match("^%s*(.-)%s*$")
        if key == "" then
            PlaySound(Sounds.Error)
            SetStatus("Please enter a key first.", T.Error)
            tw(inpWrap, { BackgroundColor3 = T.ErrorDim }, TI.Fast)
            task.wait(0.6)
            tw(inpWrap, { BackgroundColor3 = T.Input }, TI.Normal)
            return
        end

        redeemBtn.Text     = "Validating..."
        redeemBtn.Active   = false
        SetStatus("Contacting key server...", T.TextDim)

        -- Animated dots
        task.spawn(function()
            local dots = { ".", "..", "...", ".." }
            local i    = 1
            while not _unlocked and redeemBtn.Text:find("Validating") do
                SetStatus("Contacting server" .. dots[i], T.TextDim)
                i = (i % #dots) + 1
                task.wait(0.4)
            end
        end)

        task.spawn(function()
            local valid, msg = JnkieValidate(key)
            redeemBtn.Active = true

            if valid then
                _unlocked = true
                WriteSavedKey(key)
                redeemBtn.Text = "✓  Access Granted"
                tw(redeemBg, { BackgroundColor3 = T.SuccessDim }, TI.Normal)
                gradient(redeemBg, T.Success, T.SuccessDim, 160)
                SetStatus("✓  " .. msg, T.Success)
                PlaySound(Sounds.Success)
                Notify("Access Granted", msg, "success", 5)
            else
                redeemBtn.Text = "  Redeem Key"
                SetStatus("✗  " .. msg, T.Error)
                PlaySound(Sounds.Error)
                tw(inpWrap, { BackgroundColor3 = T.ErrorDim }, TI.Fast)
                task.wait(0.7)
                tw(inpWrap, { BackgroundColor3 = T.Input }, TI.Normal)
                Notify("Access Denied", msg, "error", 4)
            end
        end)
    end)

    -- Icon row
    local ICON_SIZE = 52
    local ICON_GAP  = 10
    local ICON_Y    = 306
    local totalIconW = 3 * ICON_SIZE + 2 * ICON_GAP
    local iconStartX = (CENTER_W - totalIconW) / 2

    local iconDefs = {
        {
            icon   = "👤",
            label  = "Profile",
            action = function()
                SetStatus("roblox.com/users/" .. PLAYER.UserId, T.TextDim)
            end,
        },
        {
            icon   = "💬",
            label  = "Discord",
            action = function()
                OpenURL(ZiaaUI.Links.Discord)
                SetStatus("Opening Discord...", T.Info)
                Notify("Discord", ZiaaUI.Links.Discord, "info", 4)
            end,
        },
        {
            icon   = "↺",
            label  = "Reset",
            action = function()
                PlaySound(Sounds.Click)
                _keyBox.Text       = ""
                _unlocked          = false
                redeemBtn.Text     = "  Redeem Key"
                tw(redeemBg, { BackgroundColor3 = T.Accent }, TI.Normal)
                gradient(redeemBg, T.AccentHover, T.AccentDim, 160)
                SetStatus("Key cleared.", T.TextDim)
            end,
        },
    }

    for i, d in ipairs(iconDefs) do
        local xPos = iconStartX + (i - 1) * (ICON_SIZE + ICON_GAP)
        local ibg  = mk("Frame", {
            Size             = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
            Position         = UDim2.new(0, xPos, 0, ICON_Y),
            BackgroundColor3 = T.Input,
            BorderSizePixel  = 0,
            ZIndex           = 16,
            ClipsDescendants = true,
        }, center)
        corner(ibg, 10)
        stroke(ibg, T.Border, 1)

        local ibtn = mk("TextButton", {
            Text                   = d.icon,
            TextSize               = 20,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.TextDim,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 0, ICON_SIZE - 14),
            Position               = UDim2.new(0, 0, 0, 2),
            ZIndex                 = 17,
        }, ibg)

        textLabel({
            Text       = d.label,
            TextSize   = 8,
            Font       = Enum.Font.Gotham,
            TextColor3 = T.TextMuted,
            Position   = UDim2.new(0, 0, 1, -13),
            Size       = UDim2.new(1, 0, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex     = 17,
        }, ibg)

        AddRipple(ibtn, ibg, T.Accent)

        ibtn.MouseEnter:Connect(function()
            PlaySound(Sounds.Hover)
            tw(ibg,  { BackgroundColor3 = T.InputHover }, TI.Fast)
            tw(ibtn, { TextColor3 = T.TextAccent, TextSize = 22 }, TI.Fast)
        end)
        ibtn.MouseLeave:Connect(function()
            tw(ibg,  { BackgroundColor3 = T.Input }, TI.Fast)
            tw(ibtn, { TextColor3 = T.TextDim, TextSize = 20 }, TI.Fast)
        end)
        ibtn.MouseButton1Down:Connect(function()
            tw(ibg, { Size = UDim2.new(0, ICON_SIZE-4, 0, ICON_SIZE-4), Position = UDim2.new(0, xPos+2, 0, ICON_Y+2) }, TI.Fast)
        end)
        ibtn.MouseButton1Up:Connect(function()
            tw(ibg, { Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE), Position = UDim2.new(0, xPos, 0, ICON_Y) }, TI.Fast)
        end)
        ibtn.MouseButton1Click:Connect(d.action)
    end

    -- Shop bar
    if S.Enabled then
        local shopH  = 56
        local shopBg = mk("Frame", {
            Size             = UDim2.new(1, 0, 0, shopH),
            Position         = UDim2.new(0, 0, 1, -shopH),
            BackgroundColor3 = T.Header,
            BorderSizePixel  = 0,
            ZIndex           = 16,
            ClipsDescendants = true,
        }, center)
        gradient(shopBg, T.HeaderAlt, T.Header, 180)
        mk("Frame", { Size=UDim2.new(1,0,0,1), BackgroundColor3=T.Border, BorderSizePixel=0, ZIndex=17 }, shopBg)

        -- Z badge
        local zbadge = mk("Frame", {
            Size             = UDim2.new(0, 38, 0, 38),
            Position         = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 17,
        }, shopBg)
        corner(zbadge, 9)
        gradient(zbadge, T.AccentHover, T.AccentDim, 135)

        textLabel({
            Text       = "Z",
            TextSize   = 22,
            Font       = Enum.Font.GothamBlack,
            TextColor3 = T.White,
            Size       = UDim2.new(1,0,1,0),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex     = 18,
        }, zbadge)

        textLabel({
            Text       = S.Title,
            TextSize   = 13,
            Font       = Enum.Font.GothamBold,
            TextColor3 = T.Text,
            Position   = UDim2.new(0, 58, 0, 9),
            Size       = UDim2.new(1, -148, 0, 16),
            ZIndex     = 17,
        }, shopBg)

        textLabel({
            Text       = S.Subtitle,
            TextSize   = 10,
            Font       = Enum.Font.Gotham,
            TextColor3 = T.TextMuted,
            Position   = UDim2.new(0, 58, 0, 28),
            Size       = UDim2.new(1, -148, 0, 14),
            ZIndex     = 17,
        }, shopBg)

        local buyBg = mk("Frame", {
            Size             = UDim2.new(0, 78, 0, 34),
            Position         = UDim2.new(1, -92, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 17,
            ClipsDescendants = true,
        }, shopBg)
        corner(buyBg, 9)
        gradient(buyBg, T.AccentHover, T.AccentDim, 160)
        AddShimmer(buyBg, 18)

        local buyBtn = mk("TextButton", {
            Text                   = S.ButtonText,
            TextSize               = 13,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.White,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1,0,1,0),
            ZIndex                 = 19,
        }, buyBg)
        AddRipple(buyBtn, buyBg, T.White)
        buyBtn.MouseEnter:Connect(function()
            tw(buyBg, { BackgroundColor3 = T.AccentHover }, TI.Fast)
        end)
        buyBtn.MouseLeave:Connect(function()
            tw(buyBg, { BackgroundColor3 = T.Accent }, TI.Fast)
        end)
        buyBtn.MouseButton1Click:Connect(function()
            PlaySound(Sounds.Click)
            OpenURL(S.Link)
            Notify("Premium", "Opening shop...", "key", 3)
        end)
    end

    -- ================================================================
    --   RIGHT PANEL — Changelog
    -- ================================================================
    local RIGHT_W = WIN_W - LEFT_W - CENTER_W - 2
    local right   = mk("Frame", {
        Size             = UDim2.new(0, RIGHT_W, 1, 0),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        LayoutOrder      = 3,
    }, cols)

    PanelHeader(right, "Changelog", true)

    -- Version badge
    Badge(right, A.Version, RIGHT_W - 70, 50, T.Accent)

    local scroll = mk("ScrollingFrame", {
        Size                  = UDim2.new(1, 0, 1, -46),
        Position              = UDim2.new(0, 0, 0, 46),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = T.Accent,
        ScrollBarImageTransparency = 0.4,
        CanvasSize             = UDim2.new(0,0,0,0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        ZIndex                 = 14,
        ElasticBehavior        = Enum.ElasticBehavior.WhenScrollable,
    }, right)
    padding(scroll, 12, 12, 10, 10)
    listLayout(scroll, Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder, 0)

    if #ZiaaUI.Changelog == 0 then
        textLabel({
            Text       = "No changelog entries yet.",
            TextSize   = 11,
            Font       = Enum.Font.Gotham,
            TextColor3 = T.TextMuted,
            Size       = UDim2.new(1,0,0,20),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex     = 15,
        }, scroll)
    end

    for idx, entry in ipairs(ZiaaUI.Changelog) do
        local ef = mk("Frame", {
            Size              = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize     = Enum.AutomaticSize.Y,
            BorderSizePixel   = 0,
            ZIndex            = 15,
            LayoutOrder       = idx,
        }, scroll)
        listLayout(ef, Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder, 2)

        -- Header
        local hf = mk("Frame", {
            Size              = UDim2.new(1,0,0,18),
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ZIndex            = 15,
            LayoutOrder       = 1,
        }, ef)

        textLabel({
            Text       = entry.Version,
            TextSize   = 11,
            Font       = Enum.Font.GothamBold,
            TextColor3 = T.Accent,
            Size       = UDim2.new(0, 40, 1, 0),
            ZIndex     = 16,
        }, hf)

        textLabel({
            Text       = "•",
            TextSize   = 10,
            Font       = Enum.Font.GothamBold,
            TextColor3 = T.TextMuted,
            Position   = UDim2.new(0, 44, 0, 0),
            Size       = UDim2.new(0, 12, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex     = 16,
        }, hf)

        textLabel({
            Text       = entry.Date,
            TextSize   = 10,
            Font       = Enum.Font.Gotham,
            TextColor3 = T.TextAccent,
            Position   = UDim2.new(0, 56, 0, 0),
            Size       = UDim2.new(1, -56, 1, 0),
            ZIndex     = 16,
        }, hf)

        -- Items
        for j, item in ipairs(entry.Items) do
            local itemFrame = mk("Frame", {
                Size              = UDim2.new(1,0,0,0),
                BackgroundTransparency = 1,
                AutomaticSize     = Enum.AutomaticSize.Y,
                BorderSizePixel   = 0,
                ZIndex            = 15,
                LayoutOrder       = j + 1,
            }, ef)

            -- Colored bullet
            textLabel({
                Text       = "•",
                TextSize   = 10,
                Font       = Enum.Font.GothamBold,
                TextColor3 = T.AccentDim,
                Size       = UDim2.new(0, 14, 0, 14),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex     = 16,
            }, itemFrame)

            textLabel({
                Text       = item,
                TextSize   = 11,
                Font       = Enum.Font.Gotham,
                TextColor3 = T.TextDim,
                Position   = UDim2.new(0, 14, 0, 0),
                Size       = UDim2.new(1, -14, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped= true,
                ZIndex     = 16,
            }, itemFrame)
        end

        -- Separator
        mk("Frame", {
            Size             = UDim2.new(1,0,0,1),
            BackgroundColor3 = T.Divider,
            BorderSizePixel  = 0,
            ZIndex           = 14,
            LayoutOrder      = 98,
        }, ef)
        mk("Frame", {
            Size              = UDim2.new(1,0,0,7),
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            LayoutOrder       = 99,
        }, ef)
    end
end

-- ================================================================
--   PUBLIC API
-- ================================================================

function ZiaaUI:AddChangelog(version, date, items)
    table.insert(self.Changelog, {
        Version = version or "1.0.0",
        Date    = date    or "Jan 01, 2026",
        Items   = items   or {},
    })
    return self
end

function ZiaaUI:LaunchJunkie(config)
    -- Store config only. No HTTP request is made here.
    -- This prevents the "no script key provided" kick on load.
    _junkie = {
        Service    = config.Service    or "",
        Identifier = config.Identifier or "",
        Provider   = config.Provider   or config.Service or "",
    }

    Build()

    -- Auto-fill saved key (display only, no validation request)
    local saved = ReadSavedKey()
    if saved and saved ~= "" and _keyBox then
        _keyBox.Text = saved
        if _statusLbl then
            _statusLbl.Text       = "Saved key loaded — press Redeem to validate."
            _statusLbl.TextColor3 = ZiaaUI.Theme.TextDim
        end
    end
end

function ZiaaUI:Destroy()
    _alive = false
    for _, c in ipairs(_connections) do c:Disconnect() end
    if _gui then _gui:Destroy() end
end

return ZiaaUI
