local _, ns = ...
local D = ns.data
local M = ns:NewModule("soulstone")

local ranks = D.stones.soulstone
local isBuff = {}
for _, id in ipairs(D.soulstoneBuffs) do isBuff[id] = true end
local pendingCasts = {}

local function LabelCfg() return ns.db.soulstoneLabel end

-- Soulstone on the caster, followed through combat like the armor buff.
local selfStone = ns.NewBuffTracker(D.soulstoneBuffs, nil, "soulstone")
-- Raid members get no UNIT_AURA here (see Core): rescan them this often out of combat.
local RAID_SCAN_PERIOD = 3

-- Timer zone by seconds left: "crit", "warn" or nil.
local function TimerZone(remain)
    local z = ns.db.soulstoneLabel.zones
    if z.crit.enabled and remain <= z.crit.seconds then return "crit" end
    if z.warn.enabled and remain <= z.warn.seconds then return "warn" end
end

-- Mists / Retail: Soulstone is a spell cast on the target instead of a bag item.
local function DirectCast() return ns.IsKnown(D.soulstoneSpell) end

local function Duration()
    return DirectCast() and D.soulstoneSpellDuration or D.soulstoneDuration
end

-- nil for missing, empty or secret values.
local function Safe(v)
    if v == nil or ns.IsSecret(v) or v == "" then return nil end
    return v
end

local function ShortName(name)
    name = Safe(name)
    return name and (name:gsub("%-.*$", ""))
end

