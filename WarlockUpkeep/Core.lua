local ADDON, ns = ...
_G.WarlockUpkeep = ns

ns.moduleList = {}
ns.modules = {}
ns.icons = {}
ns.ready = false

local L = ns.L
local L_PREFIX = "|cff9482c9WarlockUpkeep!|r: "
function ns.Print(...) print(L_PREFIX .. string.format(...)) end

------------------------------------------------------------------------
-- Defaults
------------------------------------------------------------------------
local function Icon(x, y, extra)
    local t = {
        enabled = true, locked = false, size = 40,
        point = { "CENTER", "CENTER", x, y },
        glow = true, glowColor = { 1, 0.82, 0, 1 },
        sound = false, soundName = "RAID_WARNING",
    }
    for k, v in pairs(extra or {}) do t[k] = v end
    return t
end

ns.defaults = {
    locale = "enUS", -- language of the addon's texts (see Locale.lua)
    preview = false,
    previewCombat = false, -- show the in-combat look (opacity, highlight, hiding) out of combat
    glowStyle = "proc",
    glowMode = "outline",
    fillAlpha = 0.4,
    moveWith = "right",
    snap = { enabled = true, distance = 10, gap = 2 },
    -- Opacity of all addon frames in / out of combat; click-through in combat.
    combat = { clickThrough = false, alpha = 1, idleAlpha = 1, glow = true, hide = false },
    minimap = { hide = false, locked = false, angle = 215 },
    hideOnTaxi = false, -- hide all icons during a flight path
    hideOnMount = false, -- hide all icons while mounted
    grimoires = { merchant = true, tooltip = true }, -- mark grimoires the demons already know
    customSounds = {}, -- { name = "alarm", path = "Interface\\WarlockUpkeepSounds\\alarm.ogg" }
    armor = Icon(-135, 160),
    healthstone = Icon(-90, 160),
    -- Firestone or Spellstone (Forever, Classic Era, TBC): only one can be on at a time, so one icon for the chosen.
    weaponStone = Icon(-180, 160, {
        stone = "firestone",
        remindOverOther = false, -- Forever: remind while another temporary enchant (an oil) is on the weapon
        states = {
            use    = { glow = true, glowColor = { 1, 0.82, 0, 1 }, sound = false, soundName = "READY_CHECK" },
            create = { glow = true, glowColor = { 1, 0.1, 0.1, 1 }, sound = false, soundName = "RAID_WARNING" },
        },
    }),
    soulstone = Icon(-45, 160, {
        createWhileApplied = false,
        hideWhenOthers = false, -- no icon while another warlock's Soulstone is on you
        states = {
            use    = { glow = true, glowColor = { 1, 0.82, 0, 1 }, sound = false, soundName = "READY_CHECK" },
            create = { glow = true, glowColor = { 1, 0.1, 0.1, 1 }, sound = false, soundName = "RAID_WARNING" },
        },
    }),
    pet = Icon(0, 160, {
        -- "none" = plain click; other keys are modifier prefixes. Value "default" = same as plain click.
        bindings = { none = "imp", shift = "voidwalker", ctrl = "succubus", alt = "felhunter", meta = "default" },
        -- With the demon out: remind to sacrifice it (Demonic Sacrifice) or to cast Soul Link, once learned.
        sacrifice = false, soulLink = true,
        states = {
            sacrifice = { glow = true, glowColor = { 0.7, 0.3, 1, 1 }, sound = false, soundName = "RAID_WARNING" },
            soulLink  = { glow = true, glowColor = { 0.7, 0.3, 1, 1 }, sound = false, soundName = "RAID_WARNING" },
        },
    }),
    -- Enslave Demon timer label.
    enslave = {
        enabled = true, locked = false,
        point = { "CENTER", "CENTER", 0, 120 },
        font = "Fonts\\FRIZQT__.TTF", outline = "OUTLINE", size = 14, bgAlpha = 0.3,
        -- Timer zones by seconds left, as on the Soulstone label; `crit` wins where they overlap.
        color = { 1, 1, 1, 1 },
        zones = {
            warn = { enabled = true, seconds = 60, color = { 1, 0.82, 0, 1 }, sound = false, soundName = "RAID_WARNING" },
            crit = { enabled = true, seconds = 30, color = { 1, 0.2, 0.2, 1 }, sound = false, soundName = "RAID_WARNING" },
        },
        expired = { sound = false, soundName = "RAID_WARNING" },
        previewSpeed = 30, -- preview timer: seconds per real second (5 minutes in 10 seconds)
    },
    soulstoneLabel = {
        enabled = true, locked = false,
        point = { "CENTER", "CENTER", -45, 120 },
        font = "Fonts\\FRIZQT__.TTF", outline = "OUTLINE",
        nameSize = 14, timerSize = 12,
        showIcon = true, bgAlpha = 0.3, showSelf = true,
        -- Timer zones by seconds left; `crit` wins where they overlap. Sounds play when a zone starts.
        timerColor = { 1, 1, 1, 1 },
        zones = {
            warn = { enabled = true, seconds = 300, color = { 1, 0.82, 0, 1 }, sound = false, soundName = "RAID_WARNING" },
            crit = { enabled = true, seconds = 60, color = { 1, 0.2, 0.2, 1 }, sound = false, soundName = "RAID_WARNING" },
        },
        expired = { sound = false, soundName = "RAID_WARNING" },
        previewSpeed = 300, -- preview timer: Soulstone seconds per real second
    },
    shards = {
        enabled = true, locked = false,
        point = { "CENTER", "CENTER", 60, 160 },
        showIcon = true, iconSize = 32, bgAlpha = 0.3,
        font = "Fonts\\FRIZQT__.TTF", fontSize = 20, outline = "OUTLINE",
        color = { 1, 1, 1, 1 }, lowColor = { 1, 0.25, 0.25, 1 }, edgeColor = { 1, 0.82, 0, 1 },
        showThreshold = false, -- "have/threshold" instead of just "have"
        keepOnTravel = true, -- stays on screen when hideOnTaxi / hideOnMount hide the rest
        autoThreshold = true, threshold = 3,
        spare = 1, includeRitual = false,
        glow = true, glowColor = { 1, 0.2, 0.2, 1 }, edgeGlowColor = { 1, 0.82, 0, 1 },
        sound = false, soundName = "RAID_WARNING",
    },
}

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function ns:ResetDB()
    local locale = WarlockUpkeepDB.locale -- the language survives a reset
    wipe(WarlockUpkeepDB)
    CopyDefaults(self.defaults, WarlockUpkeepDB)
    WarlockUpkeepDB.locale = locale
    self:ApplyAll()
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local unitEventFrame = CreateFrame("Frame")
local handlers = {}
ns.eventStatus = {} -- event -> how it got registered, or why it failed (shown by /wu auras)

