-- Exact native Options route; no small-frame lookup or toggle replay.
-- Cached native-manager/manager_view.lua46-47 stores raidOptionFrame;
-- option_window_view.lua66-69 stores invisibleRaidFrameCheckBox;
-- option_window.lua32-38 assigns CheckBtnCheckChagnedProc(self,visible),
-- which calls X2Team:SetRaidFrameVisible(visible). The spelling is native.
-- raidframe.lua291-294 restores this engine preference on LEFT_LOADING;
-- hiding only the current widget/hotkey does not change that preference.
-- A completed callback is a request, never an observed visibility result.
local M={contract=1}
local function object(value)return type(value)=="table"or type(value)=="userdata"end
function M.new(addon,managerId,alive)
 local s={contract=1,status="unavailable"};local closed,generation=false,0
 local function current(stamp)
  if closed or generation~=stamp or type(alive)~="function"then return false,"unavailable"end
  local ok,value=pcall(alive)
  if not ok then return false,"failed"end
  if value~=true or closed or generation~=stamp then return false,"unavailable"end
  return true
 end
 -- Preserve thrown versus missing fields; Bridge.member normally swallows
 -- getter errors. Each native/metatable read is separately protected here.
 local function member(parent,key,stamp)
  local live,why=current(stamp);if not live then return nil,why end
  if not object(parent)then return nil,"unavailable"end
  local ok,value=pcall(function()return parent[key]end)
  live,why=current(stamp);if not live then return nil,why end
  if not ok then return nil,"failed"end
  if value==nil then return nil,"unavailable"end
  return value
 end
 local function acquire(stamp)
  local getContent,why=member(addon,"GetContent",stamp)
  if type(getContent)~="function"then return nil,why or"unavailable"end
  local live;live,why=current(stamp);if not live then return nil,why end
  local ok,manager=pcall(getContent,addon,managerId)
  live,why=current(stamp);if not live then return nil,why end
  if not ok then return nil,"failed"end
  if not object(manager)then return nil,"unavailable"end
  local options;options,why=member(manager,"raidOptionFrame",stamp)
  if not object(options)then return nil,why or"unavailable"end
  local checkbox;checkbox,why=member(options,"invisibleRaidFrameCheckBox",stamp)
  if not object(checkbox)then return nil,why or"unavailable"end
  local proc;proc,why=member(checkbox,"CheckBtnCheckChagnedProc",stamp)
  if type(proc)~="function"then return nil,why or"unavailable"end
  return {manager=manager,options=options,checkbox=checkbox,proc=proc}
 end
 local function finish(why)s.status=why or"unavailable";return false,s.status end
 function s.setVisible(desired)
  if type(desired)~="boolean"or type(managerId)~="number"or managerId~=managerId
   or managerId<=0 or managerId>=1/0 or managerId%1~=0 then return finish("unavailable")end
  generation=generation+1;local stamp=generation
  local first,why=acquire(stamp);if not first then return finish(why)end
  -- Reacquire instead of caching a native handle across portal/reload or even
  -- across getter callbacks. GetContent itself may return a fresh proxy method.
  local again;again,why=acquire(stamp);if not again then return finish(why)end
  local compared,matches=pcall(function()
   return again.manager==first.manager and again.options==first.options
    and again.checkbox==first.checkbox and again.proc==first.proc
  end)
  if not compared then return finish("failed")end
  if not matches then return finish("unavailable")end
  local live;live,why=current(stamp);if not live then return finish(why)end
  local ok,value=pcall(again.proc,again.checkbox,desired)
  live,why=current(stamp);if not live then return finish(why)end
  if not ok or value==false then return finish("failed")end
  s.status="requested";return true,s.status
 end
 function s.close()closed=true;generation=generation+1;s.status="unavailable"end
 return s
end
return M
