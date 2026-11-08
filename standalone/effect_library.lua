-- Raid-specific browser over the shared Public suggestions/metadata modules.
-- Metadata is descriptive only: this module never establishes aura presence.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local W=require("Mazrim_Raid_Frames/shared/watchlist")
local Common=require("Mazrim_Raid_Frames/data/common_effects")
local Meta=require("Mazrim_Raid_Frames/data/effect_metadata")
local Names=require("Mazrim_Raid_Frames/data/effect_names")
local I=require("Mazrim_Raid_Frames/shared/identity")
local L={contract=1,unifiedSearchContract=1,configurationRevisionContract=1,frameRulesContract=W.frameRulesContract==1 and 1 or 0,
 commonEffectsContract=Common.contract==1 and Meta.version=="0.0.24"and 1 or 0}
local MAX_METADATA=512
L.targetBuffPolicyContract=2
local catalogue,namedOrder,families={},{},{}
for _,row in ipairs(Names.rows)do
 local id=W.id(row[1])
 if id and not catalogue[id]and Meta.label(row[2])and (row[3]=="buff"or row[3]=="debuff")then
  catalogue[id]={name=row[2],kind=row[3],icon=Meta.path(row[4]),search=row[2]:lower()}
  namedOrder[#namedOrder+1]=id
  local key=row[3]..":"..row[2]
  families[key]=families[key]or{};families[key][#families[key]+1]=id
 end
end
local kindLabels={buff="Buff",debuff="Debuff",both="Buff / debuff",unknown="Type unknown"}
local function numeric(id)
 local n=0;for i=1,#id do n=n*10+(string.byte(id,i)-48) end;return n
end
local function label(value,id)
 local name=Meta.label(value)
 if name and name~="Effect"and name~="Buff"and name~="Debuff"
  and name~="Effect "..id and name~="Buff "..id and name~="Debuff "..id then return name end
end
local function sortedIds(map)
 local ids={}
 for id in pairs(map)do ids[#ids+1]=id end
 for index=2,#ids do
  local value=ids[index]
  local position=index
  while position>1 do
   local previous=ids[position-1]
   if #previous<#value or (#previous==#value and previous<value) then break end
   ids[position]=previous
   position=position-1
  end
  ids[position]=value
 end
 return ids
end
function L.new(api,alive)
 local closed=false
 local index,order,observed={},{},{}
 local catalogueRevision,viewRows=0,nil
 local pending=0
 local cursor,last,epoch=0,nil,0
 local priority={}
 local snapshot=W.revisionSnapshot()
 local scanSnapshot=W.revisionSnapshot()
 local scanOptions,scanRevision,scanPrefs
 local function identity(id)
  local r,known=index[id],catalogue[id]
  local kind=r and(r.buff and r.debuff and"both"or r.buff and"buff"or r.debuff and"debuff")or known and known.kind or"unknown"
  return r and r.name or known and known.name,kind
 end
 local function groupMembers(row)
  if row.kindCode=="unknown"then return{row.id}end
  local members,seen={},{}
  local function add(id)
   local name,kind=identity(id)
   if not seen[id]and name==row.name and kind==row.kindCode then members[#members+1]=id;seen[id]=true end
  end
  for _,id in ipairs(families[row.kindCode..":"..row.name]or{})do add(id)end
  for _,id in ipairs(order)do add(id)end
  if not seen[row.id]then members[#members+1]=row.id end
  for i=2,#members do
   local id,j=members[i],i
   while j>1 and(#members[j-1]>#id or #members[j-1]==#id and members[j-1]>id)do members[j]=members[j-1];j=j-1 end
   members[j]=id
  end
  return members
 end
 local function groupRow(row,prefs)
  local g={};for key,value in pairs(row)do g[key]=value end
  g.members=groupMembers(row);g.id=g.members[1]
  g.selected=true;g.alertSelected=true;g.helperSelected=true;g.ruleEnabled=true;g.configured=false;g.hasRule=false
  local iconBefore,alertBefore,helperBefore,ruleBefore,priorityBefore
  for n,id in ipairs(g.members)do
   local icon,alert,r=prefs.watch[id]==true,prefs.alerts[id]==true,prefs.frame_rules[id]
   local priority=prefs.priorities[id]or 0
   local helper=prefs.hot_helper_ids[id]==true
   if n>1 then
    g.iconMixed=g.iconMixed or icon~=iconBefore
    g.alertMixed=g.alertMixed or alert~=alertBefore
    g.helperMixed=g.helperMixed or helper~=helperBefore
    local different=(r~=nil)~=(ruleBefore~=nil)
    if r and ruleBefore then
     for _,key in ipairs({"enabled","kind","material","colour","priority"})do different=different or r[key]~=ruleBefore[key]end
    end
    g.ruleMixed=g.ruleMixed or different
    g.priorityMixed=g.priorityMixed or priority~=priorityBefore
   end
   iconBefore,alertBefore,helperBefore,ruleBefore,priorityBefore=icon,alert,helper,r,priority
   g.selected=g.selected and icon;g.alertSelected=g.alertSelected and alert;g.helperSelected=g.helperSelected and helper
   g.configured=g.configured or icon or alert or helper or r~=nil;g.hasRule=g.hasRule or r~=nil
   g.ruleEnabled=g.ruleEnabled and r~=nil and r.enabled==true
   g.rule=g.rule or r
  end
  g.iconSelected=g.selected
  g.mixed=g.iconMixed or g.alertMixed or g.helperMixed or g.ruleMixed or g.priorityMixed
  return g
 end
 local function current()
  if closed or type(alive)~="function"then return false end
  local ok,v=pcall(alive);return ok and v==true and not closed
 end
 local function ensure(id)
  id=W.id(id);if not id then return nil end
  if not index[id]and #order<MAX_METADATA then
   index[id]={id=id,pending=true};order[#order+1]=id;pending=pending+1
   catalogueRevision=catalogueRevision+1
  end
  return index[id]
 end
 local function settle(r)
  if r.pending then r.pending=false;pending=pending-1 end
 end
 local function setName(r,name)
  if name then
   if r.name~=name then catalogueRevision=catalogueRevision+1 end
   r.name=name;settle(r)
  end
 end
 for _,row in ipairs(Common.rows())do local r=ensure(row.id);if r then r.common=true end end
 -- Confirmed in the live client as Inspired, Buff, ID 127. This entry makes
 -- the name searchable before an aura sample or a tooltip lookup is available.
 local inspired=ensure("127")
 inspired.verified=true;inspired.buff=true;setName(inspired,"Inspired")
 local s={contract=1,unifiedSearchContract=1,configurationRevisionContract=1,frameRulesContract=L.frameRulesContract}
 function s.observe(samples)
  if not current()or type(samples)~="table"or #samples>50 then return false end
  for i=1,#samples do
   local sample=samples[i]
   if type(sample)=="table"and sample.contract==1 and I.accepts(sample.identity)and sample.coverage=="observed"then
    for _,kind in ipairs({"buff","debuff"})do
     local list=sample[kind.."s"]
     if sample[kind.."sKnown"]==true and type(list)=="table"and #list<=64 then
      for j=1,#list do
       local e=list[j];local r=type(e)=="table"and ensure(e.id)
       if r then
        if sample.channel~="raid_filtered"then
         local key="typed_"..kind
         if not r[key]then r[key]=true;catalogueRevision=catalogueRevision+1 end
        end
        if not observed[r.id]or not r[kind]then catalogueRevision=catalogueRevision+1 end
        observed[r.id]=true;r[kind]=true
        local name=label(e.name,r.id)
        setName(r,name)
        local icon=Meta.path(e.icon)
        local direct=sample.origin=="target"or sample.origin=="player"
        local priorDirect=r.iconOrigin=="target"or r.iconOrigin=="player"
        if icon and(not r.icon or(not r.metaIcon and direct and(not priorDirect or r.iconOrigin==sample.origin)))then
         if r.icon~=icon then catalogueRevision=catalogueRevision+1 end
         r.icon=icon;r.iconOrigin=sample.origin or"unknown"
        end
       end
      end
     end
    end
   end
  end
  return current()
 end
 function s.prioritize(options,revision)
  if not current()then return false end
  local prefs,changed=snapshot(options,revision);if not prefs then return false end
  if not changed then return true end
  local result,seen={},{}
  for _,map in ipairs({prefs.alerts,prefs.watch,prefs.frame_rules,prefs.hot_helper_ids})do
   for _,id in ipairs(sortedIds(map))do if not seen[id]then seen[id]=true;ensure(id);result[#result+1]=id end end
  end
  priority=result;return true
 end
 -- Metadata chooses admission only; it never establishes current presence.
 -- The filtered widget's untyped positives cannot classify an unknown ID.
 function s.raidOptions(options,revision)
  if not current()then return nil end
  local checked,changed=scanSnapshot(options,revision)
  if not checked then return nil end
  if not checked.target_buffs_only then return options end
  if not changed and scanOptions==checked and scanRevision==catalogueRevision then return scanPrefs end
  local out=W.validate(checked)
  local function allowed(id)
   local known,r=catalogue[id],index[id]
   if not checked.hot_helper_ids[id]then return true end
   if known and known.kind=="buff"or r and r.typed_buff then return false end
   return known and known.kind=="debuff"or r and r.typed_debuff==true
  end
  for _,map in ipairs({"watch","alerts","frame_rules","priorities","debuff_colours"})do
   for id in pairs(out[map])do if not allowed(id)then out[map][id]=nil end end
  end
  scanOptions=checked;scanRevision=catalogueRevision;scanPrefs=out
  return out
 end
 function s.rows(scope,query,options)
  if not current()then return {}end
  local prefs=W.validate(options);if not prefs then return {}end
  local unified=scope=="browse"or scope=="mine"
  for id in pairs(prefs.watch)do ensure(id)end
  for id in pairs(prefs.alerts)do ensure(id)end
  for id in pairs(prefs.frame_rules)do ensure(id)end
  for id in pairs(prefs.hot_helper_ids)do ensure(id)end
  query=type(query)=="string"and query:sub(1,48):lower()or""
  if unified then query=query:match("^%s*(.-)%s*$")end
  local queryID=W.id(query)
  if queryID and not unified then ensure(queryID)end
  local result={}
  local function row(id,r)
   local known=unified and catalogue[id]or nil
   local rule=prefs.frame_rules[id]
   local catalogued=known~=nil or r~=nil and (r.common==true or r.verified==true)
   local seen=observed[id]==true
   local configured=prefs.watch[id]==true or prefs.alerts[id]==true or prefs.hot_helper_ids[id]==true or rule~=nil
   local kindCode=r and(r.buff and r.debuff and"both"or r.buff and"buff"or r.debuff and"debuff")or"unknown"
   if kindCode=="unknown"and known then kindCode=known.kind end
   local kind=kindLabels[kindCode]
   if kindCode=="unknown"and not unified then kind="Suggested effect"end
   return {id=id,name=r and r.name or known and known.name or("Effect "..id),icon=r and r.icon or known and known.icon,observed=seen,
    kind=kind,kindCode=kindCode,configured=configured,catalogued=catalogued,manual=not(catalogued or seen or configured),
    source=seen and"Observed in raid"or catalogued and"Catalogue"or configured and"Saved choice"or"Manual ID",
    alertSelected=prefs.alerts[id]==true,selected=prefs.watch[id]==true,iconSelected=prefs.watch[id]==true,rule=rule,hasRule=rule~=nil,
    ruleEnabled=rule~=nil and rule.enabled==true,colour=rule and rule.colour or"none"}
  end
  if unified then
   local included={}
   local function append(id)
    if included[id]then return end
    local r=index[id]
    local configured=prefs.watch[id]==true or prefs.alerts[id]==true or prefs.hot_helper_ids[id]==true or prefs.frame_rules[id]~=nil
    if scope=="mine"then
     if not configured then return end
    elseif not(configured or observed[id] or catalogue[id] or (r and (r.common or r.verified)) or queryID==id)then return end
    local known=catalogue[id]
    local folded=r and r.name and r.name:lower()or known and known.search or("effect "..id)
    if query~=""and not folded:find(query,1,true)and not id:find(query,1,true)then return end
    included[id]=true
    result[#result+1]=row(id,r)
   end
   -- A typed ID can be used explicitly even without cached metadata. Merely
   -- searching does not add a new tooltip lookup or a saved choice.
   if queryID then append(queryID)end
   for _,id in ipairs(order)do append(id)end
   -- Browse stays compact. Name/ID searches also cover the complete local
   -- scan without adding every record to the live metadata lookup queue.
   if scope=="browse"and query~=""then for _,id in ipairs(namedOrder)do append(id)end end
   if #order>=MAX_METADATA then
    -- Saved choices can outlive a full transient metadata cache. Keep their
    -- rows available for editing/removal without admitting more lookups.
    for _,map in ipairs({prefs.watch,prefs.frame_rules,prefs.alerts,prefs.hot_helper_ids})do
     for _,id in ipairs(sortedIds(map))do if not index[id]then append(id)end end
    end
   end
   return result
  end
  for i=1,#order do
   local r=index[order[i]]
   if(scope=="observed"and observed[r.id])or(scope=="selected"and prefs.watch[r.id])or(scope=="rules"and prefs.frame_rules[r.id])or(scope=="alerts"and prefs.alerts[r.id])
    or queryID==r.id
    or(scope~="observed"and scope~="selected"and scope~="rules"and scope~="alerts"and r.common)then
    local name=r.name or("Effect "..r.id)
    if query==""or name:lower():find(query,1,true)or r.id:find(query,1,true)then
     result[#result+1]=row(r.id,r)
    end
   end
  end
  -- Authored rules must remain removable even after the transient metadata
  -- cache fills. These placeholders do not enlarge that cache or prove presence.
  local authored=scope=="selected"and prefs.watch or scope=="rules"and prefs.frame_rules or scope=="alerts"and prefs.alerts or nil
  if authored then for id in pairs(authored)do
   if not index[id]and(query==""or("effect "..id):find(query,1,true)or id:find(query,1,true))then
    result[#result+1]=row(id,nil)
   end
  end end
  if queryID and not index[queryID]then
   local found=false;for _,r in ipairs(result)do if r.id==queryID then found=true;break end end
   if not found then result[#result+1]=row(queryID,nil)end
  end
  return result
 end
 -- Studio callers treat these cached results as read-only. Other callers use
 -- rows() for independently owned configuration previews and editable results.
 function s.studioRows(scope,query,options,revision)
  if not current()then return {}end
  if type(revision)~="number"then return s.rows(scope,query,options)end
  local cached=viewRows
  if cached and cached.scope==scope and cached.query==query and cached.options==options
   and cached.revision==revision and cached.catalogueRevision==catalogueRevision then return cached.rows end
  local raw=s.rows(scope,query,options)
  local prefs=W.validate(options);if not prefs then return {}end
  local result,seen={},{}
  for _,row in ipairs(raw)do
   local key=row.kindCode=="unknown"and row.id or row.kindCode..":"..row.name
   if not seen[key]then seen[key]=true;result[#result+1]=groupRow(row,prefs)end
  end
  if current()then viewRows={scope=scope,query=query,options=options,revision=revision,
    catalogueRevision=catalogueRevision,rows=result}end
  return result
 end
 function s.group(id,options)
  id=W.id(id);if not id then return nil end
  local row=s.rows("browse",id,options)[1]
  local prefs=W.validate(options)
  return row and prefs and groupRow(row,prefs)or nil
 end
 function s.enrich(now,allowed,priorityOnly)
  if not current()or not B.finite(now)or now<0 then return false end
  if last and now>=last and now-last<250 then return true end
  last=now;local ticket=epoch
  local function valid()
   if ticket~=epoch or not current()then return false end
   if type(allowed)=="function"then local ok,v=pcall(allowed);return ok and v==true and current()end
   return true
  end
  if pending==0 then return valid()end
  local ability=B.member(api,"Ability");local fn=B.member(ability,"GetBuffTooltip")
  if not valid()or type(fn)~="function"then return false end
  local examined,calls=0,0
  local function resolve(r)
   if r and(r.name or(r.attempts or 0)>=3)then settle(r)end
   if r and not r.name and(r.attempts or 0)<3 and(not r.retry or now>=r.retry)and calls<2 and valid()then
    r.attempts=(r.attempts or 0)+1;r.retry=now+1500;calls=calls+1
    local ok,raw=pcall(fn,ability,numeric(r.id),0)
    if not valid()then return false end
    if ok then local info=Meta.read(raw);if not valid()then return false end
     local name=label(info.label,r.id);setName(r,name)
     if info.icon then
      if r.icon~=info.icon then catalogueRevision=catalogueRevision+1 end
      r.icon=info.icon;r.metaIcon=true
     end
    end
    if(r.attempts or 0)>=3 then settle(r)end
   end
   return valid()
  end
  for _,id in ipairs(priority)do
   if calls>=2 or pending==0 or not valid()then break end
   if not resolve(index[id])then return false end
  end
  if priorityOnly==true then return valid()end
  while #order>0 and pending>0 and examined<#order and calls<2 and valid()do
   cursor=cursor%#order+1;examined=examined+1
   local r=index[order[cursor]]
   if not resolve(r)then return false end
  end
  return valid()
 end
 function s.label(id)
  id=W.id(id);local r=id and index[id]
  local known=id and catalogue[id]
  return r and r.name or known and known.name or(id and("Effect "..id)or"Effect"),r~=nil and r.name~=nil or known~=nil
 end
 function s.decorate(frame)
  if not current()or type(frame)~="table"then return frame end
  for _,item in ipairs(type(frame.items)=="table"and frame.items or{})do
   local id=W.id(item.id);local r=id and index[id]
   local known=id and catalogue[id]
   if r or known then item.label=r and r.name or known and known.name or item.label;item.icon=r and r.icon or known and known.icon or item.icon end
  end
  return frame
 end
 function s.close()closed=true;epoch=epoch+1;index={};order={};observed={};priority={};pending=0;viewRows=nil;return true end
 return s
end
return L
