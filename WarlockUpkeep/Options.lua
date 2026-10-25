local ADDON, ns = ...

local panel, content
local y = 0
local refreshers = {}
local LEFT, RIGHT = 20, 230

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
    fs:SetText(text)
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
    fs:SetText(text)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false); Changed() end)
    refreshers[#refreshers + 1] = function() cb:SetChecked(get() and true or false) end
    y = y - 26
end

local function Slider(text, min, max, step, get, set)
    Label(text)
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
    local val = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    val:SetPoint("LEFT", s, "RIGHT", 8, 0)
    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        val:SetText(v)
        if not self.refreshing and v ~= get() then set(v); ns:ApplyAll() end
    end)
    refreshers[#refreshers + 1] = function()
        s.refreshing = true
        s:SetValue(get())
        s.refreshing = nil
        val:SetText(get())
    end
    y = y - 26
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
    fs:SetText(text)

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

-- Cycle selector: left click = next, right click = previous.
local function Cycle(text, values, get, set, extra)
    Label(text)
    local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    btn:SetSize(170, 22)
    btn:SetPoint("TOPLEFT", RIGHT, y + 4)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local function List() return type(values) == "function" and values() or values end
    local function Index()
        local list, cur = List(), get()
        for i, v in ipairs(list) do if v.value == cur then return i end end
        return 1
    end
    btn:SetScript("OnClick", function(_, mouse)
        local list = List()
        local i = Index() + (mouse == "RightButton" and -1 or 1)
        if i > #list then i = 1 elseif i < 1 then i = #list end
        set(list[i].value)
        Changed()
    end)
    refreshers[#refreshers + 1] = function()
        local list = List()
        local item = list[Index()]
        btn:SetText(item and item.text or tostring(get()))
    end
    if extra then
        local e = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        e:SetSize(50, 22)
        e:SetPoint("LEFT", btn, "RIGHT", 4, 0)
        e:SetText(extra.text)
        e:SetScript("OnClick", extra.onClick)
    end
    y = y - 28
end

local function Button(text, width, onClick, x)
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetPoint("TOPLEFT", x or LEFT, y + 4)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Note(text)
    local fs = Label(text, LEFT, "GameFontDisableSmall")
    fs:SetWidth(440)
    fs:SetJustifyH("LEFT")
    y = y - (fs:GetStringHeight() + 6)
end

------------------------------------------------------------------------
-- Composite rows
------------------------------------------------------------------------
local function T(key) return function() return ns.db[key] end end

local function TestSound(value)
    if not ns.PlaySound(value) then
        ns.Print("can't play %s. Custom files need a full game restart after adding them.", tostring(value))
    end
end

local function SoundRows(getTbl, soundText)
    Check(soundText or "Play sound", function() return getTbl().sound end, function(v) getTbl().sound = v end)
    Cycle("Sound", ns.GetSoundList, function() return getTbl().soundName end, function(v) getTbl().soundName = v end,
        { text = "Test", onClick = function() TestSound(getTbl().soundName) end })
end

local function Input(text, width, onEnter)
    Label(text)
    local e = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    e:SetSize(width, 20)
    e:SetPoint("TOPLEFT", RIGHT + 6, y + 3)
    e:SetAutoFocus(false)
    e:SetScript("OnEnterPressed", function(self) onEnter(self:GetText()); self:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    y = y - 28
    return e
end

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
    Cycle("Font", ns.GetFontList, function() return get().font end, function(v) get().font = v end)
    Cycle("Outline", ns.OUTLINES, function() return get().outline end, function(v) get().outline = v end)
    for _, s in ipairs(sizes) do
        Slider(s[1], 8, 48, 1, function() return get()[s[2]] end, function(v) get()[s[2]] = v end)
    end
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
    f:SetSize(540, 620)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
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

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -32, 10)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(490, 100)
    scroll:SetScrollChild(content)

    -- General
    Header("General", ns.LOGO)
    Check("Preview mode (show all icons for positioning)", function() return ns.db.preview end, function(v) ns.db.preview = v end)
    Check("Simulate combat (opacity, highlight, hiding, click-through)", function() return ns.db.previewCombat end, function(v) ns.db.previewCombat = v end)
    Check("Show minimap button", function() return not ns.db.minimap.hide end, function(v) ns.db.minimap.hide = not v end)
    Check("Lock minimap button position", function() return ns.db.minimap.locked end, function(v) ns.db.minimap.locked = v end)
    Cycle("Move icons with", ns.GetMoveModes, function() return ns.db.moveWith end, function(v) ns.db.moveWith = v end)
    Check("Hide all icons while on a flight path", function() return ns.db.hideOnTaxi end, function(v) ns.db.hideOnTaxi = v end)
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
    Cycle("Highlight type", ns.GLOW_MODES, function() return ns.db.glowMode end, function(v) ns.db.glowMode = v end)
    Cycle("Outline style", ns.GLOW_STYLES, function() return ns.db.glowStyle end, function(v) ns.db.glowStyle = v end)
    Slider("Fill opacity, %", 5, 100, 5, function() return math.floor(ns.db.fillAlpha * 100 + 0.5) end, function(v) ns.db.fillAlpha = v / 100 end)
    Button("Lock all", 110, function() ns:SetAllLocked(true); Changed() end)
    Button("Unlock all", 110, function() ns:SetAllLocked(false); Changed() end, LEFT + 116)
    Button("Reset settings", 130, function()
        if InCombatLockdown() then ns.Print("cannot reset in combat."); return end
        ns:ResetDB(); Changed()
    end, LEFT + 232)
    y = y - 30
    Note("Icons: left click performs the action; they are moved as set in \"Move icons with\" (only when unlocked). " ..
        "If a modifier is used for moving, clicks with that modifier do nothing while the icon is unlocked. " ..
        "Labels and the shard counter are moved with left-drag. Changes made in combat apply after combat.")

    -- Custom sounds: the player's own files, offered in every sound list.
    Header("Custom sounds", "Interface\\Icons\\INV_Misc_Drum_01")
    Note("Put .ogg or .mp3 files into World of Warcraft/<client>/Interface/WarlockUpkeepSounds/ and fully restart " ..
        "the game (a /reload doesn't find new files). Then add each file here by its name, e.g. alarm.ogg, " ..
        "or by a full path starting with Interface\\. Added files appear in every Sound list.")
    local function AddSound(text)
        local path = ns.NormalizeSoundPath(text)
        if not path then return end
        for _, c in ipairs(ns.db.customSounds) do
            if c.path:lower() == path:lower() then ns.Print("already added: %s", path); return end
        end
        local name = path:match("([^\\]+)$"):gsub("%.%w+$", "")
        table.insert(ns.db.customSounds, { name = name, path = path })
        if not ns.PlaySound(path) then
            ns.Print("added %s, but it can't be played yet: check the name or restart the game.", path)
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
    Cycle("Added files", CustomList, function() return selected or CustomList()[1].value end, function(v) selected = v end,
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
        IconSection("Demon Armor / Demon Skin", "armor", "Interface\\Icons\\Spell_Shadow_RagingScream", function(get)
            -- Clients that hide auras from addons in combat (Forever).
            if C_Secrets then
                Note("Important: add Demon Skin and Demon Armor to the Cooldown Manager's Tracked Buffs. " ..
                    "In combat the game hides your buffs from addons, and the Cooldown Manager is what lets " ..
                    "this icon notice the armor being removed or recast during a fight.")
            end
            GlowAndSound(get)
        end)
    end

    -- 2. Soul Shards
    if ns.modules.shards then
        local sh = T("shards")
        Header("Soul Shard counter", "Interface\\Icons\\INV_Misc_Gem_Amethyst_02")
        Check("Enable", function() return sh().enabled end, function(v) sh().enabled = v end)
        Check("Lock position", function() return sh().locked end, function(v) sh().locked = v end)
        Check("Show shard icon", function() return sh().showIcon end, function(v) sh().showIcon = v end)
        Slider("Icon size", 12, 96, 1, function() return sh().iconSize end, function(v) sh().iconSize = v end)
        Slider("Background opacity, %", 0, 100, 5, function() return math.floor(sh().bgAlpha * 100 + 0.5) end, function(v) sh().bgAlpha = v / 100 end)
        Slider("Spare shards", 0, 10, 1, function() return sh().spare end, function(v) sh().spare = v end)
        Check("Count Ritual of Summoning in recommended amount", function() return sh().includeRitual end, function(v) sh().includeRitual = v end)
        local recommended = Label("")
        refreshers[#refreshers + 1] = function()
            local n, parts = ns.modules.shards:Desired()
            local list = table.concat(parts, ", ")
            recommended:SetText(string.format("Recommended now: |cffffd100%d|r  (%s%s+%d spare)", n, list, list ~= "" and " " or "", sh().spare))
        end
        y = y - 22
        Check("Low threshold = recommended amount", function() return sh().autoThreshold end, function(v) sh().autoThreshold = v end)
        Slider("Highlight when fewer than", 0, 40, 1, function() return sh().threshold end, function(v) sh().threshold = v end)
        Check("Show the threshold next to the count (current/threshold)", function() return sh().showThreshold end, function(v) sh().showThreshold = v end)
        SubHeader("Text")
        FontRows(sh, { { "Font size", "fontSize" } })
        Color("Text color", function() return sh().color end, function(v) sh().color = v end)
        Color("Text color when low", function() return sh().lowColor end, function(v) sh().lowColor = v end)
        SubHeader("Low shards alert")
        GlowAndSound(sh)
    end

    -- 3. Healthstone
    IconSection("Healthstone", "healthstone", "Interface\\Icons\\INV_Stone_04")

    -- 4. Soulstone
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

    -- 5. Demon
    IconSection("Demon (pet)", "pet", "Interface\\Icons\\Spell_Shadow_SummonImp", function(get)
        GlowAndSound(get)
        SubHeader("Demon per click / modifier")
        local P = ns.modules.pet
        for _, slot in ipairs(P.SLOTS) do
            if P.SlotAvailable(slot) then
                local values = function()
                    local list = {}
                    if slot.key ~= "none" then list[1] = { value = "default", text = "Same as click" } end
                    for _, d in ipairs(ns.data.demons) do
                        list[#list + 1] = { value = d.key, text = P.DemonName(d.key) .. (ns.DemonSpell(d) and "" or " (not learned)") }
                    end
                    return list
                end
                Cycle(slot.text, values, function() return get().bindings[slot.key] end, function(v) get().bindings[slot.key] = v end)
            end
        end
    end)

    -- 6. Grimoires
    if ns.modules.grimoires then
        local gr = T("grimoires")
        Header("Grimoires", ns.ItemIcon(16302) or "Interface\\Icons\\INV_Misc_Book_06")
        Check("Mark grimoires your demons already know at vendors", function() return gr().merchant end, function(v) gr().merchant = v end)
        Check("Show what your demons know in grimoire tooltips", function() return gr().tooltip end, function(v) gr().tooltip = v end)
        local checked = Label("")
        checked:SetWidth(440)
        checked:SetJustifyH("LEFT")
        refreshers[#refreshers + 1] = function()
            local list = ns.modules.grimoires:CheckedDemons()
            checked:SetText("Demons checked: |cffffd100" .. (#list > 0 and table.concat(list, ", ") or "none yet") .. "|r")
        end
        y = y - 22
        Note("A demon's spells can only be read while it's summoned: summon each demon once, and from then on " ..
            "the addon remembers what it knows and keeps it up to date. At a vendor, learned grimoires get a " ..
            "check mark and turn grey; a question mark means that demon hasn't been checked yet. Grimoires for " ..
            "demons you can't summon yet are grey, without a mark.")
    end

    content:SetHeight(-y + 20)
    f:SetScript("OnShow", function() for _, r in ipairs(refreshers) do r() end end)
end

function ns.ToggleOptions()
    if not panel then Build() end
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
    b:SetText("Open settings (/wu)")
    b:SetScript("OnClick", function()
        if SettingsPanel then HideUIPanel(SettingsPanel) end
        if not panel or not panel:IsShown() then ns.ToggleOptions() end
    end)
    local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, p, "WarlockUpkeep!")
    if ok and category then pcall(Settings.RegisterAddOnCategory, category) end
end
