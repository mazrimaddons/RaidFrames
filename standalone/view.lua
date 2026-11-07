-- Native UI shell, built only from first-party source-observed widget contracts.
-- Synthetic preview and an injected live group reader share this UI shell.
local B=require("Mazrim_Raid_Frames/standalone/bridge")
local P=require("Mazrim_Raid_Frames/shared/presentation")
local C=require("Mazrim_Raid_Frames/shared/controller")
local R=require("Mazrim_Raid_Frames/shared/cell_renderer")
local Themes=require("Mazrim_Raid_Frames/shared/themes")
local L=require("Mazrim_Raid_Frames/standalone/live")
local S=require("Mazrim_Raid_Frames/standalone/storage")
local H=require("Mazrim_Raid_Frames/shared/hover_target")
local I=require("Mazrim_Raid_Frames/shared/identity")
local Studio=require("Mazrim_Raid_Frames/standalone/settings_ui")
local Ordering=require("Mazrim_Raid_Frames/shared/ordering")
local MemberLayout=require("Mazrim_Raid_Frames/shared/member_layout")
local RaidAlerts=require("Mazrim_Raid_Frames/shared/raid_alerts")
local Auras=require("Mazrim_Raid_Frames/shared/auras")
local Preferences=require("Mazrim_Raid_Frames/shared/preferences")
local ProfileShare=require("Mazrim_Raid_Frames/shared/profile_share")
local Watch=require("Mazrim_Raid_Frames/shared/watchlist")
local Library=require("Mazrim_Raid_Frames/standalone/effect_library")
local Trace=require("Mazrim_Raid_Frames/shared/target_trace")
local Colours=require("Mazrim_Raid_Frames/shared/colours")
local Picker=require("Mazrim_Raid_Frames/shared/colour_picker")
local Materials=require("Mazrim_Raid_Frames/shared/materials")
local StudioSkin=require("Mazrim_Raid_Frames/standalone/studio_skin")
local StudioPalette=require("Mazrim_Raid_Frames/standalone/studio_palette")
local Foundation=require("Mazrim_Raid_Frames/shared/foundation")
local V={colourPickerContract=Picker.contract==1 and Studio.colourPickerContract==1 and 1 or 0,roleIconToggleContract=Preferences.roleIconToggleContract==1 and R.roleIconToggleContract==1 and 1 or 0,alwaysShiftDragContract=C.alwaysShiftDragContract==1 and Studio.alwaysShiftDragContract==1 and 1 or 0,tooltipLayerContract=Studio.tooltipLayerContract==1 and 1 or 0,overhaulContract=Foundation.overhaulContract==1 and StudioPalette.overhaulContract==1 and C.overhaulContract==1 and P.overhaulContract==1 and Studio.overhaulContract==1 and R.tintCandidatesContract==1 and Auras.tintCandidatesContract==1 and R.visualOverhaulContract==1 and Preferences.overhaulContract==1 and S.overhaulContract==1 and StudioSkin.overhaulContract==1 and Colours.overhaulContract==1 and Watch.frameRulesContract==1 and Auras.frameRulesContract==1 and Library.frameRulesContract==1 and 1 or 0,raidAdapterContract=1,version="0.2.72",slotMetadataContract=R.offlineStatusContract==1 and 1 or 0,
  inputRecoveryContract=B.pointerSpaceContract==1 and type(B.mouse)=="function"and type(B.offset)=="function"
    and R.surfaceIsolationContract==1 and 1 or 0,
  expandedStylesContract=Themes.expandedStylesContract==1 and Preferences.expandedStylesContract==1
    and R.expandedStylesContract==1 and Studio.expandedStylesContract==1 and 1 or 0,
  adaptiveEffectsContract=R.adaptiveEffectsContract==1 and 1 or 0,
  memberManaContract=R.manaDisplayContract==1 and 1 or 0,wideNamesContract=C.wideNamesContract==1 and 1 or 0,
  hoverTargetContract=H.contract==2 and R.noManaHoverContract==1 and 1 or 0,
  layoutToolsContract=C.layoutToolsContract==1 and P.compactContract==1 and S.compactContract==1 and 1 or 0,
  healthEmphasisContract=R.healthEmphasisContract==1 and 1 or 0,
  placementContract=C.placementContract==1 and S.placementContract==1 and 1 or 0,
  instantHoverContract=H.contract==2 and R.pointerTargetContract==1 and 1 or 0,
  shiftDragContract=C.shiftDragContract==1 and 1 or 0,
  nativeRaidContract=R.nativeRaidContract==1 and P.nativeRaidContract==1 and C.nativeRaidContract==1 and S.nativeRaidContract==1 and 1 or 0,
  dragRecoveryContract=R.dragRecoveryContract==1 and 1 or 0,
  nativeNameFeedbackContract=H.nativeNameFeedbackContract==1 and 1 or 0,resourceCheckUIContract=1,
  healingStudioContract=C.preferencesContract==1 and C.profileContract==1 and S.preferencesContract==1 and S.profileContract==1 and R.healingIndicatorsContract==1 and R.customThemesContract==1 and Studio.contract==1 and Auras.contract==1 and 1 or 0,
  studioControlsContract=C.dimensionsContract==1 and Studio.controlsContract==2 and 2 or 0,
  raidManagementContract=Studio.raidManagementContract==1 and 1 or 0,
  hudManagementContract=Studio.hudManagementContract==2 and P.hudManagementContract==2 and S.managementHintContract==1 and 2 or 0,
  effectRulesContract=Watch.contract==1 and Library.contract==1 and Library.commonEffectsContract==1 and Preferences.watchlistContract==1
    and S.watchlistContract==1 and Studio.effectBrowserContract==1 and Library.unifiedSearchContract==1
    and Studio.unifiedEffectsContract==1 and Auras.watchlistContract==1 and R.effectTintContract==1 and 1 or 0,
  selectedOnlyContract=Watch.selectedOnlyContract==1 and Auras.selectedOnlyContract==1 and Studio.selectedOnlyContract==1 and 1 or 0,
  effectPriorityContract=Watch.priorityContract==1 and Auras.priorityContract==1 and Studio.priorityContract==1
    and Preferences.priorityContract==1 and S.priorityContract==1 and 1 or 0,
  targetTraceContract=Trace.contract==1 and Trace.saveFormatContract==1 and Studio.targetTraceContract==1 and 1 or 0,
  nameRefreshModeContract=Studio.nameRefreshModeContract==1 and 1 or 0}
-- Original Raid Crest geometry from the selected 28px design, quantised to26px.
-- Decorative colour pieces have no input surface and share the owned button.
local CREST_PALETTE={edge={124/255,116/255,87/255},gold={198/255,180/255,127/255},
  light={220/255,229/255,218/255},blue={108/255,161/255,187/255},mid={57/255,116/255,140/255},
  deep={33/255,56/255,66/255},paper={178/255,187/255,167/255}}
local CREST_RECTS={{4,1,20,2,"gold"},{2,3,24,15,"edge"},{4,18,20,4,"edge"},{7,22,14,3,"edge"},{11,25,6,2,"edge"},
  {4,4,20,13,"deep"},{6,17,16,4,"deep"},{9,21,10,2,"deep"},{5,4,18,1,"blue"},
  {12,6,4,4,"light"},{10,11,8,7,"blue"},{5,9,3,3,"paper"},{4,13,5,5,"mid"},{20,9,3,3,"paper"},{19,13,5,5,"mid"}}
