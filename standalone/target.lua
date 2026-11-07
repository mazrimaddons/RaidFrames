-- One explicitly armed POC write through the source-observed colon API route.
-- Reuses the ONE roster reader; no discovery, fallback, cast or target restore.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local I=require("Mazrim_Raid_Frames/shared/identity")
local M={contract=6,nameRefreshModeContract=1,traceContract=1,instantHoverContract=1,nativeNameFeedbackContract=1}
function M.new(api,reader,alive,trace)
  local s={contract=6,nameRefreshModeContract=1,traceContract=1,nativeNameFeedbackContract=1,nameStatus="IDLE"}
  -- Every new service automatically reconciles the native name once, after
  -- immediate selection. This is runtime behavior, never a saved setting.
  local refreshEnabled=true
  local pending,newest=nil,nil
  local sequence,depth=0,0
  local record=type(trace)=="table"and trace.contract==1 and type(trace.record)=="function"and trace.record or nil
  local function mark(kind,request,data)
    if not record then return end
    data=data or{}
    if request then data.request=request.sequence;data.expected=request.id;data.token=request.token end
    local ok=pcall(record,kind,data);if not ok then record=nil end
  end
  local function status(request,value)
    if newest==request then s.nameStatus=value end
  end
  local function valid_name(value)
    return type(value)=="string" and #value>0 and #value<=128
      and not value:find("[%c|]") and not value:match("^%s*$")
  end
  function s.cancel()
    mark("DECISION",newest,{result="CANCELLED"})
    pending=nil;newest=nil;s.nameStatus="CANCELLED"
  end
  function s.nameRefreshEnabled()return refreshEnabled end
  -- Compatibility/diagnostic hook for offline comparisons only. No player
  -- control exposes it; a new service always returns to automatic behavior.
  function s.setNameRefresh(value)
    if type(value)~="boolean"then return false end
    s.cancel();refreshEnabled=value;s.nameStatus=value and"IDLE"or"DISABLED";return true
  end
  function s.available()
    return type(reader)=="table" and reader.targetValidationContract==1 and type(reader.validateTarget)=="function"
      and type(B.member(B.member(api,"Unit"),"TargetUnit"))=="function"
  end
  function s.attempt(token,id,pointerAlive,expectedName)
    sequence=sequence+1
    local request={sequence=sequence,id=id,token=token};newest=request;pending=nil;s.nameStatus=refreshEnabled and"UNAVAILABLE"or"DISABLED"
    mark("REQUEST",request)
    local function outcome(value)mark("DECISION",request,{result=value});return value end
    local valid=false
    for i=1,50 do if token=="team"..i then valid=true;break end end
    if not valid or not I.accepts(id) or not s.available() then return outcome("UNAVAILABLE") end
    local function current()
      if newest~=request or type(alive)~="function" or type(pointerAlive)~="function" then return false end
      local a,v=pcall(alive);if newest~=request or not a or v~=true then return false end
      local b,w=pcall(pointerAlive);if newest~=request or not b or w~=true then return false end
      local c,z=pcall(alive);return newest==request and c and z==true
    end
    if not current() then return outcome("CANCELLED") end
    -- Single-reader fast path: member/id/online/id/member, without resource reads.
    local ok,result=pcall(reader.validateTarget,token,id,current)
    if not current() then return outcome("CANCELLED") end
    if not ok or type(result)~="table" or result.contract~=1 or result.token~=token then return outcome("MEMBER_CHANGED") end
    if result.state~="valid" then
      if result.reason=="offline" or result.reason=="offline_unknown" then return outcome("OFFLINE") end
      if result.reason=="cancelled" then return outcome("CANCELLED") end
      return outcome("MEMBER_CHANGED")
    end
    local unit=B.member(api,"Unit");local fn=B.member(unit,"TargetUnit")
    if type(fn)~="function" or not current() then return outcome("CANCELLED") end
    depth=depth+1;mark("CALL_BEGIN",request,{depth=depth})
    local sent,result=pcall(fn,unit,token)
    mark("CALL_END",request,{depth=depth,result=not sent and"ERROR"or result==false and"FAILED"or result==nil and"NIL"or"OK"});depth=depth-1
    -- No immediate readback, whole-frame repair, fallback or target retry.
    -- nil is only a returned request, NOT proof of native target/cast recipient.
    if not sent or result==false then return outcome("FAILED") end
    -- No additional native reads here: target selection stays immediate.
    if refreshEnabled and newest==request and valid_name(expectedName) and current() then
      pending={request=request,id=id,name=expectedName,current=current}
      s.nameStatus="PENDING"
    else status(request,refreshEnabled and"UNAVAILABLE"or"DISABLED") end
    return outcome("REQUESTED")
  end
  function s.tick()
    if not refreshEnabled then return end
    local ticket=pending;if not ticket then return end
    pending=nil -- consume before callbacks; no retry or unbounded job chain
    local function current()
      return newest==ticket.request and ticket.current() and newest==ticket.request
    end
    local function note(value)status(ticket.request,value)end
    if not current() then note("CANCELLED");return end
    local unit=B.member(api,"Unit")
    local function target_matches()
      if not current() then return false end
      local ok,id=B.call(unit,"GetUnitId","target")
      return current() and ok and I.accepts(id) and id==ticket.id
    end
    local function name_matches()
      if not target_matches() then return false end
      local ok,name=B.call(unit,"UnitName","target")
      return current() and ok and valid_name(name) and name==ticket.name and target_matches()
    end
    if not name_matches() then note("TARGET_OR_NAME_CHANGED");return end
    local key=B.member(UIC,"TARGET_UNITFRAME")
    if key==nil then note("UNAVAILABLE");return end
    local ok,frame=B.call(ADDON,"GetContent",key)
    if not current() or not ok or not frame or B.member(frame,"target")~="target" then note("UNAVAILABLE");return end
    local label=B.member(frame,"name");local update=B.member(frame,"UpdateName")
    if type(update)~="function" then note("UNAVAILABLE");return end
    local read,text=B.call(label,"GetText")
    if not current() or not read or type(text)~="string" then note("UNAVAILABLE");return end
    if text==ticket.name then
      note(name_matches() and "ALREADY_CURRENT" or "TARGET_OR_NAME_CHANGED");return
    end
    -- Recheck immediately before calling the existing NAME-only native method.
    if B.member(frame,"target")~="target" or not name_matches() then note("TARGET_OR_NAME_CHANGED");return end
    local same,latest=B.call(ADDON,"GetContent",key)
    if not current() or not same or latest~=frame or B.member(frame,"target")~="target"
      or B.member(frame,"UpdateName")~=update or B.member(frame,"name")~=label then note("UNAVAILABLE");return end
    local latestRead,latestText=B.call(label,"GetText")
    if not current() or not latestRead or type(latestText)~="string" then note("UNAVAILABLE");return end
    if latestText==ticket.name then note(name_matches() and "ALREADY_CURRENT" or "TARGET_OR_NAME_CHANGED");return end
    if not name_matches() then note("TARGET_OR_NAME_CHANGED");return end
    mark("NAME_BEGIN",ticket.request)
    local refreshed,value=pcall(update,frame)
    mark("NAME_END",ticket.request,{result=not refreshed and"ERROR"or value==false and"FAILED"or"OK"})
    if not refreshed or value==false then note("FAILED");return end
    if not name_matches() then note("TARGET_OR_NAME_CHANGED");return end
    local verified,name=B.call(label,"GetText")
    note(current() and verified and name==ticket.name and "REFRESHED" or "UNCONFIRMED")
  end
  return s
end
return M