local function GUIDOf(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if ok then return Safe(guid) end
end

-- "Name" for the same realm, "Name-Realm" otherwise (the form UNIT_SPELLCAST_SENT reports).
local function FullName(unit)
    local ok, name, realm = pcall(UnitName, unit)
    if not ok or not Safe(name) then return nil end
    realm = Safe(realm)
    return realm and (name .. "-" .. realm:gsub("%s", "")) or name
end

local function GroupUnits()
    local units = { "player" }
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do units[#units + 1] = "raid" .. i end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do units[#units + 1] = "party" .. i end
    end
    return units
end

-- false for errors and secret values.
local function Check(fn, ...)
    local ok, v = pcall(fn, ...)
    return ok and not ns.IsSecret(v) and v or false
end

-- Where the cast goes when the event doesn't name a target: the friendly living
-- target, as in the icon's [help,nodead] macro, otherwise the caster.
local function IntendedUnit()
    if Check(UnitExists, "target") and Check(UnitCanAssist, "player", "target")
        and not Check(UnitIsDeadOrGhost, "target") then
        return "target"
    end
    return "player"
end

-- "Name" or "Name-Realm" of the caster. Some clients give your own name with the realm,
-- unlike UnitName("player").
local function IsMyName(full)
    full = Safe(full)
    if not full then return false end
    local name, realm = full:match("^([^%-]+)%-?(.*)$")
    if name ~= Safe(UnitName("player")) then return false end
    if realm == "" then return true end
    local my = (GetNormalizedRealmName and Safe(GetNormalizedRealmName())) or Safe(GetRealmName()) or ""
    return (realm:gsub("[%s%-]", "")) == (my:gsub("[%s%-]", ""))
end

local function UnitByFullName(name)
    if not name then return nil end
    if IsMyName(name) then return "player" end
    name = name:gsub("%s", "")
    for _, u in ipairs(GroupUnits()) do
        if FullName(u) == name then return u end
    end
end

-- Group plus target and focus: the Soulstone may be on a player outside the group.
local function ScanUnits()
    local units = GroupUnits()
    units[#units + 1] = "target"
    units[#units + 1] = "focus"
    return units
end

local function UnitByGUID(guid, units)
    if not guid then return nil end
    for _, u in ipairs(units or GroupUnits()) do
        if GUIDOf(u) == guid then return u end
    end
end

local function ClassOf(unit)
    if not unit then return nil end
    local ok, _, class = pcall(UnitClass, unit)
    if ok then return Safe(class) end
end

local function ClassOfGUID(guid)
    if not guid or not GetPlayerInfoByGUID then return nil end
    local ok, _, class = pcall(GetPlayerInfoByGUID, guid)
    if ok then return Safe(class) end
end

-- Who a Soulstone cast is for, read while the unit is still targeted.
local function Snapshot(unit)
    local ok, name = pcall(UnitName, unit)
    return { guid = GUIDOf(unit), name = ShortName(ok and name or nil), full = FullName(unit), class = ClassOf(unit) }
end

------------------------------------------------------------------------
-- Tracking (persisted per character so it survives /reload).
-- The target is identified by GUID; the name is only for display.
------------------------------------------------------------------------
function M:GetTracked()
    local t = ns.cdb.soulstone
    if t and t.expires > GetServerTime() then return t end
    ns.cdb.soulstone = nil
end

-- full: "Name" / "Name-Realm", kept only as a fallback when the GUID is unknown.
-- instance: the aura instance ID once seen, so its removal can be noticed in combat.
function M:SetTracked(guid, name, class, expires, full, instance)
    if not guid and not name then ns.cdb.soulstone = nil; return end
    ns.cdb.soulstone = { guid = guid, name = name, full = full, class = class, expires = expires, instance = instance }
end

-- In combat the Soulstone aura is secret, but its remembered instance still shows whether
-- it's gone (used or removed). Only for a visible unit: hidden ones read as "no aura" too.
function M:CheckInstance()
    local t = self:GetTracked()
    if not t or not t.instance then return end
    local u = UnitByGUID(t.guid, ScanUnits())
    if not u or not ns.Bool(UnitIsVisible, u) or not ns.Bool(UnitIsConnected, u) then return end
    if ns.AuraInstanceExists(u, t.instance) == false then self:SetTracked(nil) end
end

local function IsSelf(t)
    local me = GUIDOf("player")
    if t.guid and me then return t.guid == me end
    return IsMyName(t.full) or IsMyName(t.name)
end

-- Buff `i` of `unit` cast by the player, as AuraData. Older Classic clients only have UnitBuff.
local function PlayerBuffByIndex(unit, i)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        return C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL|PLAYER")
    end
    local name, _, _, _, _, expirationTime, _, _, _, spellId = UnitBuff(unit, i, "PLAYER")
    if name then return { spellId = spellId, expirationTime = expirationTime } end
end

-- Server time when another warlock's Soulstone on you runs out, or nil when there's none.
local function OthersOnSelf()
    for i = 1, 40 do
        local spellId, source, expirationTime
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not a then break end
            spellId, source, expirationTime = a.spellId, a.sourceUnit, a.expirationTime
        else
            local name, _, _, _, _, ex, src, _, _, id = UnitBuff("player", i)
            if not name then break end
            spellId, source, expirationTime = id, src, ex
        end
        if isBuff[spellId] and not (source and UnitIsUnit(source, "player")) then
            if expirationTime and expirationTime > 0 then
                return GetServerTime() + math.floor(expirationTime - GetTime())
            end
            return GetServerTime() + Duration()
        end
    end
end

-- Out of combat: read real auras of the group to confirm/correct the tracked target.
function M:Scan()
    if ns.AurasSecret() or not (UnitBuff or (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex)) then return end
    local okOthers, others = pcall(OthersOnSelf)
    if okOthers then self.others = others end
    local found
    for _, u in ipairs(ScanUnits()) do
        if UnitExists(u) then
            local ok = pcall(function()
                for i = 1, 40 do
                    local a = PlayerBuffByIndex(u, i)
                    if not a then break end
                    if isBuff[a.spellId] then found = { unit = u, aura = a }; return end
                end
            end)
            if ok and found then break end
        end
    end

    if found then
        local a = found.aura
        local expires
        if a.expirationTime and a.expirationTime > 0 then
            expires = GetServerTime() + math.floor(a.expirationTime - GetTime())
        else
            local t = self:GetTracked()
            expires = t and t.expires or GetServerTime() + Duration()
        end
        local id = a.auraInstanceID
        self:SetTracked(GUIDOf(found.unit), ShortName(UnitName(found.unit)), ClassOf(found.unit), expires, nil,
            not ns.IsSecret(id) and id or nil)
        return
    end

    -- Not found: forget it only if we can actually see the target's auras.
    local t = self:GetTracked()
    if t then
        local u = t.guid and UnitByGUID(t.guid) or (IsSelf(t) and "player")
        if u and UnitIsVisible(u) and UnitIsConnected(u) then self:SetTracked(nil) end
    end
end

------------------------------------------------------------------------
-- Label (target name in class color + timer)
------------------------------------------------------------------------
function M:CreateLabel()
    local f = CreateFrame("Frame", "WarlockUpkeep_SoulstoneLabel", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetSize(120, 36)
    f.name = f:CreateFontString(nil, "OVERLAY")
    f.name:SetPoint("TOP", f, "TOP", 0, -2)
    f.timer = f:CreateFontString(nil, "OVERLAY")
    f.icon = f:CreateTexture(nil, "OVERLAY")
    f.icon:SetPoint("RIGHT", f.timer, "LEFT", -3, 0)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.icon:SetTexture(ns.SpellTexture(D.soulstoneBuffs[1]) or ns.ItemIcon(ranks[#ranks].items[1]) or ns.QUESTION_ICON)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 1)
    ns.MakeMovable(f, LabelCfg)

    local elapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        -- The fast preview timer needs frequent ticks, or it would jump over the zones.
        if elapsed < (self.previewStart and 0.05 or 0.25) then return end
        elapsed = 0
        local remain
        if self.previewStart then
            -- Preview: counts down fast and restarts from the full duration at 0.
            local d = self.previewDuration
            remain = d - math.floor((GetTime() - self.previewStart) * LabelCfg().previewSpeed) % d
        else
            remain = (self.expires or 0) - GetServerTime()
        end
        if remain < 0 then remain = 0 end
        local cfg = LabelCfg()
        local zone = TimerZone(remain)
        local c = zone and cfg.zones[zone].color or cfg.timerColor
        self.timer:SetTextColor(c[1], c[2], c[3])
        -- Sounds when a zone starts and when the timer runs out. A new Soulstone (or preview)
        -- starts silently in its current zone.
        local key = self.previewStart or self.expires
        if self.zoneFor ~= key then
            self.zoneFor, self.zone = key, zone
        elseif ns.ready then
            if self.previewStart and remain > self.lastRemain and cfg.expired.sound then
                ns.PlaySound(cfg.expired.soundName) -- the preview sample ran out and restarted
            end
            if zone ~= self.zone then
                local zc = zone and cfg.zones[zone]
                if zc and zc.sound then ns.PlaySound(zc.soundName) end
            end
        end
        self.zone, self.lastRemain = zone, remain
        self.timer:SetFormattedText("%d:%02d", math.floor(remain / 60), remain % 60)
    end)
    f:Hide()
    self.label = f
end

-- name == nil with `expires` set: Soulstone is on the caster, show only the timer.
-- preview: a sample with a fast running timer instead of a real one.
function M:ShowLabel(name, class, expires, preview)
    local f, cfg = self.label, LabelCfg()
    if not expires or not cfg.enabled then f:Hide(); f.previewStart = nil; return end
    if preview then
        f.previewDuration = Duration()
        f.previewStart = f.previewStart or GetTime()
    else
        f.previewStart = nil
    end
    local iconSize = cfg.timerSize + 2
    local nameHeight = 0
    if name then
        local color = class and (C_ClassColor and C_ClassColor.GetClassColor(class) or RAID_CLASS_COLORS[class])
        f.name:SetText(name)
        if color then f.name:SetTextColor(color.r, color.g, color.b) else f.name:SetTextColor(1, 1, 1) end
        nameHeight = cfg.nameSize + 2
    end
    f.name:SetShown(name ~= nil)
    f.timer:ClearAllPoints()
    f.timer:SetPoint("TOP", f, "TOP", cfg.showIcon and (iconSize + 3) / 2 or 0, -(nameHeight + 3))
    f.expires = expires
    local timerWidth = math.max(f.timer:GetStringWidth(), 30) + (cfg.showIcon and (iconSize + 3) or 0)
    local w = math.max(name and f.name:GetStringWidth() or 0, timerWidth) + 12
    f:SetSize(w, nameHeight + math.max(cfg.timerSize, cfg.showIcon and iconSize or 0) + 6)
    f.bg:SetAlpha(cfg.bgAlpha)
    f:SetAlpha(ns.FrameAlpha())
    f:EnableMouse(not cfg.locked and not ns.ClickThrough())
    f:Show()
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------
function M:Init()
    self.button = ns.CreateActionIcon("soulstone", "Soulstone")
    self.button.previewState = "use"
    self.button.hint = function(tt)
        if M.button.state == "create" then
            tt:AddLine(ns.L["No Soulstone in bags. Click to create the strongest one."], 1, 0.3, 0.3)
        else
            tt:AddLine(ns.L["Soulstone is not applied. Click to use it on your"], 1, 0.82, 0)
            tt:AddLine(ns.L["friendly target (or yourself if none)."], 1, 0.82, 0)
        end
    end
    self:CreateLabel()

    -- The target name in UNIT_SPELLCAST_SENT can be empty or secret (newer clients):
    -- then the cast goes to the friendly target, or to the caster.
    ns:RegisterEvent("UNIT_SPELLCAST_SENT", function(_, unit, target, castGUID, spellID)
        if unit ~= "player" or ns.IsSecret(spellID) or not isBuff[spellID] then return end
        local name = Safe(target)
        local info
        if name then
            local u = UnitByFullName(name)
            if not u and FullName("target") == (name:gsub("%s", "")) then u = "target" end
            info = u and Snapshot(u) or { name = ShortName(name), full = name }
        else
            info = Snapshot(IntendedUnit())
        end
        pendingCasts[Safe(castGUID) or "last"] = info
    end)
    ns:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, castGUID, spellID)
        if unit ~= "player" or ns.IsSecret(spellID) or not isBuff[spellID] then return end
        local key = Safe(castGUID) or "last"
        local info = pendingCasts[key] or Snapshot(IntendedUnit())
        pendingCasts[key] = nil
        if info.guid and info.guid == GUIDOf("player") then selfStone:Cast() end
        M:SetTracked(info.guid, info.name or UnitName("player"), info.class or ClassOfGUID(info.guid),
            GetServerTime() + Duration(), info.full)
        M:Update()
    end)
    ns:RegisterEvent("GROUP_ROSTER_UPDATE", function() M:Update() end)
    -- What changed in combat (hidden auras) is caught by a fresh look right after the fight.
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        M.needScan = true
        M:Update()
    end)
    ns:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        M.needScan = true
        if ns.db.preview then M:Update() end
    end)
    ns:RegisterEvent("UNIT_AURA", function(_, unit)
        if ns.IsSecret(unit) then return end
        if unit == "player" or unit == "target" or unit == "focus"
            or (unit and (unit:match("^party") or unit:match("^raid"))) then
            M.needScan = true
        end
    end)
    self.needScan = true
end

function M:ApplySettings()
    local cfg, f = LabelCfg(), self.label
    ns.ApplyNameFont(f.name, cfg.font, cfg.nameSize, cfg.outline)
    ns.ApplyFont(f.timer, cfg.font, cfg.timerSize, cfg.outline)
    -- Small Soulstone icon left of the timer; shift the timer so the pair stays centered.
    local iconSize = cfg.timerSize + 2
    f.icon:SetSize(iconSize, iconSize)
    f.icon:SetShown(cfg.showIcon)
    ns.ApplyPoint(f, cfg.point)
    self.needScan = true
end

function M:Update()
    local b = self.button
    if not ns.db.soulstone.enabled then
        b:SetState(nil)
        self.label:Hide()
        return
    end

    if not ns.AurasSecret() and IsInRaid() and self:GetTracked()
        and GetTime() - (self.lastScan or 0) >= RAID_SCAN_PERIOD then
        self.needScan = true
    end
    if self.needScan and not ns.AurasSecret() then
        self.needScan = false
        self.lastScan = GetTime()
        self:Scan()
    elseif ns.AurasSecret() then
        self:CheckInstance()
    end
    -- On the caster the game's buff frame shows the Soulstone in combat too: gone means used.
    local wasOn = selfStone.has
    local onSelf = selfStone:Read()
    local tracked = self:GetTracked()
    if wasOn and onSelf == false and tracked and IsSelf(tracked) and ns.AurasSecret() then self:SetTracked(nil) end
    -- Another warlock's Soulstone on you: gone once it runs out or leaves the buff list (also in combat).
    if self.others and (GetServerTime() >= self.others or onSelf == false) then self.others = nil end

    local t = self:GetTracked()
    -- The tracked Soulstone ran out (not removed early): optional sound.
    if t then
        self.lastExpires = t.expires
    elseif self.lastExpires then
        local ex = LabelCfg().expired
        if GetServerTime() >= self.lastExpires and ex.sound and ns.ready then ns.PlaySound(ex.soundName) end
        self.lastExpires = nil
    end
    -- Before Soulstones can be made (low level) the label shows in preview only.
    if not ns.db.preview and not (DirectCast() or ns.HighestKnown(ranks)) then
        self:ShowLabel(nil, nil, nil)
    elseif t and not IsSelf(t) then
        if not t.class then t.class = ClassOf(UnitByGUID(t.guid)) or ClassOfGUID(t.guid) end
        self:ShowLabel(t.name, t.class, t.expires)
    elseif t then
        self:ShowLabel(nil, nil, LabelCfg().showSelf and t.expires or nil)
    elseif self.others then
        self:ShowLabel(nil, nil, LabelCfg().showSelf and self.others or nil)
    elseif ns.db.preview then
        -- As if cast now: on the current target, or on yourself without one (timer only).
        local expires = GetServerTime() + Duration()
        if Check(UnitExists, "target") and not Check(UnitIsUnit, "target", "player") then
            local s = Snapshot("target")
            self:ShowLabel(s.name or ns.L["Soulstone target"], s.class, expires, true)
        else
            self:ShowLabel(nil, nil, LabelCfg().showSelf and expires or nil, true)
        end
    else
        self:ShowLabel(nil, nil, nil)
    end

    -- Your own Soulstone is out, or (if set) another warlock's is on you: nothing to apply.
    local applied = t or (ns.db.soulstone.hideWhenOthers and self.others)

    if DirectCast() then
        local name = ns.SpellName(D.soulstoneSpell)
        local macro = string.format("/cast [help,nodead] %s; [@player] %s", name, name)
        b:SetAction({ type1 = "macro", macrotext1 = macro }, ns.SpellTexture(D.soulstoneSpell), D.soulstoneSpell)
        b:SetState(not applied and "use" or nil)
        return
    end

    -- State 2: a Soulstone is in the bags but not applied -> use it.
    local item, unknown
    for i = #ranks, 1, -1 do
        local n = ns.ItemCount(ranks[i].items[1])
        if n == nil then unknown = true elseif n > 0 then item = ranks[i].items[1]; break end
    end
    if not item and unknown then item = self.lastItem end -- bags unreadable: keep last known
    self.lastItem = item

    if item then
        local macro = string.format("/use [help,nodead] item:%d; [@player] item:%d", item, item)
        b:SetAction({ type1 = "macro", macrotext1 = macro }, ns.ItemIcon(item), nil, item)
        b:SetState(not applied and "use" or nil)
        return
    end

    -- State 1: no Soulstone in the bags -> create one.
    local spell, rank = ns.HighestKnown(ranks)
    if spell then
        b:SetSpell(spell, ns.ItemIcon(ranks[rank].items[1]))
        b:SetState((not applied or ns.db.soulstone.createWhileApplied) and "create" or nil)
    elseif ns.SHARD_ITEMS then
        local sample = ranks[1].items[1]
        b:SetUnlearned(ns.ItemIcon(sample), nil, sample)
        b:SetState(nil)
    else
        b:SetUnlearned(ns.SpellTexture(D.soulstoneSpell), D.soulstoneSpell)
        b:SetState(nil)
    end
end
