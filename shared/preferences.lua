-- Host-independent display preferences. No live units, runtime arming or IO.
local F=require("Mazrim_Raid_Frames/shared/foundation")
local Watchlist=require("Mazrim_Raid_Frames/shared/watchlist")
local Themes=require("Mazrim_Raid_Frames/shared/themes")
local Colours=require("Mazrim_Raid_Frames/shared/colours")
local MemberLayout=require("Mazrim_Raid_Frames/shared/member_layout")
local P={contract=1,helpContract=1,watchlistContract=Watchlist.contract==1 and Watchlist.commonEffectsContract==1 and 1 or 0,
  priorityContract=Watchlist.priorityContract==1 and 1 or 0,
  expandedStylesContract=Themes.expandedStylesContract==1 and type(Themes.accepts)=="function"and 1 or 0,
  overhaulContract=Colours.overhaulContract==1 and 1 or 0,visibilityContract=1,roleIconToggleContract=1,
  frameRulesContract=Watchlist.frameRulesContract==1 and 1 or 0,MAX_PROFILES=8}
P.targetBuffPolicyContract=Watchlist.targetBuffPolicyContract==1 and 1 or 0
-- A full active setup plus all eight allowed profiles. Per snapshot reserve:
-- fixed settings/view/options fields and containers (128), four scalar aura
-- maps plus six nodes per frame rule (10 per ID), four nodes per assignment,
-- and one node per class override; four nodes cover the sparse DPS palette,
-- plus one scalar palette migration revision.
-- The final128 covers global root metadata.
-- Additional200 covers bounded party rules,50 custom slots,64 class-category
-- mappings and50 raid-only pin flags, including their containers.
-- Per-table capacity also covers the expanded spell-variant maps.
-- Grouped icon anchors plus64 per-effect anchors add at most197 nodes/setup.
-- Independent name/health anchors add at most8 nodes/setup.
-- Optional distance text/anchor and warning treatment controls add11/setup.
P.MAX_COPY_NODES=(P.MAX_PROFILES+1)*(358+10*Watchlist.MAX_ENTRIES+4*MemberLayout.MAX_ASSIGNMENTS+Colours.MAX_CLASSES+200)+128
P.MAX_TABLE_FIELDS=math.max(100,Watchlist.MAX_ENTRIES)
local function finite(v)return type(v)=="number"and v==v and v>-1/0 and v<1/0 end
local function keys(t,allowed)
  if type(t)~="table"then return false end
  for k in pairs(t)do if not allowed[k]then return false end end
  return true
end
local function bool(v,default)
  if v==nil then return default end
  if type(v)=="boolean"then return v end
end
local function choice(v,default,allowed)
  if v==nil then return default end
  if type(v)=="string"and allowed[v]then return v end
end
local function theme(v)
  if v==nil then return "ellesmere"end
  if type(Themes.migrate)=="function"then return Themes.migrate(v)end
  if Themes.accepts(v)and v=="ellesmere"then return v end
end
local function number(v,default,lo,hi,integer)
  if v==nil then return default end
  if finite(v)and v>=lo and v<=hi and(not integer or v%1==0)then return v end
end
local function iconPoint(raw,empty)
  if raw==nil and empty then return {}end
  if not keys(raw,{x=true,y=true})then return nil end
  if raw.x==nil and raw.y==nil and empty then return {}end
  local x=number(raw.x,nil,-1000,2000,true);local y=number(raw.y,nil,-1000,2000,true)
  if x~=nil and y~=nil then return {x=x,y=y}end
end
local function iconPositions(raw)
  if raw==nil then return {}end
  if type(raw)~="table"then return nil end
  local out={};local count=0
  for id,value in pairs(raw)do
    count=count+1;if count>64 or type(id)~="string"or Watchlist.id(id)~=id then return nil end
    local point=iconPoint(value,false);if not point then return nil end;out[id]=point
  end
  return out
end
local function textPoint(raw)
  if raw==nil then return {}end
  if not keys(raw,{x=true,y=true})then return nil end
  if raw.x==nil and raw.y==nil then return {}end
  local x=number(raw.x,nil,0,1000,true);local y=number(raw.y,nil,0,1000,true)
  if x~=nil and y~=nil then return {x=x,y=y}end
