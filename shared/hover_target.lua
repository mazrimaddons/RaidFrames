-- Pure event-entry coordinator. Polling only monitors; no dwell or retry timer.
local I=require("Mazrim_Raid_Frames/shared/identity")
local M={contract=2,nativeNameFeedbackContract=1}
local function finite(v)return type(v)=="number" and v==v and v>=0 and v<1/0 end
local function eligible(row)
  if type(row)~="table" or row.kind~="raid" or not I.accepts(row.identity)
    or (row.offlineKnown==true and row.offline==true) then return false end
  for i=1,50 do if row.token=="team"..i then return true end end
  return false
end
function M.new(attempt,alive)
  local s={armed=false,status="Hover targeting OFF"}
  local entry=nil
  local function current()
    if type(alive)~="function" then return false end
    local ok,v=pcall(alive);return ok and v==true
  end
  function s.disarm()
    s.armed=false;entry=nil;s.status="Hover targeting OFF"
  end
  function s.leave()entry=nil end
  function s.block(key)if key then entry={key=key,blocked=true,spent=true}end end
  function s.arm()
    s.disarm()
    if type(attempt)~="function" or not current() then return false end
    s.armed=true;s.status="Hover ready: instant on entry";return true
  end
  function s.update(row,now,pointerAlive,cellKey,dispatch)
    if not s.armed then return end
    if not current() or not finite(now) then s.disarm();return end
    if cellKey==nil then entry=nil;return end
    if not entry and dispatch~=true then return end
    if not eligible(row) then
      entry={key=cellKey,blocked=true,spent=true}
      s.status="Row unavailable; leave/re-enter";return
    end
    if not entry or entry.key~=cellKey then
      if dispatch~=true then entry=nil;return end
      entry={key=cellKey,token=row.token,id=row.identity,name=row.nameKnown==true and row.name or nil,spent=false}
    elseif entry.blocked then return
    elseif entry.token~=row.token or entry.id~=row.identity then
      entry.blocked=true;entry.spent=true
      s.status="Member changed; leave/re-enter";return
    end
    if entry.spent or dispatch~=true then return end
    local ticket=entry
    local function guard()
      if not s.armed or entry~=ticket or ticket.blocked or not current() or type(pointerAlive)~="function" then return false end
      local ok,v=pcall(pointerAlive);return ok and v==true
    end
    if not guard() then entry.blocked=true;return end
    ticket.spent=true -- consume BEFORE dispatch; errors never trigger retries
    local ok,result=pcall(attempt,ticket.token,ticket.id,guard,ticket.name)
    if not s.armed or entry~=ticket then return end
    if ok and result=="REQUESTED" then s.status="Request sent; check native target"
    elseif ok and result=="OFFLINE" then s.status="Skipped: offline or status unknown"
    elseif ok and result=="MEMBER_CHANGED" then s.status="Skipped: member changed/unavailable"
    elseif ok and result=="CANCELLED" then s.status="Cancelled: hover or session ended"
    else s.status="Target request unavailable/failed" end
  end
  return s
end
return M
