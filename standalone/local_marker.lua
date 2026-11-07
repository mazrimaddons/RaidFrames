-- Local screen projections keyed by accepted raid identity. No marker writes.
local I = require("Mazrim_Raid_Frames/shared/identity")
local M = {contract = 1, multiMarkerContract = 1, MAX_MARKERS = 50}
local MAX_PER_FRAME, SINGLE_POINT_MS, MULTI_POINT_MS = 4, 350, 750
local symbols = {star=true, heart=true, diamond=true, cross=true, circle=true, triangle=true}
local tokens = {}
for slot = 1, 50 do tokens["team" .. slot] = true end

local function finite(value)
  return type(value) == "number" and value == value and value >= 0 and value < 1/0
end

local function indexRows(rows)
  local byIdentity, byToken = {}, {}
  if type(rows) ~= "table" or #rows > 50 then return byIdentity end
  for _, row in ipairs(rows) do
    if type(row) == "table" and row.kind == "raid" and I.accepts(row.identity) then
      local identity, token = row.identity, row.token
      if byIdentity[identity] == nil then
        byIdentity[identity] = tokens[token] and row or false
      else
        byIdentity[identity] = false
      end
      if tokens[token] then
        local prior = byToken[token]
        if prior and prior ~= identity then
          byIdentity[prior], byIdentity[identity] = false, false
        else
          byToken[token] = identity
        end
      end
    end
  end
  return byIdentity
end

local function visibleRow(row)
  return row and not (row.offlineKnown == true and row.offline == true)
end

