-- Frontend consumer of the shared memberAuraContract1 observer. No aura reader.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local I=require("Mazrim_Raid_Frames/shared/identity")
local M={eligibleBudgetContract=1,raidCoverageBudgetContract=1,sharedBudgetContract=1,contract=1,memberAuraContract=1,targetObservationContract=1,targetAuraDepthContract=1,MAX_REQUESTS=4}
local function integer(v,lo,hi)return B.finite(v)and v%1==0 and v>=lo and v<=hi end
local function token(v)
  if type(v)=="string"then for i=1,50 do if v=="team"..i then return true end end end
  return false
end
local function effects(list,known,count,kind,limit)
  if known~=true or not integer(count,0,256)or type(list)~="table"or #list~=math.min(count,limit)then return nil end
  local result={}
  for i=1,#list do
    local raw=list[i]
    if type(raw)~="table"or raw.kind~=kind or not integer(raw.id,1,9007199254740991)then return nil end
    local e={id=raw.id,name=(kind=="buff"and"Buff "or"Debuff ")..string.format("%.0f",raw.id)}
    if raw.iconKnown==true and type(raw.iconPath)=="string"and #raw.iconPath<=512
      and not raw.iconPath:find("[%c|]")then e.icon=raw.iconPath end
    -- Zero time does not distinguish expired/untimed effects at this boundary.
    if raw.remainingMsKnown==true and B.finite(raw.remainingMs)and raw.remainingMs>0 and raw.remainingMs<=604800000 then
      e.timeKnown=true;e.remainingMs=raw.remainingMs
    end
    if raw.stacksKnown==true and integer(raw.stacks,1,999)then e.stacksKnown=true;e.stacks=raw.stacks end
    -- No caster, own-HoT or player-dispel inference is made by this consumer.
    result[#result+1]=e
  end
  return result
end
function M.new(api,alive,reader)
  local deepSupported=type(reader)=="table"and reader.targetAuraDepthContract==1
  local s={eligibleBudgetContract=1,raidCoverageBudgetContract=1,sharedBudgetContract=1,contract=1,memberAuraContract=1,targetObservationContract=1,
    targetAuraDepthContract=deepSupported and 1 or 0,status="Aura observations unavailable"}
  local closed,cursor=false,0
  local requestTimes,lastClock,lastDeep,preferPlayer={},nil,nil,false
  local MAX_NATIVE=144 -- UNIT getter reservations; provider clocks are reported separately.
  local epoch,epochStart=0,nil
  local coverageEpoch,coverageQuota,coverageOrdinary,coverageBatchEpoch
  local coalescing=true
  local function current()
    if closed or type(alive)~="function"then return false end
    local ok,v=pcall(alive);return ok and v==true and not closed
  end
  local function selectorIdentity(selector)
    if not current()then return nil end
    local ok,id=B.call(B.member(api,"Unit"),"GetUnitId",selector)
    if current()and ok and I.accepts(id)then return id end
  end
  -- Event-driven target observations and periodic observations share one
  -- rolling four-request/250ms budget, including at most one combined deep
  -- target/player read (32/category). Team reads remain8/category. Failed
  -- attempts consume both applicable budgets; no native aura getter lives here.
  local function allowance(now)
    if not B.finite(now)or now<0 or(lastClock and now<lastClock)then return 0 end
    lastClock=now
    if not epochStart or now-epochStart>=250 then epoch=epoch+1;epochStart=now end
    local recent={}
    for i=1,#requestTimes do if now-requestTimes[i].at<250 then recent[#recent+1]=requestTimes[i]end end
    requestTimes=recent;return M.MAX_REQUESTS-#requestTimes
  end
  local function deepAvailable(now)return lastDeep==nil or now-lastDeep>=250 end
  local function claim(now,selector,id,cost)
    if allowance(now)<=0 or not I.accepts(id)then return false end
    local native=0
    for _,r in ipairs(requestTimes)do
      native=native+r.cost
      local sameChannel=(r.cost==8 and cost==8)or(r.cost==14 and cost==14)or(r.cost~=8 and r.cost~=14 and cost~=8 and cost~=14)
      -- A32-entry deep read may upgrade an8-entry ordinary observation, while
      -- a recent deep observation makes a narrower alias read redundant.
      local upgrade=r.cost==24 and cost==72
      if coalescing and sameChannel and not upgrade and(r.id==id or r.token==selector)then return false end
    end
    if native+cost>MAX_NATIVE then return false end
    requestTimes[#requestTimes+1]={at=now,id=id,token=selector,cost=cost};return true
  end
  local function reserve(now,selector,id)
    local deep=selector=="target"or selector=="player"
    if deep and not deepAvailable(now)then return false end
    if not claim(now,selector,id,deep and 72 or 24)then return false end
    if deep then lastDeep=now;preferPlayer=selector=="target"end
    return true
  end
  function s.setSharedBudgetEnabled(value)coalescing=true end
  function s.ordinaryCapacity(rows,now,limit)
    if not current()or type(rows)~="table"or #rows>50 or not integer(limit,0,2)then return nil end
    if allowance(now)<=0 then return 0 end
    local ids,tokens,duplicates,duplicateTokens={},{},{},{}
    for _,row in ipairs(rows)do if type(row)=="table"and row.kind=="raid"and token(row.token)and I.accepts(row.identity)then
      if ids[row.identity]then duplicates[row.identity]=true else ids[row.identity]=row end
      if tokens[row.token]then duplicateTokens[row.token]=true else tokens[row.token]=true end
    end end
    local count=0
    for id,row in pairs(ids)do
      local recent=false
      for _,r in ipairs(requestTimes)do if(r.cost==24 or r.cost==72)and(r.id==id or r.token==row.token)then recent=true;break end end
      if not recent and not duplicates[id]and not duplicateTokens[row.token]then count=count+1 end
    end
    return math.min(count,limit)
  end
  function s.sharedBudget(now,projection)
    coalescing=true;allowance(now)
    local used=false
    return {contract=1,claim=function(selector,id,cost)
      if used or lastClock~=now or not current()or not token(selector)or cost~=(projection and 8 or 14)then return false end
      used=true
      return claim(now,selector,id,cost)
    end}
  end
  function s.coveragePlan(now,ordinarySlots)
    if not current()or not integer(ordinarySlots,0,2)then return nil end
    local free=allowance(now);local ticket=epoch;local rawStart=epochStart
    if coverageEpoch~=ticket then
      coverageEpoch=ticket;coverageOrdinary=ordinarySlots;coverageQuota=math.max(0,math.min(3,free-ordinarySlots))
    end
    ordinarySlots=coverageOrdinary;local limit=coverageQuota
    return{contract=1,windowId=rawStart,filteredLimit=limit,ordinarySlots=ordinarySlots,unitGetterLimit=MAX_NATIVE,
      beginFilteredBatch=function()
        if epoch~=ticket or lastClock~=now or coverageBatchEpoch==ticket then return false end
        coverageBatchEpoch=ticket
        return current()and epoch==ticket and lastClock==now
      end,
      grant=function()
        local used=false
        return{contract=1,windowId=rawStart,filteredLimit=limit,claim=function(selector,id,cost)
          if used or not current()or epoch~=ticket or lastClock~=now or not token(selector)or cost~=14 then return false end
          used=true
          if allowance(now)<=ordinarySlots then return false end
          local reserved=0;for _,r in ipairs(requestTimes)do reserved=reserved+r.cost end
          if reserved+14+ordinarySlots*24>MAX_NATIVE then return false end
          return claim(now,selector,id,cost)
        end}
      end}
  end
  local function observeRows(rows,now,targetOnly,deepOnly,ordinaryLimit)
    if not current()or not B.finite(now)or now<0 or type(rows)~="table"or #rows>50 then return {}end
    if type(reader)~="table"or reader.memberAuraContract~=1 or type(reader.observeAuras)~="function"then
      s.status="Shared aura observer unavailable";return {}
    end
    if allowance(now)<=0 or(targetOnly and not deepAvailable(now))then return {}end
    local accepted,duplicates,slots,duplicateSlots,ordered={},{},{},{},{}
    for i=1,#rows do
      local row=rows[i]
      if type(row)=="table"and row.kind=="raid"and token(row.token)and I.accepts(row.identity)then
        if accepted[row.identity]then duplicates[row.identity]=true else accepted[row.identity]=row end
        if slots[row.token]then duplicateSlots[row.token]=true else slots[row.token]=row end
        ordered[#ordered+1]=row
      end
    end
    local result,seen,requests={},{},0
    local function observe(selector,row)
      local id=row and row.identity
      if row and not duplicates[id]and not duplicateSlots[row.token]and not seen[id]and current()
        and requests<M.MAX_REQUESTS and reserve(now,selector,id)then
        seen[id]=true;requests=requests+1
        local normalized={contract=1,identity=id,token=row.token,origin=selector,coverage="unknown",
          buffsKnown=false,debuffsKnown=false,buffs={},debuffs={},buffsComplete=false,debuffsComplete=false}
        local ok,raw=pcall(reader.observeAuras,selector,id,current)
        if not current()then return {}end
        if ok and type(raw)=="table"and raw.contract==1 and raw.state=="partial"and raw.clear==false
          and raw.identityBracketed==true and raw.token==selector and raw.identity==id then
          local limit=deepSupported and(selector=="target"or selector=="player")and 32 or 8
          local buffs=effects(raw.buffs,raw.buffsKnown,raw.buffCount,"buff",limit)
          local debuffs=effects(raw.debuffs,raw.debuffsKnown,raw.debuffCount,"debuff",limit)
          normalized={contract=1,identity=id,token=row.token,origin=selector,
            coverage=(buffs or debuffs)and"observed"or"unknown",buffsKnown=buffs~=nil,debuffsKnown=debuffs~=nil,
            buffs=buffs or{},debuffs=debuffs or{},
            buffsComplete=raw.absenceVerified==true and raw.buffsTruncated==false,
            debuffsComplete=raw.absenceVerified==true and raw.debuffsTruncated==false}
        end
        result[#result+1]=normalized
      end
    end
    local selectors=targetOnly and{"target"}or preferPlayer and{"player","target"}or{"target","player"}
    for _,selector in ipairs(selectors)do
      if allowance(now)<=0 or not deepAvailable(now)then break end
      local id=selectorIdentity(selector);observe(selector,id and accepted[id]or nil)
      if not current()then return {}end
    end
    local visited,ordinaryRequests=0,0
    while not deepOnly and not targetOnly and #ordered>0 and visited<#ordered and requests<M.MAX_REQUESTS and(ordinaryLimit==nil or ordinaryRequests<ordinaryLimit)and current()and allowance(now)>0 do
      cursor=cursor%#ordered+1;visited=visited+1
      local row=ordered[cursor];local before=requests;observe(row.token,row)
      if requests>before then ordinaryRequests=ordinaryRequests+1 end
    end
    if not current()then return {}end
    s.status=#result>0 and"Partial member effects; own HoTs and dispel ability unknown"or"Member aura observations unavailable"
    return result
  end
  function s.deep(rows,now)coalescing=true;return observeRows(rows,now,false,true)end
  function s.sample(rows,now,ordinaryLimit)return observeRows(rows,now,false,false,ordinaryLimit)end
  function s.target(rows,now)return observeRows(rows,now,true)end
  function s.close()closed=true;requestTimes={};lastDeep=nil;s.status="Aura observations stopped";return true end
  return s
end
return M
