-- Explicit diagnostic only. One owned zero-icon factory pool, never BuffUpdate.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local P={contract=1}
local serial=0
function P.new(api,factory,alive)
  serial=serial+1
  local prefix="maz_raid_aura_probe_"..serial
  local parent,window,getters
  local attempted,partial,closed,releasing=false,false,false,false
  local s={contract=1}
  local function current()
    if closed or type(alive)~="function"then return false end
    local ok,v=pcall(alive);return ok and v==true and not closed
  end
  local function hide(o)
    if not o then return true end
    local ok,v=B.call(o,"Show",false);return ok and v~=false
  end
  local function free(o)
    if not o then return true end
    local ok,v=B.call(B.member(api,"Interface"),"Free",o)
    return ok and v~=false -- native Free is void; hide/handlers, not destruction
  end
  function s.available()
    local iface=B.member(api,"Interface")
    return current()and not partial and type(factory)=="function"
      and type(B.member(iface,"CreateEmptyWindow"))=="function"
      and type(B.member(iface,"Free"))=="function"
      and type(B.member(B.member(api,"Time"),"GetUiMsec"))=="function"
  end
  function s.acquire()
    if not s.available()then return nil end
    if attempted then return getters end
    attempted=true
    local ok,value=B.call(B.member(api,"Interface"),"CreateEmptyWindow",prefix.."_parent","UIParent")
    if ok and value then parent=value end
    if not parent then partial=true;return nil end
    if not hide(parent)or not current()then return nil end
    -- Mark partial BEFORE crossing the factory. An unreturned root cannot be
    -- recovered by Free(parent); retain containment and prohibit another try.
    partial=true
    ok,value=pcall(factory,prefix.."_window",parent,0,"raid")
    if not ok or not value then return nil end
    window=value;partial=false
    if not hide(window)or not current()then return nil end
    local g=B.member(window,"getBuff")
    if type(g)~="table"or not current()then return nil end
    getters=g;return g
  end
  function s.release()
    if releasing then return false end
    releasing=true
    local hidden=hide(parent)
    if partial then releasing=false;return false end
    local wh=hide(window);local wf=free(window);local pf=free(parent)
    -- Keep the known inert allocation/getters for later explicit captures.
    releasing=false;return hidden and wh and wf and pf
  end
  function s.nowMs()return B.now(api)end
  function s.close()closed=true;return s.release()end
  function s.containmentUnknown()return partial end
  return s
end
return P