end
local function textPositions(raw)
  if raw==nil then raw={}end
  if not keys(raw,{name=true,health=true,distance=true})then return nil end
  local name=textPoint(raw.name);local health=textPoint(raw.health);local distance=textPoint(raw.distance)
  if name and health and distance then return {name=name,health=health,distance=distance}end
end
-- Global explanations are separate from profile snapshots. Loading a look or
-- layout must not re-enable a previously dismissed explanation.
function P.helpDefaults()return {raid_management=true}end
function P.validateHelp(raw)
  if raw==nil then return P.helpDefaults()end
  if not keys(raw,{raid_management=true})then return nil end
  local enabled=bool(raw.raid_management,true)
  if enabled==nil then return nil end
  return {raid_management=enabled}
end
function P.visibilityDefaults()return {frames=true}end
function P.validateVisibility(raw)
  if raw==nil then return P.visibilityDefaults()end
  if not keys(raw,{frames=true})or type(raw.frames)~="boolean"then return nil end
  return {frames=raw.frames}
end
function P.defaults()
  return {appearance={mode="native",theme="ellesmere",opacity=1,role_icon=false,show_distance=false},
    indicators={target=true,hover=true,low_health=true,health_style="outline",health_threshold=25,low_mana=true,mana_threshold=20,hatch_mode="stripes",hatch_opacity=1},
    range={enabled=false,distance=30,alpha=0.5},input={click_target=true,click_modifier="none",return_target=false},
    auras=Watchlist.validate(nil),aura_icons={size=0,spacing=1,max_visible=3,position="bottom_right",timer_size=9,grouped=true,anchor={},positions={}},
    text_positions={name={},health={},distance={}},colours=Colours.defaults(),member_layout=MemberLayout.defaults(),alerts=MemberLayout.position()}
end
function P.validate(raw)
  if raw==nil then return P.defaults()end
  if not keys(raw,{appearance=true,indicators=true,range=true,input=true,auras=true,aura_icons=true,text_positions=true,colours=true,member_layout=true,alerts=true})then return nil end
  local function section(v)if v==nil then return {}end;return v end
  local a=section(raw.appearance);local i=section(raw.indicators);local r=section(raw.range)
  local c=section(raw.input);local u=section(raw.auras);local icons=section(raw.aura_icons)
  if not keys(a,{mode=true,theme=true,opacity=true,role_icon=true,show_distance=true})or not keys(i,{target=true,hover=true,low_health=true,health_style=true,health_threshold=true,low_mana=true,mana_threshold=true,hatch_mode=true,hatch_opacity=true})
    or not keys(r,{enabled=true,distance=true,alpha=true})or not keys(c,{click_target=true,click_modifier=true,return_target=true})then return nil end
  if not keys(icons,{size=true,spacing=true,max_visible=true,position=true,timer_size=true,grouped=true,anchor=true,positions=true})then return nil end
  local iconSize=icons.size==nil and 0 or icons.size
  if iconSize~=0 and not number(iconSize,nil,16,32,true)then return nil end
  local iconPrefs={size=iconSize,spacing=number(icons.spacing,1,0,12,true),max_visible=number(icons.max_visible,3,1,6,true),
    position=choice(icons.position,"bottom_right",{top_right=true,top_left=true,bottom_right=true,bottom_left=true}),timer_size=number(icons.timer_size,9,8,16,true),
    grouped=bool(icons.grouped,true),anchor=iconPoint(icons.anchor,true),positions=iconPositions(icons.positions)}
  for _,k in ipairs({"size","spacing","max_visible","position","timer_size","grouped","anchor","positions"})do if iconPrefs[k]==nil then return nil end end
  local auras=Watchlist.validate(u);local colours=Colours.validate(raw.colours)
  local members=MemberLayout.validate(raw.member_layout);local alerts=MemberLayout.position(raw.alerts);local text=textPositions(raw.text_positions)
  if not auras or not colours or not members or not alerts or not text then return nil end
  local out={appearance={mode=choice(a.mode,"native",{native=true,custom=true}),
    theme=theme(a.theme),opacity=number(a.opacity,1,0.15,1,false),role_icon=bool(a.role_icon,false),show_distance=bool(a.show_distance,false)},
    indicators={target=bool(i.target,true),hover=bool(i.hover,true),low_health=bool(i.low_health,true),health_style=choice(i.health_style,"outline",{outline=true,badge=true,hatch=true}),
      health_threshold=number(i.health_threshold,25,1,100,true),low_mana=bool(i.low_mana,true),mana_threshold=number(i.mana_threshold,20,1,100,true),
      hatch_mode=choice(i.hatch_mode,"stripes",{stripes=true,solid=true,both=true}),hatch_opacity=number(i.hatch_opacity,1,0.1,1,false)},
    range={enabled=bool(r.enabled,false),distance=number(r.distance,30,5,150,true),alpha=number(r.alpha,0.5,0.15,1,false)},
    input={click_target=bool(c.click_target,true),click_modifier=choice(c.click_modifier,"none",{none=true,shift=true,ctrl=true,alt=true}),return_target=bool(c.return_target,false)},
    auras=auras,aura_icons=iconPrefs,text_positions=text,colours=colours,member_layout=members,alerts=alerts}
  -- Missing fields receive defaults; supplied malformed values never silently
  -- become false/defaults. Preserve false distinctly from a failed parse.
  for _,section in ipairs({"appearance","indicators","range","input","auras","aura_icons","text_positions","colours","member_layout","alerts"})do
    for key in pairs(P.defaults()[section])do if out[section][key]==nil then return nil end end
  end
  return out
