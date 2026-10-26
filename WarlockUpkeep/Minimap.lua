local _, ns = ...
local M = ns:NewModule("minimap")
local L = ns.L

local function Cfg() return ns.db.minimap end

local function UpdatePosition(b)
    local angle = math.rad(Cfg().angle)
    local r = Minimap:GetWidth() / 2 + 10
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function OnDragUpdate(b)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    Cfg().angle = math.deg(math.atan2(py / scale - my, px / scale - mx)) % 360
    UpdatePosition(b)
end

function M:Init()
    local b = CreateFrame("Button", "WarlockUpkeep_MinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(24, 24)
    bg:SetPoint("CENTER")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexture(ns.LOGO)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    b:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" and IsShiftKeyDown() then
            ns:TogglePreviewCombat()
        elseif mouse == "RightButton" then
            ns.db.preview = not ns.db.preview
            ns:ApplyAll()
            ns.Print(ns.db.preview and L["preview on."] or L["preview off."])
        else
            ns.ToggleOptions()
        end
    end)
    b:SetScript("OnDragStart", function(self)
        if Cfg().locked then return end
        self:SetScript("OnUpdate", OnDragUpdate)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff9482c9WarlockUpkeep!|r")
        GameTooltip:AddLine(L["Left click: settings"], 1, 1, 1)
        GameTooltip:AddLine(L["Right click: toggle preview"], 1, 1, 1)
        GameTooltip:AddLine(L["Shift + right click: simulate combat"], 1, 1, 1)
        if ns.db.previewCombat then GameTooltip:AddLine(L["Simulated combat look is ON"], 1, 0.3, 0.3) end
        if not Cfg().locked then GameTooltip:AddLine(L["Drag to move around the minimap"], 0.6, 0.6, 0.6) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    self.button = b
end

function M:ApplySettings()
    UpdatePosition(self.button)
    self.button:SetShown(not Cfg().hide)
end
