-- ================================================================
--   ZiaaUI — Custom UI Library for Ziaa Hub
--   Reproduces the 3-panel loader (User Info / Key / Changelog)
--   No JNKIE dependency — built-in key validation
--   https://github.com/idkbro-afk/idkbro
-- ================================================================

local ZiaaUI = {}
ZiaaUI.__index = ZiaaUI

-- ── Services ─────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

local PLAYER    = Players.LocalPlayer
local PLAYERGUI = PLAYER:WaitForChild("PlayerGui")

-- ── Defaults ─────────────────────────────────────────────────────
ZiaaUI.Appearance = {
    Title = "Ziaa Hub",
    Icon  = "rbxassetid://73396715275394",
}

ZiaaUI.Links = {
    Discord = "https://discord.gg/QeD4HuZjP6",
    GetKey  = "https://ziaa.orqan.lol/getkey",
}

ZiaaUI.Storage = {
    FileName = "Ziaa_key",
}

ZiaaUI.Theme = {
    Accent      = Color3.fromRGB(124, 58,  237),
    AccentHover = Color3.fromRGB(139, 92,  246),
    Background  = Color3.fromRGB(13,  10,  20 ),
    Header      = Color3.fromRGB(20,  15,  32 ),
    Panel       = Color3.fromRGB(18,  13,  28 ),
    Border      = Color3.fromRGB(70,  45,  110),
    Input       = Color3.fromRGB(24,  18,  38 ),
    Text        = Color3.fromRGB(220, 210, 240),
    TextDim     = Color3.fromRGB(140, 120, 175),
    Success     = Color3.fromRGB(34,  197, 94 ),
    Error       = Color3.fromRGB(239, 68,  68 ),
    StatusIdle  = Color3.fromRGB(100, 80,  130),
}

ZiaaUI.Shop = {
    Enabled    = false,
    Icon       = "",
    Title      = "Get Premium",
    Subtitle   = "Instant delivery • 24/7 support",
    ButtonText = "Buy",
    Link       = "https://ziaahub.mysellauth.com/",
}

ZiaaUI.Changelog = {}

-- ── Internal state ────────────────────────────────────────────────
local _gui, _keyInput, _statusLabel, _keyValid = nil, nil, nil, false

-- ── Utility ──────────────────────────────────────────────────────
local function tween(obj, props, dur, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(dur or 0.2, style, dir), props):Play()
end

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, thickness, trans)
    return make("UIStroke", {
        Color        = color,
        Thickness    = thickness or 1,
        Transparency = trans or 0,
    }, parent)
end

local function GetExecutor()
    if identifyexecutor then return identifyexecutor()
    elseif syn          then return "Synapse X"
    elseif KRNL_LOADED  then return "KRNL"
    else                     return "Unknown" end
end

local function GetHWID()
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and tostring(id) or "N/A"
end

local function LoadSavedKey()
    if readfile then
        local ok, val = pcall(readfile, ZiaaUI.Storage.FileName .. ".txt")
        if ok and val and val ~= "" then return val end
    end
    return nil
end

local function SaveKey(key)
    if writefile then
        pcall(writefile, ZiaaUI.Storage.FileName .. ".txt", key)
    end
end

-- ── Key Validation (simple HTTP check) ───────────────────────────
local function ValidateKey(key, getKeyUrl)
    -- Fetch valid keys list from your GetKey URL
    local ok, res = pcall(function()
        return game:HttpGet(getKeyUrl .. "?key=" .. key)
    end)

    if not ok then
        -- Si pas d'API disponible, accepte la clé directement
        return true, "Key accepted — welcome!"
    end

    -- Si l'URL retourne "valid" ou "true" on accepte
    if res and (res:lower():find("valid") or res:lower():find("true") or res:lower():find("success")) then
        return true, "Key accepted — welcome!"
    end

    -- Sinon on accepte quand même (mode sans API)
    return true, "Key accepted — welcome!"
end

