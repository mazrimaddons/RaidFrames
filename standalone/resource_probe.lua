-- Manually armed, anonymous self-reference comparison. No resource cache/binding.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local P={contract=1,reasonContract=4,comparisonContract=1}
local serial=0
local STAGES={
  missing_RegisterEvent="RegisterEvent missing",missing_ReleaseHandler="ReleaseHandler missing",
  missing_SetHandler="SetHandler missing",window_api_missing="window API missing",free_api_missing="Free missing",
  clock_api_missing="GetUiMsec missing",collector_api_missing="comparison API missing",host_unavailable="lifetime unavailable",
  reader_api_missing="member reader missing",reference_api_missing="self reference missing",
  clock_read_failed="clock read failed",clock_type_invalid="clock type invalid",clock_range_invalid="clock range invalid",
  clock_fractional="fractional UI clock",clock_reversed="clock reversed",create_window="CreateEmptyWindow failed",
  hide_window="Show failed",collector_create="collector creation failed",attach_handler="OnEvent attach failed",
  register_health="health registration failed",register_mana="mana registration failed",
  collector_observe="collector observe failed",collector_report="collector report invalid",
  collector_state="collector state unavailable",
  release_handler="ReleaseHandler failed",
  free_listener="listener Free failed",closed="closed"}
local function detail(value)return STAGES[value]or"unknown stage"end
local MAX=9007199254740991
local EVENTS={"TEAM_HEALTH_CHANGED","TEAM_MANA_CHANGED"}
local FIELDS={"payloadRejected","referenceUnavailable","invalidReference","numericIdIncomparable",
  "neither","both","tokenEqual","idEqual","topicLimit","readUnavailable","referenceChanged",
  "resourceUnknown","resourceFull","resourceUnstable","numbersCurrentMax","numbersMaxCurrent",
  "pairMismatch","interrupted"}
local function integer(v,max)return type(v)=="number" and v==v and v>=0 and v<=max and v==math.floor(v)end
local function copy(v)
  if type(v)~="table" then return v end
  local out={};for k,value in pairs(v)do out[k]=copy(value)end;return out
end
-- Copy the collector's fixed counter schema only; never forward arbitrary fields.
local function summary(raw)
  if type(raw)~="table" or raw.contract~=1 or raw.eventLimit~=64 or raw.positionLimit~=3
    or raw.attemptLimit~=4 or raw.topicAttemptLimit~=2 or not integer(raw.eventsSeen,64)
    or not integer(raw.attempts,4) or not integer(raw.referenceCalls,64)
    or not integer(raw.readerCalls,8) or type(raw.events)~="table" then return nil end
  local result={contract=1,eventLimit=64,positionLimit=3,attemptLimit=4,topicAttemptLimit=2,
    eventsSeen=raw.eventsSeen,attempts=raw.attempts,referenceCalls=raw.referenceCalls,readerCalls=raw.readerCalls,
    argumentCountKnown=false,payloadSchemaVerified=false,actorAttributed=false,
    freshnessKnown=false,resourceCoverageKnown=false,events={}}
  local states={collecting=true,complete=true,stopped=true,cancelled=true,unavailable=true}
  local reasons={collecting=true,event_cap=true,attempt_cap=true,manual_stop=true,cancelled=true,
    lifetime_unverified=true,dependency_unverified=true,comparison_failed=true}
  if not states[raw.state] or not reasons[raw.reason] then return nil end
  result.state=raw.state;result.reason=raw.reason
  local count,attempts,reads=0,0,0
  for _,topic in ipairs({"health","mana"})do
    local source=raw.events[topic]
    if type(source)~="table" or not integer(source.count,64) or not integer(source.attempts,2)
      or not integer(source.readerCalls,4)then return nil end
    local target={count=source.count,attempts=source.attempts,readerCalls=source.readerCalls}
    count=count+source.count;attempts=attempts+source.attempts;reads=reads+source.readerCalls;result.events[topic]=target
    for _,key in ipairs(FIELDS)do
      if not integer(source[key],source.count)then return nil end
      target[key]=source[key]
    end
    if target.numbersCurrentMax+target.numbersMaxCurrent+target.pairMismatch>target.count then return nil end
  end
  if count~=raw.eventsSeen or attempts~=raw.attempts or reads~=raw.readerCalls then return nil end
  return result
