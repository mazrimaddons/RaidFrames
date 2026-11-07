-- Read-only actual-target identity. It neither selects nor infers a member.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local I=require("Mazrim_Raid_Frames/shared/identity")
local M={contract=1}
function M.new(api,alive)
  local s={contract=1};local closed=false
  local function current()
    if closed or type(alive)~="function"then return false end
    local ok,v=pcall(alive);return ok and v==true and not closed
  end
  function s.identity()
    if not current()then return nil end
    local unit=B.member(api,"Unit")
    local a,id=B.call(unit,"GetUnitId","target")
    if not current()or not a or not I.accepts(id)then return nil end
    local b,after=B.call(unit,"GetUnitId","target")
    if current()and b and id==after then return id end
  end
  function s.close()closed=true;return true end
  return s
end
return M
