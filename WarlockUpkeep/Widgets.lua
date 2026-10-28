local _, ns = ...
local L = ns.L

ns.QUESTION_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
ns.LOGO = "Interface\\AddOns\\WarlockUpkeep\\Media\\logo"

------------------------------------------------------------------------
-- Fonts & sounds
------------------------------------------------------------------------
ns.FONTS = {
    { value = "Fonts\\FRIZQT__.TTF",     text = "Friz Quadrata" },
    { value = "Fonts\\FRIZQT___CYR.TTF", text = "Friz Quadrata (Cyrillic)" },
    { value = "Fonts\\ARIALN.TTF",       text = "Arial Narrow" },
    { value = "Fonts\\MORPHEUS.TTF",     text = "Morpheus" },
    { value = "Fonts\\SKURRI.TTF",       text = "Skurri" },
}

ns.OUTLINES = {
    { value = "",             text = "None" },
    { value = "OUTLINE",      text = "Outline" },
    { value = "THICKOUTLINE", text = "Thick outline" },
}

-- Game sounds by SOUNDKIT key; `id` is the fallback when a client lacks the key.
ns.SOUNDS = {
    { value = "RAID_WARNING",                 text = "Raid Warning",        id = 8959 },
    { value = "READY_CHECK",                  text = "Ready Check",         id = 8960 },
    { value = "ALARM_CLOCK_WARNING_1",        text = "Alarm Clock 1",       id = 12867 },
    { value = "ALARM_CLOCK_WARNING_2",        text = "Alarm Clock 2",       id = 12868 },
    { value = "ALARM_CLOCK_WARNING_3",        text = "Alarm Clock 3",       id = 12889 },
    { value = "RAID_BOSS_EMOTE_WARNING",      text = "Boss Emote",          id = 12197 },
    { value = "UI_RAID_BOSS_WHISPER_WARNING", text = "Boss Whisper",        id = 37666 },
    { value = "PVP_THROUGH_QUEUE",            text = "Queue Ready",         id = 8459 },
    { value = "LEVEL_UP",                     text = "Level Up",            id = 888 },
    { value = "IG_PLAYER_INVITE",             text = "Group Invite",        id = 880 },
    { value = "AUCTION_WINDOW_OPEN",          text = "Auction House",       id = 5274 },
    { value = "UI_BNET_TOAST",                text = "Toast",               id = 18019 },
    { value = "TELL_MESSAGE",                 text = "Whisper",             id = 3081 },
    { value = "MAP_PING",                     text = "Map Ping",            id = 3175 },
}

-- Folder for the player's own sound files; a bare file name in "Custom sounds" points here.
-- It lies outside the addon folder so addon updates don't delete the files.
ns.CUSTOM_SOUND_DIR = "Interface\\WarlockUpkeepSounds\\"

