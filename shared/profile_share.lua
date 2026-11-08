-- Portable, data-only profiles. MRF1 sends differences against a checked
-- baseline; its fingerprint prevents changed defaults being silently applied.
local F=require("Mazrim_Raid_Frames/shared/foundation")
local P=require("Mazrim_Raid_Frames/shared/preferences")
local S={contract=1,CHAT_LIMIT=120,MAX_CODE=49152,MAX_PARTS=32}
S.targetBuffPolicyContract=2
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local values={}
for n=1,#alphabet do values[alphabet:sub(n,n)]=n-1 end
-- Fixed MRF1 tags keep common profiles short enough for chat.
local keys={"settings","view","options","raid","party","display","width","height","columns","gap_x","gap_y",
 "appearance","mode","opacity","colours","member_layout","ordering","enabled","slots","parties","classes",
 "auras","watch","alerts","frame_rules","priorities","kind","material","colour","priority","aura_icons",
 "anchor","positions","text_positions","name","health","distance","x","y","indicators","range","input"}
local keyCode={}
for i,k in ipairs(keys)do keyCode[k]=alphabet:sub(i,i)end
local function hash(text)
 local a,b=1,0
 for i=1,#text do a=(a+text:byte(i))%65521;b=(b+a)%65521 end
 return string.format("%04x%04x",b,a)