local function OnEvent(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        xpcall(list[i], geterrorhandler(), event, ...)
    end
end

-- UNIT_AURA arrives on this client only per unit (as the game's own frames register it), and
-- RegisterUnitEvent takes two units per frame. Raid members aren't covered: modules poll those.
local AURA_UNITS = { { "player", "target" }, { "focus", "pet" }, { "party1", "party2" }, { "party3", "party4" } }

local function RegisterUnitAuraEvent()
    local any, errors = false, {}
    for _, pair in ipairs(AURA_UNITS) do
        local f = CreateFrame("Frame")
        local ok, err = pcall(f.RegisterUnitEvent, f, "UNIT_AURA", pair[1], pair[2])
        if ok then
            f:SetScript("OnEvent", OnEvent)
            any = true
        else
            errors[#errors + 1] = tostring(err)
        end
    end
    ns.eventStatus.UNIT_AURA = any and "RegisterUnitEvent (player, target, focus, pet, party1-4)"
        or ("FAILED: " .. table.concat(errors, "; "))
    return any
end

function ns:RegisterEvent(event, fn)
    if not handlers[event] and event == "UNIT_AURA" then
        if not RegisterUnitAuraEvent() then return false end
        handlers[event] = {}
    end
    if not handlers[event] then
        -- Unknown events throw on the Forever client, so register defensively. A unit event
        -- refused for all units may still be allowed for the player and the target.
        local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, event)
        if ok then
            ns.eventStatus[event] = "RegisterEvent"
        elseif event:match("^UNIT_") and unitEventFrame.RegisterUnitEvent
            and pcall(unitEventFrame.RegisterUnitEvent, unitEventFrame, event, "player", "target") then
            ns.eventStatus[event] = "RegisterUnitEvent(player, target); RegisterEvent: " .. tostring(err)
        else
            ns.eventStatus[event] = "FAILED: " .. tostring(err)
            return false
        end
        handlers[event] = {}
    end
    table.insert(handlers[event], fn)
    return true
end

eventFrame:SetScript("OnEvent", OnEvent)
unitEventFrame:SetScript("OnEvent", OnEvent)

------------------------------------------------------------------------
-- Modules
------------------------------------------------------------------------
function ns:NewModule(name)
    local m = { name = name }
    self.modules[name] = m
    table.insert(self.moduleList, m)
    return m
end

-- Timeline for /wu auras: what happened when (ms precision), to find where reactions lag.
ns.trace = {}
function ns.Trace(fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    table.insert(ns.trace, 1, { t = GetTime(), msg = ok and msg or fmt })
    ns.trace[25] = nil
end

-- UpdateAll on the next frame, coalescing bursts of triggers (buff frame, Cooldown Manager).
local updatePending
function ns:ScheduleUpdate()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0, function() updatePending = false; ns:UpdateAll() end)
end

function ns:UpdateAll()
    if not self.active then return end
    for _, m in ipairs(self.moduleList) do
        if m.Update then xpcall(m.Update, geterrorhandler(), m) end
    end
end

-- Re-apply settings (sizes, fonts, positions) and refresh state.
function ns:ApplyAll()
    if not self.active then return end
    for _, m in ipairs(self.moduleList) do
        if m.ApplySettings then xpcall(m.ApplySettings, geterrorhandler(), m) end
    end
    self:UpdateAll()
end

function ns:TogglePreviewCombat()
    self.db.previewCombat = not self.db.previewCombat
    self:ApplyAll()
    self.Print(self.db.previewCombat and L["simulated combat look on."] or L["simulated combat look off."])
end

function ns:SetAllLocked(locked)
    for _, key in ipairs({ "armor", "healthstone", "weaponStone", "soulstone", "pet", "soulstoneLabel", "shards", "enslave", "minimap" }) do
        self.db[key].locked = locked
    end
    self:ApplyAll()
end

local TOC = select(4, GetBuildInfo())
-- Classic Era, Forever and TBC keep Soul Shards and Soulstones as bag items. From Cataclysm on
-- (Mists, Retail) shards are a resource with its own game UI, so there's no shard counter,
-- and the Soulstone is cast directly on the target.
ns.SHARD_ITEMS = TOC < 40000
-- Demon Skin / Demon Armor / Fel Armor were removed in Mists.
ns.HAS_ARMOR = TOC < 50000
-- Forever (1.6x) and Retail hide auras from addons in combat; there the Cooldown Manager tells
-- when a tracked buff changes. Classic Era, TBC and Mists read auras in combat as usual.
ns.FOREVER = TOC >= 16000 and TOC < 20000
ns.SECRET_AURAS = ns.FOREVER or TOC >= 120000
-- Hardcore realms (Classic Era, Anniversary, Forever): nobody can be brought back to life there, so the
-- Soulstone is no use, although trainers still teach it. Clients without the function have no such realms.
function ns.Hardcore()
    return C_GameRules and C_GameRules.IsHardcoreActive and ns.Bool(C_GameRules.IsHardcoreActive) or false
end

------------------------------------------------------------------------
-- Helpers: spells, items, auras, secrets
------------------------------------------------------------------------
function ns.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) or false
end

function ns.IsKnown(id)
    if not id then return false end
    if IsPlayerSpell then
        local ok, r = pcall(IsPlayerSpell, id)
        if ok and r then return true end
    end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, r = pcall(C_SpellBook.IsSpellKnown, id)
        if ok and r then return true end
    end
    if IsSpellKnown then
        local ok, r = pcall(IsSpellKnown, id)
        if ok and r then return true end
    end
    return false
end

function ns.SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
end

function ns.SpellTexture(id)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
    if GetSpellTexture then return GetSpellTexture(id) end
end

function ns.ItemIcon(id)
    if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
    if GetItemIcon then return GetItemIcon(id) end
end

-- Bag count, or nil when unreadable (secret in combat): callers keep their last known state.
function ns.ItemCount(id)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    local ok, n = pcall(f, id)
    if ok and type(n) == "number" and not ns.IsSecret(n) then return n end
end

-- true / false from fn(...), or nil when it fails or returns a secret value.
function ns.Bool(fn, ...)
    local ok, v = pcall(fn, ...)
    if not ok or ns.IsSecret(v) then return nil end
    return v and true or false
end

-- Highest known spell from a rank list (ids or {spell=id} entries).
-- Falls back to a lookup by localized name in case Forever uses different IDs.
local knownCache = {}
function ns.HighestKnown(list)
    local cached = knownCache[list]
    if cached ~= nil then
        if cached == false then return nil end
        return cached[1], cached[2]
    end
    local function idAt(i) local e = list[i]; return type(e) == "table" and e.spell or e end
    local function nameAt(i) local e = list[i]; return ns.SpellName(idAt(i)) or (type(e) == "table" and e.name) end
    for i = #list, 1, -1 do
        if ns.IsKnown(idAt(i)) then
            knownCache[list] = { idAt(i), i }
            return idAt(i), i
        end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        for i = #list, 1, -1 do
            local name = nameAt(i)
            local ok, info = pcall(C_Spell.GetSpellInfo, name or "")
            if ok and info and info.spellID and ns.IsKnown(info.spellID) then
                knownCache[list] = { info.spellID, i }
                return info.spellID, i
            end
        end
    end
    knownCache[list] = false
end

function ns.ResetKnownCache() wipe(knownCache) end

-- Spell ID of a learned demon summon (see ns.data.demons), or nil.
function ns.DemonSpell(demon)
    if not demon then return nil end
    demon.list = demon.list or { demon }
    return (ns.HighestKnown(demon.list))
end

-- The player's aura from `ids` (AuraData), false if there is none, or nil when auras are
-- unreadable: secret auras read as "not found" instead of failing, so in combat that's unknown.
function ns.PlayerAura(ids)
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
        -- Older Classic clients: the plain buff list.
        if not UnitBuff then return nil end
        local want = {}
        for _, id in ipairs(ids) do want[id] = true end
        for i = 1, 40 do
            local name, icon, _, _, _, expirationTime, _, _, _, spellId = UnitBuff("player", i)
            if not name then break end
            if want[spellId] then return { expirationTime = expirationTime, icon = icon } end
        end
        return false
    end
    local unknown = false
    for _, id in ipairs(ids) do
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
        if not ok or ns.IsSecret(aura) then unknown = true elseif aura then return aura end
    end
    if C_UnitAuras.GetAuraDataBySpellName then
        for _, id in ipairs(ids) do
            local name = ns.SpellName(id)
            if name then
                local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", name, "HELPFUL")
                if not ok or ns.IsSecret(aura) then unknown = true elseif aura then return aura end
            end
        end
    end
    if unknown or ns.AurasSecret() then return nil end
    return false
end

-- true / false, or nil when auras are unreadable (secret in combat).
function ns.PlayerHasAura(ids)
    local aura = ns.PlayerAura(ids)
    if aura == nil then return nil end
    return aura ~= false
end

-- Follows a player buff through combat, where its aura is secret: out of combat it remembers
-- the aura instance (to find the buff in the buff frame) and its end time.
-- In combat the aura API is closed to addons, but the game's buff frame keeps a readable list
-- of the player's buffs (instance ID, icon, expiration). Returns that list, or nil.
local function BuffFrameAuras()
    local list = BuffFrame and BuffFrame.auraInfo
    if type(list) ~= "table" or ns.IsSecret(list) then return nil end
    return list
end

local BuffTracker = {}
local CAST_WINDOW = 1 -- seconds between our cast and its aura showing up, in either order
local CAST_GRACE = 2  -- after our cast, the buff frame may not list the new aura yet

local function Plain(v)
    if v ~= nil and not ns.IsSecret(v) then return v end
end

-- Takes aura instance `id` as the buff.
function BuffTracker:Claim(id, expires)
    self.has, self.instance, self.castAt, self.prevInstance = true, id, nil, nil
    if expires then self.expires = expires end
end

-- The buff was just cast. In combat its new aura can't be read by spell, so it's timed
-- by `duration` until the buff frame or an aura update shows its new instance.
function BuffTracker:Cast()
    self.has = true
    self.prevInstance, self.instance = self.instance, nil
    self.expires = self.duration and GetTime() + self.duration or nil
    self.castAt = GetTime()
    self.viewerSawCast = false
    -- The cast event comes before the buff frame lists the new aura: remember the count of buffs
    -- now, so a later entry shows the aura has arrived (see FindInBuffFrame).
    local list = BuffFrameAuras()
    self.castCount = list and #list or nil
    ns.Trace("%s: cast", self.name or "buff")
end

-- UNIT_AURA update info for the player: catches the buff's removal and, in combat, its new instance.
function BuffTracker:OnAuraUpdate(info)
    self.lastInfo = { at = GetTime(), info = info } -- for /wu auras
    if type(info) ~= "table" or ns.IsSecret(info) then return end
    local now = GetTime()
    local justCast = self.castAt and now - self.castAt <= CAST_WINDOW
    for _, id in ipairs(Plain(info.removedAuraInstanceIDs) or {}) do
        if Plain(id) and id == self.instance then self.has, self.instance, self.expires = false, nil, nil end
    end
    for _, id in ipairs(Plain(info.updatedAuraInstanceIDs) or {}) do
        -- Recast while up: the same instance is refreshed.
        if justCast and Plain(id) and id == self.prevInstance then self:Claim(id) end
    end
    for _, a in ipairs(Plain(info.addedAuras) or {}) do
        local id = not ns.IsSecret(a) and Plain(a.auraInstanceID)
        if id then
            local spell, exp = Plain(a.spellId), Plain(a.expirationTime)
            exp = exp and exp > 0 and exp or nil
            -- Only a readable spell ID counts: other buffs (food, other players) must never be taken for ours.
            if spell and self.isID[spell] then self:Claim(id, exp) end
        end
    end
end

-- true / false, or nil while the state has never been readable.
-- The buff in the game's buff frame list, matched by its remembered instance or by the icon of
-- one of its spells (a buff cast in combat has a new instance); other buffs (food, other players'
-- buffs) never match. false if it's not there, nil if unreadable or the list may be cut short.
-- Icons of the buff's spells, to recognize it in the buff frame. Secret values (in combat)
-- can't be table keys, so only readable ones are added; the aura's own icon comes from Read().
function BuffTracker:AddSpellIcons()
    if self.spellIconsAdded then return end
    local complete = true
    for _, id in ipairs(self.ids) do
        local ok, tex = pcall(ns.SpellTexture, id)
        if ok and Plain(tex) then self.icons[tex] = true elseif not ok or ns.IsSecret(tex) then complete = false end
    end
    self.spellIconsAdded = complete
end

function BuffTracker:FindInBuffFrame()
    local list = BuffFrameAuras()
    if not list then return nil end
    self:AddSpellIcons()
    -- Auras applied in combat may carry a secret icon: such an entry could be ours or anyone's.
    local unidentified = false
    for _, a in ipairs(list) do
        if type(a) ~= "table" or ns.IsSecret(a) then
            unidentified = true
        elseif a.auraType ~= "Buff" then
            -- weapon enchants
        else
            local id, tex = Plain(a.auraInstanceID), Plain(a.texture)
            if (id and id == self.instance) or (tex and self.icons[tex]) then return a end
            if not tex then unidentified = true end
        end
    end
    -- A full list may have left our buff out: unknown rather than missing.
    local max = Plain(BuffFrame.maxAuras)
    if max and #list >= max then return nil end
    -- Our known instance is gone: removed. But only if every entry is readable: in combat the game
    -- re-reads all buffs on any change, its entries turn secret and ours may be among them.
    if self.instance and not unidentified then return false end
    -- Just cast: wait until the buff frame lists the new aura (one more entry than at the cast);
    -- after that, its disappearance counts at once.
    if self.castAt and self.castCount and GetTime() - self.castAt < CAST_GRACE then
        if #list > self.castCount then self.castCount = nil else return nil end
    end
    -- Recast in combat: an unidentified entry may be the new one, so keep the state the cast set.
    if unidentified then return nil end
    return false
end

-- Blizzard's Cooldown Manager: its tracked-buff items name their spell and whether the buff is
-- active, readable in combat. Only buffs the player added to the Cooldown Manager have an item.
local VIEWERS = { "BuffIconCooldownViewer", "BuffBarCooldownViewer" }
local VIEWER_SPELL_FIELDS = { "spellID", "overrideSpellID", "overrideTooltipSpellID", "linkedSpellID" }
local hookedViewerItems = {}

function BuffTracker:ViewerItemMatches(info)
    if type(info) ~= "table" or ns.IsSecret(info) then return false end
    for _, field in ipairs(VIEWER_SPELL_FIELDS) do
        local id = Plain(info[field])
        if id and self.isID[id] then return true end
    end
    local linked = Plain(info.linkedSpellIDs)
    if type(linked) == "table" then
        for _, id in ipairs(linked) do
            if Plain(id) and self.isID[id] then return true end
        end
    end
    return false
end

-- true / false from the Cooldown Manager, or nil when it doesn't track the buff.
function BuffTracker:FindInCooldownViewer()
    local state
    for _, name in ipairs(VIEWERS) do
        local pool = type(_G[name]) == "table" and _G[name].itemFramePool
        if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
            for item in pool:EnumerateActive() do
                if not hookedViewerItems[item] and type(item.OnActiveStateChanged) == "function" then
                    hookedViewerItems[item] = true
                    hooksecurefunc(item, "OnActiveStateChanged", function() ns.Trace("CDM item active changed"); ns:ScheduleUpdate() end)
                end
                if item.cooldownID and self:ViewerItemMatches(item.cooldownInfo) then
                    local active = item.isActive
                    if not ns.IsSecret(active) and type(active) == "boolean" then
                        if active then return true end
                        state = false
                    end
                end
            end
        end
    end
    return state
end

-- Read() with the source of the answer traced when the state changes.
function BuffTracker:Read()
    local before = self.has
    self.src = "kept"
    local has = self:ReadState()
    if has ~= before then
        ns.Trace("%s: %s -> %s via %s", self.name or "buff", tostring(before), tostring(has), self.src)
    end
    return has
end

function BuffTracker:ReadState()
    local aura = ns.PlayerAura(self.ids)
    if aura ~= nil then self.src = "aura API" end
    if aura == nil then
        aura = self:FindInBuffFrame()
        if aura ~= nil then self.src = "buff frame" end
    end
    if aura == nil then
        -- The buff frame can't tell (a buff cast in combat has a hidden entry): the Cooldown Manager
        -- knows it by spell. It updates a moment after the buff frame, so it comes second, and right
        -- after our cast its stale "inactive" is ignored.
        local ok, active = pcall(self.FindInCooldownViewer, self)
        -- Right after our cast it may still say "inactive" until it picks the new aura up; once it
        -- has shown it active, "inactive" is a real removal and applies at once.
        if ok and active == false and self.castAt and not self.viewerSawCast
            and GetTime() - self.castAt < CAST_GRACE then
            active = nil
        end
        if ok and active ~= nil then
            self.src = "cooldown manager"
            if active then
                self.has, self.prevInstance, self.viewerSawCast = true, nil, true
            else
                self.has, self.instance, self.expires, self.castAt = false, nil, nil, nil
            end
            return self.has
        end
    end
    if aura then
        self.has, self.castAt, self.prevInstance = true, nil, nil
        local id, exp, tex = aura.auraInstanceID, aura.expirationTime, aura.icon or aura.texture
        self.instance = Plain(id)
        exp = Plain(exp)
        self.expires = exp and exp > 0 and exp or nil
        if Plain(tex) then self.icons[tex] = true end
    elseif aura == false then
        self.has, self.instance, self.expires = false, nil, nil
    elseif self.has and self.expires and GetTime() >= self.expires then
        -- A hidden aura can't be looked up by its instance either (Forever refuses, Retail may report
        -- a present one as missing), so only the end time tells that the buff is gone.
        self.has = false
        self.src = "end time"
    end
    return self.has
