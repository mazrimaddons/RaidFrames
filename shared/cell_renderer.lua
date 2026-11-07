-- Owned Original/Ellesmere surfaces. No native-world widgets or data reads.
local Ordering=require("Mazrim_Raid_Frames/shared/ordering")
local P=require("Mazrim_Raid_Frames/shared/presentation")
local Themes=require("Mazrim_Raid_Frames/shared/themes")
local Indicators=require("Mazrim_Raid_Frames/shared/indicators")
local Identity=require("Mazrim_Raid_Frames/shared/identity")
local Colours=require("Mazrim_Raid_Frames/shared/colours")
local Watch=require("Mazrim_Raid_Frames/shared/watchlist")
local Materials=require("Mazrim_Raid_Frames/shared/materials")
local R={offlineStatusContract=1,manaDisplayContract=1,noManaHoverContract=1,
 healthEmphasisContract=1,pointerTargetContract=1,nativeRaidContract=1,dragRecoveryContract=1,
 customThemesContract=1,healingIndicatorsContract=1,fontControlsContract=1,auraIconContract=1,effectTintContract=1,
 adaptiveEffectsContract=1,expandedStylesContract=Themes.expandedStylesContract==1 and 1 or 0,
 surfaceIsolationContract=1,tintCandidatesContract=1,roleIconToggleContract=1,visualOverhaulContract=Colours.overhaulContract==1 and Themes.twoLooksContract==1 and 1 or 0}
local defaults=Colours.defaults()
local customNames={"baseMid","trackMid","fillMid","manaTrack","manaFill","edgeTop","edgeBottom","edgeLeft","edgeRight","detail7"}
local function draw(parent,ui)
 local o=ui.drawable(parent,1,1,1,1);ui.call(o,"EnablePick",false);ui.call(o,"Clickable",false);ui.show(o,false);return o
end
local function four(parent,ui)return {draw(parent,ui),draw(parent,ui),draw(parent,ui),draw(parent,ui)}end
local function piece(o,parent,x,y,w,h,ink,ui)
 if w<=0 or h<=0 then ui.show(o,false);return end
 ui.place(o,parent,x,y,w,h);ui.colour(o,ink[1],ink[2],ink[3],ink[4]or 1);ui.show(o,true)
end
local function outline(parts,parent,x,y,w,h,size,ink,shown,ui)
 if not shown or w<=size*2 or h<=size*2 then for i=1,4 do ui.show(parts[i],false)end;return end
 piece(parts[1],parent,x,y,w,size,ink,ui);piece(parts[2],parent,x,y+h-size,w,size,ink,ui)
 piece(parts[3],parent,x,y+size,size,h-size*2,ink,ui);piece(parts[4],parent,x+w-size,y+size,size,h-size*2,ink,ui)
end
local function finite(v)return type(v)=="number"and v==v and v>-1/0 and v<1/0 end
local function colour(palette,key)return Colours.rgb(palette[key])or Colours.rgb(defaults[key])end
local function shade(v,f,a)return {math.min(1,v[1]*f),math.min(1,v[2]*f),math.min(1,v[3]*f),a or v[4]or 1}end
function R.create(i,ui)
 local c={nativeID=i,custom={},auraChips={},iconRects={},textRects={},timerBudgets={}}
 c.root=ui.widget("button","cell"..i,ui.parent);if not c.root then return nil end
 ui.call(c.root,"EnablePick",true);ui.call(c.root,"Clickable",true)
 c.nativeHost=ui.widget("window","native"..i,c.root);if not c.nativeHost then return nil end
 ui.call(c.nativeHost,"EnablePick",false);ui.call(c.nativeHost,"Clickable",false);ui.show(c.nativeHost,false)
 for _,name in ipairs(customNames)do c.custom[name]=draw(c.root,ui);if not c.custom[name]then return nil end end
 c.effectTintHost=ui.widget("window","effect_tint"..i,c.root);if not c.effectTintHost then return nil end
 ui.call(c.effectTintHost,"EnablePick",false);ui.call(c.effectTintHost,"Clickable",false)
 c.baseOverride=draw(c.effectTintHost,ui);c.manaOverride=draw(c.effectTintHost,ui);c.effectTint=draw(c.effectTintHost,ui)
 if not c.baseOverride or not c.manaOverride or not c.effectTint then return nil end
 ui.show(c.effectTintHost,false)
 c.name=ui.label("name"..i,c.root,ui.small_font);c.health=ui.label("health"..i,c.root,ui.small_font)
 c.leader=ui.leader("leader"..i,c.root);if not c.name or not c.health or not c.leader then return nil end
 ui.checked(c.name.style,"SetEllipsis",true)
 ui.checked(c.health.style,"SetEllipsis",false)
 c.decor=ui.widget("window","indicators"..i,c.root);if not c.decor then return nil end
 ui.call(c.decor,"EnablePick",false);ui.call(c.decor,"Clickable",false)
 c.targetOutline=four(c.decor,ui);c.hoverOutline=four(c.decor,ui)
 c.healthOutline=four(c.decor,ui);c.manaWarning=draw(c.decor,ui)
 for j=1,3 do
  local chip={background=draw(c.decor,ui),label=ui.label("aura"..i.."_"..j,c.decor,9)}
  if not chip.background or not chip.label then return nil end
  ui.call(chip.label.style,"SetShadow",true);ui.show(chip.label,false);c.auraChips[j]=chip
 end
 ui.show(c.decor,true);c.input=c.root;return c
end
function R.ensureNative(c,ui)
 if not c.background then c.background=ui.raid_background(c.nativeHost);if not c.background then return false end end
 if not c.hp then c.hp=ui.raid_bar("hp"..c.nativeID,c.nativeHost);if not c.hp then return false end end
 if not c.mp then c.mp=ui.raid_bar("mp"..c.nativeID,c.nativeHost);if not c.mp then return false end end
 if not c.nativeReady then
  for _,bar in ipairs({c.hp,c.mp})do
   ui.call(bar,"EnablePick",false);ui.call(bar,"Clickable",false)
   ui.call(bar.statusBar,"EnablePick",false);ui.call(bar.statusBar,"Clickable",false)
  end
  c.nativeReady=true
 end
 return true
end
local function hideNative(c,ui)
 ui.show(c.nativeHost,false);if c.background then ui.show(c.background,false)end
 if c.hp then ui.show(c.hp,false)end;if c.mp then ui.show(c.mp,false)end
