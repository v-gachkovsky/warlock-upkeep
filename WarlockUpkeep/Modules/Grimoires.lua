local _, ns = ...
-- Grimoires teach demon spells only on clients with Soul Shard items (Classic Era, TBC, Forever).
if not ns.SHARD_ITEMS then return end
local D = ns.data
local M = ns:NewModule("grimoires")

local function Cfg() return ns.db.grimoires end

M.DEMON_NAMES = {
    imp = "Imp", voidwalker = "Voidwalker", succubus = "Succubus",
    felhunter = "Felhunter", incubus = "Incubus", felguard = "Felguard",
}

-- What each demon knows, per character: known[demon][spell name] = highest rank.
-- A demon only lists its spells while summoned, so it's remembered from the last time it was out.
local function Store()
    ns.cdb.grimoires = ns.cdb.grimoires or { known = {} }
    return ns.cdb.grimoires
end

-- Pet spell ID -> rank, and spell name -> demon. Names are the client's own (localized),
-- so they're built once the spell data is there.
local rankByID = {}
for _, g in pairs(D.grimoires) do rankByID[g[2]] = g[3] end
local demonByName
local function DemonByName()
    if demonByName then return demonByName end
    local map, complete = {}, true
    for _, g in pairs(D.grimoires) do
        local name = ns.SpellName(g[2])
        if name then map[name] = g[1] else complete = false end
    end
    -- Keep it only once every name has loaded.
    if complete then demonByName = map end
    return map
end

local summonKey, demonByKey = {}, {}
for _, d in ipairs(D.demons) do
    demonByKey[d.key] = d
    for _, s in ipairs(d.list or { d.spell }) do
        if type(s) == "number" then summonKey[s] = d.key end
    end
end

