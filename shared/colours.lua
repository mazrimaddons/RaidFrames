-- Authored display colours only. No unit/class inference, native calls or IO.
local C={contract=1,overhaulContract=1,MAX_CLASSES=64,MAX_CLASS_NAME=128,PALETTE_VERSION=2}
local defaults={neutral="7A8085",tank="3D8FC4",healer="E879B0",damage="C26959",
 name="EAF0F4",self_name="FCDB27",health_text="FFFFFF",mana="3369D4",
 target="FFC93D",hover="F0FAFF",low_health="FF291F",low_mana="FFB01F"}
local dpsDefaults={mage="9B6DE3",ranged="4DBB63",melee="DC4D4D"}
function C.hex(value)
 if type(value)~="string"then return nil end
 if value:sub(1,1)=="#"then value=value:sub(2)end
 if #value~=6 or value:find("[^0-9a-fA-F]")then return nil end
 return value:upper()
end
function C.defaults()
 local out={classes={},dps={},health_styles={},palette_version=C.PALETTE_VERSION};for key,value in pairs(defaults)do out[key]=value end;return out
end
function C.healthColour(palette,style)
 local p=type(palette)=="table"and palette or nil
 local map=p and type(p.health_styles)=="table"and p.health_styles or nil
 local value=map and map[style]
 if style=="fill"and value==nil then value=map and map.hatch end
 if type(value)=="string"and C.hex(value)==value then return value end
 value=p and p.low_health
 return type(value)=="string"and C.hex(value)==value and value or defaults.low_health
end
function C.dpsColour(palette,family)
 if not dpsDefaults[family]then return nil end
 local map=type(palette)=="table"and type(palette.dps)=="table"and palette.dps or{}
 local value=map[family]
 return type(value)=="string"and C.hex(value)==value and value or dpsDefaults[family]
end
function C.className(value)
 if type(value)~="string"or #value<1 or #value>C.MAX_CLASS_NAME or value:find("[%c|]")or not value:find("%S")then return nil end
 return value
end
function C.validate(raw)
 if raw==nil then return C.defaults()end
 if type(raw)~="table"then return nil end
 local out=C.defaults()
 for key,value in pairs(raw)do
  if key=="palette_version"then
   if value~=1 and value~=C.PALETTE_VERSION then return nil end
  elseif key=="health_styles"then
   if type(value)~="table"then return nil end
   for style,ink in pairs(value)do
    if(style~="outline"and style~="badge"and style~="hatch"and style~="fill")or type(ink)~="string"or C.hex(ink)~=ink then return nil end
    out.health_styles[style]=ink
   end
  elseif key=="dps"then
   if type(value)~="table"then return nil end
   for family,ink in pairs(value)do
    if(family~="mage"and family~="ranged"and family~="melee")or type(ink)~="string"or C.hex(ink)~=ink then return nil end
    out.dps[family]=ink
   end
  elseif key=="classes"then
   if type(value)~="table"then return nil end
   local count=0
   for name,ink in pairs(value)do
    count=count+1
    if count>C.MAX_CLASSES or C.className(name)~=name or type(ink)~="string"or C.hex(ink)~=ink then return nil end
    out.classes[name]=ink
   end
  else
   if defaults[key]==nil or C.hex(value)~=value then return nil end
   out[key]=value
  end
 end
 -- Only the shipped legacy healer default changes. The marker makes this a
 -- one-time migration, so choosing the old purple explicitly still works in
 -- current palettes. Sparse DPS maps retain only authored overrides.
 if(raw.palette_version==nil or raw.palette_version==1)and raw.healer=="A36EBA"then out.healer=defaults.healer end
 return out
end
function C.rgb(value)
 if type(value)~="string"or C.hex(value)~=value then return nil end
 local function byte(at)
  local n=0
  for i=at,at+1 do local b=string.byte(value,i);n=n*16+(b<=57 and b-48 or b-55)end
  return n/255
 end
 return {byte(1),byte(3),byte(5),1}
end
return C