end
local function encode64(text)
 local result={}
 for i=1,#text,3 do
  local a,b,c=text:byte(i,i+2)
  local n=a*65536+(b or 0)*256+(c or 0)
  local function digit(divisor)
   local at=math.floor(n/divisor)%64+1;return alphabet:sub(at,at)
  end
  result[#result+1]=digit(262144)..digit(4096)..(b and digit(64)or"")..(c and digit(1)or"")
 end
 return table.concat(result)
end
local function decode64(text)
 if #text%4==1 or text:find("[^A-Za-z0-9_-]")then return nil end
 local result={}
 for i=1,#text,4 do
  local a,b,c,d=values[text:sub(i,i)],values[text:sub(i+1,i+1)],values[text:sub(i+2,i+2)],values[text:sub(i+3,i+3)]
  if not c and b%16~=0 or c and not d and c%4~=0 then return nil end
  local n=a*262144+b*4096+(c or 0)*64+(d or 0)
  result[#result+1]=string.char(math.floor(n/65536),c and math.floor(n/256)%256 or 0,d and n%256 or 0):sub(1,d and 3 or c and 2 or 1)
 end
 return table.concat(result)
end
local function sized(tag,text)return tag..#text..":"..text end
local function encode(v,out)
 local kind=type(v)
 if kind=="table"then
  local keys={}
  for k in pairs(v)do keys[#keys+1]=k end
  table.sort(keys)
  out[#out+1]="{"
  for _,k in ipairs(keys)do out[#out+1]=keyCode[k]and("@"..keyCode[k])or sized("",k);encode(v[k],out)end
  out[#out+1]="}"
 elseif kind=="boolean"then out[#out+1]=v and"t"or"f"
 elseif kind=="number"then out[#out+1]=sized("n",string.format("%.17g",v))
 else out[#out+1]=sized("s",v)end
end
local function serial(v)
 local out={};encode(v,out);return table.concat(out)
end
local function parse(text)
 local at,nodes=1,0
 local function readSized(limit)
  local tail=text:find(":",at,true)
  if not tail or tail-at<1 or tail-at>3 then return nil end
  local digits=text:sub(at,tail-1)
  local len=digits:match("^%d+$")and tonumber(digits)
  if not len or len>limit or tail+len>#text then return nil end
  at=tail+len+1;return text:sub(tail+1,tail+len)
 end
 local function value(depth)
  nodes=nodes+1
  if nodes>6000 or depth>10 then return nil end
  local tag=text:sub(at,at);at=at+1
  if tag=="t"then return true elseif tag=="f"then return false end
  if tag=="s"then return readSized(128)end
  if tag=="n"then
   local raw=readSized(32);local num=raw and raw:match("^[%d%.e+-]+$")and tonumber(raw)
   if num and num==num and num>-math.huge and num<math.huge then return num end
   return nil
  end
  if tag~="{"then return nil end
  local out,count={},0
  while text:sub(at,at)~="}"do
   local k
   if text:sub(at,at)=="@"then
    local code=values[text:sub(at+1,at+1)];at=at+2
    k=code and keys[code+1]
   else k=readSized(128)end
   if not k or k==""or out[k]~=nil or count>=P.MAX_TABLE_FIELDS then return nil end
   local v=value(depth+1)
   if v==nil then return nil end
   out[k]=v;count=count+1
  end
  at=at+1;return out
 end
 local result=value(0)
 if type(result)=="table"and at==#text+1 then return result end
end
local function any(t)for _ in pairs(t)do return true end;return false end
local baseline,fingerprint
local function prepareDefaults()
 if baseline then return end
 baseline=P.snapshot({settings=F.settings(),view={layout="raid",preview_count=25,position="left",native_style=true}},true)
 -- Keep the established MRF1 baseline and existing codes byte-compatible.
 -- A true opt-in travels as an explicit difference in full profiles.
 baseline.options.auras.target_buffs_only=nil
 baseline.options.auras.hot_helper_ids=nil
 fingerprint=hash(serial(baseline))
end
local function diff(value,default)
 if type(value)~="table"or type(default)~="table"then
  if value~=default then return value end
  return nil
 end
 local result,any={},false
 for k,v in pairs(value)do
  local d=diff(v,default[k])
  if d~=nil then result[k]=d;any=true end
 end
 if any then return result end
end
local function apply(target,patch)
 for k,v in pairs(patch)do
  if type(v)=="table"and type(target[k])=="table"then apply(target[k],v)
  else target[k]=v end
 end
end
local function portable(profile,mode)
 local out=P.snapshot(profile,true);if not out then return nil end
 local members=out.options.member_layout
 members.assignments={};members.raid_pins={};members.manual_slots=false
 if mode=="L"then
  out.options.auras=P.copy(baseline.options.auras)
  out.options.aura_icons.positions={}
  out.options.input=P.copy(baseline.options.input)
 end
 if out.options.auras.target_buffs_only==false then out.options.auras.target_buffs_only=nil end
 if out.options.auras.hot_helper_ids and not any(out.options.auras.hot_helper_ids)then out.options.auras.hot_helper_ids=nil end
 return out
end
function S.encode(profile,mode)
 if mode~="L"and mode~="F"then return nil end
 prepareDefaults()
 local clean=portable(profile,mode);if not clean then return nil end
 local payload=encode64(serial(diff(clean,baseline)or{}))
 local body=mode.."-"..fingerprint.."-"..payload
 local code="MRF1-"..hash(body).."-"..body
 if #code<=S.MAX_CODE then return code end
end
function S.decode(code)
 if type(code)~="string"or #code>S.MAX_CODE+16 then return nil,"Invalid or oversized code."end
 code=code:match("^%s*(.-)%s*$")
 local sum,mode,defaults,payload=code:match("^MRF1%-(%x%x%x%x%x%x%x%x)%-([LF])%-(%x%x%x%x%x%x%x%x)%-([A-Za-z0-9_-]+)$")
 if not payload then return nil,"Use a complete MRF1 profile code."end
 prepareDefaults()
 if defaults~=fingerprint then return nil,"This code uses different profile defaults."end
 if hash(mode.."-"..defaults.."-"..payload)~=sum then return nil,"The code is incomplete or changed."end
 local raw=decode64(payload);local patch=raw and parse(raw)
 if not patch then return nil,"The code has invalid profile data."end
 for k in pairs(patch)do if k~="settings"and k~="view"and k~="options"then return nil,"The code has invalid profile data."end end
 local data=P.copy(baseline);apply(data,patch)
 local clean=portable(data,mode)
 if not clean or S.encode(clean,mode)~=code then return nil,"The code has invalid or unsupported settings."end
 return P.snapshot(clean,true),mode
end
function S.parts(code)
 if type(code)~="string"or #code>S.MAX_CODE then return nil end
 if #code<=S.CHAT_LIMIT then return {code}end
 local width=S.CHAT_LIMIT-22;local count=math.ceil(#code/width)
 if count>S.MAX_PARTS then return nil end
 local id=hash(code);local parts={}
 for n=1,count do
  parts[n]=string.format("MRF1P-%s-%02d-%02d-%s",id,n,count,code:sub((n-1)*width+1,n*width))
 end
 return parts
end
function S.acceptPart(session,text)
 if type(text)~="string"or #text>S.CHAT_LIMIT then return nil end
 if text:sub(1,5)=="MRF1-"then return text end
 local id,index,total,part=text:match("^MRF1P%-(%x%x%x%x%x%x%x%x)%-(%d%d)%-(%d%d)%-([A-Za-z0-9_-]+)$")
 if not part then return nil end
 index,total=tonumber(index),tonumber(total)
 if total<2 or total>S.MAX_PARTS or index<1 or index>total then return nil end
 if session.id and(session.id~=id or session.total~=total)then return nil end
 session.id=id;session.total=total
 if session.parts[index]then
  if session.parts[index]~=part then return nil,"Conflicting parts. Start receiving again."end
  return nil
 end
 session.parts[index]=part;session.count=session.count+1
 if session.count<total then return nil,string.format("Received %d of %d parts.",session.count,total)end
 local code=table.concat(session.parts,"",1,total)
 if hash(code)~=id then return nil,"The whisper was shortened or changed. Start again or paste the full code."end
 return code
end
return S
