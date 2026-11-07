-- Frontend orchestration only; the shared reader owns every unit/aura read.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local Provider=require("Mazrim_Raid_Frames/standalone/raid_aura_provider")
local C={contract=1}
function C.new(api,reader,alive,factory,suppliedProvider)
  local provider=suppliedProvider or Provider.new(api,factory,alive)
  local blocked=false
  local diagnostic,closed,used,running=nil,false,false,false
  local s={contract=1}
  local function current()
    if closed then return false end
    local ok,v=pcall(alive);return ok and v==true and not closed
  end
  local function make()
    if not current()or type(reader)~="table"or reader.raidAuraDiagnosticContract~=1
      or type(reader.newRaidAuraDiagnostic)~="function"then return false end
    local ok,d=pcall(reader.newRaidAuraDiagnostic,provider)
    if not ok or type(d)~="table"or d.contract~=1 then return false end
    diagnostic=d;used=false;return true
  end
  function s.setBlocked(value)blocked=value==true end
  function s.available()return not blocked and current()and provider.available()and reader.raidAuraDiagnosticContract==1 end
  function s.report()
    if diagnostic then local ok,r=pcall(diagnostic.report);if ok and type(r)=="table"then return r end end
    return {contract=1,state="unavailable",reason="provider_unavailable",entries={},infoKnown=false}
  end
  function s.capture(token,id,requestAlive)
    if running then return s.report(),false end
    if not s.available()or type(requestAlive)~="function"then return s.report(),false end
    if s.report().cleanupPending==true then return s.report(),false end
    if(not diagnostic or used)and not make()then return s.report(),false end
    local function active()
      if not current()then return false end
      local ok,v=pcall(requestAlive);return ok and v==true and current()
    end
    if not active()then return s.report(),false end
    used=true;running=true
    local ok,r=pcall(diagnostic.run,token,id,active)
    running=false
    if not ok then pcall(diagnostic.stop)end
    return s.report(),true
  end
  function s.stop()
    if not diagnostic then return true end
    local ok,v=pcall(diagnostic.stop);return ok and v==true
  end
  function s.retryCleanup()
    if not diagnostic then return provider.release()end
    local ok,v=pcall(diagnostic.retryCleanup);return ok and v==true
  end
  function s.close()
    closed=true
    local stopped=s.stop();local released=provider.close()
    return stopped and released
  end
  make() -- pure shared controller; no provider acquisition or native calls
  return s
end
return C