function ns.GetFontList()
    local list, seen = {}, {}
    for _, f in ipairs(ns.FONTS) do list[#list + 1] = f; seen[f.value] = true end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for _, name in ipairs(LSM:List("font")) do
            local path = LSM:Fetch("font", name)
            if path and not seen[path] then
                list[#list + 1] = { value = path, text = name }
                seen[path] = true
            end
        end
    end
    return list
end

function ns.ApplyFont(fs, path, size, outline)
    local ok = fs:SetFont(path or STANDARD_TEXT_FONT, size, outline or "")
    if ok == false or not fs:GetFont() then
        fs:SetFont(STANDARD_TEXT_FONT, size, outline or "")
    end
end

-- Player names can come from other regions. The chosen font usually covers Latin only,
-- so names use a font family that takes Cyrillic and CJK glyphs from the game's own
-- fonts (the same files the default UI uses for them).
local NAME_ALPHABETS = {
    { alphabet = "russian",            file = "Fonts\\FRIZQT___CYR.TTF" },
    { alphabet = "korean",             file = "Fonts\\2002.TTF" },
    { alphabet = "simplifiedchinese",  file = "Fonts\\ARKai_T.ttf" },
    { alphabet = "traditionalchinese", file = "Fonts\\blei00d.TTF" },
}
local nameFamilies, nameFamilyCount = {}, 0
local fontProbe

-- A font set with SetFont stays on the FontString and overrides any font object,
-- so the chosen font is checked on a hidden probe and `fs` only gets the family.
function ns.ApplyNameFont(fs, path, size, outline)
    if not CreateFontFamily then return ns.ApplyFont(fs, path, size, outline) end
    if not fontProbe then fontProbe = UIParent:CreateFontString(nil, "BACKGROUND") end
    ns.ApplyFont(fontProbe, path, size, outline)
    local file = fontProbe:GetFont()
    if not file then return ns.ApplyFont(fs, path, size, outline) end
    outline = outline or ""
    local key = file .. "|" .. size .. "|" .. outline
    local family = nameFamilies[key]
    if family == nil then
        local members = { { alphabet = "roman", file = file, height = size, flags = outline } }
        for _, a in ipairs(NAME_ALPHABETS) do
            members[#members + 1] = { alphabet = a.alphabet, file = a.file, height = size, flags = outline }
        end
        nameFamilyCount = nameFamilyCount + 1
        local ok, f = pcall(CreateFontFamily, "WarlockUpkeepNameFont" .. nameFamilyCount, members)
        if not ok then ns.Print(L["can't create the name font: %s"], tostring(f)) end
        family = ok and f or false
        nameFamilies[key] = family
    end
    if family then fs:SetFontObject(family) else ns.ApplyFont(fs, path, size, outline) end
end

-- Game sounds, then the player's files, then sounds from LibSharedMedia (value = file path).
function ns.GetSoundList()
    local list, seen = {}, {}
    for _, s in ipairs(ns.SOUNDS) do list[#list + 1] = s; seen[s.value] = true end
    for _, c in ipairs(ns.db and ns.db.customSounds or {}) do
        if not seen[c.path] then
            list[#list + 1] = { value = c.path, text = string.format(L["%s (custom)"], c.name) }
            seen[c.path] = true
        end
    end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for _, name in ipairs(LSM:List("sound")) do
            local path = LSM:Fetch("sound", name)
            if path and path ~= "" and not seen[path] then
                list[#list + 1] = { value = path, text = name }
                seen[path] = true
            end
        end
    end
    return list
end

-- "alarm.ogg" -> Interface\WarlockUpkeepSounds\alarm.ogg; full paths are kept.
function ns.NormalizeSoundPath(path)
    path = (path or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("/", "\\")
    if path == "" then return nil end
    if not path:lower():find("^interface\\") then path = ns.CUSTOM_SOUND_DIR .. path end
    return path
end

-- Returns whether the sound will play (false for a missing or unreadable file).
function ns.PlaySound(name)
    if not name then return false end
    for _, s in ipairs(ns.SOUNDS) do
        if s.value == name then
            local id = (SOUNDKIT and SOUNDKIT[s.value]) or s.id
            local ok, willPlay = pcall(PlaySound, id, "Master")
            return ok and willPlay ~= false
        end
    end
    local ok, willPlay = pcall(PlaySoundFile, name, "Master")
    return ok and willPlay and true or false
end

------------------------------------------------------------------------
-- Glow. Styles:
--   proc  - Blizzard proc flipbook running around the icon (as in Cooldown Manager)
--   pixel - thin lines running around the border
--   pulse - pulsing solid border
------------------------------------------------------------------------
ns.GLOW_STYLES = {
    { value = "proc",  text = "Proc (Cooldown Manager)" },
    { value = "pixel", text = "Running lines" },
    { value = "pulse", text = "Pulsing border" },
}

-- What the highlight looks like: an outline (style above), a translucent color fill over the icon, or both.
ns.GLOW_MODES = {
    { value = "outline", text = "Outline" },
    { value = "fill",    text = "Fill icon" },
    { value = "both",    text = "Outline + fill" },
}

local PROC_ATLAS = "UI-HUD-ActionBar-Proc-Loop-Flipbook"
local hasProcAtlas
local function HasProcAtlas()
    if hasProcAtlas == nil then
        hasProcAtlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(PROC_ATLAS) ~= nil or false
    end
    return hasProcAtlas
end

-- The proc art is gold; keep it native for the default gold, otherwise desaturate and tint.
local function IsGold(c)
    return c[1] > 0.95 and math.abs(c[2] - 0.82) < 0.06 and c[3] < 0.1
end

local function BuildProc(g, parent)
    local p = CreateFrame("Frame", nil, g)
    p:SetPoint("CENTER", parent, "CENTER")
    local t = p:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints()
    t:SetAtlas(PROC_ATLAS)
    local ag = t:CreateAnimationGroup()
    ag:SetLooping("REPEAT")
    local fb = ag:CreateAnimation("FlipBook")
    fb:SetDuration(1)
    fb:SetFlipBookRows(6)
    fb:SetFlipBookColumns(5)
    fb:SetFlipBookFrames(30)
    fb:SetFlipBookFrameWidth(0)
    fb:SetFlipBookFrameHeight(0)
    p.anim = ag

    function p:Apply(color, size)
        self:SetSize(size * 1.4, size * 1.4)
        if IsGold(color) then
            t:SetDesaturated(false)
            t:SetVertexColor(1, 1, 1, 1)
        else
            t:SetDesaturated(true)
            t:SetVertexColor(color[1], color[2], color[3], 1)
        end
    end
    return p
end

local PIXEL_LINES, PIXEL_THICKNESS, PIXEL_PERIOD = 8, 2, 4

-- Places a segment of length `len` starting at perimeter offset `s` (clockwise
-- from the top-left corner). The segment must fit on a single side.
local function PlaceSegment(t, f, s, len, w, h)
    local th = PIXEL_THICKNESS
    t:ClearAllPoints()
    if s < w then
        t:SetPoint("TOPLEFT", f, "TOPLEFT", s, 0)
        t:SetSize(len, th)
    elseif s < w + h then
        t:SetPoint("TOPLEFT", f, "TOPLEFT", w - th, -(s - w))
        t:SetSize(th, len)
    elseif s < 2 * w + h then
        local x = w - (s - w - h)
        t:SetPoint("TOPLEFT", f, "TOPLEFT", x - len, -(h - th))
        t:SetSize(len, th)
    else
        local y = h - (s - 2 * w - h)
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(y - len))
        t:SetSize(th, len)
    end
end

local function SideEnd(s, w, h)
    if s < w then return w elseif s < w + h then return w + h elseif s < 2 * w + h then return 2 * w + h end
    return 2 * (w + h)
end

local function BuildPixel(g, parent)
    local p = CreateFrame("Frame", nil, g)
    p:SetPoint("TOPLEFT", parent, "TOPLEFT", -2, 2)
    p:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 2, -2)
    p.heads, p.tails = {}, {}
    for i = 1, PIXEL_LINES do
        p.heads[i] = p:CreateTexture(nil, "OVERLAY")
        p.tails[i] = p:CreateTexture(nil, "OVERLAY")
        p.heads[i]:SetColorTexture(1, 1, 1, 1)
        p.tails[i]:SetColorTexture(1, 1, 1, 1)
    end
    p.progress = 0
    p:SetScript("OnUpdate", function(self, dt)
        self.progress = (self.progress + dt / PIXEL_PERIOD) % 1
        local w, h = self:GetSize()
        if not w or w <= 0 or h <= 0 then return end
        local perimeter = 2 * (w + h)
        local len = perimeter / PIXEL_LINES * 0.5
        for i = 1, PIXEL_LINES do
            local s = ((self.progress + (i - 1) / PIXEL_LINES) % 1) * perimeter
            local first = math.min(len, SideEnd(s, w, h) - s)
            PlaceSegment(self.heads[i], self, s, first, w, h)
            local rest = len - first
            if rest > 0.5 then
                PlaceSegment(self.tails[i], self, SideEnd(s, w, h) % perimeter, rest, w, h)
                self.tails[i]:Show()
            else
                self.tails[i]:Hide()
            end
        end
    end)

    function p:Apply(color)
        for i = 1, PIXEL_LINES do
            self.heads[i]:SetVertexColor(color[1], color[2], color[3], 1)
            self.tails[i]:SetVertexColor(color[1], color[2], color[3], 1)
        end
    end
    return p
end

local function BuildPulse(g, parent)
    local p = CreateFrame("Frame", nil, g)
    p:SetPoint("TOPLEFT", parent, "TOPLEFT", -2, 2)
    p:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 2, -2)
    local edges = {}
    for i = 1, 4 do
        edges[i] = p:CreateTexture(nil, "OVERLAY")
        edges[i]:SetColorTexture(1, 1, 1, 1)
    end
    local top, bottom, left, right = unpack(edges)
    top:SetPoint("TOPLEFT");        top:SetPoint("TOPRIGHT");        top:SetHeight(2)
    bottom:SetPoint("BOTTOMLEFT");  bottom:SetPoint("BOTTOMRIGHT");  bottom:SetHeight(2)
    left:SetPoint("TOPLEFT");       left:SetPoint("BOTTOMLEFT");     left:SetWidth(2)
    right:SetPoint("TOPRIGHT");     right:SetPoint("BOTTOMRIGHT");   right:SetWidth(2)

    local ag = p:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.3)
    a:SetDuration(0.6)
    p.anim = ag

    function p:Apply(color)
        for _, t in ipairs(edges) do t:SetVertexColor(color[1], color[2], color[3], 1) end
    end
    return p
end

local builders = { proc = BuildProc, pixel = BuildPixel, pulse = BuildPulse }

function ns.CreateGlow(parent)
    local g = CreateFrame("Frame", nil, parent)
    g:SetAllPoints()
    g:SetFrameLevel(parent:GetFrameLevel() + 5)
    g.styles = {}

    function g:SetGlow(on, color, size)
        local db = ns.db
        if on and ns.CombatLook() and db and not db.combat.glow then on = false end
        local mode = db and db.glowMode or "outline"

        if on and mode ~= "outline" then
            if not self.fill then
                self.fill = self:CreateTexture(nil, "ARTWORK")
                self.fill:SetAllPoints(parent)
            end
            self.fill:SetColorTexture(color[1], color[2], color[3], db and db.fillAlpha or 0.4)
            self.fill:Show()
        elseif self.fill then
            self.fill:Hide()
        end

        on = on and mode ~= "fill"
        local style = db and db.glowStyle or "proc"
        if style == "proc" and not HasProcAtlas() then style = "pixel" end
        for key, s in pairs(self.styles) do
            if key ~= style or not on then
                s:Hide()
                if s.anim then s.anim:Stop() end
            end
        end
        if not on then return end
        local s = self.styles[style]
        if not s then
            s = builders[style](self, parent)
            self.styles[style] = s
        end
        s:Apply(color, size or parent:GetWidth())
        s:Show()
        if s.anim and not s.anim:IsPlaying() then s.anim:Play() end
    end
    return g
end

------------------------------------------------------------------------
-- Moving
------------------------------------------------------------------------
-- How action icons are dragged (labels and the shard counter use any left-drag).
ns.MOVE_MODES = {
    { value = "right", text = "Right-drag" },
    { value = "shift", text = "Shift + left-drag" },
    { value = "ctrl",  text = "Ctrl + left-drag" },
    { value = "alt",   text = "Alt + left-drag" },
    { value = "meta",  text = "Cmd + left-drag", mac = true },
}

function ns.GetMoveModes()
    local list = {}
    for _, m in ipairs(ns.MOVE_MODES) do
        if not m.mac or (IsMacClient and IsMacClient()) then list[#list + 1] = m end
    end
    return list
end

function ns.MoveModeText()
    for _, m in ipairs(ns.MOVE_MODES) do
        if m.value == ns.db.moveWith then return L[m.text] end
    end
    return L["Right-drag"]
end

local modifierDown = {
    shift = function() return IsShiftKeyDown() end,
    ctrl  = function() return IsControlKeyDown() end,
    alt   = function() return IsAltKeyDown() end,
    meta  = function() return IsMetaKeyDown and IsMetaKeyDown() end,
}

-- Stores the position as an offset of the frame's center from UIParent's center.
-- StartMoving anchors frames to the screen, which can differ from UIParent
-- (e.g. the Mac notch safe area), so the raw GetPoint() result would drift.
local function SavePoint(frame, cfg)
    local cx, cy = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not cx or not ux then return end
    local ratio = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
    cfg.point = { "CENTER", "CENTER", cx - ux * ratio, cy - uy * ratio }
end

------------------------------------------------------------------------
-- Snapping: on drop, align a frame to nearby addon frames
--   Y: top, bottom, center, or stacked above/below
--   X: center, left/right edges, or placed next to it
------------------------------------------------------------------------
ns.movables = {}

-- Frame rect in UIParent units.
local function Rect(f)
    local l, b, w, h = f:GetRect()
    if not l then return nil end
    local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    l, b, w, h = l * k, b * k, w * k, h * k
    return { l = l, b = b, r = l + w, t = b + h, cx = l + w / 2, cy = b + h / 2, w = w, h = h }
end

local function Near(a, b, range)
    return a.l - range <= b.r and b.l - range <= a.r and a.b - range <= b.t and b.b - range <= a.t
end

-- Returns the offset (UIParent units) that snaps `frame` to its neighbours.
function ns.SnapOffset(frame)
    local cfg = ns.db.snap
    if not cfg.enabled then return 0, 0 end
    local me = Rect(frame)
    if not me then return 0, 0 end
    local dist, gap = cfg.distance, cfg.gap
    local bestX, bestY

    local function Try(best, target, current)
        local d = target - current
        if math.abs(d) <= dist and (not best or math.abs(d) < math.abs(best)) then return d end
        return best
    end

    for _, o in ipairs(ns.movables) do
        if o ~= frame and o:IsVisible() and o:GetAlpha() > 0 then
            local r = Rect(o)
            if r and Near(me, r, dist + gap + 40) then
                bestX = Try(bestX, r.cx, me.cx)                     -- centers
                bestX = Try(bestX, r.l + me.w / 2, me.cx)           -- left edges
                bestX = Try(bestX, r.r - me.w / 2, me.cx)           -- right edges
                bestX = Try(bestX, r.r + gap + me.w / 2, me.cx)     -- to the right of it
                bestX = Try(bestX, r.l - gap - me.w / 2, me.cx)     -- to the left of it
                bestY = Try(bestY, r.cy, me.cy)                     -- centers
                bestY = Try(bestY, r.t - me.h / 2, me.cy)           -- top edges
                bestY = Try(bestY, r.b + me.h / 2, me.cy)           -- bottom edges
                bestY = Try(bestY, r.b - gap - me.h / 2, me.cy)     -- below it
                bestY = Try(bestY, r.t + gap + me.h / 2, me.cy)     -- above it
            end
        end
    end
    return bestX or 0, bestY or 0
end

-- getCfg() returns the settings table holding `point` and `locked`.
-- isIcon: drag button/modifier follow the "move with" setting.
function ns.MakeMovable(frame, getCfg, isIcon)
    table.insert(ns.movables, frame)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame.isIcon = isIcon
    ns.ApplyDragButton(frame)
    frame:SetScript("OnDragStart", function(self)
        if getCfg().locked then return end
        if self:IsProtected() and InCombatLockdown() then return end
        if self.isIcon then
            local check = modifierDown[ns.db.moveWith]
            if check and not check() then return end
        end
        self.moving = true
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        if not self.moving then return end
        self:StopMovingOrSizing()
        self.moving = nil
        if self.SetUserPlaced then self:SetUserPlaced(false) end
        local cfg = getCfg()
        SavePoint(self, cfg)
        local dx, dy = ns.SnapOffset(self)
        if cfg.point and (dx ~= 0 or dy ~= 0) then
            local ratio = UIParent:GetEffectiveScale() / self:GetEffectiveScale()
            cfg.point[3] = cfg.point[3] + dx * ratio
            cfg.point[4] = cfg.point[4] + dy * ratio
        end
        ns.ApplyPoint(self, cfg.point)
    end)
end

function ns.ApplyDragButton(frame)
    if frame.isIcon and ns.db and ns.db.moveWith == "right" then
        frame:RegisterForDrag("RightButton")
    else
        frame:RegisterForDrag("LeftButton")
    end
end

function ns.ApplyPoint(frame, point)
    if frame.moving then return end
    frame:ClearAllPoints()
    frame:SetPoint(point[1], UIParent, point[2], point[3], point[4])
end

------------------------------------------------------------------------
-- Secure action icon
------------------------------------------------------------------------
local Icon = {}

function Icon:Cfg() return ns.db[self.key] end

function Icon:StateCfg(state)
    local cfg = self:Cfg()
    if state and cfg.states and cfg.states[state] then return cfg.states[state] end
    return cfg
end

-- attrs: table of secure attributes, e.g. { type1 = "spell", spell1 = 706 }
function Icon:SetAction(attrs, texture, tipSpell, tipItem)
    self.icon:SetTexture(texture or ns.QUESTION_ICON)
    self.tipSpell, self.tipItem = tipSpell, tipItem
    self.wantAttrs = attrs
    self.hasAction = attrs ~= nil
    self.unlearned = nil
end

-- The spell isn't learned yet: no icon, except in preview, where a sample that does nothing
-- on click lets the icon be placed and set up in advance.
function Icon:SetUnlearned(texture, tipSpell, tipItem)
    if not ns.db.preview then
        self:SetAction(nil)
        return
    end
    self:SetAction({}, texture, tipSpell, tipItem)
    self.unlearned = true
end

function Icon:SetSpell(spellID, texture)
    self:SetAction({ type1 = "spell", spell1 = spellID }, texture or ns.SpellTexture(spellID), spellID, nil)
end

function Icon:ApplySecure()
    local want = {}
    -- While unlocked, the "move" modifier must not trigger an action on mouse down.
    local blocked = (not self:Cfg().locked and ns.db.moveWith ~= "right") and (ns.db.moveWith .. "-") or nil
    for k, v in pairs(self.wantAttrs or {}) do
        if not (blocked and k:sub(1, #blocked) == blocked) then want[k] = v end
    end
    -- Explicit no-op so the click can't fall back to an unmodified action.
    if blocked then want[blocked .. "type1"] = ATTRIBUTE_NOOP or "" end
    local applied = self.appliedAttrs or {}
    for k in pairs(applied) do
        if want[k] == nil then self:SetAttribute(k, nil) end
    end
    for k, v in pairs(want) do
        if applied[k] ~= v then self:SetAttribute(k, v) end
    end
    local copy = {}
    for k, v in pairs(want) do copy[k] = v end
    self.appliedAttrs = copy
end

function Icon:ShouldShow()
    local cfg = self:Cfg()
    if not cfg.enabled then return false end
    if ns.HiddenForTravel() then return false end
    -- Nothing to fix while dead (or a ghost); preview still shows the samples for positioning.
    if ns.IsDead() and not ns.db.preview then return false end
    -- Simulated combat with "hide icons in combat" (real combat hides them in PrepareForCombat).
    if ns.db.previewCombat and not ns.inCombat and ns.db.combat.hide then return false end
    if self.state then return true end
    return ns.db.preview and self.hasAction
end

function Icon:SetState(state)
    if state ~= self.state then
        ns.Trace("icon %s: %s -> %s", self.key, tostring(self.state), tostring(state))
        self.state = state
        if state and ns.ready and self:Cfg().enabled and not ns.IsDead() then
            local sc = self:StateCfg(state)
            if sc.sound then ns.PlaySound(sc.soundName) end
        end
    end
    self:Sync()
end

function Icon:Sync()
    local cfg = self:Cfg()
    local show = self:ShouldShow()
    local sc = self:StateCfg(self.state or self.previewState)
    self.glow:SetGlow(show and sc.glow, sc.glowColor, cfg.size)

    if InCombatLockdown() then
        -- Protected frame: only alpha may change in combat, so the icon shows and hides
        -- by opacity, the same way as out of combat ("Hide icons in combat" too, if turned on now).
        if self:IsShown() then self:SetAlpha(show and not ns.db.combat.hide and ns.FrameAlpha() or 0) end
        return
    end
    self:SetSize(cfg.size, cfg.size)
    ns.ApplyDragButton(self)
    ns.ApplyPoint(self, cfg.point)
    self:ApplySecure()
    self:EnableMouse(not ns.ClickThrough())
    if ns.CombatLook() and cfg.enabled and self.hasAction and not ns.db.combat.hide then
        -- Simulated combat looks and behaves like a real fight: the icon stays in place, invisible
        -- while not needed (and still taking clicks unless click-through is on).
        self:SetAlpha(show and ns.FrameAlpha() or 0)
        self:Show()
    else
        self:SetAlpha(ns.FrameAlpha())
        self:SetShown(show)
    end
end

-- Runs right before combat lockdown: the last moment protected frames can be
-- shown, hidden or have mouse input changed.
function Icon:PrepareForCombat()
    if not self:Cfg().enabled or not self.hasAction then return end
    self:ApplySecure()
    if ns.db.combat.hide then
        self:Hide()
        return
    end
    self:Show()
    self:SetAlpha(self:ShouldShow() and ns.FrameAlpha() or 0)
    -- Mouse input can't change in combat, so it's set for the whole fight now: clickable unless
    -- "Click-through in combat" is on, also for icons that only appear later in the fight.
    self:EnableMouse(not ns.ClickThrough())
end

local function Icon_OnEnter(self)
    if self:GetAlpha() == 0 then return end -- invisible in combat: no tooltip
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.tipItem then
        GameTooltip:SetItemByID(self.tipItem)
    elseif self.tipSpell then
        GameTooltip:SetSpellByID(self.tipSpell)
    else
        GameTooltip:AddLine(L[self.title])
    end
    if self.unlearned then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Not learned yet (shown in preview only)."], 1, 0.3, 0.3)
    elseif self.hint then
        GameTooltip:AddLine(" ")
        self.hint(GameTooltip)
    end
    if not self:Cfg().locked then
        GameTooltip:AddLine(string.format(L["%s to move"], ns.MoveModeText()), 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

function ns.CreateActionIcon(key, title)
    local b = CreateFrame("Button", "WarlockUpkeep_" .. key, UIParent, "SecureActionButtonTemplate")
    Mixin(b, Icon)
    b.key, b.title = key, title
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetFrameStrata("MEDIUM")
    b:Hide()

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 1)
    bg:SetPoint("TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", 1, -1)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    b.glow = ns.CreateGlow(b)

    -- Left click (with modifiers) performs actions; dragging follows the "move with" setting.
    ns.MakeMovable(b, function() return b:Cfg() end, true)
    b:SetScript("OnEnter", Icon_OnEnter)
    b:SetScript("OnLeave", GameTooltip_Hide)

    table.insert(ns.icons, b)
    return b
end
