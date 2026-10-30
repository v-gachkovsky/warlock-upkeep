local _, ns = ...

-- Profiles: WarlockUpkeepDB.profiles[name] holds a full set of settings; each character picks one
-- (WarlockUpkeepCharDB.profile). Export / import turn a profile into a text string and back.

local DEFAULT = "Default"

local function Profiles() return WarlockUpkeepDB.profiles end

function ns.CurrentProfile() return ns.cdb.profile or DEFAULT end

function ns.ProfileNames()
    local list = {}
    for name in pairs(Profiles()) do list[#list + 1] = name end
    table.sort(list, function(a, b)
        if a == DEFAULT or b == DEFAULT then return a == DEFAULT end
        return a:lower() < b:lower()
    end)
    return list
end

-- Makes `name` the character's profile (created from the defaults if missing) and points ns.db at it.
function ns.SelectProfile(name)
    name = (type(name) == "string" and name ~= "") and name or DEFAULT
    local p = Profiles()
    if type(p[name]) ~= "table" then p[name] = {} end
    ns.CopyDefaults(ns.defaults, p[name])
    ns.cdb.profile = name
    ns.db = p[name]
end

local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = DeepCopy(v) end
    return c
end

-- A new profile with the current settings. false when the name is taken or empty.
function ns.CreateProfile(name)
    name = name and name:match("^%s*(.-)%s*$")
    if not name or name == "" or Profiles()[name] then return false end
    Profiles()[name] = DeepCopy(ns.db)
    ns.SelectProfile(name)
    return true
end

-- Deletes a profile other than Default; characters using it go back to Default on their next login.
function ns.DeleteProfile(name)
    if not name or name == DEFAULT or not Profiles()[name] then return false end
    Profiles()[name] = nil
    if ns.CurrentProfile() == name then ns.SelectProfile(DEFAULT) end
    return true
end

------------------------------------------------------------------------
-- Export / import. The format is a small subset of Lua table syntax read by its own parser, so an imported
-- string can never run code: {key=value;...} with "strings", numbers, T / F.
------------------------------------------------------------------------
local PREFIX = "WU1:"

local function Serialize(v, out)
    local t = type(v)
    if t == "table" then
        out[#out + 1] = "{"
        local keys = {}
        for k in pairs(v) do
            if type(k) == "string" or type(k) == "number" then keys[#keys + 1] = k end
        end
        table.sort(keys, function(a, b)
            if type(a) ~= type(b) then return type(a) == "number" end
            return a < b
        end)
        for _, k in ipairs(keys) do
            Serialize(k, out)
            out[#out + 1] = "="
            Serialize(v[k], out)
            out[#out + 1] = ";"
        end
        out[#out + 1] = "}"
    elseif t == "string" then
        out[#out + 1] = '"' .. v:gsub('[\\"]', "\\%0"):gsub("\n", "\\n") .. '"'
    elseif t == "number" then
        out[#out + 1] = string.format("%.17g", v)
    elseif t == "boolean" then
        out[#out + 1] = v and "T" or "F"
    else
        out[#out + 1] = "F"
    end
end

function ns.ExportProfile()
    local out = {}
    Serialize(ns.db, out)
    return PREFIX .. table.concat(out)
end

-- Returns the value at position i and the next position, or nil and an error.
local function Parse(s, i)
    local c = s:sub(i, i)
    if c == "{" then
        local t = {}
        i = i + 1
        while s:sub(i, i) ~= "}" do
            if i > #s then return nil, "unexpected end" end
            local k, v
            k, i = Parse(s, i)
            if k == nil or type(k) == "table" or type(k) == "boolean" then return nil, "bad key" end
            if s:sub(i, i) ~= "=" then return nil, "'=' expected" end
            v, i = Parse(s, i + 1)
            if v == nil then return nil, i end
            if s:sub(i, i) ~= ";" then return nil, "';' expected" end
            t[k] = v
            i = i + 1
        end
        return t, i + 1
    elseif c == '"' then
        local buf, j = {}, i + 1
        while true do
            local ch = s:sub(j, j)
            if ch == "" then return nil, "unterminated string" end
            if ch == '"' then break end
            if ch == "\\" then
                local n = s:sub(j + 1, j + 1)
                buf[#buf + 1] = n == "n" and "\n" or n
                j = j + 2
            else
                buf[#buf + 1] = ch
                j = j + 1
            end
        end
        return table.concat(buf), j + 1
    elseif c == "T" or c == "F" then
        return c == "T", i + 1
    else
        local num = s:match("^-?[%d%.]+[eE]?[-+]?%d*", i)
        if not num or not tonumber(num) then return nil, "unexpected '" .. c .. "'" end
        return tonumber(num), i + #num
    end
end

-- Keeps only values whose type matches the defaults (lists without defaults, like custom sounds, as they are).
local function Clean(src, defaults)
    local out = {}
    for k, v in pairs(src) do
        local d = defaults and defaults[k]
        if d == nil then
            if defaults == nil or type(k) == "number" or next(defaults) == nil then out[k] = v end
        elseif type(d) == type(v) then
            out[k] = type(v) == "table" and Clean(v, d) or v
        end
    end
    return out
end

-- Replaces the current profile's settings with the string's. true, or false and the reason.
function ns.ImportProfile(text)
    text = text and text:match("^%s*(.-)%s*$") or ""
    if text:sub(1, #PREFIX) ~= PREFIX then return false, "not a WarlockUpkeep! profile string" end
    local ok, t, pos = pcall(Parse, text, #PREFIX + 1)
    if not ok then return false, tostring(t) end
    if type(t) ~= "table" then return false, tostring(pos) end
    local clean = Clean(t, ns.defaults)
    wipe(ns.db)
    for k, v in pairs(clean) do ns.db[k] = v end
    ns.CopyDefaults(ns.defaults, ns.db)
    return true
end