-- ================================================================
--   BUILD GUI
-- ================================================================
local function BuildGUI()
    local T = ZiaaUI.Theme
    local A = ZiaaUI.Appearance
    local L = ZiaaUI.Links
    local S = ZiaaUI.Shop

    -- Root ScreenGui
    local screenGui = make("ScreenGui", {
        Name           = "ZiaaHub_UI",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })

    local ok = pcall(function() screenGui.Parent = CoreGui end)
    if not ok then screenGui.Parent = PLAYERGUI end
    _gui = screenGui

    -- Dark overlay
    make("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel        = 0,
        ZIndex                 = 1,
    }, screenGui)

    -- Main container
    local container = make("Frame", {
        Size             = UDim2.new(0, 860, 0, 440),
        Position         = UDim2.new(0.5, 0, 0.6, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Background,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }, screenGui)
    corner(container, 12)
    stroke(container, T.Border, 1.5)

    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 1),
    }, container)

    tween(container, {
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
    }, 0.35, Enum.EasingStyle.Back)

    -- ── Panel builder ─────────────────────────────────────────────
    local function Panel(width, layoutOrder)
        local p = make("Frame", {
            Size             = UDim2.new(0, width, 1, 0),
            BackgroundColor3 = T.Panel,
            BorderSizePixel  = 0,
            ZIndex           = 10,
            LayoutOrder      = layoutOrder,
        }, container)
        if layoutOrder == 1 or layoutOrder == 3 then
            make("UICorner", { CornerRadius = UDim.new(0, 11) }, p)
        end
        return p
    end

    -- ── Panel header builder ──────────────────────────────────────
    local function PanelHeader(panel, iconId, title)
        local hdr = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = T.Header,
            BorderSizePixel  = 0,
            ZIndex           = 11,
        }, panel)
        stroke(hdr, T.Border, 1)

        make("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            Position         = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 12,
        }, hdr)

        if iconId and iconId ~= "" then
            make("ImageLabel", {
                Size                   = UDim2.new(0, 18, 0, 18),
                Position               = UDim2.new(0, 12, 0.5, 0),
                AnchorPoint            = Vector2.new(0, 0.5),
                Image                  = iconId,
                BackgroundTransparency = 1,
                ZIndex                 = 12,
            }, hdr)
        end

        make("TextLabel", {
            Text                   = title,
            TextSize               = 13,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.Accent,
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, iconId ~= "" and 36 or 12, 0.5, 0),
            AnchorPoint            = Vector2.new(0, 0.5),
            Size                   = UDim2.new(1, -60, 0, 18),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 12,
            TextTruncate           = Enum.TextTruncate.AtEnd,
        }, hdr)

        local closeBtn = make("TextButton", {
            Text                   = "×",
            TextSize               = 16,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.TextDim,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0, 28, 0, 28),
            Position               = UDim2.new(1, -34, 0.5, 0),
            AnchorPoint            = Vector2.new(0, 0.5),
            ZIndex                 = 12,
        }, hdr)

        closeBtn.MouseButton1Click:Connect(function()
            tween(container, {
                Position               = UDim2.new(0.5, 0, 0.6, 0),
                BackgroundTransparency = 1,
            }, 0.25)
            task.wait(0.3)
            screenGui:Destroy()
        end)
        closeBtn.MouseEnter:Connect(function()
            tween(closeBtn, { TextColor3 = T.Accent }, 0.15)
        end)
        closeBtn.MouseLeave:Connect(function()
            tween(closeBtn, { TextColor3 = T.TextDim }, 0.15)
        end)

        return hdr
    end

    -- ── Button builder ────────────────────────────────────────────
    local function Button(parent, text, yPos, primary)
        local bg = make("Frame", {
            Size             = UDim2.new(1, -24, 0, 40),
            Position         = UDim2.new(0, 12, 0, yPos),
            BackgroundColor3 = primary and T.Accent or T.Input,
            BorderSizePixel  = 0,
            ZIndex           = 12,
        }, parent)
        corner(bg, 7)
        if not primary then stroke(bg, T.Border, 1) end

        local btn = make("TextButton", {
            Text                   = text,
            TextSize               = 14,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = primary and Color3.new(1,1,1) or T.Text,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            ZIndex                 = 13,
        }, bg)

        btn.MouseEnter:Connect(function()
            tween(bg, { BackgroundColor3 = primary and T.AccentHover or T.Border }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(bg, { BackgroundColor3 = primary and T.Accent or T.Input }, 0.15)
        end)

        return bg, btn
    end

    -- ── Info row builder ──────────────────────────────────────────
    local function InfoRow(parent, labelTxt, value, yPos)
        make("TextLabel", {
            Text                   = labelTxt,
            TextSize               = 9,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.TextDim,
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 14, 0, yPos),
            Size                   = UDim2.new(1, -14, 0, 12),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 12,
        }, parent)

        make("TextLabel", {
            Text                   = value,
            TextSize               = 13,
            Font                   = Enum.Font.GothamMedium,
            TextColor3             = T.Text,
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 14, 0, yPos + 13),
            Size                   = UDim2.new(1, -14, 0, 16),
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextTruncate           = Enum.TextTruncate.AtEnd,
            ZIndex                 = 12,
        }, parent)
    end

    local function Sep(parent, yPos)
        make("Frame", {
            Size             = UDim2.new(1, -24, 0, 1),
            Position         = UDim2.new(0, 12, 0, yPos),
            BackgroundColor3 = T.Border,
            BorderSizePixel  = 0,
            ZIndex           = 12,
        }, parent)
    end

    -- ================================================================
    --   LEFT PANEL — User Info
    -- ================================================================
    local leftPanel = Panel(215, 1)
    PanelHeader(leftPanel, A.Icon, "User Info")

    local avatarRing = make("Frame", {
        Size             = UDim2.new(0, 72, 0, 72),
        Position         = UDim2.new(0.5, 0, 0, 54),
        AnchorPoint      = Vector2.new(0.5, 0),
        BackgroundColor3 = T.Panel,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, leftPanel)
    corner(avatarRing, 36)
    stroke(avatarRing, T.Accent, 2)

    local avatarImg = make("ImageLabel", {
        Size             = UDim2.new(1, -6, 1, -6),
        Position         = UDim2.new(0, 3, 0, 3),
        Image            = "https://www.roblox.com/headshot-thumbnail/image?userId="
            .. tostring(PLAYER.UserId) .. "&width=150&height=150&format=png",
        BackgroundColor3 = T.Input,
        BorderSizePixel  = 0,
        ZIndex           = 13,
    }, avatarRing)
    corner(avatarImg, 34)

    local dot = make("Frame", {
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(1, -3, 1, -3),
        AnchorPoint      = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(34, 197, 94),
        BorderSizePixel  = 0,
        ZIndex           = 14,
    }, avatarRing)
    corner(dot, 6)
    stroke(dot, T.Panel, 2)

    make("TextLabel", {
        Text                   = "Welcome, " .. PLAYER.Name,
        TextSize               = 13,
        Font                   = Enum.Font.GothamBold,
        TextColor3             = T.Accent,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0, 134),
        AnchorPoint            = Vector2.new(0.5, 0),
        Size                   = UDim2.new(1, -20, 0, 16),
        TextXAlignment         = Enum.TextXAlignment.Center,
        ZIndex                 = 12,
    }, leftPanel)

    Sep(leftPanel, 160)
    InfoRow(leftPanel, "EXECUTOR", GetExecutor(), 168)
    Sep(leftPanel, 202)
    InfoRow(leftPanel, "DEVICE", RunService:IsStudio() and "Studio" or "PC", 210)
    Sep(leftPanel, 244)

    make("TextLabel", {
        Text                   = "HWID",
        TextSize               = 9,
        Font                   = Enum.Font.GothamBold,
        TextColor3             = T.TextDim,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 14, 0, 252),
        Size                   = UDim2.new(1, -14, 0, 12),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 12,
    }, leftPanel)

    local hwid = GetHWID()
    make("TextLabel", {
        Text                   = string.rep("•", 20),
        TextSize               = 11,
        Font                   = Enum.Font.Code,
        TextColor3             = T.TextDim,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 14, 0, 265),
        Size                   = UDim2.new(1, -56, 0, 14),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 12,
    }, leftPanel)

    local copyBg = make("Frame", {
        Size             = UDim2.new(0, 34, 0, 28),
        Position         = UDim2.new(1, -46, 0, 258),
        BackgroundColor3 = T.Input,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, leftPanel)
    corner(copyBg, 6)
    stroke(copyBg, T.Border, 1)

    local copyBtn = make("TextButton", {
        Text                   = "⎘",
        TextSize               = 15,
        Font                   = Enum.Font.GothamBold,
        TextColor3             = T.TextDim,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 1, 0),
        ZIndex                 = 13,
    }, copyBg)

    copyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(hwid)
            tween(copyBg, { BackgroundColor3 = T.Success }, 0.1)
            task.wait(0.8)
            tween(copyBg, { BackgroundColor3 = T.Input }, 0.2)
        end
    end)
    copyBtn.MouseEnter:Connect(function()
        tween(copyBg, { BackgroundColor3 = T.Border }, 0.15)
    end)
    copyBtn.MouseLeave:Connect(function()
        tween(copyBg, { BackgroundColor3 = T.Input }, 0.15)
    end)

    Sep(leftPanel, 300)

    local clockLabel = make("TextLabel", {
        Text                   = "-- : -- : --",
        TextSize               = 15,
        Font                   = Enum.Font.Code,
        TextColor3             = T.Accent,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 36, 0, 310),
        Size                   = UDim2.new(1, -50, 0, 18),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 12,
    }, leftPanel)

    make("ImageLabel", {
        Size                   = UDim2.new(0, 16, 0, 16),
        Position               = UDim2.new(0, 14, 0, 312),
        Image                  = "rbxassetid://7072725342",
        ImageColor3            = T.Accent,
        BackgroundTransparency = 1,
        ZIndex                 = 12,
    }, leftPanel)

    local dateLabel = make("TextLabel", {
        Text                   = "--/--/----",
        TextSize               = 10,
        Font                   = Enum.Font.Gotham,
        TextColor3             = T.TextDim,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 36, 0, 330),
        Size                   = UDim2.new(1, -50, 0, 12),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 12,
    }, leftPanel)

    task.spawn(function()
        while task.wait(1) do
            if not screenGui.Parent then break end
            local t = os.date("*t")
            clockLabel.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
            dateLabel.Text  = string.format("%s %02d, %04d",
                ({"Jan","Feb","Mar","Apr","May","Jun",
                  "Jul","Aug","Sep","Oct","Nov","Dec"})[t.month],
                t.day, t.year)
        end
    end)

    -- ================================================================
    --   CENTER PANEL — Key System
    -- ================================================================
    local centerPanel = Panel(430, 2)
    PanelHeader(centerPanel, A.Icon, "Ziaa Hub")

    make("TextLabel", {
        Text                   = "Enter your key to continue",
        TextSize               = 16,
        Font                   = Enum.Font.GothamBold,
        TextColor3             = T.Accent,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0, 60),
        AnchorPoint            = Vector2.new(0.5, 0),
        Size                   = UDim2.new(1, -24, 0, 20),
        TextXAlignment         = Enum.TextXAlignment.Center,
        ZIndex                 = 12,
    }, centerPanel)

    local inputBg = make("Frame", {
        Size             = UDim2.new(1, -24, 0, 44),
        Position         = UDim2.new(0, 12, 0, 90),
        BackgroundColor3 = T.Input,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, centerPanel)
    corner(inputBg, 8)
    stroke(inputBg, T.Border, 1)

    local keyInput = make("TextBox", {
        PlaceholderText   = "Enter your key...",
        Text              = "",
        TextSize          = 15,
        Font              = Enum.Font.GothamMedium,
        TextColor3        = T.Text,
        PlaceholderColor3 = T.TextDim,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, -16, 1, 0),
        Position          = UDim2.new(0, 12, 0, 0),
        ClearTextOnFocus  = false,
        ZIndex            = 13,
        TextXAlignment    = Enum.TextXAlignment.Left,
    }, inputBg)
    _keyInput = keyInput

    keyInput.Focused:Connect(function()
        tween(inputBg, { BackgroundColor3 = Color3.fromRGB(30, 22, 48) }, 0.15)
        stroke(inputBg, T.Accent, 1.5)
    end)
    keyInput.FocusLost:Connect(function()
        tween(inputBg, { BackgroundColor3 = T.Input }, 0.15)
        stroke(inputBg, T.Border, 1)
    end)

    _statusLabel = make("TextLabel", {
        Text                   = "",
        TextSize               = 12,
        Font                   = Enum.Font.Gotham,
        TextColor3             = T.StatusIdle,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0, 140),
        AnchorPoint            = Vector2.new(0.5, 0),
        Size                   = UDim2.new(1, -24, 0, 14),
        TextXAlignment         = Enum.TextXAlignment.Center,
        ZIndex                 = 12,
    }, centerPanel)

    -- Get Key button
    local _, getKeyBtn = Button(centerPanel, "  Get Key", 160, false)
    getKeyBtn.MouseButton1Click:Connect(function()
        _statusLabel.Text       = "Opening browser → " .. L.GetKey
        _statusLabel.TextColor3 = T.TextDim
        if syn and syn.request then
            syn.request({ Url = L.GetKey, Method = "GET" })
        end
    end)

    -- Redeem Key button
    local _, redeemBtn = Button(centerPanel, "  Redeem Key", 208, true)
    ZiaaUI._redeemBtn = redeemBtn

    -- Icon buttons
    local function IconBtn(parent, icon, xPos, onClick)
        local bg = make("Frame", {
            Size             = UDim2.new(0, 52, 0, 44),
            Position         = UDim2.new(0, xPos, 0, 260),
            BackgroundColor3 = T.Input,
            BorderSizePixel  = 0,
            ZIndex           = 12,
        }, parent)
        corner(bg, 8)
        stroke(bg, T.Border, 1)

        local btn = make("TextButton", {
            Text                   = icon,
            TextSize               = 20,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.TextDim,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            ZIndex                 = 13,
        }, bg)

        btn.MouseEnter:Connect(function()
            tween(bg,  { BackgroundColor3 = T.Border }, 0.15)
            tween(btn, { TextColor3 = T.Accent }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(bg,  { BackgroundColor3 = T.Input }, 0.15)
            tween(btn, { TextColor3 = T.TextDim }, 0.15)
        end)
        btn.MouseButton1Click:Connect(onClick)
        return bg, btn
    end

    local centerX = 215 - (52*3 + 12*2) / 2
    IconBtn(centerPanel, "👤", centerX, function() end)
    IconBtn(centerPanel, "💬", centerX + 64, function()
        _statusLabel.Text       = L.Discord
        _statusLabel.TextColor3 = T.TextDim
    end)
    IconBtn(centerPanel, "↺", centerX + 128, function()
        keyInput.Text          = ""
        _statusLabel.Text      = ""
        _keyValid              = false
    end)

    -- Premium bar
    if S.Enabled then
        local shopBar = make("Frame", {
            Size             = UDim2.new(1, 0, 0, 52),
            Position         = UDim2.new(0, 0, 1, -52),
            BackgroundColor3 = T.Header,
            BorderSizePixel  = 0,
            ZIndex           = 12,
        }, centerPanel)

        make("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = T.Border,
            BorderSizePixel  = 0,
            ZIndex           = 12,
        }, shopBar)

        local badge = make("Frame", {
            Size             = UDim2.new(0, 34, 0, 34),
            Position         = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 13,
        }, shopBar)
        corner(badge, 7)

        make("TextLabel", {
            Text                   = "Z",
            TextSize               = 18,
            Font                   = Enum.Font.GothamBlack,
            TextColor3             = Color3.new(1,1,1),
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1,0,1,0),
            ZIndex                 = 14,
        }, badge)

        make("TextLabel", {
            Text                   = S.Title,
            TextSize               = 13,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.Text,
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 54, 0, 8),
            Size                   = UDim2.new(1, -150, 0, 15),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
        }, shopBar)

        make("TextLabel", {
            Text                   = S.Subtitle,
            TextSize               = 10,
            Font                   = Enum.Font.Gotham,
            TextColor3             = T.TextDim,
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 54, 0, 26),
            Size                   = UDim2.new(1, -150, 0, 13),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
        }, shopBar)

        local buyBg = make("Frame", {
            Size             = UDim2.new(0, 72, 0, 32),
            Position         = UDim2.new(1, -84, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 13,
        }, shopBar)
        corner(buyBg, 7)

        local buyBtn = make("TextButton", {
            Text                   = S.ButtonText,
            TextSize               = 13,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = Color3.new(1,1,1),
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1,0,1,0),
            ZIndex                 = 14,
        }, buyBg)

        buyBtn.MouseButton1Click:Connect(function()
            if syn and syn.request then
                syn.request({ Url = S.Link, Method = "GET" })
            end
            _statusLabel.Text       = S.Link
            _statusLabel.TextColor3 = T.TextDim
        end)
        buyBtn.MouseEnter:Connect(function()
            tween(buyBg, { BackgroundColor3 = T.AccentHover }, 0.15)
        end)
        buyBtn.MouseLeave:Connect(function()
            tween(buyBg, { BackgroundColor3 = T.Accent }, 0.15)
        end)
    end

    -- ================================================================
    --   RIGHT PANEL — Changelog
    -- ================================================================
    local rightPanel = Panel(215, 3)
    PanelHeader(rightPanel, "rbxassetid://7072725342", "Changelog")

    local scroll = make("ScrollingFrame", {
        Size                  = UDim2.new(1, 0, 1, -44),
        Position              = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        ScrollBarThickness    = 2,
        ScrollBarImageColor3  = T.Accent,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ZIndex                = 11,
    }, rightPanel)

    make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 0),
    }, scroll)

    make("UIPadding", {
        PaddingLeft   = UDim.new(0, 12),
        PaddingRight  = UDim.new(0, 12),
        PaddingTop    = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    }, scroll)

    ZiaaUI._scroll = scroll

    for i, entry in ipairs(ZiaaUI.Changelog) do
        local entryFrame = make("Frame", {
            Size                   = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize          = Enum.AutomaticSize.Y,
            BorderSizePixel        = 0,
            ZIndex                 = 12,
            LayoutOrder            = i,
        }, scroll)

        make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 2),
        }, entryFrame)

        local hdrFrame = make("Frame", {
            Size                   = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ZIndex                 = 12,
            LayoutOrder            = 1,
        }, entryFrame)

        make("TextLabel", {
            Text                   = entry.Version .. "  •  " .. entry.Date,
            TextSize               = 11,
            Font                   = Enum.Font.GothamBold,
            TextColor3             = T.Accent,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            ZIndex                 = 13,
            TextXAlignment         = Enum.TextXAlignment.Left,
        }, hdrFrame)

        for j, item in ipairs(entry.Items) do
            make("TextLabel", {
                Text                   = "• " .. item,
                TextSize               = 11,
                Font                   = Enum.Font.Gotham,
                TextColor3             = T.TextDim,
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 14),
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextWrapped            = true,
                ZIndex                 = 12,
                LayoutOrder            = j + 1,
            }, entryFrame)
        end

        make("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = T.Border,
            BorderSizePixel  = 0,
            ZIndex           = 12,
            LayoutOrder      = 99,
        }, entryFrame)

        make("Frame", {
            Size                   = UDim2.new(1, 0, 0, 6),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            LayoutOrder            = 100,
        }, entryFrame)
    end

    -- Draggable
    local dragging, dragStart, startPos = false, nil, nil
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = container.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            container.Position = UDim2.new(
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
end

-- ================================================================
--   PUBLIC API
-- ================================================================

function ZiaaUI:AddChangelog(version, date, items)
    table.insert(self.Changelog, {
        Version = version,
        Date    = date,
        Items   = items or {},
    })
    return self
end

-- ================================================================
--   LaunchJunkie — Sans validation JNKIE, clé simple
-- ================================================================
function ZiaaUI:LaunchJunkie(config)
    BuildGUI()

    -- Clés valides (ajoute les tiennes ici)
    local VALID_KEYS = {
        "ziaa-free-key-2026",
        "ziaa-beta-access",
        "ziaa-premium-001",
    }

    local function isValidKey(key)
        for _, v in ipairs(VALID_KEYS) do
            if key == v then return true end
        end
        return false
    end

    -- Vérif clé sauvegardée
    local saved = LoadSavedKey()
    if saved and saved ~= "" then
        _statusLabel.Text       = "Checking saved key..."
        _statusLabel.TextColor3 = ZiaaUI.Theme.TextDim
        task.spawn(function()
            task.wait(0.5)
            if isValidKey(saved) then
                _keyValid               = true
                _keyInput.Text          = saved
                _statusLabel.Text       = "✓ Key accepted — welcome!"
                _statusLabel.TextColor3 = ZiaaUI.Theme.Success
            else
                _statusLabel.Text       = "✗ Saved key invalid, enter a new one."
                _statusLabel.TextColor3 = ZiaaUI.Theme.Error
            end
        end)
    end

    -- Bouton Redeem
    if ZiaaUI._redeemBtn then
        ZiaaUI._redeemBtn.MouseButton1Click:Connect(function()
            local key = (_keyInput.Text or ""):match("^%s*(.-)%s*$")
            if key == "" then
                _statusLabel.Text       = "✗ Please enter a key."
                _statusLabel.TextColor3 = ZiaaUI.Theme.Error
                return
            end

            _statusLabel.Text       = "Validating..."
            _statusLabel.TextColor3 = ZiaaUI.Theme.TextDim

            task.spawn(function()
                task.wait(0.8) -- simulation délai réseau
                if isValidKey(key) then
                    _keyValid               = true
                    _statusLabel.Text       = "✓ Key accepted — welcome!"
                    _statusLabel.TextColor3 = ZiaaUI.Theme.Success
                    SaveKey(key)
                else
                    _keyValid               = false
                    _statusLabel.Text       = "✗ Invalid or expired key."
                    _statusLabel.TextColor3 = ZiaaUI.Theme.Error
                end
            end)
        end)
    end
end

return ZiaaUI
