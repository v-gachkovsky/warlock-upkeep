local _, ns = ...
local D = ns.data
local M = ns:NewModule("pet")

-- Binding slots: key in db.pet.bindings -> secure attribute prefix.
M.SLOTS = {
    { key = "none",  prefix = "",       text = "Click" },
    { key = "shift", prefix = "shift-", text = "Shift + Click" },
    { key = "ctrl",  prefix = "ctrl-",  text = "Ctrl + Click" },
    { key = "alt",   prefix = "alt-",   text = "Alt + Click" },
    { key = "meta",  prefix = "meta-",  text = "Cmd + Click", mac = true },
}

-- Seconds the demon gets to come back after landing or dismounting.
local PET_RETURN_DELAY = 3

-- Grimoire of Sacrifice: no demon on purpose (followed through combat like the armor buff).
local sacrifice = ns.NewBuffTracker(D.petSacrificeBuffs, nil, "sacrifice")
local isSacrifice = {}
for _, id in ipairs(D.petSacrificeBuffs) do isSacrifice[id] = true end

local demonByKey = {}
for _, d in ipairs(D.demons) do demonByKey[d.key] = d end

function M.DemonName(key)
    local d = demonByKey[key]
    if not d then return key end
    return ns.SpellName(ns.DemonSpell(d) or d.spell) or d.name or key
end

function M.SlotAvailable(slot)
    return not slot.mac or (IsMacClient and IsMacClient())
end

-- Spell ID for a demon key, or nil if the demon is not learned.
local function DemonSpell(key)
    return ns.DemonSpell(demonByKey[key])
end

-- Same prefix format the secure action button uses for modified attributes.
local function CurrentPrefix()
    local p = ""
    if IsShiftKeyDown() then p = "shift-" .. p end
    if IsControlKeyDown() then p = "ctrl-" .. p end
    if IsAltKeyDown() then p = "alt-" .. p end
    if IsMetaKeyDown and IsMetaKeyDown() then p = "meta-" .. p end
    return p
end

-- Show the demon that a click with the currently held modifier would summon.
function M:UpdateModifierIcon()
    local b = self.button
    local attrs = b.appliedAttrs or b.wantAttrs
    if not attrs then return end
    local spell = attrs[CurrentPrefix() .. "spell1"] or attrs.spell1
    if not spell then return end
    b.icon:SetTexture(ns.SpellTexture(spell) or ns.QUESTION_ICON)
    if b.tipSpell ~= spell then
        b.tipSpell = spell
        if GameTooltip:IsOwned(b) then b:GetScript("OnEnter")(b) end
    end
end

function M:Init()
    self.button = ns.CreateActionIcon("pet", "Summon Demon")
    self.button.hint = function(tt)
        tt:AddLine(ns.L["No demon summoned."], 0, 1, 0)
        local bindings = ns.db.pet.bindings
        for _, slot in ipairs(M.SLOTS) do
            if M.SlotAvailable(slot) then
                local key = bindings[slot.key]
                if key == "default" then key = bindings.none end
                if DemonSpell(key) then
                    tt:AddDoubleLine(ns.L[slot.text], M.DemonName(key), 1, 1, 1, 1, 0.82, 0)
                end
            end
        end
    end
    ns:RegisterEvent("UNIT_PET", function(_, unit)
        if unit ~= "player" then return end
        -- A demon gone is checked a moment later: taking a flight path dismisses it just before
        -- the player counts as on the taxi.
        if ns.Bool(UnitExists, "pet") then M:Update() end
        C_Timer.After(0.5, function() M:Update() end)
    end)
    ns:RegisterEvent("UNIT_AURA", function(_, unit, info)
        if ns.IsSecret(unit) or unit ~= "player" then return end
        sacrifice:OnAuraUpdate(info)
        M:Update()
    end)
    ns:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
        if unit == "player" and not ns.IsSecret(spellID) and isSacrifice[spellID] then
            sacrifice:Cast()
            M:Update()
        end
    end)
    ns:RegisterEvent("MODIFIER_STATE_CHANGED", function() M:UpdateModifierIcon() end)
end

function M:ApplySettings() end

function M:Update()
    local b = self.button
    local bindings = ns.db.pet.bindings
    local defaultSpell = DemonSpell(bindings.none) or DemonSpell("imp")
    if not defaultSpell then
        local sample = demonByKey.imp.spell
        b:SetUnlearned(ns.SpellTexture(sample), sample)
        b:SetState(nil)
        return
    end

    local attrs = {}
    for _, slot in ipairs(M.SLOTS) do
        if M.SlotAvailable(slot) then
            local key = bindings[slot.key]
            local spell = (key == "default") and defaultSpell or DemonSpell(key) or defaultSpell
            attrs[slot.prefix .. "type1"] = "spell"
            attrs[slot.prefix .. "spell1"] = spell
        end
    end
    b:SetAction(attrs, ns.SpellTexture(defaultSpell), defaultSpell)

    -- Pet state can be secret in combat: then keep the last known one.
    local exists, dead = ns.Bool(UnitExists, "pet"), ns.Bool(UnitIsDead, "pet")
    local hasPet
    if exists == nil or (exists and dead == nil) then
        hasPet = self.lastHasPet
    else
        hasPet = exists and not dead
    end
    if self.lastHasPet and not hasPet then self.petLostAt = GetTime() end
    self.lastHasPet = hasPet

    -- Flight paths and flying mounts dismiss the demon for a while: while mounted, flying or on a taxi,
    -- the demon counts as there if it was there when that started (or gone just now, a moment before
    -- the player counts as mounted or flying). After landing or dismounting it gets a few seconds
    -- to come back.
    if ns.OnTaxi() or ns.Bool(IsMounted) or ns.Bool(IsFlying) then
        if self.awayHadPet == nil then
            self.awayHadPet = hasPet or (self.petLostAt ~= nil and GetTime() - self.petLostAt < 2)
        end
        self.backAt = nil
    elseif self.awayHadPet ~= nil then
        self.backAt = self.backAt or GetTime()
        if hasPet or GetTime() - self.backAt >= PET_RETURN_DELAY then
            self.awayHadPet, self.backAt = nil, nil
        end
    end
    if self.awayHadPet then hasPet = true end
    if not hasPet then
        hasPet = sacrifice:Read() == true
    end
    b:SetState(not hasPet and "missing" or nil)
    self:UpdateModifierIcon()
end
