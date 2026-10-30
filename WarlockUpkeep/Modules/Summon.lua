local _, ns = ...
local D = ns.data
local M = ns:NewModule("summon")

-- Summon queue: group members who asked for a summon in chat ("123", "summ"...), in the order they asked.
-- A click on a row targets the player and casts Ritual of Summoning; a player leaves the queue once next to
-- you, out of the group, after the timeout, or on a right click.

local ROW_HEIGHT = 18
local HEADER = 26 -- title line and bottom padding
local WIDTH = 230
-- After the cast, a player gets this long to accept and arrive before going back to the queue.
local SUMMON_WAIT = 120

local function Cfg() return ns.db.summon end

local function Safe(v)
    if v == nil or ns.IsSecret(v) or v == "" then return nil end
    return v
end

local function GroupUnits()
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do units[#units + 1] = "raid" .. i end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do units[#units + 1] = "party" .. i end
    end
    return units
end

-- "Name" on your realm, "Name-Realm" otherwise: the form /target takes and GetUnitName(unit, true) gives.
local function Short(name)
    name = Safe(name)
    if not name then return nil end
    if Ambiguate then return Ambiguate(name, "none") end
    local n, realm = name:match("^([^%-]+)%-(.+)$")
    local mine = GetNormalizedRealmName and GetNormalizedRealmName()
    if n and realm == mine then return n end
    return name
end

local function UnitOf(name)
    for _, u in ipairs(GroupUnits()) do
        local ok, n = pcall(GetUnitName, u, true)
        if ok and Safe(n) == name then return u end
    end
end

local function Check(fn, ...)
    local ok, v = pcall(fn, ...)
    return ok and not ns.IsSecret(v) and v or false
end

-- Next to you: about as far as the portal can be clicked from. CheckInteractDistance works on friendly
-- players out of combat; UnitInRange (40 yards) is the fallback.
local function Near(unit)
    if not unit or not Check(UnitIsVisible, unit) then return false end
    if CheckInteractDistance then
        local ok, near = pcall(CheckInteractDistance, unit, 4)
        if ok and not ns.IsSecret(near) and near ~= nil then return near and true or false end
    end
    return Check(UnitInRange, unit) and true or false
end

-- Zone of a raid member (the roster has it), or nil.
local function ZoneOf(unit)
    local i = unit and tonumber(unit:match("^raid(%d+)$"))
    if not i then return nil end
    local ok, _, _, _, _, _, _, zone = pcall(GetRaidRosterInfo, i)
    return ok and Safe(zone) or nil
end

------------------------------------------------------------------------
-- Keywords
------------------------------------------------------------------------
local keywordCache, keywordSource
local function Keywords()
    local src = Cfg().keywords or ""
    if src ~= keywordSource then
        keywordSource, keywordCache = src, {}
        for raw in src:gmatch("[^,]+") do
            local kw = raw:lower():match("^%s*(.-)%s*$")
            if kw ~= "" then keywordCache[#keywordCache + 1] = kw end
        end
    end
    return keywordCache
end

-- Whole words only, punctuation ignored: "summ" matches "summ pls!" but not "summary".
local function Words(s) return " " .. s:lower():gsub("[%p%s]+", " ") .. " " end
function M.Matches(text, list)
    text = Safe(text)
    if not text then return false end
    text = Words(text)
    for _, kw in ipairs(list or Keywords()) do
        if text:find(Words(kw), 1, true) then return true end
    end
    return false
end

------------------------------------------------------------------------
-- Queue
------------------------------------------------------------------------
M.queue = {} -- { name, class, at, summonedAt }

function M:Find(name)
    for i, e in ipairs(self.queue) do
        if e.name == name then return i, e end
    end
end

-- sold: a buyer from the selling window, summoned for strangers to see (and help with).
function M:Add(name, sold)
    if not name or self:Find(name) then return end
    local unit = UnitOf(name)
    if not unit or Check(UnitIsUnit, unit, "player") or Near(unit) then return end
    local ok, _, class = pcall(UnitClass, unit)
    self.queue[#self.queue + 1] = { name = name, class = ok and Safe(class) or nil, at = GetTime(), sold = sold }
    if ns.ready and Cfg().sound then ns.PlaySound(Cfg().soundName) end
    self:Refresh()
end

function M:Remove(name)
    local i = self:Find(name)
    if i then table.remove(self.queue, i); self:Refresh() end
end

-- Drops players who arrived, left the group or waited too long; a summon not taken goes back to waiting.
function M:Prune()
    local now, changed = GetTime(), false
    for i = #self.queue, 1, -1 do
        local e = self.queue[i]
        local unit = UnitOf(e.name)
        if not unit or Near(unit) or now - e.at > Cfg().timeout * 60 then
            table.remove(self.queue, i)
            changed = true
        elseif e.summonedAt and now - e.summonedAt > SUMMON_WAIT then
            e.summonedAt = nil
            changed = true
        end
    end
    return changed
end

-- Group members next to you who can click the portal (the queue's players are elsewhere).
local function Clickers()
    local n = 0
    for _, u in ipairs(GroupUnits()) do
        if not Check(UnitIsUnit, u, "player") and Check(UnitIsConnected, u) and not Check(UnitIsDeadOrGhost, u)
            and Near(u) then
            n = n + 1
        end
    end
    return n
end

-- Shared with the selling window (SummonSell.lua).
M.UnitOf, M.Clickers = UnitOf, Clickers

-- Fewer than two people next to you for the portal: ask for help. To the group for your own group's summons;
-- for a sold summon also to /say, /yell and the Trade channel, so players around can help. Called from the
-- click that starts the ritual: the game lets addons write to /say, /yell and channels only on a click.
local CALL_COOLDOWN = 15
function M:CallClickers(e)
    local c = Cfg().clickersCall
    local need = 2 - Clickers()
    if not c.enabled or need <= 0 then return end
    if self.lastCall and GetTime() - self.lastCall < CALL_COOLDOWN then return end
    self.lastCall = GetTime()
    if not e.sold then
        ns.SendToGroup((c.groupText:gsub("{n}", tostring(need))))
        return
    end
    local sell = ns.modules.summonSell
    local text = c.publicText:gsub("{n}", tostring(need))
    if sell then text = sell.Fill(text, e.name) end
    text = text:sub(1, 255)
    if c.party then ns.SendToGroup(text) end
    if c.say then SendChatMessage(text, "SAY") end
    if c.yell then SendChatMessage(text, "YELL") end
    if c.trade and sell then
        local id = GetChannelName and GetChannelName(ns.db.summonSell.adChannel)
        if id and id ~= 0 then SendChatMessage(text, "CHANNEL", nil, id) end
    end
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------
local function ClassColor(class)
    local c = class and (C_ClassColor and C_ClassColor.GetClassColor(class) or RAID_CLASS_COLORS[class])
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function Elapsed(sec)
    sec = math.max(0, math.floor(sec))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

-- Rows are secure buttons: made out of combat, as many as the window has room for.
local function CreateRow(f, i)
    local r = CreateFrame("Button", "WarlockUpkeep_SummonRow" .. i, f, "SecureActionButtonTemplate")
    r:SetHeight(ROW_HEIGHT)
    r:SetPoint("TOPLEFT", 4, -22 - (i - 1) * ROW_HEIGHT)
    r:RegisterForClicks("AnyUp", "AnyDown")
    r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.name:SetPoint("LEFT", 2, 0)
    r.name:SetJustifyH("LEFT")
    r.time = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.time:SetPoint("RIGHT", -2, 0)
    r.zone = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.zone:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
    r.zone:SetPoint("RIGHT", r.time, "LEFT", -6, 0)
    r.zone:SetJustifyH("LEFT")
    r.zone:SetWordWrap(false)
    r:SetScript("PostClick", function(self, button, down)
        if down or not self.entryName then return end
        if button == "RightButton" then
            M:Remove(self.entryName)
        elseif button == "LeftButton" then
            local _, e = M:Find(self.entryName)
            if e then
                e.summonedAt = GetTime()
                M:CallClickers(e)
            end
            M:Refresh()
        end
    end)
    r:Hide()
    f.rows[i] = r
    return r
end

function M:CreateWindow()
    local f = CreateFrame("Frame", "WarlockUpkeep_Summon", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetSize(WIDTH, 40)
    f:EnableMouse(true)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 1)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 6, -5)
    f.info = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.info:SetPoint("TOPRIGHT", -6, -6)
    f.anchor = "TOPLEFT"
    ns.MakeMovable(f, Cfg)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.L["Summon queue"], 0.58, 0.51, 0.79)
        GameTooltip:AddLine(ns.L["Click a player: target and cast Ritual of Summoning."], 1, 1, 1)
        GameTooltip:AddLine(ns.L["Right click: remove from the queue."], 1, 1, 1)
        if not Cfg().locked then
            GameTooltip:AddLine(ns.L["Drag to move"], 0.6, 0.6, 0.6)
            GameTooltip:AddLine(ns.L["Drag the corner to resize"], 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", GameTooltip_Hide)

    f.rows = {}
    f.more = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.more:SetPoint("BOTTOMLEFT", 8, 6)
    -- More players than fit: the mouse wheel scrolls (out of combat, like everything on the secure rows).
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta)
        if InCombatLockdown() then return end
        M.offset = (M.offset or 0) - delta
        M:Refresh()
    end)
    ns.MakeResizable(f, Cfg, 160, HEADER + ROW_HEIGHT, function() M:Refresh() end)

    local elapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        M:UpdateTimes()
    end)
    f:Hide()
    self.frame = f
