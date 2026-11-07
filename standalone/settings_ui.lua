-- Shared-frame studio: bounded, reusable controls; no unit reads or file IO.
local Ordering=require("Mazrim_Raid_Frames/shared/ordering")
local T=require("Mazrim_Raid_Frames/shared/themes")
local P=require("Mazrim_Raid_Frames/shared/presentation")
local W=require("Mazrim_Raid_Frames/shared/watchlist")
local Colours=require("Mazrim_Raid_Frames/shared/colours")
local Picker=require("Mazrim_Raid_Frames/shared/colour_picker")
local Materials=require("Mazrim_Raid_Frames/shared/materials")
local ProfileShare=require("Mazrim_Raid_Frames/shared/profile_share")
local U={coveragePolicyContract=1,colourPickerContract=Picker.contract==1 and 1 or 0,alwaysShiftDragContract=1,tooltipLayerContract=1,overhaulContract=1,contract=1,controlsContract=2,raidManagementContract=1,hudManagementContract=2,effectBrowserContract=1,unifiedEffectsContract=1,selectedOnlyContract=1,targetTraceContract=1,nameRefreshModeContract=1,
 expandedStylesContract=T.expandedStylesContract==1 and 1 or 0,
 priorityContract=W.priorityContract==1 and 1 or 0}
local pages={{"appearance","Appearance"},{"layout","General Settings"},{"ordering","Layout Preset"},
  {"healing","Indicators"},{"effects","Buffs & Debuffs"},{"profiles","Profiles"},{"status","Advanced"}}
local copy={
 appearance={"Appearance","Original uses the game's role colours. Ellesmere uses your own colours.\nThe example updates as you change your settings."},
 ordering={"Layout Preset","Automatically sorts your raid into the slots you choose.\nOnly you see this layout—it doesn't change the raid's actual groups."},
 layout={"General Settings","Size and arrange your frames, set visibility and choose tracking options."},
 healing={"Indicators","Warnings use known readings. Unknown information stays unknown."},
 effects={"Buffs & Debuffs","Find an effect, then choose its icon, frame appearance or screen alert."},
 profiles={"Profiles","Save setups for different characters, groups and roles.\nYour hover targeting choice is kept separately."},
 status={"Data coverage","Optional checks to help when something isn't working."},
 known_issues={"Known issues","Game and API limits in this version."}}
local knownIssues={
 {"Wrong HP after switching",
  "The game's target frame can briefly show the new player's",
  "name with the previous player's HP."},
 {"Target jumps back",
  "Fast swaps can briefly select an earlier target again.",
  "This can also happen when clicking the original raid frames."},
 {"Distant HP and mana",
  "Our frames can show ? and an empty mana strip while the",
  "original raid frames still update those bars."},
 {"Missed or delayed effects",
  "Short or distant effects can be missed or show up late.",
  "A timer marked ~ is estimated from the last reading."},
 {"Who cast the buff",
  "An icon can show Resurgence from any healer. The addon",
  "can't tell which active Resurgence is yours."},
 {"Overhead symbols",
  "Only you can see your symbols. They can trail a player",
  "or disappear when the game can't report their position."},
 {"Returning to a target",
  "Hover targeting changes your game target. The optional",
  "return works only if your previous target was a raid member."}}
