local _, ns = ...
-- Infernal Stone and Demonic Figurine are reagents only before Cataclysm (Forever, Classic Era, TBC).
if not ns.SHARD_ITEMS then return end
local D = ns.data
local M = ns:NewModule("reagents")

local function Cfg() return ns.db.reagents end

-- Reagents of spells you know, with how many to keep: { r, have, keep }.
function M:List()
    local out = {}
    for _, r in ipairs(D.reagents) do
        if ns.IsKnown(r.spell) then
            out[#out + 1] = { r = r, have = ns.ItemCount(r.item) or 0, keep = Cfg().keep[r.key] or 0 }
        end
    end
    return out
end

-- Lines for the Soul Shard counter's tooltip.
function M:AddTooltipLines(tt)
    local list = self:List()
    if #list == 0 then return end
    tt:AddLine(" ")
    tt:AddLine(ns.L["Reagents"], 0.58, 0.51, 0.79)
    for _, e in ipairs(list) do
        local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(e.r.item)) or ns.L[e.r.name]
        local low = e.keep > 0 and e.have < e.keep
        local text = e.keep > 0 and string.format("%d/%d", e.have, e.keep) or tostring(e.have)
        tt:AddDoubleLine("  " .. name, text, 1, 1, 1, low and 1 or 0.8, low and 0.3 or 0.8, low and 0.3 or 0.8)
    end
end

local function MerchantItemID(i)
    if GetMerchantItemID then return GetMerchantItemID(i) end
    local link = GetMerchantItemLink(i)
    return link and tonumber(link:match("item:(%d+)"))
end

-- At a vendor: buy each reagent up to the amount to keep, if there's money for it.
function M:Buy()
    if not Cfg().autoBuy then return end
    local want = {}
    for _, e in ipairs(self:List()) do
        if e.have < e.keep then want[e.r.item] = e.keep - e.have end
    end
    if not next(want) then return end
    for i = 1, GetMerchantNumItems() do
        local id = MerchantItemID(i)
        local n = id and want[id]
        if n then
            local name, _, price, perPurchase, available = GetMerchantItemInfo(i)
            perPurchase = perPurchase and perPurchase > 0 and perPurchase or 1
            local buys = math.ceil(n / perPurchase)
            if available and available >= 0 then buys = math.min(buys, available) end
            if price and price > 0 then buys = math.min(buys, math.floor(GetMoney() / price)) end
            if buys > 0 then
                -- One purchase takes at most a stack.
                local total = buys * perPurchase
                local stack = GetMerchantItemMaxStack and GetMerchantItemMaxStack(i) or total
                stack = stack and stack > 0 and stack or total
                local left = total
                while left > 0 do
                    local q = math.min(left, stack)
                    BuyMerchantItem(i, q)
                    left = left - q
                end
                ns.Print(ns.L["bought %d x %s."], buys * perPurchase, name or tostring(id))
            elseif price and price > GetMoney() then
                ns.Print(ns.L["not enough money for %s."], name or tostring(id))
            end
            want[id] = nil
        end
    end
end

function M:Init()
    ns:RegisterEvent("MERCHANT_SHOW", function() M:Buy() end)
end
