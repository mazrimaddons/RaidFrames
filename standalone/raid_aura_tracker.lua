-- Experimental frontend orchestration. The shared reader owns all aura reads.
local W=require("Mazrim_Raid_Frames/shared/watchlist")
local I=require("Mazrim_Raid_Frames/shared/identity")
local T={coverageContract=1,contract=1,configurationRevisionContract=1}
local function numeric(id)
  local n=0;for i=1,#id do n=n*10+string.byte(id,i)-48 end;return n
end
local function selection(options)
  local ids,seen={},{}
  local function add(id)
    id=W.id(id);if not id or seen[id]then return end
    seen[id]=true;ids[#ids+1]=id
  end
  -- Alerts get admission first when the legacy independent maps exceed64 IDs.
  local function sorted(map,rules)
    local list={}
    for id,v in pairs(map)do if not rules or v.enabled then list[#list+1]=id end end
    for i=2,#list do local v=list[i];local j=i;while j>1 and numeric(list[j-1])>numeric(v)do list[j]=list[j-1];j=j-1 end;list[j]=v end
    for _,id in ipairs(list)do add(id)end
  end
  sorted(options.alerts);sorted(options.watch);sorted(options.frame_rules,true)
  local key=options.large_alerts and"alerts_on"or"alerts_off"
  local result={};local capped=#ids>64
  for i=1,math.min(64,#ids)do result[i]=numeric(ids[i]);key=key..":"..ids[i]end
  local alertIDs={};for id in pairs(options.alerts)do alertIDs[#alertIDs+1]=id end
  for i=2,#alertIDs do local v=alertIDs[i];local j=i;while j>1 and alertIDs[j-1]>v do alertIDs[j]=alertIDs[j-1];j=j-1 end;alertIDs[j]=v end
  for _,id in ipairs(alertIDs)do key=key.."a"..id end
  return result,key,capped
end
function T.new(reader,provider,alive,blockDiagnostic)
  local rotating=type(reader)=="table"and reader.raidAuraCoverageContract==1
  local s={coverageContract=rotating and 1 or 0,contract=1,configurationRevisionContract=1,status="Experimental tracker off"}
  local service,enabled,closed,busy,key,dirty,failed=nil,false,false,false,nil,false,false
  local capped=false
  local snapshot=W.revisionSnapshot();local cachedOptions,cachedIDs,cachedKey,cachedLimited
  local function selected(options,changed)
    if not changed and options==cachedOptions then return cachedIDs,cachedKey,cachedLimited end
    cachedIDs,cachedKey,cachedLimited=selection(options);cachedOptions=options
    return cachedIDs,cachedKey,cachedLimited
  end
  local function current()
    if closed or not enabled then return false end
    local ok,v=pcall(alive);return ok and v==true and not closed and enabled
  end
  local function block(value)if type(blockDiagnostic)=="function"then pcall(blockDiagnostic,value)end end
  local function stop()
    enabled=false
    if not service then block(false);return true end
    local ok,v=pcall(service.stop)
    if not ok or v~=true then s.status="Tracker cleanup pending: restart required";block(true);return false end
    service=nil;block(false);return true
  end
  function s.configure(options,revision)
    if closed then return false end
    local changed;options,changed=snapshot(options,revision);if not options then return false end
    if busy then
      if not options.raid_tracker then enabled=false;dirty=true end
      return false
    end
    if not options.raid_tracker then failed=false;key=nil;dirty=false;s.status="Experimental tracker off";stop();return false end
    local ids,nextKey,limited=selected(options,changed);capped=limited
    if failed then return false end
    if service and key==nextKey and not dirty then return enabled end
    if not stop()then failed=true;return false end
    key=nextKey;dirty=false
    if #ids==0 then s.status="Select icons, frame rules or alert IDs to track";return false end
    if type(reader)~="table"or reader.raidAuraObserverContract~=1 or type(reader.newRaidAuraObserver)~="function"then
      s.status="Experimental raid reader unavailable";failed=true;return false
    end
    local ok,v=pcall(reader.newRaidAuraObserver,provider)
    if not ok or type(v)~="table"or v.contract~=1 then failed=true;return false end
    service=v;enabled=true
    local started,yes=pcall(service.start,ids,current,rotating and{contract=1,coverage="rotating"}or nil)
    if not started or yes~=true then stop();failed=true;s.status="Experimental reader could not start";return false end
    block(true);s.status="Experimental polling: coverage and freshness unknown";return true
  end
  function s.step(rows,budget)
    if busy or not current()or not service then return{samples={}}end
    local actors={}
    for _,row in ipairs(rows or{})do
      if row.kind=="raid"and I.accepts(row.identity)then actors[#actors+1]={token=row.token,identity=row.identity}end
    end
    busy=true
    local ok,r=pcall(rotating and service.stepRotating or service.step,actors,budget)
    busy=false
    if not current()then return{samples={}}end
    if not ok or type(r)~="table"then failed=true;stop();s.status="Experimental reader failed";return{samples={}}end
    if r.cleanupPending then failed=true;enabled=false;block(true);s.status="Tracker cleanup pending: restart required";return{samples={}}end
    local reported,health=pcall(service.report)
    if not reported or type(health)~="table"or health.enabled~=true then
      failed=true;enabled=false;block(type(health)=="table"and health.cleanupPending==true)
      s.status="Experimental reader stopped: toggle off/on or reset to restart";return{samples={}}
    end
    local f=type(budget)=="table"and budget.filteredLimit or 1
    local visits=f and f>0 and math.ceil(#actors/math.max(1,math.min(f,#actors)))*0.25 or nil
    s.status="Rotating: "..#actors.." identified members; revisit "..(visits and string.format("%.2f",visits).."s or longer"or"waiting for budget").."; 8 entries/visit"
    if r.truncated then s.status=s.status.."; dense lists take more visits"end
    s.status=s.status.."; last: "..(r.reason or r.state or"unknown")
    if r.latchLimitReached then s.status="Experimental alert history full: reset session to admit newcomers"end
    if capped then s.status="Experimental: first64 selected IDs only"end
    if r.infoKnown~=true or not I.accepts(r.identity)then return{raw=r,samples={}}end
    local debuffs={}
    for _,e in ipairs(r.entries or{})do
      local item={id=e.id,name="Effect "..string.format("%.0f",e.id)}
      if e.iconKnown then item.icon=e.iconPath end
      if e.remainingMsKnown then item.timeKnown=true;item.remainingMs=e.remainingMs end
      if e.stacksKnown then item.stacksKnown=true;item.stacks=e.stacks end
      debuffs[#debuffs+1]=item
    end
    return{raw=r,samples={{contract=1,identity=r.identity,token=r.token,origin=r.token,channel="raid_filtered",coverage="observed",
      buffsKnown=false,buffs={},debuffsKnown=true,debuffs=debuffs,buffsComplete=false,debuffsComplete=false}}}
  end
  function s.reset()
    if busy then enabled=false;dirty=true;return false end
    if not stop()then failed=true;return false end
    key=nil;dirty=true;failed=false;return true
  end
  function s.report()
    local report={coverageContract=s.coverageContract,enabled=enabled,status=s.status,cleanupPending=false,selectionTruncated=capped}
    if service then local ok,r=pcall(service.report);if ok and type(r)=="table"then report.cleanupPending=r.cleanupPending==true;report.filteredUnitCalls=r.unitGetterCallsTotal;report.filteredClockCalls=r.clockCallsTotal;report.filteredPublicAttempts=r.totalPublicAttemptsTotal end end
    return report
  end
  function s.close()closed=true;return stop()end
  return s
end
return T