function U.new(ui,parent)
 -- Original control metrics; only the settings canvas grows.
 local s={page="appearance",section=1,totalPages=1,slot=1,rows={},labels={},panels={},previews={},materialPreviews={},built=false,previewCount=5,previewPage=1,previewPages=1}
 local all={}
 local helpRects={};s.edits={};s.effectSection="icons"
 local descriptions={
 return_target="Return to your previous raid target after your mouse leaves the frames when hover targets is on. Raid members only.",
 raid_tracker="Look for selected raid effects without changing your target. Some effects may be missed or delayed.",
 raid_scan_policy="Balance buff checks, or give debuffs more attention.",
 large_alerts="Pause or resume screen alerts for your chosen debuffs.",
 reset_raid_alerts="Let previously detected effects trigger alerts again.",
 move_raid_alert="Show an example, then Shift-drag it into place.",
 preview_count="Choose how many sample players to show.",
 preview_previous="Show the previous page of sample players.",preview_next="Show the next page of sample players.",
 text_reset_positions="Put names and health text back in their default positions.",
 addon_frames="Hide our raid frames. The cog stays available.",
 native_toggle="Hide or bring back the game's original raid frames.",
 raid_management="Open raid management. Right-click your name there for loot, dice and raid options.",
 preset="Choose a frame size preset.",layout="Choose how the frames are arranged.",
 frame_width="Change the frame width.",frame_height="Change the frame height.",spacing="Change the gap between frames.",
 font="Change the size of names and health text.",
 reset_layout="Restore the default size and position. You can confirm or undo it.",
 ind_target="Highlight the player you have selected.",ind_hover="Highlight the frame under your mouse.",
 ind_health="Show a warning when someone's health is low.",health_styles="Choose how the low-health warning looks.",health_threshold="Show the warning at or below this health percentage.",
 ind_mana="Show a marker when someone's mana is low.",mana_threshold="Show the marker at or below this mana percentage.",
 range="Fade players beyond this distance. Unknown distance stays unknown.",range_alpha="Choose how see-through distant frames become.",
 opacity="Make the frames more or less see-through.",health="Show health as a percentage, current HP or missing HP. Choose Off to hide the numbers.",mana="Show a thin mana bar below health.",
 show_distance="Show distance on frames when it is known.",
 hatch_mode="Mark missing health with stripes, a solid fill or both.",hatch_opacity="Choose how see-through the missing-health effect is.",
 hots="Show your selected buffs.",debuffs="Show your selected debuffs.",
 target_trace="Record a short targeting test to help investigate problems.",target_trace_save="Save this targeting test again.",
 resource_check="Check which health and mana readings the game provides.",
 raid_aura_member="Choose a raid member for this check.",raid_aura_run="Check this member's debuffs without targeting them.",
 appearance_role_icon="Show a small role icon beside each name.",
 theme_native="Use the game's original frame style and role colours.",theme_ellesmere="Use Ellesmere-style frames with your own colours.",
 appearance_design="Choose a frame style and how names and bars look.",appearance_colours="Choose colours for frames, names, bars and warnings.",
 rule_kind="Apply this rule to a buff, debuff, or either.",rule_material="Choose a colour or texture for this effect.",
 rule_priority="Choose which frame appearance wins when several effects are detected.",
 rule_enabled="Apply the selected colour or texture while this effect is detected.",
 rule_colour="Pick the colour for this frame effect.",rule_remove="Remove the saved frame appearance for this effect.",
 effect_watch_detail="Show this effect's icon and timer on the raid frame.",
 effect_priority_detail="Show higher-priority icons first when space is limited.",
 effect_alert_detail="Show a screen alert when the game reports this effect as a debuff.",
 icon_size="Change the icon size. Use 0 for automatic sizing.",icon_position="Choose which corner holds the icons.",
 icon_spacing="Change the gap between icons.",icon_count="Show up to this many icons. Small frames may fit fewer.",
 icon_timer="Set the largest timer text size. Long timers shrink to fit. ~ means estimated.",
 icon_grouped="Move the icons together, or give each selected effect its own position.",
 icon_reset_positions="Put the icons back in the selected corner. Both saved arrangements are cleared.",
 icon_editor_previous="Edit the previous selected effects.",icon_editor_next="Edit the next selected effects.",
 profile_name="Give this setup a name.",profile_store="Save your current setup under this name.",profile_slot="Choose a name for this setup.",
 profile_confirm_delete="Delete this saved setup.",profile_cancel_delete="Keep this saved setup.",
 ordering_slots="Choose where each class category belongs.",ordering_enabled="Place players using your preset. Manual moves take priority.",
 ordering_choice_auto="Remove this slot's exception and use its party category.",ordering_choice_cancel="Close these choices without changing anything.",
 save="Keep your changes for next time.",previous="Show the previous settings page.",next="Show the next settings page.",studio_more="Show the next settings page.",
 raid_previous="Show the previous page of raid members.",raid_next="Show the next page of raid members.",
 health_styles_back="Go back to the indicator settings.",
 health_style_outline="Use a thin outline for the low-health warning.",health_style_badge="Use a small badge for the low-health warning.",health_style_hatch="Mark the missing part of the health bar.",
 reset_accept="Keep the default layout.",reset_cancel="Restore your previous layout.",
 picker_white="Choose white.",picker_black="Choose black.",picker_use="Keep this colour.",picker_cancel="Restore your previous colour.",picker_hex="Enter a six-digit colour code."
 }
 local function dynamicHelp(id,title)
  if id:sub(1,13)=="colour_clear_"then return "Use the default colour again."end
  if id:sub(1,12)=="colour_pick_"then return "Pick the colour for "..title:lower().."."end
  if id:sub(1,13)=="profile_load_"then return "Load this setup and keep your separate hover targeting choice."end
  if id:sub(1,15)=="profile_delete_"then return "Delete this saved setup. You'll be asked to confirm."end
  if id:sub(1,16)=="ordering_choice_"then return "Use this class category for the selected party or slot."end
  if id:sub(1,4)=="tab_"then return "Open "..title:lower().." settings."end
 end
 local function help(id,title,x,y,w,h,detail)
  local body=detail or descriptions[id]or dynamicHelp(id,title)
  if not body then return end
  -- Only non-interactive setting labels register help. A cached glyph
  -- estimate avoids new native calls and excludes empty row/control space.
  s.helpMetrics=s.helpMetrics or{}
  local m=s.helpMetrics[id]
  if not m or m.title~=title then
   local units=0
   for n=1,#title do local b=string.byte(title,n)
    units=units+(b==32 and .34 or(b==105 or b==108 or b==73 or b==49 or b==46 or b==44)and .36
     or(b==77 or b==87 or b==109 or b==119)and .98 or .62)
   end
   m={title=title,width=math.ceil(units*12)};s.helpMetrics[id]=m
  end
  w=math.max(1,math.min(w,m.width+4))
  if body then helpRects[#helpRects+1]={x=x,y=y,w=w,h=h,title=title,text=body}end
 end
 local wanted={}
 local function display(o,value)if o then wanted[o]=value end end
 local function track(o)if o then all[#all+1]=o end;return o end
 local function label(id,size)return track(ui.label("studio_"..id,parent,size or 12))end
 local function box(r,g,b,a)return track(ui.drawable(parent,r,g,b,a or 1))end
 local function position(o,x,y,w,h)ui.place(o,parent,x,y,w,h)end
 local function button(id,x,y,w,h,text,enabled,accent)
  local o=ui.buttons[id]
  if not o then o=ui.button(id,parent);all[#all+1]=o end
  position(o,x,y,w,h);ui.enable(o,enabled~=false);display(o,true)
  local toggle=s.switchStates and s.switchStates[id]
  if type(toggle)=="boolean"and ui.toggleButton then
   ui.toggleButton(o,toggle,id=="addon_frames"and(toggle and"On"or"Off")or text)
  else ui.text(o,text);if ui.buttonColour then ui.buttonColour(o,accent==true)end end
  return o
 end
 local function line(id,value,x,y,w,h,size,muted,ellipsis)
  local o=s.labels[id]
  if not o then
   o=label(id,size)
   s.labels[id]=o
   if o and ellipsis then ui.call(o.style,"SetEllipsis",true)end
  end
  if not o then return nil end
  position(o,x,y,w,h or 20);ui.text(o,value);display(o,true)
  ui.colour(o.style,muted and 0.7608 or 0.9490,muted and 0.7137 or 0.9137,muted and 0.6196 or 0.8353,1)
  return o
 end
 local function panel(id,x,y,w,h,r,g,b)
  local o=s.panels[id];if not o then o=box(r,g,b,1);s.panels[id]=o end
  position(o,x,y,w,h);display(o,true);return o
 end
 local function row(id,title,value,x,y,w,enabled,controlWidth)
  local valueWidth=controlWidth or 192
  line(id.."_label",title,x,y+5,math.max(1,w-valueWidth-14),23)
  local o=button(id,x+w-valueWidth,y,valueWidth,29,value,enabled)
  help(id,title,x,y+5,math.max(1,w-valueWidth-14),23)
  return o
 end
 local function field(id,title,value,x,y,w,detail,controlWidth,helpWidth)
  local valueWidth=controlWidth or 192
  local r=s.edits[id]
  if not r then local e=ui.edit(id,parent);r={object=e};s.edits[id]=r;if e then track(e)end end
  line(id.."_label",title,x,y+5,math.max(1,w-valueWidth-14),23);help(id,title,x,y+5,helpWidth or math.max(1,w-valueWidth-14),23,detail)
  value=string.format("%s",value)
  local binding=id=="picker_hex"and s.pickerTicket or id=="rule_colour"and s.activeRuleID or (s.dpsBindings and s.dpsBindings[id])or(s.classBindings and s.classBindings[id])
  if id=="frame_width"or id=="frame_height"or id=="spacing"then binding=s.layoutKey end
  if r.object then
   if r.restore then
    local old=r.restore;r.restore=nil
    if old.binding==binding then
     r.canonical=old.canonical;r.lastText=old.lastText;r.binding=old.binding
     local restore=ui.editText or ui.text;restore(r.object,old.text or"")
    end
   end
   if r.canonical~=value or r.binding~=binding then (ui.editText or ui.text)(r.object,value);r.canonical=value;r.lastText=value;r.binding=binding end
   position(r.object,x+w-math.min(valueWidth,w),y,math.min(valueWidth,w),29);if ui.editChrome then ui.editChrome(r.object)end;display(r.object,true);r.visible=true
  else line(id.."_missing","Text input unavailable",x+w-192,y+5,192,23,10,true)end
  return r.object
 end
 local function colourField(id,title,value,x,y,w,detail)
  field(id,title,value,x,y,w,detail or("Pick the colour for "..title:lower().."."),nil,math.max(80,w-242))
  local className=s.classBindings and s.classBindings[id]
  local family=s.dpsBindings and s.dpsBindings[id]
  local binding=className or family
  -- Keep every colour chip and RGB code on the same columns. The final
  -- column is reserved for override removal, even on base-palette rows.
  position(s.labels[id.."_label"],x,y+5,math.max(80,w-242),23)
  ui.call(s.labels[id.."_label"].style,"SetEllipsis",true)
  if s.edits[id].object then position(s.edits[id].object,x+w-192,y,128,29)end
  if binding then
   local clear="colour_clear_"..id
   button(clear,x+w-56,y,56,29,"Clear",(className and s.classOverrides[className]~=nil)or(family and s.dpsOverrides[family]~=nil))
   ui.bindColour(clear,id,binding,title)
  end
  local c=Colours.rgb(value)
  if c then
   local key="colour_pick_"..id;local sw=ui.buttons[key]
   if not sw then sw=ui.surface(key,parent);track(sw)end
   position(sw,x+w-228,y,28,29);display(sw,true)
   local fill=s.panels[key]
   if not fill then fill=track(ui.drawable(sw,c[1],c[2],c[3],1));s.panels[key]=fill end
   ui.place(fill,sw,2,2,24,25);ui.colour(fill,c[1],c[2],c[3],1);display(fill,true)
   ui.bindColour(key,id,binding or s.edits[id].binding,title)
  end
 end
 local function drawForm(list,x,y,w,ph)
  local cap=math.max(1,math.floor((ph-58-y-29)/33)+1)
  local ranges={};local at=1
  while at<=#list do
   local last=math.min(#list,at+cap-1)
   -- Carry a trailing group heading onto the next page with its first field.
   if last<#list and list[last].heading and last>at then last=last-1 end
   if last==at and list[at].heading and at<#list then last=at+1 end
   ranges[#ranges+1]={at,last};at=last+1
  end
  s.totalPages=math.max(1,#ranges);s.section=math.min(s.section,s.totalPages)
  local range=ranges[s.section]or{1,0};local first=range[1]
  for n=first,range[2]do
   local r=list[n];local ry=y+(n-first)*33
   if r.heading then line(r[1],r[2],x,ry+4,w,24,13,true)
   elseif r.field then field(r[1],r[2],r[3],x,ry,w,r.help)
   elseif r.colour then colourField(r[1],r[2],r[3],x,ry,w,r.help)
   else row(r[1],r[2],r[3],x,ry,w,r[4])
    if s.activeRuleID and (r.effect or r[1]:sub(1,5)=="rule_")then ui.bindEffect(r[1],s.activeRuleID)end
   end
  end
 end
 local function childLabel(id,owner,value,x,y,w,h,size,ellipsis)
  local o=s.labels[id]
  if not o then
   o=track(ui.label("studio_"..id,owner,size or 11));s.labels[id]=o
   if o and ellipsis then ui.call(o.style,"SetEllipsis",true)end
  end
  if o then ui.place(o,owner,x,y,w,h);ui.text(o,value);display(o,true)end
  return o
 end
 local function on(v)return v and "On"or"Off"end
 local function traceRow(ctx,x,y,w)
  local active=ctx.traceActive==true
  local enabled=active or(ctx.armed==true and ctx.canArm==true and ctx.traceAvailable==true)
  row("target_trace","Rapid-hover check",active and"Stop and save"or"Record 10 seconds",x,y,w,enabled)
 end
 local function tracePanel(ctx,x,y,w,compact)
  traceRow(ctx,x,y,w)
  line("trace_help","Record, then move across raid members quickly.",x,y+31,w,compact and 18 or 25,11,true)
  line("trace_status",P.text(ctx.traceStatus or"No test recorded.",84),x,y+(compact and 51 or 64),w,compact and 22 or 32,10,true)
  line("trace_path","Mazrim_Raid_Frames/target-check.txt",x,y+(compact and 76 or 101),w,16,10,true)
  if ctx.traceReport==true and ctx.traceActive~=true then
   button("target_trace_save",x,y+(compact and 98 or 126),192,29,ctx.traceSaved==true and"Saved"or"Retry save",ctx.traceSaved~=true)
  end
 end
 local function sampleFor(prefs,names)
  local key="";for _,name in ipairs(names or{})do key=key.."|"..name end
  if not s.orderingSample or s.orderingSample.rules~=prefs or s.orderingSample.classKey~=key then
   local rows,layout=Ordering.sample(prefs,names);s.orderingSample={rules=prefs,classKey=key,rows=rows,layout=layout}
  end
  return s.orderingSample.rows,s.orderingSample.layout
 end
 local function orderingInk(category,palette)
  local key=category=="tank"and"tank"or category=="healer"and"healer"or(category=="mage"or category=="ranged"or category=="melee")and"damage"or"neutral"
  return Colours.rgb(Colours.dpsColour(palette,category)or palette[key])or{.18,.16,.12,1}
 end
 local function gridCell(id,x,y,w,h,title,ink)
  local o=ui.buttons[id]
  if not o then o=ui.orderingCell and ui.orderingCell(id,parent)or ui.button(id,parent);track(o)end
  position(o,x,y,w,h);ui.text(o,title);ui.enable(o,true);display(o,true)
  local bg=s.panels[id.."_fill"]
  if not bg then bg=track(ui.drawable(o,ink[1],ink[2],ink[3],1));s.panels[id.."_fill"]=bg end
  ui.place(bg,o,0,0,w,h);ui.colour(bg,ink[1],ink[2],ink[3],1);display(bg,true)
  local strip=s.panels[id.."_mana"]
  if not strip then strip=track(ui.drawable(o,.20,.27,.72,1));s.panels[id.."_mana"]=strip end
  ui.place(strip,o,0,h-2,w,2);display(strip,true)
  return o
 end
 local function orderingGrid(prefs,x,y,w,ph,ctx)
  local rows,layout=sampleFor(prefs);local at={};for _,p in ipairs(layout)do at[(p.group-1)*5+p.order]=rows[p.row_index]end
  local cellHeight=math.min(34,math.floor(((ph-58-y-12)/2-22)/5)-3)
  local full=cellHeight>=20 and w>=440
  s.totalPages=full and 1 or 10;s.section=math.min(s.section,s.totalPages)
  local fw=math.floor((w-16)/5);local first=full and 1 or s.section;local last=full and 10 or first
  for group=first,last do
   local col=full and(group-1)%5 or 0;local bank=full and math.floor((group-1)/5)or 0
   local gx=x+col*(fw+4);local gy=y+bank*(22+5*(cellHeight+3)+12)
   local gw=full and fw or w
   local id="ordering_grid_party_"..group
   button(id,gx,gy,gw,20,"Party "..group,true)
   if ui.bindOrdering then ui.bindOrdering(id,"party_all",group)end
   for pos=1,5 do
    local slot=(group-1)*5+pos;local actor=at[slot];local sx=full and gx or x+(pos-1)*(fw+4)
    local sy=full and gy+22+(pos-1)*(cellHeight+3)or gy+25;local sh=full and cellHeight or 28
    local id="ordering_grid_slot_"..slot
    local category=prefs.slots[string.format("%d",slot)]or prefs.parties[string.format("%d",group)]
    local title,ink
    if actor and (category=="flex"or actor.role==category)then
     title=actor.name;ink=orderingInk(actor.role,ctx.config.options.colours)
    else
     title=category=="flex"and"Any role"or(category:sub(1,1):upper()..category:sub(2).." slot")
     ink=orderingInk(category,ctx.config.options.colours)
     ink={ink[1]*.65,ink[2]*.65,ink[3]*.65,1}
    end
    gridCell(id,sx,sy,fw,sh,P.text(title,28),ink)
    if ui.bindOrdering then ui.bindOrdering(id,"slot",slot)end
   end
  end
 end
 local function appearanceExampleHeight(ctx,w,room)
  local geometry=ctx.config.settings[ctx.config.view.layout]
  local gap=geometry.gap_x or 3
  local fw=math.max(1,math.min(geometry.width,w))
  local columns=math.max(1,math.floor((w+gap)/(fw+gap)))
  local count=s.previewCount==25 and 25 or s.previewCount==50 and 50 or 5
  local rows=math.ceil(count/columns)
  local header,minimum=54,82
  local desired=header+rows*geometry.height+math.max(0,rows-1)*gap
  return math.max(minimum,math.min(desired,math.max(minimum,room)))
 end
 local function appearanceExample(ctx,x,y,w,h,previewWanted,origin)
  local header,gridTop=54,52
  local count=s.previewCount
  if count~=5 and count~=25 and count~=50 then count=5;s.previewCount=count end
  local geometry=ctx.config.settings[ctx.config.view.layout]
  local gap=geometry.gap_x or 3
  local fw=math.max(1,math.min(geometry.width,w));local fh=math.max(1,math.min(geometry.height,h-header))
  local columns=math.max(1,math.floor((w+gap)/(fw+gap)))
  local rows=math.max(1,math.floor((h-header+gap)/(fh+gap)))
  local capacity=math.max(1,math.min(50,columns*rows,count));s.previewCapacity=capacity
  s.previewPages=math.max(1,math.ceil(count/capacity));s.previewPage=math.max(1,math.min(s.previewPage or 1,s.previewPages))
  local clamped=fw~=geometry.width or fh~=geometry.height
  local caption="EXAMPLE "..s.previewPage.."/"..s.previewPages
  if clamped then caption=caption.." · fitted"end
  line("appearance_example_label",caption,x,y+3,math.max(1,w-302),20,10,true)
  button("preview_count",x+w-172,y,104,22,"Samples: "..count,true)
  button("preview_previous",x+w-62,y,28,22,"‹",s.previewPage>1)
  button("preview_next",x+w-28,y,28,22,"›",s.previewPage<s.previewPages)
  button("text_reset_positions",x+w-294,y,112,22,"Reset text",true)
  panel("appearance_drag_band",x,y+26,w,22,.2667,.2235,.1647)
  panel("appearance_drag_edge",x,y+26,3,22,.8824,.7490,.4784)
  local hint=line("appearance_drag_hint","DRAG TO CUSTOMISE  •  Move names, HP, distance and icons below",x+11,y+26,w-19,22,12,false,true)
  if hint then ui.colour(hint.style,.96,.84,.59,1)end
  local first=(s.previewPage-1)*capacity+1
  local frames={}
  for i=1,math.min(capacity,count-first+1)do
   if not s.previews[i]then s.previews[i]=ui.previewCreate("studio_slot"..i,parent)end
   previewWanted[i]=true
   local col=(i-1)%columns;local row=math.floor((i-1)/columns)
   local fx=x+col*(fw+gap);local fy=y+gridTop+row*(fh+gap)
   if ui.appearancePreview then ui.appearancePreview(s.previews[i],fx,fy,fw,fh,first+i-1,ctx.config.options,ctx.config.settings.display)end
   frames[#frames+1]={cell=s.previews[i],x=origin.x+fx,y=origin.y+fy,w=fw,h=fh}
  end
  if ctx.open==true and not ctx.orderingMenu then
   local options=ctx.config.options;local settings=ctx.config.settings.display
   local key=ctx.config.view.layout.."/"..options.appearance.mode.."/"..options.appearance.theme.."/"..geometry.width.."/"..geometry.height.."/"..gap.."/"..fw.."/"..fh.."/"..columns.."/"..count.."/"..s.previewPage.."/"..capacity
    .."/"..settings.font_size.."/"..settings.health_text.."/"..on(settings.show_names).."/"..on(settings.show_mana).."/"..on(options.appearance.role_icon)
   s.textEditorGeometry={stage={x=origin.x+x,y=origin.y+y+gridTop,w=w,h=math.max(1,h-gridTop)},frames=frames,key=key}
   if ui.textEditor then display(ui.textEditor(s.previews,s.textEditorGeometry,options,settings),true)end
  end
 end
 local function effectActions(effect)
  local summary=""
  local function add(value)
   summary=summary=="" and value or summary.." · "..value
  end
  if effect.iconSelected or effect.selected then add("Icon")end
  if effect.mixed then add("Mixed settings")end
  if effect.ruleEnabled then add("Frame")elseif effect.hasRule then add("Frame paused")end
  if effect.alertSelected then add("Alert")end
  return summary~="" and summary or "Set up"
 end
 local function effectBrowser(ctx,x,y,w,ph)
  local search=s.edits.effect_search
  if not search then
   search={object=ui.edit("effect_search",parent),lastText=ctx.effectQuery or""}
   s.edits.effect_search=search
   s.effectEdit=track(search.object)
   if search.object then ui.text(search.object,search.lastText)end
  end
  local mine=ctx.effectScope=="mine"
  if not mine then
   line("effect_name_notice","NEW NAMES MAY TAKE A MINUTE OR LONGER",x,y,w,22,15)
   line("effect_name_notice_help","Keep this page open, or search by spell ID.",x,y+22,w,16,11,true)
   y=y+44
  end
  button("effect_browse",x,y+16,88,29,"Browse",true,not mine)
  button("effect_my",x+94,y+16,100,29,"My effects",true,mine)
  local searchX=x+202
  line("effect_search_label","Name or spell ID",searchX,y,w-202,16,10,true)
  if search.object then
   local canClear=type(ctx.effectQuery)=="string" and ctx.effectQuery~=""
   local endWidth=132
   position(search.object,searchX,y+16,w-202-endWidth,29)
   if ui.editChrome then ui.editChrome(search.object)end
   search.visible=true
   display(search.object,true)
   button("effect_search",x+w-endWidth+6,y+16,64,29,"Search",true)
   button("effect_clear_search",x+w-56,y+16,56,29,"Clear",canClear)
  else
   line("effect_search_unavailable","Search input unavailable",searchX,y+18,w-202,23,11,true)
  end
  y=y+54
  local effects=ctx.effectRows or{}
  local rowHeight,gap=44,5
  local capacity=math.max(1,math.floor((ph-58-y+gap)/(rowHeight+gap)))
  s.totalPages=math.max(1,math.ceil(#effects/capacity))
  s.section=math.min(s.section,s.totalPages)
  if #effects==0 then
   line("effect_empty","No matching effects",x,y,w,22,13)
   local guidance=mine and"Choose Browse to find an effect, or clear the search."
    or"Select a raid member with the effect, then check here again.\nIf you know its spell ID, enter it above."
   line("effect_empty_help",guidance,x,y+23,w,40,11,true)
   return
  end
  local first=(s.section-1)*capacity+1
  for index=first,math.min(#effects,first+capacity-1)do
   local effect=effects[index]
   local slot=index-first+1
   local ry=y+(slot-1)*(rowHeight+gap)
   local id="effect_open_"..slot
   local card=button(id,x,ry,w,rowHeight,"",true)
   childLabel("effect_name_"..slot,card,P.text(effect.name,64),10,1,w-20,22,12,true)
   local variants=effect.members and #effect.members or 1
   local info=(effect.kind or"Type unknown")..(variants>1 and(" · "..variants.." versions")or(" · ID "..effect.id))
   if effect.source then info=effect.source.." · "..info end
   childLabel("effect_info_"..slot,card,info,10,22,w-188,17,10,true)
   childLabel("effect_actions_"..slot,card,effectActions(effect),w-174,22,164,17,10,true)
   ui.bindEffect(id,effect.id)
  end
 end
 local function effectMaterials(ctx,x,y,w,ph,previewWanted,rule)
  button("material_back",x,y,126,27,"Effect details",true)
  ui.bindEffect("material_back",ctx.ruleID)
  line("material_title","Choose a texture",x+140,y+2,w-140,24,13)
  y=y+35
  local capacity=ph<570 and 3 or 12
  local rows=capacity/3
  s.totalPages=math.ceil(#Materials.order/capacity)
  s.section=math.min(s.section,s.totalPages)
  local first=(s.section-1)*capacity+1
  local gap=10
  local tw=math.floor((w-2*gap)/3)
  local th=math.max(45,math.floor((ph-58-y-(rows-1)*gap)/rows))
  local config=ctx.config
  local geometry=config.settings[config.view.layout]
  for index=first,math.min(#Materials.order,first+capacity-1)do
   local n=index-first+1
   local key=Materials.order[index]
   local tx=x+(n-1)%3*(tw+gap)
   local ty=y+math.floor((n-1)/3)*(th+gap)
   local id="material_choice_"..key
   local tile=button(id,tx,ty,tw,th,"",true,rule.material==key)
   ui.bindEffect(id,ctx.ruleID)
   childLabel("material_caption_"..key,tile,Materials.labels[key],8,4,tw-16,20,11)
   -- A preview must belong to its card. Reusing an earlier settings preview
   -- changes its anchor, but leaves the native widget behind newer siblings.
   if not s.materialPreviews[key]then s.materialPreviews[key]=ui.previewCreate("studio_material_"..key,tile)end
   previewWanted[key]=true
   local sw=math.min(geometry.width,tw-20)
   local sh=math.max(16,math.min(geometry.height,th-30))
   if ui.materialPreview then ui.materialPreview(s.materialPreviews[key],math.floor((tw-sw)/2),th-sh-6,sw,sh,config.options,config.settings.display,key,tile)end
  end
 end
 local function effectDetails(ctx,x,y,w,ph,previewWanted,rule)
  local id=ctx.ruleID
  local config=ctx.config
  local options=config.options
  local detail=ctx.effectDetail
  local iconEnabled=options.auras.watch[id]==true
  local frameEnabled=rule~=nil and rule.enabled==true
  local alertEnabled=options.auras.alerts[id]==true
  if detail and detail.members then iconEnabled=detail.iconSelected==true;alertEnabled=detail.alertSelected==true end
  local name=ctx.ruleName or("Effect "..id)
  local previewRoom=w<600 and 132 or 176
  local infoX=x+102
  local infoW=w-previewRoom-112
  button("rule_back",x,y,92,27,"Effects list",true)
  line("rule_title",P.text(name,64),infoX,y,infoW,23,13,false,true)
  local source=ctx.effectDetail and ctx.effectDetail.source
  local meta=(ctx.effectKind or"Type unknown").." · ID "..id
  if source then meta=source.." · "..(w<600 and("ID "..id)or meta)end
  local variants=detail and detail.members and #detail.members or 1
  if variants>1 then meta=(ctx.effectKind or"Effect").." · "..variants.." versions"..(detail.mixed and" · mixed"or"")end
  line("effect_detail_meta",meta,infoX,y+22,infoW,16,10,true,true)
  if rule and s.materialsOpen then
   effectMaterials(ctx,x,y+40,w,ph,previewWanted,rule)
   return
  end
  local alertNote="Screen alerts use detected debuffs."
  if ctx.effectKindCode=="buff"then
   alertNote="Buffs cannot trigger screen alerts."
  elseif ctx.effectKindCode=="unknown"then
   alertNote="This effect needs to be identified as a debuff first."
  elseif alertEnabled and not options.auras.large_alerts then
   alertNote="Screen alerts are paused."
   button("effect_resume_alerts",x,y+30,92,23,"Resume alerts",true)
   ui.bindEffect("effect_resume_alerts",id)
  elseif alertEnabled and not options.auras.raid_tracker then
   alertNote="Raid tracking is off."
   button("effect_tracker_settings",x,y+30,92,23,"Tracking",true)
  elseif alertEnabled and not ctx.raidTrackerAvailable then
   alertNote="Raid tracker unavailable."
  end
  local groupNote=variants>1 and("Changes apply to all "..variants.." versions.")or alertNote
  if variants>64 then groupNote=variants.." versions · raid tracking checks 64 IDs"end
  line("effect_detail_note",groupNote,infoX,y+37,infoW,16,10,true)
  if ui.effectPreview then
   local geometry=config.settings[config.view.layout]
   local previewX=x+w-previewRoom
   line("effect_example_title","Example",previewX,y,previewRoom,15,10,true)
   if not s.previews[1]then s.previews[1]=ui.previewCreate("studio_slot1",parent)end
   previewWanted[1]=true
   ui.effectPreview(s.previews[1],previewX,y+16,math.min(geometry.width,previewRoom),math.min(geometry.height,34),
    options,config.settings.display,{id=id,name=name,kind=ctx.effectKind,kindCode=ctx.effectKindCode,
     icon=ctx.effectIcon,iconEnabled=iconEnabled,rule=rule,alertEnabled=alertEnabled})
  end
  s.switchStates.effect_watch_detail=iconEnabled
  s.switchStates.rule_enabled=frameEnabled
  s.switchStates.effect_alert_detail=alertEnabled
  local controls={
   {"effect_watch_detail","Show icon",on(iconEnabled),effect=true},
   {"rule_enabled","Change frame appearance",on(frameEnabled)},
   {"effect_alert_detail","Show screen alert · debuffs only",on(alertEnabled),effect=true}
  }
  if iconEnabled then
   local priority=options.auras.priorities[id]
   controls[#controls+1]={"effect_priority_detail","Icon priority",priority==2 and"Urgent"or priority==1 and"High"or"Normal",effect=true}
  end
  if frameEnabled then
   local kind=rule.kind=="buff"and"Helpful buff"or rule.kind=="debuff"and"Harmful debuff"or"Buff or debuff"
   local priority=rule.priority==2 and"Urgent"or rule.priority==1 and"High"or"Normal"
   controls[#controls+1]={"rule_kind","Apply appearance to",kind}
   controls[#controls+1]={"rule_material","Frame appearance",Materials.labels[rule.material]or"Colour"}
   controls[#controls+1]={"rule_colour",rule.material=="tint"and"Fill colour (RGB)"or"Texture tint (RGB)",rule.colour,colour=true}
   controls[#controls+1]={"rule_priority","Frame appearance priority",priority}
  end
  if rule then controls[#controls+1]={"rule_remove","Saved frame appearance","Remove"}end
  drawForm(controls,x,y+55,w,ph)
 end
 local shareFields={}
 local function shareField(id,session,value,x,y,w,limit)
  local r=shareFields[id]
  if not r then
   local o=ui.edit("share_"..id,parent)
   if not o then return nil end
   r={object=track(o)};shareFields[id]=r
   ui.call(o,"SetMaxTextLength",limit)
  end
  if r.session~=session or r.value~=value then
   (ui.editText or ui.text)(r.object,value);r.session=session;r.value=value
  end
  position(r.object,x,y,w,29);display(r.object,true)
  if ui.editChrome then ui.editChrome(r.object)end
  return r.object
 end
 function s.shareValue(id)
  local r=shareFields[id]
  if r then
   local ok,value=ui.call(r.object,"GetText")
   if ok and type(value)=="string"then return value end
  end
 end
 local function sharePanel(ctx,x,y,w,previewWanted)
  local share=ctx.profileShare
  button("share_back",x,y,90,27,"‹ Profiles",true)
  if share.kind=="export"then
   button("share_layout",x+100,y,132,27,"Layout only",true,share.mode=="L")
   button("share_full",x+240,y,132,27,"Full profile",true,share.mode=="F")
   line("share_label","Sharing "..P.text(share.name,24),x,y+33,w,21,13)
   if not share.code then line("share_status","This profile is too large to share.",x,y+60,w,20,12,true);return end
   local parts=share.parts
   local value=share.direct and share.code or parts and parts[share.part]or share.code
   if not shareField("code",share,value,x,y+57,w,ProfileShare.MAX_CODE)then
    line("share_status","The game did not provide a copyable text field.",x,y+57,w,24,12,true);return
   end
   if parts and #parts>1 then
    button("share_parts",x,y+94,125,27,share.direct and"Whisper parts"or"Full code",true)
    if not share.direct then
     button("share_part_previous",x+w-168,y+94,34,27,"‹",share.part>1)
     line("share_part_count","Part "..share.part.." of "..#parts,x+w-124,y+94,80,27,11)
     button("share_part_next",x+w-34,y+94,34,27,"›",share.part<#parts)
    end
   end
   local hint=share.direct and"Copy the full code for direct paste or Discord."or"Copy the code and paste it into a whisper."
   line("share_status",hint,x,y+126,w,21,11,true)
  elseif share.kind=="receive"then
   local sender=shareField("sender",share,"",x,y+55,w-170,48)
   line("share_sender_label","Whisper from",x,y+34,w,18,11,true)
   button("share_listen",x+w-160,y+55,160,29,share.wait and"Stop listening"or"Listen for whisper",sender~=nil,true)
   line("share_status",share.status or"",x,y+88,w,20,11,true,true)
   line("share_paste_label","Or paste a full MRF1 profile code",x,y+108,w,18,11,true)
   local code=shareField("code",share,"",x,y+129,w-154,ProfileShare.MAX_CODE)
   button("share_paste",x+w-144,y+129,144,29,"Preview pasted code",code~=nil)
  elseif share.kind=="preview"then
   local profile=share.profile;local o=profile.options;local g=profile.settings[profile.view.layout]
   local function count(map)local n=0;for _ in pairs(map)do n=n+1 end;return n end
   local style=o.appearance.mode=="custom"and"Ellesmere"or"Original ArcheAge"
   line("share_preview_kind",share.mode=="L"and"Layout only"or"Full profile",x+102,y,w-102,27,13)
   line("share_preview_size",style.."  ·  "..g.width.." × "..g.height.." px",x,y+35,w-140,20,12)
   line("share_preview_order",o.member_layout.ordering.enabled and"Custom slot sorting on"or"Custom slot sorting off",x,y+55,w-140,18,11,true)
   local a=o.auras
   local summary=share.mode=="L"and"Effect choices use the defaults."or
    string.format("%d icons  ·  %d frame effects  ·  %d alerts",count(a.watch),count(a.frame_rules),count(a.alerts))
   line("share_preview_effects",summary,x,y+75,w-140,18,11,true)
   if ui.appearancePreview and ui.previewCreate then
    if not s.previews[1]then s.previews[1]=ui.previewCreate("studio_slot1",parent)end
    local cell=s.previews[1]
    previewWanted[1]=true
    ui.appearancePreview(cell,x+w-math.min(132,g.width),y+37,math.min(132,g.width),math.min(54,g.height),2,o,profile.settings.display)
   end
   line("share_preview_name","Name for the new profile",x,y+96,w,18,11,true)
   local name=shareField("name",share,"Imported setup",x,y+116,w-174,24)
   button("share_save",x+w-164,y+116,164,29,"Save as new profile",name~=nil and ctx.canSave,true)
   line("share_status",share.status or"Your current layout stays active.",x,y+147,w,18,11,true,true)
  end
 end
 function s.render(ctx,w,h)
  local options=ctx.config.options;local a=options.auras;local i=options.indicators
  local rule=ctx.effectDetail and ctx.effectDetail.rule or ctx.ruleID and W.rule(a,ctx.ruleID)
  s.switchStates={appearance_role_icon=options.appearance.role_icon,mana=ctx.config.settings.display.show_mana,show_distance=options.appearance.show_distance,
   return_target=options.input.return_target,raid_tracker=a.raid_tracker,ordering_enabled=options.member_layout.ordering.enabled and options.member_layout.enabled,
   ind_target=i.target,ind_hover=i.hover,ind_health=i.low_health,ind_mana=i.low_mana,large_alerts=a.large_alerts,
   hots=a.hots,debuffs=a.debuffs,addon_frames=ctx.config.visibility.frames,
   icon_grouped=options.aura_icons.grouped~=false}
  if rule then s.switchStates.rule_enabled=rule.enabled end
  s.classOverrides=ctx.config.options.colours.classes
  wanted={};helpRects={};s.activeRuleID=ctx.ruleID;s.pickerTicket=ctx.picker and ctx.picker.ticket;s.layoutKey=ctx.config.view.layout;s.classBindings={};s.dpsBindings={};s.dpsOverrides=ctx.config.options.colours.dps
  for _,r in pairs(s.edits)do r.visible=false end
  if not s.built then
   s.background=box(0.1294,0.1137,0.0980,0.98);s.rail=box(0.0902,0.0784,0.0627,1)
   s.header=box(0.1294,0.1137,0.0980,1);s.footer=box(0.0902,0.0784,0.0627,1)
   s.accent=box(0.8824,0.7490,0.4784,1);s.built=true
  end
  for i=1,#all do display(all[i],false)end
  for id,o in pairs(ui.buttons)do
   if id:sub(1,5)~="tour_" and o~=ui.buttons.cog and o~=ui.buttons.manager_shortcut and o~=ui.buttons.hud_manager and o~=ui.buttons.hud_native and o~=ui.buttons.hud_addon and o~=ui.buttons.hud_hover and o~=ui.buttons.hud_sort and o~=ui.buttons.hud_reset then display(o,false)end
  end
  local previewWanted={};s.textEditorGeometry=nil
  local pw=math.min(1170,w-32);local ph=math.min(803,h-32)
  local x=math.max(16,w-pw-20);local y=math.floor((h-ph)/2)
  if s.position then
   x=math.max(0,math.min(s.position.x,math.max(0,w-pw)))
   y=math.max(0,math.min(s.position.y,math.max(0,h-ph)))
   s.position.x=x;s.position.y=y
  end
  ui.place(parent,"UIParent",x,y,pw,ph)
  position(s.background,0,0,pw,ph);position(s.header,0,0,pw,62)
  if ui.dragHandle then position(ui.dragHandle,0,0,pw-62,62);display(ui.dragHandle,true)end
  position(s.rail,0,62,148,math.max(1,ph-110));position(s.footer,0,ph-48,pw,48);position(s.accent,0,0,pw,3)
  display(s.background,true);display(s.header,true);display(s.rail,true);display(s.footer,true);display(s.accent,true)
  line("brand","RAID FRAMES",18,12,pw-84,22,16)
  line("version","Healing studio  •  "..ctx.version,18,36,pw-84,16,10,true)
  button("close",pw-42,17,26,28,"×",true)
  for i=1,#pages do
   local p=pages[i];button("tab_"..p[1],12,74+(i-1)*(ph<470 and 26 or 30),124,ph<470 and 24 or 28,p[2],not ctx.profileLoad and not ctx.alertWarning,s.page==p[1])
  end
  local infoY=ph-(ph<470 and 80 or 111)
  local infoEnabled=not ctx.picker and not ctx.resetPending and not ctx.profileLoad and not ctx.alertWarning
  button("quick_tour",12,infoY-28,124,25,"Quick tour",infoEnabled)
  button("known_issues",12,infoY,124,25,"Known issues",infoEnabled,s.page=="known_issues")
  local left,top,cw=170,78,pw-194
  if s.page=="overview"then s.page="appearance"end
  local heading=copy[s.page]or copy.appearance
  if s.page=="profiles"and ctx.profileLoad then
   heading={"Load profile?","Loading a profile replaces your current settings."}
  elseif s.page=="profiles"and ctx.profileShare then
   local kind=ctx.profileShare.kind
   heading=kind=="export"and{"Share profile","Share a copy of this saved setup."}
    or kind=="preview"and{"Preview profile","Review it before saving a separate profile."}
    or{"Receive profile","Receive a friend's whisper or paste their full code."}
  end
  if s.page=="status"then heading=({{"Data coverage","Optional checks to help when something isn't working."},{"Targeting checks","Optional checks for targeting problems."},{"Debuff checks","Check what the game reports for one raid member."},{"Tracking","Extra raid tracking settings."}})[math.min(4,s.section)]end
  line("page_title",heading[1],left,top,cw-112,26,19)
  line("page_sub",heading[2],left,top+30,cw,32,11,true)
  if ctx.picker or ctx.resetPending or ctx.alertWarning then display(s.labels.page_title,false);display(s.labels.page_sub,false)end
  local yy=top+70;local step=33;local config=ctx.config;local o=config.options
  s.totalPages=1
  if not ctx.resetPending and not ctx.picker and not ctx.alertWarning then
  if s.page=="appearance"then
   -- A short screen trades the repeated subtitle for the visible drag hint.
   if ph<470 then display(s.labels.page_sub,false);yy=top+38 end
   button("appearance_design",left,yy,math.floor(cw/2)-4,29,"Frame design",true,s.appearanceSection~="colours")
   button("appearance_colours",left+math.floor(cw/2)+4,yy,math.floor(cw/2)-4,29,"Colours",true,s.appearanceSection=="colours");yy=yy+38
   if s.appearanceSection=="colours"then
    local list={}
    local function heading(id,title)list[#list+1]={id,title,heading=true}end
    local function colour(key,title)list[#list+1]={"colour_"..key,title,o.colours[key],colour=true}end
    heading("colour_group_frames","Frame colours")
    colour("neutral","Base / unknown role");colour("tank","Tank role");colour("healer","Healer role");colour("damage","Damage / DPS fallback")
    heading("colour_group_categories","Class category colours")
    for _,family in ipairs({"mage","ranged","melee"})do
     local id="dps_colour_"..family;s.dpsBindings[id]=family
     list[#list+1]={id,({mage="Mage DPS",ranged="Ranged DPS",melee="Melee DPS"})[family],Colours.dpsColour(o.colours,family),colour=true,
      help="Pick the colour for this class category. Individual class colours take priority."}
    end
    heading("colour_group_text","Names and bars")
    colour("name","Member name");colour("self_name","Your name");colour("health_text","Health text");colour("mana","Mana strip")
    heading("colour_group_warnings","Highlights and warnings")
    colour("target","Selected target outline");colour("hover","Pointer outline");colour("low_health","Low health warning");colour("low_mana","Low mana marker")
    if #(ctx.classNames or{})>0 then heading("colour_group_classes","Individual class colours")end
    for i=1,#(ctx.classNames or{})do
     local name=ctx.classNames[i];s.classBindings["class_colour_"..i]=name
     list[#list+1]={"class_colour_"..i,name,o.colours.classes[name]or o.colours.neutral,colour=true,
      help="Use this colour for this class. It overrides the category colour."}
    end
    local eh=appearanceExampleHeight(ctx,cw,ph-52-yy-99);local ey=ph-52-eh
    drawForm(list,left,yy,cw,ey+50)
    appearanceExample(ctx,left,ey,cw,eh,previewWanted,{x=x,y=y})
   else
    local tw=math.floor((cw-12)/2)
    button("theme_native",left,yy,tw,29,"Original ArcheAge",true,o.appearance.mode=="native")
    button("theme_ellesmere",left+tw+12,yy,cw-tw-12,29,"Ellesmere",true,o.appearance.mode=="custom");yy=yy+37
    local eh=appearanceExampleHeight(ctx,cw,ph-58-yy-8-6*33)
    appearanceExample(ctx,left,yy,cw,eh,previewWanted,{x=x,y=y});yy=yy+eh+8
    local healthMode=({percent="Percentage",current="Current HP",missing="Missing HP",none="Off"})[config.settings.display.health_text]
    drawForm({{"appearance_role_icon","Ellesmere role icon",on(o.appearance.role_icon)},
     {"opacity","Frame opacity %",math.floor(o.appearance.opacity*100+0.5),field=true},
     {"font","Name / health text",config.settings.display.font_size.." px"},
     {"health","Health numbers",healthMode},{"mana","Thin mana strip",on(config.settings.display.show_mana)},
     {"show_distance","Distance text",on(o.appearance.show_distance)}},left,yy,cw,ph)
   end
  elseif s.page=="layout"then
   local l=config.settings[config.view.layout]
   local controls={{"preset","Frame size preset",ctx.preset},{"layout","Frame arrangement",config.view.layout=="raid"and"Raid"or"Party"},
    {"frame_width","Width (40–480 px)",l.width,field=true},{"frame_height","Height (20–100 px)",l.height,field=true},
    {"spacing","Spacing (0–24 px)",l.gap_x,field=true},{"reset_layout","Restore layout","Reset layout"},
    {"layout_visibility","Frame visibility",heading=true},{"addon_frames","Addon raid frames",config.visibility.frames and"Hide addon frames"or"Return addon frames"},
    {"native_toggle","Game's original frames",ctx.nativeFrameLabel or"Hide / Return original raid frames",ctx.canToggle},
    {"general_targeting","Targeting & tracking",heading=true},
    {"return_target","Return previous raid target",on(o.input.return_target)},
    {"raid_tracker","Experimental raid tracker",on(o.auras.raid_tracker),ctx.raidTrackerAvailable or o.auras.raid_tracker}}
   if ctx.pages>1 then
    controls[#controls+1]={"raid_previous","Raid members: page "..ctx.page.." of "..ctx.pages,"Previous members",ctx.page>1}
    controls[#controls+1]={"raid_next","Raid member pages","Next members",ctx.page<ctx.pages}
   end
   drawForm(controls,left,yy,cw,ph)
  elseif s.page=="ordering"then
   local prefs=o.member_layout.ordering;s.orderingPart="slots"
   local half=math.floor((cw-6)/2)
   button("ordering_slots",left,yy,half,28,"Custom slots",true,true)
   local enabled=prefs.enabled and o.member_layout.enabled
   button("ordering_enabled",left+half+6,yy,cw-half-6,28,enabled and"Sorting: ON"or"Sorting: OFF",true,enabled)
   orderingGrid(prefs,left,yy+35,cw,ph,ctx)
  elseif s.page=="healing"then
   local style=o.indicators.health_style or"outline"
   local titles={outline="Thin outline",badge="Warning badge",hatch="Deficit hatch"}
   if s.healthStylesOpen then
    button("health_styles_back",left,yy,192,28,"Back to indicators",true);yy=yy+35
    local third=math.floor((cw-12)/3)
    for i,key in ipairs({"outline","badge","hatch"})do
     local id="health_style_"..key
     button(id,left+(i-1)*(third+6),yy,i==3 and cw-2*(third+6)or third,28,titles[key],true,style==key)
    end
    yy=yy+35
    line("health_example_title","EXAMPLE · invented members · current warning colour",left,yy,cw,18,10,true);yy=yy+23
    local band=math.floor(cw/3);local fw=math.min(config.settings[config.view.layout].width,band-16)
    local fh=math.min(40,config.settings[config.view.layout].height)
    local threshold=o.indicators.health_threshold
    local values={math.floor((100+threshold)/2),math.max(1,math.floor(threshold*.65)),math.max(1,math.floor(threshold*.25))}
    for i,name in ipairs({"Healthy","Low health","Critical"})do
     if not s.previews[i]then s.previews[i]=ui.previewCreate("studio_slot"..i,parent)end
     previewWanted[i]=true
     if ui.healthPreview then ui.healthPreview(s.previews[i],left+(i-1)*band,yy,fw,fh,name,values[i],o,i>1)end
     line("health_example_"..i,values[i].."% HP",left+(i-1)*band,yy+fh+4,band-8,17,11,true)
    end
   else
   local list={{"ind_target","Selected target outline",on(o.indicators.target)},
    {"colour_target","Selected target colour",o.colours.target,colour=true},
    {"ind_hover","Pointer highlight",on(o.indicators.hover)},
    {"colour_hover","Hover highlight colour",o.colours.hover,colour=true},
    {"ind_health","Low health warning",on(o.indicators.low_health)},{"health_styles","Low health style",titles[style]}}
   local function healthColour(key,title)list[#list+1]={"health_colour_"..key,title,Colours.healthColour(o.colours,key),colour=true}end
   if style=="outline"then healthColour("outline","Outline colour")
   elseif style=="badge"then healthColour("badge","Badge colour")
   else
    local mode=o.indicators.hatch_mode or"stripes"
    -- The active colour stays beside its style; solid-only hides the unused
    -- stripe choice, while Both exposes each independent colour once.
    if mode=="solid"then healthColour("fill","Fill colour")else healthColour("hatch","Hatch colour")end
    list[#list+1]={"hatch_mode","Fill mode",({stripes="Stripes",solid="Solid",both="Stripes + solid"})[mode]}
    if mode=="both"then healthColour("fill","Fill colour")end
    list[#list+1]={"hatch_opacity","Deficit opacity %",math.floor((o.indicators.hatch_opacity or 1)*100+.5),field=true}
   end
   for _,control in ipairs({{"health_threshold","Low health threshold %",o.indicators.health_threshold,field=true},
    {"ind_mana","Low mana warning",on(o.indicators.low_mana)},{"mana_threshold","Low mana threshold %",o.indicators.mana_threshold,field=true},
    {"range","Healing distance fade",o.range.enabled and(o.range.distance.." metres")or"Native distance fade"},
    {"range_alpha","Faded opacity %",math.floor(o.range.alpha*100+0.5),field=true}})do list[#list+1]=control end
   drawForm(list,left,yy,cw,ph)
   end
  elseif s.page=="effects"then
   if ph<470 then display(s.labels.page_sub,false);yy=top+38 end
   local tabWidth=math.floor((cw-12)/3)
   button("effects_icons",left,yy,tabWidth,29,"Effects",true,s.effectSection=="icons")
   button("effects_layout",left+tabWidth+6,yy,tabWidth,29,"Icon layout",true,s.effectSection=="layout")
   button("effects_tracker",left+2*(tabWidth+6),yy,cw-2*(tabWidth+6),29,"Screen alerts",true,s.effectSection=="tracker");yy=yy+36
   if s.effectSection=="layout"then
    local icons=o.aura_icons;local names={top_right="Top right",top_left="Top left",bottom_right="Bottom right",bottom_left="Bottom left"}
    local form={{"icon_size","Icon size (0 = Auto)",icons.size,field=true},{"icon_position","Default corner",names[icons.position]},
      {"icon_spacing","Icon spacing (0-12 px)",icons.spacing,field=true},{"icon_count","Maximum icons (1-6)",icons.max_visible,field=true},
      {"icon_timer","Timer text max (8-16 px)",icons.timer_size,field=true},{"icon_grouped","Group icons",on(icons.grouped~=false)},
      {"hots","Helpful icons",on(a.hots)},{"debuffs","Harmful icons",on(a.debuffs)}}
    -- Reserve a real editor area below the controls, even on short displays.
    local compact=ph<650;local paged=ph<520;local columns=compact and not paged and 2 or 1;local formRows=math.ceil(#form/columns)
    if paged then s.totalPages=#form;s.section=math.min(s.section,#form);formRows=1 end
    for n,r in ipairs(form)do
     if not paged or n==s.section then
     local col=compact and not paged and(n-1)%2 or 0;local rn=paged and 0 or compact and math.floor((n-1)/2)or n-1
     local fw=compact and not paged and math.floor((cw-14)/2)or cw;local fx=left+col*(fw+14)
     local valueWidth=compact and not paged and 76 or 192
     if r.field then field(r[1],r[2],r[3],fx,yy+rn*33,fw,nil,valueWidth)else row(r[1],r[2],r[3],fx,yy+rn*33,fw,nil,valueWidth)end
     if compact and not paged then ui.call(s.labels[r[1].."_label"].style,"SetEllipsis",true)end
     end
    end
    local ey=yy+formRows*33+12;local eh=math.max(70,ph-58-ey)
    local geometry=config.settings[config.view.layout];local fw=math.min(math.max(geometry.width,128),cw-24);local fh=math.min(math.max(geometry.height,44),math.max(20,eh-35))
    local fx=left+math.floor((cw-fw)/2);local fy=ey+27+math.floor(math.max(0,eh-27-fh)/2)
    local ids={};local idKey=""
    for id,selected in pairs(a.watch or{})do if selected==true and W.id(id)then
     local at=#ids+1;local priority=W.priority(o.auras,id)
     while at>1 do local other=ids[at-1];local op=W.priority(o.auras,other)
      if not(priority>op or(priority==op and(#id<#other or(#id==#other and id<other))))then break end
      ids[at]=other;at=at-1
     end;ids[at]=id
    end end
    for _,id in ipairs(ids)do idKey=idKey..id..","end
    local size=icons.size>0 and icons.size or(fw>=104 and 24 or 20);local capacity=math.max(1,math.min(6,icons.max_visible,math.floor((fw-22)/(size+icons.spacing))))
    s.iconEditorPages=math.max(1,math.ceil(#ids/capacity));s.iconEditorPage=math.max(1,math.min(s.iconEditorPage or 1,s.iconEditorPages))
    local selected={};for n=(s.iconEditorPage-1)*capacity+1,math.min(#ids,s.iconEditorPage*capacity)do selected[#selected+1]=ids[n]end
    local caption="Drag text and icons"
    if fw>geometry.width or fh>geometry.height then caption=caption.." · enlarged"end
    if s.iconEditorPages>1 then caption=caption.." · "..s.iconEditorPage.." / "..s.iconEditorPages end
    line("icon_example_label",caption,left,ey,cw-267,24,11,true)
    button("text_reset_positions",left+cw-260,ey,90,24,"Reset text",true)
    button("icon_reset_positions",left+cw-164,ey,92,24,"Reset icons",true)
    button("icon_editor_previous",left+cw-64,ey,28,24,"‹",s.iconEditorPage>1)
    button("icon_editor_next",left+cw-28,ey,28,24,"›",s.iconEditorPage<s.iconEditorPages)
    if not s.previews[1]then s.previews[1]=ui.previewCreate("studio_slot1",parent)end
    local cell=s.previews[1];previewWanted[1]=true
    if ui.effectLayoutPreview then
     ui.effectLayoutPreview(cell,{x=fx,y=fy,w=fw,h=fh},o,config.settings.display,selected)
    end
    local key=config.view.layout.."/"..o.appearance.mode.."/"..idKey.."/"..s.iconEditorPage
    s.textEditorGeometry={stage={x=x+left,y=y+ey+27,w=cw,h=math.max(30,eh-27)},
     frames={{cell=cell,x=x+fx,y=y+fy,w=fw,h=fh}},key=key,allowIcons=#selected>0 or icons.grouped~=false}
    if ui.textEditor then display(ui.textEditor(s.previews,s.textEditorGeometry,o,config.settings.display),true)end
   elseif s.effectSection=="tracker"then
    local controls={
     {"large_alerts","Screen alerts",on(a.large_alerts)},
     {"move_raid_alert","Alert position",ctx.alertMoveActive and"Finish positioning"or"Preview and move"}
    }
    if not a.raid_tracker then
     controls[#controls+1]={"effect_tracker_settings","Raid tracking is off","General Settings"}
    end
    drawForm(controls,left,yy,cw,ph)
    line("screen_alert_note","Choose which effects alert on the Effects page.\nScreen alerts use detected debuffs.",left,yy+#controls*33+4,cw,38,11,true)
   elseif ctx.ruleID then
    effectDetails(ctx,left,yy,cw,ph,previewWanted,rule)
   else
    effectBrowser(ctx,left,yy,cw,ph)
   end
  elseif s.page=="known_issues"then
   local rowHeight=54
   local capacity=math.max(1,math.floor((ph-54-yy)/rowHeight))
   s.totalPages=math.ceil(#knownIssues/capacity);s.section=math.min(s.section,s.totalPages)
   local first=(s.section-1)*capacity+1
   for n=first,math.min(#knownIssues,first+capacity-1)do
    local issue=knownIssues[n];local y=yy+(n-first)*rowHeight;local id="issue_"..n
    panel(id.."_edge",left,y+2,2,43,.65,.51,.27)
    line(id.."_title",issue[1],left+11,y,cw-11,18,14)
    line(id.."_first",issue[2],left+11,y+18,cw-11,15,12,true)
    line(id.."_second",issue[3],left+11,y+33,cw-11,15,12,true)
   end
  elseif s.page=="profiles"and ctx.profileLoad then
   local pending=ctx.profileLoad
   line("profile_switch_name","Load “"..P.text(pending.name,24).."”?",left,yy,cw,26,16)
   line("profile_switch_question","Do you want to save a copy of your current setup first?",left,yy+32,cw,21,12)
   local hint=pending.savedBackup and("Saved as “"..pending.savedBackup.."”.")
    or not ctx.canSave and"Saving is blocked. Cancel to keep your current setup."
    or pending.backup and("Your copy will be called “"..pending.backup.."”.")
    or "All eight profile slots are full. Cancel to make room for a backup."
   line("profile_switch_hint",hint,left,yy+60,cw,22,11,true)
   line("profile_switch_status",pending.status or"",left,yy+86,cw,38,11,true,true)
   button("profile_switch_save",left,yy+128,142,30, "Save copy & load",ctx.canSave and pending.backup~=nil,true)
   button("profile_switch_discard",left+150,yy+128,148,30,"Load without saving",true)
   button("profile_switch_cancel",left+306,yy+128,90,30,"Cancel",true)
   if ui.bindProfile then
    ui.bindProfile("profile_switch_save",pending.name)
    ui.bindProfile("profile_switch_discard",pending.name)
    ui.bindProfile("profile_switch_cancel",pending.name)
   end
  elseif s.page=="profiles"and ctx.profileShare then
   sharePanel(ctx,left,yy,cw,previewWanted)
  elseif s.page=="profiles"then
   line("profile_help",P.text(ctx.profileStatus or"Enter a name to store this setup. Click a saved card to load it.",70),left,yy,cw,24,11,true);yy=yy+28
   if not s.profileEditAttempted then s.profileEditAttempted=true;s.edit=ui.edit("profile_name",parent);if s.edit then all[#all+1]=s.edit end end
   if s.edit then
    position(s.edit,left,yy,cw-306,29);if ui.editChrome then ui.editChrome(s.edit)end;display(s.edit,true)
   else button("profile_slot",left,yy,cw-306,29,"Name: Setup "..s.slot,true)end
   button("profile_store",left+cw-296,yy,124,29,"Store profile",true,true)
   button("profile_receive",left+cw-162,yy,162,29,"Receive from chat",true)
   yy=yy+38
   if type(ctx.deletePending)=="string"then
    line("profile_confirm_label","Delete “"..P.text(ctx.deletePending,24).."”?",left,yy+3,cw-208,26,11)
    button("profile_confirm_delete",left+cw-200,yy,110,29,"Confirm delete",true)
    button("profile_cancel_delete",left+cw-82,yy,82,29,"Cancel",true);yy=yy+36
    if type(ui.bindProfile)=="function"then
     ui.bindProfile("profile_confirm_delete",ctx.deletePending);ui.bindProfile("profile_cancel_delete",ctx.deletePending)
    end
   end
   local names=type(ctx.profileNames)=="table"and ctx.profileNames or{}
   if #names==0 then
    line("profile_empty","Your saved setups will appear here.",left,yy+10,cw,24,12,true)
   else
    local gap=8;local tw=math.floor((cw-gap)/2);local th=ph<470 and 52 or 68
    local capacity=2*math.max(1,math.floor((ph-58-yy+gap)/(th+gap)))
    s.totalPages=math.max(1,math.ceil(math.min(#names,8)/capacity));s.section=math.min(s.section,s.totalPages)
    local first=(s.section-1)*capacity+1
    for i=first,math.min(#names,8,first+capacity-1)do
     local name=names[i];local n=i-first;local tx=left+(n%2)*(tw+gap);local ty=yy+math.floor(n/2)*(th+gap)
     local active=ctx.profileName==name
     local card=button("profile_load_"..i,tx,ty,tw-126,th,P.text(name,28),true,active)
     button("profile_share_"..i,tx+tw-120,ty,86,28,"Share profile",true)
     button("profile_delete_"..i,tx+tw-28,ty,28,28,"×",true)
     if type(ui.bindProfile)=="function"then
      ui.bindProfile("profile_load_"..i,name);ui.bindProfile("profile_share_"..i,name);ui.bindProfile("profile_delete_"..i,name)
     end
     childLabel("profile_hint_"..i,card,active and"Current setup"or"Click to load",10,th-18,tw-146,16,9)
    end
   end
  else
   local compact=ph<570;s.totalPages=4;s.section=math.min(s.section,s.totalPages)
   if s.section==1 then
    row("resource_check","Resource check",ctx.probeRunning and"Stop check"or"Run check",left,yy,cw,ctx.canProbe)
    line("explain",string.format("PARTIAL  ·  %d names  ·  %d HP  ·  %d mana",ctx.named or 0,ctx.hp or 0,ctx.mana or 0),left,yy+37,cw,22,12)
    line("aura_status",ctx.auraStatus or"Aura coverage: unknown",left,yy+62,cw,32,10,true)
    line("probe_status",ctx.probeStatus or"",left,yy+98,cw,26,10,true)
    line("feedback",ctx.feedbackStatus or"",left,yy+128,cw,26,10,true)
   elseif s.section==2 then
    tracePanel(ctx,left,yy,cw,compact)
   elseif s.section==3 then
    row("raid_aura_member","Raid debuff check",ctx.raidCheckName or"No identified raid member",left,yy,cw,(ctx.raidCheckRows or 0)>1)
    button("raid_aura_run",left,yy+33,cw,29,"Read without targeting this member",ctx.raidCheckAvailable==true and(ctx.raidCheckRows or 0)>0)
    local r=ctx.raidCheckReport or{}
    local matches=ctx.raidCheckSubjectMatches==true
    line("raid_aura_status",r.cleanupPending and"Cleanup unverified: fully restart the game."or(not matches and"Not checked for this member. Choose Run."or((r.state or"ready")..": "..(r.reason or"Choose a member, then run the check."))),left,yy+66,cw,16,10,true)
    local target=matches and r.targetUnchangedKnown and(r.targetUnchanged and"unchanged"or"CHANGED")or"unknown"
    local remote=matches and r.nonTargetKnown and r.nonTarget and"yes"or"unknown"
    line("raid_aura_target","Target: "..target.." | Non-target member: "..remote.." | Count: "..(matches and r.infoKnown and string.format("%.0f",r.count or 0)or"unknown"),left,yy+83,cw,16,10,true)
    for i=1,4 do
     local e=matches and r.entries and r.entries[i]
     local value=e and("ID "..string.format("%.0f",e.id).." | time "..(e.remainingMsKnown and string.format("%.0f ms",e.remainingMs)or"unknown"))or(i==1 and"Compare with the original raid bar. Empty is inconclusive."or"")
     line("raid_aura_entry_"..i,value,left,yy+100+(i-1)*18,cw,16,10,true)
    end
   else
    row("raid_scan_policy","Scan balance",o.auras.scan_policy=="debuff_priority"and"Prioritise debuffs"or"Balanced",left,yy,cw)
    row("reset_raid_alerts","Reset alert history","Reset history",left,yy+33,cw)
   end
  end
  end
  if s.totalPages>1 then
   button("studio_more",pw-164,80,140,27,"Page "..s.section.." of "..s.totalPages.." >",not ctx.picker and not ctx.resetPending)
  end
  button("previous",pw-334,ph-37,68,27,"Back",s.section>1 and not ctx.picker and not ctx.resetPending and not ctx.profileLoad)
  button("next",pw-258,ph-37,68,27,"Next",s.section<s.totalPages and not ctx.picker and not ctx.resetPending)
  if s.page~="known_issues"and not ctx.profileShare and not ctx.profileLoad and not ctx.alertWarning then
   line("save",ctx.notice or ctx.saveStatus or"",18,ph-36,pw-366,27,10,true)
   button("save",pw-178,ph-37,160,27,"Save settings",ctx.canSave and not ctx.picker and not ctx.resetPending,true)
  end
  if ctx.resetPending then
   local small=ph<400;local rx,rw=left,cw
   panel("reset_cover",154,68,pw-162,math.max(1,ph-122),0.1294,0.1137,0.0980)
   local memberOrder=ctx.resetPending=="member_order"
   line("reset_question",memberOrder and"Return everyone to their original raid slots?"or"Do you want really want to reset\nor was that a missclick ?",rx,small and top+18 or top+78,rw,54,15)
   line("reset_note",memberOrder and"Clears manual moves and Priority. Sorting turns off.\nYour preset and frame settings are kept."
    or"Previewing the original 62 x 34 layout.\nOther options stay as they were.",rx,small and top+82 or top+138,rw,38,11,true)
   button("reset_accept",rx,small and ph-85 or top+200,110,32,"Yes",true,true)
   button("reset_cancel",rx+120,small and ph-85 or top+200,rw-120,32,"No, restore my previous settings",true)
  end
  if ctx.picker then
   local p=ctx.picker;local dx=math.max(8,math.min(math.floor((pw+148-390)/2),pw-398));local dy=math.max(8,math.min(math.max(68,math.floor((ph-258)/2)),ph-266))
   panel("picker_edge",dx,dy,390,258,0.5686,0.5176,0.4392)
   panel("picker_fill",dx+1,dy+1,388,256,0.1294,0.1137,0.0980)
   line("picker_title",P.text(p.label or"Choose a colour",44),dx+14,dy+8,360,24,16)
   local wx,wy,size=dx+16,dy+45,160
   local wheel=ui.buttons.picker_wheel
   if not wheel then wheel=ui.surface("picker_wheel",parent);track(wheel)end
   position(wheel,wx,wy,size,size);display(wheel,true)
   if not s.wheelAttempted then s.wheelAttempted=true;s.wheelImage=ui.wheelImage(wheel);if s.wheelImage then track(s.wheelImage)end end
   if s.wheelImage then ui.place(s.wheelImage,wheel,0,0,size,size);display(s.wheelImage,true)
   else line("picker_image_missing","Wheel image unavailable",wx+3,wy+70,size-6,30,10,true)end
   local value=ui.buttons.picker_value
   if not value then value=ui.surface("picker_value",parent);track(value)end
   local vx,vy,vw,vh=dx+188,wy,20,size
   position(value,vx,vy,vw,vh);display(value,true)
   local top=Colours.rgb(Picker.hex(p.h,p.s,1))
   s.valueStrips=s.valueStrips or{}
   for i=1,32 do
    local strip=s.valueStrips[i]
    if not strip then strip=track(ui.drawable(value,1,1,1,1));s.valueStrips[i]=strip end
    local v=1-(i-1)/31
    ui.place(strip,value,0,math.floor((i-1)*vh/32),vw,math.ceil(vh/32))
    ui.colour(strip,top[1]*v,top[2]*v,top[3]*v,1);display(strip,true)
   end
   line("picker_brightness","Brightness",dx+222,dy+42,150,20,11,true)
   line("picker_percent",math.floor(p.v*100+0.5).."%",dx+222,dy+63,150,20,13)
   line("picker_before_label","Before",dx+222,dy+90,66,18,10,true)
   line("picker_after_label","Preview",dx+302,dy+90,66,18,10,true)
   local old=Colours.rgb(p.original);local new=Colours.rgb(p.hex)
   local before=panel("picker_before",dx+222,dy+111,66,32,old[1],old[2],old[3]);ui.colour(before,old[1],old[2],old[3],1)
   local after=panel("picker_after",dx+302,dy+111,66,32,new[1],new[2],new[3]);ui.colour(after,new[1],new[2],new[3],1)
   button("picker_white",dx+222,dy+153,66,27,"White",true)
   button("picker_black",dx+302,dy+153,66,27,"Black",true)
   field("picker_hex","Colour code",p.hex,dx+222,dy+188,146)
   -- Compact custom placement avoids using the normal label/edit split here.
   local e=s.edits.picker_hex
   if e and e.object then position(e.object,dx+222,dy+188,146,27);if ui.editChrome then ui.editChrome(e.object)end end
   display(s.labels.picker_hex_label,false)
   button("picker_use",dx+16,dy+220,160,28,"Use colour",true,true)
   button("picker_cancel",dx+188,dy+220,180,28,"Cancel",true)
   s.pickerMarks=s.pickerMarks or{}
   for i=1,8 do if not s.pickerMarks[i]then s.pickerMarks[i]=track(ui.drawable(wheel,i<=4 and 0 or 1,i<=4 and 0 or 1,i<=4 and 0 or 1,1))end end
   local mx,my=Picker.marker(p.h,p.s,wx+size/2,wy+size/2,size/2)
   local function mark(i,x0,y0,mw,mh)ui.place(s.pickerMarks[i],wheel,math.floor(x0-wx),math.floor(y0-wy),mw,mh);display(s.pickerMarks[i],true)end
   mark(1,mx-5,my-5,11,2);mark(2,mx-5,my+4,11,2);mark(3,mx-5,my-3,2,7);mark(4,mx+4,my-3,2,7)
   mark(5,mx-4,my-4,9,1);mark(6,mx-4,my+4,9,1);mark(7,mx-4,my-3,1,7);mark(8,mx+4,my-3,1,7)
   local by=vy+(1-p.v)*vh
   if not s.valueMark then s.valueMark=track(ui.drawable(value,1,1,1,1))end
   ui.place(s.valueMark,value,-3,math.max(0,math.min(by-vy-1,vh-2)),vw+6,2);display(s.valueMark,true)
   s.picker_geometry={wheel={x=x+wx,y=y+wy,w=size,h=size,cx=x+wx+size/2,cy=y+wy+size/2,r=size/2},value={x=x+vx,y=y+vy,w=vw,h=vh}}
   for _,id in ipairs({"picker_wheel","picker_value","picker_use","picker_cancel","picker_white","picker_black"})do ui.bindPicker(id,p.ticket)end
   
  else s.picker_geometry=nil end
  if ctx.orderingMenu then
   local m=ctx.orderingMenu
   if not s.orderingMenuRoot and ui.orderingMenuRoot then s.orderingMenuRoot=track(ui.orderingMenuRoot("ordering_categories"))end
   if s.orderingMenuRoot then
    local mw,mh=240,32+#m.choices*29
    local mx=math.max(8,math.min(m.x,w-mw-8));local my=math.max(8,math.min(m.y,h-mh-8))
    s.orderingMenuRaise=s.orderingRaisedTicket~=m.ticket or s.orderingMenuX~=mx or s.orderingMenuY~=my
    s.orderingMenuX=mx;s.orderingMenuY=my
    ui.place(s.orderingMenuRoot,"UIParent",mx,my,mw,mh);display(s.orderingMenuRoot,true)
    if not s.orderingMenuFill then s.orderingMenuFill=track(ui.drawable(s.orderingMenuRoot,.1294,.1137,.0980,1))end
    ui.place(s.orderingMenuFill,s.orderingMenuRoot,0,0,mw,mh);display(s.orderingMenuFill,true)
    if not s.orderingMenuTitle then s.orderingMenuTitle=track(ui.label("ordering_menu_title",s.orderingMenuRoot,12))end
    ui.place(s.orderingMenuTitle,s.orderingMenuRoot,10,4,mw-20,24);ui.text(s.orderingMenuTitle,m.title);display(s.orderingMenuTitle,true)
    for i,choice in ipairs(m.choices)do
     local id="ordering_choice_"..choice;local o=ui.buttons[id]
     if not o then o=ui.button(id,s.orderingMenuRoot);track(o)end
     ui.place(o,s.orderingMenuRoot,6,28+(i-1)*29,mw-12,27)
     ui.text(o,choice=="cancel"and"Cancel"or choice=="auto"and"Use party category"or Ordering.titles[choice]);ui.enable(o,true);display(o,true)
     if ui.buttonColour then ui.buttonColour(o,choice==m.selected)end
     if ui.bindOrderingChoice then ui.bindOrderingChoice(id,m.ticket,choice)end
    end
   end
  end
  local tip
  if ctx.alertWarning then
   local dx,dw=left,cw
   local dy=math.max(80,math.floor((ph-180)/2))
   panel("alert_warning_edge",dx,dy,dw,180,.5686,.5176,.4392)
   panel("alert_warning_fill",dx+1,dy+1,dw-2,178,.1294,.1137,.0980)
   line("alert_warning_title","Debuff alerts only",dx+16,dy+12,dw-32,27,18)
   line("alert_warning_message",ctx.alertWarning.message,dx+16,dy+49,dw-32,76,12)
   button("alert_warning_ok",dx+dw-116,dy+136,100,29,"Got it",true,true)
   ui.bindEffect("alert_warning_ok",ctx.alertWarning.id)
  end
  if not ctx.resetPending and not ctx.picker and not ctx.orderingMenu and not ctx.alertWarning then for i=#helpRects,1,-1 do
   local r=helpRects[i];local mx,my=ctx.pointerX,ctx.pointerY
   if type(mx)=="number"and type(my)=="number"and mx>=x+r.x and mx<x+r.x+r.w and my>=y+r.y and my<y+r.y+r.h then tip=r;break end
  end end
  if ui.tooltip then
   ui.tooltip(tip,tip and x+tip.x+20 or 0,tip and y+tip.y+30 or 0,w,h)
  end
  if ctx.current and not ctx.current()then return end
  if ui.chromeFrame then ui.chromeFrame(parent,pw,ph,s.background,s.header)end
  if ctx.current and not ctx.current()then return end
  -- Small displays use a compact second settings page instead of clipping rows.
  if ui.textEditorVisible then ui.textEditorVisible(s.textEditorGeometry~=nil)end
  for i=1,#s.previews do if not previewWanted[i]then ui.previewShow(s.previews[i],false)end end
  for key,preview in pairs(s.materialPreviews)do if not previewWanted[key]then ui.previewShow(preview,false)end end
  s.extent={x=x,y=y,w=pw,h=ph};s.scale=1;display(parent,ctx.open==true)
  for object,value in pairs(wanted)do
   if ctx.current and not ctx.current()then return end
   ui.show(object,value)
  end
  if ui.orderingMenuInput then ui.orderingMenuInput(ctx.open==true and ctx.orderingMenu~=nil)end
  if ctx.orderingMenu and s.orderingMenuRoot and s.orderingMenuRaise then
   ui.call(s.orderingMenuRoot,"Raise");s.orderingRaisedTicket=ctx.orderingMenu.ticket;s.orderingMenuRaise=false
  end
 end
 -- Visible editor sampling uses the existing guarded UI driver, not an unverified key event.
 function s.poll(apply,current)
  for id,r in pairs(s.edits)do
   if not current()then return false end
   if r.visible and r.object then
    local ok,value=ui.call(r.object,"GetText")
    if not current()then return false end
    if ok and type(value)=="string"and value~=r.lastText then
     r.lastText=value;apply(id,value)
     if not current()then return false end
    end
   end
  end
  return true
 end
 function s.captureDrafts(current)
  local out={}
  for id,r in pairs(s.edits)do
   if current and not current()then return nil end
   local ok,value=ui.call(r.object,"GetText")
   if current and not current()then return nil end
   out[id]={text=ok and type(value)=="string"and value or r.lastText,canonical=r.canonical,lastText=r.lastText,binding=r.binding}
  end
  return out
 end
 function s.restoreDrafts(saved)
  for id,r in pairs(s.edits)do
   local old=saved and saved[id]
   if old then r.canonical=old.canonical;r.lastText=old.lastText;r.binding=old.binding;if r.object then (ui.editText or ui.text)(r.object,old.text or"")end
   else r.canonical=nil;r.lastText=nil end
  end
 end
 function s.clearDrafts()for _,r in pairs(s.edits)do r.canonical=nil;r.lastText=nil;r.restore=nil end end
 function s.pickerDraft(ticket,current)
  if not current()then return false end
  local r=s.edits.picker_hex
  if not r or not r.object then return true end
  if not r.visible or r.binding~=ticket then return false end
  local object=r.object;local ok,value=ui.call(object,"GetText")
  if not current()or s.edits.picker_hex~=r or r.object~=object or r.binding~=ticket then return false end
  if not ok or type(value)~="string"then return false end
  return true,value
 end
 function s.colourDraft(id,current)
  local r=s.edits[id];if not r then return nil end
  if current and not current()then return nil end
  local ok,value=ui.call(r.object,"GetText")
  if current and not current()then return nil end
  return {canonical=r.canonical,lastText=r.lastText,binding=r.binding,text=ok and type(value)=="string"and value or r.lastText}
 end
 function s.finishColourDraft(id,before,accepted)
  local r=s.edits[id];if not r then return end
  if accepted then r.canonical=nil;r.lastText=nil;r.restore=nil
  elseif before then r.restore=before end
 end
 function s.name()
  if not s.edit then return "Setup "..s.slot end
  local ok,v=ui.call(s.edit,"GetText");if ok and type(v)=="string"then return v end
 end
 function s.effectQuery()
  if not s.effectEdit then return ""end
  local ok,v=ui.call(s.effectEdit,"GetText");if ok and type(v)=="string"then return v:sub(1,48)end
  return ""
 end
 function s.setEffectQuery(value)
  local search=s.edits.effect_search
  if not search or not search.object then return false end
  local query=type(value)=="string"and value:sub(1,48)or""
  (ui.editText or ui.text)(search.object,query)
  search.lastText=query
  return true
 end
 function s.dimensions()
  if not s.widthEdit or not s.heightEdit then return nil end
  local a,width=ui.call(s.widthEdit,"GetText");local b,height=ui.call(s.heightEdit,"GetText")
  if a and b and type(width)=="string"and type(height)=="string"then return width,height end
 end
 function s.setDimensions(width,height)
  s.dimensionWidth=width;s.dimensionHeight=height
  if s.widthEdit then ui.text(s.widthEdit,type(width)=="number"and string.format("%.0f",width)or width)end
  if s.heightEdit then ui.text(s.heightEdit,type(height)=="number"and string.format("%.0f",height)or height)end
 end
 function s.setName(value)
  if s.edit then ui.text(s.edit,value or"")else for i=1,8 do if value=="Setup "..i then s.slot=i end end end
 end
 function s.nextSlot()s.slot=s.slot%8+1 end
 function s.move(x,y)
  local function finite(v)return type(v)=="number"and v==v and v>-1/0 and v<1/0 end
  if not finite(x)or not finite(y)then return false end
  s.position={x=x,y=y};return true
 end
 function s.select(page)
  if page=="known_issues"then s.page=page;s.section=1;s.materialsOpen=false;return true end
  for i=1,#pages do if pages[i][1]==page then s.page=page;s.section=1;s.materialsOpen=false;return true end end
  return false
 end
 function s.more()s.section=s.section%s.totalPages+1 end
 function s.stepPage(delta)s.section=math.max(1,math.min(s.totalPages,s.section+delta))end
 return s
end
return U
