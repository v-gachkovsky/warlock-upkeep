local _, ns = ...
-- Enslave Demon (Subjugate Demon in Classic Era) exists only before Cataclysm.
if not ns.SHARD_ITEMS then return end
local D = ns.data
local M = ns:NewModule("enslave")

-- Timer of the enslaved demon: up to 5 minutes, then (or earlier, at random) it turns on you.

local function Cfg() return ns.db.enslave end
local isEnslave = {}
for _, id in ipairs(D.enslaveDemon) do isEnslave[id] = true end

-- Expiration (GetTime) of the Enslave debuff on your pet, false without one, nil when unreadable.
local function PetDebuff()
    if not ns.Bool(UnitExists, "pet") then return false end
    local name = ns.SpellName(D.enslaveDemon[1])
    if not name then return nil end
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, "pet", name, "HARMFUL")
        if not ok or ns.IsSecret(a) then return nil end
        if not a then return ns.AurasSecret() and nil or false end
        local exp = a.expirationTime
        if ns.IsSecret(exp) then return nil end
        return exp and exp > 0 and exp or nil
    end
    if not UnitDebuff then return nil end
    for i = 1, 40 do
        local n, _, _, _, _, exp = UnitDebuff("pet", i)
        if not n then break end
        if n == name then return exp and exp > 0 and exp or nil end
    end
    return false
end

function M:Init()
    local f = CreateFrame("Frame", "WarlockUpkeep_Enslave", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetSize(120, 22)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 1)
    f.icon = f:CreateTexture(nil, "OVERLAY")
    f.icon:SetPoint("LEFT", 3, 0)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.icon:SetTexture(ns.SpellTexture(D.enslaveDemon[1]) or ns.QUESTION_ICON)
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
    ns.MakeMovable(f, Cfg)
    f:SetScript("OnUpdate", function(self, dt)
        self.elapsed = (self.elapsed or 0) + dt
        if self.elapsed < 0.2 then return end
        self.elapsed = 0
        M:Tick()
    end)
    f:Hide()
    self.frame = f

    ns:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
        if unit ~= "player" or ns.IsSecret(spellID) or not isEnslave[spellID] then return end
        -- The debuff may not be readable yet (or at all in combat): time it from the cast.
        M.expires = GetTime() + D.enslaveDuration
        M.warned = nil
        M:Update()
    end)
    ns:RegisterEvent("UNIT_PET", function(_, unit) if unit == "player" then M:Update() end end)
end

function M:ApplySettings()
    local cfg, f = Cfg(), self.frame
    ns.ApplyFont(f.text, cfg.font, cfg.size, cfg.outline)
    f.icon:SetSize(cfg.size + 2, cfg.size + 2)
    ns.ApplyPoint(f, cfg.point)
end

function M:Update()
    local cfg = Cfg()
    local exp = PetDebuff()
    if exp then
        if not self.expires or math.abs(exp - self.expires) > 1 then self.warned = nil end
        self.expires = exp
    elseif exp == false then
        self.expires = nil
    end
    if self.expires and GetTime() >= self.expires then self.expires = nil end
    local preview = ns.db.preview and not self.expires
    if not cfg.enabled or not (self.expires or preview) or ns.HiddenForTravel() then
        self.frame:Hide()
        return
    end
    self.preview = preview
    self:Tick()
    self.frame:Show()
end

function M:Tick()
    local cfg, f = Cfg(), self.frame
    local remain = self.preview and D.enslaveDuration or ((self.expires or 0) - GetTime())
    if remain <= 0 then f:Hide(); self.expires = nil; return end
    local warn = remain <= cfg.warnSeconds
    if warn and not self.warned and not self.preview then
        self.warned = true
        if ns.ready and cfg.sound then ns.PlaySound(cfg.soundName) end
    end
    local c = warn and cfg.warnColor or cfg.color
    f.text:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    f.text:SetFormattedText("%d:%02d", math.floor(remain / 60), math.floor(remain % 60))
    f:SetSize(cfg.size + 2 + f.text:GetStringWidth() + 12, cfg.size + 8)
    f.bg:SetAlpha(cfg.bgAlpha)
    f:SetAlpha(ns.FrameAlpha())
    f:EnableMouse(not cfg.locked and not ns.ClickThrough())
end