end

-- ids: spell IDs of the buff; duration: seconds, used when it's cast in combat.
function ns.NewBuffTracker(ids, duration, name)
    local isID = {}
    for _, id in ipairs(ids) do isID[id] = true end
    return Mixin({ ids = ids, isID = isID, duration = duration, icons = {}, name = name }, BuffTracker)
end

-- Only clients with secret values (Forever, Retail) hide auras in combat; Classic clients read
-- them in combat as usual, so a missing buff there is really missing.
function ns.AurasSecret()
    if not (C_Secrets and C_Secrets.ShouldAurasBeSecret) then return false end
    local ok, s = pcall(C_Secrets.ShouldAurasBeSecret)
    if not ok then return InCombatLockdown() end
    return s and true or false
end

------------------------------------------------------------------------
-- Boot
------------------------------------------------------------------------
ns:RegisterEvent("ADDON_LOADED", function(_, name)
    if name ~= ADDON then return end
    WarlockUpkeepDB = WarlockUpkeepDB or {}
    WarlockUpkeepCharDB = WarlockUpkeepCharDB or {}
    CopyDefaults(ns.defaults, WarlockUpkeepDB)
    ns.db = WarlockUpkeepDB
    ns.cdb = WarlockUpkeepCharDB
end)

ns:RegisterEvent("PLAYER_LOGIN", function()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then
        -- Not a Warlock: nothing is created, everything stays disabled.
        ns.active = false
        return
    end
    ns.active = true
    for _, m in ipairs(ns.moduleList) do
        if m.Init then xpcall(m.Init, geterrorhandler(), m) end
    end
    if ns.InitOptions then ns.InitOptions() end
    ns:ApplyAll()
    C_Timer.NewTicker(1, function() ns:UpdateAll() end)
    -- The game's buff frame updates on every player aura change, also in combat when addons
    -- get no aura data: refresh right after it.
    if BuffFrame and BuffFrame.UpdateAuras then
        hooksecurefunc(BuffFrame, "UpdateAuras", function() ns.Trace("BuffFrame updated"); ns:ScheduleUpdate() end)
    end
    ns:RegisterEvent("UNIT_AURA", function(_, unit)
        if ns.IsSecret(unit) or unit ~= "player" then return end
        ns.Trace("UNIT_AURA player")
        ns:ScheduleUpdate()
    end)
end)