end

-- Sample rows in preview, to place the window.
local SAMPLE = {
    { name = "Thrall", class = "SHAMAN", zone = "Orgrimmar", wait = 135 },
    { name = "Jaina", class = "MAGE", zone = "Stormwind City", wait = 100 },
    { name = "Uther", class = "PALADIN", zone = "Westfall", wait = 20 },
    -- More than fit by default, to try the scrolling.
    { name = "Sylvanas", class = "HUNTER", zone = "Tirisfal Glades", wait = 610 },
    { name = "Tyrande", class = "PRIEST", zone = "Darnassus", wait = 540 },
    { name = "Garrosh", class = "WARRIOR", zone = "Ashenvale", wait = 470 },
    { name = "Malfurion", class = "DRUID", zone = "Moonglade", wait = 400 },
    { name = "Valeera", class = "ROGUE", zone = "Stranglethorn Vale", wait = 330 },
    { name = "Guldan", class = "WARLOCK", zone = "Blasted Lands", wait = 290 },
    { name = "Cairne", class = "WARRIOR", zone = "Thunder Bluff", wait = 250 },
    { name = "Anduin", class = "PRIEST", zone = "Elwynn Forest", wait = 210 },
    { name = "Rexxar", class = "HUNTER", zone = "Feralas", wait = 170 },
    { name = "Muradin", class = "WARRIOR", zone = "Ironforge", wait = 60 },
    { name = "Voljin", class = "SHAMAN", zone = "Durotar", wait = 5 },
}

