local _, ns = ...
local D = ns.data
local M = ns:NewModule("healthstone")

local ranks = D.stones.healthstone
local allItems = {}
for _, r in ipairs(ranks) do
    for _, item in ipairs(r.items) do allItems[#allItems + 1] = item end
end

local function Cfg() return ns.db.healthstone end

-- Health in percent, or nil when unreadable (secret in combat on newer clients).
local function HealthPercent()
    local ok, hp, max = pcall(function() return UnitHealth("player"), UnitHealthMax("player") end)
    if not ok or ns.IsSecret(hp) or ns.IsSecret(max) or type(hp) ~= "number" or not max or max <= 0 then return nil end
    return hp / max * 100
end

-- A Healthstone on cooldown can't be used anyway: no "low health" reminder then.
local function OnCooldown(item)
    local f = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    if not f then return false end
    local ok, start, duration = pcall(f, item)
    if not ok or ns.IsSecret(start) or ns.IsSecret(duration) or not start or start == 0 then return false end
    -- The global cooldown isn't the stone's own.
    return duration > 1.5 and start + duration > GetTime()
end

function M:Init()
    self.button = ns.CreateActionIcon("healthstone", "Healthstone")
    self.button.hint = function(tt)
        if M.button.state == "low" then
            tt:AddLine(ns.L["Low health. Click to use your Healthstone."], 0.3, 1, 0.3)
        else
            tt:AddLine(ns.L["No Healthstone in bags. Click to create the strongest one."], 0, 1, 0)
        end
    end
    ns:RegisterEvent("UNIT_HEALTH", function(_, unit) if unit == "player" then M:Update() end end)
    ns:RegisterEvent("UNIT_MAXHEALTH", function(_, unit) if unit == "player" then M:Update() end end)
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

    -- The strongest Healthstone in the bags (the list goes from the weakest up).
    local have, unknown
    for i = #allItems, 1, -1 do
        local n = ns.ItemCount(allItems[i])
        if n == nil then unknown = true elseif n > 0 then have = allItems[i]; break end
    end
    if not have and unknown then have = self.lastHave end -- bags unreadable: keep last known
    self.lastHave = have

    if not have then
        b:SetSpell(spell, ns.ItemIcon(ranks[rank].items[1]))
        b:SetState("missing")
        return
    end

    -- With a stone in the bags the icon is set to use it, also while hidden: in combat the action can't
    -- change any more, only show up when health drops.
    b:SetAction({ type1 = "macro", macrotext1 = "/use item:" .. have }, ns.ItemIcon(have), nil, have)
    local low = Cfg().lowHealth
    local pct = HealthPercent()
    if pct == nil then pct = self.lastPct end
    self.lastPct = pct
    local isLow = low.enabled and pct ~= nil and pct < low.percent and not OnCooldown(have)
    b:SetState(isLow and "low" or nil)
end