ns:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    if not ns.active then return end
    ns.ResetKnownCache()
    ns:UpdateAll()
    -- Don't fire alert sounds for the state found right after loading.
    C_Timer.After(3, function() ns.ready = true end)
end)

ns:RegisterEvent("SPELLS_CHANGED", function()
    if not ns.active then return end
    ns.ResetKnownCache()
    ns:UpdateAll()
end)

ns:RegisterEvent("BAG_UPDATE_DELAYED", function() ns:UpdateAll() end)

-- Fires right before combat lockdown: last chance to show protected icons so
-- they can still appear (via alpha) during combat.
ns:RegisterEvent("PLAYER_REGEN_DISABLED", function()
    ns.inCombat = true
    ns:UpdateAll()
    for _, b in ipairs(ns.icons) do b:PrepareForCombat() end
end)

ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    ns.inCombat = false
    ns:ApplyAll()
end)

-- Taking off and landing on a flight path.
ns:RegisterEvent("PLAYER_CONTROL_LOST", function() ns:ScheduleUpdate() end)
ns:RegisterEvent("PLAYER_CONTROL_GAINED", function() ns:ScheduleUpdate() end)

function ns.OnTaxi()
    return UnitOnTaxi and ns.Bool(UnitOnTaxi, "player") or false
end

