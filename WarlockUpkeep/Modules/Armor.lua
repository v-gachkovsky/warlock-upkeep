local _, ns = ...
-- Only clients that still have the armor spells get the icon (see ns.HAS_ARMOR).
if not ns.HAS_ARMOR then return end
local D = ns.data
local M = ns:NewModule("armor")

local allIDs, isArmor = {}, {}
for _, list in pairs(D.armor) do
    for _, id in ipairs(list) do allIDs[#allIDs + 1] = id; isArmor[id] = true end
end

local buff = ns.NewBuffTracker(allIDs, D.armorDuration, "armor")

function M:Init()
    self.button = ns.CreateActionIcon("armor", "Demon Armor")
    self.button.hint = function(tt) tt:AddLine(ns.L["Missing Demon Skin / Demon Armor / Fel Armor. Click to cast."], 0, 1, 0) end

    ns:RegisterEvent("UNIT_AURA", function(event, unit, info)
        local ok, isPlayer = pcall(function() return not ns.IsSecret(unit) and unit == "player" end)
        if not ok or isPlayer or ns.IsSecret(unit) then pcall(LogAuraEvent, event, unit, info) end
        if ns.IsSecret(unit) or unit ~= "player" then return end
        buff:OnAuraUpdate(info)
        M:Update()
    end)
    ns:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
        if unit == "player" and not ns.IsSecret(spellID) and isArmor[spellID] then
            buff:Cast()
            M:Update()
        end
    end)
end

function M:ApplySettings() end

-- /wu auras: what the client returns for the armor buff right now (to diagnose combat secrecy).
local function Describe(v)
    if ns.IsSecret(v) then
        local ok, t = pcall(type, v)
        return "SECRET " .. (ok and t or "?")
    end
    if v == nil then return "nil" end
    local t = type(v)
    if t == "table" then return "table" end
    return t .. " " .. tostring(v)
end

