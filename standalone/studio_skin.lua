-- Shared live native chrome. DDS calls are source-declared, protected and
-- reported separately from actual image visibility; no native proof is inferred.
-- First-party Skin9 adaptation; fixed Antique Gold standalone namespace.
local unpack=function(v)return v[1],v[2],v[3],v[4]end
local Skin={contract=9,overhaulContract=1}
local states={enable=2,neutral=0,selected=1,action=2,disable=3,hover=4,pressed=5,unavailable=6,focus=7}
local function call(object,key,...)
 local ok,result=pcall(function(...)
  local fn=object and object[key]
  if type(fn)~='function'then return false end
  return fn(object,...)
 end,...)
 return ok and result~=false
end
local function show(d,value)
 local ok,method=pcall(function()return type(d.SetVisible)=='function'and'SetVisible'or'Show'end)
 return ok and call(d,method,value)
end
function Skin.new(appearance,themes)
 local service={contract=9}
 local probe='not_attempted'
 function service.status()return probe end
 function service.current()return appearance.current()end
 function service.session(alive,notice)
  local self={};local active=true
  local texts,colours,controls,frames={},{},{},{}
  local owned={};local issue;local after
  local function live()return active and (not alive or alive())end
  local function warn(code)
   issue=code
   if notice then pcall(notice,code)end
  end
  local function native(w,key,...)
   if not live()then return false end
   local ok=call(w,key,...);return ok and live()
  end
  local function palette()return themes.get(appearance.current())end
  local function texture()
   local id=appearance.current()
   if not themes.has(id)then warn('skin_unknown_theme');return nil end
   return 'Addon/Mazrim_Raid_Frames/assets/skins/v7/'..id..'.dds'
  end
  local function hideImages(list)
   for _,d in ipairs(list)do pcall(show,d,false)end
  end
  local function image(parent,list)
   if not live()or probe=='unavailable'then return nil end
   local path=texture();if not path then return nil end
   local ok,d=pcall(function()return parent:CreateImageDrawable(path,'background')end)
   if not live()then if ok and d then pcall(show,d,false)end;return nil end
   if ok and d then owned[#owned+1]=d;list[#list+1]=d end
   if not ok or not d then
    probe='unavailable';warn('skin_image_unavailable');return nil
   end
   local checked,w,h=pcall(function()return d:GetTextureSize()end)
   if checked and type(w)=='number'and type(h)=='number'and(w~=512 or h~=256)then
    probe='unavailable';warn('skin_image_unavailable');show(d,false);return nil
   end
   if checked and w==512 and h==256 then probe='dimensions_verified_visual_pending'
   else probe='created_visual_pending'end
   return d
  end
  local function draw(d,parent,source,dest,alpha)
   local path=texture();if not path then return false end
   return native(d,'SetTexture',path)and native(d,'SetCoords',unpack(source))
    and native(d,'SetColor',1,1,1,alpha or 1)
    and native(d,'RemoveAllAnchors')and native(d,'SetExtent',dest[3],dest[4])
    and native(d,'AddAnchor','TOPLEFT',parent,dest[1],dest[2])and live()and show(d,true)and live()
  end
  local function ink(style,c,font)
   if font then native(style,'SetFontSize',font)end
   return native(style,'SetColor',c[1],c[2],c[3],c[4]or 1)
  end
  function self.text(style,role,font,state)
   local rec={style=style,role=role or'text',font=font,state=state};texts[#texts+1]=rec
   local p=palette();local s=state and themes.buttonStyle(p,state())
   ink(style,s and s.ink or p[rec.role],font);return rec
  end
  function self.colour(d,role,state)
   colours[#colours+1]={drawable=d,role=role,state=state};return d
  end
  function self.indicator(widget)
   local rec={state='off',images={}};controls[#controls+1]=rec
   function rec.paint(state)
    if state then rec.state=state end
    if not live()then return false end
    local p=palette();local c=rec.state=='on'and p.success or(rec.state=='off'and p.error or p.warning)
    ink(widget.style,c,14)
    local x=rec.state=='on'and 72 or(rec.state=='off'and 104 or 136)
    local d=rec.images[1]or image(widget,rec.images)
    local good=d and draw(d,widget,{x,208,10,10},{0,0,10,10})
    native(widget,'SetText',good and''or'\226\128\162')
    if not good then hideImages(rec.images);warn('skin_image_unavailable')end
    return true
   end
   rec.paint();return rec
  end
  function self.button(widget,caption,size,kind,state,legacy,restore)
   local rec={widget=widget,caption=caption,size=size,kind=kind or'button',state=state or'neutral',images={},legacy=legacy or{}}
   controls[#controls+1]=rec
   function rec.disable()
    rec.disabled=true;hideImages(rec.images);hideImages(rec.legacy)
   end
   function rec.paint(nextState,nextKind)
    if nextState then rec.state=nextState end
    if nextKind then rec.kind=nextKind end
    if not live()then return false end
    local p=palette();local actual=rec.pressed and'pressed'or(rec.hover and'hover'or rec.state)
    if rec.disabled then
     hideImages(rec.images);hideImages(rec.legacy)
     if caption then ink(caption.style,p.text)end
     return true
    end
    local style=themes.buttonStyle(p,actual)
    local w,h=size();local sources,dests={},{}
    if rec.kind=='toggle'then
     sources={{rec.state=='selected'and 416 or 360,8,40,20}}
     dests={{w-48,math.floor((h-20)/2),40,20}}
     if caption then
      native(caption,'SetExtent',w-64,h-4);native(caption,'RemoveAllAnchors')
      native(caption,'AddAnchor','TOPLEFT',widget,6,2)
      local ok,left=pcall(function()return ALIGN.LEFT end)
      if ok and left~=nil then native(caption.style,'SetAlign',left)end
      ink(caption.style,p.text)
     end
    else
     local index=states[actual]or 0
     local x=296+(index%2)*112;local y=88+math.floor(index/2)*44
     if rec.kind=='nav'and actual=='neutral'then
      sources={{472,8,16,28}};dests={{0,0,w,h}}
     else
      sources={{x,y,8,28},{x+8,y,80,28},{x+88,y,8,28}}
      dests={{0,0,8,h},{8,0,math.max(1,w-16),h},{w-8,0,8,h}}
     end
     if caption then ink(caption.style,style.ink)end
    end
    local good=texture()~=nil
    if good then for i=1,#sources do
     local d=rec.images[i]or image(widget,rec.images)
     if not d or not draw(d,widget,sources[i],dests[i])then good=false;break end
    end end
    if not live()then return false end
    if good then
     for i=#sources+1,#rec.images do show(rec.images[i],false)end
     for _,d in ipairs(rec.legacy)do show(d,false)end
    else
     hideImages(rec.images)
     if restore then pcall(restore)end
     if caption then ink(caption.style,rec.kind=='toggle'and p.text or style.ink)end
     warn('skin_image_unavailable')
    end
    return true
   end
   -- Only source-declared pointer states, on these owned controls. Callback
   -- generation/aliveness checks make retained handlers inert before release.
   for name,fn in pairs({OnEnter=function()rec.hover=true end,OnLeave=function()rec.hover=false;rec.pressed=false end,
    OnMouseDown=function()rec.pressed=true end,OnMouseUp=function()rec.pressed=false end})do
    native(widget,'SetHandler',name,function()if live()and not rec.disabled then fn();rec.paint()end end)
   end
   rec.paint();return rec
  end
  function self.frame(root,size,header,legacy,options)
   header=header or 0
   local rec={root=root,size=size,header=header,legacy=legacy or{},images={}}
   frames[#frames+1]=rec
   function rec.paint()
    if not live()then return false end
    local w,h=size();local p=palette();local sources,dests,alphas={},{},{}
    local playful=p.id=='velvet_paws'or p.id=='candy_hearts'
    local function piece(s,d,alpha)sources[#sources+1]=s;dests[#dests+1]=d;alphas[#alphas+1]=alpha or 1 end
    for row=0,2 do for col=0,2 do
     local sx=col==0 and 0 or col==1 and 16 or 48
     local sy=row==0 and 0 or row==1 and 16 or 48
     local sw=col==1 and 32 or 16;local sh=row==1 and 32 or 16
     local x=col==0 and 0 or col==1 and 16 or w-16
     local y=row==0 and 0 or row==1 and 16 or h-16
     piece({sx+280,sy+8,sw,sh},{x,y,col==1 and w-32 or 16,row==1 and h-32 or 16})
    end end
    if header>0 then
     piece({8,8,8,76},{6,6,8,header-6})
     piece({16,8,240,76},{14,6,w-28,header-6})
     piece({256,8,8,76},{w-14,6,8,header-6})
     if w>=600 and header>=70 then
      piece({8,204,40,44},{18,15,40,44})
      piece({8,108,210,75},{w-480,-1,210,75},playful and 0.62 or(p.id=='silverveil'and 0.5 or 0.38))
      if playful then
       piece({8,108,210,75},{w-610,8,152,54},0.46)
       if h>=600 and(not options or not options.footer or options.footer())then
        local dest=options and options.compactFooter and{w-96,h-44,79,28}or{w-176,h-64,160,57}
        piece({8,108,210,75},dest,0.48)
       end
      end
     end
    end
    local good=texture()~=nil
    if good then for i=1,#sources do
     local d=rec.images[i]or image(root,rec.images)
     if not d or not draw(d,root,sources[i],dests[i],alphas[i])then good=false;break end
    end end
    if not live()then return false end
    if good then
     for i=#sources+1,#rec.images do show(rec.images[i],false)end
     for _,d in ipairs(rec.legacy)do show(d,false)end
    else
     hideImages(rec.images);for _,d in ipairs(rec.legacy)do show(d,true)end
     warn('skin_image_unavailable')
    end
    return true
   end
   rec.paint();return rec
  end
  function self.refresh()
   if not live()then return false end
   issue=nil;if notice then pcall(notice,nil)end
   local p=palette()
   for _,e in ipairs(colours)do
    local s=e.state and themes.buttonStyle(p,e.state())
    local c=s and s[e.role]or p[e.role]
    if c then native(e.drawable,'SetColor',c[1],c[2],c[3],c[4]or 1)end
   end
   for _,e in ipairs(texts)do
    local s=e.state and themes.buttonStyle(p,e.state());ink(e.style,s and s.ink or p[e.role],e.font)
   end
   for _,e in ipairs(frames)do e.paint()end
   for _,e in ipairs(controls)do e.paint()end
   return true
  end
  function self.after(fn)after=fn end
  local release=appearance.subscribe(function(id)
   local ok=self.refresh()
   if ok and after and live()then local done,result=pcall(after,id);if not done or result==false then warn('skin_restyle_failed');return false end end
   return ok
  end)
  if not release then warn('skin_subscription_limit')end
  function self.status()return issue end
  function self.stop()
   active=false;if release then release();release=nil end
   hideImages(owned);texts={};colours={};controls={};frames={};owned={};return true
  end
  return self
 end
 return service
end
return Skin