function M.new(reader, alive)
  local s = {contract = 1, multiMarkerContract = 1, status = "No local marker"}
  local marks, order = {}, {}
  local cursor, revision = 1, 0
  local closed, busy = false, false
  local lastStep, lastFrame, lastNow, lastWidth, lastHeight

  local function current(ticket, guard)
    if closed or revision ~= ticket then return false end
    local ok, value = pcall(alive)
    if not ok or value ~= true or closed or revision ~= ticket then return false end
    if guard then
      local safe, valid = pcall(guard)
      if not safe or valid ~= true then return false end
    end
    return not closed and revision == ticket
  end

  local function updateStatus()
    s.status = #order > 0 and ("Local symbols: " .. #order .. " marked") or "No local marker"
  end

  local function remove(identity)
    if not marks[identity] then return false end
    marks[identity] = nil
    for index, existing in ipairs(order) do
      if existing == identity then
        for nextIndex = index, #order - 1 do order[nextIndex] = order[nextIndex + 1] end
        order[#order] = nil
        if index < cursor then cursor = cursor - 1 end
        if cursor > #order then cursor = 1 end
        break
      end
    end
    revision = revision + 1
    updateStatus()
    return true
  end

  function s.set(row, symbol, rows)
    if type(row) ~= "table" or row.kind ~= "raid" or not I.accepts(row.identity)
      or not tokens[row.token] or not symbols[symbol] or not current(revision) then return false end
    local identity = row.identity
    if not marks[identity] then
      if #order >= M.MAX_MARKERS then
        local index = indexRows(rows)
        local admitted = index[identity]
        if not admitted or admitted.token ~= row.token then return false end
        -- Only an explicit new choice can replace absent history at capacity.
        -- An offline or ambiguous identity is still present in the roster.
        for _, existing in ipairs(order) do
          if index[existing] == nil then remove(existing);break end
        end
        if #order >= M.MAX_MARKERS then return false end
      end
      order[#order + 1] = identity
    end
    marks[identity] = {identity = identity, token = row.token, symbol = symbol}
    revision = revision + 1
    lastStep = nil
    updateStatus()
    return true
  end

  function s.clear(rowOrIdentity)
    local identity = type(rowOrIdentity) == "table" and rowOrIdentity.identity or rowOrIdentity
    if closed or not I.accepts(identity) then return false end
    return remove(identity)
  end

  function s.clearAll()
    marks, order = {}, {}
    cursor, lastStep = 1, nil
    revision = revision + 1
    updateStatus()
    return true
  end

  function s.invalidate()
    revision = revision + 1
    for _, mark in pairs(marks) do mark.point = nil end
  end

  local function syncRows(index)
    for identity, mark in pairs(marks) do
      local row = index[identity]
      mark.projectable = visibleRow(row) == true
      if not mark.projectable then
        mark.point = nil
      elseif row.token ~= mark.token then
        mark.token = row.token
        mark.point = nil
      end
    end
  end

  local function project(mark, row, method, now, width, height, ticket, ownerGuard, budget)
    local token, identity = mark.token, mark.identity
    local function guard()
      return current(ticket, ownerGuard) and marks[identity] == mark and mark.projectable and mark.token == token and row.identity == identity
        and row.token == token and visibleRow(row)
    end
    if not guard() then return false end
    -- Once sampled, a failed projection must never reuse its old coordinates.
    mark.point = nil
    if budget then
      local ok, granted = pcall(budget.claim, token, identity, 8)
      if not ok or granted ~= true or not guard() then return false end
    end
    local ok, result = pcall(method, token, identity, guard, width, height)
    if not guard() or not ok or type(result) ~= "table" or result.contract ~= 1
      or result.state ~= "screen_point" or result.positionKnown ~= true or result.identityBracketed ~= true
      or result.identity ~= identity or result.token ~= token or not finite(result.x) or not finite(result.y)
      or result.x <= 0 or result.y <= 0 or (width and result.x > width) or (height and result.y > height) then
      return false
    end
    if not guard() then return false end
    mark.point = {x = result.x, y = result.y, at = now, identity = identity, token = token, symbol = mark.symbol}
    return true
  end

  local function rotate(index, limit, method, now, width, height, ticket, ownerGuard, budget)
    local examined, sampled, projected = 0, 0, false
    while examined < #order and sampled < limit and revision == ticket and not closed do
      local identity = order[cursor]
      cursor = cursor % #order + 1
      examined = examined + 1
      local row = index[identity]
      if visibleRow(row) then
        sampled = sampled + 1
        if project(marks[identity], row, method, now, width, height, ticket, ownerGuard, budget) then
          projected = true
        end
      end
    end
    return projected and current(ticket, ownerGuard)
  end

  function s.follow(rows, now, width, height, frame, membershipEmptyConfirmed, ownerGuard)
    if busy or not finite(frame) or frame == lastFrame then return false end
    lastFrame = frame
    local ticket = revision
    if not current(ticket, ownerGuard) or not finite(now) or not finite(width) or width <= 0
      or not finite(height) or height <= 0 then
      s.invalidate()
      return false
    end
    -- The shared roster's only confirmed absence is an explicitly empty raid.
    -- Partial rows can lose an identity temporarily, so retain its choice.
    if membershipEmptyConfirmed == true then s.clearAll();return false end
    if #order == 0 then return false end
    if (lastNow and now < lastNow) or (lastWidth and (width ~= lastWidth or height ~= lastHeight)) then
      s.invalidate()
      ticket = revision
    end
    lastNow, lastWidth, lastHeight = now, width, height
    local index = indexRows(rows)
    syncRows(index)
    if type(reader) ~= "table" or reader.memberMovementPointContract ~= 1
      or type(reader.observeMovementPoint) ~= "function" then
      s.invalidate()
      s.status = "Movement API unavailable"
      return false
    end
    busy = true
    local ok, projected = pcall(rotate, index, MAX_PER_FRAME, reader.observeMovementPoint, now, width, height, ticket, ownerGuard)
    busy = false
    if not ok or not current(ticket, ownerGuard) then
      -- A changed mark invalidates its own point in set/clear. Preserve
      -- independent observations when another member's choice changes.
      if not ok or revision == ticket then s.invalidate() end
      return false
    end
    if projected then
      s.status = #order == 1 and "Local symbol • movement follows each UI frame" or "Local symbols • staggered movement updates"
    end
    return projected
  end

  -- Retain the original bounded screen-point path for existing callers.
  function s.step(rows, budget, now)
    local ticket = revision
    if busy or #order == 0 then return end
    if not current(ticket) or not finite(now) then s.invalidate();return end
    if lastStep and now >= lastStep and now - lastStep < 250 then return end
    lastStep = now
    local index = indexRows(rows)
    syncRows(index)
    if type(budget) ~= "table" or budget.contract ~= 1 or type(budget.claim) ~= "function" then
      s.invalidate();return
    end
    if type(reader) ~= "table" or reader.memberScreenPointContract ~= 1
      or type(reader.observeScreenPoint) ~= "function" then
      s.invalidate()
      s.status = "Projection API unavailable"
      return
    end
    busy = true
    local ok, projected = pcall(rotate, index, 1, reader.observeScreenPoint, now, nil, nil, ticket, nil, budget)
    busy = false
    if not ok or (revision == ticket and not current(ticket)) then s.invalidate();return end
    if projected and revision == ticket then s.status = "Local projection; native visibility and scale unverified" end
  end

  function s.active()
    return not closed and #order > 0
  end

  function s.points(rows, now)
    local ticket = revision
    if not current(ticket) or not finite(now) then s.invalidate();return {} end
    local index = indexRows(rows)
    syncRows(index)
    local result = {}
    local maximumAge = #order == 1 and SINGLE_POINT_MS or MULTI_POINT_MS
    for _, identity in ipairs(order) do
      local mark = marks[identity]
      local point = mark.point
      if point and (now < point.at or now - point.at > maximumAge) then mark.point = nil;point = nil end
      if point then
        result[#result + 1] = {x = point.x, y = point.y, at = point.at, identity = identity, token = point.token, symbol = point.symbol}
      end
    end
    return result
  end

  function s.point(rows, now)
    return s.points(rows, now)[1]
  end

  function s.close()
    closed = true
    return s.clearAll()
  end
  return s
end
return M
