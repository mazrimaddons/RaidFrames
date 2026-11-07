-- Fixed, original static artwork. No live observations or native handles.
local M={contract=1,path="Addon/Mazrim_Raid_Frames/assets/debuff-materials.dds",width=1024,height=512,tileWidth=256,tileHeight=128}
M.order={"tint","stone","frost","embers","poison","bleed","shadow","lightning","roots","rust","arcane","sand"}
M.labels={tint="Colour",stone="White stone",frost="Frost",embers="Embers",poison="Poison",bleed="Bleed",shadow="Shadow",lightning="Lightning",roots="Roots",rust="Rust",arcane="Arcane",sand="Sand"}
local indices={};for i,id in ipairs(M.order)do indices[id]=i end
function M.accepts(id)return type(id)=="string"and indices[id]~=nil end
function M.get(id)
 local index=indices[id];if not index then return nil end
 local out={id=id,label=M.labels[id]}
 if index>1 then local n=index-2;out.tile={x=n%4*256,y=math.floor(n/4)*128,w=256,h=128}end
 return out
end
function M.next(id)local index=indices[id];return index and M.order[index%#M.order+1]or nil end
function M.defaultColour(id)
 if not M.accepts(id)then return nil end
 return id=="stone"and"EEECE5"or id=="tint"and"C26959"or"FFFFFF"
end
return M
