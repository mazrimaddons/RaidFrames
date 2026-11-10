-- Opt-in return to a previously selected RAID MEMBER, never arbitrary IDs.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local I=require("Mazrim_Raid_Frames/shared/identity")
local M={contract=2,MAX_PENDING_READS=10,MAX_PENDING_IDENTITIES=50}
M.returnDiagnosticsContract=1
M.lateConfirmationContract=1
M.originAvailabilityContract=1
M.frameFeedbackContract=1
local function rowFor(rows,id)
  local found
  for _,r in ipairs(rows or{})do
    if r.kind=="raid"and r.identity==id then
      if found then return nil end
      for i=1,50 do if r.token=="team"..i then found=r;break end end
    end
  end
  return found
end
function M.new(api,reader,alive,trace,frameFeedback)
  local s={contract=2,status="Return target off"};local session,closed,generation=nil,false,0
  local record=type(trace)=="table"and trace.contract==1 and type(trace.record)=="function"and trace.record or nil
  local function mark(result,actual,ticket,token)
    if not record then return end
    local t=ticket or session
    local ok=pcall(record,"RETURN",{request=generation,result=result,actual=actual or false,
      origin=t and t.origin or false,wanted=t and t.wanted or false,token=token,
      frame=t and t.waits or 0})
    if not ok then record=nil end
  end
  local function current(guard)
    if closed then return false end
    local ok,v=pcall(alive);if not ok or v~=true or closed then return false end
    if guard then local a,b=pcall(guard);if not a or b~=true then return false end end
    return not closed
  end
  local function selected(guard)
    if not current(guard)then return nil end
    local ok,id=B.call(B.member(api,"Unit"),"GetUnitId","target")
    if not ok or not I.accepts(id)or not current(guard)then return nil end
    local again,other=B.call(B.member(api,"Unit"),"GetUnitId","target")
    if again and other==id and current(guard)then return id end
  end
  function s.cancel()
    if session then mark("RETURN_CANCEL_EXPLICIT")end
    generation=generation+1;session=nil;s.status="Return cancelled"
  end
  function s.before(rows,id,guard)
    generation=generation+1;local stamp=generation
    if not current(guard)then s.cancel();return end
    if not session then
      local previous=selected(guard)
      local origin=previous and rowFor(rows,previous)
      if generation~=stamp or not current(guard)then return end
      local inflight={};local count=0
      if I.accepts(previous)then inflight[previous]=true;count=1 end
      session={origin=origin and previous or nil,wanted=previous,inflight=inflight,count=count,waits=0}
      s.status=origin and"Previous raid target retained"or"Previous target is not a known raid member"
      mark("RETURN_CAPTURED",previous,session,origin and origin.token)
    else
      local actual=selected(guard)
      if generation~=stamp or not current(guard)then return end
      if actual~=session.wanted and not session.inflight[actual]then
        mark("RETURN_CANCEL_BEFORE",actual)
        session.origin=nil;s.status="Target changed; return cancelled"
      end
    end
    if not I.accepts(id)then s.cancel();return end
    if not session.inflight[id]then
      if session.count>=M.MAX_PENDING_IDENTITIES then s.cancel();return end
      session.inflight[id]=true;session.count=session.count+1
    end
    session.wanted=id;session.pending=true;session.requested=false;session.waits=0;return stamp
  end
  function s.after(id,requested,stamp)
    if generation~=stamp or not session or session.wanted~=id then return end
    if requested~=true then s.cancel();return end
    -- Returning from TargetUnit acknowledges the request, not its application.
    -- A synchronous observation may already have confirmed it; do not reset it.
    session.requested=true
    mark("RETURN_QUEUED")
  end
  function s.observe(id)
    if session and(not session.observed or session.lastObserved~=id)then
      session.observed=true;session.lastObserved=id
      mark(not I.accepts(id)and"RETURN_ID_UNKNOWN"or id==session.wanted and"RETURN_CONFIRM"or"RETURN_WAIT",id)
    end
    if session and I.accepts(id)then
      if id==session.wanted then
        session.pending=false
      elseif session.inflight[id]then
        -- An immediate local selection can be followed by an older expected
        -- identity. Confirmation of the newest ID does not retire that history.
        if not session.pending then mark("RETURN_LATE_KNOWN",id)end
        session.pending=true
      else
        mark("RETURN_CANCEL_OBSERVE",id)
        generation=generation+1;session.origin=nil;session.pending=false;s.status="Target changed; return cancelled"
      end
    end
  end
  function s.finish(rows,outside)
    local ticket=session;local stamp=generation
    if not ticket then return false end
    if not current(outside)then return false end
    if not ticket.origin then mark("RETURN_NO_ORIGIN",nil,ticket);session=nil;return false end
    if not ticket.requested then mark("RETURN_PENDING_CALL",nil,ticket);return false end
    local actual=selected(outside)
    if session~=ticket or generation~=stamp or not current(outside)then return false end
    if actual~=ticket.wanted then
      if ticket.requested and ticket.inflight[actual]then
        -- The existing driver calls this at most once per 100ms. Wait only for
        -- the final requested identity, with no new job or targeting retries.
        ticket.waits=ticket.waits+1
        if ticket.waits==1 then mark("RETURN_WAIT",actual,ticket)end
        if ticket.waits>=M.MAX_PENDING_READS then mark("RETURN_TIMEOUT",actual,ticket);session=nil;s.status="Return skipped: target not confirmed"end
      else mark("RETURN_CHANGED_EXIT",actual,ticket);session=nil;s.status="Return skipped: target/member changed"end
      return false
    end
    session=nil -- one attempt, consumed before native callbacks
    if ticket.origin==ticket.wanted then mark("RETURN_ALREADY_SELECTED",actual,ticket);return false end
    local row=rowFor(rows,ticket.origin)
    if not row then mark("RETURN_INVALID_ORIGIN",actual,ticket);s.status="Return skipped: target/member changed";return false end
    local function guard()return generation==stamp and current(outside) and generation==stamp end
    local ok,r=pcall(reader.validateTarget,row.token,ticket.origin,guard)
    if not ok or type(r)~="table"or r.contract~=1 or r.state~="valid"or r.token~=row.token or not guard()then mark("RETURN_INVALID_ORIGIN",actual,ticket,row.token);return false end
    -- A team token/identity can survive the actor unloading. Reuse the shared
    -- member reader once at exit; unknown HP is a reason to SKIP, not proof of
    -- distance or death. Never use cached row resources or screen projection.
    local observe=B.member(reader,"observeMember")
    local observed,member=false,nil
    if type(observe)=="function"then observed,member=pcall(observe,row.token,guard)end
    if not guard()then mark("RETURN_REVOKED",actual,ticket,row.token);return false end
    local available=observed and type(member)=="table"and member.contract==1
      and member.state=="partial"and member.clear==false and member.token==row.token
      and member.identity==ticket.origin and member.hpKnown==true
      and B.finite(member.hp)and B.finite(member.maxHp)
      and member.hp>=0 and member.maxHp>0 and member.maxHp<=1000000000 and member.hp<=member.maxHp
    if not available then
      mark("RETURN_ORIGIN_UNAVAILABLE",actual,ticket,row.token)
      s.status="Return skipped: original player unavailable; keeping hovered target"
      return false
    end
    local verified=selected(outside)
    if verified~=ticket.wanted then mark("RETURN_CHANGED_EXIT",verified,ticket,row.token);return false end
    local unit=B.member(api,"Unit");local fn=B.member(unit,"TargetUnit")
    if type(fn)~="function"or not guard()then mark("RETURN_REVOKED",verified,ticket,row.token);return false end
    local sent,value=pcall(fn,unit,row.token)
    local requested=sent and value~=false
    mark(requested and"RETURN_SENT"or"RETURN_FAILED",verified,ticket,row.token)
    if requested and type(frameFeedback)=="function"then
      local name=member.nameKnown==true and member.name or row.nameKnown==true and row.name or nil
      local function feedbackCurrent()
        return generation==stamp and current() and generation==stamp
      end
      pcall(frameFeedback,row.token,ticket.origin,name,feedbackCurrent)
    end
    if generation==stamp then s.status=requested and"Previous raid target requested"or"Return request failed"end
    return requested
  end
  function s.active()return not closed and session~=nil end
  function s.close()closed=true;s.cancel();return true end
  return s
end
return M
