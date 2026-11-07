-- Narrow live display adapter: player + target only. Not a raid roster provider.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local F=require("Mazrim_Raid_Frames/shared/foundation")
local P=require("Mazrim_Raid_Frames/shared/presentation")
local L={}
function L.new(api)
  local u=B.member(api,"Unit")
  local s={samples=0,last_known=0,last_state="NOT_READ"}
  local function getid(token)
    local ok,id=B.call(u,"GetUnitId",token)
    if not ok then return nil,"UNAVAILABLE" end
    if B.id(id) then return id,"KNOWN" end
    if id==nil or id=="" or id==0 then return nil,"EMPTY" end
    return nil,"INVALID_ID"
  end
  local function unknown(token,state)
    return {name=token=="player" and "You - unavailable" or (state=="EMPTY" and "No target" or "Target - unavailable"),
      kind=token,health=F.resource(nil,nil),mana=F.resource(nil,nil),state=state,selected=false}
  end
  local function row(token)
    local id,state=getid(token)
    if not id then return unknown(token,state) end
    local a,name=B.call(u,"GetUnitNameById",id)
    local b,tokenname=B.call(u,"UnitName",token)
    local h,hp=B.call(u,"UnitHealth",token);local m,max=B.call(u,"UnitMaxHealth",token)
    local after,afterstate=getid(token)
    if afterstate~="KNOWN" or after~=id then return unknown(token,"IDENTITY_CHANGED") end
    if a and b and type(name)=="string" and type(tokenname)=="string" and name~=tokenname then
      return unknown(token,"METADATA_DISAGREES")
    end
    if not a or type(name)~="string" or name=="" then
      if b and type(tokenname)=="string" then name=tokenname else name=token=="player" and "You" or "Selected target" end
    end
    local hpvalue=(h and m) and F.resource(hp,max) or F.resource(nil,nil)
    return {name=P.text(name,24),kind=token,identity=id,health=hpvalue,mana=F.resource(nil,nil),
      state=hpvalue.known and "OBSERVED" or "HEALTH_UNAVAILABLE",selected=token=="target"}
  end
  function s.read()
    s.samples=s.samples+1
    local a=row("player");local b=row("target")
    -- Re-check both tokens after the entire pair, not just after an individual getter.
    for _,r in ipairs({a,b}) do
      if r.identity then
        local id,why=getid(r.kind)
        if why~="KNOWN" or id~=r.identity then
          local replacement=unknown(r.kind,"IDENTITY_CHANGED")
          if r.kind=="player" then a=replacement else b=replacement end
        end
      end
    end
    a.selected=a.identity~=nil and b.identity~=nil and a.identity==b.identity
    s.last_known=(a.health.known and 1 or 0)+(b.health.known and 1 or 0)
    s.last_state=s.last_known==2 and "TWO_HEALTH_READINGS" or "PARTIAL_OR_UNAVAILABLE"
    return {source="live",rows={a,b},coverage="SELF_TARGET_ONLY_NO_ROSTER"}
  end
  function s.unavailable(reason)
    s.last_known=0;s.last_state=reason
    return {source="live",rows={unknown("player",reason),unknown("target",reason)},coverage="SELF_TARGET_ONLY_NO_ROSTER"}
  end
  return s
end
return L
