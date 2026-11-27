passed=0
local function Check(v,msg) assert(v,msg); passed=passed+1 end
local count,room=4,true
local cfg={enabled=true,keepOnTravel=true,showIcon=true,showThreshold=false,
    autoThreshold=true,threshold=3,spare=1,includeRitual=false,maxShards=0,
    glow=true,edgeGlow=false,fullWarn=true,iconSize=32,fontSize=20,bgAlpha=0.3,
    color={1,1,1,1},lowColor={1,.25,.25,1},edgeColor={1,.82,0,1},overColor={.6,.8,1,1},
    glowColor={1,.2,.2,1},edgeGlowColor={1,.82,0,1},fullGlowColor={1,.5,0,1}}
local frame={text={},glow={},bg={}}
function frame:Hide() self.hidden=true end
function frame:Show() self.hidden=false end
function frame:SetSize() end
function frame:SetAlpha() end
function frame:EnableMouse() end
function frame.text:SetText(s) self.text=s end
function frame.text:SetTextColor(...) self.color={...} end
function frame.text:GetStringWidth() return 20 end
function frame.glow:SetGlow(on,color) self.on=not not on; self.color=color end
function frame.bg:SetAlpha() end
local ns={SHARD_ITEMS=true,modules={},ready=true,
    db={shards=cfg,weaponStone={enabled=false},preview=false},
    data={SOUL_SHARD=6265,demons={{shard=true}},
        stoneOrder={"healthstone","soulstone"},stones={healthstone={6201},soulstone={693}},
        drainSoul={1120},ritualOfSummoning=698},
    L=setmetatable({},{__index=function(_,k)return k end})}
function ns:NewModule(name) local m={}; self.modules[name]=m; return m end
function ns.DemonSpell() return 697 end
function ns.HighestKnown(list) return list[1] end
function ns.SpellName(id) return tostring(id) end
function ns.Hardcore() return false end
function ns.IsKnown() return false end
function ns.ItemCount() return count end
function ns.HiddenForTravel() return false end
function ns.HiddenForResting() return false end
function ns.FrameAlpha() return 1 end
function ns.ClickThrough() return false end
function ns.PlaySound() ns.sounds=(ns.sounds or 0)+1 end
assert(loadfile('WarlockUpkeep/Modules/Shards.lua'))('WarlockUpkeep',ns)
function ns.CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            ns.CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end


local m=ns.modules.shards; m.frame=frame
function m:HasRoom() return room end
Check(m:Threshold()==4,"Automatic target must override manual 3 with 4")
m:Update(); Check(not frame.glow.on,"Four shards at target must not glow by default")
Check(frame.text.color[2]==cfg.edgeColor[2],"Threshold text color retained independently")
count=3; m:Update()
Check(frame.glow.on and frame.glow.color==cfg.glowColor,"Below automatic target still low glow")
count=5; m:Update(); Check(not frame.glow.on,"Above target no glow")
count=4; cfg.edgeGlow=true; m:Update()
Check(frame.glow.on and frame.glow.color==cfg.edgeGlowColor,"Threshold toggle restores yellow glow")
cfg.glow=false; m:Update(); Check(not frame.glow.on,"Master glow toggle controls threshold glow")
count=3; m:Update(); Check(not frame.glow.on,"Master toggle still controls low glow")
cfg.glow=true; cfg.edgeGlow=false; count=4; room=false; m:Update()
Check(frame.glow.on and frame.glow.color==cfg.fullGlowColor,"Full-bag warning preserved at target")
cfg.fullWarn=false; m:Update(); Check(not frame.glow.on,"Full-bag warning toggle respected")
cfg.fullWarn=true; cfg.showIcon=false; m:Update()
Check(not frame.glow.on,"Hidden icon has no glow")
cfg.showIcon=true; room=true; cfg.autoThreshold=false; cfg.threshold=3; count=4; m:Update()
Check(not frame.glow.on,"Manual threshold honored")
count=3; m:Update(); Check(not frame.glow.on,"Manual at-threshold also quiet by default")
count=2; m:Update(); Check(frame.glow.on,"Manual below-threshold glow preserved")
cfg.edgeGlow=true; count=3; m:Update(); Check(frame.glow.on,"Manual threshold toggle works")
local fresh={glow=true}; ns.CopyDefaults({edgeGlow=true},fresh)
Check(fresh.edgeGlow==true and fresh.glow,"New profiles keep the previous threshold-glow behavior")
local existing={edgeGlow=true}; ns.CopyDefaults({edgeGlow=false},existing)
Check(existing.edgeGlow==true,"Explicit threshold preference survives default merge")
existing={edgeGlow=false}; ns.CopyDefaults({edgeGlow=true},existing)
Check(existing.edgeGlow==false,"Explicitly disabling threshold glow survives default merge")
cfg.edgeGlow=false; cfg.autoThreshold=true; cfg.sound=true; m.low=false; count=4; m:Update()
Check(not ns.sounds,"At reserve has no low sound")
count=3; m:Update(); Check(ns.sounds==1,"Crossing below reserve plays low sound")
m:Update(); Check(ns.sounds==1,"Stable low count does not repeat sound")

print('shard_glow: '..passed..' behavior checks passed')
