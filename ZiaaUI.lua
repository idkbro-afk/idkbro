-- ZiaaUI.lua
local ZiaaUI = {}
ZiaaUI.__index = ZiaaUI

ZiaaUI.Appearance = { Title = "ZiaaUI", Icon = "" }
ZiaaUI.Links      = { Discord = "", GetKey = "" }
ZiaaUI.Storage    = { FileName = "ziaa_key" }
ZiaaUI.Theme = {
    Accent      = Color3.fromRGB(124, 58,  237),
    AccentHover = Color3.fromRGB(139, 92,  246),
    Background  = Color3.fromRGB(13,  10,  20),
    Header      = Color3.fromRGB(20,  15,  32),
    Input       = Color3.fromRGB(24,  18,  38),
    Text        = Color3.fromRGB(220, 210, 240),
    TextDim     = Color3.fromRGB(140, 120, 175),
    Success     = Color3.fromRGB(34,  197, 94),
    Error       = Color3.fromRGB(239, 68,  68),
}
ZiaaUI.Shop       = {}
ZiaaUI._changelog = {}
ZiaaUI._junkie    = nil

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local function tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function shadow(parent, size)
    local s = Instance.new("ImageLabel", parent)
    s.Name = "Shadow"
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.BackgroundTransparency = 1
    s.Position = UDim2.fromScale(0.5, 0.5)
    s.Size = UDim2.new(1, size or 40, 1, size or 40)
    s.ZIndex = parent.ZIndex - 1
    s.Image = "rbxassetid://6014261993"
    s.ImageColor3 = Color3.new(0, 0, 0)
    s.ImageTransparency = 0.45
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(49, 49, 450, 450)
    return s
end

local function corner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.new(1, 1, 1)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.85
    return s
end

local function label(parent, text, size, color, weight, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = size or 14
    l.TextColor3 = color or Color3.new(1, 1, 1)
    l.Font = weight or Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.RichText = true
    if props then for k, v in pairs(props) do l[k] = v end end
    return l
end

local function btn(parent, text, accent, props)
    local b = Instance.new("TextButton", parent)
    b.BackgroundColor3 = accent or Color3.fromRGB(124, 58, 237)
    b.BorderSizePixel = 0
    b.Text = text or "Button"
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    corner(b, 8)
    if props then for k, v in pairs(props) do b[k] = v end end
    b:SetAttribute("OriginalColor", accent)

    b.MouseEnter:Connect(function()
        tween(b, {BackgroundColor3 = ZiaaUI.Theme.AccentHover, Size = UDim2.new(
            b.Size.X.Scale, b.Size.X.Offset,
            b.Size.Y.Scale, b.Size.Y.Offset + 2
        )}, 0.15)
    end)
    b.MouseLeave:Connect(function()
        tween(b, {BackgroundColor3 = b:GetAttribute("OriginalColor") or accent, Size = UDim2.new(
            b.Size.X.Scale, b.Size.X.Offset,
            b.Size.Y.Scale, b.Size.Y.Offset - 2
        )}, 0.15)
    end)
    b.MouseButton1Down:Connect(function()
        tween(b, {BackgroundTransparency = 0.2}, 0.1)
    end)
    b.MouseButton1Up:Connect(function()
        tween(b, {BackgroundTransparency = 0}, 0.1)
    end)
    return b
end

-- ── Particules décoratives ──
local function addParticles(parent, T)
    for i = 1, 8 do
        local dot = Instance.new("Frame", parent)
        dot.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4))
        dot.Position = UDim2.fromScale(math.random(0, 100) / 100, math.random(0, 100) / 100)
        dot.BackgroundColor3 = T.Accent
        dot.BackgroundTransparency = math.random(60, 85) / 100
        dot.BorderSizePixel = 0
        dot.ZIndex = parent.ZIndex
        corner(dot, 99)

        local function animateDot()
            local newY = math.random(0, 100) / 100
            local newX = math.random(0, 100) / 100
            tween(dot, {
                Position = UDim2.fromScale(newX, newY),
                BackgroundTransparency = math.random(50, 90) / 100
            }, math.random(30, 70) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.delay(math.random(3, 7), animateDot)
        end
        task.delay(math.random(0, 20) / 10, animateDot)
    end
end

-- ── Barre de progression animée ──
local function addAccentBar(parent, T)
    local bar = Instance.new("Frame", parent)
    bar.Size = UDim2.new(0, 0, 0, 2)
    bar.Position = UDim2.new(0, 0, 1, -2)
    bar.BackgroundColor3 = T.Accent
    bar.BorderSizePixel = 0
    bar.ZIndex = parent.ZIndex + 1

    local grad = Instance.new("UIGradient", bar)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Accent),
        ColorSequenceKeypoint.new(1, T.AccentHover),
    })

    tween(bar, {Size = UDim2.new(1, 0, 0, 2)}, 0.8, Enum.EasingStyle.Quart)
    return bar
