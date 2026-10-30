local _, ns = ...
local D = ns.data
local M = ns:NewModule("summonSell")

-- Selling summons: while turned on, players outside the group who look for a summon in public chat
-- ("wtb sum", "lf lock"...) are listed. Click whispers them an offer, Shift + click also invites them;
-- once in the group they go on to the summon queue. Nothing is sent without a click.

local MAX_BUYERS = 20
local ROW_HEIGHT = 18
local HEADER = 50 -- title line, place line and bottom padding
local WIDTH = 300
local BUYER_TIMEOUT = 300 -- seconds a buyer stays listed after their last message
local AD_COOLDOWN = 30

local function Cfg() return ns.db.summonSell end
local function Q() return ns.modules.summon end

local function Safe(v)
    if v == nil or ns.IsSecret(v) or v == "" then return nil end
    return v
end

local function Short(name)
    name = Safe(name)
    if not name then return nil end
    if Ambiguate then return Ambiguate(name, "none") end
    return name
end

------------------------------------------------------------------------
-- Messages
------------------------------------------------------------------------
local function AutoZone() return Safe(GetZoneText and GetZoneText()) or "" end

-- {zone}: the place typed in the window ("BRD meeting stone"), else the zone you're in.
local function Zone() return M.place or AutoZone() end

-- People next to you still needed to click the portal (2 in all).
local function ClickersNeeded()
    local q = Q()
    return math.max(0, 2 - (q and q.Clickers and q.Clickers() or 0))
end

-- Price text to copper: a plain number is gold ("5", "2.5"), otherwise gold, silver and copper in that
-- order, each optional: "1g50s", "75s", "2g 5c". nil when it can't be read.
local UNITS = { { "g", 10000 }, { "s", 100 }, { "c", 1 } }
function M.ParsePrice(text)
    text = tostring(text or ""):lower():gsub("%s+", "")
    if text == "" then return 0 end
    local n = tonumber(text)
    if n then return n >= 0 and math.floor(n * 10000 + 0.5) or nil end
    local total, rest = 0, text
    for _, u in ipairs(UNITS) do
        local num, after = rest:match("^(%d+)" .. u[1] .. "(.*)$")
        if num then
            total = total + tonumber(num) * u[2]
            rest = after
        end
    end
    if rest ~= "" then return nil end
    return total
end

