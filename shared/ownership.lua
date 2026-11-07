-- HQ-agreed first-party API-table lease, not an exported native game service.
-- Claim before acquiring widgets/jobs. Revoke host callbacks before release;
-- cleanupSucceeded must cover ALL owned resources. Failed cleanup keeps lease.
local M={contract=1}
function M.new(api,packageName)
  local lease=nil
  local busy=false
  local s={contract=1}
  local valid=packageName=="standalone" or packageName=="public"
  local function read()
    return pcall(function()return api._MazrimRaidFramesOwner end)
  end
  function s.claim()
    if not valid then return false,"invalid_package" end
    if busy then return false,"busy" end
    busy=true
    local ok,current=read()
    if not ok then busy=false;return false,"ownership_unavailable" end
    if lease then busy=false;return current==lease,"ownership_changed" end
    if current~=nil then busy=false;return false,"already_owned" end
    local proposed={contract=1,package=packageName}
    -- Record ownership before writing so an uncertain write stays recoverable.
    lease=proposed
    local written=pcall(function()api._MazrimRaidFramesOwner=proposed end)
    local checked,after=read()
    busy=false
    if not checked or after~=lease then return false,"ownership_unavailable" end
    return true
  end
  function s.current()
    if busy or not lease then return false end
    busy=true;local ok,current=read();busy=false
    return ok and current==lease
  end
  function s.release(cleanupSucceeded)
    if busy then return false,"busy" end
    if cleanupSucceeded~=true then return false,"cleanup_pending" end
    if not lease then return true end
    busy=true
    local ok,current=read()
    if not ok then busy=false;return false,"ownership_unavailable" end
    if current==nil then lease=nil;busy=false;return true end
    if current~=lease then
      busy=false;return false,"ownership_changed"
    end
    local cleared=pcall(function()api._MazrimRaidFramesOwner=nil end)
    local checked,after=read()
    busy=false
    if not checked or after~=nil then return false,"ownership_unavailable" end
    lease=nil;return true
  end
  return s
end
return M
