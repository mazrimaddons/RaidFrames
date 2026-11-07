-- Opt-in return to a previously selected RAID MEMBER, never arbitrary IDs.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local I=require("Mazrim_Raid_Frames/shared/identity")
local M={contract=1}
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
function M.new(api,reader,alive)
  local s={contract=1,status="Return target off"};local session,closed,generation=nil,false,0
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
  function s.cancel()generation=generation+1;session=nil;s.status="Return cancelled"end
  function s.before(rows,id,guard)
    generation=generation+1;local stamp=generation
    if not current(guard)then s.cancel();return end
    if not session then
      local previous=selected(guard)
      local origin=previous and rowFor(rows,previous)
      if generation~=stamp or not current(guard)then return end
      session={origin=origin and previous or nil,wanted=previous}
      s.status=origin and"Previous raid target retained"or"Previous target is not a known raid member"
    else
      local actual=selected(guard)
      if generation~=stamp or not current(guard)then return end
      if actual~=session.wanted then
        session.origin=nil;s.status="Target changed; return cancelled"
      end
    end
    session.pendingFrom=session.wanted;session.wanted=id;session.pending=true;return stamp
  end
  function s.after(id,requested,stamp)
    if generation~=stamp or not session or session.wanted~=id then return end
    session.pending=false
    if requested~=true then s.cancel()end
  end
  function s.observe(id)
    if session and I.accepts(id)and id~=session.wanted and(not session.pending or id~=session.pendingFrom)then
      generation=generation+1;session.origin=nil;session.pending=false;s.status="Target changed; return cancelled"
    end
  end
  function s.finish(rows,outside)
    local ticket=session;local stamp=generation
    if not ticket or ticket.pending then return false end
    if not current(outside)then return false end
    session=nil -- one attempt, consumed before native callbacks
    if not ticket.origin or ticket.origin==ticket.wanted then return false end
    local row=rowFor(rows,ticket.origin)
    if not row or selected(outside)~=ticket.wanted then s.status="Return skipped: target/member changed";return false end
    local function guard()return generation==stamp and current(outside)end
    local ok,r=pcall(reader.validateTarget,row.token,ticket.origin,guard)
    if not ok or type(r)~="table"or r.contract~=1 or r.state~="valid"or r.token~=row.token or not guard()then return false end
    if selected(outside)~=ticket.wanted then return false end
    local unit=B.member(api,"Unit");local fn=B.member(unit,"TargetUnit")
    if type(fn)~="function"or not guard()then return false end
    local sent,value=pcall(fn,unit,row.token)
    s.status=sent and value~=false and"Previous raid target requested"or"Return request failed"
    return sent and value~=false
  end
  function s.active()return not closed and session~=nil end
  function s.close()closed=true;s.cancel();return true end
  return s
end
return M