-- Copper to "1g50s" (only the parts that aren't 0).
function M.FormatPrice(copper)
    copper = math.floor(tonumber(copper) or 0)
    if copper <= 0 then return "0" end
    local parts = {}
    for _, u in ipairs(UNITS) do
        local n = math.floor(copper / u[2])
        copper = copper - n * u[2]
        if n > 0 then parts[#parts + 1] = n .. u[1] end
    end
    return table.concat(parts)
end

local function Price()
    local p = tonumber(Cfg().price) or 0
    return p > 0 and M.FormatPrice(p) or nil
end

-- Fills {name}, {zone}, {price} and {clickers}; {clickers} is the clickers sentence, or nothing when two
-- people already stand by.
function M.Fill(template, name)
    local need = ClickersNeeded()
    local clickers = need > 0 and (Cfg().templates.clickers:gsub("{n}", tostring(need))) or ""
    local text = template
        :gsub("{name}", function() return name or "" end)
        :gsub("{zone}", function() return Zone() end)
        :gsub("{price}", function() return Price() or "" end)
        :gsub("{clickers}", function() return clickers end)
    text = text:gsub("%s+", " "):match("^%s*(.-)%s*$")
    return text:sub(1, 255)
end

local function Offer(name)
    local t = Cfg().templates
    return M.Fill(Price() and t.priced or t.ask, name)
end

------------------------------------------------------------------------
-- Buyers
------------------------------------------------------------------------
M.buyers = {} -- { name, class, text, source, at, status }

function M:Find(name)
    for i, b in ipairs(self.buyers) do
        if b.name == name then return i, b end
    end
end

local function InGroup(name)
    local q = Q()
    return q and q.UnitOf and q.UnitOf(name) ~= nil
end

function M:OnMessage(text, sender, source, guid)
    if not Cfg().enabled then return end
    local name = Short(sender)
    if not name or name == Safe(UnitName("player")) or InGroup(name) then return end
    local q = Q()
    if not (q and q.Matches(text, self:Keywords())) then return end
    local _, b = self:Find(name)
    if not b then
        local class
        if guid and GetPlayerInfoByGUID then
            local ok, _, c = pcall(GetPlayerInfoByGUID, guid)
            class = ok and Safe(c) or nil
        end
        b = { name = name, class = class }
        table.insert(self.buyers, 1, b)
        while #self.buyers > MAX_BUYERS do table.remove(self.buyers) end
        if ns.ready and Cfg().sound then ns.PlaySound(Cfg().soundName) end
    end
    b.text, b.source, b.at = text, source, GetTime()
    self:Refresh()
end

local keywordCache, keywordSource
function M:Keywords()
    local src = Cfg().keywords or ""
    if src ~= keywordSource then
        keywordSource, keywordCache = src, {}
        for raw in src:gmatch("[^,]+") do
            local kw = raw:lower():match("^%s*(.-)%s*$")
            if kw ~= "" then keywordCache[#keywordCache + 1] = kw end
        end
    end
    return keywordCache
end

function M:Remove(name)
    local i = self:Find(name)
    if i then table.remove(self.buyers, i); self:Refresh() end
end

-- Buyers who joined the group go on to the summon queue; quiet ones drop off after a while.
function M:Prune()
    local now = GetTime()
    for i = #self.buyers, 1, -1 do
        local b = self.buyers[i]
        if InGroup(b.name) then
            table.remove(self.buyers, i)
            if Q() then Q():Add(b.name) end
        elseif now - b.at > BUYER_TIMEOUT then
            table.remove(self.buyers, i)
        end
    end
end

function M:Whisper(b)
    SendChatMessage(Offer(b.name), "WHISPER", nil, b.name)
    b.status = b.status or "whispered"
end

function M:Invite(b)
    local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
    if invite then pcall(invite, b.name) end
    b.status = "invited"
end

-- An ad in the chosen public channel; the game sends to channels only on a click.
function M:PostAd()
    local now = GetTime()
    if self.lastAd and now - self.lastAd < AD_COOLDOWN then
        ns.Print(ns.L["wait %d s before the next ad."], math.ceil(AD_COOLDOWN - (now - self.lastAd)))
        return
    end
    local channel = Cfg().adChannel
    local id = GetChannelName and GetChannelName(channel)
    if not id or id == 0 then ns.Print(ns.L["you're not in the %s channel."], channel); return end
    SendChatMessage(M.Fill(Cfg().templates.ad), "CHANNEL", nil, id)
    self.lastAd = now
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------
local function ClassColor(class)
    local c = class and (C_ClassColor and C_ClassColor.GetClassColor(class) or RAID_CLASS_COLORS[class])
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function SmallButton(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 18)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local STATUS_TEXT = { whispered = "whispered", invited = "invited" }

local function CreateRow(f, i)
    local r = CreateFrame("Button", nil, f)
    r:SetHeight(ROW_HEIGHT)
    r:SetPoint("TOPLEFT", 4, -46 - (i - 1) * ROW_HEIGHT)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.name:SetPoint("LEFT", 2, 0)
    r.status = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    r.status:SetPoint("RIGHT", -2, 0)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.text:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
    r.text:SetPoint("RIGHT", r.status, "LEFT", -6, 0)
    r.text:SetJustifyH("LEFT")
    r.text:SetWordWrap(false)
    r:SetScript("OnClick", function(self, button)
        local _, b = M:Find(self.buyer)
        if not b then return end
        if button == "RightButton" then M:Remove(b.name); return end
        if IsShiftKeyDown() then M:Invite(b) end
        M:Whisper(b)
        M:Refresh()
    end)
    r:SetScript("OnEnter", function(self)
        local _, b = M:Find(self.buyer)
        if not b then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(b.name, ClassColor(b.class))
        GameTooltip:AddLine(b.text, 1, 1, 1, true)
        GameTooltip:AddLine(string.format("[%s]", b.source or ""), 0.6, 0.6, 0.6)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(Offer(b.name), 0.6, 0.8, 1, true)
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", GameTooltip_Hide)
    r:Hide()
    f.rows[i] = r
    return r
end

function M:CreateWindow()
    local f = CreateFrame("Frame", "WarlockUpkeep_SummonSell", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetSize(WIDTH, 44)
    f:EnableMouse(true)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 1)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 6, -6)
    f.stop = SmallButton(f, "X", 22, function() M:SetSelling(false) end)
    f.stop:SetPoint("TOPRIGHT", -3, -3)
    f.ad = SmallButton(f, "", 70, function() M:PostAd() end)
    f.ad:SetPoint("RIGHT", f.stop, "LEFT", -2, 0)
    f.empty = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.empty:SetPoint("TOPLEFT", 8, -48)

    -- Where you summon to, for {zone}: typed here or the zone you're in. Cleared in another zone.
    f.placeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.placeLabel:SetPoint("TOPLEFT", 8, -30)
    f.place = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    f.place:SetHeight(18)
    f.place:SetPoint("LEFT", f.placeLabel, "RIGHT", 10, 0)
    f.place:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    f.place:SetAutoFocus(false)
    f.place:SetFontObject("GameFontHighlightSmall")
    f.placeHint = f.place:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.placeHint:SetPoint("LEFT", 0, 0)
    f.placeHint:SetPoint("RIGHT", 0, 0)
    f.placeHint:SetJustifyH("LEFT")
    f.placeHint:SetWordWrap(false)
    local function Hint() f.placeHint:SetShown(f.place:GetText() == "" and not f.place:HasFocus()) end
    f.place:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.place:SetScript("OnEscapePressed", function(self)
        self:SetText(M.place or "")
        self:ClearFocus()
    end)
    f.place:SetScript("OnEditFocusGained", Hint)
    f.place:SetScript("OnEditFocusLost", function(self)
        local text = self:GetText():match("^%s*(.-)%s*$")
        M.place = text ~= "" and text or nil
        self:SetText(M.place or "")
        Hint()
    end)
    f.place:SetScript("OnTextChanged", Hint)
    f.place:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.L["Where you summon to"], 1, 1, 1)
        GameTooltip:AddLine(ns.L["Goes into the offer and the ad as {zone}. Empty: the zone you're in. " ..
            "Cleared when you go to another zone."], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    f.place:SetScript("OnLeave", GameTooltip_Hide)
    f.anchor = "TOPLEFT"
    ns.MakeMovable(f, Cfg)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.L["Selling summons"], 0.58, 0.51, 0.79)
        GameTooltip:AddLine(ns.L["Click: whisper the offer. Shift + click: also invite."], 1, 1, 1)
        GameTooltip:AddLine(ns.L["Right click: remove from the list."], 1, 1, 1)
        if not Cfg().locked then
            GameTooltip:AddLine(ns.L["Drag to move"], 0.6, 0.6, 0.6)
            GameTooltip:AddLine(ns.L["Drag the corner to resize"], 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", GameTooltip_Hide)

    f.rows = {}
    f.more = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.more:SetPoint("BOTTOMLEFT", 8, 6)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta)
        M.offset = (M.offset or 0) - delta
        M:Refresh()
    end)
    ns.MakeResizable(f, Cfg, 200, HEADER + ROW_HEIGHT, function() M:Refresh() end)
    f:Hide()
    self.frame = f
end

local SAMPLE = {
    { name = "Thrall", class = "SHAMAN", text = "wtb sum to BRD 5g", source = "Trade" },
    { name = "Jaina", class = "MAGE", text = "LF lock summon ZF", source = "LookingForGroup", status = "whispered" },
    -- More than fit by default, to try the scrolling.
    { name = "Uther", class = "PALADIN", text = "need summ to Strat pls", source = "General", status = "invited" },
    { name = "Sylvanas", class = "HUNTER", text = "wtb summon UBRS", source = "Trade" },
    { name = "Tyrande", class = "PRIEST", text = "any lock for summ? 3g", source = "Trade" },
    { name = "Garrosh", class = "WARRIOR", text = "lfw ST", source = "Say" },
    { name = "Malfurion", class = "DRUID", text = "WTB SUM MARAUDON", source = "Yell" },
    { name = "Valeera", class = "ROGUE", text = "need a summon to Scholo", source = "Whisper" },
    { name = "Rexxar", class = "HUNTER", text = "lf lock Dire Maul", source = "General" },
}

function M:Refresh()
    local f, cfg = self.frame, Cfg()
    if not f then return end
    -- Shown while selling (once Ritual of Summoning is learned), and in preview for positioning.
    local on = cfg.enabled and ns.IsKnown(D.ritualOfSummoning) or ns.db.preview
    if not on or ns.HiddenForTravel() then
        f:Hide()
        return
    end
    local list = self.buyers
    local sample = #list == 0 and ns.db.preview
    if sample then list = SAMPLE end
    f.title:SetText(ns.L["Selling summons"])
    f.ad:SetText(ns.L["Ad"])
    f.ad:SetWidth(math.max(40, f.ad:GetFontString():GetStringWidth() + 20))
    f.empty:SetText(#list == 0 and ns.L["Waiting for buyers..."] or "")
    f.placeLabel:SetText(ns.L["Place:"])
    f.placeHint:SetText(AutoZone())
    if not f.place:HasFocus() then f.place:SetText(M.place or "") end
    if f.sizing then return end
    local offset, visible, scroll = ns.ListSlice(math.max(1, #list), cfg.height, HEADER, ROW_HEIGHT, self.offset)
    self.offset = offset
    for i = 1, math.max(#f.rows, visible) do
        local r = f.rows[i] or CreateRow(f, i)
        local b = i <= visible and list[offset + i]
        if b then
            r.buyer = not sample and b.name or nil
            r.name:SetText(b.name)
            r.name:SetTextColor(ClassColor(b.class))
            r.text:SetText(b.text)
            r.status:SetText(b.status and ("|cff33ff33" .. ns.L[STATUS_TEXT[b.status]] .. "|r") or "")
            r:Show()
        else
            r.buyer = nil
            r:Hide()
        end
    end
    f.more:SetText(scroll and string.format(ns.L["%d-%d of %d, scroll with the mouse wheel"],
        offset + 1, offset + visible, #list) or "")
    f:SetHeight(cfg.height)
    f.grip:SetShown(not cfg.locked)
    -- Wide enough for the title and the buttons in a longer translation.
    local width = math.max(cfg.width, f.title:GetStringWidth() + f.ad:GetWidth() + f.stop:GetWidth() + 24)
    f:SetWidth(width)
    for _, r in ipairs(f.rows) do r:SetWidth(width - 8) end
    f.bg:SetAlpha(ns.db.summon.bgAlpha)
    f:SetAlpha(ns.FrameAlpha())
    f:Show()
end

function M:SetSelling(on)
    Cfg().enabled = on
    if not on then wipe(self.buyers) end
    ns.Print(on and ns.L["selling summons on."] or ns.L["selling summons off."])
    self:Refresh()
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------
function M:Init()
    self:CreateWindow()
    ns:RegisterEvent("CHAT_MSG_CHANNEL", function(_, text, sender, _, _, _, _, _, _, channel, _, _, guid)
        M:OnMessage(text, sender, Safe(channel) or CHANNEL, guid)
    end)
    for event, source in pairs({ CHAT_MSG_SAY = "Say", CHAT_MSG_YELL = "Yell", CHAT_MSG_WHISPER = "Whisper" }) do
        ns:RegisterEvent(event, function(_, text, sender, _, _, _, _, _, _, _, _, _, guid)
            M:OnMessage(text, sender, ns.L[source], guid)
        end)
    end
    ns:RegisterEvent("GROUP_ROSTER_UPDATE", function() M:Prune(); M:Refresh() end)
    ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
        -- Losing focus keeps what's typed, so drop the focus first.
        if M.frame and M.frame.place:HasFocus() then M.frame.place:ClearFocus() end
        M.place = nil
        M:Refresh()
    end)
end

function M:ApplySettings()
    ns.ApplyPoint(self.frame, Cfg().point)
end

function M:Update()
    self:Prune()
    self:Refresh()
end
