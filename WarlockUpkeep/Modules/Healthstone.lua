local _, ns = ...
local D = ns.data
local M = ns:NewModule("healthstone")

local ranks = D.stones.healthstone
local allItems = {}
for _, r in ipairs(ranks) do
    for _, item in ipairs(r.items) do allItems[#allItems + 1] = item end
end

function M:Init()
    self.button = ns.CreateActionIcon("healthstone", "Healthstone")
    self.button.hint = function(tt) tt:AddLine(ns.L["No Healthstone in bags. Click to create the strongest one."], 0, 1, 0) end
end

function M:ApplySettings() end

function M:Update()
    local b = self.button
    local spell, rank = ns.HighestKnown(ranks)
    if not spell then
        local item = ranks[1].items[1]
        b:SetUnlearned(ns.ItemIcon(item), nil, item)
        b:SetState(nil)
        return
    end
    b:SetSpell(spell, ns.ItemIcon(ranks[rank].items[1]))

    local have, unknown = false, false
    for _, item in ipairs(allItems) do
        local n = ns.ItemCount(item)
        if n == nil then unknown = true elseif n > 0 then have = true; break end
    end
    if not have and unknown then have = self.lastHave end -- bags unreadable: keep last known
    self.lastHave = have
    b:SetState(not have and "missing" or nil)
end
