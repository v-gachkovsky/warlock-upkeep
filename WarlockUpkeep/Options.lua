local ADDON, ns = ...
local L = ns.L

local panel, scroll, nav, content, settingsButton
local BuildContent
local y = 0
local refreshers = {}
local LEFT, RIGHT = 20, 290
local WIDTH = 610 -- a page of settings; the list of pages runs down the left side

local function Changed()
    ns:ApplyAll()
    for _, r in ipairs(refreshers) do r() end
end

------------------------------------------------------------------------
-- Widgets
------------------------------------------------------------------------
local function Label(text, x, template)
    local fs = content:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x or LEFT, y)
    fs:SetText(L[text])
    return fs
end

local function Header(text, icon)
    y = y - 10
    local fs = Label(text, icon and 34 or 12, "GameFontNormalLarge")
    if icon then
        local tex = content:CreateTexture(nil, "ARTWORK")
        tex:SetSize(18, 18)
        tex:SetPoint("RIGHT", fs, "LEFT", -4, 0)
        tex:SetTexture(icon)
        if icon ~= ns.LOGO then tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    end
    local line = content:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.15)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 12, y - 22)
    line:SetPoint("TOPRIGHT", -12, y - 22)
    y = y - 30
end

local function SubHeader(text)
    y = y - 4
    Label(text, LEFT, "GameFontNormal")
    y = y - 20
end

