local _, ns = ...
-- Only clients with Soul Shard items get the counter (see ns.SHARD_ITEMS).
if not ns.SHARD_ITEMS then return end
local D = ns.data
local M = ns:NewModule("shards")

local function Cfg() return ns.db.shards end

-- Recommended shard reserve: one demon summon + one per learned stone + spare.
function M:Desired()
    local cfg = Cfg()
    local parts = {}
    for _, d in ipairs(D.demons) do
        if d.shard and ns.DemonSpell(d) then
            parts[#parts + 1] = ns.L["Demon summon"]
            break
        end
    end
    for _, key in ipairs(D.stoneOrder) do
        local spell = ns.HighestKnown(D.stones[key])
        if spell then parts[#parts + 1] = ns.SpellName(spell) or key end
    end
    if cfg.includeRitual and ns.IsKnown(D.ritualOfSummoning) then
        parts[#parts + 1] = ns.SpellName(D.ritualOfSummoning) or "Ritual of Summoning"
    end
    return #parts + cfg.spare, parts
end

function M:Threshold()
    local cfg = Cfg()
    if cfg.autoThreshold then return (self:Desired()) end
    return cfg.threshold
end

function M:Init()
    local f = CreateFrame("Frame", "WarlockUpkeep_Shards", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true)
    self.frame = f

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("LEFT")
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.icon:SetTexture(ns.ItemIcon(D.SOUL_SHARD) or ns.QUESTION_ICON)

    f.iconFrame = CreateFrame("Frame", nil, f)
    f.iconFrame:SetAllPoints(f.icon)
    f.glow = ns.CreateGlow(f.iconFrame)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 1)

    ns.MakeMovable(f, Cfg)
    f:SetScript("OnEnter", function(self)
        local count = ns.ItemCount(D.SOUL_SHARD) or M.lastCount or 0
        local desired, parts = M:Desired()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.L["Soul Shards"], 0.58, 0.51, 0.79)
        GameTooltip:AddDoubleLine(ns.L["In bags"], count, 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(ns.L["Recommended"], desired, 1, 1, 1, 1, 0.82, 0)
        for _, p in ipairs(parts) do GameTooltip:AddDoubleLine("  " .. p, 1, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8) end
        if Cfg().spare > 0 then GameTooltip:AddDoubleLine("  " .. ns.L["Spare"], Cfg().spare, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8) end
        GameTooltip:AddDoubleLine(ns.L["Low threshold"], M:Threshold(), 1, 1, 1, 1, 0.3, 0.3)
        if not Cfg().locked then GameTooltip:AddLine(ns.L["Drag to move"], 0.6, 0.6, 0.6) end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", GameTooltip_Hide)
end

function M:ApplySettings()
    local cfg, f = Cfg(), self.frame
    ns.ApplyFont(f.text, cfg.font, cfg.fontSize, cfg.outline)
    f.icon:SetSize(cfg.iconSize, cfg.iconSize)
    f.icon:SetShown(cfg.showIcon)
    f.text:ClearAllPoints()
    if cfg.showIcon then
        f.text:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
    else
        f.text:SetPoint("LEFT", f, "LEFT", 2, 0)
    end
    ns.ApplyPoint(f, cfg.point)
end

function M:Update()
    local cfg, f = Cfg(), self.frame
    if not cfg.enabled then
        f:Hide()
        self.low = nil
        return
    end
    -- Hidden with the icons on a flight path or a mount, unless kept on screen.
    if ns.HiddenForTravel() and not cfg.keepOnTravel then
        f:Hide()
        return
    end

    -- Bags unreadable (secret in combat): keep the last known count.
    local count = ns.ItemCount(D.SOUL_SHARD) or self.lastCount or 0
    self.lastCount = count
    -- No Drain Soul yet (low level): no shards to count, so no counter and no "low" alert.
    if not ns.HighestKnown(D.drainSoul) and not ns.db.preview then
        f:Hide()
        self.low = nil
        return
    end
    local threshold = self:Threshold()
    local low = count < threshold

    f.text:SetText(cfg.showThreshold and string.format("%d/%d", count, threshold) or tostring(count))
    -- Exactly at the threshold (one shard more used and it's low): text and highlight in their own color.
    local edge = not low and threshold > 0 and count == threshold
    local c = low and cfg.lowColor or edge and cfg.edgeColor or cfg.color
    f.text:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    f.glow:SetGlow((low or edge) and cfg.glow and cfg.showIcon, edge and cfg.edgeGlowColor or cfg.glowColor, cfg.iconSize)

    if low and not self.low and ns.ready and cfg.sound then ns.PlaySound(cfg.soundName) end
    self.low = low

    local w = (cfg.showIcon and cfg.iconSize + 4 or 2) + f.text:GetStringWidth() + 4
    local h = math.max(cfg.showIcon and cfg.iconSize or 0, cfg.fontSize + 4)
    f:SetSize(w, h)
    f.bg:SetAlpha(cfg.bgAlpha)
    f:SetAlpha(ns.FrameAlpha())
    f:EnableMouse(not ns.ClickThrough())
    f:Show()
end
