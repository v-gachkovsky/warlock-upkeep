local _, ns = ...
local D = ns.data
local M = ns:NewModule("broker")

-- LibDataBroker feed for display addons (Titan Panel, ElvUI, Bazooka, ChocolateBar...): the Soul Shard count
-- as text, the state in the tooltip, and the same clicks as the minimap button. Only when some addon has
-- loaded LibDataBroker.

local function Clock(sec)
    sec = math.max(0, math.floor(sec))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function Text()
    if not ns.SHARD_ITEMS then return "WarlockUpkeep!" end
    local n = ns.ItemCount(D.SOUL_SHARD)
    local sh = ns.modules.shards
    local low = sh and n and n < sh:Threshold()
    return string.format(low and "|cffff4040%d|r" or "%d", n or 0)
end

local function Tooltip(tt)
    local L = ns.L
    tt:AddLine("|cff9482c9WarlockUpkeep!|r")
    local sh = ns.modules.shards
    if sh then
        tt:AddDoubleLine(L["Soul Shards"], string.format("%d / %d", ns.ItemCount(D.SOUL_SHARD) or 0, (sh:Desired())), 1, 1, 1, 1, 1, 1)
    end
    local ss = ns.modules.soulstone
    local t = ss and ss.GetTracked and ss:GetTracked()
    if t then
        tt:AddDoubleLine(L["Soulstone"], string.format("%s  %s", t.name or "", Clock(t.expires - GetServerTime())), 1, 1, 1, 1, 0.82, 0)
    end
    tt:AddLine(" ")
    tt:AddLine(L["Left click: settings"], 0.8, 0.8, 0.8)
    tt:AddLine(L["Right click: toggle preview"], 0.8, 0.8, 0.8)
    tt:AddLine(L["Shift + right click: simulate combat"], 0.8, 0.8, 0.8)
end

function M:Init()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    if not LDB then return end
    self.obj = LDB:NewDataObject("WarlockUpkeep", {
        type = "data source",
        label = "WarlockUpkeep!",
        icon = ns.SHARD_ITEMS and ns.ItemIcon(D.SOUL_SHARD) or ns.LOGO,
        text = Text(),
        OnClick = function(_, button)
            if button == "RightButton" and IsShiftKeyDown() then
                ns:TogglePreviewCombat()
            elseif button == "RightButton" then
                ns.db.preview = not ns.db.preview
                ns:ApplyAll()
                ns.Print(ns.db.preview and ns.L["preview on."] or ns.L["preview off."])
            else
                ns.ToggleOptions()
            end
        end,
        OnTooltipShow = Tooltip,
    })
end

function M:Update()
    if not self.obj then return end
    local text = Text()
    if self.obj.text ~= text then self.obj.text = text end
end