-- Raw UNIT_AURA events, described when they arrive (before any filtering).
local auraLog = {}
local function LogAuraEvent(_, unit, info)
    local e = { at = GetTime(), unit = Describe(unit), info = Describe(info), inCombat = InCombatLockdown() }
    if type(info) == "table" and not ns.IsSecret(info) then
        e.full = Describe(info.isFullUpdate)
        local function List(t, field)
            if ns.IsSecret(t) then return "SECRET" end
            if type(t) ~= "table" then return Describe(t) end
            local out = {}
            for i = 1, math.min(#t, 4) do
                local v = t[i]
                if field and type(v) == "table" and not ns.IsSecret(v) then
                    v = string.format("{id %s, spell %s}", Describe(v.auraInstanceID), Describe(v.spellId))
                else
                    v = Describe(v)
                end
                out[#out + 1] = v
            end
            return #t .. ": " .. table.concat(out, "; ")
        end
        local ok1, added = pcall(List, info.addedAuras, true)
        local ok2, removed = pcall(List, info.removedAuraInstanceIDs)
        local ok3, updated = pcall(List, info.updatedAuraInstanceIDs)
        e.added = ok1 and added or ("ERROR " .. tostring(added))
        e.removed = ok2 and removed or ("ERROR " .. tostring(removed))
        e.updated = ok3 and updated or ("ERROR " .. tostring(updated))
    end
    table.insert(auraLog, 1, e)
    auraLog[6] = nil
end

local function Try(fn, ...)
    if not fn then return "no API" end
    local ok, v = pcall(fn, ...)
    if not ok then return "ERROR " .. tostring(v) end
    return Describe(v), v
end

function ns.DebugAuras()
    local P = function(...) ns.Print(...) end
    P("--- auras debug (%s) ---", InCombatLockdown() and "IN COMBAT" or "out of combat")
    P("ShouldAurasBeSecret: %s", Try(C_Secrets and C_Secrets.ShouldAurasBeSecret))
    P("ShouldSpellAuraBeSecret(687): %s, GetSpellAuraSecrecy(687): %s",
        Try(C_Secrets and C_Secrets.ShouldSpellAuraBeSecret, 687), Try(C_Secrets and C_Secrets.GetSpellAuraSecrecy, 687))
    P("HasSecretRestrictions: %s", Try(C_Secrets and C_Secrets.HasSecretRestrictions))
    for _, id in ipairs(allIDs) do
        if ns.IsKnown(id) then
            local d, aura = Try(C_UnitAuras.GetPlayerAuraBySpellID, id)
            P("GetPlayerAuraBySpellID(%d %s): %s", id, ns.SpellName(id) or "?", d)
            if type(aura) == "table" and not ns.IsSecret(aura) then
                P("  .auraInstanceID %s, .spellId %s, .expirationTime %s",
                    Describe(aura.auraInstanceID), Describe(aura.spellId), Describe(aura.expirationTime))
            end
        end
    end
    P("tracker: has %s, instance %s, expires in %s, castAt %s", Describe(buff.has), Describe(buff.instance),
        buff.expires and string.format("%.0f s", buff.expires - GetTime()) or "nil", Describe(buff.castAt))
    local icons = {}
    for tex in pairs(buff.icons) do icons[#icons + 1] = tostring(tex) end
    P("tracker icons: %s; SpellTexture(687): %s; FindInBuffFrame: %s; FindInCooldownViewer: %s", table.concat(icons, ", "),
        Try(ns.SpellTexture, 687), Try(function() return buff:FindInBuffFrame() end),
        Try(function() return buff:FindInCooldownViewer() end))
    -- What FindInBuffFrame works from: the buff frame's aura list.
    local info = BuffFrame and BuffFrame.auraInfo
    if type(info) == "table" and not ns.IsSecret(info) then
        local secret, buffs, out = 0, 0, {}
        for _, a in ipairs(info) do
            if type(a) ~= "table" or ns.IsSecret(a) then
                secret = secret + 1
            elseif a.auraType == "Buff" then
                buffs = buffs + 1
                if #out < 4 then
                    out[#out + 1] = string.format("{id %s, tex %s}", Describe(a.auraInstanceID), Describe(a.texture))
                end
            end
        end
        P("BuffFrame.auraInfo: %d entries, %d secret, %d buffs, max %s: %s", #info, secret, buffs,
            Describe(BuffFrame.maxAuras), table.concat(out, "; "))
    else
        P("BuffFrame.auraInfo: %s", Describe(info))
    end
    -- What FindInCooldownViewer works from: the Cooldown Manager's tracked-buff items.
    for _, name in ipairs({ "BuffIconCooldownViewer", "BuffBarCooldownViewer" }) do
        local pool = type(_G[name]) == "table" and _G[name].itemFramePool
        if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
            local n = 0
            for item in pool:EnumerateActive() do
                n = n + 1
                local ci = item.cooldownInfo
                local readable = type(ci) == "table" and not ns.IsSecret(ci)
                local matches = buff:ViewerItemMatches(ci)
                -- Only the armor's item, and items whose spell can't be read (may be the armor).
                if matches or not readable or ns.IsSecret(ci.spellID) then
                    P("  %s item: cooldownID %s, spellID %s, overrideSpellID %s, isActive %s, matches %s", name,
                        Describe(item.cooldownID), Describe(readable and ci.spellID),
                        Describe(readable and ci.overrideSpellID), Describe(item.isActive), Describe(matches))
                end
            end
            P("%s: %d items", name, n)
        else
            P("%s: %s", name, _G[name] and "no item pool" or "not loaded")
        end
    end
    if buff.instance then
        local d, aura = Try(C_UnitAuras.GetAuraDataByAuraInstanceID, "player", buff.instance)
        P("GetAuraDataByAuraInstanceID(player, %s): %s", Describe(buff.instance), d)
        if type(aura) == "table" and not ns.IsSecret(aura) then
            P("  .auraInstanceID %s, .spellId %s", Describe(aura.auraInstanceID), Describe(aura.spellId))
        end
    end
    local d, list = Try(C_UnitAuras.GetUnitAuras, "player", "HELPFUL")
    P("GetUnitAuras(player, HELPFUL): %s%s", d, type(list) == "table" and not ns.IsSecret(list) and (", count " .. #list) or "")
    if type(list) == "table" and not ns.IsSecret(list) and list[1] then
        local a = list[1]
        P("  [1]: %s, .auraInstanceID %s, .spellId %s, .name %s", Describe(a), Describe(not ns.IsSecret(a) and a.auraInstanceID),
            Describe(not ns.IsSecret(a) and a.spellId), Describe(not ns.IsSecret(a) and a.name))
    end
    P("GetAuraDataByIndex(player, 1, HELPFUL): %s", (Try(C_UnitAuras.GetAuraDataByIndex, "player", 1, "HELPFUL")))
    -- The game's own buff frame keeps showing buffs in combat: what can an addon read from it?
    local frames = BuffFrame and (BuffFrame.auraFrames or (BuffFrame.AuraContainer and { BuffFrame.AuraContainer:GetChildren() }))
    if type(frames) == "table" then
        local shown = 0
        for _, f in ipairs(frames) do
            local okShown, isShown = pcall(f.IsShown, f)
            if okShown and not ns.IsSecret(isShown) and isShown then
                shown = shown + 1
                if shown <= 3 then
                    local icon = f.Icon or f.icon
                    local okTex, tex = pcall(function() return icon and icon:GetTexture() end)
                    local bi = not ns.IsSecret(f.buttonInfo) and type(f.buttonInfo) == "table" and f.buttonInfo or nil
                    P("  BuffFrame shown #%d: texture %s, auraInstanceID %s, buttonInfo.auraInstanceID %s, .expirationTime %s",
                        shown, okTex and Describe(tex) or "ERROR", Describe(f.auraInstanceID),
                        Describe(bi and bi.auraInstanceID), Describe(bi and bi.expirationTime))
                end
            end
        end
        P("BuffFrame: %d frames, %d shown", #frames, shown)
    else
        P("BuffFrame: no aura frames found (%s)", Describe(BuffFrame))
    end
    local now = GetTime()
    P("timeline (oldest first, ms ago):")
    for i = math.min(#ns.trace, 15), 1, -1 do
        local e = ns.trace[i]
        P("  %6d  %s", math.floor((now - e.t) * 1000 + 0.5), e.msg)
    end
    for _, ev in ipairs({ "UNIT_AURA", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_PET" }) do
        P("event %s: %s", ev, ns.eventStatus[ev] or "not registered")
    end
    if #auraLog == 0 then P("no UNIT_AURA for the player since /reload") end
    for i, e in ipairs(auraLog) do
        P("UNIT_AURA #%d, %.1f s ago%s: unit %s, info %s", i, GetTime() - e.at, e.inCombat and " (combat)" or "",
            e.unit, e.info)
        if e.added then
            P("  full %s | added %s | removed %s | updated %s", e.full, e.added, e.removed, e.updated)
        end
    end
end

function M:Update()
    local b = self.button
    -- Mists and Retail have no armor spells: the icon stays off.
    local spell = ns.HighestKnown(D.armor.felArmor) or ns.HighestKnown(D.armor.demonArmor)
        or ns.HighestKnown(D.armor.demonSkin)
    if not spell then
        local sample = D.armor.demonSkin[1]
        b:SetUnlearned(ns.SpellTexture(sample), sample)
        b:SetState(nil)
        return
    end
    b:SetSpell(spell)

    b:SetState(buff:Read() == false and "missing" or nil)
end
