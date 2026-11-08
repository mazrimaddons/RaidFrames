-- Profile-scoped aura choices. IDs are effect IDs, never player identities.
-- Suggested IDs do not establish buff/debuff kind or current presence.
local Common=require("Mazrim_Raid_Frames/data/common_effects")
local Colours=require("Mazrim_Raid_Frames/shared/colours")
local Materials=require("Mazrim_Raid_Frames/shared/materials")
local W={contract=1,revisionSnapshotContract=1,selectedOnlyContract=1,priorityContract=1,frameRulesContract=Colours.contract==1 and 1 or 0,MAX_ENTRIES=256,MAX_ID=9007199254740991,
  commonEffectsContract=Common.contract==1 and Common.count==230 and 1 or 0}
W.targetBuffPolicyContract=2
local palette={red={0.88,0.20,0.22},amber={0.93,0.62,0.12},purple={0.63,0.36,0.85},
  blue={0.20,0.56,0.88},green={0.24,0.73,0.39}}
local order={"none","red","amber","purple","blue","green"}
local legacyHex={}
for name,ink in pairs(palette)do legacyHex[name]=string.format("%02X%02X%02X",math.floor(ink[1]*255+0.5),math.floor(ink[2]*255+0.5),math.floor(ink[3]*255+0.5))end
local function keys(t,allowed)
  if type(t)~="table"then return false end
  for k in pairs(t)do if not allowed[k]then return false end end
  return true
end
function W.id(value)
  if type(value)=="number"then
    if value~=value or value<1 or value>W.MAX_ID or value%1~=0 then return nil end
    return string.format("%.0f",value)
  end
  if type(value)~="string"or #value<1 or #value>16 or value:sub(1,1)=="0"then return nil end
  local n=0
  for i=1,#value do
    local digit=string.byte(value,i)-48
    if digit<0 or digit>9 then return nil end
    n=n*10+digit;if n>W.MAX_ID then return nil end
  end
  if string.format("%.0f",n)~=value then return nil end
  return value
end
local function rule(raw)
  if not keys(raw,{kind=true,material=true,colour=true,priority=true,enabled=true})
    or(raw.kind~="buff"and raw.kind~="debuff"and raw.kind~="any")
    or not Materials.accepts(raw.material)
    or type(raw.colour)~="string"or Colours.hex(raw.colour)~=raw.colour
    or(raw.priority~=0 and raw.priority~=1 and raw.priority~=2)or type(raw.enabled)~="boolean"then return nil end
  return {kind=raw.kind,material=raw.material,colour=raw.colour,priority=raw.priority,enabled=raw.enabled}
end
function W.validate(raw)
  if raw==nil then raw={}end
  if not keys(raw,{hots=true,debuffs=true,selected_only=true,watch=true,debuff_colours=true,priorities=true,frame_rules=true,raid_tracker=true,large_alerts=true,alerts=true,scan_policy=true,target_buffs_only=true,hot_helper_ids=true})then return nil end
  local out={hots=true,debuffs=true,selected_only=true,watch={},debuff_colours={},priorities={},frame_rules={},raid_tracker=true,large_alerts=false,alerts={},scan_policy="balanced",target_buffs_only=false,hot_helper_ids={}}
  -- Retain the old boolean in saved files/profiles for compatibility. Display
  -- always requires explicit selection; false no longer enables all effects.
  for _,name in ipairs({"hots","debuffs","selected_only","raid_tracker","large_alerts","target_buffs_only"})do
    if raw[name]~=nil then if type(raw[name])~="boolean"then return nil end;out[name]=raw[name]end
  end
  if raw.scan_policy~=nil then
    if raw.scan_policy~="balanced"and raw.scan_policy~="debuff_priority"then return nil end
    out.scan_policy=raw.scan_policy
  end
  for _,name in ipairs({"watch","debuff_colours","priorities","alerts","hot_helper_ids"})do
    local source=raw[name]
    if source~=nil then
      if type(source)~="table"then return nil end
      local count=0
      for id,value in pairs(source)do
        count=count+1
        if count>W.MAX_ENTRIES or type(id)~="string"or W.id(id)~=id then return nil end
        if name=="watch"or name=="alerts"or name=="hot_helper_ids"then if value~=true then return nil end
        elseif name=="priorities"then if value~=1 and value~=2 then return nil end
        elseif type(value)~="string"or not palette[value]then return nil end
        if name=="debuff_colours"then
          out.frame_rules[id]={kind="debuff",material="tint",colour=legacyHex[value],priority=0,enabled=true}
        else out[name][id]=value end
      end
    end
  end
  if raw.frame_rules~=nil then
    if type(raw.frame_rules)~="table"then return nil end
    local count=0
    for id,value in pairs(raw.frame_rules)do
      count=count+1
      if count>W.MAX_ENTRIES or type(id)~="string"or W.id(id)~=id then return nil end
      local accepted=rule(value);if not accepted then return nil end
      out.frame_rules[id]=accepted
    end
  end
  local count=0;for _ in pairs(out.frame_rules)do count=count+1;if count>W.MAX_ENTRIES then return nil end end
  for id in pairs(out.priorities)do if out.watch[id]~=true then return nil end end
  return out