-- Getting on and off a mount.
ns:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", function() ns:ScheduleUpdate() end)

function ns.Mounted()
    return IsMounted and ns.Bool(IsMounted) or false
end

-- Everything (icons, Soulstone label, shard counter unless kept) is hidden on a flight path or a mount
-- by the options. A flight path follows its own option, also where it counts as being mounted.
function ns.HiddenForTravel()
    if ns.OnTaxi() then return ns.db.hideOnTaxi end
    return ns.db.hideOnMount and ns.Mounted()
end

-- Dying, releasing the spirit and coming back to life.
ns:RegisterEvent("PLAYER_DEAD", function() ns:ScheduleUpdate() end)
ns:RegisterEvent("PLAYER_ALIVE", function() ns:ScheduleUpdate() end)
ns:RegisterEvent("PLAYER_UNGHOST", function() ns:ScheduleUpdate() end)

function ns.IsDead()
    return ns.Bool(UnitIsDeadOrGhost, "player") or false
end

-- Lowest opacity allowed in combat: an (almost) invisible icon would still catch clicks.
ns.MIN_COMBAT_ALPHA = 0.2

-- Real combat, or the "simulate combat" preview (looks and click-through).
function ns.CombatLook()
    return ns.inCombat or (ns.db and ns.db.previewCombat) or false