function M:Rows()
    if #self.queue > 0 then return self.queue, false end
    if ns.db.preview then return SAMPLE, true end
    return {}, false
end

function M:UpdateTimes()
    local _, sample = self:Rows()
    local now = GetTime()
    for _, r in ipairs(self.frame.rows) do
        local e = r.entry
        if e and r:IsShown() then
            if sample then
                r.time:SetText(Elapsed(e.wait))
            elseif e.summonedAt then
                r.time:SetText("|cff33ff33" .. ns.L["summoning"] .. "|r")
            else
                r.time:SetText(Elapsed(now - e.at))
            end
            if not sample then r.zone:SetText(ZoneOf(UnitOf(e.name)) or "") end
        end
    end
    local f = self.frame
    if f:IsShown() then
        local parts = {}
        if ns.SHARD_ITEMS then
            parts[#parts + 1] = string.format(ns.L["Shards: %d"], ns.ItemCount(D.SOUL_SHARD) or 0)
        end
        local n = sample and 2 or Clickers()
        parts[#parts + 1] = string.format(n >= 2 and "|cff33ff33%s|r" or "|cffff5555%s|r",
            string.format(ns.L["Clickers: %d/2"], math.min(n, 2)))
        f.info:SetText(table.concat(parts, "   "))
    end
end

-- Secure rows can't change in combat: the queue is redrawn after the fight.
function M:Refresh()
    if not self.frame then return end
    if InCombatLockdown() then self.dirty = true; return end
    self.dirty = false
    local f, cfg = self.frame, Cfg()
    local known = ns.IsKnown(D.ritualOfSummoning)
    local list, sample = self:Rows()
    if not cfg.enabled or (not known and not sample) or #list == 0 or ns.HiddenForTravel() then
        f:Hide()
        return
    end
    local spell = ns.SpellName(D.ritualOfSummoning) or "Ritual of Summoning"
    f.title:SetText(ns.L["Summon queue"])
    if f.sizing then return end
    local offset, visible, scroll = ns.ListSlice(#list, cfg.height, HEADER, ROW_HEIGHT, self.offset)
    self.offset = offset
    for i = 1, math.max(#f.rows, visible) do
        local r = f.rows[i] or CreateRow(f, i)
        local e = i <= visible and list[offset + i]
        r.entry = e or nil
        if e then
            r.entryName = not sample and e.name or nil
            r.name:SetText(string.format("%d. %s", offset + i, e.name))
            r.name:SetTextColor(ClassColor(e.class))
            r.zone:SetText(sample and e.zone or "")
            if sample then
                r:SetAttribute("type1", nil)
            else
                r:SetAttribute("type1", "macro")
                r:SetAttribute("macrotext1", string.format("/target %s\n/cast %s", e.name, spell))
            end
            r:Show()
        else
            r.entryName = nil
            r:Hide()
        end
    end
    f.more:SetText(scroll and string.format(ns.L["%d-%d of %d, scroll with the mouse wheel"],
        offset + 1, offset + visible, #list) or "")
    f:SetHeight(cfg.height)
    f.grip:SetShown(not cfg.locked)
    f.bg:SetAlpha(cfg.bgAlpha)
    f:SetAlpha(ns.FrameAlpha())
    f:Show()
    self:UpdateTimes()
    -- Wide enough for the title and the info line (a longer translation, more shards); out of combat only,
    -- like the secure rows.
    local width = math.max(cfg.width, f.title:GetStringWidth() + f.info:GetStringWidth() + 36)
    f:SetWidth(width)
    for _, r in ipairs(f.rows) do r:SetWidth(width - 8) end
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------
local CHAT_EVENTS = {
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_WHISPER",
}

function M:Announce(name)
    local a = Cfg().announce
    if a.group then ns.SendToGroup((a.groupText:gsub("{name}", function() return name end))) end
    if a.whisper and UnitOf(name) then
        SendChatMessage((a.whisperText:gsub("{name}", function() return name end)):sub(1, 255), "WHISPER", nil, name)
    end
end

function M:Init()
    self:CreateWindow()
    for _, event in ipairs(CHAT_EVENTS) do
        ns:RegisterEvent(event, function(_, text, sender)
            if not Cfg().enabled or not ns.IsKnown(D.ritualOfSummoning) then return end
            if not M.Matches(text) then return end
            M:Add(Short(sender))
        end)
    end
    -- Announcements when the ritual starts, for casts from the queue and by hand alike.
    ns:RegisterEvent("UNIT_SPELLCAST_SENT", function(_, unit, target, _, spellID)
        if unit ~= "player" or ns.IsSecret(spellID) or spellID ~= D.ritualOfSummoning then return end
        local name = Safe(target) or Safe(UnitName("target"))
        if name then M:Announce(Short(name)) end
    end)
    ns:RegisterEvent("GROUP_ROSTER_UPDATE", function() if M:Prune() then M:Refresh() end end)
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", function() if M.dirty then M:Refresh() end end)
end

function M:ApplySettings()
    ns.ApplyPoint(self.frame, Cfg().point)
end

function M:Update()
    self:Prune()
    self:Refresh()
end
