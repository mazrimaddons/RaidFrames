-- Authored display rules only. No API reads, targeting, or live-state cache.
local ClassCategories=require("Mazrim_Raid_Frames/data/class_categories")
local O={contract=1,MAX_CLASSES=64}
O.categories={"tank","melee","healer","mage","ranged","flex"}
O.titles={tank="Tanks",melee="Melee",healer="Healers",mage="Mages",ranged="Ranged",flex="Any / unknown"}
local allowed={tank=true,melee=true,healer=true,mage=true,ranged=true,flex=true}
local function keys(v,a)if type(v)~="table"then return false end;for k in pairs(v)do if not a[k]then return false end end;return true end
function O.defaults()return{enabled=false,parties={["1"]="tank",["2"]="tank",["3"]="melee",["4"]="melee",["5"]="healer",["6"]="mage",["7"]="mage",["8"]="ranged",["9"]="ranged",["10"]="healer"},slots={},classes={}}end
function O.validate(v)
 if v==nil then return O.defaults()end
 if not keys(v,{enabled=true,parties=true,slots=true,classes=true})or type(v.enabled)~="boolean"or type(v.parties)~="table"or type(v.slots)~="table"or type(v.classes)~="table"then return nil end
 local out=O.defaults();out.enabled=v.enabled;local n=0
 for k,r in pairs(v.parties)do if type(k)~="string"or not out.parties[k]or not allowed[r]then return nil end;n=n+1;out.parties[k]=r end
 if n~=10 then return nil end
 for k,r in pairs(v.slots)do local slot
  for i=1,50 do if string.format("%d",i)==k then slot=i;break end end
  if not slot or not allowed[r]then return nil end;out.slots[k]=r
 end
 n=0;for name,r in pairs(v.classes)do
  n=n+1;if n>O.MAX_CLASSES or type(name)~="string"or #name<1 or #name>128 or name:find("[%c|]")or name:match("^%s*$")or not allowed[r]then return nil end
  out.classes[name]=r
 end
 return out
end
function O.defaultCategory(name)
 return type(name)=="string"and ClassCategories.classes[name:lower()]or"flex"
end
function O.category(row,rules)
 if row.classKnown~=true or type(row.className)~="string"then return"flex"end
 return rules.classes[row.className]or O.defaultCategory(row.className)
end
-- Entries carry row_index and canonical slot. Explicit assignments reserve
-- their address first; custom category slots precede inherited party rules.
-- Overflow always remains visible, even when a template cannot fit the raid.
function O.arrange(rows,entries,rules)
 local occupied,pending={},{}
 for _,p in ipairs(entries)do
  if p.pinned then
   local at=(p.group-1)*5+math.min(p.order,5)
   if not occupied[at]then occupied[at]=p else pending[#pending+1]=p end
  else pending[#pending+1]=p end
 end
 local function take(slot,category)
  if occupied[slot]then return end
  for i,p in ipairs(pending)do if p and(category=="flex"or O.category(rows[p.row_index],rules)==category)then occupied[slot]=p;for j=i,#pending-1 do pending[j]=pending[j+1]end;pending[#pending]=nil;return end end
 end
 for slot=1,50 do local r=rules.slots[string.format("%d",slot)];if r then take(slot,r)end end
 for slot=1,50 do if not rules.slots[string.format("%d",slot)]then take(slot,rules.parties[string.format("%d",math.floor((slot-1)/5)+1)])end end
 -- Native-slot ordering is a deterministic tie-break, never an identity guess.
 for slot=1,50 do if not rules.slots[string.format("%d",slot)]then take(slot,"flex")end end
 local overflow=#pending
 for slot=1,50 do take(slot,"flex")end
 local out={};for slot=1,50 do local p=occupied[slot];if p then p.group=math.floor((slot-1)/5)+1;p.order=(slot-1)%5+1;p.position=p.order;out[#out+1]=p end end
 return out,overflow
end
function O.sample(raw,classNames)
 local rules=O.validate(raw);if not rules then return nil end
 local rows,entries,counts={},{},{};local roles={"tank","melee","healer","mage","ranged"}
 for i=1,40 do
  local category=roles[(i-1)%5+1];counts[category]=(counts[category]or 0)+1;local name=category.." "..counts[category]
  rows[i]={name=name,roleKnown=true,role=category,classKnown=true,className="Example "..category,slot=i}
  if type(classNames)=="table"and #classNames>0 then
   local class=classNames[(i-1)%#classNames+1]
   rows[i]={name=class,roleKnown=false,classKnown=true,className=class,slot=i}
   rows[i].role=O.category(rows[i],rules)
  else rules.classes["Example "..category]=category end
  entries[i]={row_index=i,group=math.floor((i-1)/5)+1,order=(i-1)%5+1,slot=i}
 end
 local arranged=O.arrange(rows,entries,rules);return rows,arranged
end
return O
