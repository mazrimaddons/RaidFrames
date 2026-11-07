-- Original geometry and owned colour surfaces; no copied code or assets.
local T={contract=1,expandedStylesContract=1,twoLooksContract=1}
local ellesmere={id="ellesmere",name="Ellesmere",subtitle="Flat role-coloured health and a thin power strip",inspiration="EllesmereUI visible raid-frame demo",
 swatch={0.24,0.56,0.77,1},canvas={0.025,0.035,0.045,1},track={0.10,0.12,0.14,1},
 fill={0.48,0.50,0.52,1},accent={0.77,0.84,0.91,1},ink={0.92,0.95,0.98,1},mana={0.20,0.41,0.83,1},
 border={0,0,0,1},shape="ellesmere",inset=1,manaHeight=2,roleFill="solid",roleIcons=true}
local previous={ellesmere=true,lumen=true,graphite=true,parchment=true,aurora=true,tactical=true,
 simple=true,soft=true,mono=true,bold=true,split=true,ribbon=true,capsule=true,glass=true,beacon=true}
function T.accepts(id)return id=="ellesmere"end
function T.migrate(id)if type(id)=="string"and previous[id]then return "ellesmere"end end
function T.get()return ellesmere end
function T.catalog()
 return {{id=ellesmere.id,name=ellesmere.name,subtitle=ellesmere.subtitle,inspiration=ellesmere.inspiration,
  swatch={ellesmere.swatch[1],ellesmere.swatch[2],ellesmere.swatch[3],ellesmere.swatch[4]}}}
end
local function roleColour(key)
 return ({HP_RAID_TANKER={0.24,0.56,0.77,1},HP_RAID_HEALER={0.64,0.43,0.73,1},HP_RAID_DEALER={0.76,0.41,0.35,1}})[key]
end
function T.roleAccent(theme,key)return roleColour(key)or ellesmere.accent end
function T.roleColour(theme,key)return roleColour(key)or ellesmere.fill end
return T