end

-- Opacity for addon frames in the current combat state.
function ns.FrameAlpha()
    local c = ns.db.combat
    if ns.CombatLook() then return math.max(c.alpha, ns.MIN_COMBAT_ALPHA) end
    return c.idleAlpha
end

-- Whether addon frames should ignore the mouse right now.
function ns.ClickThrough()
    return ns.CombatLook() and ns.db.combat.clickThrough
end

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
SLASH_WARLOCKUPKEEP1 = "/wu"
SLASH_WARLOCKUPKEEP2 = "/warlockupkeep"
SlashCmdList.WARLOCKUPKEEP = function(msg)
    if not ns.active then
        ns.Print(L["disabled: this character is not a Warlock."])
        return
    end
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "lock" then
        ns:SetAllLocked(true); ns.Print(L["all frames locked."])
    elseif msg == "unlock" then
        ns:SetAllLocked(false); ns.Print(L["all frames unlocked (%s icons to move)."], ns.MoveModeText():lower())
    elseif msg == "preview" then
        ns.db.preview = not ns.db.preview; ns:ApplyAll()
        ns.Print(ns.db.preview and L["preview on."] or L["preview off."])
    elseif msg == "combat" then
        ns:TogglePreviewCombat()
    elseif msg == "auras" then
        if ns.DebugAuras then
            local ok, err = pcall(ns.DebugAuras)
            if not ok then ns.Print("auras debug failed: %s", tostring(err)) end
        end
    elseif msg == "grimoires" and ns.DebugGrimoires then
        ns.DebugGrimoires()
    elseif msg == "reset" then
        if InCombatLockdown() then ns.Print(L["cannot reset in combat."]); return end
        ns:ResetDB(); ns.Print(L["settings reset."])
    else
        ns.ToggleOptions()
    end
end
