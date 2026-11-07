-- Positive-only experimental notifications, not authoritative applications.
local I=require("Mazrim_Raid_Frames/shared/identity")
local W=require("Mazrim_Raid_Frames/shared/watchlist")
local A={contract=1,MAX_VISIBLE=3}
local function finite(v)return type(v)=="number"and v==v and v>=0 and v<1/0 end
function A.new()
  local seen,visible={},{}
  local s={contract=1}
  function s.reset(id)
    id=W.id(id)
    if id then for _,record in pairs(seen)do record[id]=nil end
    else seen={}end
    visible={}
  end
  function s.clearVisible()visible={}end
  function s.push(raw,rows,now,options)
    if type(raw)~="table"or raw.contract~=1 or raw.state~="partial"or raw.reason~="observed"or raw.infoKnown~=true or not I.accepts(raw.identity)
      or type(raw.entries)~="table"or #raw.entries>8 or not finite(now)
      or options.raid_tracker~=true or options.large_alerts~=true then return end
    local row,count=nil,0
    for _,r in ipairs(rows or{})do
      if r.identity==raw.identity and r.token==raw.token then row=r;count=count+1 end
    end
    if count~=1 then return end
    local record=seen[raw.identity]
    if not record then
      local n=0;for _ in pairs(seen)do n=n+1 end
      if n>=64 then return end
      record={};seen[raw.identity]=record
    end
    local latched=0;for _ in pairs(record)do latched=latched+1 end
    for _,e in ipairs(raw.entries)do
      local id=W.id(e.id)
      if id and options.alerts[id]==true and e.firstObservationKnown==true and e.firstObserved==true and not record[id]and latched<64 then
        record[id]=true;latched=latched+1
        local expiry=now+3000
        if e.remainingMsKnown==true and finite(e.remainingMs)and e.remainingMs>0 then expiry=math.min(expiry,now+e.remainingMs)end
        visible[#visible+1]={identity=raw.identity,token=raw.token,id=id,name=row.nameKnown==true and row.name or"Raid member",untilMs=expiry}
        if #visible>A.MAX_VISIBLE then for i=2,#visible do visible[i-1]=visible[i]end;visible[#visible]=nil end
      end
    end
  end
  function s.current(rows,now)
    if not finite(now)then visible={};return{}end
    local result={}
    for _,a in ipairs(visible)do
      local count=0
      for _,r in ipairs(rows or{})do if r.identity==a.identity and r.token==a.token then count=count+1 end end
      if count==1 and now<a.untilMs then result[#result+1]=a end
    end
    visible=result;return result
  end
  return s
end
return A