end
-- Internal read-only snapshot cache. A versioned caller MUST advance its
-- revision for every in-place authoring change; unversioned callers continue
-- validating on every call. Returned snapshots must not be mutated.
function W.revisionSnapshot()
  local rawBefore,revisionBefore,snapshot,has=nil,nil,nil,false
  return function(raw,revision)
    local versioned=type(revision)=="number"and revision==revision and revision>=0 and revision<=W.MAX_ID and revision%1==0
    if versioned and has and raw==rawBefore and revision==revisionBefore then return snapshot,false end
    local checked=W.validate(raw)
    rawBefore=nil;revisionBefore=nil;snapshot=nil;has=false
    if versioned and checked then rawBefore=raw;revisionBefore=revision;snapshot=checked;has=true end
    return checked,true
  end
end
-- User-selected helper IDs express a tracking preference, never caster or HoT evidence.
function W.targetOnly(options,id)
  id=W.id(id)
  return id~=nil and type(options)=="table"and options.target_buffs_only==true
    and type(options.hot_helper_ids)=="table"and options.hot_helper_ids[id]==true
end
function W.setHelper(raw,id,enabled)
  local out=W.validate(raw);id=W.id(id)
  if not out or not id or type(enabled)~="boolean"then return nil end
  out.hot_helper_ids[id]=enabled and true or nil;return W.validate(out)
end
function W.setAlert(raw,id,enabled)
  local out=W.validate(raw);id=W.id(id)
  if not out or not id or type(enabled)~="boolean"then return nil end
  out.alerts[id]=enabled and true or nil;return W.validate(out)
end
function W.alertSelected(raw,id)
  local out=W.validate(raw);id=W.id(id)
  return out~=nil and id~=nil and out.alerts[id]==true
end
function W.set(raw,id,enabled)
  local out=W.validate(raw);id=W.id(id)
  if not out or not id or type(enabled)~="boolean"then return nil end
  out.watch[id]=enabled and true or nil
  if not enabled then out.priorities[id]=nil end
  return W.validate(out)
end
function W.tint(raw,id,colour)
  local out=W.validate(raw);id=W.id(id)
  if not out or not id or type(colour)~="string"or(colour~="none"and not palette[colour])then return nil end
  if colour=="none"then out.frame_rules[id]=nil
  else
    local prior=out.frame_rules[id]
    out.frame_rules[id]={kind="debuff",material="tint",colour=legacyHex[colour],priority=prior and prior.priority or 0,enabled=true}
  end
  return W.validate(out)
end
function W.selected(raw,id)
  local out=W.validate(raw);id=W.id(id)
  return out~=nil and id~=nil and out.watch[id]==true