end
function P.copy(value)
  local budget=P.MAX_COPY_NODES
  local function copy(v,depth)
    budget=budget-1;if budget<0 or depth>10 then return nil,false end
    if type(v)~="table"then
      if v==nil or type(v)=="boolean"or type(v)=="string"or finite(v)then return v,true end
      return nil,false
    end
    local out={};local count=0
    for k,item in pairs(v)do
      count=count+1;if count>P.MAX_TABLE_FIELDS or type(k)~="string"then return nil,false end
      local result,ok=copy(item,depth+1);if not ok then return nil,false end
      out[k]=result
    end
    return out,true
  end
  local result,ok=copy(value,0);if ok then return result end
end
-- A profile contains only authored appearance/layout choices. Keep this shared
-- validator separate from either host's storage and lifecycle implementation.
function P.snapshot(raw,normalise)
  if type(raw)~="table"or not keys(raw.view,{layout=true,preview_count=true,position=true,compact=true,locked=true,native_style=true,x=true,y=true})then return nil end
  local settings,warnings=F.settings(raw.settings)
  if not settings or #warnings>0 then return nil end
  local v=raw.view
  if(v.layout~="party"and v.layout~="raid")or(v.preview_count~=5 and v.preview_count~=25 and v.preview_count~=50)
    or(v.position~="left"and v.position~="centre"and v.position~="right"and v.position~="custom")
    or(v.compact~=nil and type(v.compact)~="boolean")or(v.locked~=nil and type(v.locked)~="boolean")
    or(v.native_style~=nil and v.native_style~=true)then return nil end
  local view={layout=v.layout,preview_count=v.preview_count,position=v.position}
  if v.compact~=nil then view.compact=v.compact end
  if v.locked~=nil then view.locked=v.locked end
  if v.native_style~=nil then view.native_style=v.native_style end
  if v.position=="custom"then
    local function coordinate(n)return finite(n)and n>=0 and n<=32768 and n%1==0 end
    if not coordinate(v.x)or not coordinate(v.y)then return nil end
    view.x=v.x;view.y=v.y
  elseif v.x~=nil or v.y~=nil then return nil end
  local result={settings=settings,view=view}
  if raw.options~=nil or normalise then result.options=P.validate(raw.options);if not result.options then return nil end end
  if normalise then view.compact=v.compact==true;view.locked=v.locked~=false end
  return result
end
function P.profileName(value)
  if type(value)~="string"then return nil end
  local name=value:match("^%s*(.-)%s*$")
  if #name<1 or #name>24 or name:find("[%c|]")then return nil end
  return name
end
return P
