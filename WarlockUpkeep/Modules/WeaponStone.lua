local _, ns = ...
-- Firestone and Spellstone exist only before Cataclysm (Forever, Classic Era, TBC).
if not ns.SHARD_ITEMS then return end
local D = ns.data
local M = ns:NewModule("weaponStone")

local MAIN_HAND = 16
-- Forever: the stone is used to imbue the main-hand weapon, and the imbue stacks with an oil. Classic Era and
-- TBC: it's held in the off-hand.
local IMBUE = ns.FOREVER
-- After a stone is used, how long a new enchant or buff that shows up is taken for the stone's.
local LEARN_TIME = 5

local function Cfg() return ns.db.weaponStone end
local function Ranks() return D.stones[Cfg().stone] or D.stones.firestone end

local function StoneName() return ns.L[Cfg().stone == "spellstone" and "Spellstone" or "Firestone"] end

-- Right-click flyout: both stones, the chosen one marked; a stone not learned yet can't be picked.
local function FlyoutEntries()
    local list = {}
    for _, key in ipairs({ "firestone", "spellstone" }) do
        local ranks = D.stones[key]
        local spell, rank = ns.HighestKnown(ranks)
        local item = ranks[rank or 1].items[1]
        list[#list + 1] = {
            texture = ns.ItemIcon(item), tipItem = item,
            selected = Cfg().stone == key, disabled = not spell,
            note = not spell and ns.L["Not learned yet."] or nil,
            onClick = function()
                Cfg().stone = key
                ns:UpdateAll()
            end,
        }
    end
    return list
end

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

-- Forever: which stone a weapon enchant or a buff comes from, learned when a stone is used. Since the imbue
-- stacks with an oil, the game may show it either way.
local function Enchants()
    ns.cdb.stoneEnchants = ns.cdb.stoneEnchants or {}
    return ns.cdb.stoneEnchants
end

local function Buffs()
    ns.cdb.stoneBuffs = ns.cdb.stoneBuffs or {}
    return ns.cdb.stoneBuffs
end

-- Your buffs as { [spellID] = cast by you }, or nil when they can't be read (secret in combat).
local function PlayerBuffIDs()
    local set = {}
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
            if not ok or ns.IsSecret(a) then return nil end
            if not a then break end
            if ns.IsSecret(a.spellId) then return nil end
            local src = a.sourceUnit
            set[a.spellId] = ns.IsSecret(src) or src == nil or src == "player"
        end
    elseif UnitBuff then
        for i = 1, 40 do
            local name, _, _, _, _, _, src, _, _, id = UnitBuff("player", i)
            if not name then break end
            set[id] = src == nil or src == "player"
        end
    else
        return nil
    end
    if not next(set) and ns.AurasSecret() then return nil end
    return set
end

-- The buffs to look for: the stone's own use spells and the buffs learned for it.
local function StoneBuffIDs(key)
    local ids = {}
    local get = (C_Item and C_Item.GetItemSpell) or GetItemSpell
    for _, r in ipairs(D.stones[key]) do
        local _, id = get(r.items[1])
        if id then ids[#ids + 1] = id end
    end
    for id, from in pairs(Buffs()) do
        if from == key then ids[#ids + 1] = id end
    end
    return ids
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
        tt:AddLine(ns.L["Right click: choose Firestone or Spellstone."], 0.6, 0.8, 1)
    end
    self.flyout = ns.CreateFlyout(self.button, FlyoutEntries)
    if not IMBUE then return end
    -- Before the stone takes effect: what was on the weapon and on you, to learn what's new afterwards. A
    -- click comes before the cast and the cast's success after it, so the first of the two keeps its picture.
    local function Used(key)
        if not (self.usedAt and GetTime() - self.usedAt < 10) then
            self.enchantBefore, self.buffsBefore = self.lastEnchant, self.lastBuffs
        end
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
    local enchant, buffs = MainHandEnchant(), PlayerBuffIDs()
    -- A stone was just used: an enchant or a buff that wasn't there before is that stone's. An oil already on the
    -- weapon stays an oil.
    if self.usedAt and GetTime() - self.usedAt <= LEARN_TIME then
        if enchant and enchant ~= 0 and enchant ~= self.enchantBefore then Enchants()[enchant] = self.usedKey end
        -- Only a single new buff of your own: one from a groupmate in the meantime isn't the stone.
        if buffs and self.buffsBefore then
            local new, count = nil, 0
            for id, mine in pairs(buffs) do
                if mine and self.buffsBefore[id] == nil then new, count = id, count + 1 end
            end
            if count == 1 then Buffs()[new] = self.usedKey end
        end
    end
    -- Last known state while no stone is being used, for the next time one is.
    if not self.usedAt or GetTime() - self.usedAt > LEARN_TIME then
        if enchant ~= nil then self.lastEnchant = enchant end
        if buffs then self.lastBuffs = buffs end
    end
    local stone = Cfg().stone
    if enchant and Enchants()[enchant] == stone then return true end
    local buff = ns.PlayerHasAura(StoneBuffIDs(stone))
    if buff then return true end
    -- An oil or another stone doesn't count: the imbue stacks with them.
    if enchant == nil or buff == nil then return nil end
    return false
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