-- The summoned demon's spellbook: { name, sub (rank text), id }. Clients mix the old and the new
-- spellbook API (Classic Era has C_SpellBook.HasPetSpells but not C_SpellBook.GetSpellBookItemInfo),
-- so each call takes whichever exists. The new calls name the pet bank by Enum, the old ones by
-- "pet" (given a number, the old ones read the player's own spellbook).
local function NewPetBank() return Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet end
local OLD_PET_BANK = BOOKTYPE_PET or "pet"

local function PetSpellCount()
    local fn = (C_SpellBook and C_SpellBook.HasPetSpells) or HasPetSpells
    return fn and fn() or 0
end

local function PetSpell(i)
    local bank = NewPetBank()
    if bank and C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
        local info = C_SpellBook.GetSpellBookItemInfo(i, bank)
        if info and info.name then return info.name, info.subName, info.spellID or info.actionID end
    end
    local name, sub
    if bank and C_SpellBook and C_SpellBook.GetSpellBookItemName then
        name, sub = C_SpellBook.GetSpellBookItemName(i, bank)
    elseif GetSpellBookItemName then
        name, sub = GetSpellBookItemName(i, OLD_PET_BANK)
    end
    local id
    if GetSpellBookItemInfo then id = select(2, GetSpellBookItemInfo(i, OLD_PET_BANK)) end
    -- Pet entries carry flags in the high byte (0xC10018A3 is spell 6307, 0x18A3): keep the spell ID.
    if type(id) == "number" then id = id % 0x1000000 end
    return name, sub, id
end

function M.PetSpells()
    local list = {}
    for i = 1, PetSpellCount() do
        local ok, name, sub, id = pcall(PetSpell, i)
        if ok and name then list[#list + 1] = { name = name, sub = sub, id = id } end
    end
    return list
end

function M:ScanPet()
    if not ns.Bool(UnitExists, "pet") then return end
    local ok, spells = pcall(M.PetSpells)
    if not ok then return end
    local names = DemonByName()
    local demon, ranks = nil, {}
    for _, s in ipairs(spells) do
        local d = s.name and names[s.name]
        if d then
            demon = demon or d
            local r = rankByID[s.id] or tonumber(s.sub and s.sub:match("%d+")) or 1
            ranks[s.name] = math.max(ranks[s.name] or 0, r)
        end
    end
    if not demon then return end
    local store = Store()
    -- Forever's Incubus has the Succubus spells: tell them apart by the last summon.
    if demon == "succubus" and store.lastSummon == "incubus" then demon = "incubus" end
    local known = store.known[demon] or {}
    for name, r in pairs(ranks) do known[name] = math.max(known[name] or 0, r) end
    store.known[demon] = known
    if MerchantFrame and MerchantFrame:IsShown() then self:MarkMerchant() end
end

local function ScheduleScan()
    C_Timer.After(0.5, function() M:ScanPet() end)
end

-- Per demon the grimoire is for: "known", "missing", "unknown" (never seen summoned)
-- or "unlearned" (you can't summon it yet: no mark, nothing to check).
function M:Status(itemID)
    local g = itemID and D.grimoires[itemID]
    if not g then return nil end
    local name = ns.SpellName(g[2])
    local known = Store().known
    local demons = { g[1] }
    -- The Incubus may learn Succubus grimoires too: show it once its spells were seen.
    if g[1] == "succubus" and known.incubus then demons[2] = "incubus" end
    local out = {}
    for _, d in ipairs(demons) do
        local k = known[d]
        local have = k and name and k[name] or 0
        out[#out + 1] = { demon = d, have = have, rank = g[3], spell = name,
            state = k and (have >= g[3] and "known" or "missing")
                or (ns.DemonSpell(demonByKey[d]) and "unknown" or "unlearned") }
    end
    return out
end

-- Any of them missing: "missing"; any unchecked: "unknown"; then any known: "known";
-- none of them summonable yet: "unlearned".
local function Overall(list)
    local seen = {}
    for _, s in ipairs(list) do seen[s.state] = true end
    if seen.missing then return "missing" end
    if seen.unknown then return "unknown" end
    if seen.known then return "known" end
    return "unlearned"
end

local function ItemIDFromLink(link)
    if not link or ns.IsSecret(link) then return nil end
    return tonumber(link:match("item:(%d+)"))
end

------------------------------------------------------------------------
-- Vendor window: a check on grimoires already learned, a question mark where it's unknown;
-- learned ones turn light green, those for demons you can't summon yet dark grey; a bag on the ones
-- in your bags.
------------------------------------------------------------------------
local MARKS = { known = "Interface\\RaidFrame\\ReadyCheck-Ready", unknown = "Interface\\RaidFrame\\ReadyCheck-Waiting" }

local function MerchantButton(i)
    local b = _G["MerchantItem" .. i .. "ItemButton"]
    if not b then return nil end
    if not b.wuMark then
        b.wuMark = b:CreateTexture(nil, "OVERLAY", nil, 7)
        b.wuMark:SetSize(18, 18)
        b.wuMark:SetPoint("TOPRIGHT", 4, 4)
        -- A bag in the other corner: you already have this grimoire with you.
        b.wuBag = b:CreateTexture(nil, "OVERLAY", nil, 7)
        b.wuBag:SetSize(16, 16)
        b.wuBag:SetPoint("TOPLEFT", -4, 4)
        b.wuBag:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
    end
    return b
end

-- Icon colors over the greyed icon: learned grimoires light green, those for demons you can't
-- summon yet dark grey, apart from the game's own red for books you can't use yet.
local TINTS = { known = { 0.55, 1, 0.55 }, unlearned = { 0.4, 0.4, 0.4 } }

local function IsTint(r, g, b)
    for _, c in pairs(TINTS) do
        if math.abs(r - c[1]) < 0.01 and math.abs(g - c[2]) < 0.01 and math.abs(b - c[3]) < 0.01 then
            return true
        end
    end
    return false
end

local function SetMark(b, state)
    local icon = b.icon or _G[b:GetName() .. "IconTexture"]
    b.wuMark:SetTexture(state and MARKS[state])
    b.wuMark:SetShown(state ~= nil and MARKS[state] ~= nil)
    if not icon then return end
    -- Restore only what this addon changed: the game's own color (red when unusable) is kept aside.
    local tint = TINTS[state]
    if tint or b.wuGrey then
        icon:SetDesaturated(tint ~= nil)
        b.wuGrey = tint and true or nil
    end
    -- The vendor window repaints the colors on every page, so the tint is checked each time.
    local r, g, bl = icon:GetVertexColor()
    local tinted = IsTint(r, g, bl)
    if tint then
        if not tinted then b.wuColor = { r, g, bl } end
        icon:SetVertexColor(unpack(tint))
    elseif b.wuColor then
        if tinted then icon:SetVertexColor(unpack(b.wuColor)) end
        b.wuColor = nil
    end
end

function M:MarkMerchant()
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10
    local buyback = MerchantFrame.selectedTab and MerchantFrame.selectedTab ~= 1
    for i = 1, perPage do
        local b = MerchantButton(i)
        if b then
            local state, inBags
            if Cfg().merchant and not buyback then
                local index = ((MerchantFrame.page or 1) - 1) * perPage + i
                local id = ItemIDFromLink(GetMerchantItemLink(index))
                local list = self:Status(id)
                state = list and Overall(list) or nil
                if state == "missing" then state = nil end
                inBags = list and (ns.ItemCount(id) or 0) > 0
            end
            SetMark(b, state)
            b.wuBag:SetShown(inBags and true or false)
        end
    end
end

------------------------------------------------------------------------
-- Tooltip: what each demon knows of the grimoire's spell.
------------------------------------------------------------------------
local STATE_TEXT = {
    known   = { "already knows %s", 0.3, 1, 0.3 },
    missing = { "doesn't know it yet", 1, 0.82, 0 },
    unknown = { "not checked yet: summon this demon once", 0.6, 0.6, 0.6 },
    unlearned = { "you can't summon it yet", 0.6, 0.6, 0.6 },
}

local function AddTooltipLines(tt, itemID)
    if not Cfg().tooltip then return end
    local list = M:Status(itemID)
    if not list then return end
    for _, s in ipairs(list) do
        local t = STATE_TEXT[s.state]
        local have = s.have > 0 and string.format(ns.L["%s (Rank %d)"], s.spell or "", s.have) or (s.spell or "")
        local text = s.state == "known" and string.format(ns.L[t[1]], have) or ns.L[t[1]]
        if s.state == "missing" and s.have > 0 then text = string.format(ns.L["knows Rank %d, not this one"], s.have) end
        tt:AddLine("|cff9482c9" .. ns.L[M.DEMON_NAMES[s.demon]] .. ":|r " .. text, t[2], t[3], t[4])
    end
    tt:Show()
end

local function HookTooltips()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
            if tt ~= GameTooltip and tt ~= ItemRefTooltip then return end
            local id = data and data.id
            if id and not ns.IsSecret(id) then pcall(AddTooltipLines, tt, id) end
        end)
        return
    end
    for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
        tt:HookScript("OnTooltipSetItem", function(self)
            local _, link = self:GetItem()
            pcall(AddTooltipLines, self, ItemIDFromLink(link))
        end)
    end
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------
function M:Init()
    Store()
    ns:RegisterEvent("UNIT_PET", function(_, unit) if unit == "player" then ScheduleScan() end end)
    ns:RegisterEvent("PET_BAR_UPDATE", ScheduleScan)
    ns:RegisterEvent("SPELLS_CHANGED", ScheduleScan)
    ns:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
        if unit ~= "player" or ns.IsSecret(spellID) or not summonKey[spellID] then return end
        Store().lastSummon = summonKey[spellID]
    end)
    -- A grimoire bought, read or sold changes the bag marks.
    ns:RegisterEvent("BAG_UPDATE_DELAYED", function()
        if MerchantFrame and MerchantFrame:IsShown() then M:MarkMerchant() end
    end)
    if MerchantFrame_UpdateMerchantInfo then
        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function() M:MarkMerchant() end)
    end
    if MerchantFrame_UpdateBuybackInfo then
        hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function() M:MarkMerchant() end)
    end
    HookTooltips()
    ScheduleScan()