end
local function nativeStyle(row,offline)
 if offline then return "HP_RAID_OFFLINE"end
 local role=row.roleKnown==true and row.role
 local key=role=="tank"and"HP_RAID_TANKER"or role=="healer"and"HP_RAID_HEALER"or role=="damage"and"HP_RAID_DEALER"or"HP_RAID"
 if row.roleStyleEstimated==true and(row.roleStyle=="HP_RAID"or row.roleStyle=="HP_RAID_TANKER"or row.roleStyle=="HP_RAID_HEALER"or row.roleStyle=="HP_RAID_DEALER")then key=row.roleStyle end
 return key
end
local function family(key)return key=="HP_RAID_TANKER"and"tank"or key=="HP_RAID_HEALER"and"healer"or key=="HP_RAID_DEALER"and"damage"or nil end
local function baseColour(row,key,palette,rules)
 local classes=type(palette.classes)=="table"and palette.classes or{}
 local name=row.classKnown==true and Colours.className(row.className)
 if name and Colours.rgb(classes[name])then return Colours.rgb(classes[name]),classes[name],true end
 local category=name and(type(rules)=="table"and type(rules.classes)=="table"and Ordering.category(row,rules)or Ordering.defaultCategory(name))
 local dps=category and Colours.dpsColour(palette,category)
 if dps then return Colours.rgb(dps),dps,true end
 local k=category=="tank"and"tank"or category=="healer"and"healer"or(category=="mage"or category=="ranged"or category=="melee")and"damage"or family(key)or"neutral"
 local classified=type(category)=="string"and category~="flex"and k~=(family(key)or"neutral")
 return colour(palette,k),palette[k]or defaults[k],classified,k
end
local function resource(bar,value,offline,ui)
 local known=not offline and Indicators.fraction(value)~=nil
 ui.checked(bar.statusBar,"SetMinMaxValues",0,known and value.maximum or 1);ui.checked(bar.statusBar,"SetValue",known and value.current or 0)
end
local function healthText(row,mode,offline)
 if offline then return "Offline"end
 local f=Indicators.fraction(row.health);if f==nil then return "?"end
 return P.health({known=true,current=row.health.current,maximum=row.health.maximum,percent=f*100,missing=row.health.maximum-row.health.current},mode)
