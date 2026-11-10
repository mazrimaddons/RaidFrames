-- Session-only observation recorder. No SDK, callbacks, clock, IO or targeting.
-- Lua 5.1 pairs projects raw literal fields; it never invokes __index/__pairs.
local M={contract=1,saveFormatContract=1,MAX_EVENTS=512,MAX_ALIASES=128,DURATION_MS=10000}
M.returnDiagnosticsContract=1
M.lateConfirmationContract=1
M.originAvailabilityContract=1
local kinds={"RETURN","ENTER","LEAVE","REQUEST","CALL_BEGIN","CALL_END","DECISION","SELECTED","TARGET_EVENT","NAME_BEGIN","NAME_END","POINTER"}
local allowed,fields={},{}
for i=1,#kinds do allowed[kinds[i]]=true end
local numbers={"entry","request","frame","depth"}
local flags={"painting","inside","dispatch","stable"}
for i=1,#numbers do fields[numbers[i]]=true end
for i=1,#flags do fields[flags[i]]=true end
for _,key in ipairs({"token","expected","actual","origin","wanted","x","y","result","targetType"})do fields[key]=true end
local results={}
results.RETURN_ORIGIN_UNAVAILABLE=true
results.STYLE_RETURNED=true
results.STYLE_FAILED=true
results.STYLE_UNAVAILABLE=true
results.RETURN_FRAME_QUEUED=true
results.LEVEL_RETURNED=true
results.LEVEL_FAILED=true
for _,key in ipairs({"RETURN_CAPTURED","RETURN_LATE_KNOWN","RETURN_QUEUED","RETURN_CONFIRM","RETURN_WAIT","RETURN_CANCEL_BEFORE","RETURN_CANCEL_OBSERVE","RETURN_CANCEL_EXPLICIT","RETURN_NO_ORIGIN","RETURN_PENDING_CALL","RETURN_TIMEOUT","RETURN_CHANGED_EXIT","RETURN_INVALID_ORIGIN","RETURN_REVOKED","RETURN_ALREADY_SELECTED","RETURN_SENT","RETURN_FAILED","RETURN_ID_UNKNOWN"})do results[key]=true end
for _,key in ipairs({"REQUESTED","CANCELLED","UNAVAILABLE","FAILED","OFFLINE","MEMBER_CHANGED","VALID","INVALID","ERROR","UNKNOWN","OBSERVED","UNSTABLE","MISSING","SPENT","BLOCKED","DISPATCH","MONITOR","READY","PENDING","REFRESHED","UNCONFIRMED","ALREADY_CURRENT","TARGET_OR_NAME_CHANGED","IDLE","TRUE","FALSE","NIL","OK","DISABLED","NAME_REFRESH_OFF","NAME_REFRESH_ON"})do results[key]=true end
local reasons={manual=true,timeout=true,clock_invalid=true,clock_backwards=true,hidden=true,closed=true,stopped=true,error=true,replaced=true}
local targetTypes={target=true,watchtarget=true,targettarget=true,player=true,unknown=true}
local function finite(v)return type(v)=="number"and v==v and v>-1/0 and v<1/0 end
local function time(v)return finite(v)and v>=0 and v<=9007199254740991 end
local function whole(v)return finite(v)and v>=0 and v<=1000000000 and v%1==0 end
local function identity(v)
  if type(v)=="string"then return #v>0 and #v<=128 and not v:find("%c")and not v:match("^%s*$")end
  return finite(v)and v>0 and v<=9007199254740991 and v%1==0
end
local function token(v)
  if type(v)~="string"then return false end
  for i=1,50 do if v=="team"..i then return true end end
  return false
end
local function version(v)
  return type(v)=="string"and #v<=24 and v:match("^%d+%.%d+%.%d+$")and v or"unknown"
