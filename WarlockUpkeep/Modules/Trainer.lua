local _, ns = ...
-- Spell ranks come from the class trainer on clients with Soul Shard items (Forever, Classic Era, TBC).
if not ns.SHARD_ITEMS then return end
local M = ns:NewModule("trainer")

-- New ranks at the trainer. The game lists what a trainer teaches only while its window is open, so the addon
-- remembers that list per character (with the level each rank needs) and, once you reach that level, tells
-- you what's waiting at the trainer.

local function Cfg() return ns.db.trainer end

local function Store()
    ns.cdb.trainer = ns.cdb.trainer or { services = {} }
    return ns.cdb.trainer
end

local function Money(copper)
    if GetCoinTextureString then return GetCoinTextureString(copper) end
    return string.format("%dg %ds %dc", math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end

-- Reads every service, whatever the trainer window's filters show, and puts the filters back. Learned ranks
-- ("used") are skipped anyway, so that filter stays as it is. The filters take true / false.
local FILTERS = { "available", "unavailable" }
local function SetFilter(f, on) pcall(SetTrainerServiceTypeFilter, f, on) end
function M:ReadTrainer()
    if not (GetNumTrainerServices and GetTrainerServiceInfo) then return end
    if IsTradeskillTrainer and IsTradeskillTrainer() then return end
    local saved = {}
    if GetTrainerServiceTypeFilter and SetTrainerServiceTypeFilter then
        for _, f in ipairs(FILTERS) do
            local on = GetTrainerServiceTypeFilter(f)
            saved[f] = on == true or on == 1
            if not saved[f] then SetFilter(f, true) end
        end
    end
    local list = {}
    for i = 1, GetNumTrainerServices() do
        local name, rank, kind = GetTrainerServiceInfo(i)
        if name and kind ~= "header" and kind ~= "used" then
            local level = GetTrainerServiceLevelReq and GetTrainerServiceLevelReq(i) or 0
            local cost = GetTrainerServiceCost and GetTrainerServiceCost(i) or 0
            list[#list + 1] = { name = name, rank = rank ~= "" and rank or nil, level = level or 0, cost = cost or 0 }
        end
    end
    if GetTrainerServiceTypeFilter and SetTrainerServiceTypeFilter then
        for _, f in ipairs(FILTERS) do
            if not saved[f] then SetFilter(f, false) end
        end
    end
    -- Whatever was learned is gone from the list ("used" is skipped), so the stored list is replaced.
    local s = Store()
    s.services = list
    s.notified = UnitLevel("player")
end

-- Ranks you can learn now (level reached), from the last trainer visit.
function M:Available()
    local level = UnitLevel("player")
    local out, cost = {}, 0
    for _, e in ipairs(Store().services) do
        if e.level <= level then
            out[#out + 1] = e
            cost = cost + e.cost
        end
    end
    return out, cost
end

local function Label(e) return e.rank and string.format("%s (%s)", e.name, e.rank) or e.name end

-- After a level up: what's new at this level, once per level.
function M:Notify(level)
    if not Cfg().enabled then return end
    local s = Store()
    if s.notified and s.notified >= level then return end
    s.notified = level
    local new, cost = {}, 0
    for _, e in ipairs(s.services) do
        if e.level <= level then
            new[#new + 1] = Label(e)
            cost = cost + e.cost
        end
    end
    if #new == 0 then return end
    ns.Print(ns.L["new at your trainer (%s): %s."], Money(cost), table.concat(new, ", "))
    if Cfg().sound then ns.PlaySound(Cfg().soundName) end
end

function M:Init()
    ns:RegisterEvent("TRAINER_SHOW", function() C_Timer.After(0, function() M:ReadTrainer() end) end)
    ns:RegisterEvent("PLAYER_LEVEL_UP", function(_, level)
        -- UnitLevel may still report the old level right at the event.
        C_Timer.After(1, function() M:Notify(tonumber(level) or UnitLevel("player")) end)
    end)
end

-- /wu trainer: what's waiting at the trainer now.
function ns.PrintTrainer()
    local list, cost = M:Available()
    if not Store().services[1] then
        ns.Print(ns.L["visit your class trainer once so the addon learns what it teaches."])
    elseif #list == 0 then
        ns.Print(ns.L["nothing new at your trainer for now."])
    else
        local names = {}
        for _, e in ipairs(list) do names[#names + 1] = Label(e) end
        ns.Print(ns.L["new at your trainer (%s): %s."], Money(cost), table.concat(names, ", "))
    end
end