end
local function textLayout(row,w,h,display,offline,layout,ui)
 local font=display.font_size
 if not finite(font)or font<10 or font>24 then font=ui.small_font end
 font=math.min(font,math.max(10,h-layout.mana-4))
 local crown=not layout.dead and row.authorityKnown==true and(row.authority=="leader"or row.authority=="subleader")
 local nx=crown and 16 or(layout.custom and 6 or 4);local ny=2;local nh=font+2
 local reserve=layout.badge and 13 or 0
 local sx,sy,sw=4,h-layout.mana-nh,w-8-reserve;local nw=w-nx-2-reserve;local status=layout.dead and""or healthText(row,display.health_text,offline)
 if h-layout.mana<font*2+4 and status~=""then
  sw=math.min(w*0.45,math.max(16,#status*font*0.55));sx=w-sw-3-reserve;sy=ny;nw=math.max(1,sx-nx-3)
 end
 return {font=font,crown=crown,nx=nx,ny=ny,nw=nw,nh=nh,sx=sx,sy=sy,sw=sw,status=status}
end
local function scopeAccepted(row,scope,state)
 return type(scope)=="table"and scope.contract==1 and not(row.offlineKnown==true and row.offline==true)
  and((Identity.accepts(row.identity)and scope.identity==row.identity and(scope.token==nil or scope.token==row.token))or(state.preview==true and scope.preview==true))
end
local function remainingText(a)
 if not finite(a.remaining)or a.remaining<0 or a.remaining>604800 then return ""end
 local v=a.remaining;local text
 if v>=86400 then text=string.format("%dd",math.floor(v/86400))elseif v>=3600 then text=string.format("%dh",math.floor(v/3600))
 elseif v>=60 then text=string.format("%dm",math.floor(v/60))else text=string.format("%.0f",math.floor(v))end
 return (a.estimated==true and"~"or"")..text
end
local function widthOf(value,font)
 local n=0;for i=1,#value do local x=value:sub(i,i);n=n+(x=="~"and 0.8 or x:match("%d")and 0.6 or 0.65)end
 return n*font
end
local function cornerIconPlan(row,w,h,display,layout,scope,state,prefs,icons)
 local plan={};local t=layout.text;if not scopeAccepted(row,scope,state)or type(scope.items)~="table"then return plan end
 icons=type(icons)=="table"and icons or{}
 local size=finite(icons.size)and(icons.size==0 or(icons.size>=16 and icons.size<=32 and icons.size%1==0))and icons.size or 0;local maximum=math.min(size==0 and 30 or 32,h-layout.mana-4)
 if maximum<(size==0 and 20 or 16)then return plan end
 local position=icons.position or"bottom_right";local fromLeft=position=="top_left"or position=="bottom_left"
 local fromTop=position=="top_left"or position=="top_right"
 local function bounded(v,fallback,lo,hi)return finite(v)and v%1==0 and v>=lo and v<=hi and v or fallback end
 local spacing=bounded(icons.spacing,1,0,12);local limit=bounded(icons.max_visible,3,1,6);local timerSize=bounded(icons.timer_size,9,8,16)
 local reserve=layout.badge and 13 or 0
 local cursor=fromLeft and 3 or w-3-reserve
 for i=1,math.min(#scope.items,12)do
  local a=scope.items[i]
  local fresh=type(a)=="table"and a.observed==true and a.estimated~=true
  local history=type(a)=="table"and a.estimated==true and a.observed~=true and finite(a.remaining)and a.remaining>0 and a.remaining<=604800
  if (fresh or history)and((a.kind=="debuff"and prefs.debuffs~=false)or((a.kind=="hot"or a.kind=="buff")and prefs.hots~=false))then
   local timer=remainingText(a)
   -- Reserve the estimated prefix even while fresh, so observation/history
   -- transitions never resize a chip or push it off a compact frame.
   local metrics=timer==""and""or(timer:sub(1,1)=="~"and timer or"~"..timer)
   local iconSize=math.min(maximum,size==0 and(w>=104 and 24 or 20)or size)
   local font=math.min(timerSize,math.floor((iconSize-2)/math.max(1,widthOf(metrics,1))))
   local y=fromTop and 2 or h-layout.mana-iconSize-2;local left=3
   if display.show_names and t.ny<y+iconSize and t.ny+t.nh>y then left=math.max(left,t.nx+12)end
   if t.crown and y<15 then left=math.max(left,16)end
   if t.status~=""and t.sy<y+iconSize and t.sy+t.nh>y then left=math.max(left,t.sx+math.min(t.sw,math.ceil(#t.status*t.font*0.7)+4)+2)end
   local x
   if fromLeft then
    if t.crown and y<15 then cursor=math.max(cursor,16)end
    x=cursor
    local required=display.show_names and t.ny<y+iconSize and t.ny+t.nh>y and 15 or 0
    if t.status~=""and t.sy<y+iconSize and t.sy+t.nh>y then required=math.max(required,math.min(t.sw,math.ceil(#t.status*t.font*.7)+4))end
    if x+iconSize+required+3>w-reserve-3 then break end
    cursor=x+iconSize+spacing
   else
    x=cursor-iconSize-1
    if x<left then break end
    cursor=x-spacing+1
   end
   if widthOf(timer,font)>iconSize-2 then break end
   plan[#plan+1]={a=a,x=x,y=y,size=iconSize,timer=timer,font=font,maxFont=timerSize}
   if #plan==limit then break end
  end
 end
 if #plan>0 then
  local edge=fromLeft and(plan[#plan].x+plan[#plan].size)or plan[#plan].x
  for _,p in ipairs(plan)do
   if t.ny<p.y+p.size and t.ny+t.nh>p.y then
    if fromLeft then local right=t.nx+t.nw;t.nx=math.max(t.nx,edge+3);t.nw=math.max(1,right-t.nx)
    else t.nw=math.min(t.nw,math.max(1,edge-t.nx-3))end
   end
   if t.sy<p.y+p.size and t.sy+t.nh>p.y then
    if fromLeft then local right=t.sx+t.sw;t.sx=math.max(t.sx,edge+3);t.sw=math.max(1,right-t.sx)
    else t.sw=math.min(t.sw,math.max(1,edge-t.sx-3))end
   end
  end
 end
 return plan
end
-- Coordinates describe centres, in thousandths of the chosen frame size.
-- Empty maps retain the compact corner layout used by earlier profiles.
local function iconPoint(value)
 return type(value)=="table"and finite(value.x)and finite(value.y)and value.x%1==0 and value.y%1==0
  and value.x>=-1000 and value.x<=2000 and value.y>=-1000 and value.y<=2000
end
local function reserveIconText(t,plan,showNames)
 local function band(x,y,width,height)
  local intervals={{x,x+width}}
  for _,p in ipairs(plan)do if y<p.y+p.size and y+height>p.y then
   local nextIntervals={};local left,right=p.x-3,p.x+p.size+3
   for _,span in ipairs(intervals)do
    if right<=span[1]or left>=span[2]then nextIntervals[#nextIntervals+1]=span
    else
     if left>span[1]then nextIntervals[#nextIntervals+1]={span[1],math.min(left,span[2])}end
     if right<span[2]then nextIntervals[#nextIntervals+1]={math.max(right,span[1]),span[2]}end
    end
   end
   intervals=nextIntervals
  end end
  local bx,bw=x,1
  for _,span in ipairs(intervals)do if span[2]-span[1]>bw then bx=span[1];bw=span[2]-span[1]end end
  return bx,bw
 end
 if showNames then t.nx,t.nw=band(t.nx,t.ny,t.nw,t.nh)end
 if t.status~=""then t.sx,t.sw=band(t.sx,t.sy,t.sw,t.nh)end
end
local function iconPlan(row,w,h,display,layout,scope,state,prefs,icons)
 icons=type(icons)=="table"and icons or{}
 local grouped=icons.grouped~=false;local positions=type(icons.positions)=="table"and icons.positions or{}
 local custom=grouped and iconPoint(icons.anchor)or false
 if not custom and not grouped and scopeAccepted(row,scope,state)and type(scope.items)=="table"then
  for i=1,math.min(#scope.items,12)do local a=scope.items[i];local id=type(a)=="table"and Watch.id(a.id)
   if id and iconPoint(positions[id])then custom=true;break end
  end
 end
 if not custom then return cornerIconPlan(row,w,h,display,layout,scope,state,prefs,icons)end
 local plan={};if not scopeAccepted(row,scope,state)or type(scope.items)~="table"then return plan end
 local function bounded(v,fallback,lo,hi)return finite(v)and v%1==0 and v>=lo and v<=hi and v or fallback end
 local size=icons.size==0 and 0 or bounded(icons.size,0,16,32)
 local iconSize=size==0 and(w>=104 and 24 or 20)or size
 local spacing=bounded(icons.spacing,1,0,12);local limit=bounded(icons.max_visible,3,1,6);local timerSize=bounded(icons.timer_size,9,8,16)
 for i=1,math.min(#scope.items,12)do
  local a=scope.items[i]
  local fresh=type(a)=="table"and a.observed==true and a.estimated~=true
  local history=type(a)=="table"and a.estimated==true and a.observed~=true and finite(a.remaining)and a.remaining>0 and a.remaining<=604800
  if(fresh or history)and((a.kind=="debuff"and prefs.debuffs~=false)or((a.kind=="hot"or a.kind=="buff")and prefs.hots~=false))then
   local timer=remainingText(a);local metrics=timer==""and""or(timer:sub(1,1)=="~"and timer or"~"..timer)
   local font=math.min(timerSize,math.floor((iconSize-2)/math.max(1,widthOf(metrics,1))))
   if widthOf(timer,font)<=iconSize-2 then plan[#plan+1]={a=a,size=iconSize,timer=timer,font=font,maxFont=timerSize}end
   if #plan==limit then break end
  end
 end
 local fromLeft=icons.position=="top_left"or icons.position=="bottom_left"
 local fromTop=icons.position=="top_left"or icons.position=="top_right"
 local total=#plan*iconSize+math.max(0,#plan-1)*spacing
 for i,p in ipairs(plan)do
  local id=Watch.id(p.a.id);local point=not grouped and id and positions[id]
  if grouped then
   local left=icons.anchor.x*w/1000-total/2
   p.x=left+(fromLeft and i-1 or #plan-i)*(iconSize+spacing);p.y=icons.anchor.y*h/1000-iconSize/2
  elseif iconPoint(point)then p.x=point.x*w/1000-iconSize/2;p.y=point.y*h/1000-iconSize/2
  else
   p.x=fromLeft and 3+(i-1)*(iconSize+spacing)or w-4-(layout.badge and 13 or 0)-i*iconSize-(i-1)*spacing
   p.y=fromTop and 2 or h-layout.mana-iconSize-2
  end
 end
 reserveIconText(layout.text,plan,display.show_names)
 return plan
end
local function iconPath(a)
 local path=a.icon
 return type(path)=="string"and #path>0 and #path<=512 and not path:find("[%c|]")and not path:find("..",1,true)and not path:find(":",1,true)and path or nil
end
-- Reserve every format this particular countdown can reach. Short effects
-- keep their larger text; unit changes and the history prefix never refit it.
local function timerWidth(duration)
 local seconds=math.min(59,math.floor(duration));local width=widthOf(seconds>=10 and"~99"or"~9",1)
 if duration>=60 then width=math.max(width,widthOf(math.min(59,math.floor(duration/60))>=10 and"~99m"or"~9m",1))end
 if duration>=3600 then width=math.max(width,widthOf(math.min(23,math.floor(duration/3600))>=10 and"~99h"or"~9h",1))end
 if duration>=86400 then width=math.max(width,widthOf("~9d",1))end
 return width
end
local function stableTimerFont(c,p,generation)
 local id=Watch.id(p.a.id);if not id then return p.font end
 local entry=c.timerBudgets[id];local duration=p.a.remaining
 local timed=finite(duration)and duration>=0 and duration<=604800
 if entry and(entry.size~=p.size or entry.maximum~=p.maxFont)then c.timerBudgets[id]=nil;entry=nil end
 if not entry and timed then
  entry={size=p.size,maximum=p.maxFont,duration=duration,font=math.min(p.maxFont,math.floor((p.size-2)/timerWidth(duration)))}
  c.timerBudgets[id]=entry
 elseif entry and timed and duration>entry.duration and p.a.observed==true and p.a.estimated~=true then
  -- An actual fresh extension can require more room. A shrinking countdown
  -- never increases its font again while this effect remains on the frame.
  entry.duration=duration;entry.font=math.min(entry.font,math.floor((p.size-2)/timerWidth(duration)))
 end
 if entry then entry.seen=generation;return entry.font end
 return p.font
end
local function paintIcons(c,plan,ui,identity)
 local historical={};c.effectIconFallback=false;c.iconRects={}
 if c.timerBudgetIdentity~=identity then c.timerBudgets={};c.timerBudgetIdentity=identity end
 c.timerBudgetGeneration=(c.timerBudgetGeneration or 0)+1;local generation=c.timerBudgetGeneration
 for i=#c.auraChips+1,#plan do
  local chip={background=draw(c.decor,ui),label=ui.label("aura"..c.nativeID.."_"..i,c.decor,9)}
  if not chip.background or not chip.label then return historical end
  ui.call(chip.label.style,"SetShadow",true);c.auraChips[i]=chip
 end
 for i=1,#c.auraChips do
  local chip=c.auraChips[i];local p=plan[i]
  local beforeID=chip.item and Watch.id(chip.item.id);local beforePath=chip.iconPath
  if p then
   p.font=stableTimerFont(c,p,generation)
   -- Right alignment keeps the numeric suffix still when the explicit
   -- estimated prefix appears. Hosts without the reviewed enum skip it.
   if ui.timer_align~=nil and chip.timerAlignAttempt~=ui.timer_align then
    chip.timerAlignAttempt=ui.timer_align
    local ok,result=ui.call(chip.label.style,"SetAlign",ui.timer_align)
    if ok and result~=false then chip.timerAlign=ui.timer_align end
   end
   local path=iconPath(p.a);local shown=false
   if path and chip.iconPath==path and chip.icon then shown=true
   elseif path and chip.iconAttempt~=path then
    chip.iconAttempt=path
    if chip.icon and type(ui.effectTexture)=="function"then
     local ok,v=pcall(ui.effectTexture,chip.icon,path);if ok and v==true then chip.iconPath=path;shown=true else chip.iconPath=nil end
    elseif not chip.icon and type(ui.effectImage)=="function"then
     local ok,o=pcall(ui.effectImage,c.decor,path);if ok and o then chip.icon=o;chip.iconPath=path;shown=true end
    end
   end
   if chip.icon then
    if shown then ui.place(chip.icon,c.decor,p.x,p.y,p.size,p.size);ui.colour(chip.icon,1,1,1,1)end
    ui.show(chip.icon,shown)
   end
   if shown then ui.show(chip.background,false)else
    piece(chip.background,c.decor,p.x,p.y,p.size,p.size,{0.23,0.25,0.28,1},ui);c.effectIconFallback=true
   end
   if p.timer~=""then
    ui.checked(chip.label.style,"SetFontSize",p.font);ui.place(chip.label,c.decor,p.x+1,p.y+p.size-p.font-2,p.size-2,p.font+2)
    ui.text(chip.label,p.timer);ui.colour(chip.label.style,1,1,1,1);ui.show(chip.label,true)
    if p.a.estimated==true then local id=Watch.id(p.a.id);if id then historical[id]=true end end
   else ui.text(chip.label,"");ui.show(chip.label,false)end
   chip.item=p.a
   c.iconRects[#c.iconRects+1]={id=Watch.id(p.a.id),kind=p.a.kind,x=p.x,y=p.y,w=p.size,h=p.size}
  else
   ui.show(chip.background,false);ui.show(chip.label,false);if chip.icon then ui.show(chip.icon,false)end;chip.item=nil
  end
  local afterID=chip.item and Watch.id(chip.item.id)
  if beforeID~=afterID or beforePath~=chip.iconPath then c.iconRenderGeneration=(c.iconRenderGeneration or 0)+1 end
 end
 for id,entry in pairs(c.timerBudgets)do if entry.seen~=generation then c.timerBudgets[id]=nil end end
 return historical
end
local function rolePaint(c,w,h,display,layout,ui,options)
 local t=layout.text;local role=not layout.dead and layout.custom and options.appearance.role_icon==true and layout.family;local rect
 if role and t.nw>=31 and t.ny+10<=h-layout.mana-2 then
  rect={x=t.nx,y=t.ny+2};t.nx=t.nx+11;t.nw=t.nw-11
 end
 if rect then
  piece(c.custom.detail7,c.root,rect.x-1,rect.y-1,10,10,{0.01,0.02,0.03,0.95},ui)
  if not c.roleParts then c.roleParts={};for i=1,5 do c.roleParts[i]=draw(c.decor,ui)end end
  local used={};local function part(i,x,y,pw,ph)used[i]=true;piece(c.roleParts[i],c.decor,rect.x+x,rect.y+y,pw,ph,layout.base,ui)end
  if role=="tank"then part(1,0,0,8,2);part(2,1,2,6,3);part(3,2,5,4,2);part(4,3,7,2,1)
  elseif role=="healer"then part(1,3,0,2,8);part(2,0,3,8,2)
  else part(1,6,0,2,2);part(2,4,2,2,2);part(3,2,4,2,2);part(4,0,5,5,1);part(5,0,6,2,2)end
  for i=1,5 do if not used[i]then ui.show(c.roleParts[i],false)end end
 else
  if layout.custom then ui.show(c.custom.detail7,false)end
  if c.roleParts then for i=1,5 do ui.show(c.roleParts[i],false)end end
 end
end
local function materialPaint(c,row,w,h,layout,scope,state,historical,ui)
 local function eligible(t)
  local valid=type(t)=="table"and Watch.id(t.id)~=nil and type(t.colour)=="table"and layout.hp~=nil and layout.hp>0
  if valid then
   local count=0;for key,value in pairs(t.colour)do count=count+1;if(key~=1 and key~=2 and key~=3)or not finite(value)or value<0 or value>1 then valid=false end end
   if count~=3 then valid=false end
   if t.remaining~=nil and(not finite(t.remaining)or t.remaining<=0 or t.remaining>604800)then valid=false end
   if t.estimated==true then valid=valid and t.observed~=true and finite(t.remaining)and t.remaining>0
   else valid=valid and t.observed==true end
   if t.material~=nil and not Materials.accepts(t.material)then valid=false end
  end
  return valid==true
 end
 local t
 if scopeAccepted(row,scope,state)then
  local list=scope.tintCandidates
  if list~=nil then
   local valid=type(list)=="table"and #list<=64;local count=0
   if valid then for k in pairs(list)do
    count=count+1;if type(k)~="number"or k%1~=0 or k<1 or k>#list then valid=false;break end
   end end
   if valid and count==#list then for i=1,#list do if eligible(list[i])then t=list[i];break end end end
  elseif eligible(scope.tint)then t=scope.tint end
 end
 local valid=t~=nil
 local f=layout.fill
 if valid then
  local material=Materials.get(t.material or"tint");local textured=material and material.tile~=nil
  local ink={t.colour[1],t.colour[2],t.colour[3],textured and 0.94 or 0.40}
  local fw=f.w*layout.hp
  piece(c.effectTint,c.effectTintHost,f.x,f.y,fw,f.h,ink,ui)
  local artShown=false
  if textured then
   if not c.materialArtTried then
    c.materialArtTried=true
    if type(ui.materialArt)=="function"then local ok,o=pcall(ui.materialArt,c.effectTintHost);if ok and o then c.materialImage=o end end
   end
   if c.materialImage and not c.materialCoordsFailed then
    local tile=material.tile;local crop=math.max(1,math.ceil(tile.w*layout.hp));local key=material.id..":"..crop
    if c.materialCoords~=key then
     local ok,result=ui.call(c.materialImage,"SetCoords",tile.x,tile.y,crop,tile.h)
     if ok and result~=false then c.materialCoords=key else c.materialCoords=nil;c.materialCoordsFailed=true end
    end
    if c.materialCoords==key then piece(c.materialImage,c.effectTintHost,f.x,f.y,fw,f.h,ink,ui);artShown=true end
   end
  end
  if c.materialImage and not artShown then ui.show(c.materialImage,false)end
  c.materialArtFallback=textured and not artShown or false
 else
  ui.show(c.effectTint,false);if c.materialImage then ui.show(c.materialImage,false)end;c.materialArtFallback=false
 end
 -- The reviewed label shadow keeps user-selected text readable on pale art.
 -- Cache transitions; do not recolour names or issue a setter every repaint.
 if c.materialTextShadow~=valid then
  ui.call(c.name.style,"SetShadow",valid);ui.call(c.health.style,"SetShadow",valid);c.materialTextShadow=valid
 end
 c.materialEstimated=valid and t.estimated==true or false;c.materialVisible=valid or false
 c.materialID=valid and Watch.id(t.id)or nil;c.materialStyle=valid and t.material or nil
 return valid
end
-- Static warning art; one cached drawable per chosen style, no timers.
local function healthWarning(c,w,h,layout,model,style,palette,prefs,ui)
 local ink=Colours.rgb(Colours.healthColour(palette,style))
 local active=model.lowHealth==true
 outline(c.healthOutline,c.decor,2,2,w-4,h-4,1,ink,active and style=="outline",ui)
 if c.healthBadge and(not active or style~="badge")then ui.show(c.healthBadge,false)end
 if c.healthBadgeText and(not active or style~="badge")then ui.show(c.healthBadgeText,false)end
 if c.healthHatch and(not active or style~="hatch")then ui.show(c.healthHatch,false)end
 if c.healthSolid and(not active or style~="hatch")then ui.show(c.healthSolid,false)end
 if not active or style=="outline"then return false end
 if style=="badge"then
  if not c.healthBadgeTried and ui.healthArt then c.healthBadgeTried=true;c.healthBadge=ui.healthArt(c.decor)end
  if not c.healthBadge then outline(c.healthOutline,c.decor,2,2,w-4,h-4,1,ink,true,ui);return false end
  if not c.healthBadgeText then c.healthBadgeText=ui.label("health_badge"..c.nativeID,c.decor,11)end
  if not c.healthBadgeCoords then ui.call(c.healthBadge,"SetCoords",496,0,16,16);c.healthBadgeCoords=true end
  piece(c.healthBadge,c.decor,w-13,2,11,11,ink,ui)
  ui.place(c.healthBadgeText,c.decor,w-10,1,7,13);ui.text(c.healthBadgeText,"!")
  ui.colour(c.healthBadgeText.style,0.12,0.07,0.06,1);ui.show(c.healthBadgeText,true)
  return false
 end
 local f=layout.fill;local missing=f.w*(1-model.hp)
 if missing<=0 then if c.healthHatch then ui.show(c.healthHatch,false)end;if c.healthSolid then ui.show(c.healthSolid,false)end;return false end
 local mode=prefs.hatch_mode=="solid"and"solid"or prefs.hatch_mode=="both"and"both"or"stripes"
 local opacity=prefs.hatch_opacity;if not finite(opacity)or opacity<.1 or opacity>1 then opacity=1 end
 -- Create the missing-health fill first so stripes remain above it when both
 -- treatments are selected later. It is inert and hidden in the legacy mode.
 if not c.healthSolid then c.healthSolid=draw(c.effectTintHost,ui)end
 local solid=mode~="stripes"
 if solid then
  local fill=Colours.rgb(Colours.healthColour(palette,"fill"));fill[4]=opacity
  piece(c.healthSolid,c.effectTintHost,f.x+f.w*model.hp,f.y,missing,f.h,fill,ui)
 else ui.show(c.healthSolid,false)end
 if mode=="solid"then if c.healthHatch then ui.show(c.healthHatch,false)end;return true end
 if not c.healthHatchTried and ui.healthArt then c.healthHatchTried=true;c.healthHatch=ui.healthArt(c.effectTintHost)end
 if not c.healthHatch then if not solid then outline(c.healthOutline,c.decor,2,2,w-4,h-4,1,ink,true,ui)end;return solid end
 local tw,th=math.ceil(missing),math.ceil(f.h)
 if c.healthHatchW~=tw or c.healthHatchH~=th then ui.call(c.healthHatch,"SetCoords",0,0,tw,th);c.healthHatchW=tw;c.healthHatchH=th end
 ink[4]=opacity;piece(c.healthHatch,c.effectTintHost,f.x+f.w*model.hp,f.y,missing,f.h,ink,ui)
 return missing>0
end
-- Conservative, bounded glyph estimates make drag handles follow the visible
-- text without a native measurement call on each repaint. Stable text/font
-- pairs reuse scalar caches; native ellipsis still clips long member names.
local function textWidth(c,kind,value,font)
 local before=kind=="name"and c.nameMetricText or kind=="distance"and c.distanceMetricText or c.healthMetricText
 local size=kind=="name"and c.nameMetricFont or kind=="distance"and c.distanceMetricFont or c.healthMetricFont
 if before==value and size==font then return kind=="name"and c.nameMetricWidth or kind=="distance"and c.distanceMetricWidth or c.healthMetricWidth end
 local units=0
 for i=1,math.min(#value,128)do
  local b=string.byte(value,i)
  units=units+(kind=="health"and b>=48 and b<=57 and .72 or b==32 and .34 or(b==105 or b==108 or b==73 or b==49 or b==46 or b==44 or b==58 or b==59 or b==39 or b==33)and .36
   or(b==77 or b==87 or b==109 or b==119 or b==64 or b==35)and .98
   or b>=48 and b<=57 and .64 or b>=65 and b<=90 and .80 or .70)
 end
 if #value>128 then units=units+(#value-128)*.98 end
 local width=#value>0 and math.ceil(units*font)+2 or 0
 if kind=="name"then c.nameMetricText=value;c.nameMetricFont=font;c.nameMetricWidth=width
 elseif kind=="distance"then c.distanceMetricText=value;c.distanceMetricFont=font;c.distanceMetricWidth=width
 else c.healthMetricText=value;c.healthMetricFont=font;c.healthMetricWidth=width end
 return width
end
local function textPoint(value)
 return type(value)=="table"and finite(value.x)and finite(value.y)and value.x%1==0 and value.y%1==0
  and value.x>=0 and value.x<=1000 and value.y>=0 and value.y<=1000
end
local function anchoredText(point,width,height,w,h,x,y,available)
 if not textPoint(point)then return x,y,math.max(1,available),height end
 local pw=math.max(1,math.min(width,w-2));local ph=math.max(1,math.min(height,h-2))
 local px=math.max(1,math.min(point.x*w/1000-pw/2,w-1-pw))
 local py=math.max(1,math.min(point.y*h/1000-ph/2,h-1-ph))
 return px,py,pw,ph
end
local function overlaps(rect,x,y,w,h)
 return x<rect.x+rect.w and x+w>rect.x and y<rect.y+rect.h and y+h>rect.y
end
local function freeTextPosition(c,x,y,width,height,barWidth,barHeight,crown,protectText)
 local blocked=false
 for _,icon in ipairs(c.iconRects)do if overlaps(icon,x,y,width,height)then blocked=true;break end end
 if protectText and not blocked then
  for _,text in ipairs(c.textRects)do if overlaps(text,x,y,width,height)then blocked=true;break end end
 end
 if protectText and crown and x<14 and y<15 and y+height>3 then blocked=true end
 if not blocked then return x,y end
 local obstacles={}
 for _,icon in ipairs(c.iconRects)do obstacles[#obstacles+1]=icon end
 for _,text in ipairs(c.textRects)do obstacles[#obstacles+1]=text end
 if crown then obstacles[#obstacles+1]={x=2,y=3,w=12,h=12}end
 local bands={y,1,math.max(1,math.floor((barHeight-height)/2)),barHeight-height-1}
 for _,top in ipairs(bands)do
  local left=barWidth-width-1
  while left>=1 do
   local free=left
   for _,rect in ipairs(obstacles)do
    if overlaps(rect,left,top,width,height)then free=math.min(free,rect.x-width-1)end
   end
   if left==free then return left,top end
   left=free
  end
 end
end

-- Prefer full digits at the chosen size. A narrow bar can take a smaller HP
-- font. Scientific notation is reserved for values too wide even at 8 px.
local function fitHealthWidth(c,value,number,font,width,limit)
 if width<=limit then return value,font,width end
 local fitted=math.floor(font*(limit-2)/(width-2))
 if fitted<8 and number and finite(number)then
  value=string.format("%.3g",number):gsub("e%+0*","e")
  width=textWidth(c,"health",value,font)
  fitted=math.floor(font*(limit-2)/(width-2))
 end
 font=math.max(1,math.min(font,fitted))
 return value,font,textWidth(c,"health",value,font)
end

local function paintText(c,row,display,offline,layout,palette,ui,options,w,h)
 local t=layout.text
 local name=(layout.dead or display.show_names)and P.text(row.name,128)or"";local nameWidth=textWidth(c,"name",name,t.font);local healthWidth=textWidth(c,"health",t.status,t.font)
 local positions=type(options.text_positions)=="table"and options.text_positions or nil
 local nx,ny,nw,nh=anchoredText(positions and positions.name,nameWidth,t.nh,w,h,t.nx,t.ny,t.nw)
 local sx,sy,sw,sh=anchoredText(positions and positions.health,healthWidth,t.nh,w,h,t.sx,t.sy,t.sw)
 local distance=not layout.dead and type(options.appearance)=="table"and options.appearance.show_distance==true
 local font=t.font
 local automatic=distance and not textPoint(positions and positions.name)and not textPoint(positions and positions.health)and not textPoint(positions and positions.distance)
 local stacked=false
 if automatic then
  local inner=h-2;stacked=name~=""and inner>=20
  if stacked then
   font=math.min(font,math.max(10,math.floor(inner/2)-2))
   nh=math.min(font+2,math.floor(inner/2));sh=nh
   nx=math.max(1,math.min(t.nx,w-2));ny=1;nw=math.max(1,math.min(t.nw,w-1-nx))
   sx=1;sy=h-1-sh;sw=w-2
  else
   nh=math.min(font+2,inner);sh=nh;ny=h-1-nh;sy=ny
  end
  nameWidth=textWidth(c,"name",name,font);healthWidth=textWidth(c,"health",t.status,font)
 end
 local dx,dy,dw,dh,distanceValue,distanceWidth
 if distance then
  if not c.distance then
   c.distance=ui.label("distance"..c.nativeID,c.root,ui.small_font)
   if c.distance then ui.call(c.distance,"EnablePick",false);ui.call(c.distance,"Clickable",false);ui.call(c.distance.style,"SetEllipsis",true);ui.call(c.distance.style,"SetShadow",true)end
  end
  local known=not offline and row.rangeKnown==true and finite(row.distanceM)and row.distanceM>=0
  distanceValue=known and(string.format("%.0f",math.floor(row.distanceM+.5)).." m")or"?"
  local width=textWidth(c,"distance",distanceValue,font);distanceWidth=width
  dw=math.max(1,math.min(width,w-2));dh=math.max(1,math.min(t.nh,h-2));dx=math.max(1,w-3-dw);dy=math.max(1,h-dh-1)
  dx,dy,dw,dh=anchoredText(positions and positions.distance,width,dh,w,h,dx,dy,dw)
  if automatic then
   local left=not stacked and name~=""and math.max(1,math.min(t.nx,w-4))or 1
   local available=w-1-left
   if t.status~=""then dw=math.min(dw,math.max(1,math.floor(available*.55)))end
   if not stacked and name~=""then dw=math.min(dw,math.max(1,math.floor(available*.45)))end
   dh=sh;dx=w-1-dw;dy=h-1-dh
   if stacked then sw=math.max(1,dx-1-sx)
   elseif name~=""then
    nx=left
    if t.status~=""then sw=math.max(1,math.floor((dx-1-left)*.45));sx=dx-1-sw;nw=math.max(1,sx-1-left)
    else nw=math.max(1,dx-1-left)end
   else sx=left;sw=math.max(1,dx-1-left)end
  elseif not textPoint(positions and positions.distance)then
   if not textPoint(positions and positions.health)and sy<dy+dh and sy+sh>dy then
    if t.status~=""then dw=math.min(dw,math.max(1,math.floor((w-2)*.55)));dx=w-1-dw end
    if sx>=dx-1 then sx=1 end
    sw=math.max(1,math.min(sw,dx-2-sx))
   end
   if not textPoint(positions and positions.name)and ny<dy+dh and ny+nh>dy then
    if name~=""then dw=math.min(dw,math.max(1,math.floor((w-2)*.55)));dx=w-1-dw end
    if nx>=dx-1 then nx=1 end
    nw=math.max(1,math.min(nw,dx-2-nx))
   end
  end
 end
 c.textBounds={width=w,height=h}
 local nameRect
 if name~=""then
  nameRect={kind="name",x=nx,y=ny,w=math.min(nw,nameWidth),h=nh};c.textRects[1]=nameRect
 end
 local hp,healthFont=t.status,font
 local refit=not offline and hp~=""and hp~="?"and healthWidth>sw
 if refit then
  local number=display.health_text=="current"and row.health.current
    or display.health_text=="missing"and(row.health.current-row.health.maximum)
  hp,healthFont,healthWidth=fitHealthWidth(c,hp,number,font,healthWidth,w-2)
  sw=math.min(w-2,healthWidth)
  sh=math.max(1,math.min(sh,healthFont+2,h-2))
  sx=math.max(1,math.min(sx,w-1-sw));sy=math.max(1,math.min(sy,h-1-sh))
  if textPoint(positions and positions.health)then
   sx,sy=anchoredText(positions.health,sw,sh,w,h,sx,sy,sw)
  else
   local x,y=freeTextPosition(c,sx,sy,sw,sh,w,h,t.crown,true)
   if x then sx,sy=x,y end
  end
  if nameRect and not textPoint(positions and positions.name)and overlaps(nameRect,sx,sy,sw,sh)then
   local left=sx-nx-1
   local right=nx+nw-(sx+sw+1)
   if left<1 and right<1 then
    name="";c.textRects[1]=nil
   else
    if right>left then nx=sx+sw+1;nw=right else nw=left end
    nameRect.x=nx;nameRect.w=math.min(nw,nameWidth)
   end
  end
 end
 if hp~=""then c.textRects[#c.textRects+1]={kind="health",x=sx,y=sy,w=math.min(sw,healthWidth),h=sh}end
 if distance and not textPoint(positions and positions.distance)then
  if refit then dw=math.min(w-2,distanceWidth);dx=math.max(1,w-1-dw)end
  dx,dy=freeTextPosition(c,dx,dy,dw,dh,w,h,t.crown,refit)
 end
 if t.crown then ui.checked(c.leader,"SetMark",row.authority);ui.place(c.leader,c.root,2,3,12,12)end;ui.show(c.leader,t.crown or false)
 ui.checked(c.name.style,"SetFontSize",font);ui.checked(c.health.style,"SetFontSize",healthFont)
 ui.place(c.name,c.root,nx,ny,nw,nh);ui.text(c.name,name)
 local ink=colour(palette,row.selfKnown==true and row.isSelf==true and"self_name"or"name")
 if not layout.custom and palette.name==defaults.name and not(row.selfKnown==true and row.isSelf==true)then ink={1,1,1,1}end
 if offline then ink=layout.custom and shade(ink,0.65)or ui.offline_ink end
 ui.colour(c.name.style,ink[1],ink[2],ink[3],ink[4]or 1)
 ui.place(c.health,c.root,sx,sy,sw,sh);ui.text(c.health,hp)
 local hi=offline and ink or colour(palette,"health_text");ui.colour(c.health.style,hi[1],hi[2],hi[3],hi[4]or 1)
 if dx and c.distance then
  ui.checked(c.distance.style,"SetFontSize",font);ui.place(c.distance,c.root,dx,dy,dw,dh);ui.text(c.distance,distanceValue)
  ui.colour(c.distance.style,hi[1],hi[2],hi[3],hi[4]or 1);ui.show(c.distance,true)
  c.textRects[#c.textRects+1]={kind="distance",x=dx,y=dy,w=dw,h=dh}
 elseif c.distance then ui.text(c.distance,"");ui.show(c.distance,false)end
end
function R.paint(c,row,rect,display,hover,ui,options,state)
 c.textRects={}
 options=type(options)=="table"and options or{};state=type(state)=="table"and state or{}
 local w,h=rect.width,rect.height;local palette=type(options.colours)=="table"and options.colours or defaults
 local offline=row.offlineKnown==true and row.offline==true;local key=nativeStyle(row,offline)
 local model=Indicators.state(row,options,state,hover,display.show_mana)
 local opacity=type(options.appearance)=="table"and options.appearance.opacity or 1
 if not finite(opacity)or opacity<0.15 or opacity>1 then opacity=1 end
 model.alpha=model.alpha*opacity
 local custom=type(options.appearance)=="table"and options.appearance.mode=="custom"
 -- Original uses the game's declared raid-role texture unchanged. Class and
 -- authored role palettes belong to Ellesmere, independently of aura effects.
 local base=custom and baseColour(row,key,palette,type(options.member_layout)=="table"and options.member_layout.ordering or nil)or colour(defaults,family(key)or"neutral")
 local prefs=type(options.indicators)=="table"and options.indicators or{}
 local healthStyle=prefs.health_style=="badge"and"badge"or prefs.health_style=="hatch"and"hatch"or"outline"
 local showMana=display.show_mana and not model.dead
 local mh=showMana and(custom and 2 or 6)or 0
 local layout={custom=custom,dead=model.dead,mana=mh,badge=model.lowHealth and healthStyle=="badge",family=not offline and family(key)or nil,base=base,hp=model.hp,fill={x=1,y=1,w=w-2,h=h-mh-2}}
 ui.place(c.root,ui.parent,rect.x,rect.y,w,h);ui.place(c.decor,c.root,0,0,w,h);ui.place(c.effectTintHost,c.root,0,0,w,h)
 local p=c.custom
 if custom then
  hideNative(c,ui)
  local theme=Themes.get();local f=layout.fill
  piece(p.baseMid,c.root,0,0,w,h,theme.canvas,ui);piece(p.trackMid,c.root,f.x,f.y,f.w,f.h,theme.track,ui)
  if model.hp~=nil then piece(p.fillMid,c.root,f.x,f.y,f.w*model.hp,f.h,base,ui)else ui.show(p.fillMid,false)end
  piece(p.edgeTop,c.root,0,0,w,1,theme.border,ui);piece(p.edgeBottom,c.root,0,h-1,w,1,theme.border,ui)
  piece(p.edgeLeft,c.root,0,1,1,h-2,theme.border,ui);piece(p.edgeRight,c.root,w-1,1,1,h-2,theme.border,ui)
  if showMana then
   piece(p.manaTrack,c.root,1,h-mh-1,w-2,mh,theme.track,ui)
   if model.mana~=nil then piece(p.manaFill,c.root,1,h-mh-1,(w-2)*model.mana,mh,colour(palette,"mana"),ui)else ui.show(p.manaFill,false)end
  else ui.show(p.manaTrack,false);ui.show(p.manaFill,false)end
 else
  if not R.ensureNative(c,ui)then return false end
  for _,name in ipairs(customNames)do ui.show(p[name],false)end
  ui.place(c.nativeHost,c.root,0,0,w,h);ui.show(c.nativeHost,true)
  ui.place(c.background,c.nativeHost,0,0,w,h);ui.show(c.background,true)
  local hpStyle=ui.bar_style(key);local mpStyle=ui.bar_style(offline and"MP_RAID_OFFLINE"or"MP_RAID")
  if not hpStyle or not mpStyle then ui.unavailable();return false end
  ui.checked(c.hp,"ApplyBarTexture",hpStyle);ui.checked(c.mp,"ApplyBarTexture",mpStyle)
  ui.place(c.hp,c.nativeHost,0,0,w,h-mh);ui.place(c.mp,c.nativeHost,0,h-7,w,6)
  resource(c.hp,row.health,offline,ui);resource(c.mp,row.mana,offline,ui);ui.show(c.hp,true);ui.show(c.mp,showMana)
 end
 -- Clear any prior owned overlays when switching back from Ellesmere.
 ui.show(c.baseOverride,false);ui.show(c.manaOverride,false)
 layout.text=textLayout(row,w,h,display,offline,layout,ui)
 local scope=type(state.auras)=="table"and state.auras or nil
 local prefs=type(options.auras)=="table"and options.auras or{}
 local plan=model.dead and{}or iconPlan(row,w,h,display,layout,scope,state,prefs,options.aura_icons);local historical=paintIcons(c,plan,ui,row.identity)
 rolePaint(c,w,h,display,layout,ui,options)
 local materialShown=materialPaint(c,row,w,h,layout,scope,state,historical,ui)
 local hatchShown=healthWarning(c,w,h,layout,model,healthStyle,palette,type(options.indicators)=="table"and options.indicators or{},ui)
 ui.show(c.effectTintHost,materialShown or hatchShown)
 paintText(c,row,display,offline,layout,palette,ui,options,w,h-mh)
 outline(c.targetOutline,c.decor,0,0,w,h,1,colour(palette,"target"),model.target,ui)
 outline(c.hoverOutline,c.decor,1,1,w-2,h-2,1,colour(palette,"hover"),model.hover,ui)
 if model.lowMana then piece(c.manaWarning,c.decor,w-8,h-5,6,3,colour(palette,"low_mana"),ui)else ui.show(c.manaWarning,false)end
 ui.checked(c.root,"SetAlpha",model.alpha);c.row=row;c.rect=rect;c.visualState=model;c.theme=custom and"ellesmere"or"native"
 ui.show(c.decor,true);ui.show(c.root,true);return true
end
return R
