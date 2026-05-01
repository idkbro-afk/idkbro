-- ZiaaUI.lua (version corrigée et belle)
local ZiaaUI = {}
ZiaaUI.__index = ZiaaUI

-- Données par défaut
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
ZiaaUI.Shop      = {}
ZiaaUI._changelog = {}
ZiaaUI._junkie   = nil

-- Services
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local Players        = game:GetService("Players")

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
    s.ImageColor3 = Color3.new(0,0,0)
    s.ImageTransparency = 0.5
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(49,49,450,450)
    return s
end

local function corner(parent, r)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.new(1,1,1)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.85
    return s
end

local function label(parent, text, size, color, weight, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = size or 14
    l.TextColor3 = color or Color3.new(1,1,1)
    l.Font = weight or Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.RichText = true
    if props then for k,v in pairs(props) do l[k] = v end end
    return l
end

local function btn(parent, text, accent, props)
    local b = Instance.new("TextButton", parent)
    b.BackgroundColor3 = accent or Color3.fromRGB(124,58,237)
    b.BorderSizePixel = 0
    b.Text = text or "Button"
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    corner(b, 8)
    if props then for k,v in pairs(props) do b[k] = v end end

    b.MouseEnter:Connect(function()
        tween(b, {BackgroundColor3 = ZiaaUI.Theme.AccentHover}, 0.15)
    end)
    b.MouseLeave:Connect(function()
        tween(b, {BackgroundColor3 = b:GetAttribute("OriginalColor") or accent}, 0.15)
    end)
    b:SetAttribute("OriginalColor", accent)
    return b
end

-- Sauvegarde clé
local function saveKey(key)
    if writefile then
        writefile(ZiaaUI.Storage.FileName..".txt", key)
    end
end
local function loadKey()
    if isfile and isfile(ZiaaUI.Storage.FileName..".txt") then
        return readfile(ZiaaUI.Storage.FileName..".txt")
    end
    return nil
end

function ZiaaUI:AddChangelog(version, date, changes)
    table.insert(self._changelog, {version=version, date=date, changes=changes})
end

function ZiaaUI:LaunchJunkie(data)
    self._junkie = data
end

-- ════════════════════════════════════════════
--  BUILD UI
-- ════════════════════════════════════════════
function ZiaaUI:Build()
    local T = self.Theme
    local A = self.Appearance

    -- Nettoyer anciens
    if game.CoreGui:FindFirstChild("ZiaaHub") then
        game.CoreGui:FindFirstChild("ZiaaHub"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZiaaHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    pcall(function() ScreenGui.Parent = game.CoreGui end)

    -- Fond flouté
    local Blur = Instance.new("BlurEffect")
    Blur.Size = 0
    Blur.Parent = game.Lighting

    -- ── Overlay sombre ──
    local Overlay = Instance.new("Frame", ScreenGui)
    Overlay.Size = UDim2.fromScale(1,1)
    Overlay.BackgroundColor3 = Color3.new(0,0,0)
    Overlay.BackgroundTransparency = 1
    Overlay.ZIndex = 1

    -- ── Fenêtre principale ──
    local Win = Instance.new("Frame", ScreenGui)
    Win.Name = "Window"
    Win.AnchorPoint = Vector2.new(0.5, 0.5)
    Win.Position = UDim2.fromScale(0.5, 0.5)
    Win.Size = UDim2.fromOffset(480, 560)
    Win.BackgroundColor3 = T.Background
    Win.BorderSizePixel = 0
    Win.ZIndex = 10
    Win.ClipsDescendants = true
    corner(Win, 16)
    stroke(Win, T.Accent, 1.5, 0.6)
    shadow(Win, 60)

    -- Animation d'entrée
    Win.Position = UDim2.new(0.5, 0, 0.5, 30)
    Win.BackgroundTransparency = 1
    tween(Overlay, {BackgroundTransparency = 0.55}, 0.4)
    tween(Blur, {Size = 8}, 0.4)
    tween(Win, {
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0
    }, 0.45, Enum.EasingStyle.Back)

    -- ── Header ──
    local Header = Instance.new("Frame", Win)
    Header.Size = UDim2.new(1, 0, 0, 70)
    Header.BackgroundColor3 = T.Header
    Header.BorderSizePixel = 0
    Header.ZIndex = 11

    local headerGrad = Instance.new("UIGradient", Header)
    headerGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Header),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(
            T.Header.R*255 + 8 > 255 and 255 or T.Header.R*255 + 8,
            T.Header.G*255 + 5 > 255 and 255 or T.Header.G*255 + 5,
            T.Header.B*255 + 15 > 255 and 255 or T.Header.B*255 + 15
        ))
    })
    headerGrad.Rotation = 90

    -- Séparateur header
    local headerLine = Instance.new("Frame", Header)
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 1, -1)
    headerLine.BackgroundColor3 = T.Accent
    headerLine.BackgroundTransparency = 0.5
    headerLine.BorderSizePixel = 0
    headerLine.ZIndex = 12

    -- Icône
    local IconFrame = Instance.new("Frame", Header)
    IconFrame.Size = UDim2.fromOffset(40, 40)
    IconFrame.Position = UDim2.fromOffset(18, 15)
    IconFrame.BackgroundColor3 = T.Accent
    IconFrame.BackgroundTransparency = 0.7
    IconFrame.BorderSizePixel = 0
    IconFrame.ZIndex = 12
    corner(IconFrame, 10)

    local IconImg = Instance.new("ImageLabel", IconFrame)
    IconImg.Size = UDim2.fromScale(1,1)
    IconImg.BackgroundTransparency = 1
    IconImg.Image = A.Icon or ""
    IconImg.ZIndex = 13

    -- Titre
    local TitleLbl = label(Header, A.Title, 20, T.Text, Enum.Font.GothamBold, {
        Position = UDim2.fromOffset(70, 14),
        Size = UDim2.new(1, -140, 0, 24),
        ZIndex = 12
    })

    local SubLbl = label(Header, "Key System  •  v1.0.1", 11, T.TextDim, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(70, 40),
        Size = UDim2.new(1, -140, 0, 16),
        ZIndex = 12
    })

    -- Boutons header (Discord, Shop, X)
    local function headerBtn(icon, posX, onClick)
        local b = Instance.new("TextButton", Header)
        b.Size = UDim2.fromOffset(30, 30)
        b.Position = UDim2.new(1, posX, 0.5, -15)
        b.BackgroundColor3 = T.Input
        b.BackgroundTransparency = 0.3
        b.Text = icon
        b.TextColor3 = T.TextDim
        b.TextSize = 14
        b.Font = Enum.Font.GothamMedium
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.AutoButtonColor = false
        corner(b, 8)
        b.MouseEnter:Connect(function() tween(b,{BackgroundTransparency=0, TextColor3=T.Text},0.15) end)
        b.MouseLeave:Connect(function() tween(b,{BackgroundTransparency=0.3, TextColor3=T.TextDim},0.15) end)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    headerBtn("✕", -14, function()
        tween(Win, {Position = UDim2.new(0.5,0,0.5,30), BackgroundTransparency=1}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        tween(Overlay, {BackgroundTransparency=1}, 0.3)
        tween(Blur, {Size=0}, 0.3)
        task.delay(0.35, function() ScreenGui:Destroy() Blur:Destroy() end)
    end)
    headerBtn("⚙", -50, function() end) -- placeholder settings

    -- ── Tabs ──
    local TabBar = Instance.new("Frame", Win)
    TabBar.Size = UDim2.new(1, -32, 0, 36)
    TabBar.Position = UDim2.fromOffset(16, 78)
    TabBar.BackgroundTransparency = 1
    TabBar.ZIndex = 11

    local TabList = Instance.new("UIListLayout", TabBar)
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.Padding = UDim.new(0, 6)

    local tabNames = {"🔑  Key", "📋  Changelog"}
    if self.Shop.Enabled then table.insert(tabNames, "🛒  Shop") end
    if self.Links.Discord ~= "" then table.insert(tabNames, "💬  Discord") end

    local tabFrames = {}
    local tabBtns   = {}
    local activeTab = 1

    -- Contenu
    local Content = Instance.new("Frame", Win)
    Content.Size = UDim2.new(1, -32, 1, -130)
    Content.Position = UDim2.fromOffset(16, 122))
    Content.BackgroundTransparency = 1
    Content.ZIndex = 11
    Content.ClipsDescendants = true

    local function switchTab(idx)
        activeTab = idx
        for i, f in pairs(tabFrames) do
            f.Visible = (i == idx)
        end
        for i, b in pairs(tabBtns) do
            if i == idx then
                tween(b, {BackgroundColor3 = T.Accent, BackgroundTransparency = 0}, 0.2)
                b.TextColor3 = Color3.new(1,1,1)
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
        tb.Text = "  "..name.."  "
        tb.TextColor3 = i == 1 and Color3.new(1,1,1) or T.TextDim
        tb.TextSize = 12
        tb.Font = Enum.Font.GothamMedium
        tb.BorderSizePixel = 0
        tb.ZIndex = 12
        tb.AutoButtonColor = false
        corner(tb, 8)
        tabBtns[i] = tb

        local f = Instance.new("Frame", Content)
        f.Size = UDim2.fromScale(1,1)
        f.BackgroundTransparency = 1
        f.Visible = (i == 1)
        f.ZIndex = 11
        tabFrames[i] = f

        local li = i
        tb.MouseButton1Click:Connect(function()
            if name:find("Discord") then
                if setclipboard then setclipboard(self.Links.Discord) end
                return
            end
            if name:find("Shop") then
                if self.Shop.Link ~= "" then
                    if setclipboard then setclipboard(self.Shop.Link) end
                end
            end
            switchTab(li)
        end)
    end

    -- ════════════════════════
    --  TAB 1 : KEY
    -- ════════════════════════
    local KeyTab = tabFrames[1]

    -- Carte centrale
    local Card = Instance.new("Frame", KeyTab)
    Card.Size = UDim2.new(1, 0, 0, 240)
    Card.Position = UDim2.fromOffset(0, 10)
    Card.BackgroundColor3 = T.Header
    Card.BorderSizePixel = 0
    Card.ZIndex = 12
    corner(Card, 14)
    stroke(Card, T.Accent, 1, 0.75)

    -- Icône key
    local keyIcon = Instance.new("TextLabel", Card)
    keyIcon.Size = UDim2.fromOffset(64, 64)
    keyIcon.Position = UDim2.new(0.5, -32, 0, 20)
    keyIcon.BackgroundColor3 = T.Accent
    keyIcon.BackgroundTransparency = 0.8
    keyIcon.Text = "🔑"
    keyIcon.TextSize = 30
    keyIcon.Font = Enum.Font.GothamBold
    keyIcon.TextColor3 = Color3.new(1,1,1)
    keyIcon.TextXAlignment = Enum.TextXAlignment.Center
    keyIcon.BorderSizePixel = 0
    keyIcon.ZIndex = 13
    corner(keyIcon, 16)

    label(Card, A.Title.." — Key Required", 16, T.Text, Enum.Font.GothamBold, {
        Position = UDim2.fromOffset(0, 95),
        Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 13
    })
    label(Card, "Enter your key to continue", 12, T.TextDim, Enum.Font.Gotham, {
        Position = UDim2.fromOffset(0, 116),
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 13
    })

    -- Champ clé
    local InputBox = Instance.new("Frame", Card)
    InputBox.Size = UDim2.new(1, -32, 0, 40)
    InputBox.Position = UDim2.fromOffset(16, 143)
    InputBox.BackgroundColor3 = T.Input
    InputBox.BorderSizePixel = 0
    InputBox.ZIndex = 13
    corner(InputBox, 8)
    stroke(InputBox, T.Accent, 1, 0.7)

    local KeyInput = Instance.new("TextBox", InputBox)
    KeyInput.Size = UDim2.new(1, -16, 1, 0)
    KeyInput.Position = UDim2.fromOffset(12, 0)
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
        tween(InputBox, {BackgroundColor3 = Color3.fromRGB(30,22,48)}, 0.2)
        stroke(InputBox, T.Accent, 1.5, 0.3)
    end)
    KeyInput.FocusLost:Connect(function()
        tween(InputBox, {BackgroundColor3 = T.Input}, 0.2)
    end)

    -- Boutons
    local BtnRow = Instance.new("Frame", KeyTab)
    BtnRow.Size = UDim2.new(1, 0, 0, 40)
    BtnRow.Position = UDim2.fromOffset(0, 260)
    BtnRow.BackgroundTransparency = 1
    BtnRow.ZIndex = 12

    local BtnLayout = Instance.new("UIListLayout", BtnRow)
    BtnLayout.FillDirection = Enum.FillDirection.Horizontal
    BtnLayout.Padding = UDim.new(0, 8)

    local GetKeyBtn = btn(BtnRow, "🔗  Get Key", T.Input, {
        Size = UDim2.new(0.45, 0, 1, 0),
        BackgroundTransparency = 0.4,
        ZIndex = 12
    })
    GetKeyBtn:SetAttribute("OriginalColor", T.Input)

    local SubmitBtn = btn(BtnRow, "✓  Submit Key", T.Accent, {
        Size = UDim2.new(0.55, -8, 1, 0),
        ZIndex = 12
    })

    -- Status
    local StatusLbl = label(KeyTab, "", 12, T.TextDim, Enum.Font.GothamMedium, {
        Position = UDim2.fromOffset(0, 310),
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 12
    })

    -- Clé sauvegardée ?
    local savedKey = loadKey()
    if savedKey and savedKey ~= "" then
        KeyInput.Text = savedKey
    end

    GetKeyBtn.MouseButton1Click:Connect(function()
        if self.Links.GetKey ~= "" then
            if setclipboard then setclipboard(self.Links.GetKey) end
            StatusLbl.TextColor3 = T.TextDim
            StatusLbl.Text = "📋 Link copied! Open in browser."
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
            StatusLbl.TextColor3 = T.Error
            StatusLbl.Text = "✗  Please enter a key."
            return
        end

        SubmitBtn.Text = "⏳  Checking..."
        SubmitBtn.Active = false
        StatusLbl.TextColor3 = T.TextDim
        StatusLbl.Text = "Verifying key..."

        task.spawn(function()
            local valid = verifyKey(key)
            if valid then
                saveKey(key)
                StatusLbl.TextColor3 = T.Success
                StatusLbl.Text = "✓  Key accepted! Loading..."
                SubmitBtn.Text = "✓  Accepted"
                tween(SubmitBtn, {BackgroundColor3 = T.Success}, 0.3)
                task.wait(1.2)

                -- Fermer l'UI
                tween(Win, {Position = UDim2.new(0.5,0,0.5,-30), BackgroundTransparency=1}, 0.4)
                tween(Overlay, {BackgroundTransparency=1}, 0.4)
                tween(Blur, {Size=0}, 0.4)
                task.delay(0.5, function()
                    ScreenGui:Destroy()
                    Blur:Destroy()
                    -- Callback de succès
                    if ZiaaUI.OnSuccess then ZiaaUI.OnSuccess() end
                end)
            else
                StatusLbl.TextColor3 = T.Error
                StatusLbl.Text = "✗  Invalid key. Try again."
                SubmitBtn.Text = "✓  Submit Key"
                tween(SubmitBtn, {BackgroundColor3 = T.Error}, 0.15)
                task.wait(0.5)
                tween(SubmitBtn, {BackgroundColor3 = T.Accent}, 0.3)
                SubmitBtn.Active = true
            end
        end)
    end)

    -- ════════════════════════
    --  TAB 2 : CHANGELOG
    -- ════════════════════════
    local CLTab = tabFrames[2]
    local CLScroll = Instance.new("ScrollingFrame", CLTab)
    CLScroll.Size = UDim2.fromScale(1,1)
    CLScroll.BackgroundTransparency = 1
    CLScroll.BorderSizePixel = 0
    CLScroll.ScrollBarThickness = 3
    CLScroll.ScrollBarImageColor3 = T.Accent
    CLScroll.ZIndex = 12
    CLScroll.CanvasSize = UDim2.fromOffset(0,0)
    CLScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local CLLayout = Instance.new("UIListLayout", CLScroll)
    CLLayout.Padding = UDim.new(0, 10)
    CLLayout.SortOrder = Enum.SortOrder.LayoutOrder

    for idx, entry in ipairs(self._changelog) do
        local clCard = Instance.new("Frame", CLScroll)
        clCard.Size = UDim2.new(1, -4, 0, 0)
        clCard.AutomaticSize = Enum.AutomaticSize.Y
        clCard.BackgroundColor3 = T.Header
        clCard.BorderSizePixel = 0
        clCard.ZIndex = 13
        clCard.LayoutOrder = idx
        corner(clCard, 10)
        stroke(clCard, T.Accent, 1, 0.8)

        local clPad = Instance.new("UIPadding", clCard)
        clPad.PaddingTop = UDim.new(0,10)
        clPad.PaddingBottom = UDim.new(0,10)
        clPad.PaddingLeft = UDim.new(0,12)
        clPad.PaddingRight = UDim.new(0,12)

        local clInner = Instance.new("UIListLayout", clCard)
        clInner.Padding = UDim.new(0,4)

        local headerRow = Instance.new("Frame", clCard)
        headerRow.Size = UDim2.new(1,0,0,20)
        headerRow.BackgroundTransparency = 1
        headerRow.ZIndex = 14

        local vLbl = label(headerRow, "v"..entry.version, 14, T.Accent, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(0.5,1), ZIndex = 14
        })
        local dLbl = label(headerRow, entry.date, 11, T.TextDim, Enum.Font.Gotham, {
            Size = UDim2.fromScale(0.5,1),
            Position = UDim2.fromScale(0.5,0),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 14
        })

        for _, change in ipairs(entry.changes) do
            local row = Instance.new("Frame", clCard)
            row.Size = UDim2.new(1,0,0,18)
            row.BackgroundTransparency = 1
            row.ZIndex = 14
            label(row, "<font color='#"..string.format("%02x%02x%02x",
                math.floor(T.Accent.R*255),
                math.floor(T.Accent.G*255),
                math.floor(T.Accent.B*255))
                .."'>•</font>  "..change,
                12, T.Text, Enum.Font.Gotham, {
                    Size = UDim2.fromScale(1,1),
                    ZIndex = 14
                })
        end
    end

    -- ════════════════════════
    --  TAB 3 : SHOP (si activé)
    -- ════════════════════════
    local shopIdx = self.Shop.Enabled and 3 or nil
    if shopIdx and tabFrames[shopIdx] then
        local ShopTab = tabFrames[shopIdx]
        local sc = Instance.new("Frame", ShopTab)
        sc.Size = UDim2.new(1,0,0,180)
        sc.Position = UDim2.fromOffset(0,10)
        sc.BackgroundColor3 = T.Header
        sc.BorderSizePixel = 0
        sc.ZIndex = 12
        corner(sc, 14)
        stroke(sc, T.Accent, 1, 0.7)

        label(sc, "✨  "..self.Shop.Title, 18, T.Text, Enum.Font.GothamBold, {
            Position = UDim2.fromOffset(0,24),
            Size = UDim2.new(1,0,0,24),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 13
        })
        label(sc, self.Shop.Subtitle, 12, T.TextDim, Enum.Font.Gotham, {
            Position = UDim2.fromOffset(0,52),
            Size = UDim2.new(1,0,0,16),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 13
        })

        local shopBtn = btn(sc, "🛒  "..self.Shop.ButtonText, T.Accent, {
            Position = UDim2.new(0.5,-80,0,90),
            Size = UDim2.fromOffset(160,38),
            ZIndex = 13
        })
        shopBtn.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(self.Shop.Link) end
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
    -- Build AVANT de vérifier quoi que ce soit
    self:Build()
end

return ZiaaUI
