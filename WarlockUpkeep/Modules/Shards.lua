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
    local ws = ns.db.weaponStone
    for _, key in ipairs(D.stoneOrder) do
        local spell = ns.HighestKnown(D.stones[key])
        -- Hardcore realms: trainers teach the Soulstone, but it can't bring anyone back there.
        local skip = key == "soulstone" and ns.Hardcore()
        -- With the Firestone / Spellstone icon on, only the chosen stone of the two is kept.
        if ws.enabled and (key == "firestone" or key == "spellstone") and key ~= ws.stone then skip = true end
        if spell and not skip then parts[#parts + 1] = ns.SpellName(spell) or key end
    end
    if cfg.includeRitual and ns.IsKnown(D.ritualOfSummoning) then
        parts[#parts + 1] = ns.SpellName(D.ritualOfSummoning) or "Ritual of Summoning"
    end
    return #parts + cfg.spare, parts
end

------------------------------------------------------------------------
-- Bags: room for new shards, and deleting the extra ones
------------------------------------------------------------------------
local C = C_Container or {}
local NumSlots = C.GetContainerNumSlots or GetContainerNumSlots
local NumFree = C.GetContainerNumFreeSlots or GetContainerNumFreeSlots
local ItemID = C.GetContainerItemID or GetContainerItemID
local Pickup = C.PickupContainerItem or PickupContainerItem
-- The last bag index: the reagent bag slot comes after the four bag slots, and a Soul Bag can sit there.
local BAGS = (NUM_BAG_SLOTS or 4) + (NUM_REAGENTBAG_SLOTS or 0)

-- Bag family bits a Soul Shard fits in (Soul Bags), besides ordinary bags.
local function ShardFamily()
    local f = (C_Item and C_Item.GetItemFamily) or GetItemFamily
    local ok, fam = pcall(f, D.SOUL_SHARD)
    return ok and type(fam) == "number" and fam or 0
end

-- true when a new shard has a free slot, false when it has none, nil when bags are unreadable.
function M:HasRoom()
    if not NumFree then return nil end
    local fam = ShardFamily()
    for bag = 0, BAGS do
        local ok, free, bagFam = pcall(NumFree, bag)
        if not ok or ns.IsSecret(free) or ns.IsSecret(bagFam) then return nil end
        if free and free > 0 and (not bagFam or bagFam == 0 or bit.band(bagFam, fam) ~= 0) then return true end
    end
    return false
end

-- Shards above the limit, or 0 without a limit.
function M:Extra(count)
    local max = Cfg().maxShards
    if not max or max <= 0 then return 0 end
    return math.max(0, count - max)
end

-- Shard slots: ordinary bags first (last slots first), then Soul Bags.
local function ShardSlots()
    local ordinary, shardBags = {}, {}
    for bag = BAGS, 0, -1 do
        local okFree, _, bagFam = pcall(NumFree, bag)
        local list = (okFree and bagFam and bagFam ~= 0) and shardBags or ordinary
        for slot = NumSlots(bag) or 0, 1, -1 do
            if ItemID(bag, slot) == D.SOUL_SHARD then list[#list + 1] = { bag, slot } end
        end
    end
    return ordinary, shardBags
end

-- Deletes up to `n` shards from `slots`; returns how many went, and true when the game refused a delete.
local function DeleteFrom(slots, n)
    local deleted = 0
    for _, s in ipairs(slots) do
        if deleted >= n then break end
        ClearCursor()
        Pickup(s[1], s[2])
        if CursorHasItem and CursorHasItem() then
            -- Still on the cursor afterwards: the game ignored the call (not a real input). Put it back.
            local ok = pcall(DeleteCursorItem)
            if not ok or (CursorHasItem and CursorHasItem()) then ClearCursor(); return deleted, true end
            deleted = deleted + 1
        end
    end
    ClearCursor()
    return deleted
end

-- "deleted 1 extra Soul Shard." / "deleted 3 extra Soul Shards."; `extra` picks the wording.
local function PrintDeleted(n, extra)
    local L = ns.L
    if n == 1 then
        ns.Print(extra and L["deleted 1 extra Soul Shard."] or L["deleted 1 Soul Shard automatically."])
    else
        ns.Print(extra and L["deleted %d extra Soul Shards."] or L["deleted %d Soul Shards automatically."], n)
    end
end

local function CanDelete()
    return NumSlots and ItemID and Pickup and DeleteCursorItem and not (CursorHasItem and CursorHasItem())
end

-- Deletes `n` shards: from ordinary bags first (Soul Bags keep theirs), from the last slots.
-- Runs from a click (the game lets addons delete items only on a player's action), not in combat.
function M:DeleteExtra(n)
    if n <= 0 or not CanDelete() then return end
    if InCombatLockdown() then ns.Print(ns.L["can't delete Soul Shards in combat."]); return end
    local ordinary, shardBags = ShardSlots()
    local slots = ordinary
    for _, s in ipairs(shardBags) do slots[#slots + 1] = s end
    local deleted = DeleteFrom(slots, n)
    if deleted > 0 then PrintDeleted(deleted, true) end
end

-- Automatic cleanup, one mode at a time. "over": the shards above the maximum, what Shift + click on the counter
-- does. "loose": every shard outside the Soul Bags, ignoring the maximum, and only with a Soul Bag equipped, or
-- no shard would be kept. Returns the slots to delete.
local function Plan()
    local mode = Cfg().autoDelete
    if mode ~= "over" and mode ~= "loose" then return {} end
    local ordinary, soulBags = ShardSlots()
    if mode == "loose" then return #soulBags > 0 and ordinary or {} end
    local del, pool = {}, ordinary
    for _, s in ipairs(soulBags) do pool[#pool + 1] = s end
    for i = 1, M:Extra(#pool) do del[#del + 1] = pool[i] end
    return del
end

-- The game lets addons delete items only on a player's input (a click or a key press). A bag change that
-- leaves shards to delete only marks them pending and shows an invisible full-screen frame that passes clicks
-- and keys through; the next input does the deleting. The game also sends key events no player made (a key
-- already held when the frame appears) and blocks the delete on them, so input right after the frame appears is
-- skipped, and a blocked delete leaves the shards pending for the next input.
local function Run()
    if not M.pending or InCombatLockdown() or not CanDelete() then return end
    if GetTime() - (M.shownAt or 0) < 0.3 then return end
    local del = Plan()
    if #del > 0 then
        local deleted, blocked = DeleteFrom(del, #del)
        if deleted > 0 then PrintDeleted(deleted, false) end
        if blocked then return end -- stays pending: the next real input tries again
    end
    M.pending = false
    M.input:Hide()
end

function M:AutoClean()
    if not ns.active or not M.input or M.pending then return end
    if #Plan() == 0 then return end
    M.pending = true
    M.shownAt = GetTime()
    M.input:Show()
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
        if Cfg().maxShards > 0 then GameTooltip:AddDoubleLine(ns.L["Maximum"], Cfg().maxShards, 1, 1, 1, 0.6, 0.8, 1) end
        if Cfg().fullWarn and M:HasRoom() == false then
            GameTooltip:AddLine(ns.L["Bags are full: a new Soul Shard has nowhere to go."], 1, 0.5, 0)
        end
        local extra = M:Extra(count)
        if extra > 0 then
            GameTooltip:AddLine(string.format(ns.L["Shift + click to delete %d extra Soul Shards."], extra), 0.6, 0.8, 1)
        end
        if ns.modules.reagents then ns.modules.reagents:AddTooltipLines(GameTooltip) end
        if not Cfg().locked then GameTooltip:AddLine(ns.L["Drag to move"], 0.6, 0.6, 0.6) end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", GameTooltip_Hide)
    local input = CreateFrame("Frame", "WarlockUpkeep_ShardsInput", UIParent)
    input:SetAllPoints(UIParent)
    input:SetFrameStrata("BACKGROUND")
    input:EnableMouse(false)
    if input.SetMouseClickEnabled then input:SetMouseClickEnabled(true) end
    if input.SetMouseMotionEnabled then input:SetMouseMotionEnabled(false) end
    if input.SetPassThroughButtons then input:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton") end
    input:SetScript("OnMouseDown", Run)
    input:SetScript("OnMouseUp", Run)
    input:EnableKeyboard(true)
    input:SetPropagateKeyboardInput(true)
    input:SetScript("OnKeyDown", Run)
    -- A click on the 3D world reaches WorldFrame; hook it too in case the frame above doesn't see it.
    if WorldFrame and WorldFrame.HookScript then
        WorldFrame:HookScript("OnMouseDown", Run)
    end
    input:Hide()
    self.input = input
    ns:RegisterEvent("BAG_UPDATE_DELAYED", function() M:AutoClean() end)
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", function() M:AutoClean() end)
    f:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" or self.moving or not IsShiftKeyDown() then return end
        M:DeleteExtra(M:Extra(ns.ItemCount(D.SOUL_SHARD) or 0))
        if GameTooltip:IsOwned(self) then self:GetScript("OnEnter")(self) end
    end)
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
    self:AutoClean() -- also covers a new option choice, login and the end of combat
end

function M:Update()
    local cfg, f = Cfg(), self.frame
    if not cfg.enabled then
        f:Hide()
        self.low = nil
        return
    end
    -- Hidden with the icons on a flight path or a mount, unless kept on screen; resting hides it anyway.
    if ns.HiddenForResting() or (ns.HiddenForTravel() and not cfg.keepOnTravel) then
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
    local over = self:Extra(count) > 0
    local c = low and cfg.lowColor or edge and cfg.edgeColor or over and cfg.overColor or cfg.color
    f.text:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    -- No room in the bags for a new shard (Drain Soul would lose it): its own highlight, above the others.
    local room = self:HasRoom()
    if room == nil then room = self.lastRoom end
    self.lastRoom = room
    local full = cfg.fullWarn and room == false
    local glowColor = full and cfg.fullGlowColor or edge and cfg.edgeGlowColor or cfg.glowColor
    f.glow:SetGlow((full or ((low or edge) and cfg.glow)) and cfg.showIcon, glowColor, cfg.iconSize)

    if low and not self.low and ns.ready and cfg.sound then ns.PlaySound(cfg.soundName) end
    self.low = low
    if full and not self.full and ns.ready and cfg.fullSound then ns.PlaySound(cfg.fullSoundName) end
    self.full = full

    local w = (cfg.showIcon and cfg.iconSize + 4 or 2) + f.text:GetStringWidth() + 4
    local h = math.max(cfg.showIcon and cfg.iconSize or 0, cfg.fontSize + 4)
    f:SetSize(w, h)
    f.bg:SetAlpha(cfg.bgAlpha)
    f:SetAlpha(ns.FrameAlpha())
    f:EnableMouse(not ns.ClickThrough())
    f:Show()
end
