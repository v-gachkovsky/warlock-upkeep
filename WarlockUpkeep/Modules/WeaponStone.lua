local _, ns = ...
-- Firestone and Spellstone exist only before Cataclysm (Forever, Classic Era, TBC).
if not ns.SHARD_ITEMS then return end
local D = ns.data
local M = ns:NewModule("weaponStone")

local MAIN_HAND = 16
-- Forever: the stone is used to imbue the main-hand weapon. Classic Era and TBC: it's held in the off-hand.
local IMBUE = ns.FOREVER

local function Cfg() return ns.db.weaponStone end
local function Ranks() return D.stones[Cfg().stone] or D.stones.firestone end

local function StoneName() return ns.L[Cfg().stone == "spellstone" and "Spellstone" or "Firestone"] end

local function IsEquipped(item)
    local f = (C_Item and C_Item.IsEquippedItem) or IsEquippedItem
    return f and ns.Bool(f, item)
end

-- Main-hand temporary enchant: its ID, false for none, or nil when unreadable.
local function MainHandEnchant()
    if not GetWeaponEnchantInfo then return nil end
    local ok, has, _, _, id = pcall(GetWeaponEnchantInfo)
    if not ok or ns.IsSecret(has) or ns.IsSecret(id) then return nil end
    if not has then return false end
    return id or 0
end

-- Use spell of every stone item, to notice a stone used by hand (bag, macro) and learn its enchant.
local itemSpells
local function StoneOfSpell(spellID)
    if not itemSpells then
        itemSpells = {}
        local get = (C_Item and C_Item.GetItemSpell) or GetItemSpell
        for _, key in ipairs({ "firestone", "spellstone" }) do
            for _, r in ipairs(D.stones[key]) do
                local _, id = get(r.items[1])
                if id then itemSpells[id] = key end
            end
        end
        if not next(itemSpells) then itemSpells = nil end -- item data not loaded yet: try again later
    end
    return itemSpells and itemSpells[spellID]
end

-- Forever: which stone a weapon enchant comes from, learned when a stone is used.
local function Enchants()
    ns.cdb.stoneEnchants = ns.cdb.stoneEnchants or {}
    return ns.cdb.stoneEnchants
end

function M:Init()
    self.button = ns.CreateActionIcon("weaponStone", "Firestone / Spellstone")
    self.button.previewState = "use"
    self.button.hint = function(tt)
        local name = StoneName()
        if M.button.state == "create" then
            tt:AddLine(string.format(ns.L["No %s in bags. Click to create the strongest one."], name), 1, 0.3, 0.3)
        elseif IMBUE then
            tt:AddLine(string.format(ns.L["%s is not applied to your weapon. Click to apply it."], name), 1, 0.82, 0)
        else
            tt:AddLine(string.format(ns.L["%s is not equipped. Click to equip it."], name), 1, 0.82, 0)
        end
    end
    if not IMBUE then return end
    local function Used(key)
        self.usedKey, self.usedAt = key, GetTime()
        ns:ScheduleUpdate()
    end
    self.button:HookScript("PostClick", function()
        if M.button.state == "use" then Used(Cfg().stone) end
    end)
    ns:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
        if unit ~= "player" or ns.IsSecret(spellID) then return end
        local key = StoneOfSpell(spellID)
        if key then Used(key) end
    end)
    ns:RegisterEvent("UNIT_INVENTORY_CHANGED", function(_, unit)
        if unit == "player" then ns:ScheduleUpdate() end
    end)
end

function M:ApplySettings() end

-- Is the chosen stone on: equipped (Classic Era, TBC) or imbued on the weapon (Forever)?
-- nil when it can't be told right now.
function M:Applied()
    local ranks = Ranks()
    if not IMBUE then
        for _, r in ipairs(ranks) do
            if IsEquipped(r.items[1]) then return true end
        end
        return false
    end
    local enchant = MainHandEnchant()
    if enchant == nil then return nil end
    -- A stone was just used: the enchant that shows up is that stone's.
    if enchant and self.usedAt and GetTime() - self.usedAt <= 3 then
        Enchants()[enchant] = self.usedKey
        self.usedAt = nil
    end
    if not enchant then return false end
    local from = Enchants()[enchant]
    if from == Cfg().stone then return true end
    -- Another stone's or an oil's enchant: counts as applied unless set to remind anyway.
    return not Cfg().remindOverOther
end

function M:Update()
    local b = self.button
    if not Cfg().enabled then
        b:SetState(nil)
        return
    end
    local ranks = Ranks()
    local spell, rank = ns.HighestKnown(ranks)
    if not spell then
        local sample = ranks[1].items[1]
        b:SetUnlearned(ns.ItemIcon(sample), nil, sample)
        b:SetState(nil)
        return
    end

    local applied = self:Applied()
    if applied == nil then applied = self.lastApplied end -- unreadable: keep last known
    self.lastApplied = applied
    -- Forever: nothing to imbue without a main-hand weapon.
    local noWeapon = IMBUE and not GetInventoryItemID("player", MAIN_HAND)

    -- A stone in the bags: equip or use it.
    local item, unknown
    for i = #ranks, 1, -1 do
        local n = ns.ItemCount(ranks[i].items[1])
        if n == nil then unknown = true elseif n > 0 and not (not IMBUE and IsEquipped(ranks[i].items[1])) then
            item = ranks[i].items[1]
            break
        end
    end
    if not item and unknown then item = self.lastItem end -- bags unreadable: keep last known
    self.lastItem = item

    if item then
        local macro = string.format(IMBUE and "/use item:%d" or "/equip item:%d", item)
        b:SetAction({ type1 = "macro", macrotext1 = macro }, ns.ItemIcon(item), nil, item)
        b:SetState(not applied and not noWeapon and "use" or nil)
        return
    end

    -- No stone in the bags: create one.
    b:SetSpell(spell, ns.ItemIcon(ranks[rank].items[1]))
    b:SetState(not applied and not noWeapon and "create" or nil)
end
