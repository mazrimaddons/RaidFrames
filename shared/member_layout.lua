-- Authored exact-name layout choices; runtime identities are never persisted.
local Ordering=require("Mazrim_Raid_Frames/shared/ordering")
local I=require("Mazrim_Raid_Frames/shared/identity")
local M={contract=1,MAX_ASSIGNMENTS=50}
local function integer(v,lo,hi)return type(v)=="number"and v==v and v%1==0 and v>=lo and v<=hi end
local function keys(t,allowed)
 if type(t)~="table"then return false end
 for k in pairs(t)do if not allowed[k]then return false end end
 return true
end
function M.name(value)
 if type(value)~="string"or #value<1 or #value>96 or value:find("[%c|]")or value:match("^%s")or value:match("%s$")then return nil end
 return value
end
-- Display placement may use accepted name/slot metadata without a rendered
-- actor. This does not produce an identity or authorize unit API operations.
function M.arrangeable(row)
 return type(row)=="table"and row.kind=="raid"and row.nameKnown==true and M.name(row.name)~=nil
  and(I.accepts(row.identity)or(row.identity==nil and row.state=="SLOT_METADATA"and integer(row.slot,1,50)))
end
function M.unique(rows,row)
 if not M.arrangeable(row)then return false end
 local names,ids,slots,index=0,0,0,nil
 for i,r in ipairs(rows)do if r==row then index=i end end
 if not index then return false end
 local slot=integer(row.slot,1,50)and row.slot or index
 for i,r in ipairs(rows)do
  if r.nameKnown==true and r.name==row.name then names=names+1 end
  if I.accepts(row.identity)and r.identity==row.identity then ids=ids+1 end
  if(integer(r.slot,1,50)and r.slot or i)==slot then slots=slots+1 end
 end
 return names==1 and slots==1 and(not I.accepts(row.identity)or ids==1)
end
function M.position(raw)
 if raw==nil then return{custom_position=false,x=0,y=0}end
 if not keys(raw,{custom_position=true,x=true,y=true})or type(raw.custom_position)~="boolean"
  or not integer(raw.x,0,32768)or not integer(raw.y,0,32768)then return nil end
 return{custom_position=raw.custom_position,x=raw.x,y=raw.y}
end
function M.defaults()return{enabled=false,assignments={},priority=M.position(),dock=M.position(),sort="native",manual_slots=false,ordering=Ordering.defaults(),raid_pins={}}end
function M.validate(raw)
 if raw==nil then return M.defaults()end
 if not keys(raw,{enabled=true,assignments=true,priority=true,dock=true,sort=true,manual_slots=true,ordering=true,raid_pins=true})or type(raw.enabled)~="boolean"or type(raw.assignments)~="table"then return nil end
 local priority=M.position(raw.priority);local dock=M.position(raw.dock)
 local ordering=Ordering.validate(raw.ordering)
 if not ordering or(raw.raid_pins~=nil and type(raw.raid_pins)~="table")then return nil end
 local pins={};local pinCount=0
 for name,value in pairs(raw.raid_pins or{})do pinCount=pinCount+1;if pinCount>50 or M.name(name)~=name or value~=true or not raw.assignments[name]then return nil end;pins[name]=true end
 if not priority or not dock or(raw.sort~=nil and raw.sort~="native"and raw.sort~="class")or(raw.manual_slots~=nil and type(raw.manual_slots)~="boolean")then return nil end
 local out={enabled=raw.enabled,assignments={},priority=priority,dock=dock,sort=raw.sort or"native",manual_slots=raw.manual_slots==true,ordering=ordering,raid_pins=pins};local count=0
 for name,record in pairs(raw.assignments)do
  count=count+1
  if count>M.MAX_ASSIGNMENTS or M.name(name)~=name or not keys(record,{group=true,order=true})
   or(record.group~="priority"and not integer(record.group,1,10))or not integer(record.order,1,50)then return nil end
  out.assignments[name]={group=record.group,order=record.order}
 end
 return out
end
function M.assignmentFor(raw,name)
 local checked=M.validate(raw);name=M.name(name)
 return checked and name and checked.assignments[name]or nil
end
function M.set(raw,name,group,order)
 local checked=M.validate(raw);name=M.name(name)
 if not checked or not name then return nil end
 if group==nil or group=="original"then checked.assignments[name]=nil;checked.raid_pins[name]=nil
 else checked.assignments[name]={group=group,order=order}end
 return M.validate(checked)