end
-- Priorities change only display preference for explicitly selected IDs.
-- Normal (0) is absent from the sparse saved map; no observation is implied.
function W.priority(raw,id)
  local out=W.validate(raw);id=W.id(id)
  if out and id and out.watch[id]==true then return out.priorities[id]or 0 end
  return 0
end
function W.setPriority(raw,id,value)
  local out=W.validate(raw);id=W.id(id)
  if not out or not id or out.watch[id]~=true or(value~=0 and value~=1 and value~=2)then return nil end
  out.priorities[id]=value~=0 and value or nil
  return W.validate(out)
end
function W.nextPriority(raw,id)
  local out=W.validate(raw);id=W.id(id)
  if not out or not id or out.watch[id]~=true then return nil end
  return ((out.priorities[id]or 0)+1)%3
end
function W.colour(raw,id)
  local out=W.validate(raw);id=W.id(id)
  local r=out and id and out.frame_rules[id]
  local ink=r and r.enabled and Colours.rgb(r.colour)
  if ink then return {ink[1],ink[2],ink[3]}end
end
function W.nextColour(raw,id)
  local out=W.validate(raw);id=W.id(id)
  if not out or not id then return nil end
  local r=out.frame_rules[id];local current="none"
  if r and r.enabled and r.kind=="debuff"and r.material=="tint"then
    for name,value in pairs(legacyHex)do if r.colour==value then current=name;break end end
  end
  for i=1,#order do if order[i]==current then return order[i%#order+1]end end
end
-- Frame treatments are authored independently from icon selection and priority.
-- This record expresses preference only, never an observed effect or kind.
function W.rule(raw,id)
  local out=W.validate(raw);id=W.id(id)
  return out and id and out.frame_rules[id]or nil
end
function W.setRule(raw,id,value)
  local out=W.validate(raw);id=W.id(id);local accepted=rule(value)
  if not out or not id or not accepted then return nil end
  out.frame_rules[id]=accepted;return W.validate(out)
end
function W.removeRule(raw,id)
  local out=W.validate(raw);id=W.id(id)
  if not out or not id then return nil end
  out.frame_rules[id]=nil;return W.validate(out)
end
function W.suggestions()
  local rows={}
  if W.commonEffectsContract~=1 then return rows end
  for _,row in ipairs(Common.rows())do
    local id=W.id(row.id)
    if id then rows[#rows+1]={id=row.id,name="Effect "..id}end
  end
  return rows
end
-- Configure a complete name/type group in one transaction. The caller receives
-- a new validated payload only when every known variant fits.
function W.setMany(raw,ids,action,value)
  local out=W.validate(raw)
  if not out or type(ids)~="table"or #ids<1 or #ids>W.MAX_ENTRIES then return nil end
  local count=0
  for key in pairs(ids)do
    if type(key)~="number"or key%1~=0 or key<1 or key>#ids then return nil end
    count=count+1
  end
  if count~=#ids then return nil end
  local accepted
  if action=="rule"then
    accepted=value~=false and rule(value)or nil
    if value~=false and not accepted then return nil end
  elseif action=="icon"or action=="alert"or action=="helper"then
    if type(value)~="boolean"then return nil end
  elseif action=="priority"then
    if value~=0 and value~=1 and value~=2 then return nil end
  else return nil end
  local seen={}
  for _,id in ipairs(ids)do
    if W.id(id)~=id or seen[id]then return nil end
    seen[id]=true
    if action=="icon"then out.watch[id]=value and true or nil;if not value then out.priorities[id]=nil end
    elseif action=="alert"then out.alerts[id]=value and true or nil
    elseif action=="helper"then out.hot_helper_ids[id]=value and true or nil
    elseif action=="priority"then
      if not out.watch[id]then return nil end
      out.priorities[id]=value~=0 and value or nil
    else
      out.frame_rules[id]=accepted and rule(accepted)or nil;out.debuff_colours[id]=nil
    end
  end
  return W.validate(out)
end
return W