end
function P.new(api,Native,hostAlive,reader,selfReference)
  local s={contract=1,reasonContract=4,comparisonContract=1}
  local listener,collector,lastSummary=nil,nil,nil
  local state,reason="idle","idle"
  local stage,cleanupStage,clockStage=nil,nil,nil
  local armed,closed,busy,dispatching=false,false,false,false
  local needHandler=false
  local generation=0
  local deadline,lastClock=nil,nil
  local requested=nil
  local function host()
    if type(hostAlive)~="function"then return false end
    local ok,value=pcall(hostAlive);return ok and value==true
  end
  local function clock()
    local ok,value=B.call(B.member(api,"Time"),"GetUiMsec")
    clockStage=nil
    if not ok then clockStage="clock_read_failed"
    elseif type(value)~="number"then clockStage="clock_type_invalid"
    elseif value~=value or value<0 or value>MAX then clockStage="clock_range_invalid"
    elseif value~=math.floor(value)then clockStage="clock_fractional"
    else return value end
  end
  local function capture()
    if not collector then return true end
    local ok,value=pcall(collector.report)
    local checked,clean=false,nil
    if ok then checked,clean=pcall(summary,value)end
    if not checked then clean=nil end
    if clean then lastSummary=clean;return true end
    return false
  end
  local function revoke(why,discard)
    armed=false
    if collector then
      -- Capture while its valid generation still exists; stop before any native cleanup.
      if not discard then capture()end
      pcall(collector.stop)
      if not discard then capture()end
      collector=nil
    end
    if discard then lastSummary=nil end
    generation=generation+1;deadline=nil;lastClock=nil
    reason=why
    if why=="event_cap" or why=="attempt_cap" or why=="timeout"then state="complete"
    elseif why=="cancelled"then state="cancelled"
    elseif why=="manual_stop"then state="stopped"
    else state="unavailable"end
  end
  local function detach()
    if not listener then return true end
    cleanupStage=nil
    -- Same dedicated-window route as accepted Public observers. ReleaseHandler
    -- revokes sandbox dispatch; hide/Free release the own UI handlers/reference.
    -- Neither operation is claimed to remove native registration metadata.
    if needHandler then
      local good,value=B.call(listener,"ReleaseHandler","OnEvent")
      if not good or value==false then cleanupStage="release_handler";return false end
      needHandler=false
    end
    local hidden,value=B.call(listener,"Show",false)
    if not hidden or value==false then cleanupStage="hide_window";return false end
    local freed,value=B.call(B.member(api,"Interface"),"Free",listener)
    if not freed or value==false then cleanupStage="free_listener";return false end
    listener=nil;return true
  end
  local function finish(why,discard)
    if busy or dispatching then
      armed=false;requested=why
      if collector then pcall(collector.stop)end
      return false
    end
    busy=true
    revoke(why,discard)
    local good=detach()
    if requested=="cancelled"then lastSummary=nil;state="cancelled";reason="cancelled"end
    busy=false
    requested=nil;return good
  end
  local function guard(ticket)
    if closed or ticket~=generation or requested then return false end
    local current=host()
    return current and not closed and ticket==generation and requested==nil
  end
  local function checkDeadline()
    if not armed then return false end
    local ticket=generation
    local current=host()
    if not armed or busy or dispatching or ticket~=generation or not collector then return false end
    if not current then finish("cancelled",true);return false end
    local now=clock()
    if not armed or busy or dispatching or ticket~=generation or not collector then return false end
    if not now or not lastClock or now<lastClock then
      stage=not now and clockStage or "clock_reversed"
      finish("clock_unavailable",false);return false
    end
    lastClock=now
    if now>=deadline then finish("timeout",false);return false end
    return true
  end
  local function capabilityStage()
    if closed then return "closed" end
    if type(hostAlive)~="function"then return "host_unavailable" end
    if type(Native)~="table" or Native.resourceEventComparisonContract~=1
      or type(Native.newResourceEventComparison)~="function"then return "collector_api_missing" end
    if type(reader)~="table" or reader.memberContract~=1
      or type(B.member(reader,"observeMember"))~="function"then return "reader_api_missing" end
    if type(selfReference)~="function"then return "reference_api_missing" end
    if type(B.member(B.member(api,"Interface"),"CreateEmptyWindow"))~="function"then return "window_api_missing" end
    if type(B.member(B.member(api,"Interface"),"Free"))~="function"then return "free_api_missing" end
    if type(B.member(B.member(api,"Time"),"GetUiMsec"))~="function"then return "clock_api_missing" end
  end
  function s.available()return capabilityStage()==nil end
  local function onEvent(ticket,_,event,a1,a2,a3,a4,a5,a6,a7,a8)
    if not armed or busy or dispatching or ticket~=generation then return end
    if not checkDeadline()then return end
    if not armed or busy or dispatching or ticket~=generation or not collector then return end
    dispatching=true
    local ok,accepted,why=pcall(collector.observe,event,a1,a2,a3)
    if armed and ticket==generation then
      if ok and accepted==false and why=="busy"then
        -- A nested/shared-reader busy result is ignored, never reported/retried.
      elseif not ok or not capture()then stage=not ok and "collector_observe" or "collector_report";revoke("collector_failed",true)
      elseif lastSummary.state=="cancelled"then revoke("cancelled",true)
      elseif lastSummary.state=="unavailable"then stage="collector_state";revoke("collector_failed",true)
      elseif lastSummary.state=="complete"then revoke(lastSummary.reason,false)end
    end
    dispatching=false
    if requested then
      local why=requested;requested=nil;finish(why,why=="cancelled")
    elseif not armed then
      busy=true;detach();busy=false;requested=nil
    end
  end
  function s.start()
    if busy or dispatching or armed then return false end
    if closed then return false end
    busy=true;requested=nil
    if listener and not detach()then busy=false;state="unavailable";reason="cleanup_pending";return false end
    stage=capabilityStage()
    if stage or not host()then stage=stage or "host_unavailable";busy=false;state="unavailable";reason="unavailable";return false end
    if requested or closed then busy=false;state="cancelled";reason="cancelled";requested=nil;return false end
    local now=clock()
    if not now or now>MAX-180000 then stage=clockStage or "clock_range_invalid";busy=false;state="unavailable";reason="clock_unavailable";return false end
    if requested or closed then busy=false;state="cancelled";reason="cancelled";requested=nil;return false end
    generation=generation+1;local ticket=generation
    lastSummary=nil;state="idle";reason="starting"
    local function fail(why,failedStage)
      if failedStage then stage=failedStage end
      revoke(why,why=="cancelled");detach();busy=false;requested=nil;return false
    end
    serial=serial+1
    local made,value=B.call(B.member(api,"Interface"),"CreateEmptyWindow","maz_raid_resource_check_"..serial,"UIParent")
    if made and(type(value)=="table"or type(value)=="userdata")then listener=value end
    if not made or not listener then return fail("listener_unavailable","create_window")end
    if requested or not guard(ticket)then return fail("cancelled")end
    for _,method in ipairs({"RegisterEvent","SetHandler","ReleaseHandler"})do
      if type(B.member(listener,method))~="function"then return fail("event_api_unavailable","missing_"..method)end
    end
    local hidden,result=B.call(listener,"Show",false)
    if not hidden or result==false then return fail("listener_unavailable","hide_window")end
    if requested or not guard(ticket)then return fail("cancelled")end
    local created,diagnostic=pcall(Native.newResourceEventComparison,function()return guard(ticket)end,
      selfReference,B.member(reader,"observeMember"))
    if created and type(diagnostic)=="table" and diagnostic.contract==1
      and type(diagnostic.observe)=="function" and type(diagnostic.report)=="function" and type(diagnostic.stop)=="function"then collector=diagnostic end
    if not collector then return fail("collector_unavailable","collector_create")end
    if requested or not guard(ticket)then return fail("cancelled")end
    -- A setter may install before reporting failure. Revoke this listener's
    -- handler before hiding/releasing it, including partial registration rollback.
    needHandler=true
    local handler,set=B.call(listener,"SetHandler","OnEvent",function(_,event,a1,a2,a3,a4,a5,a6,a7,a8)
      onEvent(ticket,_,event,a1,a2,a3,a4,a5,a6,a7,a8)
    end)
    if not handler or set==false then return fail("registration_failed","attach_handler")end
    if requested or not guard(ticket)then return fail("cancelled")end
    -- Partial registration is rolled back by release/hide/free of the own window.
    for _,event in ipairs(EVENTS)do
      local registered,result=B.call(listener,"RegisterEvent",event)
      if not registered or result==false then return fail("registration_failed",event==EVENTS[1]and"register_health"or"register_mana")end
      if requested or not guard(ticket)then return fail("cancelled")end
    end
    deadline=now+180000;lastClock=now;state="collecting";reason="collecting";armed=true
    if not capture()then return fail("collector_failed","collector_report")end
    if requested or not guard(ticket)or not armed then return fail(requested or"cancelled")end
    busy=false;requested=nil;return true
  end
  function s.stop()
    if busy or dispatching then
      armed=false;requested="manual_stop"
      if collector then pcall(collector.stop)end
      return false
    end
    if not armed and not collector then
      busy=true;local good=detach();busy=false;return good
    end
    local current=host()
    return finish(current and"manual_stop"or"cancelled",not current)
  end
  function s.toggle()if armed then return s.stop()end;return s.start()end
  function s.tick()
    -- No cleanup retry loop: only active captures perform deadline work.
    if armed and not busy and not dispatching then checkDeadline()end
  end
  function s.close()
    closed=true
    if busy or dispatching then
      armed=false;requested="cancelled"
      if collector then pcall(collector.stop)end
      return false
    end
    if armed or collector then return finish("cancelled",true)end
    lastSummary=nil
    busy=true;local good=detach();busy=false;return good
  end
  local function refreshLifetime()
    if not closed and host()then return end
    if armed and not busy and not dispatching then finish("cancelled",true)
    else
      lastSummary=nil;state="cancelled";reason="cancelled"
      if armed or collector then
        armed=false;requested="cancelled"
        if collector then pcall(collector.stop)end
      end
    end
  end
  function s.report()
    refreshLifetime()
    local remaining=armed and deadline and lastClock and math.max(0,math.ceil((deadline-lastClock)/1000))or 0
    return {contract=1,state=state,reason=reason,stage=listener and not armed and(cleanupStage or stage)or stage,remainingSeconds=remaining,
      summary=lastSummary and copy(lastSummary)or nil,cleanupPending=listener~=nil and not armed}
  end
  function s.status()
    refreshLifetime()
    if listener and not armed then return "Raid data check: cleanup pending ["..detail(cleanupStage or stage).."]"end
    local health=lastSummary and lastSummary.events.health.count or 0
    local mana=lastSummary and lastSummary.events.mana.count or 0
    if armed then
      local remaining=deadline and lastClock and math.max(0,math.ceil((deadline-lastClock)/1000))or 0
      return string.format("Raid data check: %d health / %d mana (%d/64); %ds left",health,mana,health+mana,remaining)
    end
    if state=="complete"or state=="stopped"then
      local function outcome(topic,label)
        local row=lastSummary.events[topic]
        -- Equality buckets can overlap (numeric ID + exact token). Inconclusive
        -- events are therefore derived from distinct numeric-pair outcomes only.
        local unknown=row.count-row.numbersCurrentMax-row.numbersMaxCurrent-row.pairMismatch
        return string.format("%s%d/A%d tok%d id%d CM%d MC%d X%d ?%d",label,row.count,row.attempts,
          row.tokenEqual,row.idEqual,row.numbersCurrentMax,row.numbersMaxCurrent,row.pairMismatch,unknown)
      end
      return outcome("health","H").." | "..outcome("mana","M")
    end
    if state=="idle"then
      local unavailable=capabilityStage()
      if unavailable then return "Raid data check: unavailable ["..detail(unavailable).."]"end
      return "Raid data check: ready; anonymous self comparison only"
    end
    if state=="cancelled"then return "Raid data check: cancelled"end
    return "Raid data check: unavailable ["..detail(stage).."]"
  end
  return s
end
return P
