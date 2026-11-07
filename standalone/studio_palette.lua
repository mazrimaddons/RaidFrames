-- Reviewed first-party Antique Gold tokens and button contrast logic.
local Themes={contract=1,overhaulContract=1}
local palette={["id"]="gilded_reliquary",["name"]="Antique Gold",["family"]="Worlds",["frame"]="reliquary",["motif"]="filigree",["panel"]={0.129411765,0.11372549,0.098039216,1},["nav"]={0.090196078,0.078431373,0.062745098,1},["detail"]={0.188235294,0.168627451,0.141176471,1},["header"]={0.129411765,0.11372549,0.098039216,1},["text"]={0.949019608,0.91372549,0.835294118,1},["muted"]={0.760784314,0.71372549,0.619607843,1},["headerText"]={0.949019608,0.91372549,0.835294118,1},["button"]={0.188235294,0.168627451,0.141176471,1},["buttonText"]={0.949019608,0.91372549,0.835294118,1},["edge"]={0.568627451,0.517647059,0.439215686,1},["decorativeEdge"]={0.419607843,0.349019608,0.235294118,1},["accent"]={0.882352941,0.749019608,0.478431373,1},["ornament"]={0.619607843,0.749019608,0.690196078,1},["action"]={0.882352941,0.749019608,0.478431373,1},["actionText"]={0.2,0.149019608,0.082352941,1},["selected"]={0.266666667,0.223529412,0.164705882,1},["success"]={0.568627451,0.850980392,0.717647059,1},["warning"]={0.960784314,0.788235294,0.482352941,1},["error"]={1.0,0.678431373,0.721568627,1},["info"]={0.68627451,0.803921569,0.956862745,1}}
local function copy(v)if type(v)~="table"then return v end;local r={};for k,x in pairs(v)do r[k]=copy(x)end;return r end
function Themes.has(id)return id=="gilded_reliquary"end
function Themes.get(id)if Themes.has(id)then return copy(palette)end end
local function mix(a,b,t)
    local result={}
    for i=1,4 do result[i]=(a[i] or 1)*(1-t)+(b[i] or 1)*t end
    return result
end
local function luminance(rgb)
    local total=0
    for i,w in ipairs({0.2126,0.7152,0.0722}) do
        local v=rgb[i]
        total=total+w*(v<=0.04045 and v/12.92 or ((v+0.055)/1.055)^2.4)
    end
    return total
end
local function contrast(a,b)
    a,b=luminance(a),luminance(b)
    return (math.max(a,b)+0.05)/(math.min(a,b)+0.05)
end
-- Explicit action/selection roles from the approved design tokens. Text and
-- control edges are contrast-paired; status meaning is never inferred by hue.
function Themes.buttonStyle(p,state)
    local fill,edge,ink=p.button,p.edge,p.buttonText
    if state=="enable" or state=="action" then fill,edge,ink=p.action,p.accent,p.actionText
    elseif state=="selected" then fill,edge=p.selected,p.accent
    elseif state=="disable" then fill=mix(p.button,p.panel,0.35)
    elseif state=="hover" or state=="focus" then fill,edge=mix(p.selected,p.button,0.35),p.accent
    elseif state=="pressed" then fill,edge=mix(p.selected,p.panel,0.3),p.accent
    elseif state=="unavailable" then fill=mix(p.button,p.panel,0.65) end
    if contrast(ink,fill)<4.5 then
        local black,white={0,0,0,1},{1,1,1,1}
        ink=contrast(black,fill)>contrast(white,fill) and black or white
    end
    return {fill=copy(fill),edge=copy(edge),ink=copy(ink)}
end
return Themes
