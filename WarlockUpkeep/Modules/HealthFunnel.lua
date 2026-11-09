local _, ns = ...
local D = ns.data
local M = ns:NewModule("healthFunnel")

-- Health Funnel: the icon shows when the demon's health drops into the warning or the critical zone, and a click
-- heals it. Until the spell is learned, a warning on screen and in chat instead.
-- Forever and Retail may hide the demon's health from addons in combat. Then the game's curves turn the hidden
-- value into opacity, so the icon, its highlights and the screen warning still follow it; sounds and chat
-- messages need a comparison the addon can't make, so they wait for readable health.

local function Cfg() return ns.db.healthFunnel end
local ZONES = { "crit", "warn" } -- crit first: it wins where the zones overlap
local CURVES = UnitHealthPercent and C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType

-- Demon health in percent; false without a living demon; nil when unreadable.
local function PetHealth()
    if ns.Bool(UnitExists, "pet") == false then return false end
    if ns.Bool(UnitIsDeadOrGhost, "pet") then return false end
    local ok, hp, max = pcall(function() return UnitHealth("pet"), UnitHealthMax("pet") end)
    if not ok or ns.IsSecret(hp) or ns.IsSecret(max) or type(hp) ~= "number" or not max or max <= 0 then return nil end
    if hp <= 0 then return false end
    return hp / max * 100
end

local function Zone(pct)
    local states = Cfg().states
    for _, key in ipairs(ZONES) do
        if states[key].enabled and pct <= states[key].percent then return key end
    end
end

-- Health range of a zone in percent, (from, upTo]: the warning zone ends where the critical one starts.
local function ZoneRange(key)
    local s = Cfg().states
    if not s[key].enabled then return end
    local from = key == "warn" and s.crit.enabled and s.crit.percent or nil
    if from and from >= s.warn.percent then return end
    return from, s[key].percent
end

-- UnitHealthPercent gives 0..1 unless told otherwise; checked against the plain numbers while they're readable.
local scale = 1
local function Calibrate(pct)
    if not CURVES or pct < 2 then return end
    local ok, v = pcall(UnitHealthPercent, "pet")
    if ok and type(v) == "number" and not ns.IsSecret(v) then scale = v > 1.5 and 100 or 1 end
end

-- A step curve: `value` for health in (from, upTo] percent (from 0 without `from`), 0 elsewhere.
local curves = {}
local function StepCurve(from, upTo, value)
    local key = table.concat({ scale, from or -1, upTo, value }, ":")
    if curves[key] == nil then
        local ok, c = pcall(function()
            local c = C_CurveUtil.CreateCurve()
            c:SetType(Enum.LuaCurveType.Step)
            if from then
                c:AddPoint(0, 0)
                c:AddPoint((from + 0.01) / 100 * scale, value)
            else
                c:AddPoint(0, value)
            end
            c:AddPoint((upTo + 0.01) / 100 * scale, 0)
            return c
        end)
        curves[key] = ok and c or false
    end
    return curves[key] or nil
end

-- Sets the opacity of `frame` from the hidden health; false when the game refuses.
local function AlphaByCurve(frame, from, upTo, value)
    local curve = upTo and StepCurve(from, upTo, value)
    if not curve then
        frame:SetAlpha(0)
        return true
    end
    local ok, v = pcall(UnitHealthPercent, "pet", false, curve)
    return ok and v ~= nil and pcall(frame.SetAlpha, frame, v)
end

local function TopPercent()
    local s, top = Cfg().states, nil
    for _, key in ipairs(ZONES) do
        if s[key].enabled then top = math.max(top or 0, s[key].percent) end
    end
    return top
end

------------------------------------------------------------------------
-- Screen warning (without the spell)
------------------------------------------------------------------------
local WARN_TEXT = {
    warn = { "Your demon's health is low: %d%%.", "Your demon's health is low!" },
    crit = { "Your demon is about to die: %d%%.", "Your demon is about to die!" },
}

local function CreateWarning()
    local f = CreateFrame("Frame", "WarlockUpkeep_HealthFunnelWarning", UIParent)
    f:SetFrameStrata("MEDIUM")
    f.lines = {}
    for _, key in ipairs(ZONES) do
        local fs = f:CreateFontString(nil, "OVERLAY")
        fs:SetPoint("CENTER")
        f.lines[key] = fs
    end
    ns.MakeMovable(f, function() return Cfg().text end)
    f:Hide()
    return f
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------
function M:Init()
    self.button = ns.CreateActionIcon("healthFunnel", "Health Funnel")
    self.button.previewState = "warn"
    self.button.hint = function(tt)
        tt:AddLine(ns.L["Your demon's health is low. Click to cast Health Funnel."], 1, 0.82, 0)
    end
    -- Highlights by zone for hidden health: each one shown by its own curve.
    self.zoneGlows = {}
    for _, key in ipairs(ZONES) do self.zoneGlows[key] = ns.CreateGlow(self.button) end
    self.warning = CreateWarning()

    local ev = CreateFrame("Frame")
    local listening = true
    for _, e in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH" }) do
        if not (ev.RegisterUnitEvent and pcall(ev.RegisterUnitEvent, ev, e, "pet")) then listening = false end
    end
    ev:SetScript("OnEvent", function() M:Update() end)
    -- No demon health events (Forever may refuse them): check often instead.
    if not listening then
        ev:SetScript("OnUpdate", function(_, dt)
            M.elapsed = (M.elapsed or 0) + dt
            if M.elapsed < 0.25 then return end
            M.elapsed = 0
            M:Update()
        end)
    end
    ns:RegisterEvent("UNIT_PET", function(_, unit) if unit == "player" then M:Update() end end)
    -- After the icons got ready for combat (opacity by state): hidden health takes over from here.
    ns:RegisterEvent("PLAYER_REGEN_DISABLED", function() M:Update() end)