end

local function saveKey(key)
    if writefile then writefile(ZiaaUI.Storage.FileName .. ".txt", key) end
end
local function loadKey()
    if isfile and isfile(ZiaaUI.Storage.FileName .. ".txt") then
        return readfile(ZiaaUI.Storage.FileName .. ".txt")
    end
    return nil
end

function ZiaaUI:AddChangelog(version, date, changes)
    table.insert(self._changelog, {version = version, date = date, changes = changes})
end

-- ════════════════════════════════════════════
--  BUILD UI
-- ════════════════════════════════════════════
function ZiaaUI:Build()
    local T = self.Theme
    local A = self.Appearance

    if game.CoreGui:FindFirstChild("ZiaaHub") then
        game.CoreGui:FindFirstChild("ZiaaHub"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZiaaHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    pcall(function() ScreenGui.Parent = game.CoreGui end)

    local Blur = Instance.new("BlurEffect")
    Blur.Size = 0
    Blur.Parent = game.Lighting

    -- ── Overlay ──
    local Overlay = Instance.new("Frame", ScreenGui)
    Overlay.Size = UDim2.fromScale(1, 1)
    Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.ZIndex = 1

    -- Gradient overlay
    local overlayGrad = Instance.new("UIGradient", Overlay)
    overlayGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 5, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    })
    overlayGrad.Rotation = 135

    -- ── Fenêtre principale ──
    local Win = Instance.new("Frame", ScreenGui)
    Win.Name = "Window"
    Win.AnchorPoint = Vector2.new(0.5, 0.5)
    Win.Position = UDim2.new(0.5, 0, 0.5, 40)
    Win.Size = UDim2.fromOffset(480, 580)
    Win.BackgroundColor3 = T.Background
    Win.BorderSizePixel = 0
    Win.ZIndex = 10
    Win.ClipsDescendants = true
    Win.BackgroundTransparency = 1
    corner(Win, 18)
    stroke(Win, T.Accent, 1.5, 0.55)
    shadow(Win, 70)

    -- Particules dans la fenêtre
    addParticles(Win, T)

    -- Gradient de fond de la fenêtre
    local winGrad = Instance.new("UIGradient", Win)
    winGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Background),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(
            math.clamp(T.Background.R * 255 + 4, 0, 255),
            math.clamp(T.Background.G * 255 + 2, 0, 255),
            math.clamp(T.Background.B * 255 + 8, 0, 255)
        )),
        ColorSequenceKeypoint.new(1, T.Background),
    })
    winGrad.Rotation = 135

    -- Animation entrée
    tween(Overlay, {BackgroundTransparency = 0.5}, 0.5)
    tween(Blur, {Size = 10}, 0.5)
    tween(Win, {
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0
    }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- ── Header ──
    local Header = Instance.new("Frame", Win)
    Header.Size = UDim2.new(1, 0, 0, 72)
    Header.BackgroundColor3 = T.Header
    Header.BorderSizePixel = 0
    Header.ZIndex = 11
    Header.ClipsDescendants = true

    local headerGrad = Instance.new("UIGradient", Header)
    headerGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(
            math.clamp(T.Header.R * 255 + 15, 0, 255),
            math.clamp(T.Header.G * 255 + 8, 0, 255),
            math.clamp(T.Header.B * 255 + 25, 0, 255)
        )),
        ColorSequenceKeypoint.new(1, T.Header),
    })
    headerGrad.Rotation = 90

    -- Barre accent animée en bas du header
    addAccentBar(Header, T)

    -- Lueur accent dans le coin
    local headerGlow = Instance.new("ImageLabel", Header)
    headerGlow.Size = UDim2.fromOffset(200, 200)
    headerGlow.Position = UDim2.new(0, -60, 0, -80)
    headerGlow.BackgroundTransparency = 1
    headerGlow.Image = "rbxassetid://6014261993"
    headerGlow.ImageColor3 = T.Accent
    headerGlow.ImageTransparency = 0.88
    headerGlow.ScaleType = Enum.ScaleType.Slice
    headerGlow.SliceCenter = Rect.new(49, 49, 450, 450)
    headerGlow.ZIndex = 11

    -- Icône frame
    local IconFrame = Instance.new("Frame", Header)
    IconFrame.Size = UDim2.fromOffset(42, 42)
    IconFrame.Position = UDim2.fromOffset(16, 15)
    IconFrame.BackgroundColor3 = T.Accent
    IconFrame.BackgroundTransparency = 0.6
    IconFrame.BorderSizePixel = 0
    IconFrame.ZIndex = 12
    corner(IconFrame, 12)
    stroke(IconFrame, T.Accent, 1, 0.5)

    local IconImg = Instance.new("ImageLabel", IconFrame)
    IconImg.Size = UDim2.fromScale(0.8, 0.8)
    IconImg.AnchorPoint = Vector2.new(0.5, 0.5)
    IconImg.Position = UDim2.fromScale(0.5, 0.5)
    IconImg.BackgroundTransparency = 1
    IconImg.Image = A.Icon or ""
    IconImg.ZIndex = 13

    -- Pulse animation sur l'icône
    task.spawn(function()
        while IconFrame and IconFrame.Parent do
            tween(IconFrame, {BackgroundTransparency = 0.4}, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.2)
            tween(IconFrame, {BackgroundTransparency = 0.75}, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.2)
        end
    end)

    label(Header, A.Title, 20, T.Text, Enum.Font.GothamBold, {
        Position = UDim2.fromOffset(70, 13),
        Size = UDim2.new(1, -150, 0, 26),
        ZIndex = 12
    })
    label(Header, "🔐  Key System  •  v1.0.1", 11, T.TextDim, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(70, 41),
        Size = UDim2.new(1, -150, 0, 16),
        ZIndex = 12
    })

    -- Boutons header
    local function headerBtn(icon, posX, onClick)
        local b = Instance.new("TextButton", Header)
        b.Size = UDim2.fromOffset(30, 30)
        b.Position = UDim2.new(1, posX, 0.5, -15)
        b.BackgroundColor3 = T.Input
        b.BackgroundTransparency = 0.4
        b.Text = icon
        b.TextColor3 = T.TextDim
        b.TextSize = 14
        b.Font = Enum.Font.GothamMedium
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.AutoButtonColor = false
        corner(b, 8)
        stroke(b, T.Accent, 1, 0.8)
        b.MouseEnter:Connect(function()
            tween(b, {BackgroundTransparency = 0, TextColor3 = T.Text}, 0.15)
        end)
        b.MouseLeave:Connect(function()
            tween(b, {BackgroundTransparency = 0.4, TextColor3 = T.TextDim}, 0.15)
        end)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    headerBtn("✕", -14, function()
        tween(Win, {Position = UDim2.new(0.5, 0, 0.5, 40), BackgroundTransparency = 1}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        tween(Overlay, {BackgroundTransparency = 1}, 0.35)
        tween(Blur, {Size = 0}, 0.35)
        task.delay(0.4, function() ScreenGui:Destroy() Blur:Destroy() end)
    end)
    headerBtn("⚙", -50, function() end)

    -- ── Tab Bar ──
    local TabBar = Instance.new("Frame", Win)
    TabBar.Size = UDim2.new(1, -32, 0, 34)
    TabBar.Position = UDim2.fromOffset(16, 80)
    TabBar.BackgroundTransparency = 1
    TabBar.ZIndex = 11

    local TabList = Instance.new("UIListLayout", TabBar)
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.Padding = UDim.new(0, 6)
    TabList.VerticalAlignment = Enum.VerticalAlignment.Center

    local tabNames = {"🔑  Key", "📋  Changelog"}
    if self.Shop and self.Shop.Enabled then table.insert(tabNames, "🛒  Shop") end
    if self.Links.Discord ~= "" then table.insert(tabNames, "💬  Discord") end

    local tabFrames = {}
    local tabBtns   = {}
    local activeTab = 1

    -- ── Contenu ──
    local Content = Instance.new("Frame", Win)
    Content.Size = UDim2.new(1, -32, 1, -128)
    Content.Position = UDim2.fromOffset(16, 122)  -- ✅ CORRIGÉ (une seule parenthèse)
    Content.BackgroundTransparency = 1
    Content.ZIndex = 11
    Content.ClipsDescendants = true

    local function switchTab(idx)
        activeTab = idx
        for i, f in pairs(tabFrames) do
            if i == idx then
                f.Visible = true
                f.BackgroundTransparency = 1
                tween(f, {BackgroundTransparency = 1}, 0.2)
            else
                f.Visible = false
            end
        end
        for i, b in pairs(tabBtns) do
            if i == idx then
                tween(b, {BackgroundColor3 = T.Accent, BackgroundTransparency = 0}, 0.2)
                b.TextColor3 = Color3.new(1, 1, 1)
            else
                tween(b, {BackgroundColor3 = T.Input, BackgroundTransparency = 0.5}, 0.2)
                b.TextColor3 = T.TextDim
            end
        end
    end

    for i, name in ipairs(tabNames) do
        local tb = Instance.new("TextButton", TabBar)
        tb.Size = UDim2.fromOffset(0, 30)
        tb.AutomaticSize = Enum.AutomaticSize.X
        tb.BackgroundColor3 = i == 1 and T.Accent or T.Input
        tb.BackgroundTransparency = i == 1 and 0 or 0.5
        tb.Text = "  " .. name .. "  "
        tb.TextColor3 = i == 1 and Color3.new(1, 1, 1) or T.TextDim
        tb.TextSize = 12
        tb.Font = Enum.Font.GothamMedium
        tb.BorderSizePixel = 0
        tb.ZIndex = 12
        tb.AutoButtonColor = false
        corner(tb, 8)
        if i == 1 then stroke(tb, T.Accent, 1, 0.5) end
        tabBtns[i] = tb

        local f = Instance.new("Frame", Content)
        f.Size = UDim2.fromScale(1, 1)
        f.BackgroundTransparency = 1
        f.Visible = (i == 1)
        f.ZIndex = 11
        tabFrames[i] = f

        local li = i
        tb.MouseButton1Click:Connect(function()
            if name:find("Discord") then
                if setclipboard then setclipboard(self.Links.Discord) end
                -- Notification flash
                local notif = label(Win, "✓ Discord link copied!", 12, T.Success, Enum.Font.GothamMedium, {
                    Position = UDim2.new(0, 0, 1, -30),
                    Size = UDim2.new(1, 0, 0, 20),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 20,
                    BackgroundTransparency = 1
                })
                task.delay(2, function() if notif then notif:Destroy() end end)
                return
            end
            if name:find("Shop") and self.Shop and self.Shop.Link ~= "" then
                if setclipboard then setclipboard(self.Shop.Link) end
            end
            switchTab(li)
        end)
    end

    -- ════════════════════════
    --  TAB 1 : KEY
    -- ════════════════════════
    local KeyTab = tabFrames[1]

    -- Lueur derrière la carte
    local cardGlow = Instance.new("ImageLabel", KeyTab)
    cardGlow.Size = UDim2.fromOffset(300, 300)
    cardGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    cardGlow.Position = UDim2.new(0.5, 0, 0, 120)
    cardGlow.BackgroundTransparency = 1
    cardGlow.Image = "rbxassetid://6014261993"
    cardGlow.ImageColor3 = T.Accent
    cardGlow.ImageTransparency = 0.92
    cardGlow.ScaleType = Enum.ScaleType.Slice
    cardGlow.SliceCenter = Rect.new(49, 49, 450, 450)
    cardGlow.ZIndex = 11

    -- Carte
    local Card = Instance.new("Frame", KeyTab)
    Card.Size = UDim2.new(1, 0, 0, 250)
    Card.Position = UDim2.fromOffset(0, 10)
    Card.BackgroundColor3 = T.Header
    Card.BorderSizePixel = 0
    Card.ZIndex = 12
    corner(Card, 16)
    stroke(Card, T.Accent, 1, 0.65)
    shadow(Card, 30)

    local cardInnerGrad = Instance.new("UIGradient", Card)
    cardInnerGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(
            math.clamp(T.Header.R * 255 + 10, 0, 255),
            math.clamp(T.Header.G * 255 + 5, 0, 255),
            math.clamp(T.Header.B * 255 + 18, 0, 255)
        )),
        ColorSequenceKeypoint.new(1, T.Header),
    })
    cardInnerGrad.Rotation = 135

    -- Icône clé animée
    local keyIconBg = Instance.new("Frame", Card)
    keyIconBg.Size = UDim2.fromOffset(70, 70)
    keyIconBg.Position = UDim2.new(0.5, -35, 0, 18)
    keyIconBg.BackgroundColor3 = T.Accent
    keyIconBg.BackgroundTransparency = 0.75
    keyIconBg.BorderSizePixel = 0
    keyIconBg.ZIndex = 13
    corner(keyIconBg, 18)
    stroke(keyIconBg, T.Accent, 1.5, 0.4)

    local keyIcon = Instance.new("TextLabel", keyIconBg)
    keyIcon.Size = UDim2.fromScale(1, 1)
    keyIcon.BackgroundTransparency = 1
    keyIcon.Text = "🔑"
    keyIcon.TextSize = 32
    keyIcon.Font = Enum.Font.GothamBold
    keyIcon.TextColor3 = Color3.new(1, 1, 1)
    keyIcon.TextXAlignment = Enum.TextXAlignment.Center
    keyIcon.ZIndex = 14

    -- Animation flottante de l'icône
    task.spawn(function()
        while keyIconBg and keyIconBg.Parent do
            tween(keyIconBg, {Position = UDim2.new(0.5, -35, 0, 14)}, 1.5, Enum.EasingStyle.Sine)
            task.wait(1.5)
            tween(keyIconBg, {Position = UDim2.new(0.5, -35, 0, 22)}, 1.5, Enum.EasingStyle.Sine)
            task.wait(1.5)
        end
    end)

    label(Card, A.Title .. " — Key Required", 16, T.Text, Enum.Font.GothamBold, {
        Position = UDim2.fromOffset(0, 100),
        Size = UDim2.new(1, 0, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 13
    })
    label(Card, "Enter your license key to continue", 12, T.TextDim, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(0, 124),
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 13
    })

    -- Séparateur
    local sep = Instance.new("Frame", Card)
    sep.Size = UDim2.new(0.85, 0, 0, 1)
    sep.Position = UDim2.new(0.075, 0, 0, 148)
    sep.BackgroundColor3 = T.Accent
    sep.BackgroundTransparency = 0.8
    sep.BorderSizePixel = 0
    sep.ZIndex = 13

    -- Input
    local InputBox = Instance.new("Frame", Card)
    InputBox.Size = UDim2.new(1, -32, 0, 42)
    InputBox.Position = UDim2.fromOffset(16, 158)
    InputBox.BackgroundColor3 = T.Input
    InputBox.BorderSizePixel = 0
    InputBox.ZIndex = 13
    corner(InputBox, 10)
    stroke(InputBox, T.Accent, 1, 0.65)

    -- Icône dans l'input
    local inputIcon = Instance.new("TextLabel", InputBox)
    inputIcon.Size = UDim2.fromOffset(30, 42)
    inputIcon.BackgroundTransparency = 1
    inputIcon.Text = "🔑"
    inputIcon.TextSize = 14
    inputIcon.Font = Enum.Font.Gotham
    inputIcon.TextColor3 = T.TextDim
    inputIcon.TextXAlignment = Enum.TextXAlignment.Center
    inputIcon.ZIndex = 14

    local KeyInput = Instance.new("TextBox", InputBox)
    KeyInput.Size = UDim2.new(1, -38, 1, 0)
    KeyInput.Position = UDim2.fromOffset(32, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "Paste your key here..."
    KeyInput.PlaceholderColor3 = T.TextDim
    KeyInput.TextColor3 = T.Text
    KeyInput.TextSize = 13
    KeyInput.Font = Enum.Font.GothamMedium
    KeyInput.ClearTextOnFocus = false
    KeyInput.ZIndex = 14

    KeyInput.Focused:Connect(function()
        tween(InputBox, {BackgroundColor3 = Color3.fromRGB(32, 24, 52)}, 0.2)
        tween(sep, {BackgroundTransparency = 0.4}, 0.2)
    end)
    KeyInput.FocusLost:Connect(function()
        tween(InputBox, {BackgroundColor3 = T.Input}, 0.2)
        tween(sep, {BackgroundTransparency = 0.8}, 0.2)
    end)

    -- Boutons
    local BtnRow = Instance.new("Frame", KeyTab)
    BtnRow.Size = UDim2.new(1, 0, 0, 42)
    BtnRow.Position = UDim2.fromOffset(0, 270)
    BtnRow.BackgroundTransparency = 1
    BtnRow.ZIndex = 12

    local BtnLayout = Instance.new("UIListLayout", BtnRow)
    BtnLayout.FillDirection = Enum.FillDirection.Horizontal
    BtnLayout.Padding = UDim.new(0, 10)
    BtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local GetKeyBtn = btn(BtnRow, "🔗  Get Key", T.Input, {
        Size = UDim2.new(0.44, 0, 1, 0),
        BackgroundTransparency = 0.3,
        ZIndex = 12
    })
    stroke(GetKeyBtn, T.Accent, 1, 0.7)

    local SubmitBtn = btn(BtnRow, "✓  Submit Key", T.Accent, {
        Size = UDim2.new(0.56, -10, 1, 0),
        ZIndex = 12
    })

    -- Gradient sur SubmitBtn
    local submitGrad = Instance.new("UIGradient", SubmitBtn)
    submitGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Accent),
        ColorSequenceKeypoint.new(1, T.AccentHover),
    })
    submitGrad.Rotation = 90

    -- Status
    local StatusFrame = Instance.new("Frame", KeyTab)
    StatusFrame.Size = UDim2.new(1, 0, 0, 32)
    StatusFrame.Position = UDim2.fromOffset(0, 322)
    StatusFrame.BackgroundColor3 = T.Input
    StatusFrame.BackgroundTransparency = 1
    StatusFrame.BorderSizePixel = 0
    StatusFrame.ZIndex = 12
    corner(StatusFrame, 8)

    local StatusLbl = label(StatusFrame, "", 12, T.TextDim, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 13
    })

    local function setStatus(text, color, showBg)
        StatusLbl.Text = text
        StatusLbl.TextColor3 = color
        if showBg then
            StatusFrame.BackgroundColor3 = color
            StatusFrame.BackgroundTransparency = 0.88
        else
            StatusFrame.BackgroundTransparency = 1
        end
    end

    -- Clé sauvegardée
    local savedKey = loadKey()
    if savedKey and savedKey ~= "" then
        KeyInput.Text = savedKey
        setStatus("✓  Saved key loaded", T.Success, false)
    end

    GetKeyBtn.MouseButton1Click:Connect(function()
        if self.Links.GetKey ~= "" then
            if setclipboard then setclipboard(self.Links.GetKey) end
            setStatus("📋  Link copied! Open it in your browser.", T.TextDim, false)
        end
    end)

    -- Vérification Junkie
    local function verifyKey(key)
        if not self._junkie then return true end
        local ok, result = pcall(function()
            local url = string.format(
                "https://api.jnkie.net/check?key=%s&service=%s",
                key, tostring(self._junkie.Identifier)
            )
            local res = game:HttpGet(url)
            local data = HttpService:JSONDecode(res)
            return data.valid == true or data.status == "valid" or data.success == true
        end)
        if ok then return result end
        return false
    end

    SubmitBtn.MouseButton1Click:Connect(function()
        local key = KeyInput.Text
        if key == "" then
            setStatus("✗  Please enter a key.", T.Error, true)
            tween(InputBox, {BackgroundColor3 = Color3.fromRGB(40, 18, 18)}, 0.2)
            task.wait(0.5)
            tween(InputBox, {BackgroundColor3 = T.Input}, 0.4)
            return
        end

        SubmitBtn.Text = "⏳  Checking..."
        SubmitBtn.Active = false
        setStatus("🔍  Verifying your key...", T.TextDim, false)

        -- Animation de chargement
        local dots = 0
        local loadAnim = task.spawn(function()
            while SubmitBtn.Text:find("Checking") do
                dots = (dots % 3) + 1
                SubmitBtn.Text = "⏳  Checking" .. string.rep(".", dots)
                task.wait(0.4)
            end
        end)

        task.spawn(function()
            local valid = verifyKey(key)
            task.cancel(loadAnim)

            if valid then
                saveKey(key)
                setStatus("✓  Key accepted! Loading your script...", T.Success, true)
                SubmitBtn.Text = "✓  Accepted!"
                tween(SubmitBtn, {BackgroundColor3 = T.Success}, 0.3)
                submitGrad.Enabled = false

                -- Flash vert
                tween(Card, {BackgroundColor3 = Color3.fromRGB(15, 30, 20)}, 0.3)
                task.wait(0.3)
                tween(Card, {BackgroundColor3 = T.Header}, 0.5)

                task.wait(1.2)
                tween(Win, {Position = UDim2.new(0.5, 0, 0.5, -40), BackgroundTransparency = 1}, 0.45)
                tween(Overlay, {BackgroundTransparency = 1}, 0.45)
                tween(Blur, {Size = 0}, 0.45)
                task.delay(0.5, function()
                    ScreenGui:Destroy()
                    Blur:Destroy()
                    if ZiaaUI.OnSuccess then ZiaaUI.OnSuccess() end
                end)
            else
                setStatus("✗  Invalid key. Check your key and try again.", T.Error, true)
                SubmitBtn.Text = "✓  Submit Key"
                tween(SubmitBtn, {BackgroundColor3 = T.Error}, 0.15)
                tween(Card, {BackgroundColor3 = Color3.fromRGB(30, 12, 12)}, 0.2)
                task.wait(0.4)
                tween(SubmitBtn, {BackgroundColor3 = T.Accent}, 0.35)
                tween(Card, {BackgroundColor3 = T.Header}, 0.4)
                submitGrad.Enabled = true
                SubmitBtn.Active = true
            end
        end)
    end)

    -- ════════════════════════
    --  TAB 2 : CHANGELOG
    -- ════════════════════════
    local CLTab = tabFrames[2]
    local CLScroll = Instance.new("ScrollingFrame", CLTab)
    CLScroll.Size = UDim2.fromScale(1, 1)
    CLScroll.BackgroundTransparency = 1
    CLScroll.BorderSizePixel = 0
    CLScroll.ScrollBarThickness = 3
    CLScroll.ScrollBarImageColor3 = T.Accent
    CLScroll.ZIndex = 12
    CLScroll.CanvasSize = UDim2.fromOffset(0, 0)
    CLScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local CLLayout = Instance.new("UIListLayout", CLScroll)
    CLLayout.Padding = UDim.new(0, 10)
    CLLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local CLPad = Instance.new("UIPadding", CLScroll)
    CLPad.PaddingTop = UDim.new(0, 4)
    CLPad.PaddingBottom = UDim.new(0, 4)

    for idx, entry in ipairs(self._changelog) do
        local clCard = Instance.new("Frame", CLScroll)
        clCard.Size = UDim2.new(1, -4, 0, 0)
        clCard.AutomaticSize = Enum.AutomaticSize.Y
        clCard.BackgroundColor3 = T.Header
        clCard.BorderSizePixel = 0
        clCard.ZIndex = 13
        clCard.LayoutOrder = idx
        corner(clCard, 12)
        stroke(clCard, T.Accent, 1, 0.78)

        local clGrad = Instance.new("UIGradient", clCard)
        clGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(
                math.clamp(T.Header.R * 255 + 8, 0, 255),
                math.clamp(T.Header.G * 255 + 4, 0, 255),
                math.clamp(T.Header.B * 255 + 14, 0, 255)
            )),
            ColorSequenceKeypoint.new(1, T.Header),
        })
        clGrad.Rotation = 135

        local clPad = Instance.new("UIPadding", clCard)
        clPad.PaddingTop = UDim.new(0, 12)
        clPad.PaddingBottom = UDim.new(0, 12)
        clPad.PaddingLeft = UDim.new(0, 14)
        clPad.PaddingRight = UDim.new(0, 14)

        local clInner = Instance.new("UIListLayout", clCard)
        clInner.Padding = UDim.new(0, 5)

        -- Badge version
        local headerRow = Instance.new("Frame", clCard)
        headerRow.Size = UDim2.new(1, 0, 0, 22)
        headerRow.BackgroundTransparency = 1
        headerRow.ZIndex = 14

        local vBadge = Instance.new("Frame", headerRow)
        vBadge.Size = UDim2.fromOffset(0, 20)
        vBadge.AutomaticSize = Enum.AutomaticSize.X
        vBadge.BackgroundColor3 = T.Accent
        vBadge.BackgroundTransparency = 0.7
        vBadge.BorderSizePixel = 0
        vBadge.ZIndex = 14
        corner(vBadge, 6)

        local vPad = Instance.new("UIPadding", vBadge)
        vPad.PaddingLeft = UDim.new(0, 6)
        vPad.PaddingRight = UDim.new(0, 6)

        label(vBadge, "v" .. entry.version, 12, T.Accent, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 15
        })

        label(headerRow, entry.date, 11, T.TextDim, Enum.Font.Gotham, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 14
        })

        for _, change in ipairs(entry.changes) do
            local row = Instance.new("Frame", clCard)
            row.Size = UDim2.new(1, 0, 0, 18)
            row.BackgroundTransparency = 1
            row.ZIndex = 14

            local accentHex = string.format("%02x%02x%02x",
                math.floor(T.Accent.R * 255),
                math.floor(T.Accent.G * 255),
                math.floor(T.Accent.B * 255)
            )
            label(row,
                "<font color='#" .. accentHex .. "'>▸</font>  " .. change,
                12, T.Text, Enum.Font.Gotham, {
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 14
                }
            )
        end
    end

    -- ════════════════════════
    --  TAB 3 : SHOP
    -- ════════════════════════
    local shopTabIdx = nil
    if self.Shop and self.Shop.Enabled then
        shopTabIdx = 3
    end

    if shopTabIdx and tabFrames[shopTabIdx] then
        local ShopTab = tabFrames[shopTabIdx]

        local shopGlow = Instance.new("ImageLabel", ShopTab)
        shopGlow.Size = UDim2.fromOffset(280, 280)
        shopGlow.AnchorPoint = Vector2.new(0.5, 0.5)
        shopGlow.Position = UDim2.new(0.5, 0, 0.3, 0)
        shopGlow.BackgroundTransparency = 1
        shopGlow.Image = "rbxassetid://6014261993"
        shopGlow.ImageColor3 = T.Accent
        shopGlow.ImageTransparency = 0.9
        shopGlow.ScaleType = Enum.ScaleType.Slice
        shopGlow.SliceCenter = Rect.new(49, 49, 450, 450)
        shopGlow.ZIndex = 11

        local sc = Instance.new("Frame", ShopTab)
        sc.Size = UDim2.new(1, 0, 0, 200)
        sc.Position = UDim2.fromOffset(0, 10)
        sc.BackgroundColor3 = T.Header
        sc.BorderSizePixel = 0
        sc.ZIndex = 12
        corner(sc, 16)
        stroke(sc, T.Accent, 1, 0.6)
        shadow(sc, 30)

        local scGrad = Instance.new("UIGradient", sc)
        scGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(
                math.clamp(T.Header.R * 255 + 12, 0, 255),
                math.clamp(T.Header.G * 255 + 6, 0, 255),
                math.clamp(T.Header.B * 255 + 20, 0, 255)
            )),
            ColorSequenceKeypoint.new(1, T.Header),
        })
        scGrad.Rotation = 135

        local shopEmoji = Instance.new("TextLabel", sc)
        shopEmoji.Size = UDim2.fromOffset(56, 56)
        shopEmoji.Position = UDim2.new(0.5, -28, 0, 16)
        shopEmoji.BackgroundColor3 = T.Accent
        shopEmoji.BackgroundTransparency = 0.75
        shopEmoji.Text = "✨"
        shopEmoji.TextSize = 28
        shopEmoji.Font = Enum.Font.GothamBold
        shopEmoji.TextColor3 = Color3.new(1, 1, 1)
        shopEmoji.TextXAlignment = Enum.TextXAlignment.Center
        shopEmoji.BorderSizePixel = 0
        shopEmoji.ZIndex = 13
        corner(shopEmoji, 14)

        label(sc, self.Shop.Title or "Premium", 18, T.Text, Enum.Font.GothamBold, {
            Position = UDim2.fromOffset(0, 84),
            Size = UDim2.new(1, 0, 0, 24),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 13
        })
        label(sc, self.Shop.Subtitle or "", 12, T.TextDim, Enum.Font.Gotham, {
            Position = UDim2.fromOffset(0, 110),
            Size = UDim2.new(1, 0, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 13
        })

        local shopBtn = btn(sc, "🛒  " .. (self.Shop.ButtonText or "Buy Now"), T.Accent, {
            Position = UDim2.new(0.5, -90, 0, 140),
            Size = UDim2.fromOffset(180, 40),
            ZIndex = 13
        })
        local shopBtnGrad = Instance.new("UIGradient", shopBtn)
        shopBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.Accent),
            ColorSequenceKeypoint.new(1, T.AccentHover),
        })
        shopBtnGrad.Rotation = 90

        shopBtn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(self.Shop.Link or "") end
            local notif = label(ShopTab, "✓ Shop link copied!", 12, T.Success, Enum.Font.GothamMedium, {
                Position = UDim2.new(0, 0, 0, 220),
                Size = UDim2.new(1, 0, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 20,
                BackgroundTransparency = 1
            })
            task.delay(2, function() if notif then notif:Destroy() end end)
        end)
    end

    -- ── Draggable ──
    local dragging, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Win.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return ScreenGui
end

-- ════════════════════════
--  LAUNCH
-- ════════════════════════
function ZiaaUI:LaunchJunkie(data)
    self._junkie = data
    self:Build()
end

return ZiaaUI