end
function M.new(build)
  local s={contract=1,saveFormatContract=1}
  local closed,active,disabled=false,false,false
  local serial,started,finished,last,reason=0,nil,nil,nil,"stopped"
  local events,head,size,sequence={},1,0,0
  local strings,numbersMap,aliasCount={}, {},0
  local counts,stats={},{}
  local saved,saveFailed=false,false
  local selectedKey,pointerKey=nil,nil
  local buildVersion=version(build)
  local function finish(why)
    if not active then return false end
    active=false;finished=last;reason=reasons[why]and why or"stopped"
    -- Aliases are already baked into strings. Drop all retained raw identities.
    strings={};numbersMap={};selectedKey=nil;pointerKey=nil
    return true
  end
  local function alias(v)
    if not identity(v)then return"?"end
    local isString=type(v)=="string"
    local map=isString and strings or numbersMap
    if map[v]then return map[v]end
    if aliasCount>=M.MAX_ALIASES then
      stats.aliasOverflow=stats.aliasOverflow+1;return isString and"S?"or"N?"
    end
    aliasCount=aliasCount+1
    local value=(isString and"S"or"N")..string.format("%d",aliasCount)
    map[v]=value;return value
  end
  local function project(data)
    if data==nil then return{}end
    if type(data)~="table"then return nil end
    local out,n={},0
    -- Lua 5.1 pairs reads table storage, not SDK getters or user metamethods.
    for key,value in pairs(data)do
      n=n+1;if n>32 then return nil end
      if fields[key]then out[key]=value end
    end
    return out
  end
  local function append(kind,data)
    if type(kind)~="string"or not allowed[kind]then stats.rejected=stats.rejected+1;return false end
    local d=project(data)
    if not d then stats.rejected=stats.rejected+1;return false end
    local stable=type(d.stable)=="boolean"and d.stable or false
    if kind=="SELECTED"then
      -- Deduplicate by exact typed input, not the capacity-limited alias.
      local actual=identity(d.actual)and d.actual or false
      if selectedKey and selectedKey.actual==actual and selectedKey.stable==stable then
        stats.duplicates=stats.duplicates+1;return false
      end
      selectedKey={actual=actual,stable=stable}
    elseif kind=="POINTER"then
      if pointerKey and pointerKey.x==d.x and pointerKey.y==d.y and pointerKey.entry==d.entry
        and pointerKey.inside==d.inside then stats.duplicates=stats.duplicates+1;return false end
      pointerKey={x=finite(d.x)and d.x or false,y=finite(d.y)and d.y or false,
        entry=whole(d.entry)and d.entry or false,inside=d.inside==true}
    end
    sequence=sequence+1
    local line=string.format("%d t=%.3f %s",sequence,last,kind)
    for i=1,#numbers do local key=numbers[i];if whole(d[key])then line=line.." "..key.."="..string.format("%d",d[key])end end
    if token(d.token)then line=line.." token="..d.token end
    if d.expected~=nil then line=line.." expected="..alias(d.expected)end
    if d.actual~=nil or kind=="SELECTED"then line=line.." actual="..alias(d.actual)end
    for _,key in ipairs({"origin","wanted"})do if d[key]~=nil then line=line.." "..key.."="..alias(d[key])end end
    for _,key in ipairs({"x","y"})do if finite(d[key])then line=line.." "..key.."="..string.format("%.6g",d[key])end end
    for i=1,#flags do local key=flags[i];if type(d[key])=="boolean"then line=line.." "..key.."="..(d[key]and"1"or"0")end end
    if type(d.result)=="string"and results[d.result]then line=line.." result="..d.result end
    if type(d.targetType)=="string"and targetTypes[d.targetType]then line=line.." targetType="..d.targetType end
    if size<M.MAX_EVENTS then
      local index=(head+size-1)%M.MAX_EVENTS+1;events[index]=line;size=size+1
    else events[head]=line;head=head%M.MAX_EVENTS+1;stats.dropped=stats.dropped+1 end
    counts[kind]=(counts[kind]or 0)+1;stats.recorded=stats.recorded+1
    return true
  end
  function s.start(now)
    if closed or disabled or active or(serial>0 and not saved)or not time(now)then return false end
    serial=serial+1;started=now;last=now;finished=nil;reason="stopped"
    events={};head=1;size=0;sequence=0;strings={};numbersMap={};aliasCount=0;counts={}
    stats={recorded=0,dropped=0,aliasOverflow=0,duplicates=0,rejected=0}
    selectedKey=nil;pointerKey=nil;saved=false;saveFailed=false;active=true;return true
  end
  function s.clock(now)
    if closed or not active then return false end
    if not time(now)then finish("clock_invalid");return false end
    if now<last then finish("clock_backwards");return false end
    last=math.min(now,started+M.DURATION_MS)
    if now-started>=M.DURATION_MS then finish("timeout");return false end
    return true
  end
  function s.record(kind,data)
    if closed or disabled or not active then return false end
    local ok,value=pcall(append,kind,data)
    if not ok then disabled=true;finish("error");return false end
    return value==true
  end
  function s.stop(why)if closed then return false end;return finish(why)end
  function s.isActive()return not closed and active end
  function s.needsSave()return serial>0 and not active and not saved end
  function s.captureId()return serial>0 and serial or nil end
  function s.acknowledge(id,ok)
    if id~=serial or serial==0 or active or type(ok)~="boolean"then return false end
    if ok then saved=true;saveFailed=false else saveFailed=true end
    return ok
  end
  function s.export()
    if serial==0 then return nil end
    local list,totals={},{}
    for i=1,size do list[i]=events[(head+i-2)%M.MAX_EVENTS+1]end
    for i=1,#kinds do local key=kinds[i];totals[key]=counts[key]or 0 end
    -- Native api.lua77-117 emits identifier-shaped keys bare (including Lua
    -- reserved words) and numbers through tostring. Use a safe field name and
    -- decimal strings so native number formatting cannot round UI timestamps.
    return {schema=1,version=buildVersion,capture=serial,start=string.format("%.3f",started),
      finished=finished and string.format("%.3f",finished)or nil,
      reason=active and"recording"or reason,events=list,
      stats={recorded=stats.recorded,kept=size,dropped=stats.dropped,aliases=aliasCount,
        aliasOverflow=stats.aliasOverflow,duplicates=stats.duplicates,rejected=stats.rejected,counts=totals}}
  end
  function s.summary()
    if serial==0 then return"Target trace: off"end
    if active then return string.format("Recording target trace (%d s left).",math.ceil((started+M.DURATION_MS-last)/1000))end
    if saveFailed and not saved then return"Target trace save failed; retry available."end
    if saved then return string.format("Target trace saved: %d events.",stats.recorded)end
    return string.format("Target trace ready: %d events, %d dropped.",stats.recorded,stats.dropped)
  end
  function s.close()
    if closed then return true end
    finish("closed");closed=true;strings={};numbersMap={};selectedKey=nil;pointerKey=nil;return true
  end
  return s
end
return M