end
local function insert(list,item)
 local n=#list+1
 while n>1 do
  local prior=list[n-1]
  local before=item.group<prior.group or(item.group==prior.group and(item.order<prior.order or(item.order==prior.order and item.row_index<prior.row_index)))
  if not before then break end
  list[n]=prior;n=n-1
 end
 list[n]=item
end
function M.project(rows,raw)
 local checked=M.validate(raw);if not checked or type(rows)~="table"or #rows>50 then return nil end
 local names,identities,slots={},{},{}
 for i,r in ipairs(rows)do
  if type(r)=="table"and r.kind=="raid"then
   local slot=integer(r.slot,1,50)and r.slot or i;slots[slot]=(slots[slot]or 0)+1
   if I.accepts(r.identity)then identities[r.identity]=(identities[r.identity]or 0)+1 end
   if r.nameKnown==true and M.name(r.name)then names[r.name]=(names[r.name]or 0)+1 end
  end
 end
 local classOrder={};if checked.enabled and checked.sort=="class"then for i,r in ipairs(rows)do classOrder[#classOrder+1]={index=i,key=r.classKnown==true and type(r.className)=="string"and r.className or "~",slot=r.slot or i}end end
 if checked.sort=="class"then
  for i=2,#classOrder do local v=classOrder[i];local j=i
   while j>1 and(v.key<classOrder[j-1].key or(v.key==classOrder[j-1].key and v.slot<classOrder[j-1].slot))do classOrder[j]=classOrder[j-1];j=j-1 end;classOrder[j]=v
  end
 end
 local ranks={};for rank,v in ipairs(classOrder)do ranks[v.index]=rank end
 local result={main={},priority={},enabled=checked.enabled,applied=checked.sort=="class"and 1 or 0}
 for i,r in ipairs(rows)do
  if type(r)~="table"then return nil end
  local slot=integer(r.slot,1,50)and r.slot or i
  local display=checked.enabled and checked.sort=="class"and ranks[i]or slot
  local group,order=math.floor((display-1)/5)+1,(display-1)%5+1
  local record=M.arrangeable(r)and names[r.name]==1 and slots[slot]==1 and(not I.accepts(r.identity)or identities[r.identity]==1)and checked.assignments[r.name]or nil
  if record and(checked.enabled or record.group=="priority")then group=record.group;order=record.order;result.applied=result.applied+1 else record=nil end
  if group=="priority"then insert(result.priority,{row_index=i,group=1,order=order,slot=slot})
  else insert(result.main,{row_index=i,group=group,order=order,slot=slot,pinned=record~=nil})end
 end
 if checked.enabled and checked.ordering.enabled then
  result.applied=result.applied+1
  result.main,result.overflow=Ordering.arrange(rows,result.main,checked.ordering)
  result.fixed_slots=true
  for i,p in ipairs(result.priority)do p.position=i end
  return result
 end
 result.fixed_slots=checked.manual_slots or checked.sort=="native"
 if not checked.manual_slots then for _,p in ipairs(result.main)do
  local row=rows[p.row_index]
  if checked.enabled and checked.assignments[row.name]then result.fixed_slots=false;break end
 end end
 -- Saved manual edits may put two names in one slot or retain an old
 -- order above five. Repair projection only; never discard a member or rewrite
 -- the saved choice during a read. Valid unoccupied slots keep their addresses.
 if checked.manual_slots then
  local occupied,pending={},{}
  for pass=1,2 do for _,p in ipairs(result.main)do
   if(pass==1)==(p.pinned==true)then local slot=(p.group-1)*5+p.order
    if p.order<=5 and not occupied[slot]then occupied[slot]=true else pending[#pending+1]=p end
   end
  end end
  for _,p in ipairs(pending)do
   local start=(p.group-1)*5+math.min(p.order,5)
   for offset=0,49 do local slot=(start-1+offset)%50+1
    if not occupied[slot]then occupied[slot]=true;p.group=math.floor((slot-1)/5)+1;p.order=(slot-1)%5+1;break end
   end
  end
  if #pending>0 then local ordered={};for _,p in ipairs(result.main)do insert(ordered,p)end;result.main=ordered end
 end
 local counts={}
 for _,p in ipairs(result.main)do counts[p.group]=(counts[p.group]or 0)+1;p.position=result.fixed_slots and p.order or counts[p.group]end
 for i,p in ipairs(result.priority)do p.position=i end
 return result
end
-- At capacity, reclaim only session pins absent from a fully named roster.
-- Unresolved names could still belong to members with existing placements.
local function validateMove(layout,rows,names)
 local count=0
 for _ in pairs(layout.assignments)do count=count+1 end
 if count>M.MAX_ASSIGNMENTS then
  for _,row in ipairs(rows)do
   if row.nameKnown~=true or names[row.name]~=1 then return nil end
  end
  for name in pairs(layout.raid_pins)do
   if not names[name]then layout.raid_pins[name]=nil;layout.assignments[name]=nil end
  end
 end
 return M.validate(layout)
end
-- Changes are display-only and atomic. A drag snapshot pins every current
-- occupant, so sparse destinations stay empty and swaps cannot compact peers.
function M.move(rows,raw,name,group,order)
 local checked=M.validate(raw);local projection=checked and M.project(rows,checked)
 if not projection or not M.name(name)or(group~="priority"and not integer(group,1,10))or not integer(order,1,group=="priority"and 50 or 5)then return nil end
 local source,target,all=nil,nil,{}
 local names,ids,slots={},{},{}
 for i,r in ipairs(rows)do
  if r.nameKnown==true and M.name(r.name)then names[r.name]=(names[r.name]or 0)+1 end
  if I.accepts(r.identity)then ids[r.identity]=(ids[r.identity]or 0)+1 end
  local slot=integer(r.slot,1,50)and r.slot or i;slots[slot]=(slots[slot]or 0)+1
 end
 for _,panel in ipairs({"main","priority"})do for _,p in ipairs(projection[panel])do
  local row=rows[p.row_index];local g=panel=="priority"and"priority"or p.group
  local slot=integer(row.slot,1,50)and row.slot or p.row_index
  local movable=M.arrangeable(row)and names[row.name]==1 and slots[slot]==1 and(not I.accepts(row.identity)or ids[row.identity]==1)
  if g~="priority"and p.position>5 then return nil end
  local item={name=row.name,identity=row.identity,group=g,order=p.position,movable=movable};all[#all+1]=item
  if item.name==name and movable then source=item end
  if g==group and p.position==order then if target then return nil end;target=item end
 end end
 if not source or(target and not target.movable)then return nil end
 if target and target~=source then target.group=source.group;target.order=source.order end
 source.group=group;source.order=order
 if checked.ordering.enabled then
  checked.enabled=true;checked.manual_slots=true
  checked.assignments[source.name]={group=source.group,order=source.order};checked.raid_pins[source.name]=true
  if target and target~=source then checked.assignments[target.name]={group=target.group,order=target.order};checked.raid_pins[target.name]=true end
  return validateMove(checked,rows,names)
 end
 checked.enabled=true;checked.sort="native";checked.manual_slots=true
 for _,item in ipairs(all)do if item.movable then checked.assignments[item.name]={group=item.group,order=item.order};checked.raid_pins[item.name]=true end end
 local valid=validateMove(checked,rows,names);local result=valid and M.project(rows,valid);if not result then return nil end
 local occupied={};for _,p in ipairs(result.main)do local slot=(p.group-1)*5+p.order;if occupied[slot]then return nil end;occupied[slot]=true end
 return valid
end
-- Release only this identified member's Priority assignment. Restore a prior
-- authored address only when it is vacant; never swap another player into
-- Priority as a side effect of Reset. Origins are controller-session data.
function M.resetPriority(rows,raw,name,identity,origin,slot)
 local checked=M.validate(raw);local projection=checked and M.project(rows,checked)
 if not projection or not M.name(name)or(not I.accepts(identity)and not(identity==nil and integer(slot,1,50)))then return nil end
 local found
 for _,p in ipairs(projection.priority)do local r=rows[p.row_index]
  if r.name==name and r.identity==identity and(I.accepts(identity)or(r.slot==slot and M.arrangeable(r)))and M.unique(rows,r)then if found then return nil end;found=r end
 end
 if not found then return nil end
 checked.assignments[name]=nil;checked.raid_pins[name]=nil
 if checked.enabled and checked.ordering.enabled then return M.validate(checked),"category"end
 if type(origin)=="table"and origin.name==name and origin.assigned==true
  and((I.accepts(origin.identity)and origin.identity==identity)or(origin.identity==nil and origin.slot==found.slot))
  and integer(origin.group,1,10)and integer(origin.order,1,5)then
  local occupied=false
  for _,p in ipairs(projection.main)do if p.group==origin.group and p.position==origin.order then occupied=true;break end end
  if not occupied then
   checked.assignments[name]={group=origin.group,order=origin.order}
   checked.raid_pins[name]=origin.pinned==true and true or nil
   return M.validate(checked),"origin"
  end
 end
 return M.validate(checked),"original"
end
return M