end

function M:ApplySettings()
    if MerchantFrame and MerchantFrame:IsShown() then self:MarkMerchant() end
end

-- Demons whose spells are remembered, and learned ones not summoned since, in the usual order.
function M:CheckedDemons()
    local checked, unchecked = {}, {}
    for _, d in ipairs(D.demons) do
        local name = ns.L[M.DEMON_NAMES[d.key] or d.key]
        if Store().known[d.key] then
            checked[#checked + 1] = name
        elseif ns.DemonSpell(d) then
            unchecked[#unchecked + 1] = name
        end
    end
    return checked, unchecked
end

-- /wu grimoires: what's remembered, and the summoned demon's raw spellbook.
function ns.DebugGrimoires()
    for demon, spells in pairs(Store().known) do
        local parts = {}
        for name, r in pairs(spells) do parts[#parts + 1] = name .. " " .. r end
        table.sort(parts)
        ns.Print("%s: %s", M.DEMON_NAMES[demon] or demon, table.concat(parts, ", "))
    end
    ns.Print("last summon: %s", tostring(Store().lastSummon))
    local n = 0
    for _ in pairs(DemonByName()) do n = n + 1 end
    ns.Print("spell names loaded: %d; Firebolt = %s", n, tostring(ns.SpellName(7799)))
    local ok, count = pcall(PetSpellCount)
    ns.Print("pet spellbook: %s spells; C_SpellBook item info %s, item name %s; old item name %s",
        tostring(count), tostring(C_SpellBook and C_SpellBook.GetSpellBookItemInfo ~= nil),
        tostring(C_SpellBook and C_SpellBook.GetSpellBookItemName ~= nil), tostring(GetSpellBookItemName ~= nil))
    if not ns.Bool(UnitExists, "pet") then ns.Print("no demon out."); return end
    local okList, list = pcall(M.PetSpells)
    if not okList then ns.Print("reading the spellbook failed: %s", tostring(list)); return end
    for _, s in ipairs(list) do
        ns.Print("  pet spell: %s / %s / id %s", tostring(s.name), tostring(s.sub), tostring(s.id))
    end
    M:ScanPet()
end
