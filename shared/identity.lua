-- Exact opaque identity predicate from the existing RC06 coverage boundary.
-- Shared validation only: no discovery, member reads, identity inference or cache.
local M={}
function M.accepts(v)
  if type(v)=="string" then
    return #v>0 and #v<=128 and not v:find("%c") and not v:match("^%s*$")
  end
  return type(v)=="number" and v==v and v>0 and v<=9007199254740991 and v==math.floor(v)
end
return M
