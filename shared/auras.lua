-- Display-only positive aura observations/history. No API, targeting or IO.
local I=require("Mazrim_Raid_Frames/shared/identity")
local P=require("Mazrim_Raid_Frames/shared/presentation")
local W=require("Mazrim_Raid_Frames/shared/watchlist")
local Colours=require("Mazrim_Raid_Frames/shared/colours")
local A={contract=1,watchlistContract=W.contract==1 and 1 or 0,selectedOnlyContract=W.selectedOnlyContract==1 and 1 or 0,
 priorityContract=W.priorityContract==1 and 1 or 0,frameRulesContract=W.frameRulesContract==1 and Colours.contract==1 and 1 or 0,tintCandidatesContract=1,
 MAX_INPUT_EFFECTS=32,MAX_EFFECTS=16,MAX_MEMBERS=50,MAX_VISIBLE=6}
local FRESH_MS,MAX_DURATION_MS=500,604800000
A.targetBuffPolicyContract=1
local function finite(v)return type(v)=="number"and v==v and v>=0 and v<1/0 end
local function integer(v,lo,hi)return finite(v)and v%1==0 and v>=lo and v<=hi end
local function token(v)
 if type(v)=="string"then for i=1,50 do if v=="team"..i then return true end end end
 return false
end
local function array(a,limit)
 if type(a)~="table"or #a>limit then return false end
 local n=0;for k in pairs(a)do if not integer(k,1,#a)then return false end;n=n+1 end
 return n==#a
end
local function flag(o,key)return o[key.."Known"]==true and type(o[key])=="boolean",o[key]==true end
local function origin(v)return v=="target"and"target"or v=="player"and"player"or token(v)and v or"unknown"end
local function effect(raw,now,source)
 if type(raw)~="table"or not I.accepts(raw.id)then return nil end
 local e={id=raw.id,name=type(raw.name)=="string"and P.text(raw.name,32)or"Effect",
  observedAt=now,origin=source,fresh=true}
 if type(raw.icon)=="string"and #raw.icon<=256 and #raw.icon>0
  and not raw.icon:find("[%c|]")and not raw.icon:find("..",1,true)then e.icon=raw.icon end
 if raw.timeKnown==true and finite(raw.remainingMs)and raw.remainingMs<=MAX_DURATION_MS then
  e.expiresAt=now+raw.remainingMs;e.timeKnown=true
 end
 if raw.stacksKnown==true and integer(raw.stacks,1,999)then e.stacksKnown=true;e.stacks=raw.stacks end
 e.mineKnown,e.mine=flag(raw,"mine");e.hotKnown,e.hot=flag(raw,"hot")
 e.dispelKnown,e.dispellable=raw.dispelKnown==true and type(raw.dispellable)=="boolean",raw.dispellable==true
 e.priority=integer(raw.priority,0,100)and raw.priority or 0
 return e
end
local function category(raw,known,complete,now,source)
 if known~=true or not array(raw,A.MAX_INPUT_EFFECTS)then return nil end
 local effects,seen={},{}
 for i=1,#raw do
  local e=effect(raw[i],now,source);if not e then return nil end
  -- Without a caster/instance contract, show the first positively observed
  -- occurrence of an ID; never invent combined stacks or caster ownership.
  -- User priority ranks that existing representative, not separate instances.
  if not seen[e.id]then seen[e.id]=true;effects[#effects+1]=e end
 end
 return {effects=effects,observedAt=now,fresh=true,complete=complete==true}
end
local function merge(prior,incoming)
 if not incoming then return prior end
 local result,seen={},{}
 for i=1,#incoming.effects do
  local e=incoming.effects[i];local old
  if prior then for j=1,#prior.effects do if prior.effects[j].id==e.id then old=prior.effects[j];break end end end
  -- Team caches have no accepted age. Their repeated timer must never move a
  -- remembered deadline forward, even after that deadline has passed.
  if old and old.timeKnown and e.origin~="target"and e.origin~="player"then
   e.expiresAt=e.timeKnown and math.min(old.expiresAt,e.expiresAt)or old.expiresAt;e.timeKnown=true
   e.observedAt=old.observedAt;e.origin=old.origin;e.fresh=false
  end
  if old then e.order=old.order end
  seen[e.id]=true;result[#result+1]=e
 end
 if prior and not incoming.complete then
  for i=1,#prior.effects do local old=prior.effects[i];if not seen[old.id]then result[#result+1]=old end end
 end
 incoming.effects=result;return incoming
end
local function blank()
 return {contract=1,coverage="unknown",buffCoverage="unknown",debuffCoverage="unknown",buffs={},debuffs={},hots={},items={},tintCandidates={},
  buffsKnown=false,debuffsKnown=false,buffsComplete=false,debuffsComplete=false,hotsKnown=false,dispelKnown=false}
end
local function queries(options,validated)
 local prefs
 if validated then prefs=options else prefs=W.validate(options)end
 local q={}
 function q.selected(id)
  id=W.id(id);return prefs~=nil and id~=nil and prefs.watch[id]==true
 end
 function q.rule(id,kind)
  id=W.id(id);local r=prefs and id and prefs.frame_rules[id]
  if r and r.enabled and(r.kind=="any"or r.kind==kind)then return r end
 end
 function q.priority(id)
  id=W.id(id);return prefs and id and prefs.watch[id]and(prefs.priorities[id]or 0)or 0
 end
 return q
end
local function higher(a,b,options)
 local selectedA,selectedB=options.selected(a.id),options.selected(b.id)
 if selectedA~=selectedB then return selectedA end
 local priorityA,priorityB=options.priority(a.id),options.priority(b.id)
 if priorityA~=priorityB then return priorityA>priorityB end
 local dispelA,dispelB=a.dispelKnown and a.dispellable,b.dispelKnown and b.dispellable
 if dispelA~=dispelB then return dispelA==true end
 if a.priority~=b.priority then return a.priority>b.priority end
 return (a.order or 0)<(b.order or 0)
end
local function sort(list,options)
 local result={}
 for i=1,#list do
  local item,n=list[i],#result+1
  while n>1 and higher(item,result[n-1],options)do result[n]=result[n-1];n=n-1 end
  result[n]=item
 end
 return result
end
local function prune(record,now,q)
 local candidates={}
 for _,kind in ipairs({"buffs","debuffs"})do
  local cat=record[kind]
  if cat then for i=1,#cat.effects do candidates[#candidates+1]={effect=cat.effects[i],kind=kind}end end
 end
 if #candidates<=A.MAX_EFFECTS then return end
 local function preferred(a,b,userPriority)
  local x,y=a.effect,b.effect
  local ax,ay=x.timeKnown and x.expiresAt>now or not x.timeKnown and x.fresh and now-x.observedAt<=FRESH_MS,
   y.timeKnown and y.expiresAt>now or not y.timeKnown and y.fresh and now-y.observedAt<=FRESH_MS
  if ax~=ay then return ax end
  local rx,ry=q.rule(x.id,a.kind=="buffs"and"buff"or"debuff"),q.rule(y.id,b.kind=="buffs"and"buff"or"debuff")
  local sx,sy=q.selected(x.id)or rx~=nil,q.selected(y.id)or ry~=nil
  if sx~=sy then return sx end
  if userPriority then
   local px,py=math.max(q.priority(x.id),rx and rx.priority or 0),math.max(q.priority(y.id),ry and ry.priority or 0)
   if px~=py then return px>py end
  end
  if x.fresh~=y.fresh then return x.fresh==true end
  if x.priority~=y.priority then return x.priority>y.priority end
  return x.observedAt>y.observedAt
 end
 local function ordered(userPriority)
  local result={}
  for i=1,#candidates do
   local item,n=candidates[i],#result+1
   while n>1 and preferred(item,result[n-1],userPriority)do result[n]=result[n-1];n=n-1 end
   result[n]=item
  end
  return result
 end
 local ranked=ordered(true);local wanted={}
 for i=1,math.min(#ranked,A.MAX_EFFECTS)do wanted[ranked[i].effect]=true end
 -- Priority chooses retention, not a new observation order. Keep the existing
 -- normal tie order so switching a cached choice back to Normal takes effect
 -- immediately without requiring another observation or extending a deadline.
 local normal=ordered(false)
 local kept={buffs={},debuffs={}}
 for i=1,#normal do local item=normal[i];if wanted[item.effect]then
  local list=kept[item.kind];list[#list+1]=item.effect
 end end
 for _,kind in ipairs({"buffs","debuffs"})do if record[kind]then
  if #kept[kind]<#record[kind].effects then record[kind].complete=false end
  record[kind].effects=kept[kind]
 end end
end
function A.new(alive)
 local s={contract=1,watchlistContract=A.watchlistContract,priorityContract=A.priorityContract,frameRulesContract=A.frameRulesContract,tintCandidatesContract=A.tintCandidatesContract}
 local records,lastNow={},nil
 local snapshot=W.revisionSnapshot();local cachedQueries
 local function getQueries(options,revision)
  local prefs,changed=snapshot(options,revision)
  if changed or not cachedQueries then cachedQueries=queries(prefs,true)end
  return cachedQueries
 end
 local closed,generation=false,0
 local targetBuffsOnly
 local function applyBuffPolicy(options)
  local enabled=type(options)=="table"and options.target_buffs_only==true
  if enabled~=targetBuffsOnly then
   for _,record in pairs(records)do record.buffs=nil end
   targetBuffsOnly=enabled
  end
 end
 local function current(ticket)
  if closed or ticket~=generation or type(alive)~="function"then return false end
  local ok,v=pcall(alive);return ok and v==true and not closed and ticket==generation
 end
 function s.clear()generation=generation+1;records={};lastNow=nil;return true end
 function s.close()s.clear();closed=true;return true end
 local function clock(now)
  if not finite(now)or(lastNow and now<lastNow)then s.clear();return false end
  lastNow=now;return true
 end
 function s.replace(samples,now,options,revision)
  local ticket=generation;if not current(ticket)or not clock(now)then return false end
  applyBuffPolicy(options)
  local ok,staged=pcall(function()
   if not array(samples,A.MAX_MEMBERS)then return nil end
   local result,seen={},{}
   for i=1,#samples do
    local sample=samples[i]
    if type(sample)~="table"or sample.contract~=1 or not I.accepts(sample.identity)
     or(sample.token~=nil and not token(sample.token))then return nil end
    local source=origin(sample.origin)
    local channel=sample.channel
    if channel~=nil and(channel~="raid_filtered"or not token(source)or source~=sample.token)then return nil end
    local sourceKey=source..(channel=="raid_filtered"and":raid_filtered"or":ordinary")
    local incoming={identity=sample.identity,token=sample.token,
     buffs=(not targetBuffsOnly or source=="target")and category(sample.buffs,sample.buffsKnown,sample.buffsComplete,now,source)or nil,
     debuffs=category(sample.debuffs,sample.debuffsKnown,sample.debuffsComplete,now,source)}
    local group=seen[sample.identity]
    if not group then
     group={identity=sample.identity,token=sample.token,sources={},samples={}}
     seen[sample.identity]=group;result[#result+1]=group
    elseif group.token~=sample.token or source=="unknown"or group.sources.unknown then return nil end
    -- The canonical team origin is retained for conservative cached expiry.
    -- A filtered and ordinary team read are separate admitted channels, while
    -- two records from the same channel remain ambiguous and reject the batch.
    if group.sources[sourceKey]then return nil end
    group.sources[sourceKey]=true;if source=="unknown"then group.sources.unknown=true end
    group.samples[#group.samples+1]={source=source,value=incoming}
   end
   for _,group in ipairs(result)do
    -- Fold cached categories first. A direct, complete category is allowed to
    -- establish absence; an incomplete/unknown category cannot erase positive
    -- records from the complementary source. Never union complete absence
    -- with an older team cache after the direct read has won.
    for pass=1,2 do for _,sample in ipairs(group.samples)do
     local direct=sample.source=="target"or sample.source=="player"
     if direct==(pass==2)then
      group.buffs=merge(group.buffs,sample.value.buffs)
      group.debuffs=merge(group.debuffs,sample.value.debuffs)
     end
    end end
   end
   return result
  end)
  if not current(ticket)then return false end
  for _,r in pairs(records)do for _,kind in ipairs({"buffs","debuffs"})do
   local cat=r[kind];if cat then
    cat.fresh=false;local timed={}
    for i=1,#cat.effects do local e=cat.effects[i];if e.timeKnown then e.fresh=false;timed[#timed+1]=e end end
    cat.effects=timed
   end
  end end
  if not ok or not staged then return false end
  local q=getQueries(options,revision)
  for i=1,#staged do
   local item=staged[i];local r=records[item.identity]or{}
   r.token=item.token;r.buffs=merge(r.buffs,item.buffs);r.debuffs=merge(r.debuffs,item.debuffs)
   -- Native list slots can reorder between target and filtered reads. Retain
   -- first-positive order for equal priorities instead of shuffling icons.
   for _,kind in ipairs({"buffs","debuffs"})do if r[kind]then
    for _,e in ipairs(r[kind].effects)do if not e.order then r.nextOrder=(r.nextOrder or 0)+1;e.order=r.nextOrder end end
   end end
   prune(r,now,q);records[item.identity]=r
  end
  local count=0;for _ in pairs(records)do count=count+1 end
  if count>A.MAX_MEMBERS then records={};return false end
  return current(ticket)
 end
 function s.retain(identities)
  local ticket=generation;if not current(ticket)then return false end
  if not array(identities,A.MAX_MEMBERS)then s.clear();return false end
  local keep,duplicates={},{}
  for i=1,#identities do
   local id=identities[i];if not I.accepts(id)then s.clear();return false end
   if keep[id]then duplicates[id]=true end;keep[id]=true
  end
  for id in pairs(records)do if not keep[id]or duplicates[id]then records[id]=nil end end
  return current(ticket)
 end
 local function display(cat,now,onlyMineHots,options)
  if not cat then return {},"unknown",false,false,false end
  local known=cat.fresh and now-cat.observedAt<=FRESH_MS
  local result,classification={},cat.complete==true
  for i=1,#cat.effects do
   local e=cat.effects[i];local fresh=e.fresh and now-e.observedAt<=FRESH_MS
   if not(e.hotKnown and not e.hot)and not(e.mineKnown and not e.mine)and not(e.hotKnown and e.mineKnown)then classification=false end
   local show=not onlyMineHots or(e.hotKnown and e.hot and e.mineKnown and e.mine)
   if show and(not e.timeKnown or e.expiresAt>now)and(fresh or e.timeKnown)then
    local d={id=e.id,name=e.name,icon=e.icon,estimated=not fresh,observedAt=e.observedAt,origin=e.origin,
     timeKnown=e.timeKnown==true,stacksKnown=e.stacksKnown==true,stacks=e.stacks,
     mineKnown=e.mineKnown,mine=e.mine,hotKnown=e.hotKnown,hot=e.hot,
     dispelKnown=e.dispelKnown,dispellable=e.dispellable,priority=e.priority,order=e.order}
    if d.timeKnown then d.remainingMs=math.max(0,e.expiresAt-now);d.expiresAt=e.expiresAt end
    result[#result+1]=d
   end
  end
  result=sort(result,options)
  local coverage=known and"observed"or(#result>0 and"last_seen"or"unknown")
  return result,coverage,known,known and cat.complete,classification and known
 end
 function s.frame(identity,now,options,revision,maximumIcons)
  local ticket=generation
  if not current(ticket)or not I.accepts(identity)or not clock(now)then return blank()end
  applyBuffPolicy(options)
  local r=records[identity];if not r then return blank()end
  options=type(options)=="table"and options or{}
  local q=getQueries(options,revision)
  local out=blank();out.identity=identity;out.token=r.token
  out.buffs,out.buffCoverage,out.buffsKnown,out.buffsComplete,out.hotsKnown=display(r.buffs,now,options.onlyMineHots==true,q)
  out.hots=display(r.buffs,now,true,q)
  out.debuffs,out.debuffCoverage,out.debuffsKnown,out.debuffsComplete=display(r.debuffs,now,false,q)
  local allDispel=out.debuffsComplete
  if r.debuffs then for i=1,#r.debuffs.effects do if not r.debuffs.effects[i].dispelKnown then allDispel=false end end end
  out.dispelKnown=allDispel
  if out.buffCoverage=="observed"or out.debuffCoverage=="observed"then out.coverage="observed"
  elseif out.buffCoverage=="last_seen"or out.debuffCoverage=="last_seen"then out.coverage="last_seen"end
  -- Frame treatments use their own authored rules, independently of selected
  -- icons and their kind switches. Only positive, identity-bound observations
  -- or unexpired timed history are eligible; preferences never prove presence.
  local treatments={}
  local frameBuffs=out.buffs
  if options.onlyMineHots==true then frameBuffs=display(r.buffs,now,false,q)end
  local function before(a,b)
   if a.rule.priority~=b.rule.priority then return a.rule.priority>b.rule.priority end
   if a.effect.estimated~=b.effect.estimated then return a.effect.estimated~=true end
   if a.kind~=b.kind then return a.kind=="debuff"end
   local x,y=W.id(a.effect.id),W.id(b.effect.id)
   if #x~=#y then return #x<#y end
   return x<y
  end
  for _,kind in ipairs({"buff","debuff"})do
   local effects=kind=="buff"and frameBuffs or out.debuffs
   for i=1,#effects do
    local e=effects[i];local rule=q.rule(e.id,kind)
    if rule then local candidate={effect=e,rule=rule,kind=kind}
     local n=#treatments+1
     while n>1 and before(candidate,treatments[n-1])do treatments[n]=treatments[n-1];n=n-1 end
     treatments[n]=candidate
    end
   end
  end
  -- The renderer knows which estimated timers actually fit on the frame. Keep
  -- ordered positives so an undisclosed history winner cannot hide a fresh rule.
  for i=1,math.min(#treatments,W.MAX_ENTRIES)do
   local winner=treatments[i]
   local e,rule=winner.effect,winner.rule;local colour=Colours.rgb(rule.colour)
   if colour then
    local treatment={id=e.id,kind=winner.kind,material=rule.material,colour={colour[1],colour[2],colour[3]},estimated=e.estimated==true,
     observed=e.estimated~=true,observedAt=e.observedAt,userPriority=rule.priority}
    if e.timeKnown then treatment.remaining=e.remainingMs/1000 end
    out.tintCandidates[#out.tintCandidates+1]=treatment
   end
  end
  out.tint=out.tintCandidates[1]
  if options.hots==false then out.buffs={}end
  if options.debuffs==false then out.debuffs={}end
  local candidates={}
  local function add(e,kind)
   local selected=q.selected(e.id)
   if not selected then return end
   local item={id=e.id,kind=kind,label=e.name,icon=e.icon,observed=not e.estimated,estimated=e.estimated==true,
    highlight=selected,dispelKnown=e.dispelKnown==true,priority=e.priority,userPriority=q.priority(e.id)}
   if e.timeKnown then item.remaining=e.remainingMs/1000 end
   if e.stacksKnown then item.stacks=e.stacks end
   if e.dispelKnown then item.dispel=e.dispellable==true end
   candidates[#candidates+1]=item
  end
  if options.debuffs~=false then for i=1,#out.debuffs do local e=out.debuffs[i];if e.dispelKnown and e.dispellable then add(e,"debuff")end end end
  if options.hots~=false then for i=1,#out.hots do add(out.hots[i],"hot")end else out.hots={}end
  if options.debuffs~=false then for i=1,#out.debuffs do local e=out.debuffs[i];if not(e.dispelKnown and e.dispellable)then add(e,"debuff")end end end
  if options.hots~=false and options.onlyMineHots~=true then for i=1,#out.buffs do
   local e=out.buffs[i];if not(e.mineKnown and e.mine and e.hotKnown and e.hot)then add(e,"buff")end
  end end
  -- Only positively observed/eligible history enters this list. User priority
  -- outranks the kind buckets, but equal levels retain their existing order.
  -- The source-provided priority remains separate and is never overwritten.
  for i=1,#candidates do
   local item,n=candidates[i],#out.items+1
   while n>1 and item.userPriority>out.items[n-1].userPriority do out.items[n]=out.items[n-1];n=n-1 end
   out.items[n]=item
  end
  local visible=integer(maximumIcons,1,A.MAX_VISIBLE)and maximumIcons or 3
  for i=#out.items,visible+1,-1 do out.items[i]=nil end
  if not current(ticket)then return blank()end
  return out
 end
 return s
end
return A