end

function M:ApplySettings()
    local t, f = Cfg().text, self.warning
    for _, fs in pairs(f.lines) do ns.ApplyFont(fs, t.font, t.size, t.outline) end
    ns.ApplyPoint(f, t.point)
end

function M:Update()
    local cfg, b = Cfg(), self.button
    local spell = ns.HighestKnown(D.healthFunnel)
    local hp = PetHealth()
    local hidden = hp == nil
    local byCurve = hidden and CURVES and not self.noCurves and cfg.enabled
    local zone
    if hp then
        Calibrate(hp)
        zone = Zone(hp)
    elseif hidden and not byCurve then
        zone = self.zone -- unreadable and no curves: the last known zone
    end
    -- Chat: on getting into a zone or into the critical one, not on healing up into the warning zone.
    if zone and zone ~= self.zone and (not self.zone or zone == "crit") and hp and not spell and ns.ready
        and cfg.enabled and cfg.text.chat then
        ns.Print(ns.L[WARN_TEXT[zone][1]], math.ceil(hp))
    end
    self.zone, self.pct = zone, hp or (hidden and self.pct) or nil

    if spell then
        b:SetSpell(spell)
        b:SetState(zone)
    else
        b:SetUnlearned(ns.SpellTexture(D.healthFunnel[1]), D.healthFunnel[1])
        b:SetState(nil)
    end
    self:ShowZoneGlows(byCurve and spell)
    self:UpdateWarning(not spell, byCurve)
end

local function IconVisible(b)
    return b:Cfg().enabled and not ns.HiddenForTravel() and not ns.IsDead()
end

-- Hidden health in combat: the icon and the zone highlights show by curves (the state stays as it was).
function M:ShowZoneGlows(on)
    local b, cfg = self.button, Cfg()
    on = on and InCombatLockdown() and b:IsShown() and not ns.db.combat.hide
    if on and IconVisible(b) and AlphaByCurve(b, nil, TopPercent(), ns.FrameAlpha()) then
        b.glow:SetGlow(false)
        for key, g in pairs(self.zoneGlows) do
            local sc = cfg.states[key]
            g:SetGlow(sc.glow, sc.glowColor, cfg.size)
            local from, upTo = ZoneRange(key)
            if not AlphaByCurve(g, from, upTo, 1) then g:SetAlpha(0) end
        end
        return
    end
    if on then
        -- The game refused the curves: from now on the icon keeps the last readable state in combat.
        if IconVisible(b) then self.noCurves = true end
        b:SetAlpha(0)
    end
    for _, g in pairs(self.zoneGlows) do g:SetGlow(false) end
end

-- Without the spell: the zone's warning on screen, with the health while it's readable.
function M:UpdateWarning(noSpell, byCurve)
    local cfg, f = Cfg(), self.warning
    local on = noSpell and cfg.enabled and cfg.text.enabled and not ns.HiddenForTravel() and not ns.IsDead()
    byCurve = byCurve and on
    -- Preview: a sample of the warning zone to place the text.
    local sample = ns.db.preview and noSpell and cfg.enabled and not (on and (self.zone or byCurve))
    if not (sample or (on and (self.zone or byCurve))) then
        f:Hide()
        return
    end
    local width, height = 0, 0
    for _, key in ipairs(ZONES) do
        local fs, sc = f.lines[key], cfg.states[key]
        local c = sc.glowColor
        fs:SetTextColor(c[1], c[2], c[3], 1)
        if sample then
            fs:SetFormattedText(ns.L[WARN_TEXT[key][1]], sc.percent)
        elseif self.pct and not byCurve then
            fs:SetFormattedText(ns.L[WARN_TEXT[key][1]], math.ceil(self.pct))
        else
            fs:SetText(ns.L[WARN_TEXT[key][2]])
        end
        width, height = math.max(width, fs:GetStringWidth()), math.max(height, fs:GetStringHeight())
        if byCurve then
            local from, upTo = ZoneRange(key)
            if not AlphaByCurve(fs, from, upTo, 1) then
                self.noCurves = true
                fs:SetAlpha(0)
            end
        else
            fs:SetAlpha(key == (sample and "warn" or self.zone) and 1 or 0)
        end
    end
    f:SetSize(width + 12, height + 8)
    f:SetAlpha(ns.FrameAlpha())
    f:EnableMouse(not cfg.text.locked and not ns.ClickThrough())
    f:Show()
end
