-- First-party AAC boundary. Only previously inspected APIs from Overhead 0.3.2.
-- No team discovery, target writes, aura reads, input hooks or native-frame edits.
local I=require("Mazrim_Raid_Frames/shared/identity")
local B={pointerSpaceContract=1}
function B.member(object,key)
  if object==nil then return nil end
  local ok,v=pcall(function()return object[key]end)
  if ok then return v end
end
function B.call(object,key,...)
  local fn=B.member(object,key)
  if type(fn)~="function" then return false,nil end
  return pcall(fn,object,...)
end
function B.finite(v)return type(v)=="number" and v==v and v>-1/0 and v<1/0 end
function B.id(v)
  return I.accepts(v)
end
function B.now(api)
  local ok,v=B.call(B.member(api,"Time"),"GetUiMsec")
  if ok and B.finite(v) and v>=0 then return v end
end
function B.extent(api,alive)
  local function current()return type(alive)~="function"or alive()==true end
  if not current()then return 1280,720 end
  local i=B.member(api,"Interface")
  local ok,w=B.call(i,"GetScreenWidth")
  if not current()then return 1280,720 end
  local good,h=B.call(i,"GetScreenHeight")
  if not current()then return 1280,720 end
  if ok and good and B.finite(w) and B.finite(h) and w>=1 and h>=1 then return w,h end
  return 1280,720
end
-- Mouse positions are device pixels; anchors use UI units (native
-- F_LAYOUT.CalcDontApplyUIScale divides by UIParent:GetUIScale()).
function B.mouse(api,alive)
  local function current()return type(alive)~="function"or alive()==true end
  if not current()then return false end
  local ok,x,y=B.call(B.member(api,"Input"),"GetMousePos")
  if not current()then return false end
  local good,scale=B.call(B.member(api,"Interface"),"GetUIScale")
  if not current()then return false end
  if not ok or not good or not B.finite(x)or not B.finite(y)or not B.finite(scale)or scale<=0 then return false end
  return true,x/scale,y/scale
end
function B.offset(api,object,alive)
  local function current()return type(alive)~="function"or alive()==true end
  if not current()then return false end
  local ok,x,y=B.call(object,"GetOffset")
  if not current()then return false end
  if ok and B.finite(x)and B.finite(y)then return true,x,y end
  ok,x,y=B.call(object,"GetEffectiveOffset")
  if not current()then return false end
  local good,scale=B.call(B.member(api,"Interface"),"GetUIScale")
  if not current()then return false end
  if ok and good and B.finite(x)and B.finite(y)and B.finite(scale)and scale>0 then return true,x/scale,y/scale end
  return false
end
function B.log(api,message) B.call(B.member(api,"Log"),"Info","Mazrim Raid Frames: "..message) end
return B