local function Check(text, get, set)
    local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", LEFT - 4, y + 4)
    local fs = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    fs:SetWidth(WIDTH - LEFT - 50)
    fs:SetJustifyH("LEFT")
    fs:SetText(L[text])
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false); Changed() end)
    refreshers[#refreshers + 1] = function() cb:SetChecked(get() and true or false) end
    -- Long (translated) texts wrap onto more lines.
    y = y - math.max(26, fs:GetStringHeight() + 12)
end

-- Label of a row with a control on the right: long (translated) texts wrap instead of running under it.
local function RowLabel(text)
    local fs = Label(text)
    fs:SetWidth(RIGHT - LEFT - 8)
    fs:SetJustifyH("LEFT")
    return fs
end

local function RowHeight(fs, height) return math.max(height, fs:GetStringHeight() + 12) end

-- A slider with a box to type the value: Enter applies it (whole number, kept within the range), Escape
-- or clicking away puts back the current value.
local function Slider(text, min, max, step, get, set)
    local fs = RowLabel(text)
    local s = CreateFrame("Slider", nil, content)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(180, 16)
    s:SetPoint("TOPLEFT", RIGHT, y + 1)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:EnableMouse(true)
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0, 0, 0, 0.6)
    track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(6)
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local val = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    val:SetSize(42, 20)
    val:SetPoint("LEFT", s, "RIGHT", 14, 0)
    val:SetAutoFocus(false)
    val:SetJustifyH("CENTER")
    local function Refresh()
        s.refreshing = true
        s:SetValue(get())
        s.refreshing = nil
        val:SetText(get())
        val:SetCursorPosition(0)
    end
    s:SetScript("OnValueChanged", function(self, v)
        if self.refreshing then return end
        v = math.floor(v / step + 0.5) * step
        val:SetText(v)
        if v ~= get() then set(v); ns:ApplyAll() end
    end)
    val:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText())
        if v then
            v = math.min(max, math.max(min, math.floor(v + 0.5)))
            if v ~= get() then set(v); ns:ApplyAll() end
        end
        self:ClearFocus()
    end)
    val:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    val:SetScript("OnEditFocusLost", Refresh)
    refreshers[#refreshers + 1] = Refresh
    y = y - RowHeight(fs, 26)
end

local function Color(text, get, set)
    local b = CreateFrame("Button", nil, content)
    b:SetSize(18, 18)
    b:SetPoint("TOPLEFT", LEFT, y + 2)
    local border = b:CreateTexture(nil, "BACKGROUND")
    border:SetColorTexture(1, 1, 1, 1)
    border:SetAllPoints()
    local sw = b:CreateTexture(nil, "ARTWORK")
    sw:SetPoint("TOPLEFT", 1, -1)
    sw:SetPoint("BOTTOMRIGHT", -1, 1)
    local fs = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", b, "RIGHT", 6, 0)
    fs:SetText(L[text])

    local function Paint() local c = get(); sw:SetColorTexture(c[1], c[2], c[3], 1) end
    b:SetScript("OnClick", function()
        local c = get()
        local r0, g0, b0 = c[1], c[2], c[3]
        local function OnColor()
            local r, g, bb = ColorPickerFrame:GetColorRGB()
            set({ r, g, bb, 1 }); Paint(); ns:ApplyAll()
        end
        local function OnCancel()
            set({ r0, g0, b0, 1 }); Paint(); ns:ApplyAll()
        end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r0, g = g0, b = b0, hasOpacity = false,
                swatchFunc = OnColor, cancelFunc = OnCancel,
            })
        else
            ColorPickerFrame.func, ColorPickerFrame.cancelFunc = OnColor, OnCancel
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame:SetColorRGB(r0, g0, b0)
            ColorPickerFrame:Show()
        end
    end)
    refreshers[#refreshers + 1] = Paint
    y = y - 24
end

-- Dropdown list. Clients with the new menu system get its dropdown (scrolls when the list is long),
-- the others the old UIDropDownMenu.
local selectCount = 0
local function Select(text, values, get, set, extra)
    local fs = RowLabel(text)
    local function List() return type(values) == "function" and values() or values end
    local function Pick(value) set(value); Changed() end
    local ok, btn = pcall(CreateFrame, "DropdownButton", nil, content, "WowStyle1DropdownTemplate")
    local gap = 4
    if ok and btn and btn.SetupMenu then
        btn:SetSize(170, 22)
        btn:SetPoint("TOPLEFT", RIGHT, y + 4)
        btn:SetupMenu(function(_, root)
            if root.SetScrollMode then root:SetScrollMode(400) end
            for _, item in ipairs(List()) do
                root:CreateRadio(L[item.text], function() return get() == item.value end, function() Pick(item.value) end)
            end
        end)
        refreshers[#refreshers + 1] = function() btn:GenerateMenu() end
    else
        selectCount = selectCount + 1 -- the old template needs a named frame
        btn = CreateFrame("Frame", "WarlockUpkeepSelect" .. selectCount, content, "UIDropDownMenuTemplate")
        btn:SetPoint("TOPLEFT", RIGHT - 16, y + 6)
        UIDropDownMenu_SetWidth(btn, 150)
        UIDropDownMenu_Initialize(btn, function(_, level)
            for _, item in ipairs(List()) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = L[item.text]
                info.checked = get() == item.value
                info.func = function() Pick(item.value) end
                UIDropDownMenu_AddButton(info, level)
            end
        end)
        refreshers[#refreshers + 1] = function()
            local label = tostring(get())
            for _, item in ipairs(List()) do
                if item.value == get() then label = L[item.text] end
            end
            UIDropDownMenu_SetText(btn, label)
        end
        gap = -12 -- the old template has empty space on its right
    end
    if extra then
        local e = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        e:SetPoint("LEFT", btn, "RIGHT", gap, 0)
        e:SetText(L[extra.text])
        e:SetSize(math.max(50, e:GetFontString():GetStringWidth() + 24), 22) -- fits a longer translation
        e:SetScript("OnClick", extra.onClick)
    end
    y = y - RowHeight(fs, 28)
end

local function Button(text, width, onClick, x)
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetPoint("TOPLEFT", x or LEFT, y + 4)
    b:SetText(L[text])
    b:SetScript("OnClick", onClick)
    return b
end

local function Note(text)
    local fs = Label(text, LEFT, "GameFontDisableSmall")
    fs:SetWidth(WIDTH - LEFT - 20)
    fs:SetJustifyH("LEFT")
    y = y - (fs:GetStringHeight() + 12)
end

------------------------------------------------------------------------
-- Composite rows
------------------------------------------------------------------------
local function T(key) return function() return ns.db[key] end end

local function TestSound(value)
    if not ns.PlaySound(value) then
        ns.Print(L["can't play %s. Custom files need a full game restart after adding them."], tostring(value))
    end
end

local function SoundRows(getTbl, soundText)
    Check(soundText or "Play sound", function() return getTbl().sound end, function(v) getTbl().sound = v end)
    Select("Sound", ns.GetSoundList, function() return getTbl().soundName end, function(v) getTbl().soundName = v end,
        { text = "Test", onClick = function() TestSound(getTbl().soundName) end })
end

local function Input(text, width, onEnter)
    local fs = RowLabel(text)
    local e = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    e:SetSize(width, 20)
    e:SetPoint("TOPLEFT", RIGHT + 6, y + 3)
    e:SetAutoFocus(false)
    e:SetScript("OnEnterPressed", function(self) onEnter(self:GetText()); self:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ns.AddUndo(e)
    y = y - RowHeight(fs, 28)
    return e
end

-- A message or a word list: a box over the whole row that wraps long texts. Saved on Enter or when it loses
-- focus; Escape puts back the saved text. Chat messages have no line breaks, so they're dropped. default: the
-- text the Default button puts back. legend: the placeholders the text takes, { { "{name}", "the buyer" }, ... }.
local function TextArea(text, get, set, default, legend)
    Label(text)
    local reset
    if default then
        reset = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        reset:SetText(L["Default"])
        reset:SetSize(math.max(70, reset:GetFontString():GetStringWidth() + 20), 20)
        reset:SetPoint("TOPRIGHT", content, "TOPLEFT", WIDTH - 20, y + 4)
    end
    y = y - 22
    local box = CreateFrame("Frame", nil, content, "BackdropTemplate")
    box:SetPoint("TOPLEFT", LEFT, y)
    box:SetSize(WIDTH - LEFT - 20, 50)
    box:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.5)
    box:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    local e = CreateFrame("EditBox", nil, box)
    e:SetMultiLine(true)
    e:SetAutoFocus(false)
    e:SetFontObject("ChatFontNormal")
    e:SetPoint("TOPLEFT", 8, -7)
    e:SetPoint("BOTTOMRIGHT", -8, 7)
    e:SetWidth(WIDTH - LEFT - 36)
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function() e:SetFocus() end)
    e:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(self) self:SetText(get() or ""); self:ClearFocus() end)
    e:SetScript("OnEditFocusLost", function(self)
        local v = self:GetText():gsub("[\r\n]+", " ")
        self:SetText(v)
        if v ~= get() then set(v); Changed() end
    end)
    -- A multi-line box may take Enter as a line break: that ends the editing too.
    e:HookScript("OnTextChanged", function(self, userInput)
        if userInput and self:GetText():find("\n") then self:ClearFocus() end
    end)
    ns.AddUndo(e)
    refreshers[#refreshers + 1] = function()
        if not e:HasFocus() then e:SetText(get() or ""); e:SetCursorPosition(0) end
    end
    if reset then
        reset:SetScript("OnClick", function()
            e:ClearFocus()
            set(default)
            Changed()
        end)
    end
    y = y - 54
    if legend then
        local parts = {}
        for _, l in ipairs(legend) do parts[#parts + 1] = "|cffffd100" .. l[1] .. "|r - " .. L[l[2]] end
        local fs = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        fs:SetPoint("TOPLEFT", LEFT + 2, y)
        fs:SetWidth(WIDTH - LEFT - 20)
        fs:SetJustifyH("LEFT")
        fs:SetText(table.concat(parts, "     "))
        y = y - fs:GetStringHeight() - 4
    end
    y = y - 10
end

-- Placeholders of the message texts, for the legends under them.
local P_NAME_SS = { "{name}", "the player with your Soulstone" }
local P_TIME = { "{time}", "the time left (m:ss)" }
local P_NAME_SUMMON = { "{name}", "the player being summoned" }
local P_NAME_BUYER = { "{name}", "the buyer" }
local P_ZONE = { "{zone}", "the place typed in the selling window, or your zone" }
local P_PRICE = { "{price}", "your price, like 1g50s" }
local P_CLICKERS = { "{clickers}", "the clickers sentence below, left out once two stand by" }
local P_N = { "{n}", "how many more people you need" }

local function GlowAndSound(getTbl, glowText, soundText)
    Check(glowText or "Highlight (glow)", function() return getTbl().glow end, function(v) getTbl().glow = v end)
    Color("Highlight color", function() return getTbl().glowColor end, function(v) getTbl().glowColor = v end)
    SoundRows(getTbl, soundText)
end

local function IconSection(title, key, icon, extra)
    local get = T(key)
    Header(title, icon)
    Check("Enable", function() return get().enabled end, function(v) get().enabled = v end)
    Check("Lock position", function() return get().locked end, function(v) get().locked = v end)
    Slider("Icon size", 16, 128, 1, function() return get().size end, function(v) get().size = v end)
    if extra then extra(get) else GlowAndSound(get) end
end

local function FontRows(get, sizes)
    Select("Font", ns.GetFontList, function() return get().font end, function(v) get().font = v end)
    Select("Outline", ns.OUTLINES, function() return get().outline end, function(v) get().outline = v end)
    for _, s in ipairs(sizes) do
        Slider(s[1], 8, 48, 1, function() return get()[s[2]] end, function(v) get()[s[2]] = v end)
    end
end

------------------------------------------------------------------------
-- Pages: one group of settings at a time, picked from the list on the left
------------------------------------------------------------------------
local pages, navButtons = {}, {}
local currentPage
local ORDER = { "general", "profiles", "armor", "shards", "healthstone", "weaponStone", "soulstone", "pet",
    "enslave", "summon", "sell", "trainer", "grimoires", "sounds" }

local function FinishPage()
    if content then content:SetHeight(-y + 20) end
end

-- Starts a page: the rows that follow go on it.
local function Page(key, title, icon)
    FinishPage()
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH, 100)
    content:Hide()
    y = 0
    pages[key] = { frame = content, title = title, icon = icon }
end

local function ShowPage(key)
    if not pages[key] then
        for _, k in ipairs(ORDER) do
            if pages[k] then key = k; break end
        end
    end
    currentPage = key
    for k, p in pairs(pages) do p.frame:SetShown(k == key) end
    scroll:SetScrollChild(pages[key].frame)
    scroll:SetVerticalScroll(0)
    for k, b in pairs(navButtons) do b.selected:SetShown(k == key) end
end

local function BuildNav()
    for _, b in pairs(navButtons) do b:Hide() end
    wipe(navButtons)
    local top = -6
    for _, key in ipairs(ORDER) do
        local p = pages[key]
        if p then
            local b = CreateFrame("Button", nil, nav)
            b:SetSize(nav:GetWidth() - 8, 24)
            b:SetPoint("TOPLEFT", 4, top)
            b.icon = b:CreateTexture(nil, "ARTWORK")
            b.icon:SetSize(18, 18)
            b.icon:SetPoint("LEFT", 4, 0)
            b.icon:SetTexture(p.icon)
            if p.icon ~= ns.LOGO then b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
            b.text = b:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            b.text:SetPoint("LEFT", b.icon, "RIGHT", 6, 0)
            b.text:SetPoint("RIGHT", -4, 0)
            b.text:SetJustifyH("LEFT")
            b.text:SetWordWrap(false)
            b.text:SetText(L[p.title])
            b.selected = b:CreateTexture(nil, "BACKGROUND")
            b.selected:SetAllPoints()
            b.selected:SetColorTexture(0.58, 0.51, 0.79, 0.35)
            b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            b:SetScript("OnClick", function() ShowPage(key) end)
            navButtons[key] = b
            top = top - 26
        end
    end
    nav.reset:SetText(L["Reset all settings"])
end

-- Every setting of the current profile back to the defaults, after a confirmation.
local function ConfirmReset()
    if InCombatLockdown() then ns.Print(L["cannot reset in combat."]); return end
    StaticPopupDialogs.WARLOCKUPKEEP_RESET = {
        text = L["Reset all settings of the \"%s\" profile to the defaults?"],
        button1 = YES, button2 = NO,
        OnAccept = function()
            if InCombatLockdown() then ns.Print(L["cannot reset in combat."]); return end
            ns:ResetDB()
            ns.Print(L["settings reset."])
            -- The language may have changed back too.
            C_Timer.After(0, function()
                BuildContent()
                if settingsButton then settingsButton:SetText(L["Open settings (/wu)"]) end
                Changed()
            end)
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopup_Show("WARLOCKUPKEEP_RESET", ns.CurrentProfile())
end

------------------------------------------------------------------------
-- Build
------------------------------------------------------------------------
local function Build()
    local ok, f = pcall(CreateFrame, "Frame", "WarlockUpkeepOptions", UIParent, "BasicFrameTemplateWithInset")
    if not ok then
        f = CreateFrame("Frame", "WarlockUpkeepOptions", UIParent, "BackdropTemplate")
        f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
        f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        f.CloseButton:SetPoint("TOPRIGHT")
    end
    panel = f
    -- The template's button closes through the game's panel manager (HideUIPanel), which sometimes
    -- leaves this window open; hide it directly instead.
    local close = f.CloseButton or _G["WarlockUpkeepOptionsCloseButton"]
    if close then close:SetScript("OnClick", function() f:Hide() end) end
    f:SetSize(880, 640)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH") -- below the confirmation popups
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "WarlockUpkeepOptions")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 8, -6)
    title:SetText("|cff9482c9WarlockUpkeep!|r")
    local logo = f:CreateTexture(nil, "OVERLAY")
    logo:SetSize(16, 16)
    logo:SetPoint("RIGHT", title, "LEFT", -4, 0)
    logo:SetTexture(ns.LOGO)

    nav = CreateFrame("Frame", nil, f, "BackdropTemplate")
    nav:SetPoint("TOPLEFT", 10, -30)
    nav:SetPoint("BOTTOMLEFT", 10, 10)
    nav:SetWidth(210)
    nav:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    nav:SetBackdropColor(0, 0, 0, 0.35)
    nav.reset = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    nav.reset:SetSize(194, 22)
    nav.reset:SetPoint("BOTTOM", 0, 8)
    nav.reset:SetScript("OnClick", ConfirmReset)

    scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", nav, "TOPRIGHT", 8, 0)
    scroll:SetPoint("BOTTOMRIGHT", -32, 10)
    f:SetScript("OnShow", function() for _, r in ipairs(refreshers) do r() end end)
end

-- Settings rows, page by page. Built again in new frames when the language changes.
function BuildContent()
    for _, p in pairs(pages) do p.frame:Hide() end
    wipe(pages)
    content = nil
    wipe(refreshers)

    -- General
    Page("general", "General", ns.LOGO)
    Header("General", ns.LOGO)
    Select("Language", ns.LANGUAGES, function() return ns.db.locale end, function(v)
        ns.db.locale = v
        C_Timer.After(0, function()
            BuildContent()
            if settingsButton then settingsButton:SetText(L["Open settings (/wu)"]) end
            Changed()
        end)
    end)
    -- A profile switch can change the language too: the rows are built again.
    local function Rebuild()
        C_Timer.After(0, function()
            BuildContent()
            if settingsButton then settingsButton:SetText(L["Open settings (/wu)"]) end
            Changed()
        end)
    end

    Check("Preview mode (show all icons for positioning)", function() return ns.db.preview end, function(v) ns.db.preview = v end)
    Check("Simulate combat (opacity, highlight, hiding, click-through)", function() return ns.db.previewCombat end, function(v) ns.db.previewCombat = v end)
    Check("Show minimap button", function() return not ns.db.minimap.hide end, function(v) ns.db.minimap.hide = not v end)
    Check("Lock minimap button position", function() return ns.db.minimap.locked end, function(v) ns.db.minimap.locked = v end)
    Select("Move icons with", ns.GetMoveModes, function() return ns.db.moveWith end, function(v) ns.db.moveWith = v end)
    Check("Hide all icons while on a flight path", function() return ns.db.hideOnTaxi end, function(v) ns.db.hideOnTaxi = v end)
    Check("Hide all icons while mounted", function() return ns.db.hideOnMount end, function(v) ns.db.hideOnMount = v end)
    if ns.modules.shards then
        Note("These also hide the Soulstone label and the Soul Shard counter. The counter can stay on screen: " ..
            "see \"Keep showing on a mount or flight path\" in its section.")
    else
        Note("These also hide the Soulstone label.")
    end
    Check("Snap frames to each other (top / bottom / center, side by side)", function() return ns.db.snap.enabled end, function(v) ns.db.snap.enabled = v end)
    Slider("Snap distance", 2, 30, 1, function() return ns.db.snap.distance end, function(v) ns.db.snap.distance = v end)
    Slider("Gap between snapped frames", 0, 20, 1, function() return ns.db.snap.gap end, function(v) ns.db.snap.gap = v end)
    SubHeader("Combat")
    Check("Highlight in combat", function() return ns.db.combat.glow end, function(v) ns.db.combat.glow = v end)
    Check("Click-through in combat (target / turn the camera through icons)", function() return ns.db.combat.clickThrough end, function(v) ns.db.combat.clickThrough = v end)
    Check("Hide icons in combat", function() return ns.db.combat.hide end, function(v) ns.db.combat.hide = v end)
    Slider("Opacity in combat, %", ns.MIN_COMBAT_ALPHA * 100, 100, 5, function() return math.floor(ns.db.combat.alpha * 100 + 0.5) end, function(v) ns.db.combat.alpha = v / 100 end)
    Slider("Opacity out of combat, %", 0, 100, 5, function() return math.floor(ns.db.combat.idleAlpha * 100 + 0.5) end, function(v) ns.db.combat.idleAlpha = v / 100 end)
    Note("Click-through can't change during a fight (the game locks mouse input in combat): it applies after combat. " ..
        "Hiding applies at once, but icons hidden when the fight started stay hidden until it ends. " ..
        "Without click-through, icons are clickable in combat, and a faded-out icon still takes clicks at its spot.")
    SubHeader("Appearance")
    Select("Highlight type", ns.GLOW_MODES, function() return ns.db.glowMode end, function(v) ns.db.glowMode = v end)
    Select("Outline style", ns.GLOW_STYLES, function() return ns.db.glowStyle end, function(v) ns.db.glowStyle = v end)
    Slider("Fill opacity, %", 5, 100, 5, function() return math.floor(ns.db.fillAlpha * 100 + 0.5) end, function(v) ns.db.fillAlpha = v / 100 end)
    Button("Lock all", 110, function() ns:SetAllLocked(true); Changed() end)
    Button("Unlock all", 110, function() ns:SetAllLocked(false); Changed() end, LEFT + 116)
    y = y - 30
    Note("Icons: left click performs the action; they are moved as set in \"Move icons with\" (only when unlocked). " ..
        "If a modifier is used for moving, clicks with that modifier do nothing while the icon is unlocked. " ..
        "Labels and the shard counter are moved with left-drag. Changes made in combat apply after combat.")

    -- Profiles
    Page("profiles", "Profiles", "Interface\\Icons\\INV_Misc_Note_01")
    Header("Profiles", "Interface\\Icons\\INV_Misc_Note_01")
    local function ProfileList()
        local list = {}
        for _, name in ipairs(ns.ProfileNames()) do list[#list + 1] = { value = name, text = name } end
        return list
    end
    Select("Profile", ProfileList, ns.CurrentProfile, function(v) ns.SelectProfile(v); Rebuild() end,
        { text = "Delete", onClick = function()
            if ns.DeleteProfile(ns.CurrentProfile()) then Rebuild() else ns.Print(L["the Default profile can't be deleted."]) end
        end })
    Input("New profile (copy of the current one)", 170, function(text)
        if ns.CreateProfile(text) then Rebuild() else ns.Print(L["enter a new, unused profile name."]) end
    end)
    local io = Input("Export / import", 170, function() end)
    io:SetMaxLetters(0)
    Button("Export", 80, function()
        io:SetText(ns.ExportProfile())
        io:SetFocus()
        io:HighlightText()
        ns.Print(L["the profile string is selected: copy it with Ctrl+C (Cmd+C on a Mac)."])
    end, RIGHT + 6)
    Button("Import", 80, function()
        local ok, err = ns.ImportProfile(io:GetText())
        if ok then
            io:SetText("")
            ns.Print(L["profile imported into %s."], ns.CurrentProfile())
            Rebuild()
        else
            ns.Print(L["can't import: %s."], err)
        end
    end, RIGHT + 92)
    y = y - 28
    Note("Each character uses one profile. Export puts the current profile's settings into the box as text; paste " ..
        "such a text into the box and press Import to replace the current profile's settings with it.")

    -- Custom sounds: the player's own files, offered in every sound list.
    Page("sounds", "Custom sounds", "Interface\\Icons\\INV_Misc_Drum_01")
    Header("Custom sounds", "Interface\\Icons\\INV_Misc_Drum_01")
    Note("Put .ogg or .mp3 files into World of Warcraft/<client>/Interface/WarlockUpkeepSounds/ and fully restart " ..
        "the game (a /reload doesn't find new files). Then add each file here by its name, e.g. alarm.ogg, " ..
        "or by a full path starting with Interface\\. Added files appear in every Sound list.")
    local function AddSound(text)
        local path = ns.NormalizeSoundPath(text)
        if not path then return end
        for _, c in ipairs(ns.db.customSounds) do
            if c.path:lower() == path:lower() then ns.Print(L["already added: %s"], path); return end
        end
        local name = path:match("([^\\]+)$"):gsub("%.%w+$", "")
        table.insert(ns.db.customSounds, { name = name, path = path })
        if not ns.PlaySound(path) then
            ns.Print(L["added %s, but it can't be played yet: check the name or restart the game."], path)
        end
        Changed()
    end
    local input = Input("Sound file", 170, function(text) AddSound(text) end)
    local add = Button("Add", 60, function() AddSound(input:GetText()); input:SetText(""); input:ClearFocus() end)
    add:ClearAllPoints()
    add:SetPoint("LEFT", input, "RIGHT", 6, 0)
    local selected
    local function CustomList()
        local list = {}
        for _, c in ipairs(ns.db.customSounds) do list[#list + 1] = { value = c.path, text = c.name } end
        if #list == 0 then list[1] = { value = "", text = "(none)" } end
        return list
    end
    Select("Added files", CustomList, function() return selected or CustomList()[1].value end, function(v) selected = v end,
        { text = "Test", onClick = function() local v = selected or CustomList()[1].value; if v ~= "" then TestSound(v) end end })
    Button("Remove selected", 130, function()
        local v = selected or CustomList()[1].value
        for i, c in ipairs(ns.db.customSounds) do
            if c.path == v then table.remove(ns.db.customSounds, i); break end
        end
        selected = nil
        Changed()
    end, RIGHT)
    y = y - 30

    -- 1. Demon Armor
    if ns.modules.armor then
        Page("armor", "Demon Armor / Demon Skin", "Interface\\Icons\\Spell_Shadow_RagingScream")
        IconSection("Demon Armor / Demon Skin", "armor", "Interface\\Icons\\Spell_Shadow_RagingScream", function(get)
            -- Clients that hide auras from addons in combat (Forever).
            if ns.SECRET_AURAS then
                Note("Important: add Demon Skin and Demon Armor to the Cooldown Manager's Tracked Buffs. " ..
                    "In combat the game hides your buffs from addons, and the Cooldown Manager is what lets " ..
                    "this icon notice the armor being removed or recast during a fight.")
            end
            GlowAndSound(get)
        end)
    end

    -- 2. Soul Shards
    if ns.modules.shards then
        Page("shards", "Soul Shard counter", "Interface\\Icons\\INV_Misc_Gem_Amethyst_02")
        local sh = T("shards")
        Header("Soul Shard counter", "Interface\\Icons\\INV_Misc_Gem_Amethyst_02")
        Check("Enable", function() return sh().enabled end, function(v) sh().enabled = v end)
        Check("Lock position", function() return sh().locked end, function(v) sh().locked = v end)
        Check("Keep showing on a mount or flight path", function() return sh().keepOnTravel end, function(v) sh().keepOnTravel = v end)
        Check("Show shard icon", function() return sh().showIcon end, function(v) sh().showIcon = v end)
        Slider("Icon size", 12, 96, 1, function() return sh().iconSize end, function(v) sh().iconSize = v end)
        Slider("Background opacity, %", 0, 100, 5, function() return math.floor(sh().bgAlpha * 100 + 0.5) end, function(v) sh().bgAlpha = v / 100 end)
        Slider("Spare shards", 0, 10, 1, function() return sh().spare end, function(v) sh().spare = v end)
        Check("Count Ritual of Summoning in recommended amount", function() return sh().includeRitual end, function(v) sh().includeRitual = v end)
        local recommended = Label("")
        refreshers[#refreshers + 1] = function()
            local n, parts = ns.modules.shards:Desired()
            local list = table.concat(parts, ", ")
            recommended:SetText(string.format(L["Recommended now: |cffffd100%d|r  (%s%s+%d spare)"], n, list, list ~= "" and " " or "", sh().spare))
        end
        y = y - 22
        Check("Low threshold = recommended amount", function() return sh().autoThreshold end, function(v) sh().autoThreshold = v end)
        Slider("Highlight when fewer than", 0, 40, 1, function() return sh().threshold end, function(v) sh().threshold = v end)
        Check("Show the threshold next to the count (current/threshold)", function() return sh().showThreshold end, function(v) sh().showThreshold = v end)
        SubHeader("Text")
        FontRows(sh, { { "Font size", "fontSize" } })
        Color("Text color", function() return sh().color end, function(v) sh().color = v end)
        Color("Text color at the threshold", function() return sh().edgeColor end, function(v) sh().edgeColor = v end)
        Color("Text color when low", function() return sh().lowColor end, function(v) sh().lowColor = v end)
        SubHeader("Low shards alert")
        GlowAndSound(sh)
        Color("Highlight color at the threshold", function() return sh().edgeGlowColor end, function(v) sh().edgeGlowColor = v end)
        SubHeader("Extra shards")
        Slider("Maximum shards (0 = no limit)", 0, 40, 1, function() return sh().maxShards end, function(v) sh().maxShards = v end)
        Color("Text color above the maximum", function() return sh().overColor end, function(v) sh().overColor = v end)
        Note("Shift + click on the counter deletes the shards above the maximum: from ordinary bags first, so a " ..
            "Soul Pouch keeps its shards. Not in combat.")
        SubHeader("Full bags")
        Check("Highlight when a new shard has no room in the bags", function() return sh().fullWarn end, function(v) sh().fullWarn = v end)
        Color("Highlight color", function() return sh().fullGlowColor end, function(v) sh().fullGlowColor = v end)
        Check("Play sound", function() return sh().fullSound end, function(v) sh().fullSound = v end)
        Select("Sound", ns.GetSoundList, function() return sh().fullSoundName end, function(v) sh().fullSoundName = v end,
            { text = "Test", onClick = function() TestSound(sh().fullSoundName) end })
    end

    -- 2b. Reagents
    if ns.modules.reagents then
        local rg = T("reagents")
        Header("Reagents", ns.ItemIcon(5565) or "Interface\\Icons\\INV_Stone_05")
        Check("Buy reagents at vendors automatically", function() return rg().autoBuy end, function(v) rg().autoBuy = v end)
        for _, r in ipairs(ns.data.reagents) do
            local label = string.format(L["%s: keep in bags"], L[r.name])
            if not ns.IsKnown(r.spell) then label = label .. " " .. L["(not learned)"] end
            Slider(label, 0, 10, 1, function() return rg().keep[r.key] end, function(v) rg().keep[r.key] = v end)
        end
        Note("At a vendor that sells them, reagents for the spells you know are bought up to these amounts (0: never). " ..
            "The Soul Shard counter's tooltip shows how many you have.")
    end

    -- 3. Healthstone
    Page("healthstone", "Healthstone", "Interface\\Icons\\INV_Stone_04")
    IconSection("Healthstone", "healthstone", "Interface\\Icons\\INV_Stone_04", function(get)
        SubHeader("State: no Healthstone in bags")
        GlowAndSound(get)
        local low = function() return get().lowHealth end
        SubHeader("State: low health")
        Check("Remind to use the Healthstone at low health", function() return low().enabled end, function(v) low().enabled = v end)
        Slider("Health below, %", 5, 90, 5, function() return low().percent end, function(v) low().percent = v end)
        GlowAndSound(function() return get().states.low end)
        Note("Shows the icon while a Healthstone is in your bags and off cooldown; a click uses the strongest one.")
    end)

    -- 3b. Firestone / Spellstone (Forever, Classic Era, TBC)
    if ns.modules.weaponStone then
        Page("weaponStone", "Firestone / Spellstone", ns.ItemIcon(13699) or "Interface\\Icons\\INV_Misc_Gem_Bloodstone_02")
        IconSection("Firestone / Spellstone", "weaponStone", ns.ItemIcon(13699) or "Interface\\Icons\\INV_Misc_Gem_Bloodstone_02", function(get)
            Select("Stone", { { value = "firestone", text = "Firestone" }, { value = "spellstone", text = "Spellstone" } },
                function() return get().stone end, function(v) get().stone = v end)
            if ns.FOREVER then
                Check("Remind while another temporary enchant (an oil) is on the weapon", function() return get().remindOverOther end, function(v) get().remindOverOther = v end)
                Note("The stone imbues your main-hand weapon. The addon tells its enchant from an oil's once you use " ..
                    "the stone (from the icon, your bags or a macro).")
                SubHeader("State: stone in bags but not applied to the weapon")
            else
                Note("The stone works while held in the off-hand: clicking the icon equips it in place of your " ..
                    "off-hand item.")
                SubHeader("State: stone in bags but not equipped")
            end
            GlowAndSound(function() return get().states.use end)
            SubHeader("State: no stone in bags")
            GlowAndSound(function() return get().states.create end)
        end)
    end

    -- 4. Soulstone
    Page("soulstone", "Soulstone", "Interface\\Icons\\Spell_Shadow_SoulGem")
    if ns.Hardcore() then
        Header("Soulstone", "Interface\\Icons\\Spell_Shadow_SoulGem")
        Note("Hardcore realm: nobody can be brought back to life here, so the Soulstone icon and label are off " ..
            "and the Soulstone isn't counted in the recommended shards.")
    else
        IconSection("Soulstone", "soulstone", "Interface\\Icons\\Spell_Shadow_SoulGem", function(get)
            Check("Hide while another warlock's Soulstone is on you", function() return get().hideWhenOthers end, function(v) get().hideWhenOthers = v end)
            if not ns.SHARD_ITEMS then
                -- Cast directly on the target: there's only the "not applied" state.
                GlowAndSound(function() return get().states.use end)
                return
            end
            Check("Remind to create a new Soulstone while one is applied", function() return get().createWhileApplied end, function(v) get().createWhileApplied = v end)
            SubHeader("State: Soulstone in bags but not applied")
            GlowAndSound(function() return get().states.use end)
            SubHeader("State: no Soulstone in bags")
            GlowAndSound(function() return get().states.create end)
        end)
        local an = function() return ns.db.soulstone.announce end
        local function Text(label, key)
            TextArea(label, function() return an()[key] end, function(v) an()[key] = v end,
                ns.defaults.soulstone.announce[key], { P_NAME_SS, P_TIME })
        end
        SubHeader("Soulstone messages")
        Check("Tell the group who has your Soulstone", function() return an().group end, function(v) an().group = v end)
        Text("Group message", "groupText")
        Check("Whisper the player who got it", function() return an().whisper end, function(v) an().whisper = v end)
        Text("Whisper", "whisperText")
        Check("Tell the group when it's about to run out", function() return an().expire end, function(v) an().expire = v end)
        Slider("Seconds before it runs out", 10, 300, 10, function() return an().expireSeconds end, function(v) an().expireSeconds = v end)
        Text("Running-out message", "expireText")
        Note("The messages go to the instance, raid or party chat, whichever you're in.")
        local lb = T("soulstoneLabel")
        SubHeader("Soulstone target label")
        Check("Show label (name + timer) when used on another player", function() return lb().enabled end, function(v) lb().enabled = v end)
        Check("Show timer (without name) when Soulstone is on yourself (yours or another warlock's)", function() return lb().showSelf end, function(v) lb().showSelf = v end)
        Check("Lock label position", function() return lb().locked end, function(v) lb().locked = v end)
        Check("Show Soulstone icon left of the timer", function() return lb().showIcon end, function(v) lb().showIcon = v end)
        Slider("Background opacity, %", 0, 100, 5, function() return math.floor(lb().bgAlpha * 100 + 0.5) end, function(v) lb().bgAlpha = v / 100 end)
        FontRows(lb, { { "Name size", "nameSize" }, { "Timer size", "timerSize" } })
        Color("Timer color", function() return lb().timerColor end, function(v) lb().timerColor = v end)
        for _, z in ipairs({ { "warn", "Timer: warning zone" }, { "crit", "Timer: critical zone" } }) do
            local get = function() return lb().zones[z[1]] end
            SubHeader(z[2])
            Check("Enable", function() return get().enabled end, function(v) get().enabled = v end)
            Slider("Starts at, seconds left", 5, 1800, 5, function() return get().seconds end, function(v) get().seconds = v end)
            Color("Timer color in this zone", function() return get().color end, function(v) get().color = v end)
            SoundRows(get, "Play sound when the zone starts")
        end
        SubHeader("Timer: Soulstone ran out")
        SoundRows(function() return lb().expired end, "Play sound when the timer runs out")
        Slider("Preview timer speed, x", 1, 600, 1, function() return lb().previewSpeed end, function(v) lb().previewSpeed = v end)
        Note("The critical zone wins where the zones overlap. In preview mode the timer runs faster by the speed above " ..
            "(300x: a second per 5 minutes) and the sounds play on every cycle.")
    end

    -- 5. Demon
    Page("pet", "Demon (pet)", "Interface\\Icons\\Spell_Shadow_SummonImp")
    IconSection("Demon (pet)", "pet", "Interface\\Icons\\Spell_Shadow_SummonImp", function(get)
        GlowAndSound(get)
        if ns.IsKnown(ns.data.demonicSacrifice) or ns.IsKnown(ns.data.soulLink) then
            SubHeader("Talents")
        end
        if ns.IsKnown(ns.data.demonicSacrifice) then
            Check("Remind to sacrifice the demon (Demonic Sacrifice)", function() return get().sacrifice end, function(v) get().sacrifice = v end)
            GlowAndSound(function() return get().states.sacrifice end)
        end
        if ns.IsKnown(ns.data.soulLink) then
            Check("Remind to cast Soul Link", function() return get().soulLink end, function(v) get().soulLink = v end)
            GlowAndSound(function() return get().states.soulLink end)
        end
        SubHeader("Demon per click / modifier")
        local P = ns.modules.pet
        for _, slot in ipairs(P.SLOTS) do
            if P.SlotAvailable(slot) then
                local values = function()
                    local list = {}
                    if slot.key ~= "none" then list[1] = { value = "default", text = "Same as click" } end
                    for _, d in ipairs(ns.data.demons) do
                        list[#list + 1] = { value = d.key, text = P.DemonName(d.key) .. (ns.DemonSpell(d) and "" or " " .. L["(not learned)"]) }
                    end
                    return list
                end
                Select(slot.text, values, function() return get().bindings[slot.key] end, function(v) get().bindings[slot.key] = v end)
            end
        end
    end)

    -- 5b. Summon queue
    do
        local su = T("summon")
        Page("summon", "Summon queue", "Interface\\Icons\\Spell_Shadow_Twilight")
        Header("Summon queue", "Interface\\Icons\\Spell_Shadow_Twilight")
        Check("Enable", function() return su().enabled end, function(v) su().enabled = v end)
        Check("Lock position", function() return su().locked end, function(v) su().locked = v end)
        Slider("Background opacity, %", 0, 100, 5, function() return math.floor(su().bgAlpha * 100 + 0.5) end, function(v) su().bgAlpha = v / 100 end)
        Slider("Remove from the queue after, minutes", 1, 30, 1, function() return su().timeout end, function(v) su().timeout = v end)
        local sd = ns.defaults.summon
        TextArea("Keywords (comma-separated)", function() return su().keywords end, function(v) su().keywords = v end,
            sd.keywords)
        SoundRows(su, "Play sound when someone joins the queue")
        local an = function() return su().announce end
        Check("Announce the summon in group chat", function() return an().group end, function(v) an().group = v end)
        TextArea("Group message", function() return an().groupText end, function(v) an().groupText = v end,
            sd.announce.groupText, { P_NAME_SUMMON })
        Check("Whisper the player being summoned", function() return an().whisper end, function(v) an().whisper = v end)
        TextArea("Whisper", function() return an().whisperText end, function(v) an().whisperText = v end,
            sd.announce.whisperText, { P_NAME_SUMMON })
        local cc = function() return su().clickersCall end
        SubHeader("Not enough people at the portal")
        Check("Ask for help when fewer than 2 stand next to you", function() return cc().enabled end, function(v) cc().enabled = v end)
        TextArea("Message to the group", function() return cc().groupText end, function(v) cc().groupText = v end,
            sd.clickersCall.groupText, { P_N })
        TextArea("Message for a sold summon", function() return cc().publicText end, function(v) cc().publicText = v end,
            sd.clickersCall.publicText, { P_N, P_ZONE, P_PRICE, P_NAME_SUMMON })
        Check("Sold summon: to the party or raid", function() return cc().party end, function(v) cc().party = v end)
        Check("Sold summon: to /say", function() return cc().say end, function(v) cc().say = v end)
        Check("Sold summon: to /yell", function() return cc().yell end, function(v) cc().yell = v end)
        Check("Sold summon: to the ad channel (Trade)", function() return cc().trade end, function(v) cc().trade = v end)
        Note("Sent when you click a player in the queue and fewer than two group members stand next to you, at most " ..
            "once per 15 seconds. Your group's summons ask the group; a summon you sold asks everyone around too.")
        Note("Group members who write one of the keywords in party, raid or a whisper join the queue. Click a " ..
            "player to target them and cast Ritual of Summoning; right click removes them. Players leave the queue " ..
            "once they're next to you or leave the group. The window shows only while someone is waiting.")

        local se = T("summonSell")
        local function Text(label, get, set)
            local e = Input(label, 250, function(text) set(text); Changed() end)
            refreshers[#refreshers + 1] = function() e:SetText(get() or ""); e:SetCursorPosition(0) end
        end
        Page("sell", "Selling summons", "Interface\\Icons\\INV_Misc_Coin_01")
        Header("Selling summons", "Interface\\Icons\\INV_Misc_Coin_01")
        Check("Selling summons (/wu sell)", function() return se().enabled end, function(v) se().enabled = v end)
        Check("Lock position", function() return se().locked end, function(v) se().locked = v end)
        local sell = ns.modules.summonSell
        Text("Price: 5 or 5g, 1g50s, 75s (0 = ask the buyer)", function() return sell.FormatPrice(se().price) end,
            function(v)
                local copper = sell.ParsePrice(v)
                if copper then se().price = copper else ns.Print(L["can't read the price \"%s\"."], v) end
            end)
        Text("Channel for the ad", function() return se().adChannel end, function(v) se().adChannel = v end)
        local sd = ns.defaults.summonSell
        TextArea("Buyer keywords (comma-separated)", function() return se().keywords end, function(v) se().keywords = v end,
            sd.keywords)
        local function Template(label, key, legend)
            TextArea(label, function() return se().templates[key] end, function(v) se().templates[key] = v end,
                sd.templates[key], legend)
        end
        Template("Offer without a price", "ask", { P_NAME_BUYER, P_ZONE, P_CLICKERS })
        Template("Offer with a price", "priced", { P_NAME_BUYER, P_ZONE, P_PRICE, P_CLICKERS })
        Template("Clickers sentence", "clickers", { P_N })
        Template("Ad", "ad", { P_ZONE, P_PRICE, P_CLICKERS })
        SoundRows(se, "Play sound when a new buyer shows up")
        Note("Players outside your group who write a buyer keyword in a public channel, /say, /yell or a whisper are " ..
            "listed while selling is on. Click a buyer to whisper the offer, Shift + click to invite them too; once " ..
            "they join they go on to the summon queue. The Ad button posts the ad to the channel above. Nothing is " ..
            "sent without your click.")
    end

    -- 5c. Enslave Demon timer
    if ns.modules.enslave then
        local en = T("enslave")
        Page("enslave", "Enslave Demon timer", ns.SpellTexture(ns.data.enslaveDemon[1]) or "Interface\\Icons\\Spell_Shadow_EnslaveDemon")
        Header("Enslave Demon timer", ns.SpellTexture(ns.data.enslaveDemon[1]) or "Interface\\Icons\\Spell_Shadow_EnslaveDemon")
        Check("Enable", function() return en().enabled end, function(v) en().enabled = v end)
        Check("Lock position", function() return en().locked end, function(v) en().locked = v end)
        Slider("Background opacity, %", 0, 100, 5, function() return math.floor(en().bgAlpha * 100 + 0.5) end, function(v) en().bgAlpha = v / 100 end)
        FontRows(en, { { "Font size", "size" } })
        Color("Timer color", function() return en().color end, function(v) en().color = v end)
        for _, z in ipairs({ { "warn", "Timer: warning zone" }, { "crit", "Timer: critical zone" } }) do
            local get = function() return en().zones[z[1]] end
            SubHeader(z[2])
            Check("Enable", function() return get().enabled end, function(v) get().enabled = v end)
            Slider("Starts at, seconds left", 5, 300, 5, function() return get().seconds end, function(v) get().seconds = v end)
            Color("Timer color in this zone", function() return get().color end, function(v) get().color = v end)
            SoundRows(get, "Play sound when the zone starts")
        end
        SubHeader("Timer: the demon is free")
        SoundRows(function() return en().expired end, "Play sound when the timer runs out")
        Slider("Preview timer speed, x", 1, 300, 1, function() return en().previewSpeed end, function(v) en().previewSpeed = v end)
        Note("Shows how long your enslaved demon stays under control (up to 5 minutes). It can break free earlier. " ..
            "The critical zone wins where the zones overlap. In preview mode the timer runs faster by the speed above " ..
            "(30x: 5 minutes in 10 seconds) and the sounds play on every cycle.")
    end

    -- 5d. Trainer
    if ns.modules.trainer then
        local tr = T("trainer")
        Page("trainer", "New ranks at the trainer", "Interface\\Icons\\INV_Misc_Book_09")
        Header("New ranks at the trainer", "Interface\\Icons\\INV_Misc_Book_09")
        Check("Tell me after a level up what I can learn", function() return tr().enabled end, function(v) tr().enabled = v end)
        SoundRows(tr)
        Note("The game lists what a trainer teaches only while its window is open, so visit your class trainer once: " ..
            "the addon remembers the ranks you can't learn yet and their levels. /wu trainer shows what's waiting now.")
    end

    -- 6. Grimoires
    if ns.modules.grimoires then
        local gr = T("grimoires")
        Page("grimoires", "Grimoires", ns.ItemIcon(16302) or "Interface\\Icons\\INV_Misc_Book_06")
        Header("Grimoires", ns.ItemIcon(16302) or "Interface\\Icons\\INV_Misc_Book_06")
        Check("Mark grimoires your demons already know at vendors", function() return gr().merchant end, function(v) gr().merchant = v end)
        Check("Show what your demons know in grimoire tooltips", function() return gr().tooltip end, function(v) gr().tooltip = v end)
        local checked = Label("")
        checked:SetWidth(WIDTH - LEFT - 20)
        checked:SetJustifyH("LEFT")
        refreshers[#refreshers + 1] = function()
            local list, rest = ns.modules.grimoires:CheckedDemons()
            checked:SetText(L["Demons checked: "] .. "|cffffd100" .. (#list > 0 and table.concat(list, ", ") or L["none yet"]) .. "|r\n" ..
                (#rest > 0 and L["Not checked yet: "] .. "|cffff8040" .. table.concat(rest, ", ") .. "|r" .. L[" (summon each one once)"]
                    or L["All your demons are checked."]))
        end
        y = y - 36
        Note("A demon's spells can only be read while it's summoned: summon each demon once, and from then on " ..
            "the addon remembers what it knows and keeps it up to date. To check a demon, just summon it anywhere: " ..
            "its spells are read in a moment, and you can summon another one right after. At a vendor, learned " ..
            "grimoires get a check mark and turn grey; a question mark means that demon hasn't been checked yet. " ..
            "Grimoires for demons you can't summon yet are dark grey with a red cross. A bag icon means you already have " ..
            "that grimoire in your bags.")
    end

    FinishPage()
    BuildNav()
    ShowPage(currentPage)
end

function ns.ToggleOptions()
    if not panel then Build(); BuildContent() end
    panel:SetShown(not panel:IsShown())
end

-- Entry in the game's AddOns settings list that opens the window.
function ns.InitOptions()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    local p = CreateFrame("Frame")
    local t = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    local logo = p:CreateTexture(nil, "ARTWORK")
    logo:SetSize(32, 32)
    logo:SetPoint("TOPLEFT", 16, -12)
    logo:SetTexture(ns.LOGO)
    t:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    t:SetText("WarlockUpkeep!")
    local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    b:SetSize(200, 26)
    b:SetPoint("TOPLEFT", 16, -50)
    b:SetText(L["Open settings (/wu)"])
    settingsButton = b
    b:SetScript("OnClick", function()
        if SettingsPanel then HideUIPanel(SettingsPanel) end
        if not panel or not panel:IsShown() then ns.ToggleOptions() end
    end)
    local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, p, "WarlockUpkeep!")
    if ok and category then pcall(Settings.RegisterAddOnCategory, category) end
end