function V.new(api,liveAdapter,targetAttempt,targetFeedback,resourceProbe,ownerCurrent,nativeControls)
  local iface=B.member(api,"Interface")
  local s={active=true,visible=false,built=false,owned={},effect_icons={},cells={},labels={},buttons={},cache={},
    handlers={},failed=false,paint_count=0,last_tick=nil,last_live=nil,cleanup_ok=true,hover_index=nil,input_epoch=0,selected_identity=nil}
  local feedback=type(targetFeedback)=="table" and targetFeedback.nativeNameFeedbackContract==1 and targetFeedback or nil
  local probe=type(resourceProbe)=="table" and resourceProbe.contract==1 and resourceProbe or nil
  local probe_tick_failed=false
  local function probe_call(key)
    local fn=B.member(probe,key)
    if type(fn)~="function" then return false end
    return pcall(fn)
  end
  local function feedback_call(key,...)
    local fn=B.member(feedback,key)
    if type(fn)=="function" then
      local ok,result=pcall(fn,...);if not ok then feedback=nil end
      return ok,result
    end
  end
  local owner_alive
  local show,replace_handler
  s.storage=S.new(api);s.controller=C.new(s.storage.load());s.live=liveAdapter or L.new(api)
  s.first_use_tour=B.member(nativeControls,"firstUseTour")==true
  s.remember_controls=B.member(nativeControls,"rememberControls")==true
  s.hover_intent=s.remember_controls and s.controller.config.controls and s.controller.config.controls.hover==true or false
  local returnTarget=B.member(nativeControls,"returnTarget")
  local hoverAttempt=targetAttempt
  if type(targetAttempt)=="function"then hoverAttempt=function(token,id,guard,name)
    local stamp
    if s.controller.config.options.input.return_target and returnTarget then
      stamp=returnTarget.before(s.last_plan and s.last_plan.data.rows or{},id,guard)
    end
    local ok,result=pcall(targetAttempt,token,id,guard,name)
    if stamp then returnTarget.after(id,ok and result=="REQUESTED",stamp)end
    if ok and result=="REQUESTED"and owner_alive and owner_alive()and s.visible then
      -- Hover-only selection can rebuild native picking just like Click.
      -- Repair after selection returns; do not depend on MouseDown/events.
      s.dock_repair_serial=(s.dock_repair_serial or 0)+1;s.dock_repair_pending=true
      if not s.painting and s.repair_dock then s.repair_dock()end
    end
    return ok and result or"FAILED"
  end end
  s.hover=H.new(hoverAttempt,function()
    return (not owner_alive or owner_alive()) and s.active and s.visible and not s.failed and s.controller.mode=="live"
      and s.controller.config.visibility.frames~=false and not s.settings_open and not s.dragging and not s.aux_drag and not s.pointer_pressed
      and type(s.controller.live)=="table" and s.controller.live.source=="raid"
      and s.controller.live.coverage~="ROSTER_UNAVAILABLE"
  end)
  local selection=B.member(nativeControls,"selection")
  local auraSource=B.member(nativeControls,"auraSource")
  local localMarker=B.member(nativeControls,"localMarker")
  local raidTracker=B.member(nativeControls,"raidTracker")
  s.raidAlerts=RaidAlerts.new()
  local trace=B.member(nativeControls,"trace")
  if type(trace)~="table"or trace.contract~=1 then trace=nil end
  s.target_trace=trace;s.trace_entry=0
  local function trace_call(key,...)
    if not trace then return false end
    local fn=trace[key];if type(fn)~="function"then return false end
    local ok,a=pcall(fn,...)
    if not ok then pcall(trace.close);trace=nil;s.target_trace=nil;return false end
    return true,a
  end
  local function trace_record(kind,data)trace_call("record",kind,data)end
  owner_alive=function()
    if not s.active or s.failed then return false end
    if type(ownerCurrent)=="function" then local ok,v=pcall(ownerCurrent);return ok and v==true and s.active end
    return true
  end
  local function remember_control(patch)
    if not s.remember_controls or not owner_alive()then return false end
    local c=s.controller.config.controls or{hover=false,native_frames="unchanged"}
    for key,value in pairs(patch)do c[key]=value end;s.controller.config.controls=c
    if patch.hover~=nil then s.hover_intent=patch.hover end
    local ok,saved=pcall(s.storage.rememberControls,patch,owner_alive)
    if not ok or saved~=true then s.studio_notice="Control choice applies now; it could not be saved for reloads."end
    return ok and saved==true
  end
  function s.restore_hover_intent(now)
    if not s.remember_controls or not owner_alive()or not s.visible then return false end
    s.hover_enabled=s.hover_intent==true
    if not s.hover_enabled then if s.hover.armed then s.hover.disarm()end;return false end
    if not B.finite(now)or s.settings_open or s.dragging or s.aux_drag or s.member_drag or s.pointer_pressed
      or s.settings_moving or s.colour_picker or s.reset_pending or s.controller.config.visibility.frames==false then return false end
    if not s.hover.armed then
      s.hover.arm();s.hover.block(s.last_hover_key)
    end
    return s.hover.armed
  end
  function s.restore_native_preference(now)
    if not s.remember_controls or s.native_restore_done or not owner_alive()then return false end
    local choice=s.controller.config.controls and s.controller.config.controls.native_frames
    if type(choice)~="boolean"then s.native_restore_done=true;return false end
    local fn=B.member(nativeControls,"setRaidVisible");if type(fn)~="function"then return false end
    if not B.finite(now)then return false end
    if s.native_restore_clock and now<s.native_restore_clock then s.native_restore_at=nil end
    s.native_restore_clock=now
    if(s.native_restore_at and now<s.native_restore_at)or(s.native_restore_attempts or 0)>=3 then return false end
    s.native_restore_attempts=(s.native_restore_attempts or 0)+1;s.native_restore_at=now+500
    local ok,value=pcall(fn,choice)
    if owner_alive()and ok and value==true then s.native_restore_done=true;return true end
    s.studio_notice="Original-frame preference is saved; native control is currently unavailable."
    return false
  end
  function s.request_native_visibility()
    if not owner_alive()then return false end
    local set=B.member(nativeControls,"setRaidVisible")
    if s.remember_controls then
      if type(set)~="function"then
        s.studio_notice="Persistent original-frame control unavailable. Use Raid management > raid options."
        return false
      end
      local choice=s.controller.config.controls and s.controller.config.controls.native_frames
      local desired=choice==false
      local ok,value=pcall(set,desired)
      if owner_alive()and ok and value==true then
        local saved=remember_control({native_frames=desired});s.native_restore_done=true
        if saved then s.studio_notice=desired and"Return original frames requested and remembered."or"Hide original frames requested and remembered."end
        return true
      end
      s.studio_notice="Persistent original-frame control unavailable. Use Raid management > raid options."
      return false
    end
    local toggle=B.member(nativeControls,"toggleRaid");local ok,value=false,false
    if type(toggle)=="function"then ok,value=pcall(toggle)end
    s.studio_notice=ok and value==true and"Hide / return original raid frames requested."or"Original raid frame control unavailable."
    return ok and value==true
  end
  local appearance={current=function()return "gilded_reliquary"end,subscribe=function()return function()end end}
  s.chrome=StudioSkin.new(appearance,StudioPalette).session(owner_alive,function(code)s.chrome_issue=code end)
  local function paint_button_chrome(o,active,kind,captionValue)
    if not owner_alive()then return end
    local c=s.cache[o];if not c or not c.w or not c.h then return end
    kind=kind or"button"
    local caption=o
    if kind=="toggle"then
      if not c.switch_caption and s.make_switch_caption then c.switch_caption=s.make_switch_caption(o)end
      caption=c.switch_caption
      c.switch_state=active==true;c.switch_text=captionValue or(active and"On"or"Off")
      if c.switch_native_text~=""then B.call(o,"SetText","");c.switch_native_text="";c.SetText=nil end
      if caption then
        local value=c.w<112 and""or c.switch_text
        if c.switch_caption_text~=value then B.call(caption,"SetText",value);c.switch_caption_text=value end
        if c.switch_caption_shown~=true then B.call(caption,"Show",true);c.switch_caption_shown=true end
      end
    elseif c.switch_caption and c.switch_caption_shown~=false then B.call(c.switch_caption,"Show",false);c.switch_caption_shown=false;c.switch_native_text=nil end
    local state=kind=="toggle"and(active and"selected"or"neutral")or(c.enabled==false and"disable"or active and"selected"or"neutral")
    local key=string.format("%s/%s/%s/%s/%s",c.w,c.h,kind,state,c.enabled==false and"disabled"or"enabled")
    if c.chrome_key==key then return end
    c.chrome_key=key
    if c.chrome and c.chrome_kind~=kind then c.chrome.disable();c.chrome=nil end
    c.chrome_kind=kind
    if not c.chrome then
      c.chrome=s.chrome.button(o,caption,function()return c.w,c.h end,kind,state,{o.studio_bg},function()
        if o.studio_bg then B.call(o.studio_bg,"Show",true)end
        if kind=="toggle"then
          if caption then B.call(caption,"Show",false)end
          B.call(o,"SetText",c.switch_text or(active and"On"or"Off"))
        end
      end)
      s.handlers[o]=s.handlers[o]or{}
      for _,name in ipairs({"OnEnter","OnLeave","OnMouseDown","OnMouseUp"})do s.handlers[o][#s.handlers[o]+1]=name end
    else c.chrome.paint(state,kind)end
  end
  s.auraModel=Auras.new(owner_alive)
  s.effectLibrary=Library.new(api,owner_alive);s.effect_scope="browse";s.effect_query=""
  function s.save_target_trace()
    if s.trace_saving or not trace or not owner_alive()or not s.visible then return false end
    local ok,report=trace_call("export")
    if not ok or type(report)~="table"or type(report.events)~="table"then return false end
    local capture=report.capture;local service=trace
    local function current()
      return trace==service and owner_alive()and s.visible and service.captureId()==capture and not service.isActive()
    end
    if not current()then return false end
    s.trace_saving=true
    local function finish(saved)
      s.trace_saving=false
      if current()then
        trace_call("acknowledge",capture,saved);s.trace_saved_capture=saved and capture or nil
        s.trace_save_notice=saved and"Saved target check."or"Target check save failed; use Save capture to retry."
      end
      return saved
    end
    local file=B.member(api,"File");local write=B.member(file,"Write")
    if not current()or type(write)~="function"then return finish(false)end
    local good,value=pcall(write,file,"Mazrim_Raid_Frames/target-check.txt",report)
    if not current()then return finish(false)end
    if not good or value==false then return finish(false)end
    local read=B.member(file,"Read")
    if not current()or type(read)~="function"then return finish(false)end
    local readOK,copy=pcall(read,file,"Mazrim_Raid_Frames/target-check.txt")
    if not current()then return finish(false)end
    local budget=8192
    local function equal(a,b,depth)
      budget=budget-1;if budget<0 or depth>8 or type(a)~=type(b)then return false end
      if type(a)~="table"then return (a==nil or type(a)=="string"or type(a)=="boolean"or B.finite(a))and a==b end
      local n,m=0,0
      for key,value in pairs(a)do
        n=n+1;if n>1024 or(type(key)~="number"and type(key)~="string")or not equal(value,b[key],depth+1)then return false end
      end
      for _ in pairs(b)do m=m+1;if m>1024 then return false end end
      return n==m
    end
    return finish(readOK and equal(report,copy,0)==true)
  end
  local function save_trace()
    local ok,saved=pcall(s.save_target_trace)
    if not ok then
      s.trace_saving=false
      if owner_alive()and s.visible then s.trace_save_notice="Target check save failed; retry from Status."end
    end
    return ok and saved==true
  end
  local function cancel_input()
    if s.cancel_text_drag then s.cancel_text_drag()end
    s.ordering_menu=nil
    if s.studio then show(s.studio.orderingMenuRoot,false)end
    if s.set_ordering_menu_input then s.set_ordering_menu_input(false)end
    s.drag_resume_hover=nil;s.manager_menu_open=false;s.dock_repair_pending=nil
    s.input_epoch=s.input_epoch+1;s.click_ticket=nil;s.manager_help_open=false
    s.marker_menu_subject=nil;show(s.marker_menu_root,false)
    if returnTarget then returnTarget.cancel()end
    s.hover_enabled=false;s.hover.disarm();s.hover.leave();s.hover_rect=nil;s.pointer_cell=nil;s.pointer_pressed=false
    feedback_call("cancel");probe_call("stop");return true
  end
  local function cycle(value,values)
    for i=1,#values do if values[i]==value then return values[i%#values+1] end end
    return values[1]
  end
  local function whole_pixels(value,lo,hi)
    if type(value)~="string"then return nil end
    local digits=string.match(value,"^%s*(%d+)%s*$")
    if not digits or #digits>6 then return nil end
    local n=0
    for i=1,#digits do n=n*10+string.byte(digits,i)-48 end
    if n<lo or n>hi then return nil end
    return n
  end
  local function contains(rect,x,y)
    return rect and B.finite(x)and B.finite(y)and x>=rect.x and x<rect.x+rect.w and y>=rect.y and y<rect.y+rect.h
  end
  local function call(o,k,...)return B.call(o,k,...)end
  local function hide_icon(o,guard)
    local ok,value=call(o,"Show",false)
    if guard and not guard()then return false end
    if ok and value~=false then return true end
    local verified,visible=call(o,"IsVisible")
    if guard and not guard()then return false end
    return verified and visible==false
  end
  local function critical(o,k,...)
    if not s.active then return false end
    local ok,v=call(o,k,...)
    if not s.active then return false end
    if not ok or v==false then s.failed=true;s.first_failure=s.first_failure or k;return false end
    if k=="SetHandler" then
      local name=(...);s.handlers[o]=s.handlers[o] or {};s.handlers[o][#s.handlers[o]+1]=name
    end
    return true
  end
  local function own(o)
    if o then s.owned[#s.owned+1]=o else s.failed=true end
    if not s.active then if s.close then s.close()end;return nil end
    return o
  end
  local function empty(id)
    if not owner_alive()then return nil end
    local ok,o=call(iface,"CreateEmptyWindow","maz_raid_basics_"..id,"UIParent")
    if ok and o then return own(o) end;s.failed=true;s.first_failure=s.first_failure or "CreateEmptyWindow"
  end
  local function widget(kind,id,parent)
    if not owner_alive()then return nil end
    local ok,o=call(iface,"CreateWidget",kind,"maz_raid_basics_"..id,parent)
    if ok and o then return own(o) end;s.failed=true;s.first_failure=s.first_failure or "CreateWidget"
  end
  local function cached(o,k,value)
    if not s.active then return false end
    if not o then s.failed=true;return false end
    local c=s.cache[o];if not c then c={};s.cache[o]=c end
    if c[k]==value then return true end
    if critical(o,k,value) then c[k]=value;return true end
    return false
  end
  show=function(o,v)
    if not o then return end
    if s.effect_icons[o]and v==false then
      if not owner_alive()then return false end
      local c=s.cache[o];if not c then c={};s.cache[o]=c end
      if c.Show==false then return true end
      if not hide_icon(o,owner_alive)then
        if owner_alive()then s.failed=true;s.first_failure=s.first_failure or"effect_icon_hide"end
        return false
      end
      c.Show=false;return true
    end
    return cached(o,"Show",v)
  end
  local function text(o,v)
    local c=s.cache[o]
    if c and c.chrome_kind=="toggle"then c.SetText=v;return true end
    if o then return cached(o,"SetText",v)end
  end
  local function place(o,parent,x,y,w,h)
    if not s.active then return false end
    if not o then s.failed=true;return false end
    local c=s.cache[o];if not c then c={};s.cache[o]=c end
    if c.parent==parent and c.x==x and c.y==y and c.w==w and c.h==h then return true end
    if not critical(o,"SetExtent",w,h)or not critical(o,"RemoveAllAnchors")or not s.active then return false end
    local ok,v=call(o,"AddAnchor","TOPLEFT",parent,"TOPLEFT",x,y)
    if not s.active then return false end
    if not ok or v==false then ok,v=call(o,"AddAnchor","TOPLEFT",parent,x,y) end
    if not ok or v==false then s.failed=true;s.first_failure=s.first_failure or "AddAnchor";return false end
    c.parent=parent;c.x=x;c.y=y;c.w=w;c.h=h;return true
  end
  local function colour(o,r,g,b,a)
    if not s.active then return end
    if not o then s.failed=true;return end
    local key=string.format("%.3f,%.3f,%.3f,%.3f",r,g,b,a)
    local c=s.cache[o];if not c then c={};s.cache[o]=c end
    if c.colour==key then return end
    if critical(o,"SetColor",r,g,b,a) then c.colour=key end
  end
  local function drawable(parent,r,g,b,a)
    if not s.active then return nil end
    local ok,o=call(parent,"CreateColorDrawable",r,g,b,a,"background")
    if not s.active then return nil end
    -- Drawables belong to their parent; freeing that owner releases them.
    if not ok or not o then s.failed=true;s.first_failure=s.first_failure or "CreateColorDrawable";return nil end
    show(o,true);return o
  end
  local function label(id,parent,size)
    local o=widget("label",id,parent);if not o then return nil end
    local style=B.member(o,"style")
    critical(style,"SetFontSize",size);critical(style,"SetColor",0.93,0.96,0.98,1)
    local align=B.member(ALIGN,"LEFT");if align then call(style,"SetAlign",align) end
    if not s.active then return nil end
    call(o,"EnablePick",false);if not s.active then return nil end;call(o,"Clickable",false);show(o,true);return o
  end
  s.make_switch_caption=function(parent)
    s.switch_caption_serial=(s.switch_caption_serial or 0)+1
    local o=label("switch_caption_"..s.switch_caption_serial,parent,12)
    if o then call(o,"EnablePick",false);call(o,"Clickable",false)end
    return o
  end
  local function factory(source,key,id,parent)
    if not owner_alive()then return nil end
    local fn=B.member(source,key)
    if type(fn)~="function" then s.failed=true;s.first_failure=s.first_failure or key;return nil end
    local ok,o=pcall(fn,"maz_raid_native_"..id,parent)
    if not ok or not o then s.failed=true;s.first_failure=s.first_failure or key;return nil end
    return own(o)
  end
  local function raid_bar(id,parent)
    local o=factory(W_BAR,"CreateStatusBarOfRaidFrame",id,parent)
    if o then
      call(o,"EnablePick",false);call(o,"Clickable",false)
      local status=B.member(o,"statusBar")
      call(status,"EnablePick",false);call(status,"Clickable",false)
    end
    return o
  end
  local function raid_background(parent)
    local path=B.member(TEXTURE_PATH,"RAID")
    if type(path)~="string" then s.failed=true;return nil end
    local ok,o=call(parent,"CreateNinePartDrawable",path,"background")
    if not ok or not o then s.failed=true;s.first_failure=s.first_failure or "CreateNinePartDrawable";return nil end
    critical(o,"SetCoords",33,141,7,7);critical(o,"SetInset",3,3,3,3)
    critical(o,"SetColor",1,1,1,0.8);show(o,true);return o
  end
  local function checked(o,k,...)
    if not o then s.failed=true;return false end
    -- All native render arguments here are scalars or immutable style tables.
    local c=s.cache[o] or {};s.cache[o]=c
    local args={...};local prior=c["native_"..k];local equal=prior and #prior==#args
    if equal then for i=1,#args do if prior[i]~=args[i] then equal=false;break end end end
    if equal then return true end
    if critical(o,k,...) then c["native_"..k]=args;return true end
    return false
  end
  -- Button input setters vary between native clients. An unsupported method
  -- must not stop the HUD, and failed attempts must not repeat every refresh.
  local function optional_input(o,k,value)
    if not o or not owner_alive()then return end
    local c=s.cache[o]or{};s.cache[o]=c
    local key="input_attempt_"..k
    if c[key]==value then return end
    c[key]=value
    call(o,k,value)
  end
  local function rebuild_pick_geometry()
    for i=1,#s.cells do
      local c=s.cells[i];local cachedCell=c.root and s.cache[c.root]
      if cachedCell then
        cachedCell.parent=nil;cachedCell.input_attempt_Enable=nil;cachedCell.input_attempt_EnablePick=nil
        cachedCell.input_attempt_Clickable=nil;cachedCell.input_attempt_EnableDrag=nil
      end
    end
    for _,o in pairs(s.buttons)do if s.cache[o]then s.cache[o].parent=nil end end
  end
  function s.end_drag(commit)
    if not s.dragging then return true end
    if s.stopping_drag then return false end
    s.stopping_drag=true
    local ok,value=call(s.root,"StopMovingOrSizing")
    s.stopping_drag=false
    if not ok or value==false then return false end
    s.dragging=false;s.pointer_cell=nil;s.pointer_pressed=false
    if s.cache[s.root] then s.cache[s.root].parent=nil end
    rebuild_pick_geometry()
    if commit and owner_alive()then
      local read,x,y=B.offset(api,s.root,owner_alive)
      if not owner_alive()then return true end
      local w,h=B.extent(api,owner_alive);if not owner_alive()then return true end
      s.controller.screen(w,h)
      if not read or not s.controller.setPosition(x,y) then s.drag_notice="Position read failed; prior placement kept."
      else s.drag_notice="Position moved; Save settings to keep." end
    end
    return true
  end
  local function begin_drag()
    if not s.active or not s.visible or not s.drag_ready or s.dragging then return end
    local ok,shift=call(B.member(api,"Input"),"IsShiftKeyDown")
    if not ok or shift~=true or not owner_alive()or not s.visible or not s.root then return end
    local resume=s.hover.armed==true
    cancel_input();s.drag_resume_hover=resume
    show(s.settings_tip,false)
    show(s.manager_tip,false)
    if not owner_alive()or not s.visible then if s.failed then s.fault()end;return end
    s.drag_click_block=true
    s.dragging=true
    local moved,result=call(s.root,"StartMoving")
    if not moved or result==false then
      s.drag_notice="Shift-drag unavailable."
      if not s.end_drag(false) then s.fault() end
    end
  end
  local function finish_drag()
    if s.member_drag then s.end_member_drag(true);return end
    if s.aux_drag then if s.end_aux_drag(true)then s.refresh();s.hover.block(s.last_hover_key)else s.fault()end;return end
    if not s.active or s.stopping_drag or not s.dragging then return end
    if not s.end_drag(true) then s.fault();return end
    local resume=s.drag_resume_hover;s.drag_resume_hover=nil
    if resume and owner_alive()and s.visible and not s.settings_open then s.hover_enabled=s.hover.arm()==true end
    s.refresh()
    if resume then s.hover.block(s.last_hover_key)end
  end
  local function bind_drag(handle,eligible)
    if type(B.member(B.member(api,"Input"),"IsShiftKeyDown"))~="function"
      or type(B.member(s.root,"StartMoving"))~="function" or type(B.member(s.root,"StopMovingOrSizing"))~="function"
      or (type(B.member(s.root,"GetOffset"))~="function" and type(B.member(s.root,"GetEffectiveOffset"))~="function") then return false end
    -- Native raid eventWindow uses EnableDrag only. An unrelated optional
    -- RegisterForDrag method must not disable a successfully enabled surface.
    local ok,v=call(handle,"EnableDrag",true)
    if not ok or v==false then return false end
    call(handle,"EnablePick",true);call(handle,"Clickable",true)
    local function start()
      if type(eligible)=="function" then
        local ok,v=pcall(eligible);if not ok or v~=true then return end
      end
      local ctrlOk,ctrl=call(B.member(api,"Input"),"IsControlKeyDown")
      if ctrlOk and ctrl==true and handle.member_cell then s.begin_member_drag(handle.member_cell);return end
      if handle.priority_root then s.begin_aux_drag(handle.priority_root,"priority")else begin_drag()end
    end
    for _,entry in ipairs({{"OnDragStart",start},{"OnDragStop",finish_drag},{"OnDragEnd",finish_drag}}) do
      if not critical(handle,"SetHandler",entry[1],entry[2]) then return false end
    end
    return true
  end
  function s.end_aux_drag(commit)
    local d=s.aux_drag;if not d then return true end;if s.aux_stopping then return false end
    s.aux_stopping=true;local ok,v=call(d.root,"StopMovingOrSizing");s.aux_stopping=false
    if not ok or v==false then return false end
    s.aux_drag=nil;s.pointer_pressed=false
    if d.kind=="dock"then local now=owner_alive()and B.now(api)or nil;s.dock_click_block_until=now and now+150 or nil end
    if s.cache[d.root]then s.cache[d.root].parent=nil end
    if commit and owner_alive()and s.visible then
      local read,x,y=B.offset(api,d.root,owner_alive)
      if read then
        if d.kind=="tour"then s.tour_position={x=x,y=y}
        elseif d.kind=="priority"then s.controller.setPriorityPosition(x,y)
        elseif d.kind=="dock"then s.controller.setDockPosition(x,y)
        else s.controller.setAlertPosition(x,y)end
      end
    end
    if commit and d.resume and owner_alive()and s.visible and not s.settings_open then s.hover_enabled=s.hover.arm()==true end
    if d.kind~="tour"then rebuild_pick_geometry()end
    return true
  end
  function s.begin_aux_drag(root,kind)
    if not owner_alive()or not s.visible or s.aux_drag then return end
    if kind=="tour"then
      if not s.settings_open or not s.tour_step or s.tour_practice_drag or not s.cache[root]or not s.cache[root].Show then return end
    else
      local yes,shift=call(B.member(api,"Input"),"IsShiftKeyDown")
      if not yes or shift~=true then return end
    end
    local resume=s.hover.armed==true
    if kind~="tour"then cancel_input()end
    if not owner_alive()or not s.visible or s.aux_drag then return end
    if kind~="tour"then s.drag_click_block=true end
    if kind=="dock"then s.dock_click_block=true end
    s.aux_drag={root=root,kind=kind,resume=resume}
    local moved,value=call(root,"StartMoving")
    if not moved or value==false then s.end_aux_drag(false)end
  end
  local function bind_aux(handle,root,kind)
    local ok,v=call(handle,"EnableDrag",true);if not ok or v==false then return false end
    call(handle,"EnablePick",true);call(handle,"Clickable",true)
    local function start()s.begin_aux_drag(root,kind)end
    local function stop()if s.aux_drag and s.aux_drag.root==root then if not s.end_aux_drag(true)then s.fault();return end;s.refresh();s.hover.block(s.last_hover_key)end end
    for _,entry in ipairs({{"OnDragStart",start},{"OnDragStop",stop},{"OnDragEnd",stop},{"OnMouseUp",stop}})do replace_handler(handle,entry[1],entry[2])end
    return true
  end
  function s.end_settings_drag(commit)
    if not s.settings_moving then return true end
    if s.stopping_settings_drag then return false end
    s.stopping_settings_drag=true
    local ok,value=call(s.options,"StopMovingOrSizing")
    s.stopping_settings_drag=false
    if not ok or value==false then return false end
    s.settings_moving=false
    if s.cache[s.options]then s.cache[s.options].parent=nil end
    for _,o in pairs(s.buttons)do if s.cache[o]then s.cache[o].parent=nil end end
    if s.settings_header and s.cache[s.settings_header]then s.cache[s.settings_header].parent=nil end
    if commit and owner_alive()and s.studio then
      local read,x,y=B.offset(api,s.options,owner_alive)
      if read and B.finite(x)and B.finite(y)and type(s.studio.move)=="function"then s.studio.move(x,y)end
    end
    return true
  end
  local function cancel_reset()
    if s.reset_pending then
      s.controller.cancelReset();s.reset_pending=false
      if s.studio and owner_alive()then s.studio.restoreDrafts(s.reset_drafts)end
      s.reset_drafts=nil;rebuild_pick_geometry()
    end
  end
  local function colour_read(target)
    local o=s.controller.config.options
    if target.kind=="palette"then return o.colours[target.key]end
    if target.kind=="class"then return o.colours.classes[target.name]or o.colours.neutral end
    if target.kind=="dps"then return Colours.dpsColour(o.colours,target.key)end
    if target.kind=="health_style"then return Colours.healthColour(o.colours,target.key)end
    for _,id in ipairs(target.members or{target.id})do
      local rule=o.auras.frame_rules[id];if rule then return rule.colour end
    end
  end
  local function colour_anchor(p)
    return p and s.controller.config==p.config and s.controller.config.options==p.options
      and(p.target.kind=="rule"and p.options.auras==p.anchor or p.target.kind~="rule"and p.options.colours==p.anchor)
  end
  local function picker_current(p)
    return p and s.colour_picker==p and owner_alive()and s.visible and s.settings_open and not s.dragging and not s.settings_moving
      and not s.reset_pending and s.studio==p.studio and s.studio.page==p.page and s.studio.section==p.section
      and colour_anchor(p)and colour_read(p.target)==p.hex and(p.target.kind~="rule"or s.rule_id==p.target.id)
  end
  local function colour_write(p,hex,rollback)
    if not colour_anchor(p)then return false end
    local o=p.options;local t=p.target
    if t.kind=="palette"then o.colours[t.key]=hex
    elseif t.kind=="dps"then if rollback then o.colours.dps[t.key]=p.originalOverride else o.colours.dps[t.key]=hex end
    elseif t.kind=="class"then if rollback then o.colours.classes[t.name]=p.originalOverride else o.colours.classes[t.name]=hex end
    elseif t.kind=="health_style"then if rollback then o.colours.health_styles[t.key]=p.originalOverride else o.colours.health_styles[t.key]=hex end
    else
      local nextValue
      if rollback then
        nextValue=Watch.validate(o.auras)
        for _,id in ipairs(t.members)do
          nextValue.frame_rules[id]=p.originalRules[id]and Preferences.copy(p.originalRules[id])or nil
          nextValue.debuff_colours[id]=p.originalLegacy[id]or nil
        end
        nextValue=Watch.validate(nextValue)
      else
        local r
        for _,id in ipairs(t.members)do if o.auras.frame_rules[id]then r=Watch.rule(o.auras,id);break end end
        if not r then return false end
        r.colour=hex;nextValue=Watch.setMany(o.auras,t.members,"rule",r)
      end
      if not nextValue then return false end
      o.auras=nextValue;p.anchor=nextValue
    end
    s.controller.revision=s.controller.revision+1;return true
  end
  local function cancel_colour()
    local p=s.colour_picker;if not p then return end
    s.colour_picker=nil;p.drag=nil
    if colour_anchor(p)and colour_read(p.target)==p.hex then colour_write(p,p.original,true)end
    if p.studio then p.studio.finishColourDraft(p.field,p.draft,false)end
  end
  local function picker_preview(p,h,sat,value)
    if not picker_current(p)then return false end
    local hex=Picker.hex(h,sat,value);if not hex then return false end
    if hex~=p.hex and not colour_write(p,hex,false)then return false end
    p.h=h;p.s=sat;p.v=value;p.hex=hex;return true
  end
  function s.open_colour(field,binding,label)
    if not owner_alive()or not s.visible or not s.settings_open or s.dragging or s.settings_moving or s.reset_pending then return false end
    cancel_colour()
    local o=s.controller.config.options;local target
    if field:sub(1,7)=="colour_"and type(o.colours[field:sub(8)])=="string"then target={kind="palette",key=field:sub(8)}
    elseif field:sub(1,14)=="health_colour_"and({outline=true,badge=true,hatch=true,fill=true})[field:sub(15)]then target={kind="health_style",key=field:sub(15)}
    elseif field=="dps_colour_"..(binding or"")and(binding=="mage"or binding=="ranged"or binding=="melee")then target={kind="dps",key=binding}
    elseif field:match("^class_colour_%d+$")and Colours.className(binding)then
      local count=0;for _ in pairs(o.colours.classes)do count=count+1 end
      if o.colours.classes[binding]==nil and count>=Colours.MAX_CLASSES then s.studio_notice="Up to 64 class colour overrides can be stored.";return false end
      target={kind="class",name=binding}
    elseif field=="rule_colour"and Watch.id(binding)==s.rule_id then
      local group=s.effectLibrary.group(s.rule_id,o.auras)
      if group and group.rule then target={kind="rule",id=s.rule_id,members=group.members}end
    end
    if not target then return false end
    local studio,config,page,section,epoch=s.studio,s.controller.config,s.studio.page,s.studio.section,s.input_epoch
    local function same()
      return owner_alive()and s.visible and s.settings_open and not s.colour_picker and not s.reset_pending
        and s.studio==studio and s.controller.config==config and config.options==o and s.input_epoch==epoch and studio.page==page and studio.section==section
    end
    local original=colour_read(target);local h,sat,value=Picker.fromHex(original)
    if h==nil then return false end
    local draft=studio.colourDraft(field,same);if not same()or type(draft)~="table"then return false end
    cancel_input();show(s.settings_tip,false)
    if not owner_alive()or not s.visible or not s.settings_open or s.settings_moving or s.dragging or s.reset_pending or s.colour_picker
      or s.studio~=studio or s.controller.config~=config or config.options~=o or s.input_epoch~=epoch+1
      or studio.page~=page or studio.section~=section then return false end
    s.colour_picker={ticket={},target=target,field=field,label=label or"Choose a colour",original=original,hex=original,h=h,s=sat,v=value,
      originalOverride=target.kind=="class"and o.colours.classes[target.name]or(target.kind=="dps"and o.colours.dps[target.key]or(target.kind=="health_style"and o.colours.health_styles[target.key]or nil)),config=config,options=o,
      anchor=target.kind=="rule"and o.auras or o.colours,studio=studio,page=page,section=section,draft=draft}
    if target.kind=="rule"then
      local p=s.colour_picker;p.originalRules={};p.originalLegacy={}
      for _,id in ipairs(target.members)do
        p.originalRules[id]=Watch.rule(o.auras,id)or false
        p.originalLegacy[id]=o.auras.debuff_colours[id]or false
      end
    end
    return true
  end
  function s.picker_point(ticket,kind,continuing)
    local p=s.colour_picker;if not p or p.ticket~=ticket or not picker_current(p)then return false end
    local geometry=s.studio.picker_geometry;local g=geometry and geometry[kind]
    if not g then return false end
    local good,x,y=B.mouse(api,function()return picker_current(p)end)
    if not good or not picker_current(p)then return false end
    if kind=="wheel"then
      local h,sat=Picker.wheel(x,y,g.cx,g.cy,g.r)
      if h==nil and continuing and p.drag==kind then
        local dx,dy=x-g.cx,y-g.cy;local length=math.sqrt(dx*dx+dy*dy)
        if B.finite(length)and length>0 then
          h,sat=Picker.wheel(g.cx+dx*g.r*0.999999/length,g.cy+dy*g.r*0.999999/length,g.cx,g.cy,g.r)
          if h~=nil then sat=1 end
        end
      end
      return h~=nil and picker_preview(p,h,sat,p.v)or false
    end
    if not continuing and not contains(g,x,y)then return false end
    local value=Picker.value(y,g.y,g.h);return value~=nil and picker_preview(p,p.h,p.s,value)or false
  end
  function s.apply_edit(id,value)
    if not owner_alive()or not s.visible or not s.settings_open or s.reset_pending or s.alert_warning then return false end
    if s.colour_picker then
      if id~="picker_hex"then return false end
      local h,sat,v=Picker.fromHex(Colours.hex(value));return h~=nil and picker_preview(s.colour_picker,h,sat,v)or false
    end
    if id=="effect_search"then
      if s.studio.page=="effects" and s.studio.effectSection=="icons" and not s.rule_id then
        local query=type(value)=="string"and value:sub(1,48)or""
        if query~=s.effect_query then s.effect_query=query;s.studio.section=1 end
      end
      return
    end
    local changed=false;local o=s.controller.config.options
    if id=="frame_width"or id=="frame_height"then
      local width=id=="frame_width";local n=whole_pixels(value,width and C.MIN_WIDTH or C.MIN_HEIGHT,width and C.MAX_WIDTH or C.MAX_HEIGHT)
      if n then changed=s.controller.setDimension(width and"width"or"height",n)end
    elseif id=="spacing"then local n=whole_pixels(value,0,24);if n then changed=s.controller.setSpacing(n)end
    elseif id=="icon_size"or id=="icon_spacing"or id=="icon_count"or id=="icon_timer"then
      local key=({icon_size="size",icon_spacing="spacing",icon_count="max_visible",icon_timer="timer_size"})[id]
      local bounds=({icon_size={0,32},icon_spacing={0,12},icon_count={1,6},icon_timer={8,16}})[id]
      local n=whole_pixels(value,bounds[1],bounds[2])
      if n and(id~="icon_size"or n==0 or n>=16)then changed=s.controller.setOption("aura_icons",key,n)end
    elseif id=="health_threshold"or id=="mana_threshold"then
      local n=whole_pixels(value,1,99);if n then changed=s.controller.setOption("indicators",id,n)end
    elseif id=="range_alpha"or id=="opacity"then
      local n=whole_pixels(value,15,100)
      if n then changed=s.controller.setOption(id=="opacity"and"appearance"or"range",id=="opacity"and"opacity"or"alpha",n/100)end
    elseif id=="hatch_opacity"then
      local n=whole_pixels(value,10,100);if n then changed=s.controller.setOption("indicators","hatch_opacity",n/100)end
    elseif id:sub(1,14)=="health_colour_"then
      local key=id:sub(15);local hex=Colours.hex(value)
      if hex and({outline=true,badge=true,hatch=true,fill=true})[key]then
        local map=Preferences.copy(o.colours.health_styles);if map then map[key]=hex;changed=s.controller.setOption("colours","health_styles",map)end
      end
    elseif id:sub(1,7)=="colour_"then
      local hex=Colours.hex(value);if hex then changed=s.controller.setOption("colours",id:sub(8),hex)end
    elseif id:match("^dps_colour_")then
      local family=id:sub(12);local e=s.studio.edits[id];local hex=Colours.hex(value)
      if e and e.visible and e.binding==family and hex then changed=s.controller.setDpsColour(family,hex)end
    elseif id:match("^class_colour_%d+$")then
      local index=whole_pixels(id:match("(%d+)$"),1,#(s.class_names or{}));local name=index and s.class_names[index]
      local edit=s.studio.edits[id];local hex=Colours.hex(value)
      if name and hex and edit and edit.visible and edit.binding==name then changed=s.controller.setClassColour(name,hex)end
    elseif id=="rule_colour"then
      local editor=s.studio.edits.rule_colour
      local group=editor and editor.visible and editor.binding==s.rule_id and s.effectLibrary.group(s.rule_id,o.auras)
      local r=group and group.rule
      local hex=Colours.hex(value)
      if r and r.enabled and hex then r.colour=hex;local nextValue=Watch.setMany(o.auras,group.members,"rule",r)
        if nextValue then o.auras=nextValue;s.controller.revision=s.controller.revision+1;changed=true end
      end
    end
    if changed then cancel_input();rebuild_pick_geometry()end
    return changed==true
  end
  local function editor_blocks_click()
    if s.text_drag then return true end
    local releaseUntil=s.text_editor_release_until or 0
    if releaseUntil<=0 then return false end
    local now=B.now(api)
    if now and now<=releaseUntil then return true end
    s.text_editor_release_until=nil
    return false
  end
  local function commit_effect_choices(changed,limit)
    if not changed then s.studio_notice=limit;return false end
    s.controller.config.options.auras=changed
    s.controller.revision=s.controller.revision+1
    s.studio_notice="Save settings to keep your effect choices."
    return true
  end
  local function share_current(session)
    return owner_alive()and s.visible and s.settings_open and s.studio.page=="profiles"
      and s.profile_share==session and not s.reset_pending and not s.colour_picker
  end
  local function preview_shared(session,code)
    local profile,mode=ProfileShare.decode(code)
    if not share_current(session)then return end
    session.wait=nil
    if profile then
      session.kind="preview";session.profile=profile;session.mode=mode;session.status=nil
    else session.status=mode end
  end
  function s.receive_profile_chat(channel,sender,message)
    local session=s.profile_share;local wait=session and session.wait
    if not wait or not share_current(session)or channel~=s.profile_whisper_channel
      or type(sender)~="string"or #sender>48 or sender:lower()~=wait.sender then return end
    local now=B.now(api)
    if not share_current(session)or session.wait~=wait then return end
    if not now or now>=wait.deadline then
      session.wait=nil;session.status="Listening timed out. Start again or paste a code."
    else
      local code,status=ProfileShare.acceptPart(wait,message)
      if code then preview_shared(session,code)
      elseif status then session.status=status
      else return end
    end
    s.refresh()
  end
  local function profile_share_action(action,key)
    if not owner_alive()or not s.visible or not s.settings_open or s.studio.page~="profiles"then return end
    local cfg=s.controller.config
    local session=s.profile_share
    if action=="profile_receive"then
      s.delete_pending=nil;s.profile_share={kind="receive",status="Enter your friend's character name to listen."}
    elseif action:sub(1,14)=="profile_share_"then
      local profile=key and cfg.profiles[key]
      if profile then
        s.delete_pending=nil
        s.profile_share={kind="export",name=key,profile=profile,mode="L",part=1}
        session=s.profile_share
      end
    elseif not session or not share_current(session)then return
    elseif action=="share_back"then s.profile_share=nil
    elseif action=="share_layout"or action=="share_full"then
      session.mode=action=="share_layout"and"L"or"F";session.part=1
    elseif action=="share_parts"then session.direct=not session.direct
    elseif action=="share_part_next"then session.part=math.min(#session.parts,session.part+1)
    elseif action=="share_part_previous"then session.part=math.max(1,session.part-1)
    elseif action=="share_listen"then
      if session.wait then session.wait=nil;session.status="Listening stopped."
      else
        local sender=s.studio.shareValue("sender")
        if not share_current(session)then return end
        sender=type(sender)=="string"and #sender<=64 and sender:match("^%s*(.-)%s*$")or""
        if sender==""or #sender>48 or sender:find("[%c|]")then session.status="Enter your friend's character name."
        else
          local now=B.now(api)
          if not share_current(session)then return end
          local channel=B.member(CHAT_MESSAGE_FILTERS,"WHISPER")
          if not s.profile_chat_ready and s.profile_chat_attached and type(channel)=="number"then
            local ok,value=call(s.driver,"RegisterEvent","CHAT_MESSAGE")
            if not share_current(session)then return end
            s.profile_chat_ready=ok and value~=false
          end
          if s.profile_chat_ready and now and type(channel)=="number"then
            s.profile_whisper_channel=channel
            session.wait={sender=sender:lower(),parts={},count=0,deadline=now+120000}
            session.status="Listening for a whisper from "..sender.."."
          else session.status="Whisper reception is unavailable. Paste the code below."end
        end
      end
    elseif action=="share_paste"then
      local code=s.studio.shareValue("code")
      if not share_current(session)then return end
      preview_shared(session,code)
    elseif action=="share_save"and session.kind=="preview"then
      if session.saving then return end
      local name=Preferences.profileName(s.studio.shareValue("name"))
      if not share_current(session)then return end
      if not name then session.status="Enter a profile name of 1–24 characters."
      elseif cfg.profiles[name]then session.status="That name already exists. Choose a new one."
      elseif #s.controller.profileNames()>=Preferences.MAX_PROFILES then session.status="Eight profiles are stored. Delete one to make room."
      else
        session.saving=true
        local function stillOwned()return owner_alive()and s.controller.config==cfg end
        local function current()return stillOwned()and share_current(session)and not cfg.profiles[name]end
        local ok,reason=s.storage.saveNewProfile(name,session.profile,current,stillOwned)
        session.saving=false
        if ok and stillOwned()then
          cfg.profiles[name]=session.profile
          s.controller.revision=s.controller.revision+1
          s.controller.profile_status="Imported "..name..". Click its card to load it."
          if s.profile_share==session then s.profile_share=nil end
        elseif share_current(session)then session.status=reason or"Profile import could not be saved."end
      end
    else return end
    if s.profile_share and s.profile_share.kind=="export"then
      local export=s.profile_share
      if export.encodedMode~=export.mode then
        export.code=ProfileShare.encode(export.profile,export.mode)
        export.parts=export.code and ProfileShare.parts(export.code)
        export.direct=not export.parts;export.encodedMode=export.mode
      end
    end
    if owner_alive()and s.visible then s.refresh()end
  end
  local function profile_switch(action,key)
    local pending=s.profile_load
    if not pending or key~=pending.name or pending.saving then return end
    local c=s.controller;local cfg=c.config
    local function owned()return owner_alive()and c.config==cfg end
    local function current()
      return owned()and s.visible and s.settings_open and s.studio.page=="profiles"
        and s.profile_load==pending and cfg.profiles[key]==pending.target
    end
    if not current()then return end
    if action=="profile_switch_cancel"then s.profile_load=nil;s.refresh();return end
    local revision=c.revision
    if action=="profile_switch_save"then
      local name=pending.backup
      local snapshot=name and not cfg.profiles[name]and c.profileSnapshot()
      if not snapshot then pending.status="Could not make a backup. Your current settings are still active.";s.refresh();return end
      pending.saving=true
      local function canWrite()return current()and c.revision==revision and not cfg.profiles[name]end
      local ok,reason=s.storage.saveNewProfile(name,snapshot,canWrite,owned)
      pending.saving=false
      if ok and owned()then
        cfg.profiles[name]=snapshot;pending.savedBackup=name;pending.backup=nil
      end
      if not current()then return end
      if not ok or c.revision~=revision then
        pending.status=ok and"Backup saved. Your setup changed during saving, so it is still active."
          or reason or"Could not save your current setup."
        s.refresh();return
      end
    elseif action~="profile_switch_discard"then return end
    cancel_input()
    if not current()then return end
    if action=="profile_switch_save"and c.revision~=revision then
      pending.status="Backup saved. Your setup changed during saving, so it is still active.";s.refresh();return
    end
    if c.loadProfile(key)then
      s.profile_load=nil;s.profile_name=key;s.auraModel.clear();s.last_aura=nil
      s.studio.setName(key);s.studio.clearDrafts();s.dimensions_notice=nil
      if pending.savedBackup then
        c.profile_status="Previous setup saved as "..pending.savedBackup..". Loaded "..key.."."
      end
    else pending.status=c.profile_status end
    s.refresh()
  end
  local function perform(name,profileKey)
    -- Legacy controller preview support remains available to offline callers;
    -- the settings UI now owns a separate, non-interactive local example.
    if name=="mode"or name=="count"or name=="click_target"or name=="native_name_refresh"then return end
    if editor_blocks_click()then return end
    local resumeHud=name=="hud_sort"and(s.hover_enabled or s.hover.armed)
    local resumeReturn=name=="return_target"and(s.hover_enabled or s.hover.armed)
    local wasManagerOpen=s.manager_menu_open==true
    if not owner_alive()or not s.visible or s.dragging or s.aux_drag then return end
    if name=="hud_hover"then name="hover"end
    if name=="manager_shortcut"then
      local resume=s.hover_enabled or s.hover.armed
      cancel_input();s.hover_enabled=resume;s.manager_menu_open=not wasManagerOpen
      if wasManagerOpen and resume then s.hover_enabled=s.hover.arm()==true end
      s.refresh();return
    end
    if not owner_alive() or not s.visible or s.dragging or s.aux_drag then return end
    if not s.end_settings_drag(true)then return end
    local colourPicker=s.colour_picker
    if colourPicker then
      if name:sub(1,7)=="picker_"then
        if profileKey~=colourPicker.ticket or not picker_current(colourPicker)then return end
        if name=="picker_cancel"then cancel_colour()
        elseif name=="picker_use"then
          local epoch=s.input_epoch
          local function current()return picker_current(colourPicker)and s.input_epoch==epoch end
          local read,draft=colourPicker.studio.pickerDraft(colourPicker.ticket,current)
          if not read or not current()then return end
          if draft~=nil then
            local h,sat,value=Picker.fromHex(Colours.hex(draft))
            if h~=nil and not picker_preview(colourPicker,h,sat,value)then return end
          end
          if not current()then return end
          if colourPicker.target.kind=="class"and colourPicker.options.colours.classes[colourPicker.target.name]==nil then colour_write(colourPicker,colourPicker.hex,false)end
          s.colour_picker=nil;colourPicker.drag=nil;colourPicker.studio.finishColourDraft(colourPicker.field,colourPicker.draft,true)
        elseif name=="picker_white"then picker_preview(colourPicker,0,0,1)
        elseif name=="picker_black"then picker_preview(colourPicker,colourPicker.h,colourPicker.s,0)end
        s.refresh();return
      elseif name=="save"then return
      else cancel_colour()end
    elseif name:sub(1,7)=="picker_"then return end
    if s.reset_pending then
      if name=="reset_accept"then s.controller.acceptReset();s.reset_pending=false;s.reset_drafts=nil;rebuild_pick_geometry();s.refresh();return
      elseif name=="reset_cancel"then cancel_reset();s.refresh();return
      elseif name=="close"or name=="cog"then cancel_reset()
      else return end
    end
    if s.alert_warning then
      if name=="alert_warning_ok"and profileKey==s.alert_warning.id then s.alert_warning=nil;s.refresh();return end
      if name=="close"or name=="cog"then s.alert_warning=nil else return end
    end
    if s.profile_load then
      if name:sub(1,15)=="profile_switch_"then profile_switch(name,profileKey);return end
      if name=="close"or name=="cog"then s.profile_load=nil else return end
    end
    if name:match("^profile_load_%d+$")then
      local cfg=s.controller.config
      local target=profileKey and cfg.profiles[profileKey]
      if not target or not s.settings_open or s.studio.page~="profiles"or s.profile_share then return end
      local backup
      if #s.controller.profileNames()<Preferences.MAX_PROFILES then
        backup="Before profile load"
        local i=2
        while cfg.profiles[backup]do backup="Before profile load "..i;i=i+1 end
      end
      s.delete_pending=nil
      s.profile_load={name=profileKey,target=target,backup=backup}
      s.refresh();return
    end
    if name=="profile_receive"or name:sub(1,14)=="profile_share_"or name:sub(1,6)=="share_"then
      profile_share_action(name,profileKey);return
    end
    if name=="known_issues"then
      s.stop_tour();s.ordering_menu=nil;s.delete_pending=nil
      s.studio.select("known_issues");s.refresh();return
    end
    if s.studio.page=="known_issues"then
      if name=="studio_more"then s.studio.more();s.refresh();return end
      if name=="previous"or name=="next"then s.studio.stepPage(name=="next"and 1 or -1);s.refresh();return end
      if name:sub(1,4)=="tab_"then s.studio.select(name:sub(5));s.refresh();return end
    end
    if name=="quick_tour"or name:sub(1,5)=="tour_"then
      s.step_tour(name);s.refresh();return
    end
    if name=="raid_aura_member"then
      local rows=s.raid_check_rows or{}
      s.raid_check_index=#rows>0 and((s.raid_check_index or 1)%#rows+1)or 1
      s.raid_check_selected=rows[s.raid_check_index];s.refresh();return
    end
    if name=="raid_aura_run"then
      local check=B.member(nativeControls,"raidAuraCheck");local row=s.raid_check_selected
      if not row or not check or type(check.capture)~="function"then return end
      cancel_input()
      local epoch=s.input_epoch
      local function active()return owner_alive()and s.visible and s.settings_open and s.input_epoch==epoch end
      if not active()then return end
      local subject={token=row.token,identity=row.identity}
      local _,started=check.capture(row.token,row.identity,active)
      if started==true and owner_alive()then s.raid_check_subject=subject end
      s.refresh();return
    end
    if name=="hud_reset"then
      local resume=s.hover_enabled or s.hover.armed
      cancel_input();s.hover_enabled=resume;s.settings_open=true;s.manager_menu_open=false
      s.studio.select("layout");s.studio.section=1
      if not s.refresh()or not owner_alive()or not s.visible or not s.settings_open then return end
    end
    if name=="reset_layout"or name=="hud_reset"then
      local resetOrder=name=="hud_reset"
      local studio,config,epoch,page,section=s.studio,s.controller.config,s.input_epoch,s.studio.page,s.studio.section
      local function same_settings()
        return owner_alive()and s.visible and s.settings_open and not s.reset_pending
          and s.studio==studio and s.controller.config==config and s.input_epoch==epoch
          and studio.page==page and studio.section==section
      end
      local drafts=studio.captureDrafts(same_settings)
      if not same_settings()or type(drafts)~="table"then return end
      if s.controller.beginReset(resetOrder)then
        local resume=s.hover_enabled or s.hover.armed
        s.reset_drafts=drafts;cancel_input();s.hover_enabled=resume
        s.reset_pending=resetOrder and"member_order"or true
        if not resetOrder then studio.clearDrafts()end
        rebuild_pick_geometry()
      end
      s.refresh();return
    end
    if name=="target_trace_save"then save_trace();s.refresh();return end
    if name=="target_trace"then
      local _,active=trace_call("isActive")
      if active then
        trace_call("stop","manual");local _,capture=trace_call("captureId");s.trace_auto_attempt=capture;save_trace()
      elseif trace and(s.hover.armed or(s.settings_open and s.hover_enabled))then
        local now=B.now(api);if not owner_alive()or not s.visible then return end
        local ok,started=trace_call("start",now)
        if ok and started then
          cancel_input();s.settings_open=false;s.trace_entry=0;s.trace_save_notice=nil;s.trace_saved_capture=nil;s.trace_auto_attempt=nil
          s.hover_enabled=s.hover.arm()==true
          trace_record("SELECTED",{actual=s.selected_identity,stable=I.accepts(s.selected_identity),result=I.accepts(s.selected_identity)and"OBSERVED"or"UNKNOWN"})
          local _,nameOn=feedback_call("nameRefreshEnabled")
          trace_record("DECISION",{result=nameOn==true and"NAME_REFRESH_ON"or"NAME_REFRESH_OFF"})
          if not s.hover_enabled then trace_call("stop","stopped");s.trace_save_notice="Hover is unavailable; capture stopped."end
        else s.trace_save_notice="Save the previous capture before recording again."end
      else s.trace_save_notice="Enable hover targeting before recording."end
      s.refresh();return
    end
    if name=="close" or name=="cog" or name=="compact" then
      local enabled=s.settings_open and s.hover_enabled or s.hover.armed
      cancel_input();s.delete_pending=nil;s.settings_open=name~="close" and not s.settings_open or false
      if enabled then
        if s.settings_open then s.hover_enabled=true
        else s.hover_enabled=s.hover.arm()==true end
      end
      s.refresh();return
    end
    if name=="hover" then
      if s.hover_enabled or s.hover.armed then
        if s.remember_controls then remember_control({hover=false})end
        cancel_input()
      else
        cancel_input();s.settings_open=false;s.hover_enabled=s.hover.arm()==true
        if s.remember_controls and s.hover_enabled then remember_control({hover=true})end
      end
      s.refresh();return
    end
    if name=="preview_count"or name=="preview_previous"or name=="preview_next"then
      if not owner_alive()or not s.visible or not s.settings_open or not s.studio or s.studio.page~="appearance"
        or s.settings_moving or s.dragging or s.colour_picker or s.reset_pending or not s.last_plan then return end
      -- This is a settings example, separate from the live raid controller.
      -- Redraw just the studio: no input cancellation, unit/aura sampling or
      -- actual raid-page change is needed to browse invented examples.
      local studio=s.studio
      if name=="preview_count"then studio.previewCount=cycle(studio.previewCount or 5,{5,25,50});studio.previewPage=1
      else
        local page=studio.previewPage or 1;local pages=studio.previewPages or 1
        studio.previewPage=math.max(1,math.min(pages,page+(name=="preview_next"and 1 or -1)))
      end
      local w,h=B.extent(api);s.refresh_options(s.last_plan,w,h);return
    end
    if name=="icon_editor_previous"or name=="icon_editor_next"then
      if s.studio.page~="effects"or s.studio.effectSection~="layout"then return end
      local page=s.studio.iconEditorPage or 1
      s.studio.iconEditorPage=math.max(1,math.min(s.studio.iconEditorPages or 1,page+(name=="icon_editor_next"and 1 or -1)))
      local w,h=B.extent(api);s.refresh_options(s.last_plan,w,h);return
    end
    if name=="text_reset_positions"then
      if not s.studio then return end
      local page=s.studio.page
      if page~="appearance"and not(page=="effects"and s.studio.effectSection=="layout")then return end
      cancel_input()
      if s.controller.setOption("text_positions","name",{})then
        s.controller.setOption("text_positions","health",{});s.controller.setOption("text_positions","distance",{})
      end
      local w,h=B.extent(api);s.refresh_options(s.last_plan,w,h);return
    end
    cancel_input()
    if not owner_alive()or not s.visible then return end
    local deleteIndex=whole_pixels(string.match(name,"^profile_delete_(%d+)$"),1,Preferences.MAX_PROFILES)
    if not deleteIndex and name~="profile_confirm_delete"and name~="profile_cancel_delete"then s.delete_pending=nil end
    if name~="dimensions_apply"and name:sub(1,6)~="frame_"then s.dimensions_notice=nil end
    if name:sub(1,4)=="tab_" then
      s.studio.select(name:sub(5));s.delete_pending=nil
    elseif name:sub(1,9)=="ordering_"then
      if s.studio.page~="ordering"then return end
      local rules=Ordering.validate(s.controller.config.options.member_layout.ordering)
      if not rules then return end
      if name=="ordering_slots"then s.studio.orderingPart="slots";s.studio.section=1
      elseif name=="ordering_enabled"then
        rules.enabled=not(rules.enabled and s.controller.config.options.member_layout.enabled);s.controller.setOrdering(rules);rebuild_pick_geometry()
      else return end
    elseif name=="move_raid_alert"then
      s.alert_move_active=not s.alert_move_active
      if s.alert_move_active then s.settings_open=false end
      cancel_input()
    elseif name=="return_target"then
      s.controller.setOption("input","return_target",not s.controller.config.options.input.return_target)
      if returnTarget then returnTarget.cancel()end
      if resumeReturn and owner_alive()and s.visible then
        s.hover_enabled=true
        if not s.settings_open then s.hover_enabled=s.hover.arm()==true end
      end
      s.studio_notice="Return to the previous raid target when your mouse leaves the frames."
    elseif name=="raid_scan_policy"then
      s.controller.setOption("auras","scan_policy",s.controller.config.options.auras.scan_policy=="balanced"and"debuff_priority"or"balanced")
      s.studio_notice="Debuff priority checks debuffs more often and buffs less often."
    elseif name=="raid_tracker"or name=="large_alerts"then
      local on=not s.controller.config.options.auras[name]
      s.controller.setOption("auras",name,on)
      if not on then s.raidAlerts.clearVisible()end
      if name=="large_alerts"then
        s.studio_notice=on and "Screen alerts enabled. Save settings to keep this choice."
          or "Screen alerts paused. Save settings to keep this choice."
      else
        s.studio_notice="Some effects may be missed or delayed."
      end
    elseif name=="reset_raid_alerts"then
      s.raidAlerts.reset();if raidTracker then raidTracker.reset()end
      s.studio_notice="Alert history reset. Previously detected effects can alert again."
    elseif name=="appearance_design"or name=="appearance_colours"then
      s.studio.appearanceSection=name=="appearance_colours"and"colours"or"design"
      s.studio.section=1
    elseif name=="effects_icons"or name=="effects_layout"or name=="effects_tracker"then
      s.studio.effectSection=name=="effects_layout"and"layout"or name=="effects_tracker"and"tracker"or"icons"
      s.rule_id=nil;s.studio.materialsOpen=false;s.studio.section=1
    elseif name=="effect_browse"or name=="effect_my"then
      s.effect_scope=name=="effect_my"and"mine"or"browse"
      s.studio.section=1
    elseif name=="effect_tracker_settings"then
      s.studio.select("layout")
    elseif name=="effect_resume_alerts"then
      local id=Watch.id(profileKey)
      local auras=s.controller.config.options.auras
      if not id or id~=s.rule_id or auras.alerts[id]~=true then return end
      s.controller.setOption("auras","large_alerts",true)
      s.studio_notice="Screen alerts enabled. Save settings to keep this choice."
    elseif name:match("^effect_open_%d+$")then
      local id=Watch.id(profileKey)
      if not id or s.rule_id or s.studio.effectSection~="icons"then return end
      s.effect_list_page=s.studio.section
      s.rule_id=id;s.studio.section=1;s.studio.materialsOpen=false
    elseif name=="rule_back"then
      s.rule_id=nil;s.studio.section=s.effect_list_page or 1;s.studio.materialsOpen=false
    elseif name=="material_back"then
      if Watch.id(profileKey)~=s.rule_id then return end
      s.studio.materialsOpen=false;s.studio.section=s.effect_detail_page or 1
    elseif name:sub(1,16)=="material_choice_"then
      if Watch.id(profileKey)~=s.rule_id or not s.studio.materialsOpen then return end
      local material=name:sub(17)
      local a=s.controller.config.options.auras
      local group=s.effectLibrary.group(s.rule_id,a)
      local r=group and group.rule
      if not r or not r.enabled or not Materials.accepts(material)then return end
      r.material=material;r.colour=Materials.defaultColour(material)
      commit_effect_choices(Watch.setMany(a,group.members,"rule",r),"Too many spell versions selected. Remove another effect first.")
      s.studio.materialsOpen=false;s.studio.section=s.effect_detail_page or 1
    elseif name=="effect_watch_detail"or name=="effect_alert_detail"or name=="effect_priority_detail"or name:sub(1,5)=="rule_"then
      local id=Watch.id(profileKey)
      if not id or id~=s.rule_id or s.studio.effectSection~="icons"then return end
      local a=s.controller.config.options.auras
      local group=s.effectLibrary.group(id,a);if not group then return end
      if name=="effect_watch_detail"then
        commit_effect_choices(Watch.setMany(a,group.members,"icon",not group.selected),"Too many spell versions selected. Remove another effect first.")
      elseif name=="effect_alert_detail"then
        local enabled=not group.alertSelected
        local effect=enabled and group
        if enabled and effect and effect.kindCode~="debuff"and effect.kindCode~="both"then
          s.alert_warning={id=id,message=effect.kindCode=="buff"
            and(P.text(effect.name,48).." is a buff.\nScreen alerts work with detected debuffs.\nThis alert is now off.")
            or"This effect has not been identified as a debuff yet.\nSelect a raid member with it, then try again.\nThis alert is now off."}
        else
          commit_effect_choices(Watch.setMany(a,group.members,"alert",enabled),"Too many spell versions selected. Remove another effect first.")
        end
      elseif name=="effect_priority_detail"then
        local level=group.selected and(Watch.priority(a,id)+1)%3 or nil
        if level~=nil then commit_effect_choices(Watch.setMany(a,group.members,"priority",level),"Icon priority could not be changed.")end
      else
        local r=group.rule
        if name=="rule_enabled"then
          if r then r.enabled=not r.enabled
          else
            local effect=s.effectLibrary.rows("browse",id,a)[1]
            local kind=effect and effect.kindCode
            if kind~="buff"and kind~="debuff"then kind="any"end
            r={kind=kind,material="tint",colour=Materials.defaultColour("tint"),priority=0,enabled=true}
          end
          commit_effect_choices(Watch.setMany(a,group.members,"rule",r),"Too many spell versions selected. Remove another effect first.")
        elseif name=="rule_remove"and r then
          commit_effect_choices(Watch.setMany(a,group.members,"rule",false),"Frame appearance could not be removed.")
        elseif r and r.enabled then
          if name=="rule_material"then
            s.effect_detail_page=s.studio.section
            s.studio.materialsOpen=true;s.studio.section=1;s.refresh();return
          elseif name=="rule_kind"then
            r.kind=cycle(r.kind,{"debuff","buff","any"})
          elseif name=="rule_priority"then
            r.priority=(r.priority+1)%3
          else return end
          commit_effect_choices(Watch.setMany(a,group.members,"rule",r),"Frame appearance could not be changed.")
        end
      end
    elseif name=="addon_frames"or name=="hud_addon"then
      s.controller.config.visibility.frames=not s.controller.config.visibility.frames
      s.controller.revision=s.controller.revision+1
    elseif name=="hud_sort"then
      if s.controller.config.options.member_layout.ordering.enabled then s.settings_open=true;s.manager_help_open=false;s.studio.select("ordering")
      else s.controller.sortMembers();rebuild_pick_geometry()end
    elseif name=="hud_manager"then s.open_raid_management();return
    elseif name=="hud_native"then
      s.request_native_visibility()
    elseif name=="icon_position"then
      local icons=s.controller.config.options.aura_icons
      s.controller.setOption("aura_icons","position",cycle(icons.position,{"bottom_right","top_right","top_left","bottom_left"}))
      s.controller.setOption("aura_icons",icons.grouped~=false and"anchor"or"positions",{})
    elseif name=="icon_grouped"then
      s.controller.setOption("aura_icons","grouped",not s.controller.config.options.aura_icons.grouped)
    elseif name=="icon_reset_positions"then
      s.controller.setOption("aura_icons","anchor",{});s.controller.setOption("aura_icons","positions",{})
    elseif name=="effect_search"then
      s.effect_query=s.studio.effectQuery();s.studio.section=1
    elseif name=="effect_clear_search"then
      if s.studio.setEffectQuery then s.studio.setEffectQuery("")end
      s.effect_query="";s.studio.section=1
    elseif name=="studio_more" then s.studio.more()
    elseif name=="previous"then s.studio.stepPage(-1)
    elseif name=="next"then s.studio.stepPage(1)
    elseif name=="raid_previous"then s.controller.action("previous")
    elseif name=="raid_next"then s.controller.action("next")
    elseif name=="native_toggle" then
      s.request_native_visibility()
    elseif name=="manager_shortcut"then
      local open=not wasManagerOpen
      cancel_input();s.manager_menu_open=open;s.refresh();return
    elseif name=="raid_management"then s.open_raid_management();return
    elseif name=="resource_check" then
      local ok,v=probe_call("toggle");if ok and v~=false then probe_tick_failed=false end
    elseif name=="save" then s.storage.save(s.controller.config);s.studio_notice=nil;s.drag_notice=nil
    elseif name=="theme_native"then s.controller.setOption("appearance","mode","native")
    elseif name:sub(1,6)=="theme_"and Themes.accepts(name:sub(7))then
      s.controller.setOption("appearance","mode","custom");s.controller.setOption("appearance","theme",name:sub(7))
    elseif name=="appearance_role_icon"then s.controller.setOption("appearance","role_icon",not s.controller.config.options.appearance.role_icon)
    elseif name=="show_distance"then s.controller.setOption("appearance","show_distance",not s.controller.config.options.appearance.show_distance)
    elseif name=="ind_target"or name=="ind_hover" then
      local key=name=="ind_target"and"target"or"hover";s.controller.setOption("indicators",key,not s.controller.config.options.indicators[key])
    elseif name=="health_styles"or name=="health_styles_back"then
      s.studio.healthStylesOpen=name=="health_styles";s.studio.section=1
    elseif name=="hatch_mode"then
      s.controller.setOption("indicators","hatch_mode",cycle(s.controller.config.options.indicators.hatch_mode,{"stripes","solid","both"}))
    elseif name=="health_style_outline"or name=="health_style_badge"or name=="health_style_hatch"then
      if s.studio.page~="healing"or not s.studio.healthStylesOpen then return end
      s.controller.setOption("indicators","health_style",name:sub(14))
    elseif name=="ind_health"or name=="ind_mana"then
      local key=name=="ind_health"and"low_health"or"low_mana"
      s.controller.setOption("indicators",key,not s.controller.config.options.indicators[key])
    elseif name=="range"then
      local r=s.controller.config.options.range;local n=cycle(r.enabled and r.distance or 0,{0,15,20,25,30,35,40,50,100,130})
      s.controller.setOption("range","enabled",n~=0);if n~=0 then s.controller.setOption("range","distance",n)end
    elseif name=="range_alpha"then s.controller.setOption("range","alpha",cycle(s.controller.config.options.range.alpha,{0.35,0.5,0.65,0.8}))
    elseif name=="hots"or name=="debuffs"then s.controller.setOption("auras",name,not s.controller.config.options.auras[name])
    elseif name=="font"then
      local d=s.controller.config.settings.display;d.font_size=cycle(d.font_size,{10,12,14,16,18,20,24})
    elseif name=="dimensions_apply"then
      local width,height=s.studio.dimensions()
      width=whole_pixels(width,C.MIN_WIDTH,C.MAX_WIDTH);height=whole_pixels(height,C.MIN_HEIGHT,C.MAX_HEIGHT)
      if width and height and s.controller.setDimensions(width,height)then
        s.studio.setDimensions(width,height)
        s.dimensions_notice="Frame size: "..width.." Ãƒâ€” "..height.." px. Save settings to keep it."
      else s.dimensions_notice="Use whole pixels: width 40Ã¢â‚¬â€œ480; height 20Ã¢â‚¬â€œ100."end
    elseif name=="frame_width_down"or name=="frame_width_up"or name=="frame_height_down"or name=="frame_height_up"then
      local key=name:find("width",1,true)and"width"or"height"
      local l=s.controller.config.settings[s.controller.config.view.layout]
      local delta=name:sub(-2)=="up"and 1 or -1
      if s.controller.setDimension(key,l[key]+delta)then s.dimensions_notice="Frame size: "..l.width.." Ãƒâ€” "..l.height.." px. Save settings to keep it."end
    elseif name=="profile_store"then
      local n=s.studio.name();if not n or n==""then n=s.profile_name or"My healing setup"end
      n=Preferences.profileName(n)
      if s.controller.saveProfile(n)then s.profile_name=n;s.delete_pending=nil end
    elseif name=="profile_slot"then s.studio.nextSlot()
    elseif deleteIndex then
      local n=profileKey
      if n and s.controller.config.profiles[n]then s.delete_pending=n;s.delete_epoch=(s.delete_epoch or 0)+1 end
    elseif name=="profile_confirm_delete"then
      local n=profileKey==s.delete_pending and profileKey or nil
      if n and s.controller.deleteProfile(n)then if s.profile_name==n then s.profile_name=nil end end
      s.delete_pending=nil
    elseif name=="profile_cancel_delete"then if profileKey==s.delete_pending then s.delete_pending=nil end
    else
      s.controller.action(name)
      if name=="lock"or name=="reset_layout"then rebuild_pick_geometry()end
      if name=="reset_layout"then
        for _,edit in ipairs({s.studio.widthEdit,s.studio.heightEdit})do
          if edit and s.cache[edit]then s.cache[edit].SetText=nil end
        end
        local layout=s.controller.config.settings.raid;s.studio.setDimensions(layout.width,layout.height)
        s.dimensions_notice="Layout reset: original raid size 62 Ãƒâ€” 34 px, default spacing, columns and font. Save settings to keep it."
      end
    end
    if resumeHud and owner_alive()and s.visible and not s.settings_open then s.hover_enabled=s.hover.arm()==true end
    s.refresh()
  end
  local function button(id,parent)
    local o=widget("button",id,parent or s.options);if not o then return nil end
    if id~="cog"and id~="manager_shortcut"and id~="picker_wheel"and id~="picker_value"and id:sub(1,12)~="colour_pick_"then o.studio_bg=drawable(o,0.075,0.11,0.15,1)end
    critical(B.member(o,"style"),"SetFontSize",12)
    critical(o,"SetHandler","OnClick",function()
      if not owner_alive()then return end
      if(id=="cog"or id=="manager_shortcut")and s.aux_drag then return end
      if(id=="cog"or id=="manager_shortcut")and s.dock_click_block then
        -- Native HUD buttons may omit OnMouseDown. Suppress the trailing drag
        -- click once, never permanently latch both controls off.
        local now=B.now(api);local untilTime=s.dock_click_block_until
        s.dock_click_block=nil;s.dock_click_block_until=nil
        if not now or not untilTime or now<=untilTime then return end
      end
      if not s.active or not s.visible or not s.cache[o] or s.cache[o].Show~=true or s.cache[o].enabled==false then return end
      if id:sub(1,4)=="hud_"and(not s.manager_help_open or not s.cache[s.manager_tip]or s.cache[s.manager_tip].Show~=true)then return end
      if id~="cog"and id~="manager_shortcut"and id:sub(1,4)~="hud_"and not s.settings_open then return end
      local ok=pcall(perform,id)
      if not ok or s.failed then s.fault() end
    end)
    show(o,true);s.buttons[id]=o;return o
  end
  local function enable(o,v)
    if not o then return end
    local c=s.cache[o];if c.enabled==v then return end
    if critical(o,"Enable",v) then c.enabled=v end
  end
  do
    local steps={
      {title="Raid Frames at a glance",anchor="tab_appearance",lines={
        "•  Click or hover to target",
        "•  Move and style your raid frames",
        "•  Auto-sort by class, set priorities and mark players",
        "•  Track chosen buffs and debuffs, with screen alerts",
        "•  Save and share layouts with profiles"}},
      {title="Shield shortcuts",anchor="manager_shortcut",lines={
        "Click the shield beside the cog for quick actions.",
        "Toggle hover targeting, open raid management,",
        "or show and hide either set of raid frames."}},
      {title="Settings and Priority",anchor="tab_ordering",practice=true,lines={
        "Appearance and Indicators change how the bars look.",
        "General Settings controls frame size and spacing.",
        "Layout Preset sorts each new raid by class the way you want.",
        "Try Ctrl-dragging the healer between Raid and Priority."}},
      {title="Help for a setting",page="appearance",label="appearance_role_icon_label",lines={
        "Hover a setting's name for a short explanation.",
        "Try the label at the arrow."}},
      {title="Buffs & Debuffs",page="effects",anchor="effects_icons",lines={
        "Search for an effect to choose an icon, frame tint",
        "or screen alert. Drag the samples in Icon layout",
        "to arrange the text and icons."}},
      {title="Screen alerts",page="effects",section="tracker",anchor="effects_tracker",demo=true,lines={
        "This is what a large debuff alert looks like.",
        "Pick a debuff in Effects and turn on its Screen alert.",
        "Use Screen alerts to enable alerts and move the text."}},
      {title="Keep your setup",anchor="save",lines={
        "Use Save settings to keep your changes.",
        "Profiles lets you store and share different setups.",
        "Open Quick tour anytime to run it again."}}
    }

    function s.stop_tour()
      local saved=s.tour_return
      if saved and s.studio then
        s.studio.page=saved.page;s.studio.section=saved.section
        s.studio.appearanceSection=saved.appearance;s.studio.effectSection=saved.effects
        s.studio.materialsOpen=saved.materials;s.rule_id=saved.rule
      end
      s.tour_step=nil;s.tour_return=nil;s.tour_started=nil;s.tour_anchor=nil
      s.tour_position=nil;s.tour_priority=nil;s.tour_practice_drag=nil;s.tour_alert_demo=nil
      show(s.tour_root,false);show(s.tour_arrow,false)
    end

    function s.step_tour(action)
      if not owner_alive()or not s.settings_open or not s.studio then return end
      local step=s.tour_step
      if action=="quick_tour"then
        if not step then
          s.tour_return={page=s.studio.page,section=s.studio.section,appearance=s.studio.appearanceSection,
            effects=s.studio.effectSection,materials=s.studio.materialsOpen,rule=s.rule_id}
        end
        step=1;s.tour_position=nil;s.tour_priority=nil
      elseif not step then return
      elseif action=="tour_skip"or(action=="tour_next"and step==#steps)then s.stop_tour();return
      elseif action=="tour_back"then step=math.max(1,step-1)
      elseif action=="tour_next"then step=step+1
      else return end
      s.cancel_text_drag();s.ordering_menu=nil;s.tour_practice_drag=nil
      s.tour_step=step;s.tour_started=B.now(api)or 0
      local page=steps[step].page
      if page then
        s.studio.select(page)
        if page=="appearance"then s.studio.appearanceSection="design"
        else s.studio.effectSection=steps[step].section or"icons";s.studio.materialsOpen=false;s.rule_id=nil end
      end
    end

    -- Same champagne stops and sparkle tint as Buffs & Debuffs Common Effects.
    local stops={{0,116,87,34},{.17,188,157,90},{.40,246,232,189},{.61,178,147,80},{.78,216,194,138},{1,131,99,41}}
    local glints={{8,14,7},{22,5,3},{58,7,5},{75,15,7},{7,29,5},{76,32,3},
      {12,48,7},{73,51,7},{19,62,3},{64,64,5},{40,68,3}}
    local bounce={0,2,4,6,8,6,4,2}
    local function arrow_strip(n)
      local t=(n-1)/15;local i=1
      while t>stops[i+1][1]do i=i+1 end
      local a,b=stops[i],stops[i+1];local f=(t-a[1])/(b[1]-a[1])
      return (a[2]+(b[2]-a[2])*f)/255,(a[3]+(b[3]-a[3])*f)/255,(a[4]+(b[4]-a[4])*f)/255,1
    end
    local function orient_arrow(direction,x,y,w,h)
      if direction=="right"then return y,x,h,w end
      if direction=="up"then return x,72-y-h,w,h end
      return x,y,w,h
    end
    function s.animate_tour(now)
      local a=s.tour_anchor
      if not a or not s.tour_step or not s.settings_open or s.settings_moving or s.aux_drag
        or s.dragging or s.member_drag then return end
      local frame=math.floor(math.max(0,now-(s.tour_started or now))/70)
      local offset=bounce[frame%#bounce+1]
      local x=a.x+(a.direction=="right"and -offset or 0)
      local y=a.y+(a.direction=="up"and offset or a.direction=="down"and -offset or 0)
      place(s.tour_arrow,"UIParent",math.max(0,math.min(x,a.sw-a.w)),math.max(0,math.min(y,a.sh-a.h)),a.w,a.h)
      if s.tour_glint_frame==frame then return end
      s.tour_glint_frame=frame
      for i,pair in ipairs(s.tour_glints)do
        local phase=(frame+i*5)%12
        local alpha=math.max(0,1-math.abs(phase-4)/5)
        for _,part in ipairs(pair)do colour(part,1,.97,.85,alpha)end
      end
    end

    local function practice_card(root)
      local demo={}
      demo.raid=drawable(root,.20,.17,.13,1);demo.priority=drawable(root,.25,.20,.13,1)
      demo.raidTitle=label("tour_raid_title",root,12);text(demo.raidTitle,"RAID SLOTS")
      demo.priorityTitle=label("tour_priority_title",root,12);text(demo.priorityTitle,"SEPARATE PRIORITY")
      demo.raidTank=drawable(root,.22,.44,.55,1);demo.raidTankName=label("tour_raid_tank",root,12);text(demo.raidTankName,"Tank")
      demo.priorityDps=drawable(root,.35,.29,.54,1);demo.priorityDpsName=label("tour_priority_dps",root,12);text(demo.priorityDpsName,"Mage")
      demo.drop=drawable(root,.37,.31,.22,1);demo.dropText=label("tour_practice_drop",root,11)
      demo.member=button("tour_practice_member",root);text(demo.member,"Healer");colour(demo.member.studio_bg,.54,.28,.43,1)
      call(demo.member,"EnableDrag",true)
      local function current()
        return owner_alive()and s.visible and s.settings_open and steps[s.tour_step]and steps[s.tour_step].practice
          and s.cache[root]and s.cache[root].Show and not s.aux_drag
      end
      local function start()
        if not current()then return end
        local ok,ctrl=call(B.member(api,"Input"),"IsControlKeyDown")
        if ok and ctrl==true and current()then s.tour_practice_drag=true;s.refresh()end
      end
      local function stop()
        if not s.tour_practice_drag then return end
        s.tour_practice_drag=nil
        if not current()then return end
        local ok,mx,my=B.mouse(api,current)
        if ok and current()then
          local box,drop=s.cache[root],s.cache[demo.drop]
          if mx>=box.x+drop.x and mx<box.x+drop.x+drop.w and my>=box.y+drop.y and my<box.y+drop.y+drop.h then
            s.tour_priority=not s.tour_priority
          end
        end
        if current()then s.refresh()end
      end
      replace_handler(demo.member,"OnDragStart",start)
      replace_handler(demo.member,"OnDragStop",stop);replace_handler(demo.member,"OnDragEnd",stop);replace_handler(demo.member,"OnMouseUp",stop)
      return demo
    end
    local function paint_practice(root,width,y,visible)
      if visible and not s.tour_practice then s.tour_practice=practice_card(root)end
      local d=s.tour_practice;if not d then return end
      for _,o in pairs(d)do show(o,visible)end
      if not visible then return end
      local lx,rx=18,math.floor(width/2)+26
      local w=math.floor(width/2)-44
      place(d.raid,root,lx,y,w,87);place(d.priority,root,rx,y,w,87)
      place(d.raidTitle,root,lx+9,y+3,w-18,18);place(d.priorityTitle,root,rx+9,y+3,w-18,18)
      place(d.raidTank,root,lx+9,y+23,w-18,23);place(d.raidTankName,root,lx+16,y+23,w-32,23)
      place(d.priorityDps,root,rx+9,y+23,w-18,23);place(d.priorityDpsName,root,rx+16,y+23,w-32,23)
      local memberX,dropX=lx+9,rx+9
      if s.tour_priority then memberX,dropX=dropX,memberX end
      place(d.drop,root,dropX,y+51,w-18,27);place(d.dropText,root,dropX+7,y+51,w-32,27)
      text(d.dropText,s.tour_practice_drag and"Drop here"or"Empty slot")
      if s.tour_practice_drag then colour(d.drop,.57,.42,.19,1)else colour(d.drop,.37,.31,.22,1)end
      place(d.member,root,memberX,y+51,w-18,27)
      place(d.member.studio_bg,d.member,0,0,w-18,27)
    end

    function s.paint_tour(w,h,now)
      if not s.tour_step then return end
      if not s.settings_open or not s.visible then s.stop_tour();return end
      s.tour_alert_demo=nil
      if s.colour_picker or s.reset_pending or s.ordering_menu or s.delete_pending then
        s.tour_anchor=nil;show(s.tour_root,false);show(s.tour_arrow,false);return
      end
      local step=steps[s.tour_step]
      local anchor=step.label and s.studio.labels[step.label]or s.buttons[step.anchor]
      local rect=s.cache[anchor]
      local ax,ay
      if rect and rect.Show then
        ax=rect.x;ay=rect.y
        local parent=rect.parent
        while parent and parent~="UIParent"do
          local c=s.cache[parent]
          if not c or not c.Show then ax=nil;break end
          ax=ax+c.x;ay=ay+c.y;parent=c.parent
        end
      end
      if not s.tour_root then
        s.tour_root=empty("quick_tour_card");s.tour_arrow=empty("quick_tour_arrow")
        if not s.tour_root or not s.tour_arrow then return end
        call(s.tour_root,"EnablePick",true)
        call(s.tour_arrow,"EnablePick",false);call(s.tour_arrow,"Clickable",false)
        s.tour_edge=drawable(s.tour_root,.59,.47,.28,1);s.tour_fill=drawable(s.tour_root,.13,.11,.09,1)
        s.tour_header=button("tour_drag",s.tour_root)
        bind_aux(s.tour_header,s.tour_root,"tour")
        s.tour_title=label("quick_tour_title",s.tour_root,20)
        s.tour_drag_hint=label("quick_tour_drag_hint",s.tour_root,11);text(s.tour_drag_hint,"Drag to move")
        s.tour_lines={};s.tour_pieces={};s.tour_outline={};s.tour_glints={}
        for n=1,#steps[1].lines do s.tour_lines[n]=label("quick_tour_line_"..n,s.tour_root,14)end
        for n=1,16 do s.tour_outline[n]=drawable(s.tour_arrow,.675,.549,.271,1)end
        for n=1,16 do s.tour_pieces[n]=drawable(s.tour_arrow,arrow_strip(n))end
        for i=1,#glints do
          s.tour_glints[i]={drawable(s.tour_arrow,1,.97,.85,1),drawable(s.tour_arrow,1,.97,.85,1)}
        end
        for _,id in ipairs({"tour_skip","tour_back","tour_next"})do button(id,s.tour_root)end
      end
      local cw,ch=488,96+#step.lines*23+(step.practice and 96 or 0)
      local root=s.tour_root;local position=s.tour_position
      local x=position and position.x or math.floor((w-cw)/2)
      local y=position and position.y or math.floor((h-ch)/2)
      if not position and s.tour_step>1 and ax and x<ax+rect.w and x+cw>ax and y<ay+rect.h and y+ch>ay then
        if ax+rect.w+cw+18<=w then x=ax+rect.w+10
        elseif ay+rect.h+ch+18<=h then y=ay+rect.h+10
        elseif ay>=ch+18 then y=ay-ch-10 end
      end
      if not(s.aux_drag and s.aux_drag.kind=="tour")then
        place(root,"UIParent",math.max(8,math.min(x,w-cw-8)),math.max(8,math.min(y,h-ch-8)),cw,ch)
      end
      place(s.tour_edge,root,0,0,cw,ch);place(s.tour_fill,root,1,1,cw-2,ch-2)
      place(s.tour_header,root,1,1,cw-2,42);show(s.tour_header,true)
      place(s.tour_title,s.tour_header,17,2,cw-120,38);text(s.tour_title,s.tour_step.." / "..#steps.."  "..step.title)
      place(s.tour_drag_hint,s.tour_header,cw-91,2,80,38);colour(s.tour_drag_hint.style,.88,.75,.48,1)
      for n,line in ipairs(s.tour_lines)do
        if step.lines[n]then place(line,root,19,49+(n-1)*23,cw-38,22);text(line,step.lines[n]);show(line,true)
        else show(line,false)end
      end
      paint_practice(root,cw,51+#step.lines*23,step.practice==true)
      for n,id in ipairs({"tour_skip","tour_back","tour_next"})do
        local o=s.buttons[id]
        place(o,root,n==1 and 18 or cw-18-(4-n)*88,ch-39,80,27)
        text(o,n==1 and "Skip"or n==2 and"Back"or s.tour_step==#steps and"Done"or"Next")
        enable(o,n~=2 or s.tour_step>1);show(o,true);paint_button_chrome(o,n==3,"button")
      end
      if ax then
        local direction=step.label and"right"or ay<71 and"up"or"down"
        local x=direction=="right"and ax-63 or ax+math.floor(rect.w/2)-42
        local y=direction=="right"and ay+math.floor(rect.h/2)-42 or direction=="up"and ay+rect.h-9 or ay-63
        s.tour_anchor={x=x,y=y,direction=direction,w=direction=="right"and 72 or 84,h=direction=="right"and 84 or 72,sw=w,sh=h}
        for n,piece in ipairs(s.tour_pieces)do
          local width=n<=9 and 18 or 54-(n-10)*6
          local x,y=42-width/2,12+(n-1)*3
          place(s.tour_outline[n],s.tour_arrow,orient_arrow(direction,x-1,y-1,width+2,5))
          place(piece,s.tour_arrow,orient_arrow(direction,x,y,width,3))
        end
        for i,g in ipairs(glints)do
          local x,y,span=g[1],g[2],g[3];local half=math.floor(span/2)
          place(s.tour_glints[i][1],s.tour_arrow,orient_arrow(direction,x-half,y,span,1))
          place(s.tour_glints[i][2],s.tour_arrow,orient_arrow(direction,x,y-half,1,span))
        end
        s.animate_tour(now or s.tour_started)
      else s.tour_anchor=nil end
      local raise=s.tour_raised_step~=s.tour_step or s.cache[root].Show~=true
      show(root,true);show(s.tour_arrow,ax~=nil)
      if raise then call(root,"Raise");call(s.tour_arrow,"Raise");s.tour_raised_step=s.tour_step end
      s.tour_alert_demo=step.demo==true
    end
  end
  function s.repair_dock(managerEnabled,dx,dy)
    if not owner_alive()or not s.visible or not s.dock_root or s.aux_drag then return false end
    local cachedRoot=s.cache[s.dock_root];if not cachedRoot then return false end
    local plan=s.last_plan
    if managerEnabled==nil then managerEnabled=plan~=nil end
    dx=dx or cachedRoot.x;dy=dy or cachedRoot.y
    local repair=s.dock_repair_serial or 0
    if owner_alive()and(s.dock_raise_epoch~=s.input_epoch or s.dock_raise_cells~=#s.cells or s.dock_raise_x~=dx or s.dock_raise_y~=dy or s.dock_repair_done~=repair)then
      if s.dock_repair_done~=repair then
        local rootCache=s.cache[s.dock_root]
        if rootCache then
          local x0,y0,w0,h0=rootCache.x,rootCache.y,rootCache.w,rootCache.h
          rootCache.parent=nil;rootCache.Show=nil;rootCache.input_attempt_Enable=nil
          rootCache.input_attempt_EnablePick=nil;rootCache.input_attempt_Clickable=nil
          place(s.dock_root,"UIParent",x0,y0,w0,h0);optional_input(s.dock_root,"Enable",true)
          optional_input(s.dock_root,"EnablePick",true);optional_input(s.dock_root,"Clickable",true);show(s.dock_root,true)
        end
        for _,id in ipairs({"cog","manager_shortcut"})do
          local o=s.buttons[id];local c=s.cache[o]
          if c then
            local x0,y0,w0,h0=c.x,c.y,c.w,c.h;c.parent=nil;c.enabled=nil;c.Show=nil;c.input_attempt_EnablePick=nil;c.input_attempt_Clickable=nil
            place(o,s.dock_root,x0,y0,w0,h0);show(o,true);optional_input(o,"EnablePick",true);optional_input(o,"Clickable",true)
            enable(o,id=="cog"or managerEnabled);call(o,"RegisterForClicks","LeftButton",true)
          end
        end
      end
      if owner_alive()then call(s.dock_root,"Raise");s.dock_repair_done=repair;s.dock_raise_epoch=s.input_epoch;s.dock_raise_cells=#s.cells;s.dock_raise_x=dx;s.dock_raise_y=dy end
    end
    return not s.failed
  end
  local function bind_profile(id,name)
    local o=s.buttons[id];if not o or type(name)~="string"or not owner_alive()then return end
    s.profile_bindings=s.profile_bindings or{}
    local prior=s.profile_bindings[id]
    local epoch=(id=="profile_confirm_delete"or id=="profile_cancel_delete")and s.delete_epoch or nil
    if id:sub(1,15)=="profile_switch_"then epoch=s.profile_load end
    if prior and prior.name==name and prior.epoch==epoch then return end
    local ticket={name=name,epoch=epoch};s.profile_bindings[id]=ticket
    local ok,value=call(o,"SetHandler","OnClick",function()
      if not owner_alive()or not s.visible or not s.settings_open or s.profile_bindings[id]~=ticket
        or not s.cache[o]or s.cache[o].Show~=true or s.cache[o].enabled==false then return end
      local good=pcall(perform,id,ticket.name)
      if not good or s.failed then s.fault()end
    end)
    -- button() already owns the single OnClick release; replacement adds no
    -- extra cleanup entry. Old queued closures cannot act on a reordered card.
    if not owner_alive()then return end
    if not ok or value==false then s.failed=true;s.first_failure=s.first_failure or"SetHandler"end
  end
  local function bind_effect(id,effectID)
    local o=s.buttons[id];effectID=Watch.id(effectID)
    if not o or not effectID or not owner_alive()then return end
    s.effect_bindings=s.effect_bindings or{}
    local epoch=id=="alert_warning_ok"and s.alert_warning or nil
    local prior=s.effect_bindings[id];if prior and prior.id==effectID and prior.epoch==epoch then return end
    local ticket={id=effectID,epoch=epoch};s.effect_bindings[id]=ticket
    local ok,value=call(o,"SetHandler","OnClick",function()
      if not owner_alive()or not s.visible or not s.settings_open or not s.studio or s.studio.page~="effects"
        or s.studio.effectSection~="icons" or s.effect_bindings[id]~=ticket
        or not s.cache[o] or s.cache[o].Show~=true or s.cache[o].enabled==false then return end
      local good=pcall(perform,id,ticket.id);if not good or s.failed then s.fault()end
    end)
    if not owner_alive()then return end
    if not ok or value==false then s.failed=true;s.first_failure=s.first_failure or"SetHandler"end
  end
  replace_handler=function(o,event,fn)
    local found=false;for _,name in ipairs(s.handlers[o]or{})do if name==event then found=true;break end end
    if not found then return critical(o,"SetHandler",event,fn)end
    local ok,value=call(o,"SetHandler",event,fn)
    if not ok or value==false then s.failed=true;s.first_failure=s.first_failure or"SetHandler";return false end
    return true
  end
  function s.set_ordering_menu_input(active)
    local root=s.studio and s.studio.orderingMenuRoot
    if root then optional_input(root,"EnablePick",active);optional_input(root,"Clickable",active)end
    for id in pairs(s.ordering_choice_bindings or{})do local o=s.buttons[id];if o then
      local enabled=active and s.cache[o]and s.cache[o].Show==true or false
      optional_input(o,"EnablePick",enabled);optional_input(o,"Clickable",enabled)
    end end
  end
  function s.open_ordering_menu(kind,index,anchor)
    if not owner_alive()or not s.visible or not s.settings_open or s.settings_moving or s.dragging or s.member_drag or s.colour_picker or s.reset_pending
      or s.studio.page~="ordering"or(kind=="party"and s.studio.orderingPart~=nil and s.studio.orderingPart~="rules")
      or(kind~="party"and s.studio.orderingPart~="slots")then return false end
    local c=s.cache[anchor];if not c or not c.Show then return false end
    local rules=s.controller.config.options.member_layout.ordering
    local selected
    if kind=="slot"then selected=rules.slots[string.format("%d",index)]else selected=rules.parties[string.format("%d",index)]end
    if s.ordering_menu and s.ordering_menu.anchor==anchor then s.ordering_menu=nil;s.refresh();return true end
    cancel_input()
    if not owner_alive()or not s.settings_open then return false end
    local choices={"tank","melee","healer","mage","ranged","flex"}
    if kind=="slot"then choices[#choices+1]="auto";selected=selected or"auto"end
    choices[#choices+1]="cancel"
    local origin=s.studio.extent
    s.ordering_menu={ticket={},kind=kind,index=index,anchor=anchor,config=s.controller.config,rules=rules,
      part=s.studio.orderingPart,section=s.studio.section,choices=choices,selected=selected,
      x=origin.x+c.x,y=origin.y+c.y+c.h+2,
      title=kind=="slot"and("Party "..(math.floor((index-1)/5)+1)..", slot "..((index-1)%5+1))or("Party "..index..(kind=="party_all"and": all five slots"or" category"))}
    s.refresh();return true
  end
  local function ordering_menu_current(ticket)
    local m=s.ordering_menu
    return m and m.ticket==ticket and owner_alive()and s.visible and s.settings_open and not s.settings_moving and not s.dragging and not s.member_drag
      and not s.colour_picker and not s.reset_pending and s.controller.config==m.config
      and s.controller.config.options.member_layout.ordering==m.rules and s.studio.page=="ordering"
      and s.studio.orderingPart==m.part and s.studio.section==m.section
  end
  local function bind_ordering_choice(id,ticket,choice)
    local o=s.buttons[id];if not o then return end
    s.ordering_choice_bindings=s.ordering_choice_bindings or{}
    if s.ordering_choice_bindings[id]==ticket then return end;s.ordering_choice_bindings[id]=ticket
    replace_handler(o,"OnClick",function()
      if s.ordering_choice_bindings[id]~=ticket or not ordering_menu_current(ticket)or not s.cache[o]or not s.cache[o].Show then return end
      local ok=pcall(function()
        local m=s.ordering_menu;s.ordering_menu=nil
        if choice~="cancel"then
          local rules=Ordering.validate(m.rules);if not rules then return end
          if m.kind=="slot"then rules.slots[string.format("%d",m.index)]=choice~="auto"and choice or nil
          else
            rules.parties[string.format("%d",m.index)]=choice
            if m.kind=="party_all"then for slot=(m.index-1)*5+1,m.index*5 do rules.slots[string.format("%d",slot)]=nil end end
          end
          if s.controller.setOrdering(rules)then cancel_input();rebuild_pick_geometry()end
        end
        s.refresh()
      end)
      if not ok or s.failed then s.fault()end
    end)
  end
  local function bind_ordering(id,kind,index)
    local o=s.buttons[id];if not o then return end
    s.ordering_bindings=s.ordering_bindings or{}
    local config,part,section=s.controller.config,s.studio.orderingPart,s.studio.section
    local old=s.ordering_bindings[id]
    if old and old.config==config and old.part==part and old.section==section and old.index==index and old.kind==kind then return end
    local ticket={config=config,part=part,section=section,index=index,kind=kind};s.ordering_bindings[id]=ticket
    call(o,"RegisterForClicks","LeftButton",true);call(o,"RegisterForClicks","RightButton",true)
    replace_handler(o,"OnClick",function(a,b)
      local which=(a=="LeftButton"or a=="RightButton")and a or((b=="LeftButton"or b=="RightButton")and b or nil)
      if not which then
        if type(a)=="string"or type(b)=="string"then return end
        which="LeftButton"
      end
      if s.ordering_bindings[id]~=ticket or s.controller.config~=config or s.studio.page~="ordering"or s.studio.orderingPart~=part or s.studio.section~=section then return end
      local ok=pcall(s.open_ordering_menu,kind,index,o);if not ok or s.failed then s.fault()end
    end)
  end
  local function bind_colour(id,field,binding,label)
    local o=s.buttons[id];if not o or not owner_alive()then return end
    s.colour_bindings=s.colour_bindings or{}
    local clear=id:sub(1,13)=="colour_clear_"
    local config,options=s.controller.config,s.controller.config.options
    local old=s.colour_bindings[id]
    local page,section=s.studio.page,s.studio.section
    if old and old.field==field and old.binding==binding and old.page==page and old.section==section and old.options==options and old.config==config then return end
    local ticket={field=field,binding=binding,page=page,section=section,config=config,options=options};s.colour_bindings[id]=ticket
    replace_handler(o,"OnClick",function()
      if not owner_alive()or not s.visible or not s.settings_open or(not clear and s.colour_picker)or s.reset_pending
        or s.controller.config~=config or config.options~=options
        or s.colour_bindings[id]~=ticket or s.studio.page~=page or s.studio.section~=section
        or not s.cache[o]or s.cache[o].Show~=true or editor_blocks_click()then return end
      local ok=pcall(function()
        if clear then
          local dps=field=="dps_colour_"..(binding or"")and(binding=="mage"or binding=="ranged"or binding=="melee")
          if dps then if options.colours.dps[binding]==nil then return end
          elseif not Colours.className(binding)or options.colours.classes[binding]==nil then return end
          local p=s.colour_picker
          if p then
            if not picker_current(p)or(dps and(p.target.kind~="dps"or p.target.key~=binding))or(not dps and(p.target.kind~="class"or p.target.name~=binding))then return end
            cancel_colour()
          end
          if s.controller.config~=config or config.options~=options then return end
          if dps then s.controller.setDpsColour(binding,nil)else s.controller.setClassColour(binding,nil)end
          local r=s.studio.edits[field];if r then r.visible=false;r.canonical=nil;r.lastText=nil;r.restore=nil end
        else s.open_colour(field,binding,label)end
        s.refresh()
      end)
      if not ok or s.failed then s.fault()end
    end)
  end
  local function bind_picker(id,ticket)
    local o=s.buttons[id];if not o or not owner_alive()then return end
    s.picker_bindings=s.picker_bindings or{}
    if s.picker_bindings[id]==ticket then return end;s.picker_bindings[id]=ticket
    local function current()
      local p=s.colour_picker
      return s.picker_bindings[id]==ticket and p and p.ticket==ticket and picker_current(p)
        and s.cache[o]and s.cache[o].Show==true
    end
    local kind=id=="picker_wheel"and"wheel"or id=="picker_value"and"value"or nil
    local function guarded(fn)return function(...)
      if not current()then return end
      local ok=pcall(fn,...);if not ok or s.failed then s.fault()end
    end end
    if not kind then
      replace_handler(o,"OnClick",guarded(function()perform(id,ticket)end));return
    end
    optional_input(o,"Enable",true);optional_input(o,"EnablePick",true);optional_input(o,"Clickable",true);optional_input(o,"EnableDrag",true)
    local function start(a,b)
      if a=="RightButton"or b=="RightButton"then return end
      if s.picker_point(ticket,kind,false)and current()then s.colour_picker.drag=kind;s.refresh()end
    end
    local function stop()
      local p=s.colour_picker
      if p.drag==kind then s.picker_point(ticket,kind,true)end
      if current()then p.drag=nil;s.refresh()end
    end
    replace_handler(o,"OnMouseDown",guarded(start));replace_handler(o,"OnDragStart",guarded(start))
    replace_handler(o,"OnMouseUp",guarded(stop));replace_handler(o,"OnDragStop",guarded(stop));replace_handler(o,"OnDragEnd",guarded(stop))
    replace_handler(o,"OnLeave",guarded(function()s.colour_picker.drag=nil end))
    replace_handler(o,"OnClick",guarded(function(a,b)if a~="RightButton"and b~="RightButton"then s.picker_point(ticket,kind,false);s.refresh()end end))
  end
  local renderer_ui={widget=widget,label=label,drawable=drawable,call=function(o,k,...)
      if not owner_alive()then return false end
      local ok,a,b=call(o,k,...);if not owner_alive()then return false end
      return ok,a,b
    end,place=place,show=show,text=text,colour=colour,
    raid_bar=raid_bar,raid_background=raid_background,checked=checked,
    unavailable=function()s.failed=true end,
    small_font=B.member(FONT_SIZE,"SMALL") or 12,middle_font=B.member(FONT_SIZE,"MIDDLE") or 14,timer_align=B.member(ALIGN,"RIGHT"),
    offline_ink=B.member(FONT_COLOR,"DARK_GRAY") or {0.35,0.35,0.35,1},
    bar_style=function(key)return B.member(STATUSBAR_STYLE,key)end,
    effectImage=function(parent,path)
      if not owner_alive()or type(path)~="string"then return nil end
      local ok,o=call(parent,"CreateIconImageDrawable",path,"background")
      if not owner_alive()then if ok and o then call(o,"Show",false)end;return nil end
      if not ok or not o then return nil end
      local cleared,result=call(o,"ClearAllTextures")
      if not owner_alive()or not cleared or result==false then call(o,"Show",false);return nil end
      local good,v=call(o,"AddTexture",path)
      if not owner_alive()or not good or v==false then call(o,"Show",false);return nil end
      return o
    end,
    effectTexture=function(o,path)
      if not owner_alive()or type(path)~="string"then return false end
      local ok,v=call(o,"ClearAllTextures")
      if not owner_alive()or not ok or v==false then return false end
      ok,v=call(o,"AddTexture",path);return owner_alive()and ok and v~=false
    end,
    healthArt=function(parent)
      if not owner_alive()then return nil end
      local ok,o=call(parent,"CreateImageDrawable","Addon/Mazrim_Raid_Frames/assets/health-indicators.dds","background")
      if not owner_alive()or not ok or not o then return nil end
      call(o,"EnablePick",false);call(o,"Clickable",false);return o
    end,
    materialArt=function(parent)
      if not owner_alive()then return nil end
      local ok,o=call(parent,"CreateImageDrawable",Materials.path,"background")
      if not owner_alive()or not ok or not o then return nil end
      call(o,"EnablePick",false);call(o,"Clickable",false);return o
    end,
    leader=function(id,parent)
      local o=factory(W_ICON,"CreateLeaderMark",id,parent)
      call(o,"EnablePick",false);call(o,"Clickable",false);return o
    end}
  local function editor_redraw()
    if owner_alive()and s.visible and s.settings_open and s.last_plan then
      local w,h=B.extent(api);s.refresh_options(s.last_plan,w,h)
    end
  end
  local function editor_location()
    if not s.studio then return nil end
    if s.studio.page=="appearance"then return "appearance/"..(s.studio.appearanceSection or"design")end
    if s.studio.page=="effects"and s.studio.effectSection=="layout"then return "effects/layout"end
  end
  -- Both examples edit a draft and share one validated release path.
  local function text_editor_current(editor)
    return editor and owner_alive()and s.visible and s.settings_open
      and not s.settings_moving and not s.member_drag and not s.dragging and not s.aux_drag
      and not s.colour_picker and not s.reset_pending and editor.section==editor_location()
      and s.controller.config==editor.config and editor.config.options==editor.options
      and s.controller.revision==editor.revision and s.text_editor==editor
  end
  function s.cancel_text_drag()s.text_drag=nil end
  function s.begin_text_drag()
    local editor=s.text_editor
    if s.text_drag or not text_editor_current(editor)then return false end
    local ok,mx,my=B.mouse(api,function()return text_editor_current(editor)end)
    if not ok or not text_editor_current(editor)or not contains(editor.stage,mx,my)then return false end
    local frame,hit,isIcon
    for n=#editor.frames,1,-1 do
      local f=editor.frames[n];local cell=f.cell
      for _,list in ipairs({editor.allowIcons and cell.iconRects or{},cell.textRects or{}})do
        for i=#list,1,-1 do local r=list[i]
          if contains({x=f.x+r.x,y=f.y+r.y,w=r.w,h=r.h},mx,my)then frame=f;hit=r;isIcon=list==cell.iconRects;break end
        end
        if hit then break end
      end
      if hit then break end
    end
    if not hit then return false end
    local section=isIcon and"aura_icons"or"text_positions"
    local draft=Preferences.copy(editor.options[section]);if not draft then return false end
    local cx,cy=hit.x+hit.w/2,hit.y+hit.h/2
    local grouped=isIcon and draft.grouped~=false;local key=hit.kind
    if isIcon then
      if not Watch.id(hit.id)then return false end
      key=grouped and"anchor"or"positions"
      if grouped then
        local x0,y0,x1,y1
        for _,r in ipairs(frame.cell.iconRects)do
          x0=math.min(x0 or r.x,r.x);y0=math.min(y0 or r.y,r.y);x1=math.max(x1 or(r.x+r.w),r.x+r.w);y1=math.max(y1 or(r.y+r.h),r.y+r.h)
        end
        cx=(x0+x1)/2;cy=(y0+y1)/2
      end
    elseif key~="name"and key~="health"and key~="distance"then return false end
    local bounds=frame.cell.textBounds
    s.text_drag={editor=editor,frame=frame,section=section,key=key,id=hit.id,grouped=grouped,draft=draft,
      height=isIcon and frame.h or(bounds and bounds.height or frame.h),
      grab={x=mx-frame.x-cx,y=my-frame.y-cy},start={x=mx,y=my}}
    show(s.settings_tip,false);return true
  end
  function s.text_drag_point()
    local drag=s.text_drag;local editor=drag and drag.editor
    if not drag then return false end
    if not text_editor_current(editor)then s.cancel_text_drag();return false end
    local ok,mx,my=B.mouse(api,function()return s.text_drag==drag and text_editor_current(editor)end)
    if not ok or s.text_drag~=drag or not text_editor_current(editor)then s.cancel_text_drag();return false end
    -- A press with no movement must never turn the legacy position into a
    -- custom position, or shift a name when releasing the same pixel.
    if mx==drag.start.x and my==drag.start.y and not drag.changed then return true end
    local icon=drag.section=="aura_icons";local lo,hi=icon and-1000 or 0,icon and 2000 or 1000
    local function normal(value,size)return math.max(lo,math.min(hi,math.floor(value/size*1000+.5)))end
    local point={x=normal(mx-drag.frame.x-drag.grab.x,drag.frame.w),y=normal(my-drag.frame.y-drag.grab.y,drag.height)}
    local old=icon and not drag.grouped and drag.draft.positions[drag.id]or drag.draft[drag.key]
    if old and old.x==point.x and old.y==point.y then return true end
    if icon and not drag.grouped then drag.draft.positions[drag.id]=point else drag.draft[drag.key]=point end
    drag.changed=true;editor_redraw();return true
  end
  function s.finish_text_drag(commit)
    local drag=s.text_drag;if not drag then return false end
    local current=text_editor_current(drag.editor)
    if commit and current then s.text_drag_point();current=s.text_drag==drag and text_editor_current(drag.editor)end
    s.text_drag=nil
    if not current then return false end
    if commit and drag.changed then
      if not s.controller.setOption(drag.section,drag.key,drag.draft[drag.key])then editor_redraw();return false end
    end
    s.text_editor_release_until=(B.now(api)or 0)+150
    editor_redraw();return true
  end
  local function bind_text_editor(input)
    if s.text_editor_bound==input then return end;s.text_editor_bound=input
    optional_input(input,"Enable",true);optional_input(input,"EnablePick",true);optional_input(input,"Clickable",true);optional_input(input,"EnableDrag",true)
    local function start(a,b)
      if a=="RightButton"or b=="RightButton"then return end
      local ok=pcall(s.begin_text_drag);if not ok or s.failed then s.fault()end
    end
    local function stop()
      local ok=pcall(s.finish_text_drag,true);if not ok or s.failed then s.fault()end
    end
    replace_handler(input,"OnMouseDown",start);replace_handler(input,"OnDragStart",start)
    replace_handler(input,"OnMouseUp",stop);replace_handler(input,"OnDragStop",stop);replace_handler(input,"OnDragEnd",stop)
    replace_handler(input,"OnLeave",stop);replace_handler(input,"OnClick",function()end)
  end
  local function dragOccupant(row)
    return {name=row.name,nameKnown=row.nameKnown,slot=row.slot,token=row.token,identity=row.identity}
  end
  local function sameDragOccupant(a,b)
    if not a or not b then return a==b end
    return a.name==b.name and a.nameKnown==b.nameKnown and a.slot==b.slot and a.token==b.token and a.identity==b.identity
  end
  local function validMemberDrop(rows,layout,drag,target)
    local projection=MemberLayout.project(rows,layout)
    if not projection then return false end
    local source,occupant
    for _,panel in ipairs({"main","priority"})do
      for _,position in ipairs(projection[panel])do
        local row=rows[position.row_index]
        local group=panel=="priority"and"priority"or position.group
        if group==drag.source.group and position.position==drag.source.order and sameDragOccupant(row,drag.source)then source=row end
        if target and group==target.group and position.position==target.order then
          if occupant then return false end
          occupant=row
        end
      end
    end
    return source~=nil and MemberLayout.unique(rows,source)
      and(not target or sameDragOccupant(occupant,target.occupant))
  end
  function s.begin_member_drag(cell)
    if s.member_drag or s.member_drag_finishing or s.aux_drag or s.dragging or s.settings_moving or s.colour_picker or s.reset_pending or not owner_alive()or s.controller.mode~="live"then return false end
    local row=cell and cell.row;local plan=s.last_plan
    if not row or not plan or not MemberLayout.unique(plan.data.rows,row)then return false end
    local rows=plan.data.rows
    local projection=MemberLayout.project(rows,s.controller.config.options.member_layout)
    if not projection then return false end
    local resume=s.hover_enabled or s.hover.armed;cancel_input();show(s.settings_tip,false)
    local d={source=dragOccupant(row),config=s.controller.config,revision=s.controller.revision,
      sourcePriority=cell.rect and cell.rect.panel=="priority"or false,resume=resume,targets={},ghosts={}}
    s.priority_drop_active=true
    if not s.refresh()or not owner_alive()or not s.visible then s.priority_drop_active=false;return false end
    plan=s.last_plan
    if s.controller.config~=d.config or s.controller.revision~=d.revision or plan.data.rows~=rows then s.priority_drop_active=false;s.refresh();return false end
    if d.sourcePriority then
      if not s.priority_reset_root then
        s.priority_reset_root=empty("priority_reset_drop");call(s.priority_reset_root,"EnablePick",false);call(s.priority_reset_root,"Clickable",false)
        s.priority_reset_edge=drawable(s.priority_reset_root,.88,.75,.48,1)
        s.priority_reset_fill=drawable(s.priority_reset_root,.10,.14,.18,.98)
        s.priority_reset_title=label("priority_reset_title",s.priority_reset_root,19)
        s.priority_reset_help=label("priority_reset_help",s.priority_reset_root,11)
        call(B.member(s.priority_reset_title,"style"),"SetAlign",B.member(ALIGN,"CENTER"))
        call(B.member(s.priority_reset_help,"style"),"SetAlign",B.member(ALIGN,"CENTER"))
      end
      local width=math.min(360,plan.screen_w-32);local height=92
      local x=math.floor((plan.screen_w-width)/2);local y=plan.screen_h-height-12
      place(s.priority_reset_root,"UIParent",x,y,width,height)
      place(s.priority_reset_edge,s.priority_reset_root,0,0,width,height)
      place(s.priority_reset_fill,s.priority_reset_root,2,2,width-4,height-4)
      place(s.priority_reset_title,s.priority_reset_root,8,16,width-16,30);text(s.priority_reset_title,"DRAG HERE TO RESET")
      place(s.priority_reset_help,s.priority_reset_root,8,51,width-16,24);text(s.priority_reset_help,"Return to class rules or previous raid position")
      show(s.priority_reset_root,true);call(s.priority_reset_root,"Raise")
      d.reset={x=x,y=y,w=width,h=height}
    else show(s.priority_reset_root,false)end
    local byRow={};for _,panel in ipairs({"main","priority"})do for _,p in ipairs(projection[panel])do
      local group=panel=="priority"and"priority"or p.group
      byRow[p.row_index]={group=group,order=p.position}
      if rows[p.row_index]==row then d.source.group=group;d.source.order=p.position end
    end end
    for _,r in ipairs(s.rendered_cells or{})do local a=byRow[r.row_index];local origin=r.panel=="priority"and plan.priority or plan
      if a then d.targets[#d.targets+1]={x=origin.x+r.x,y=origin.y+r.y,w=r.width,h=r.height,group=a.group,order=a.order,
        occupant=dragOccupant(rows[r.row_index])}end
    end
    if plan.priority and #projection.priority<50 then
      local p=plan.priority;local order=#projection.priority+1
      local drop=p.drop
      if drop then d.targets[#d.targets+1]={x=p.x+drop.x,y=p.y+drop.y,w=drop.width,h=drop.height,group="priority",order=order}end
    end
    if not s.drop_root then s.drop_root=empty("member_drop_slots");call(s.drop_root,"EnablePick",false);call(s.drop_root,"Clickable",false)end
    place(s.drop_root,"UIParent",0,0,plan.screen_w,plan.screen_h);show(s.drop_root,true)
    local slots={source="raid",rows={}};for i=1,50 do slots.rows[i]={slot=i}end
    local grid=P.nativeLayout(slots,s.controller.config.view.layout,s.controller.config.settings,plan.screen_w,plan.screen_h,plan.page)
    for _,r in ipairs(grid and grid.grid.cells or{})do
      local t={x=plan.x+r.x,y=plan.y+r.y,w=r.width,h=r.height,group=math.floor((r.slot-1)/5)+1,order=(r.slot-1)%5+1}
      local p=plan.priority
      local occupied=p and t.x<p.x+p.width and t.x+t.w>p.x and t.y<p.y+p.height and t.y+t.h>p.y or false
      for _,prior in ipairs(d.targets)do if prior.x==t.x and prior.y==t.y then occupied=true;break end end
      if not occupied and t.x>=0 and t.y>=0 and t.x+t.w<=plan.screen_w and t.y+t.h<=plan.screen_h then
        d.targets[#d.targets+1]=t
        local id=#d.ghosts+1;s.drop_ghosts=s.drop_ghosts or{};local o=s.drop_ghosts[id]
        if not o then o=label("member_drop_"..id,s.drop_root,10);s.drop_ghosts[id]=o;call(o,"EnablePick",false)end
        place(o,s.drop_root,t.x,t.y,t.w,t.h);text(o,"[ Empty slot ]");show(o,true);d.ghosts[#d.ghosts+1]=o
      end
    end
    if d.reset then call(s.priority_reset_root,"Raise")end
    s.member_drag=d;s.drag_click_block=true;return true
  end
  function s.end_member_drag(commit,quiet)
    local d=s.member_drag;if not d then return false end
    s.member_drag=nil;s.member_drag_finishing=true;s.priority_drop_active=false
    for _,o in ipairs(d.ghosts)do show(o,false)end;show(s.drop_root,false);show(s.priority_reset_root,false)
    local function current()
      return owner_alive()and s.visible and s.controller.config==d.config and s.controller.revision==d.revision
        and s.controller.mode=="live"
    end
    if commit and current()then
      local ok,x,y=B.mouse(api,current)
      if ok and current()then
        local data=s.controller.data();local layout=d.config.options.member_layout
        local reset=d.sourcePriority and contains(d.reset,x,y)
        local target
        if not reset then
          for _,t in ipairs(d.targets)do if contains(t,x,y)then target=t;break end end
        end
        if reset or target then
          if data.source~="raid"or not validMemberDrop(data.rows,layout,d,target)then
            s.drag_notice="Raid slot changed during the move. Try again."
          elseif reset then
            local source=d.source
            local returned=s.controller.resetPriorityMember(source.name,source.identity,source.slot)
            s.drag_notice=returned and"Priority placement reset."or"Priority reset unavailable for this member."
          elseif not s.controller.moveMember(d.source.name,target.group,target.order)then
            s.drag_notice="Move unavailable: check unique roster names and slots, with at most five per main group."
          end
        end
      end
    end
    s.member_drag_finishing=nil;s.pointer_pressed=false;s.pointer_cell=nil;rebuild_pick_geometry()
    if commit and d.resume and owner_alive()and s.visible then
      s.hover_enabled=true;if not s.settings_open then s.hover_enabled=s.hover.arm()==true end
    end
    if not quiet and owner_alive()and s.visible then s.refresh();s.hover.block(s.last_hover_key)end
    return true
  end
  local function new_cell(i,parent)
    renderer_ui.parent=parent or s.root
    local cell=R.create(i,renderer_ui);s.cells[i]=cell
    if not cell then return nil end
    local function guarded(fn)return function(...)
      if not s.active or not s.visible then return end
      local ok=pcall(fn,...);if not ok or s.failed then s.fault() end
    end end
    critical(cell.input,"SetHandler","OnEnter",guarded(function()s.enter_cell(cell)end))
    critical(cell.input,"SetHandler","OnClick",guarded(function(a,b)
      local button=(a=="LeftButton"or a=="RightButton")and a or((b=="LeftButton"or b=="RightButton")and b or nil)
      s.click_cell(cell,button)
    end))
    -- Native buttons deliver left clicks by default. The first-party buff
    -- button explicitly opts into RightButton separately; retain left input.
    local registered,value=call(cell.input,"RegisterForClicks","RightButton")
    cell.right_click_ready=registered and value~=false
    if not owner_alive()then return nil end
    critical(cell.input,"SetHandler","OnLeave",guarded(function()
      trace_record("LEAVE",{entry=s.trace_entry,token=cell.row and cell.row.token,expected=cell.row and cell.row.identity,painting=s.painting==true})
      if s.pointer_cell==cell.input then s.pointer_cell=nil;s.pointer_pressed=false;s.click_ticket=nil;s.hover.leave() end
    end))
    critical(cell.input,"SetHandler","OnMouseDown",guarded(function()if returnTarget then returnTarget.cancel()end;if not s.dragging and not s.aux_drag then s.drag_click_block=nil end;s.pointer_pressed=true;s.dock_repair_serial=(s.dock_repair_serial or 0)+1;s.hover.leave()end))
    critical(cell.input,"SetHandler","OnMouseUp",guarded(function()s.pointer_pressed=false;finish_drag()end))
    if s.drag_ready then cell.drag_bound=bind_drag(cell.input,function()
      return cell.row~=nil and cell.rect~=nil and s.cache[cell.root] and s.cache[cell.root].Show==true
    end);if not cell.drag_bound then s.drag_ready=false end end
    return cell
  end
  local function pointer_guard(cell,row,epoch,ticket)
    local function ready()
      if not owner_alive()or not s.visible or s.settings_open or s.dragging or s.aux_drag or s.controller.mode~="live"
        or epoch~=s.input_epoch or s.pointer_cell~=cell.input
        or(ticket and s.click_ticket~=ticket)or not cell.row or cell.row.identity~=row.identity or cell.row.token~=row.token then return nil end
      return cell.rect,s.last_plan
    end
    return function()
      local r,p=ready();if not r or not p then return false end
      local ok,over=call(cell.input,"IsMouseOver")
      if ready()~=r then return false end
      local origin=r.panel=="priority"and p.priority or p
      local inside=ok and type(over)=="boolean"and over or nil
      if ok and over==false then inside=false
      elseif inside~=true then
        local a,x0,y0=call(cell.input,"GetEffectiveOffset");if ready()~=r then return false end
        local b,rw,rh=call(cell.input,"GetEffectiveExtent");if ready()~=r then return false end
        local m,x,y=call(B.member(api,"Input"),"GetMousePos");if ready()~=r then return false end
        local aa,xx,yy=call(cell.input,"GetEffectiveOffset");if ready()~=r then return false end
        local bb,ww,hh=call(cell.input,"GetEffectiveExtent");if ready()~=r then return false end
        inside=a and b and m and aa and bb and B.finite(x0)and B.finite(y0)and B.finite(rw)and B.finite(rh)
          and rw>0 and rh>0 and xx==x0 and yy==y0 and ww==rw and hh==rh
          and B.finite(x)and B.finite(y)and x>=x0 and x<x0+rw and y>=y0 and y<y0+rh
      end
      local x,y
      if s.manager_help_open then
        local m,xx,yy=B.mouse(api,owner_alive);x=xx;y=yy
        if ready()~=r or not m or contains(s.manager_help_rect,x,y)then inside=false end
      end
      local rr,pp=ready();inside=inside==true and rr==r and pp==p
      -- Native picking supplies the hit result directly; tracing must not add
      -- a separate mouse query merely to attach optional coordinates.
      trace_record("POINTER",{entry=s.trace_entry,token=row.token,expected=row.identity,x=x or false,y=y or false,inside=inside==true})
      return inside
    end
  end
  function s.enter_cell(cell)
    if not owner_alive()or not s.visible or not cell.row or not cell.rect then return end
    s.trace_entry=s.trace_entry+1
    trace_record("ENTER",{entry=s.trace_entry,token=cell.row.token,expected=cell.row.identity,painting=s.painting==true,dispatch=not s.painting})
    s.pointer_cell=cell.input;s.click_ticket=nil
    if s.dragging or s.aux_drag or s.member_drag or s.pointer_pressed then s.hover.leave();return end
    local row=cell.row
    s.hover.update(row,B.now(api),pointer_guard(cell,row,s.input_epoch),cell.input,not s.painting)
  end
  function s.click_cell(cell,buttonName)
    if s.drag_click_block or s.aux_drag or s.member_drag then return false end
    if buttonName=="RightButton"then
      local opened,handled=s.open_marker_menu(cell)
      if opened or handled then return true end
      return s.open_raid_management(cell)
    end
    if buttonName~="LeftButton"or not owner_alive()or not s.visible or s.settings_open or s.dragging or s.painting
      or s.controller.mode~="live"or type(targetAttempt)~="function"then return false end
    if not cell.row or not cell.rect or not I.accepts(cell.row.identity)then return false end
    -- Retired click_modifier values remain readable in old profiles. Targeting
    -- always uses an ordinary left click; drag gestures have their own guards.
    if returnTarget then returnTarget.cancel()end
    if not owner_alive()or not s.visible then return false end
    local row=cell.row;local ticket={epoch=s.input_epoch};s.click_ticket=ticket;s.pointer_cell=cell.input;s.pointer_pressed=false
    local guard=pointer_guard(cell,row,ticket.epoch,ticket)
    if not guard()then s.click_ticket=nil;return false end
    local ok,result=pcall(targetAttempt,row.token,row.identity,guard,row.nameKnown==true and row.name or nil)
    s.last_input_status=ok and result=="REQUESTED"and"Click target requested"or"Click target unavailable for this member"
    -- Selection can synchronously rebuild native input surfaces. A member
    -- click does not change our settings epoch, so request a separate dock
    -- hit/stack repair AFTER the call returns, without repeating selection.
    s.dock_repair_serial=(s.dock_repair_serial or 0)+1;s.dock_repair_pending=true
    if owner_alive()and s.visible then s.refresh()end
    return ok and result=="REQUESTED"
  end
  function s.close_marker_menu(resume)
    local ticket=s.marker_menu_subject;s.marker_menu_subject=nil;show(s.marker_menu_root,false)
    if ticket and resume and ticket.resume and owner_alive()and s.visible then
      s.hover_enabled=true;if not s.settings_open then s.hover_enabled=s.hover.arm()==true end
    end
  end
  function s.open_marker_menu(cell)
    if not owner_alive()or not s.visible or(s.settings_open and not(cell and cell.rect and cell.rect.panel=="priority"))or s.dragging or s.aux_drag
      or s.controller.mode~="live"or not cell or not cell.row or(not I.accepts(cell.row.identity)and not MemberLayout.unique(s.last_plan and s.last_plan.data.rows or{},cell.row))then return false end
    local row=cell.row;local ticket={identity=row.identity,slot=row.slot,token=row.token,resume=s.hover_enabled or s.hover.armed,name=row.name,priority=cell.rect and cell.rect.panel=="priority"}
    cancel_input()
    if not owner_alive()or not s.visible or cell.row~=row then return false end
    s.marker_menu_subject=ticket
    local function valid()
      if not owner_alive()or not s.visible or(s.settings_open and not ticket.priority)or s.dragging or s.marker_menu_subject~=ticket then return false end
      local n=0;for _,r in ipairs(s.last_plan and s.last_plan.data.rows or{})do if r.identity==ticket.identity and r.token==ticket.token and r.name==ticket.name and r.slot==ticket.slot and(I.accepts(ticket.identity)or MemberLayout.unique(s.last_plan.data.rows,r))then n=n+1 end end
      return n==1
    end
    local function finish(resume)
      if s.marker_menu_subject==ticket then s.close_marker_menu(resume)end
    end
    if not s.marker_menu_root then
      s.marker_menu_root=empty("local_marker_menu")
      s.marker_menu_background=drawable(s.marker_menu_root,0.13,0.11,0.09,0.99)
      s.marker_menu_title=label("local_marker_title",s.marker_menu_root,12)
      s.marker_menu_hint=label("local_marker_hint",s.marker_menu_root,10)
    end
    local w,h=B.extent(api);local ok,x,y=B.mouse(api,owner_alive)
    if not ok or not valid()then finish(false);return false,true end
    x=math.max(8,math.min(x,w-266));y=math.max(8,math.min(y,h-333))
    place(s.marker_menu_root,"UIParent",x,y,258,325);place(s.marker_menu_background,s.marker_menu_root,0,0,258,325)
    place(s.marker_menu_title,s.marker_menu_root,10,6,210,23);text(s.marker_menu_title,P.text(row.name or"Raid member",24))
    local canMark=localMarker and type(localMarker.points)=="function" and I.accepts(row.identity)
    place(s.marker_menu_hint,s.marker_menu_root,10,31,238,18)
    text(s.marker_menu_hint,canMark and "Local only • one symbol per member" or "Roster placement only • marker unavailable")
    local choices={{"priority",ticket.priority and"Reset Priority: return to raid"or"Move to Priority"},{"star","Star"},{"heart","Heart"},{"diamond","Diamond"},{"cross","Cross"},{"circle","Circle"},{"triangle","Triangle"},{"clear","Clear local symbol"},{"manage","Raid management"},{"close","×"}}
    for n,choice in ipairs(choices)do
      local id="local_marker_"..choice[1];local o=s.buttons[id]or button(id,s.marker_menu_root)
      local close=choice[1]=="close"
      place(o,s.marker_menu_root,close and 224 or 10,close and 6 or 53+(n-1)*29,close and 24 or 238,close and 23 or 27)
      local available=choice[1]=="priority" and MemberLayout.unique(s.last_plan.data.rows,row)
        or choice[1]~="priority" and (canMark or choice[1]=="manage" or choice[1]=="close")
      text(o,choice[2]);enable(o,available);paint_button_chrome(o,false);show(o,true)
      local symbol=choice[1]
      replace_handler(o,"OnClick",function()
        if not valid()then return end
        if symbol=="manage"then finish(false);s.open_raid_management();return end
        if symbol=="priority"and ticket.priority then
          local reset=s.controller.resetPriorityMember(ticket.name,ticket.identity,ticket.slot)
          s.drag_notice=reset and"Priority placement reset."or"Priority reset unavailable for this member."
          rebuild_pick_geometry()
        elseif symbol=="priority"then
          local used={};local projection=MemberLayout.project(s.controller.data().rows,s.controller.config.options.member_layout)
          for _,p in ipairs(projection and projection.priority or{})do used[p.position]=true end
          local at=1;while used[at]and at<50 do at=at+1 end
          if not s.controller.moveMember(ticket.name,"priority",at)then s.drag_notice="Move unavailable: check unique roster names and slots, with at most five per main group."end
        elseif symbol=="clear" and canMark then localMarker.clear(ticket.identity)
        elseif symbol~="close" and canMark then localMarker.set(row,symbol,s.last_plan.data.rows)end
        finish(true);s.refresh()
      end)
    end
    if not valid()then finish(false);return false,true end
    call(s.marker_menu_root,"Raise")
    if not valid()then finish(false);return false,true end
    show(s.marker_menu_root,true)
    if not valid()then finish(false);return false,true end
    s.marker_menu_rect={x=x,y=y,w=258,h=325};return true
  end
  local markerShapes={
    star={".....#.....","....###....","....###....","###########",".#########.","..#######..","..#######..","..###.###..",".###...###.",".##.....##."},
    heart={".###...###.","#####.#####","###########","###########",".#########.","..#######..","...#####...","....###....",".....#....."},
    diamond={".....#.....","....###....","...#####...","..#######..",".#########.","###########",".#########.","..#######..","...#####...","....###....",".....#....."},
    cross={"....###....","....###....","....###....","....###....","###########","###########","###########","....###....","....###....","....###....","....###...."},
    circle={"...#####...",".#########.",".#########.","###########","###########","###########","###########","###########",".#########.",".#########.","...#####..."},
    triangle={".....#.....","....###....","....###....","...#####...","...#####...","..#######..","..#######..",".#########.",".#########.","###########","###########"}}
  local markerColours={star={1,0.86,0.1},heart={1,0.25,0.4},diamond={0.5,0.6,1},cross={0.3,1,0.5},circle={0.2,0.85,1},triangle={1,0.55,0.15}}
  -- Leave room for the game's overhead nameplate under the symbol.
  local markerRise=68
  local markerSurfaces={}
  function s.hide_markers()
    for _,surface in ipairs(markerSurfaces)do
      surface.identity=nil
      show(surface.root,false)
    end
  end
  local function move_marker(root,point,ready)
    local x,y=math.floor(point.x-18),math.floor(point.y-markerRise)
    local cachedPoint=s.cache[root]
    if not cachedPoint or cachedPoint.parent~="UIParent"then
      return place(root,"UIParent",x,y,37,37) and ready()
    end
    if cachedPoint.x==x and cachedPoint.y==y then return ready()end
    if not critical(root,"RemoveAllAnchors")or not ready()then return false end
    local ok,value=call(root,"AddAnchor","TOPLEFT","UIParent","TOPLEFT",x,y)
    if not ready()then return false end
    if not ok or value==false then
      ok,value=call(root,"AddAnchor","TOPLEFT","UIParent",x,y)
    end
    if not ok or value==false or not ready()then
      cachedPoint.x=nil;cachedPoint.y=nil
      return false
    end
    cachedPoint.x=x;cachedPoint.y=y
    return true
  end
  local function paint_marker_shape(surface,symbol,ready)
    if surface.symbol==symbol then return true end
    local index=0
    local ink,shape=markerColours[symbol],markerShapes[symbol]
    for y,line in ipairs(shape)do
      local x=1
      while x<=#line do
        if line:sub(x,x)=="#"then
          if not ready()then return false end
          local first=x
          while x<=#line and line:sub(x,x)=="#"do x=x+1 end
          index=index+1
          local part=surface.parts[index]
          if not part then
            part=drawable(surface.root,ink[1],ink[2],ink[3],1)
            if not part then return false end
            surface.parts[index]=part
          end
          place(part,surface.root,2+(first-1)*3,2+(y-1)*3,(x-first)*3,3)
          colour(part,ink[1],ink[2],ink[3],1);show(part,true)
        else
          x=x+1
        end
      end
    end
    for n=index+1,#surface.parts do show(surface.parts[n],false)end
    if not ready()then return false end
    surface.symbol=symbol
    return true
  end
  function s.paint_marker(rows,w,h,now)
    local plan=s.last_plan
    local function ready()
      return owner_alive() and s.visible and s.controller.mode=="live" and s.last_plan==plan
    end
    if not ready() or not localMarker or type(localMarker.points)~="function" or not localMarker.active()then
      s.hide_markers();return
    end
    local visible={}
    local points=localMarker.points(rows,now)
    for _,point in ipairs(points)do
      if markerShapes[point.symbol] and point.x>=22 and point.x<=w-22 and point.y>=markerRise+2 and point.y<=h then
        visible[point.identity]=point
      end
    end
    local assigned,free={},{}
    for _,surface in ipairs(markerSurfaces)do
      if surface.identity and visible[surface.identity]then
        assigned[surface.identity]=surface
      else
        surface.identity=nil
        show(surface.root,false)
        free[#free+1]=surface
      end
    end
    for _,point in ipairs(points)do
      if not ready()then return end
      if visible[point.identity]then
        local surface=assigned[point.identity] or free[#free]
        if not assigned[point.identity]then
          if surface then
            free[#free]=nil
          else
            local root=empty("local_projected_symbol_"..(#markerSurfaces+1))
            if not root then return end
            surface={root=root,parts={}}
            markerSurfaces[#markerSurfaces+1]=surface
            call(root,"EnablePick",false);call(root,"Clickable",false);show(root,false)
          end
          surface.identity=point.identity
        end
        local shown=move_marker(surface.root,point,ready)
          and paint_marker_shape(surface,point.symbol,ready)
        if not ready()then return end
        show(surface.root,shown==true)
      end
    end
  end
  function s.paint_overlays(rows,w,h,now)
    local function ready()return owner_alive()and s.visible and s.controller.mode=="live"end
    s.paint_marker(rows,w,h,now)
    local prefs=s.controller.config.options.auras
    local alerts=prefs.raid_tracker and prefs.large_alerts and s.raidAlerts.current(rows,now)or{}
    local preview=s.alert_move_active==true
    local demo=s.tour_alert_demo==true and not preview
    if preview or demo then alerts={{name="Raid member",id=0}}end
    if #alerts>0 and ready()then
      if not s.raid_alert_root then
        s.raid_alert_root=empty("large_raid_alerts");call(s.raid_alert_root,"EnablePick",true);call(s.raid_alert_root,"Clickable",true)
        s.raid_alert_handle=button("alert_drag_handle",s.raid_alert_root);bind_aux(s.raid_alert_handle,s.raid_alert_root,"alert")
        s.raid_alert_labels={};s.raid_alert_caption=label("raid_alert_caption",s.raid_alert_root,10)
      end
      local width=math.min(w-32,demo and 390 or 880);local height=#alerts*34+22
      local pos=s.controller.config.options.alerts
      local ax=not demo and pos.custom_position and pos.x or math.floor((w-width)/2)
      local ay=pos.custom_position and pos.y or math.max(8,math.floor(h*0.5))
      if demo then
        local card=s.cache[s.tour_root]
        if card then
          local below=card.y+card.h+8
          ay=below+height<=h-8 and below or math.max(8,card.y-height-8)
        end
      end
      if not(s.aux_drag and s.aux_drag.kind=="alert")then place(s.raid_alert_root,"UIParent",math.max(8,math.min(ax,w-width-8)),math.max(8,math.min(ay,h-height-8)),width,height)end
      place(s.raid_alert_handle,s.raid_alert_root,0,0,width,19);text(s.raid_alert_handle,"Shift-drag alert • Click to finish");show(s.raid_alert_handle,preview)
      if preview then replace_handler(s.raid_alert_handle,"OnMouseDown",function()if not s.aux_drag then s.drag_click_block=nil end end);replace_handler(s.raid_alert_handle,"OnClick",function()
        if s.aux_drag or s.drag_click_block or not owner_alive() or not s.visible or not s.alert_move_active then return end
        s.alert_move_active=false;s.settings_open=true;s.studio.select("effects");s.studio.effectSection="tracker"
        s.refresh()
      end)end
      text(s.raid_alert_caption,demo and"TUTORIAL EXAMPLE"or preview and"Alert position preview"or"EXPERIMENTAL • first observed • freshness unknown")
      show(s.raid_alert_caption,not preview)
      place(s.raid_alert_caption,s.raid_alert_root,0,0,width,18)
      for i,a in ipairs(alerts)do
        local o=s.raid_alert_labels[i];if not o then o=label("large_raid_alert_"..i,s.raid_alert_root,24);s.raid_alert_labels[i]=o end
        call(B.member(o,"style"),"SetEllipsis",true);colour(B.member(o,"style"),1,0.8,0.3,1)
        local effectName,known=s.effectLibrary.label(a.id)
        text(o,P.text(a.name,24).." • "..P.text(demo and"Petrification"or preview and"Debuff alert preview"or(known and effectName or"Selected debuff"),32));place(o,s.raid_alert_root,0,20+(i-1)*34,width,32);show(o,true)
      end
      for i=#alerts+1,#s.raid_alert_labels do show(s.raid_alert_labels[i],false)end
      if ready()then call(s.raid_alert_root,"Raise")end
      if ready()then show(s.raid_alert_root,true)end
      if not ready()then show(s.raid_alert_root,false)end
    else show(s.raid_alert_root,false)end
    if s.marker_menu_subject and s.marker_menu_rect then
      local ok,x,y=B.mouse(api,owner_alive);local r=s.marker_menu_rect
      if ok and(x<r.x or x>=r.x+r.w or y<r.y or y>=r.y+r.h)then s.close_marker_menu(true)end
    end
  end
  function s.open_raid_management(cell)
    if not owner_alive()or not s.visible or s.dragging or s.painting or s.controller.mode~="live"
      or not s.controller.live or s.controller.live.source~="raid"then return false end
    if cell and(s.settings_open or not cell.row or not cell.rect or not s.cache[cell.root]or s.cache[cell.root].Show~=true)then return false end
    local root=s.root;local plan=s.last_plan;local rect=cell and cell.rect
    cancel_input();s.manager_help_open=false;show(s.manager_tip,false);s.settings_open=false;s.delete_pending=nil
    local epoch=s.input_epoch
    local function ready()
      return owner_alive()and s.visible and not s.settings_open and not s.dragging and not s.painting
        and s.root==root and s.input_epoch==epoch and s.controller.mode=="live"
        and s.controller.live and s.controller.live.source=="raid"
        and(not cell or(cell.rect==rect and s.last_plan==plan and cell.row and s.cache[cell.root]and s.cache[cell.root].Show==true))
    end
    local function guard()
      if not ready()then return false end
      if not cell then return true end
      local ok,x,y=B.mouse(api,owner_alive)
      return ready()and ok and B.finite(x)and B.finite(y)
        and x>=plan.x+rect.x and x<plan.x+rect.x+rect.width and y>=plan.y+rect.y and y<plan.y+rect.y+rect.height
    end
    local fn=B.member(nativeControls,"openRaidManager")
    local ok,result=false,"UNAVAILABLE"
    if type(fn)=="function"and guard()then ok,result=pcall(fn,guard)end
    if not owner_alive()or not s.visible or s.input_epoch~=epoch then return false end
    local requested=ok and(result=="OPEN"or result=="REQUESTED")
    s.last_input_status=requested and"Raid Management: right-click your name there for the full raid menu."or"Raid Management shortcut unavailable."
    s.studio_notice=s.last_input_status
    if requested and not s.raid_manager_hint_shown then
      s.raid_manager_hint_shown=true;B.log(api,s.last_input_status)
      if not owner_alive()then return false end
    end
    s.refresh();return requested
  end
  local function paint_cell(cell,row,rect,display,hover,now)
    renderer_ui.parent=rect.panel=="priority"and s.priority_root or s.root
    local observed=s.effectLibrary.decorate(s.auraModel.frame(row.identity,now,s.controller.config.options.auras,s.controller.revision,s.controller.config.options.aura_icons.max_visible))
    R.paint(cell,row,rect,display,hover,renderer_ui,s.controller.config.options,
      {selected=s.controller.mode=="preview"and row.selected==true or(I.accepts(row.identity)and row.identity==s.selected_identity),
        preview=s.controller.mode=="preview",auras=observed})
  end
  function s.sample_visual(now,data)
    trace_call("clock",now)
    local previous=s.selected_identity
    s.effectLibrary.prioritize(s.controller.config.options.auras,s.controller.revision)
    local selectedAlerts=false;for _ in pairs(s.controller.config.options.auras.alerts)do selectedAlerts=true;break end
    if s.visible and s.controller.mode=="live"and selectedAlerts and s.controller.config.options.auras.raid_tracker and s.controller.config.options.auras.large_alerts then
      s.effectLibrary.enrich(now,function()return owner_alive()and s.visible end,true)
    end
    s.selected_identity=nil
    if s.controller.mode~="live"or not owner_alive()then return end
    local getter=B.member(selection,"identity")
    if type(getter)=="function"then local ok,id=pcall(getter);if owner_alive()and ok and I.accepts(id)then s.selected_identity=id end end
    if s.selected_identity~=previous then s.dock_repair_serial=(s.dock_repair_serial or 0)+1 end
    if returnTarget then returnTarget.observe(s.selected_identity)end
    trace_record("SELECTED",{actual=s.selected_identity,stable=I.accepts(s.selected_identity),result=I.accepts(s.selected_identity)and"OBSERVED"or"UNKNOWN",painting=s.painting==true})
    if not B.finite(now)or type(data)~="table"or type(data.rows)~="table"then s.auraModel.clear();return end
    local ids={};for i=1,#data.rows do local id=data.rows[i].identity;if I.accepts(id)then ids[#ids+1]=id end end
    s.auraModel.retain(ids)
    local prefs=s.controller.config.options.auras
    local tracking=false
    if raidTracker then tracking=raidTracker.configure(prefs,s.controller.revision)==true end
    if type(B.member(auraSource,"setSharedBudgetEnabled"))=="function"then auraSource.setSharedBudgetEnabled(tracking)end
    if not prefs.large_alerts then s.raidAlerts.clearVisible()end
    local auraDemand=false
    if prefs.hots~=false or prefs.debuffs~=false then for _ in pairs(prefs.watch)do auraDemand=true;break end end
    if not auraDemand then for _,rule in pairs(prefs.frame_rules)do if rule.enabled then auraDemand=true;break end end end
    if not auraDemand and prefs.raid_tracker and prefs.large_alerts then for _ in pairs(prefs.alerts)do auraDemand=true;break end end
    local discover=s.settings_open and s.studio and s.studio.page=="effects" and s.studio.effectSection=="icons"
    if not auraDemand and not discover then
      -- Pause reads without dropping same-actor deadline evidence. retain() above still clears departed/replaced actors.
      s.aura_demand_active=false;s.aura_status="No selected effects require scanning. Open Buffs & Debuffs to discover effects.";return
    end
    s.aura_demand_active=true
    local targetChanged=s.selected_identity~=previous or s.target_dirty==true;s.target_dirty=false
    local targetSample=targetChanged and s.selected_identity and B.member(auraSource,"target")
    local due=not s.last_aura or now<s.last_aura or now-s.last_aura>=250
    if s.visible and(type(targetSample)=="function"or due)then
      local observations={}
      local function append(value)if type(value)=="table"then for _,item in ipairs(value)do observations[#observations+1]=item end end end
      if due and(tracking)and type(B.member(auraSource,"deep"))=="function"and type(B.member(auraSource,"sharedBudget"))=="function"then
        s.last_aura=now
        local ok,deep=pcall(auraSource.deep,data.rows,now);if ok then append(deep)end
        local ordinaryNeed=discover==true
        if prefs.hots~=false or prefs.debuffs~=false then for _ in pairs(prefs.watch)do ordinaryNeed=true;break end end
        for _,rule in pairs(prefs.frame_rules)do if rule.enabled and(rule.kind=="buff"or rule.kind=="any")then ordinaryNeed=true;break end end
        local ordinarySlots=ordinaryNeed and(prefs.scan_policy=="debuff_priority"and 1 or 2)or 0
        if auraSource.eligibleBudgetContract==1 and type(B.member(auraSource,"ordinaryCapacity"))=="function"then
          local ok,capacity=pcall(auraSource.ordinaryCapacity,data.rows,now,ordinarySlots)
          if ok and B.finite(capacity)and capacity>=0 and capacity<=ordinarySlots and capacity%1==0 then ordinarySlots=capacity end
        end
        local plan=raidTracker.coverageContract==1 and auraSource.coveragePlan(now,ordinarySlots)or nil
        if tracking and owner_alive()and s.controller.config.options.auras.raid_tracker then
          local count=plan and plan.filteredLimit or 1
          local unique,duplicates={},{};local actors=0
          for _,row in ipairs(data.rows)do if row.kind=="raid"and I.accepts(row.identity)then
            if unique[row.identity]then duplicates[row.identity]=true else unique[row.identity]=true end
          end end
          for id in pairs(unique)do if not duplicates[id]then actors=actors+1 end end
          count=math.min(count,actors)
          if count>0 and plan and type(plan.beginFilteredBatch)=="function"then
            local ok,begun=pcall(plan.beginFilteredBatch);if not ok or begun~=true then count=0 end
          end
          for _=1,count do
            if not owner_alive()or not s.controller.config.options.auras.raid_tracker then break end
            local filtered=raidTracker.step(data.rows,plan and plan.grant()or auraSource.sharedBudget(now))
            if owner_alive()and s.controller.config.options.auras.raid_tracker then
              append(filtered.samples)
              s.raidAlerts.push(filtered.raw,data.rows,now,s.controller.config.options.auras)
            end
          end
        end
        if owner_alive()and ordinarySlots>0 then local yes,rest=pcall(auraSource.sample,data.rows,now,ordinarySlots);if yes then append(rest)end end
      else
        local sample=type(targetSample)=="function"and targetSample or B.member(auraSource,"sample")
        if sample~=targetSample then s.last_aura=now end
        if type(sample)=="function"then local ok,value=pcall(sample,data.rows,now);if ok then append(value)end end
      end
      if not owner_alive()then s.auraModel.clear();return end
      s.effectLibrary.observe(observations)
      s.auraModel.replace(observations,now,s.controller.config.options.auras,s.controller.revision)
      local count=0;for i=1,#observations do if observations[i].coverage=="observed"then count=count+1 end end
      s.aura_status=count>0 and("Observed effects: "..count..". ~ = last-seen; other effects unknown.")or"Effects unknown here. Available members are observed over time."
      s.aura_status=s.aura_status.." HoT owner / dispel unknown."
    end
  end
  -- Selector hint from the existing display sample only. The comparison owner
  -- must independently validate the actor and readings before/after each event.
  function s.resource_reference()
    local function ready()
      return s.active==true and s.visible==true and s.settings_open==true
        and not s.failed and not s.closing and s.controller.mode=="live"
    end
    local ok,result=pcall(function()
      if not ready() or type(ownerCurrent)~="function" then return nil end
      if ownerCurrent()~=true or not ready() then return nil end
      local data=s.controller.live
      if type(data)~="table" or data.source~="raid" or data.coverage=="ROSTER_UNAVAILABLE"
        or type(data.rows)~="table" then return nil end
      local rows=data.rows;local count=#rows
      if count>50 then return nil end
      local selected,index,identity,token
      for i=1,count do
        local row=rows[i]
        if type(row)=="table" and row.selfKnown==true and row.isSelf==true then
          if selected or row.kind~="raid" or (row.state~="OBSERVED" and row.state~="HEALTH_UNAVAILABLE")
            or not I.accepts(row.identity) or type(row.token)~="string" then return nil end
          local suffix=row.token:match("^team([1-9][0-9]?)$")
          if not suffix or (#suffix==2 and suffix>"50") then return nil end
          selected=row;index=i;identity=row.identity;token=row.token
        end
      end
      if not selected or ownerCurrent()~=true or not ready() or s.controller.live~=data
        or data.source~="raid" or data.coverage=="ROSTER_UNAVAILABLE" or data.rows~=rows or #rows~=count
        or rows[index]~=selected or selected.kind~="raid"
        or (selected.state~="OBSERVED" and selected.state~="HEALTH_UNAVAILABLE")
        or selected.identity~=identity or selected.token~=token
        or selected.selfKnown~=true or selected.isSelf~=true then return nil end
      return {token=token,identity=identity,selfKnown=true,isSelf=true}
    end)
    if ok then return result end
  end
  function s.sample_live(force)
    local now=B.now(api)
    if not now then
      s.controller.live=s.live.unavailable("CLOCK_UNAVAILABLE");s.last_live=nil;return
    end
    if not force and s.last_live and now>=s.last_live and now-s.last_live<250 then return end
    s.last_live=now
    local ok,value=pcall(s.live.read)
    s.controller.live=ok and value or s.live.unavailable("READ_FAILED")
    if localMarker and type(localMarker.clearAll)=="function" and type(value)=="table"
      and value.source=="raid" and value.membershipEmptyConfirmed==true
      and owner_alive() and localMarker.active() then
      localMarker.clearAll()
      s.hide_markers()
    end
  end
  function s.refresh_options(v,w,h)
    if not s.active then return end
    if not s.studio then return end
    if not s.settings_open then s.profile_share=nil;s.profile_load=nil;s.alert_warning=nil;show(s.settings_tip,false);show(s.options,false);return end
    if s.studio.page~="profiles"then s.profile_share=nil;s.profile_load=nil end
    if s.studio.page~="effects"or s.studio.effectSection~="icons"then s.alert_warning=nil end
    local load=s.profile_load
    if load and s.controller.config.profiles[load.name]~=load.target then s.profile_load=nil end
    local share=s.profile_share
    local wait=share and share.wait
    if wait then
      local now=B.now(api)
      if s.profile_share==share and share.wait==wait and (not now or now>=wait.deadline)then
        share.wait=nil;share.status="Listening timed out. Start again or paste a code."
      end
    end
    if s.colour_picker and not picker_current(s.colour_picker)then cancel_colour()end
    if s.colour_picker and s.colour_picker.drag then s.picker_point(s.colour_picker.ticket,s.colour_picker.drag,true)end
    if not owner_alive()or not s.visible or not s.settings_open then return end
    if not s.reset_pending and not s.alert_warning then
      local page,section,rule,config,revision=s.studio.page,s.studio.section,s.rule_id,s.controller.config,s.controller.revision
      s.studio.poll(s.apply_edit,function()
        return owner_alive()and s.visible and s.settings_open and not s.reset_pending
          and s.studio.page==page and s.studio.section==section and s.rule_id==rule
          and s.controller.config==config and s.controller.revision==revision
      end)
    end
    if not owner_alive()or not s.visible or not s.settings_open then return end
    local running,canProbe,status=false,false,""
    if s.settings_open and s.studio.page=="status"then
      local ok,report=probe_call("report");running=ok and type(report)=="table"and report.state=="collecting"
      local supported,ready=probe_call("available");canProbe=running or(supported and ready==true and v.mode=="live"and v.data.source=="raid")
      local good,value=probe_call("status");if good and type(value)=="string"then status=P.text(value,100)end
    end
    local names=s.controller.profileNames()
    if s.profile_name and not s.controller.config.profiles[s.profile_name]then s.profile_name=nil end
    s.profile_names=names
    if s.delete_pending and not s.controller.config.profiles[s.delete_pending]then s.delete_pending=nil end
    local locked=s.controller.config.view.locked~=false
    local _,traceActive=trace_call("isActive");local _,traceStatus=trace_call("summary");local _,capture=trace_call("captureId")
    local effectRows,effectDetail={},nil
    s.effectLibrary.prioritize(s.controller.config.options.auras,s.controller.revision)
    if s.studio.page=="effects" and s.studio.effectSection=="icons"then
      s.effectLibrary.enrich(B.now(api),function()
        return owner_alive() and s.visible and s.settings_open
          and s.studio.page=="effects" and s.studio.effectSection=="icons"
      end)
      if not owner_alive()or not s.visible or not s.settings_open then return end
      local auras=s.controller.config.options.auras
      if s.rule_id then
        effectDetail=s.effectLibrary.studioRows("browse",s.rule_id,auras,s.controller.revision)[1]
      else
        effectRows=s.effectLibrary.studioRows(s.effect_scope,s.effect_query,auras,s.controller.revision)
      end
    end
    local seen={};s.observed_classes=s.observed_classes or{}
    local count=0;for _ in pairs(s.observed_classes)do count=count+1 end
    for _,row in ipairs(v.data.rows)do
      local name=row.classKnown==true and Colours.className(row.className)
      if name and not s.observed_classes[name]and count<64 then s.observed_classes[name]=true;count=count+1 end
    end
    for name in pairs(s.observed_classes)do seen[name]=true end
    for name in pairs(s.controller.config.options.colours.classes)do seen[name]=true end
    for name in pairs(s.controller.config.options.member_layout.ordering.classes)do seen[name]=true end
    s.class_names={}
    for name in pairs(seen)do
      local at=#s.class_names+1
      while at>1 and s.class_names[at-1]>name do s.class_names[at]=s.class_names[at-1];at=at-1 end
      s.class_names[at]=name
    end
    local check=B.member(nativeControls,"raidAuraCheck")
    local checkRows={}
    for _,row in ipairs(v.data.rows)do
      if row.kind=="raid"and I.accepts(row.identity)and type(row.token)=="string"then checkRows[#checkRows+1]=row end
    end
    local choice=s.raid_check_selected;local found
    for i,row in ipairs(checkRows)do if choice and row.identity==choice.identity and row.token==choice.token then found=i;break end end
    s.raid_check_rows=checkRows;s.raid_check_index=found or 1;s.raid_check_selected=checkRows[s.raid_check_index]
    local raidReport=check and check.report and check.report()or{}
    local raidCan=check and check.available and check.available()==true and raidReport.cleanupPending~=true
    local studio,config,options,epoch,page,picker=s.studio,s.controller.config,s.controller.config.options,s.input_epoch,s.studio.page,s.colour_picker
    local function render_current()
      return owner_alive()and s.visible and s.settings_open and not s.settings_moving and not s.dragging
        and s.studio==studio and s.controller.config==config and config.options==options and s.input_epoch==epoch
        and studio.page==page and s.colour_picker==picker
    end
    local subject=s.raid_check_subject;local selected=s.raid_check_selected
    local subjectMatches=subject and selected and subject.token==selected.token and subject.identity==selected.identity
    if s.options_raise_epoch~=s.input_epoch then call(s.options,"Raise");s.options_raise_epoch=s.input_epoch end
    if not render_current()then return end
    s.studio.render({orderingMenu=s.ordering_menu,alertMoveActive=s.alert_move_active==true,returnTargetStatus=returnTarget and returnTarget.status or"Experimental return unavailable",raidTrackerAvailable=raidTracker~=nil,raidTrackerStatus=raidTracker and raidTracker.report().status or"Experimental reader unavailable",raidCheckSubjectMatches=subjectMatches==true,raidCheckName=s.raid_check_selected and P.text(s.raid_check_selected.name,32)or"No identified raid member",raidCheckRows=#checkRows,raidCheckAvailable=raidCan,raidCheckReport=raidReport,current=render_current,picker=s.colour_picker,classNames=s.class_names,ruleID=s.rule_id,resetPending=s.reset_pending,pointerX=s.pointer_x,pointerY=s.pointer_y,version=V.version,config=s.controller.config,open=s.settings_open,armed=s.hover.armed or(s.settings_open and s.hover_enabled==true),
      canArm=type(targetAttempt)=="function"and v.mode=="live"and v.data.source=="raid"and not s.dragging and v.data.coverage~="ROSTER_UNAVAILABLE",
      preview=v.mode=="preview",locked=locked,preset=C.presetName(s.controller.config),named=v.data.named or #v.data.rows,
      hp=v.data.healthKnown or 0,mana=v.data.manaKnown or 0,page=v.page,pages=v.pages,
      canToggle=type(B.member(nativeControls,"toggleRaid"))=="function"or type(B.member(nativeControls,"setRaidVisible"))=="function",canProbe=canProbe,probeRunning=running,probeStatus=status,
      nativeFrameLabel=s.remember_controls and(s.controller.config.controls.native_frames==false and"Return original raid frames"or"Hide original raid frames")or nil,
      canOpenManager=type(B.member(nativeControls,"openRaidManager"))=="function"and v.mode=="live"and v.data.source=="raid",
      saveStatus=s.storage.status,canSave=not s.storage.blocked,notice=s.dimensions_notice or s.studio_notice or s.drag_notice,
      auraStatus=s.aura_status or"Aura coverage: unknown. Hover/click a member to observe available effects.",
      feedbackStatus=s.last_input_status or("Target feedback: "..(B.member(feedback,"nameStatus")or"unavailable")),
      profileNames=names,profileName=s.profile_name,profileStatus=s.controller.profile_status,deletePending=s.delete_pending,profileShare=s.profile_share,profileLoad=s.profile_load,alertWarning=s.alert_warning,
      dimensionsStatus=s.dimensions_notice,effectScope=s.effect_scope,effectRows=effectRows,effectQuery=s.effect_query,
      effectDetail=effectDetail,ruleName=effectDetail and effectDetail.name,effectKind=effectDetail and effectDetail.kind,
      effectKindCode=effectDetail and effectDetail.kindCode,effectIcon=effectDetail and effectDetail.icon,
      traceAvailable=trace~=nil,traceActive=traceActive==true,traceStatus=s.trace_save_notice or traceStatus,
      traceReport=capture~=nil and traceActive~=true,traceSaved=capture~=nil and s.trace_saved_capture==capture,
      },w,h)
    if not s.visible or not s.settings_open then show(s.settings_tip,false)end
    if not s.visible or not s.settings_open then show(s.options,false)end
    -- Compatibility aliases for shared lifecycle fixtures; labels are still real controls.
    for k,vv in pairs(s.studio.labels)do s.labels[k]=vv end
  end
  function s.refresh()
    if not s.active or not s.visible or not s.root then return false end
    if s.dragging or s.member_drag or s.settings_moving or s.painting then return true end
    s.painting=true
    local w,h=B.extent(api)
    local v,err=s.controller.screen(w,h,s.priority_drop_active==true)
    if not v then s.painting=false;B.log(api,err=="SCREEN_TOO_SMALL"and"Screen too small; minimum 680 x 400."or("Layout could not be displayed: "..(err or"unknown")..". Reopen Raid Frames to retry."));s.hide();return false end
    local framesShown=s.controller.config.visibility.frames~=false
    s.last_plan=v;s.paint_count=s.paint_count+1
    local visualNow=B.now(api)
    s.sample_visual(visualNow,v.data)
    if not s.active or not s.visible or not s.root then s.painting=false;return false end
    place(s.root,"UIParent",v.x,v.y,v.width,v.height)
    local dock=s.controller.config.options.member_layout.dock
    local dx=dock.custom_position and math.max(0,math.min(dock.x,w-50))or v.x+v.width-50
    local dy=dock.custom_position and math.max(0,math.min(dock.y,h-26))or v.y
    if not(s.aux_drag and s.aux_drag.kind=="dock")then place(s.dock_root,"UIParent",dx,dy,50,26)end
    place(s.buttons.cog,s.dock_root,0,0,22,22)
    place(s.buttons.manager_shortcut,s.dock_root,24,0,26,26)
    local canOpenManager=type(B.member(nativeControls,"openRaidManager"))=="function"and v.mode=="live"and v.data.source=="raid"
    local managerEnabled=true -- The shield also owns targeting and layout controls.
    enable(s.buttons.manager_shortcut,managerEnabled)
    for i=1,#s.manager_crest do
      local ink=CREST_PALETTE[CREST_RECTS[i][5]]
      colour(s.manager_crest[i],ink[1],ink[2],ink[3],managerEnabled and 1 or 0.4)
    end
    for _,id in ipairs({"cog","manager_shortcut"})do
      local o=s.buttons[id];optional_input(o,"EnablePick",true);optional_input(o,"Clickable",true)
    end
    enable(s.buttons.cog,true);optional_input(s.dock_root,"EnablePick",true);optional_input(s.dock_root,"Clickable",true)
    show(s.buttons.cog,true);show(s.buttons.manager_shortcut,true);show(s.dock_root,true)
    local hintX=math.max(8,math.min(dx+50-340,w-348))
    local hintY=dy+26
    local hintHeight=258
    if hintY+hintHeight>h-8 then hintY=dy-hintHeight end
    hintY=math.max(8,math.min(hintY,h-hintHeight-8))
    local hintWidth=340
    -- At middle heights on a small screen neither above nor below fits. Put
    -- the menu beside the dock instead of clamping it over the cog/shield.
    if hintX<dx+50 and hintX+hintWidth>dx and hintY<dy+26 and hintY+hintHeight>dy then
      local leftSpace=math.max(0,dx-16);local rightSpace=math.max(0,w-dx-50-16)
      if rightSpace>=leftSpace then hintWidth=math.min(340,rightSpace);hintX=dx+58
      else hintWidth=math.min(340,leftSpace);hintX=dx-hintWidth-8 end
    end
    s.manager_button_rect={x=dx+24,y=dy,w=26,h=26}
    s.manager_help_rect={x=hintX,y=hintY,w=hintWidth,h=hintHeight}
    place(s.manager_tip,"UIParent",hintX,hintY,hintWidth,hintHeight)
    place(s.manager_background,s.manager_tip,0,0,hintWidth,hintHeight)
    if framesShown then
    for i=1,#v.groups do
      local group=v.groups[i];local o=s.group_labels[i]
      if not o then
        o=label("party"..i,s.root,B.member(FONT_SIZE,"MIDDLE") or 14);s.group_labels[i]=o
        call(B.member(o,"style"),"SetShadow",true)
        critical(o,"SetInset",20,4,0,0)
        call(B.member(o,"style"),"SetAlign",B.member(ALIGN,"CENTER"))
        local ok,bg=call(o,"CreateImageDrawable",B.member(TEXTURE_PATH,"RAID"),"background")
        if ok and bg then
          critical(bg,"SetCoords",0,123,32,28);critical(bg,"SetColor",1,1,1,0.7)
          place(bg,o,10,2,32,28);show(bg,true)
        else s.failed=true end
      end
      place(o,s.root,group.x,group.y,34,19);text(o,group.text.."");show(o,framesShown and v.mode~="preview")
    end
    else for i=1,#s.group_labels do show(s.group_labels[i],false)end end
    for i=#v.groups+1,#s.group_labels do show(s.group_labels[i],false) end
    place(s.empty_label,s.root,0,#v.grid.cells==0 and 26 or 0,v.width-52,18)
    text(s.empty_label,v.mode=="preview" and "PREVIEW" or "Raid --")
    show(s.empty_label,framesShown and(#v.grid.cells==0 or v.mode=="preview"))
    local mx,my
    local mok,a,b=B.mouse(api,owner_alive);if mok then mx=a;my=b end
    s.pointer_x=mx;s.pointer_y=my
    local menuAllowed=not s.dragging and s.cache[s.buttons.manager_shortcut].enabled==true
    s.manager_help_open=menuAllowed and s.manager_menu_open==true
    optional_input(s.manager_tip,"EnablePick",s.manager_help_open);optional_input(s.manager_tip,"Clickable",s.manager_help_open)
    show(s.manager_tip,s.manager_help_open)
    for i,id in ipairs({"hud_hover","hud_manager","hud_native","hud_addon","hud_sort","hud_reset"})do
      local o=s.buttons[id];place(o,s.manager_tip,10,10+(i-1)*40,hintWidth-20,34);show(o,s.manager_help_open)
      enable(o,id~="hud_manager"or canOpenManager)
      optional_input(o,"EnablePick",s.manager_help_open);optional_input(o,"Clickable",s.manager_help_open)
      local bg=B.member(o,"studio_bg");if bg then place(bg,o,0,0,hintWidth-20,34);colour(bg,0.16,0.14,0.10,1)end
      colour(B.member(o,"style"),0.88,0.80,0.59,1)
    end
    text(s.buttons.hud_hover,"     Toggle hover healing: "..(s.hover_enabled and "ON"or"OFF"))
    if s.remember_controls then text(s.buttons.hud_native,s.controller.config.controls.native_frames==false and"Return original raid frames"or"Hide original raid frames")end
    if not s.hud_hover_dot then s.hud_hover_dot=label("hud_hover_dot",s.buttons.hud_hover,16);text(s.hud_hover_dot,"●")end
    place(s.hud_hover_dot,s.buttons.hud_hover,8,3,18,26)
    colour(B.member(s.hud_hover_dot,"style"),s.hover_enabled and 0.2 or 1,s.hover_enabled and 0.9 or 0.2,0.2,1)
    show(s.hud_hover_dot,s.manager_help_open)
    paint_button_chrome(s.buttons.hud_hover,s.hover_enabled,"toggle","      Hover targeting")
    paint_button_chrome(s.buttons.hud_addon,framesShown,"toggle","Show addon frames")
    text(s.buttons.hud_sort,s.controller.config.options.member_layout.ordering.enabled and"Configure layout preset"or("Raid order: "..(s.controller.config.options.member_layout.sort=="class"and"Class"or"Original")))
    local rendered={};for _,r in ipairs(v.grid.cells)do rendered[#rendered+1]=r end
    if v.priority then
      if not s.priority_root then s.priority_root=empty("priority_frames")end
      if not(s.aux_drag and s.aux_drag.kind=="priority")then place(s.priority_root,"UIParent",v.priority.x,v.priority.y,v.priority.width,v.priority.height)end
      show(s.priority_root,framesShown)
      if v.priority.drop and not s.priority_add then
        s.priority_add=label("priority_drop",s.priority_root,10)
        s.priority_add_fill=drawable(s.priority_add,0.65,0.46,0.12,0.90)
        s.priority_add_edge=drawable(s.priority_add,1,0.83,0.32,1)
      end
      if s.priority_add then local drop=v.priority.drop
        if drop then
          place(s.priority_add,s.priority_root,drop.x,drop.y,drop.width,drop.height)
          place(s.priority_add_fill,s.priority_add,0,0,drop.width,drop.height)
          place(s.priority_add_edge,s.priority_add,0,0,drop.width,2)
          text(s.priority_add,"Priority");show(s.priority_add,true)
        else show(s.priority_add,false)end
      end
      for _,r in ipairs(v.priority.grid.cells)do rendered[#rendered+1]=r end
    else show(s.priority_root,false)end
    s.rendered_cells=rendered
    local overRow,overKey=nil,nil;s.hover_rect=nil
    s.panel_cells=s.panel_cells or{main={},priority={}};local panelCount={main=0,priority=0};local lowerPanels={}
    if framesShown then
      for i,r in ipairs(rendered)do
        local panel=r.panel=="priority"and"priority"or"main";panelCount[panel]=panelCount[panel]+1
        local pool=s.panel_cells[panel];local c=pool[panelCount[panel]]
        if not c then c=new_cell(#s.cells+1,panel=="priority"and s.priority_root or s.root);pool[panelCount[panel]]=c end
        if not c then break end;c.used=s.paint_count
        optional_input(c.input,"Enable",true);optional_input(c.input,"EnablePick",true);optional_input(c.input,"Clickable",true)
        if c.drag_bound then optional_input(c.input,"EnableDrag",s.drag_ready)end
        if not owner_alive()or not s.visible then s.painting=false;if s.failed then s.fault()end;return false end
        c.input.priority_root=r.panel=="priority"and s.priority_root or nil;c.input.member_cell=c
        local origin=r.panel=="priority"and v.priority or v
        local row=v.data.rows[r.row_index]
        local over=B.finite(mx)and B.finite(my)and mx>=origin.x+r.x and mx<origin.x+r.x+r.width and my>=origin.y+r.y and my<origin.y+r.y+r.height
          and not(s.manager_help_open and contains(s.manager_help_rect,mx,my))
        if over then overRow=row;overKey=c.input;s.hover_rect={x=origin.x+r.x,y=origin.y+r.y,w=r.width,h=r.height}end
        -- A newly shown/retinted child may promote its HUD parent in the
        -- native window stack. Passive roster updates must stay behind dialogs.
        local hpKnown=type(row.health)=="table"and row.health.known==true
        local mpKnown=type(row.mana)=="table"and row.mana.known==true
        local mode=s.controller.config.options.appearance.mode
        if not c.layer_seen or c.layer_identity~=row.identity or c.layer_hp~=hpKnown or c.layer_mp~=mpKnown
          or c.layer_class~=row.className or c.layer_role~=row.roleStyle or c.layer_declared~=row.role
          or c.layer_offline~=row.offline or c.layer_name~=row.name or c.layer_mode~=mode then lowerPanels[panel]=true end
        c.layer_seen=true;c.layer_identity=row.identity;c.layer_hp=hpKnown;c.layer_mp=mpKnown
        c.layer_class=row.className;c.layer_role=row.roleStyle;c.layer_declared=row.role;c.layer_offline=row.offline;c.layer_name=row.name;c.layer_mode=mode
        paint_cell(c,row,r,s.controller.config.settings.display,over,visualNow)
        if c.layer_icons~=c.iconRenderGeneration or c.layer_material~=c.materialID or c.layer_material_style~=c.materialStyle then
          lowerPanels[panel]=true;s.dock_raise_epoch=nil
        end
        c.layer_icons=c.iconRenderGeneration;c.layer_material=c.materialID;c.layer_material_style=c.materialStyle
        local warning=c.visualState and c.visualState.lowHealth==true
        local warningStyle=s.controller.config.options.indicators.health_style
        if c.layer_warning~=warning or c.layer_warning_style~=warningStyle then lowerPanels[panel]=true end
        c.layer_warning=warning;c.layer_warning_style=warningStyle
      end
    else for _,c in ipairs(s.cells)do c.row=nil;c.rect=nil;show(c.root,false)end end
    s.last_hover_key=overKey
    local hit=s.hover_rect
    if s.pointer_pressed or s.settings_open or s.aux_drag or s.member_drag then s.hover.leave()else
      s.hover.update(overRow,B.now(api),function()
        if not hit or s.hover_rect~=hit then return false end
        local ok,x,y=B.mouse(api,owner_alive)
        return ok and B.finite(x)and B.finite(y)and x>=hit.x and x<hit.x+hit.w and y>=hit.y and y<hit.y+hit.h
      end,overKey,false)
    end
    if not s.active or not s.visible or not s.root then s.painting=false;return false end
    for _,c in ipairs(s.cells)do if c.used~=s.paint_count or not framesShown then c.row=nil;c.rect=nil;show(c.root,false)end end
    for _,panel in ipairs({"main","priority"})do
      if lowerPanels[panel]and owner_alive()then call(panel=="priority"and s.priority_root or s.root,"Lower")end
    end
    s.refresh_options(v,w,h)
    if owner_alive()then s.paint_tour(w,h,visualNow)end
    if owner_alive()then s.paint_overlays(v.data.rows,w,h,visualNow)end
    if owner_alive()and s.manager_help_open then call(s.manager_tip,"Raise")end
    s.repair_dock(managerEnabled,dx,dy)
    s.painting=false
    if s.failed then s.fault();return false end
    return true
  end
  function s.hide()
    s.profile_share=nil;s.profile_load=nil;s.alert_warning=nil
    s.stop_tour()
    if s.member_drag then s.end_member_drag(false,true)end
    cancel_colour()
    cancel_reset()
    trace_call("stop","hidden");local _,capture=trace_call("captureId");s.trace_auto_attempt=capture
    if localMarker then localMarker.invalidate()end
    cancel_input();s.manager_help_open=false;s.auraModel.clear();s.last_aura=nil
    feedback_call("cancel")
    probe_call("stop")
    s.compact_notice=false
    s.pointer_cell=nil;s.pointer_pressed=false
    if not s.end_drag(true)or not s.end_settings_drag(true)then s.fault();return end
    if not s.active then return end
    if not s.end_aux_drag(false)then s.fault();return end
    s.visible=false;s.settings_open=false;s.hide_markers();show(s.priority_reset_root,false);show(s.priority_root,false);show(s.raid_alert_root,false);show(s.marker_menu_root,false);show(s.settings_tip,false);show(s.manager_tip,false);show(s.options,false);show(s.dock_root,false);show(s.root,false)
    -- Keep live sampling active, without rendering or creating widgets while hidden.
  end
  function s.fault()
    if not s.active then return end
    -- Only an internal fixed operation name, never raw errors or member values.
    B.log(api,"UI operation failed ["..(s.first_failure or "callback").."]. This panel has been stopped; native frames are unchanged.")
    s.close()
  end
  function s.tick()
    if not s.active then return end
    local now=B.now(api)
    if s.aux_drag and s.aux_drag.kind=="dock"then
      local ok,shift=call(B.member(api,"Input"),"IsShiftKeyDown")
      if ok and shift==false then finish_drag()end
    end
    trace_call("clock",now)
    local _,needsSave=trace_call("needsSave");local _,capture=trace_call("captureId")
    if needsSave and capture~=s.trace_auto_attempt and owner_alive()and s.visible then
      s.trace_auto_attempt=capture;save_trace()
    end
    if not now then
      cancel_input()
      feedback_call("cancel")
      probe_call("stop")
      if s.last_tick~=false then
        s.last_tick=false
        if s.controller.mode=="live" then s.controller.live=s.live.unavailable("CLOCK_UNAVAILABLE") end
        if s.visible then s.refresh() end
      end
      return
    end
    s.restore_hover_intent(now);s.restore_native_preference(now)
    if s.tour_step and s.tour_anchor then s.animate_tour(now)end
    if localMarker and localMarker.active()then
      s.marker_frame=(s.marker_frame or 0)+1
      local plan=s.last_plan
      local function markerReady()return owner_alive()and s.visible and s.controller.mode=="live"and s.last_plan==plan and plan~=nil end
      if markerReady()then
        local iface=B.member(api,"Interface")
        local wok,w=call(iface,"GetScreenWidth")
        if markerReady()then
          local hok,h=call(iface,"GetScreenHeight")
          if wok and hok and B.finite(w)and B.finite(h)and markerReady()then
            localMarker.follow(plan.data.rows,now,w,h,s.marker_frame,false,markerReady)
            if markerReady()then s.paint_marker(plan.data.rows,w,h,now)
            else localMarker.invalidate();s.hide_markers()end
          else localMarker.invalidate();s.hide_markers()end
        else localMarker.invalidate();s.hide_markers()end
      else localMarker.invalidate();s.hide_markers()end
    end
    -- One pending name-only reconciliation on the next driver frame; selection
    -- itself already happened synchronously. Never wait for the render throttle.
    feedback_call("tick")
    if s.dock_repair_pending and owner_alive()and s.visible then
      s.dock_repair_pending=nil;s.dock_repair_serial=(s.dock_repair_serial or 0)+1
      s.repair_dock()
    end
    if s.text_drag then s.text_drag_point()end
    if probe and not probe_tick_failed then
      local ok=probe_call("tick")
      if not ok then probe_tick_failed=true;probe_call("stop") end
    end
    if not s.active then return end
    if type(s.last_tick)=="number" and now>=s.last_tick and now-s.last_tick<100 then return end
    s.last_tick=now
    if s.controller.mode=="live" then s.sample_live(false) end
    if s.visible then s.refresh() end
    if returnTarget and returnTarget.active()and s.controller.config.options.input.return_target and s.hover.armed then
      local function outside()
        if not owner_alive()or not s.visible or s.settings_open or s.dragging or s.aux_drag or s.painting
          or s.controller.mode~="live"or s.controller.config.visibility.frames==false then return false end
        local v=s.last_plan;if not v or not v.grid then return false end
        local ok,x,y=B.mouse(api,owner_alive);if not ok then return false end
        local function inside(grid,ox,oy)
          local left,top,right,bottom
          for _,r in ipairs(grid.cells)do left=left and math.min(left,ox+r.x)or ox+r.x;top=top and math.min(top,oy+r.y)or oy+r.y;right=right and math.max(right,ox+r.x+r.width)or ox+r.x+r.width;bottom=bottom and math.max(bottom,oy+r.y+r.height)or oy+r.y+r.height end
          return left and x>=left and x<right and y>=top and y<bottom
        end
        return not inside(v.grid,v.x,v.y)and not(v.priority and inside(v.priority.grid,v.priority.x,v.priority.y))
      end
      if outside()and returnTarget.finish(s.last_plan.data.rows,outside)and owner_alive()and s.visible then
        s.dock_repair_serial=(s.dock_repair_serial or 0)+1;s.dock_repair_pending=true;s.repair_dock()
      end
    end
  end
  local function first_tour()
    if not s.first_use_tour or s.tutorial_checked or not owner_alive()or not s.visible then return end
    s.tutorial_checked=true
    if s.storage.tutorialSeen(owner_alive)~=false or not owner_alive()or not s.visible then return end
    local enabled=s.hover_enabled or s.hover.armed
    cancel_input()
    if not owner_alive()or not s.visible then return end
    s.hover_enabled=enabled;s.settings_open=true
    s.step_tour("quick_tour")
    if s.refresh()and owner_alive()and s.visible and s.tour_step
      and s.tour_root and s.cache[s.tour_root]and s.cache[s.tour_root].Show==true then
      if not s.storage.rememberTutorialSeen(owner_alive)and owner_alive()then
        s.studio_notice="The tour could not be remembered. It may appear again next time."
      end
    end
  end
  function s.open()
    if not s.active then return false end
    if s.built then
      s.dock_repair_serial=(s.dock_repair_serial or 0)+1
      s.visible=true
      if s.controller.mode=="live" then s.sample_live(true) end
      show(s.root,true);local ready=s.refresh()
      if ready then local now=B.now(api);s.restore_hover_intent(now);s.restore_native_preference(now)end
      if ready then first_tour()end
      if not owner_alive()then return false end
      return ready
    end
    -- Without release support, refuse to allocate a panel that cannot be cleaned up.
    if type(B.member(iface,"Free"))~="function" then
      B.log(api,"Widget cleanup is unavailable; no panel created.");return false
    end
    local w,h=B.extent(api)
    if w<680 or h<400 then B.log(api,"This basic panel requires at least 680 x 400.");return false end
    s.root=empty("panel");if not s.root then return false end
    s.options=empty("settings");if not s.options then return false end
    s.settings_header=widget("button","settings_drag",s.options)
    if not s.settings_header then return false end
    call(s.settings_header,"EnablePick",true);call(s.settings_header,"Clickable",true)
    if type(B.member(s.options,"StartMoving"))=="function"and type(B.member(s.options,"StopMovingOrSizing"))=="function"then
      local enabled,value=call(s.settings_header,"EnableDrag",true)
      if enabled and value~=false then
        critical(s.settings_header,"SetHandler","OnDragStart",function()
          if not owner_alive()or not s.visible or not s.settings_open or s.settings_moving then return end
          cancel_colour();s.ordering_menu=nil;if s.studio then show(s.studio.orderingMenuRoot,false)end;s.settings_moving=true;show(s.settings_tip,false)
          local ok,result=call(s.options,"StartMoving")
          if not ok or result==false then if not s.end_settings_drag(false)then s.fault()end end
        end)
        local function stop()
          if not s.active or not s.settings_moving or s.stopping_settings_drag then return end
          if not s.end_settings_drag(true)then s.fault();return end
          s.refresh()
        end
        critical(s.settings_header,"SetHandler","OnDragStop",stop)
        critical(s.settings_header,"SetHandler","OnDragEnd",stop)
      end
    end
    s.group_labels={};s.settings_open=false
    s.empty_label=label("empty",s.root,12)
    s.studio=Studio.new({label=label,drawable=drawable,place=place,text=text,show=show,colour=colour,call=call,bindProfile=bind_profile,bindEffect=bind_effect,dragHandle=s.settings_header,
      surface=button,bindColour=bind_colour,bindPicker=bind_picker,
      bindOrdering=bind_ordering,bindOrderingChoice=bind_ordering_choice,orderingMenuInput=function(active)s.set_ordering_menu_input(active)end,
      orderingMenuRoot=function(id)local o=empty(id);if o then call(o,"EnablePick",true);call(o,"Clickable",true)end;return o end,
      orderingCell=function(id,parent)
        local o=widget("button",id,parent)
        if o then call(o,"EnablePick",true);call(o,"Clickable",true);call(B.member(o,"style"),"SetFontSize",11);call(B.member(o,"style"),"SetEllipsis",true);s.buttons[id]=o end
        return o
      end,
      sampleRoot=function(id,parent)
        local o=widget("window",id,parent)
        if o then call(o,"EnablePick",false);call(o,"Clickable",false)end
        return o
      end,
      wheelImage=function(parent)
        local ok,o=call(parent,"CreateImageDrawable","Addon/Mazrim_Raid_Frames/assets/colour-wheel.dds","background")
        if not owner_alive()then if ok and o then call(o,"Show",false)end;return nil end
        if not ok or not o then return nil end
        local good,v=call(o,"SetCoords",0,0,512,512)
        if not good or v==false or not owner_alive()then call(o,"Show",false);return nil end
        call(o,"SetColor",1,1,1,1);return o
      end,
      button=button,buttons=s.buttons,enable=enable,editText=function(o,v)
        if s.cache[o]then s.cache[o].SetText=nil end;text(o,v)
      end,edit=function(id,parent)
        local fn=B.member(W_CTRL,"CreateEdit");if type(fn)~="function"then return nil end
        local ok,o=pcall(fn,"maz_raid_studio_"..id,parent);if not ok or not o then return nil end
        own(o);call(B.member(o,"style"),"SetFontSize",12);call(o,"SetText","");return o
      end,
      tooltip=function(tip,x,y,w,h,scale)
        if not tip or s.text_drag or not owner_alive()or not s.visible or not s.settings_open then
          s.settings_tip_ticket=nil;show(s.settings_tip,false);return
        end
        local ticket={};s.settings_tip_ticket=ticket
        local studio,config,epoch,page,section=s.studio,s.controller.config,s.input_epoch,s.studio.page,s.studio.section
        local function current()
          return s.settings_tip_ticket==ticket and owner_alive()and s.visible and s.settings_open
            and not s.settings_moving and not s.dragging and not s.colour_picker and not s.reset_pending
            and s.studio==studio and s.controller.config==config and s.input_epoch==epoch
            and studio.page==page and studio.section==section
        end
        if not s.settings_tip then
          s.settings_tip=empty("settings_tip");if not s.settings_tip then return end
          call(s.settings_tip,"EnablePick",false);call(s.settings_tip,"Clickable",false)
          s.settings_tip_edge=drawable(s.settings_tip,0.5686,0.5176,0.4392,1)
          s.settings_tip_fill=drawable(s.settings_tip,0.1294,0.1137,0.0980,1)
          s.settings_tip_lines={}
        end
        if not current()then return end
        local tipWindow=s.settings_tip
        -- Native labels are single-line surfaces. Publish each wrapped line on
        -- its own pooled label instead of relying on embedded newline layout.
        local lines={}
        scale=scale or 1
        local function px(v)return math.floor(v*scale+.5)end
        local width=math.min(px(316),w-16);local titleCount,height
        local layoutKey=tip.title.."\0"..tip.text.."\0"..width..":"..h..":"..scale
        local retained=s.settings_tip_layout
        if retained and retained.key==layoutKey then
          lines=retained.lines;width=retained.width;height=retained.height;titleCount=retained.titleCount
        else
          -- GetTextWidth(text) is used by the native role/menu widgets. Measure
          -- only a new explanation/viewport, then reuse the wrapped result on
          -- stationary updates. Missing native metrics use a bounded estimate.
          if not s.settings_tip_measure then
            s.settings_tip_measure=label("settings_tip_measure",tipWindow,px(11));show(s.settings_tip_measure,false)
          end
          local measureStyle=B.member(s.settings_tip_measure,"style")
          local nativeMetrics=true;local measured={};local measureSize
          local function estimate(value,size)
            local units=0
            for i=1,#value do
              local ch=value:sub(i,i)
              units=units+(ch==" "and .32 or ch:find("[ilI%.,:;!'|]")and .31
                or ch:find("[mwMW@#%%&]")and .94 or ch:find("[A-Z]")and .7 or .58)
            end
            return units*size
          end
          local function textWidth(value,size)
            local key=size..":"..value
            if measured[key]then return measured[key]end
            local extent
            if nativeMetrics and current()then
              if measureSize~=size then call(measureStyle,"SetFontSize",size);measureSize=size end
              if current()then
                local ok,result=call(measureStyle,"GetTextWidth",value)
                if ok and B.finite(result)and result>0 then extent=result else nativeMetrics=false end
              end
            end
            extent=extent or estimate(value,size);measured[key]=extent;return extent
          end
          local function wrap(value,limit,size,step)
            local first=#lines+1;local line=""
            local function emit()if line~=""then lines[#lines+1]={text=line,size=size,step=step};line=""end end
            for word in value:gmatch("%S+")do
              if #line>0 and textWidth(line.." "..word,size)>limit then emit()end
              while #word>1 and textWidth(word,size)>limit do
                local take=1
                while take<#word and textWidth(word:sub(1,take+1),size)<=limit do take=take+1 end
                line=word:sub(1,take);emit();word=word:sub(take+1)
              end
              if word~=""then line=line==""and word or line.." "..word end
            end
            emit()
            -- Avoid a lone short word occupying the last line of a paragraph.
            if #lines>first then
              local previous,last=lines[#lines-1],lines[#lines]
              while textWidth(last.text,size)<textWidth(previous.text,size)*.42 do
                local head,tail=previous.text:match("^(.*)%s+(%S+)$")
                if not head or head==""or textWidth(tail.." "..last.text,size)>limit then break end
                previous.text=head;last.text=tail.." "..last.text
              end
            end
          end
          local function layout()
            lines={}
            wrap(tip.title,math.max(1,width-px(24)),px(12),px(20));titleCount=#lines
            wrap(tip.text,math.max(1,width-px(24)),px(11),px(18))
            height=px(20);for _,line in ipairs(lines)do height=height+line.step end
          end
          layout()
          -- Widen long explanations before placing them; fonts stay unchanged.
          if height>h-16 then width=w-16;layout()end
          local used=0
          for _,line in ipairs(lines)do used=math.max(used,textWidth(line.text,line.size))end
          width=math.min(width,math.max(px(160),math.ceil(used)+px(24)))
          if not current()then return end
          s.settings_tip_layout={key=layoutKey,lines=lines,width=width,height=height,titleCount=titleCount}
        end
        local tx=math.max(8,math.min(x,w-width-8));local ty=math.max(8,math.min(y,h-height-8))
        place(tipWindow,"UIParent",tx,ty,width,height)
        place(s.settings_tip_edge,tipWindow,0,0,width,height);place(s.settings_tip_fill,tipWindow,1,1,width-2,height-2)
        local yy=px(8)
        for i,line in ipairs(lines)do
          if not current()then return end
          local row=s.settings_tip_lines[i]
          if not row then row=label("settings_tip_line_"..i,tipWindow,line.size);s.settings_tip_lines[i]=row end
          call(B.member(row,"style"),"SetEllipsis",true)
          call(B.member(row,"style"),"SetFontSize",line.size)
          place(row,tipWindow,px(10),yy,width-px(20),line.step);text(row,line.text);show(row,true)
          yy=yy+line.step;if i==titleCount then yy=yy+px(4)end
        end
        for i=#lines+1,#s.settings_tip_lines do show(s.settings_tip_lines[i],false)end
        if not current()or s.settings_tip~=tipWindow then return end
        local key=tip.title..tip.text..s.input_epoch
        if s.settings_tip_key~=key or not s.cache[tipWindow]or s.cache[tipWindow].Show~=true then
          s.settings_tip_key=key;call(tipWindow,"Raise")
        end
        if not current()or s.settings_tip~=tipWindow then
          if s.settings_tip_ticket==nil or s.settings_tip_ticket==ticket then show(tipWindow,false)end
          return
        end
        show(tipWindow,true)
        if not current()or s.settings_tip~=tipWindow then
          if s.settings_tip_ticket==nil or s.settings_tip_ticket==ticket then show(tipWindow,false)end
        end
      end,
      editChrome=function(o)
        if not owner_alive()then return end
        local c=s.cache[o];if not c or not c.w or not c.h then return end
        if not o.studio_edge then
          o.studio_edge=drawable(o,0.5686,0.5176,0.4392,1)
          if not owner_alive()then return end
          o.studio_fill=drawable(o,0.0902,0.0784,0.0627,1)
        end
        if not owner_alive()then return end
        place(o.studio_edge,o,0,0,c.w,c.h);place(o.studio_fill,o,1,1,c.w-2,c.h-2)
        colour(B.member(o,"style"),0.9490,0.9137,0.8353,1)
      end,
      toggleButton=function(o,active,caption)
        local bg=B.member(o,"studio_bg");local c=s.cache[o]
        if bg and c then place(bg,o,0,0,c.w,c.h)end
        paint_button_chrome(o,active,"toggle",caption)
      end,
      buttonColour=function(o,active)
        local bg=B.member(o,"studio_bg");local c=s.cache[o]
        if bg and c then place(bg,o,0,0,c.w,c.h);colour(bg,active and 0.2667 or 0.1882,active and 0.2235 or 0.1686,active and 0.1647 or 0.1412,1)end
        paint_button_chrome(o,active)
      end,
      chromeFrame=function(parent,w,h,bg,header,scale)
        if not owner_alive()then return end
        local key=string.format("%s/%s",w,h)
        if s.chrome_frame_key==key then return end
        s.chrome_frame_key=key;s.chrome_frame_w=w;s.chrome_frame_h=h
        if not s.chrome_frame then
          s.chrome_frame=s.chrome.frame(parent,function()return s.chrome_frame_w,s.chrome_frame_h end,math.floor(62*(scale or 1)+.5),{bg,header})
        else s.chrome_frame.paint()end
      end,
      previewCreate=function(id,parent)
        renderer_ui.parent=parent;local c=R.create(id,renderer_ui)
        if c then call(c.input,"EnablePick",false);call(c.input,"Clickable",false)end
        return c
      end,
      previewShow=function(c,v)if c then show(c.root,v)end end,
      appearancePreview=function(c,x,y,w,h,index,options,settings)
        if not c or not owner_alive()or not s.settings_open then return end
        options=type(options)=="table"and options or{}
        settings=type(settings)=="table"and settings or{}
        local samples={{"Tank","Defiler","tank"},{"Mage","Animist","damage"},{"Ranged","Warpriest","damage"},
          {"Melee","Paladin","damage"},{"Healer","Templar","healer"}}
        local number=type(index)=="number"and index>=1 and math.floor(index)or 1
        local kind=(number-1)%10+1;local sample=samples[(number-1)%5+1]
        local indicators=type(options.indicators)=="table"and options.indicators or{}
        local health=kind==2 and math.max(1,math.floor((indicators.health_threshold or 25)*.6))or(kind==1 and 100 or 68)
        local mana=kind==2 and math.max(1,math.floor((indicators.mana_threshold or 20)*.6))or 75
        local row={kind="preview",name=sample[1].." "..number,classKnown=true,className=sample[2],
          roleKnown=true,role=sample[3],selfKnown=true,isSelf=kind==1,
          health={known=true,current=health,maximum=100},mana={known=true,current=mana,maximum=100}}
        if kind==1 then row.name="You";row.authorityKnown=true;row.authority="leader"
        elseif kind==3 then
          local range=type(options.range)=="table"and options.range or{}
          row.rangeKnown=true;row.outOfRange=true;row.distanceM=(range.distance or 30)+10
        elseif kind==6 then row.name="Offline";row.offlineKnown=true;row.offline=true
        elseif kind==7 then row.name="Unknown";row.classKnown=false;row.className=nil;row.roleKnown=false;row.role=nil;row.health={known=false};row.mana={known=false}end
        local scope={contract=1,preview=true,items={}}
        if kind==2 then
          local prefs=type(options.auras)=="table"and options.auras or{}
          local priorities=type(prefs.priorities)=="table"and prefs.priorities or{}
          local ids={}
          local iconsEnabled=prefs.hots~=false or prefs.debuffs~=false
          for id,selected in pairs(iconsEnabled and type(prefs.watch)=="table"and prefs.watch or{})do
            if selected==true and Watch.id(id)then
              local at=#ids+1;local priority=priorities[id]or 0
              while at>1 do
                local other=ids[at-1];local before=priority>(priorities[other]or 0)
                  or(priority==(priorities[other]or 0)and(#id<#other or(#id==#other and id<other)))
                if not before then break end;ids[at]=other;at=at-1
              end
              ids[at]=id
            end
          end
          for i=1,math.min(6,#ids)do
            scope.items[i]={id=ids[i],kind=prefs.hots==false and"debuff"or"buff",observed=true,
              icon="Addon/Mazrim_Raid_Frames/assets/sample-effect.dds",remaining=12+(i-1)*7}
          end
          -- Reuse only metadata already in memory. The example never enriches
          -- the library or claims any live member has one of these effects.
          scope=s.effectLibrary.decorate(scope)
          local chosen,chosenID
          for id,rule in pairs(type(prefs.frame_rules)=="table"and prefs.frame_rules or{})do
            if rule.enabled==true and Colours.rgb(rule.colour)and(not chosen or rule.priority>chosen.priority
              or(rule.priority==chosen.priority and(#id<#chosenID or(#id==#chosenID and id<chosenID))))then chosen=rule;chosenID=id end
          end
          if chosen then
            local ink=Colours.rgb(chosen.colour)
            scope.tint={id=chosenID,kind=chosen.kind=="buff"and"buff"or"debuff",observed=true,
              material=chosen.material,colour={ink[1],ink[2],ink[3]},remaining=12}
          end
        end
        if not owner_alive()or not s.settings_open then return end
        renderer_ui.parent=s.options
        local drawing=options
        if s.text_drag and text_editor_current(s.text_drag.editor)then
          drawing={};for key,value in pairs(options)do drawing[key]=value end
          drawing[s.text_drag.section]=s.text_drag.draft
        end
        R.paint(c,row,{x=x,y=y,width=w,height=h},settings,kind==4,renderer_ui,drawing,
          {preview=true,selected=kind==1,auras=scope})
        -- R.create shares the live renderer's widget recipe. Its sample root
        -- remains inert even after native texture/geometry changes.
        call(c.input,"EnablePick",false);call(c.input,"Clickable",false)
      end,
      textEditorVisible=function(visible)
        if not visible then s.cancel_text_drag();s.text_editor=nil;show(s.text_editor_input,false)end
      end,
      textEditor=function(previews,geometry,options,settings)
        if not owner_alive()or not s.settings_open then return nil end
        local config=s.controller.config;local old=s.text_editor
        local section=editor_location()
        local key=geometry.key or""
        for _,f in ipairs(geometry.frames)do key=key..string.format("/%s/%s/%s/%s/%s",f.x,f.y,f.w,f.h,f.cell.nativeID or"")end
        local same=old and old.key==key and old.section==section and old.config==config and old.options==options and old.revision==s.controller.revision
        if not same then
          s.cancel_text_drag();old={key=key,section=section,config=config,options=options,revision=s.controller.revision};s.text_editor=old
        end
        old.stage=geometry.stage;old.frames=geometry.frames;old.allowIcons=geometry.allowIcons~=false
        if not s.text_editor_input then s.text_editor_input=widget("button","text_editor_input",s.options);s.buttons.text_editor_input=s.text_editor_input end
        if s.text_editor_input then
          local parent=s.cache[s.options];local stage=geometry.stage
          place(s.text_editor_input,s.options,stage.x-(parent and parent.x or 0),stage.y-(parent and parent.y or 0),stage.w,stage.h)
          bind_text_editor(s.text_editor_input)
        end
        return s.text_editor_input
      end,
      effectLayoutPreview=function(c,frame,options,display,ids)
        if not c or not owner_alive()or not s.settings_open then return end
        local drawing={}
        for key,value in pairs(options)do drawing[key]=value end
        local drag=s.text_drag
        if drag and text_editor_current(drag.editor)then drawing[drag.section]=drag.draft end
        drawing.appearance={}
        for key,value in pairs(options.appearance)do drawing.appearance[key]=value end
        drawing.appearance.show_distance=true
        drawing.auras={hots=true,debuffs=true}
        local exampleDisplay={}
        for key,value in pairs(display)do exampleDisplay[key]=value end
        exampleDisplay.show_names=true
        if exampleDisplay.health_text=="none"then exampleDisplay.health_text="percent"end
        local items={}
        local count=#ids>0 and #ids or 3
        for n=1,count do
          items[n]={id=ids[n]or string.format("%d",n),kind="buff",
            icon="Addon/Mazrim_Raid_Frames/assets/sample-effect.dds",observed=true,remaining=12+n*7}
        end
        local scope={contract=1,preview=true,items=items}
        if #ids>0 then scope=s.effectLibrary.decorate(scope)end
        renderer_ui.parent=s.options
        R.paint(c,{kind="preview",name="You",classKnown=true,className="Paladin",
          roleKnown=true,role="damage",selfKnown=true,isSelf=true,rangeKnown=true,distanceM=18,
          health={known=true,current=80,maximum=100},mana={known=true,current=75,maximum=100}},
          {x=frame.x,y=frame.y,width=frame.w,height=frame.h},exampleDisplay,false,renderer_ui,drawing,
          {preview=true,auras=scope})
        call(c.input,"EnablePick",false);call(c.input,"Clickable",false)
      end,
      effectPreview=function(c,x,y,w,h,options,display,detail)
        if not c or not owner_alive()or not s.settings_open then return end
        local scope={contract=1,preview=true,items={}}
        local rule=detail.rule
        local kind=detail.kindCode=="debuff"and"debuff"or"buff"
        if detail.kindCode~="buff" and detail.kindCode~="debuff" and rule and rule.kind=="debuff"then kind="debuff"end
        if detail.iconEnabled then
          scope.items[1]={id=detail.id,kind=kind,observed=true,remaining=12,
            icon=detail.icon or"Addon/Mazrim_Raid_Frames/assets/sample-effect.dds"}
        end
        if rule and rule.enabled then
          local rgb=Colours.rgb(rule.colour)
          if rgb then
            scope.tint={id=detail.id,kind=rule.kind=="buff"and"buff"or"debuff",observed=true,
              material=rule.material,colour={rgb[1],rgb[2],rgb[3]},remaining=12}
          end
        end
        renderer_ui.parent=s.options
        R.paint(c,{kind="preview",name="Raid member",roleKnown=true,role="tank",
          health={known=true,current=92,maximum=100},mana={known=true,current=75,maximum=100}},
          {x=x,y=y,width=w,height=h},display,false,renderer_ui,options,{preview=true,auras=scope})
        call(c.input,"EnablePick",false);call(c.input,"Clickable",false)
      end,
      materialPreview=function(c,x,y,w,h,options,display,material,parent)
        if not c or not owner_alive()or not s.settings_open then return end
        local drawing={};for key,value in pairs(options)do drawing[key]=value end
        drawing.aura_icons={max_visible=1};drawing.auras={hots=false,debuffs=false};drawing.indicators={}
        local ink=Colours.rgb(Materials.defaultColour(material));renderer_ui.parent=parent or s.options
        R.paint(c,{kind="preview",name=Materials.labels[material],roleKnown=true,role="tank",health={known=true,current=100,maximum=100},mana={known=true,current=75,maximum=100}},
          {x=x,y=y,width=w,height=h},display,false,renderer_ui,drawing,{preview=true,auras={contract=1,preview=true,items={},
            tint={id="1",kind="debuff",observed=true,material=material,colour={ink[1],ink[2],ink[3]},remaining=12}}})
        call(c.input,"EnablePick",false);call(c.input,"Clickable",false)
      end,
      healthPreview=function(c,x,y,w,h,name,hp,options,warn)
        if not c then return end
        renderer_ui.parent=s.options
        local prefs=options.indicators
        R.paint(c,{kind="preview",name=name,roleKnown=true,role="tank",health={known=true,current=hp,maximum=100},mana={known=true,current=75,maximum=100}},
          {x=x,y=y,width=w,height=h},{show_names=true,show_mana=true,health_text="none",font_size=11},false,renderer_ui,
          {appearance=options.appearance,colours=options.colours,range={enabled=false},indicators={low_health=warn,health_threshold=prefs.health_threshold,health_style=prefs.health_style,hatch_mode=prefs.hatch_mode,hatch_opacity=prefs.hatch_opacity}}, {preview=true})
      end,
      previewPaint=function(c,theme,x,y,w,h,role,scale)
        if not c then return end
        renderer_ui.parent=s.options
        R.paint(c,{kind="preview",name="Serenity",roleKnown=true,role=role,
          health={known=true,current=68,maximum=100,fraction=0.68},mana={known=true,current=24,maximum=100,fraction=0.24}},
          {x=x,y=y,width=w,height=h},{show_names=true,show_mana=true,health_text="none",font_size=math.floor(11*(scale or 1)+.5)},false,renderer_ui,
          {appearance={mode=theme=="native"and"native"or"custom",theme=theme=="native"and"lumen"or theme},indicators={},range={enabled=false}}, {})
      end},s.options)
    s.dock_root=empty("raid_controls_dock")
    button("cog",s.dock_root)
    -- Native BUTTON_HUD isn't exported; use its documented skin-data shape and
    -- exact ROAD_MAP_OPTION atlas recipe (basic_style.lua3761-3774).
    local hud=B.member(TEXTURE_PATH,"HUD")
    if type(hud)~="string" then s.failed=true else
      critical(iface,"ApplyButtonSkin",s.buttons.cog,{drawableType="drawable",path=hud,
        coords={normal={624,215,22,22},over={646,215,22,22},click={624,237,22,22},disable={646,237,22,22}},
        width=22,height=22})
    end
    text(s.buttons.cog,"")
    local managerButton=button("manager_shortcut",s.dock_root)
    text(managerButton,"")
    call(managerButton,"EnablePick",true);if not owner_alive()then return false end
    call(managerButton,"Clickable",true);if not owner_alive()then return false end
    s.manager_crest={}
    local function edge(value)return math.floor(value*26/28+0.5)end
    for i=1,#CREST_RECTS do
      local r=CREST_RECTS[i];local ink=CREST_PALETTE[r[5]]
      local piece=drawable(managerButton,ink[1],ink[2],ink[3],1);s.manager_crest[i]=piece
      local x,y= edge(r[1]),edge(r[2])
      place(piece,managerButton,x,y,edge(r[1]+r[3])-x,edge(r[2]+r[4])-y)
    end
    s.manager_tip=empty("manager_tip")
    call(s.manager_tip,"EnablePick",true);call(s.manager_tip,"Clickable",true)
    s.manager_background=drawable(s.manager_tip,0.1294,0.1137,0.0980,0.98)
    place(s.manager_background,s.manager_tip,0,0,340,258);show(s.manager_tip,false)
    for _,entry in ipairs({{"hud_hover","Toggle hover healing"},{"hud_manager","Open raid management"},{"hud_native","Hide / Return original raid frames"},{"hud_addon","Hide / Return addon frames"},{"hud_sort","Raid order: Original"},{"hud_reset","Reset member positions"}})do
      local o=button(entry[1],s.manager_tip);text(o,entry[2])
    end
    for _,o in ipairs({s.buttons.cog,managerButton})do
      replace_handler(o,"OnMouseDown",function()if not s.aux_drag and not s.dragging and not s.member_drag then s.drag_click_block=nil;s.dock_click_block=nil end end)
      bind_aux(o,s.dock_root,"dock")
      call(o,"RegisterForClicks","LeftButton",true)
    end
    local rootDragReady=true
    if type(B.member(s.root,"EnableDrag"))=="function" then
      local ok,r=call(s.root,"EnableDrag",true);rootDragReady=ok and r~=false
    end
    local handleReady=true
    s.drag_ready=rootDragReady and handleReady
    critical(s.root,"SetHandler","OnMouseUp",finish_drag)
    s.driver=empty("driver")
    place(s.driver,"UIParent",0,0,1,1);call(s.driver,"EnablePick",false);show(s.driver,true)
    critical(s.driver,"SetHandler","OnUpdate",function()
      if not s.active then return end
      local ok=pcall(s.tick);if not ok or s.failed then s.fault() end
    end)
    -- Optional event wake-up on the same owned driver. Never use payload IDs as
    -- roster identities. ReleaseHandler + Free use the existing cleanup path.
    local driver=s.driver
    local register=B.member(driver,"RegisterEvent");local release=B.member(driver,"ReleaseHandler");local attach=B.member(driver,"SetHandler")
    if owner_alive()and s.driver==driver and not s.failed and type(register)=="function"and type(release)=="function"and type(attach)=="function"then
      s.handlers[driver][#s.handlers[driver]+1]="OnEvent"
      local attached,value=pcall(attach,driver,"OnEvent",function(_,event,channel,targetType,_,sender,message)
        if event=="CHAT_MESSAGE"then
          if s.profile_share and s.profile_share.wait then pcall(s.receive_profile_chat,channel,sender,message)end
          return
        end
        if not s.target_events_ready or event~="TARGET_CHANGED"or not owner_alive()or not s.visible then return end
        trace_record("TARGET_EVENT",{targetType=targetType,painting=s.painting==true})
        -- A delayed native selection may rebuild picking after Click returned.
        -- Repair once per event; the ordinary render timer does no extra work.
        s.dock_repair_serial=(s.dock_repair_serial or 0)+1
        s.target_dirty=true
        local ok=pcall(s.refresh);if not ok or s.failed then s.fault()end
      end)
      if attached and value~=false and owner_alive()and s.driver==driver then
        s.profile_chat_attached=true
        local registered,result=pcall(register,driver,"TARGET_CHANGED")
        s.target_events_ready=registered and result~=false and owner_alive()
      end
    end
    if not owner_alive()or s.driver~=driver then return false end
    critical(s.root,"SetHandler","OnHide",function()if s.active and s.visible then s.hide() end end)
    if s.failed then return false end
    s.built=true;s.visible=true;show(s.root,true);local ready=s.refresh()
    if ready then local now=B.now(api);s.restore_hover_intent(now);s.restore_native_preference(now)end
    if ready then first_tour()end
    if not owner_alive()then return false end
    return ready
  end
  function s.close()
    s.profile_share=nil;s.profile_load=nil;s.alert_warning=nil
    s.stop_tour()
    s.cancel_text_drag();s.text_editor=nil
    trace_call("close")
    if s.member_drag then s.end_member_drag(false,true)end
    cancel_colour()
    cancel_reset()
    if s.chrome then s.chrome.stop()end
    s.manager_help_open=false;s.hover_enabled=false;s.hover.disarm();s.hover_rect=nil
    feedback_call("cancel")
    probe_call("stop")
    s.pointer_cell=nil;s.pointer_pressed=false;s.painting=false
    if s.closing then return false end
    if not s.end_drag(false)or not s.end_settings_drag(false)or not s.end_aux_drag(false)then s.active=false;s.visible=false;s.cleanup_ok=false;return false end
    if not s.active and #s.owned==0 then return s.cleanup_ok end
    s.active=false;s.visible=false
    s.closing=true
    s.raidAlerts.reset()
    s.auraModel.close()
    s.effectLibrary.close();s.target_events_ready=false;s.target_dirty=false
    -- Release callbacks first; retain the unfreed prefix for explicit retry.
    local function hide_panel(panel)
      if not panel then return true end
      if s.effect_icons[panel]then return hide_icon(panel)end
      local ok,r=call(panel,"Show",false)
      return ok and r~=false
    end
    local contained=true
    for _,key in ipairs({"priority_reset_root","dock_root","manager_tip","tour_root","tour_arrow","options","root"})do
      local panel=s[key]
      if panel then call(panel,"EnablePick",false);call(panel,"Clickable",false);if not hide_panel(panel)then contained=false end end
    end
    for _,id in ipairs({"cog","manager_shortcut"})do
      local o=s.buttons[id]
      if o and s.handlers[o]then call(o,"EnablePick",false);call(o,"Clickable",false);if not hide_panel(o)then contained=false end end
    end
    if not contained then s.cleanup_ok=false;s.closing=false;return false end
    for i=#s.owned,1,-1 do
      local o=s.owned[i]
      local handlers=s.handlers[o]or{}
      for j=#handlers,1,-1 do
        local ok,r=call(o,"ReleaseHandler",handlers[j])
        if not ok or r==false then s.cleanup_ok=false;s.closing=false;return false end
        handlers[j]=nil
      end
      if not hide_panel(o)then s.cleanup_ok=false;s.closing=false;return false end
      local ok,value=call(iface,"Free",o)
      if not ok or value==false then s.cleanup_ok=false;s.closing=false;return false end
      -- A later failure must never make the retry touch a confirmed-freed panel.
      if o==s.tour_root then s.tour_root=nil end
      if o==s.tour_arrow then s.tour_arrow=nil end
      if o==s.options then s.options=nil end
      if o==s.root then s.root=nil end
      if o==s.driver then s.driver=nil end
      if o==s.manager_tip then s.manager_tip=nil end
      if o==s.dock_root then s.dock_root=nil end
      if o==s.priority_reset_root then s.priority_reset_root=nil end
      s.owned[i]=nil;s.handlers[o]=nil;s.effect_icons[o]=nil
    end
    s.cleanup_ok=true;s.closing=false;s.owned={};s.cells={};s.panel_cells=nil;s.cache={};s.root=nil;s.driver=nil;s.controller.live=nil
    return true
  end
  return s
end
return V
