-- Host-independent state and layout controls; no native API access or file IO.
local F=require("Mazrim_Raid_Frames/shared/foundation")
local P=require("Mazrim_Raid_Frames/shared/presentation")
local Preferences=require("Mazrim_Raid_Frames/shared/preferences")
local Colours=require("Mazrim_Raid_Frames/shared/colours")
local Themes=require("Mazrim_Raid_Frames/shared/themes")
local Ordering=require("Mazrim_Raid_Frames/shared/ordering")
local MemberLayout=require("Mazrim_Raid_Frames/shared/member_layout")
-- Match shared/foundation.layout_settings bounds. Values remain the exact
-- authored dimensions; viewport fitting belongs to the presentation layer.
local MIN_WIDTH,MAX_WIDTH,MIN_HEIGHT,MAX_HEIGHT=40,480,20,100
local C={alwaysShiftDragContract=1,wideNamesContract=1,layoutToolsContract=1,placementContract=1,shiftDragContract=1,nativeRaidContract=1,overhaulContract=1,
  preferencesContract=Preferences.contract==1 and 1 or 0,profileContract=Preferences.contract==1 and 1 or 0,dimensionsContract=1,
  MIN_WIDTH=MIN_WIDTH,MAX_WIDTH=MAX_WIDTH,MIN_HEIGHT=MIN_HEIGHT,MAX_HEIGHT=MAX_HEIGHT}
C.targetBuffPolicyContract=Preferences.targetBuffPolicyContract==2 and 2 or 0
local presets={
  {name="Native raid",mode="raid",width=62,height=34,columns=5},
  {name="Compact raid",mode="raid",width=104,height=36,columns=5},
  {name="Wide raid",mode="raid",width=240,height=44,columns=5},
  {name="Party list",mode="party",width=200,height=44,columns=1}}
local function presetIndex(c)
  local layout=c.settings[c.view.layout]
  for i=1,#presets do
    local p=presets[i]
    if c.view.layout==p.mode and layout.width==p.width and layout.height==p.height
      and layout.gap_x==3 and layout.gap_y==(i==1 and 0 or 3) then return i end
  end
  return 0
end
function C.presetName(c)
  local i=presetIndex(c);return i>0 and presets[i].name or "Custom"
end
local function cycle(value,values)
  for i=1,#values do if value==values[i] then return values[i%#values+1] end end
  return values[1]
end
function C.new(config)
  config.options=Preferences.validate(config.options)or Preferences.defaults()
  config.profiles=config.profiles or {}
  config.visibility=Preferences.validateVisibility(config.visibility)or Preferences.visibilityDefaults()
  -- Adopt the owner's requested overhaul once, in memory; never auto-write.
  if config.view.native_style~=true then
    config.view.native_style=true;config.view.layout="raid"
    config.settings.raid={width=62,height=34,columns=5,gap_x=3,gap_y=0,grow_x="right",grow_y="down"}
    config.settings.display.health_text="none";config.settings.display.show_mana=true
  end
  local s={config=config,mode="preview",page=1,revision=0,live=nil,profile_status="Profiles save your frame setup. Your hover choice is kept separately."}
  local resetBefore=nil
  function s.setDimensions(width,height)
    local function dimension(value,lo,hi)
      return type(value)=="number"and value==value and value>=lo and value<=hi and value%1==0
    end
    if not dimension(width,MIN_WIDTH,MAX_WIDTH)or not dimension(height,MIN_HEIGHT,MAX_HEIGHT)then return false end
    local layout=config.settings[config.view.layout]
    if type(layout)~="table"then return false end
    layout.width=width;layout.height=height
    s.page=1;s.revision=s.revision+1;return true
  end
  function s.setDimension(key,value)
    local layout=config.settings[config.view.layout]
    if type(layout)~="table"then return false end
    if key=="width"then return s.setDimensions(value,layout.height)end
    if key=="height"then return s.setDimensions(layout.width,value)end
    return false
  end
  function s.setSpacing(value)
    if type(value)~="number"or value~=value or value<0 or value>24 or value%1~=0 then return false end
    local layout=config.settings[config.view.layout];if type(layout)~="table"then return false end
    layout.gap_x=value;layout.gap_y=value;s.page=1;s.revision=s.revision+1;return true
  end
  function s.setOption(section,key,value)
    if section=="appearance"and key=="theme"and not Themes.accepts(value)then return false end
    local options=Preferences.copy(config.options)
    if not options or type(section)~="string"or type(key)~="string"or type(options[section])~="table"or options[section][key]==nil then return false end
    options[section][key]=value
    local checked=Preferences.validate(options);if not checked then return false end
    config.options=checked;s.revision=s.revision+1;return true
  end
  function s.setClassColour(name,value)
    if not Colours.className(name)then return false end
    if value~=nil and(type(value)~="string"or Colours.hex(value)~=value)then return false end
    local classes=Preferences.copy(config.options.colours.classes);if not classes then return false end
    classes[name]=value;return s.setOption("colours","classes",classes)
  end
  function s.setDpsColour(family,value)
    if family~="mage"and family~="ranged"and family~="melee"then return false end
    if value~=nil and(type(value)~="string"or Colours.hex(value)~=value)then return false end
    local map=Preferences.copy(config.options.colours.dps);if not map then return false end
    map[family]=value;return s.setOption("colours","dps",map)
  end
  function s.setFramesVisible(value)
    if type(value)~="boolean"then return false end
    config.visibility={frames=value};s.revision=s.revision+1;return true
  end
  local priorityOrigins={}
  local function trackPriorityOrigins(rows,before,after)
    local old=MemberLayout.project(rows,before);local next=MemberLayout.project(rows,after)
    if not old or not next then return end
    local main={};for _,p in ipairs(old.main)do local row=rows[p.row_index];if MemberLayout.unique(rows,row)then main[row.name]=p end end
    for _,p in ipairs(next.priority)do local row=rows[p.row_index];local prior=main[row.name]
      if prior then local assigned=before.enabled and before.assignments[row.name]or nil
        priorityOrigins[row.name]={name=row.name,identity=row.identity,slot=row.slot,group=prior.group,order=prior.position,
          assigned=assigned~=nil,pinned=before.raid_pins[row.name]==true}
      end
    end
    for name in pairs(priorityOrigins)do local a=after.assignments[name]
      if not a or a.group~="priority"then priorityOrigins[name]=nil end
    end
  end
  function s.resetPriorityMember(name,identity,slot)
    local changed,reason=MemberLayout.resetPriority(s.data().rows,config.options.member_layout,name,identity,priorityOrigins[name],slot)
    if not changed then return false end
    config.options.member_layout=changed;priorityOrigins[name]=nil;s.page=1;s.revision=s.revision+1
    return true,reason
  end
  function s.setMemberAssignment(name,group,order)
    local nextLayout=MemberLayout.set(config.options.member_layout,name,group,order)
    if not nextLayout then return false end
    trackPriorityOrigins(s.data().rows,config.options.member_layout,nextLayout)
    config.options.member_layout=nextLayout;s.page=1;s.revision=s.revision+1;return true
  end
  function s.clearMemberAssignment(name)return s.setMemberAssignment(name,"original")end
  function s.resetMemberLayout()
    priorityOrigins={};config.options.member_layout=MemberLayout.defaults();s.page=1;s.revision=s.revision+1;return true
  end
  function s.moveMember(name,group,order)
    local rows=s.data().rows
    local changed=MemberLayout.move(rows,config.options.member_layout,name,group,order)
    if not changed then return false end
    trackPriorityOrigins(rows,config.options.member_layout,changed)
    config.options.member_layout=changed;s.revision=s.revision+1;return true
  end
  function s.setOrdering(value)
    local checked=Ordering.validate(value);if not checked then return false end
    config.options.member_layout.ordering=checked
    if checked.enabled then config.options.member_layout.enabled=true end
    s.page=1;s.revision=s.revision+1;return true
  end
  local function clearRaidPins(m)
    local changed=false
    for name in pairs(m.raid_pins)do m.assignments[name]=nil;changed=true end
    m.raid_pins={}
    if changed then m.manual_slots=false end
    return changed
  end
  function s.confirmRaidEnded()
    priorityOrigins={}
    if resetBefore then
      resetBefore.origins={}
      clearRaidPins(resetBefore.member_layout)
    end
    local changed=clearRaidPins(config.options.member_layout)
    if changed then s.revision=s.revision+1 end
    return changed
  end
  function s.sortMembers()
    local m=config.options.member_layout;m.enabled=true;m.manual_slots=false
    for _ in pairs(m.raid_pins)do m.manual_slots=true;break end
    m.sort=m.sort=="class"and"native"or"class"
    for name,a in pairs(m.assignments)do if a.group~="priority"and not m.raid_pins[name]then m.assignments[name]=nil end end
    s.page=1;s.revision=s.revision+1;return true
  end
  function s.setDockPosition(x,y)
    if type(x)~="number"or type(y)~="number"or x~=x or y~=y or x<0 or y<0 or x>32768 or y>32768 then return false end
    config.options.member_layout.dock={custom_position=true,x=math.floor(x),y=math.floor(y)};s.revision=s.revision+1;return true
  end
  function s.setPriorityPosition(x,y)
    local plan=s.last_plan;local p=plan and plan.priority
    if not p or type(x)~="number"or type(y)~="number"or x~=x or y~=y or x<=-1/0 or x>=1/0 or y<=-1/0 or y>=1/0 then return false end
    config.options.member_layout.priority={custom_position=true,
      x=math.floor(math.max(12,math.min(x,plan.screen_w-p.width-12,32768))),
      y=math.floor(math.max(12,math.min(y,plan.screen_h-p.height-12,32768)))}
    s.revision=s.revision+1;return true
  end
  function s.setAlertPosition(x,y)
    if type(x)~="number"or type(y)~="number"or x~=x or y~=y or x<0 or y<0 or x>32768 or y>32768 then return false end
    config.options.alerts={custom_position=true,x=math.floor(x),y=math.floor(y)}
    s.revision=s.revision+1;return true
  end
  local function resetLayout()
    config.settings.raid={width=62,height=34,columns=5,gap_x=3,gap_y=0,grow_x="right",grow_y="down"}
    config.settings.party=F.settings().party
    config.settings.display.font_size=F.settings().display.font_size
    config.view.layout="raid";config.view.native_style=true;config.view.compact=false;config.view.locked=true
    config.view.position="left";config.view.x=nil;config.view.y=nil
    config.options.member_layout=MemberLayout.defaults();config.options.alerts=MemberLayout.position()
    s.page=1;s.revision=s.revision+1
  end
  function s.beginReset(memberOrder)
    if resetBefore then return false end
    resetBefore=Preferences.copy({settings=config.settings,view=config.view,member_layout=config.options.member_layout,alerts=config.options.alerts})
    if not resetBefore then return false end
    resetBefore.page=s.page;resetBefore.origins=priorityOrigins
    priorityOrigins={};s.reset_pending=true
    if memberOrder then
      local m=config.options.member_layout
      m.assignments={};m.raid_pins={};m.sort="native";m.manual_slots=false
      m.enabled=false;m.ordering.enabled=false
      s.page=1;s.revision=s.revision+1
    else resetLayout()end
    return true
  end
  function s.acceptReset()
    if not resetBefore then return false end
    resetBefore=nil;s.reset_pending=false;s.revision=s.revision+1;return true
  end
  function s.cancelReset()
    if not resetBefore then return false end
    config.settings=resetBefore.settings;config.view=resetBefore.view;s.page=resetBefore.page
    config.options.member_layout=resetBefore.member_layout;config.options.alerts=resetBefore.alerts
    priorityOrigins=resetBefore.origins
    resetBefore=nil;s.reset_pending=false;s.revision=s.revision+1;return true
  end
  function s.resetPending()return resetBefore~=nil end
  function s.profileNames()
    local names={}
    for name in pairs(config.profiles)do
      local i=#names+1
      while i>1 and names[i-1]>name do names[i]=names[i-1];i=i-1 end
      names[i]=name
    end
    return names
  end
  function s.profileSnapshot()
    local snapshot=Preferences.snapshot(config,true)
    if not snapshot then return nil end
    local ml=snapshot.options.member_layout
    for name in pairs(ml.raid_pins)do ml.assignments[name]=nil end
    ml.raid_pins={}
    return snapshot
  end
  function s.saveProfile(value)
    local name=Preferences.profileName(value)
    if not name then s.profile_status="Use a profile name of 1–24 characters.";return false end
    local names=s.profileNames()
    if config.profiles[name]==nil and #names>=Preferences.MAX_PROFILES then s.profile_status="Eight profiles are saved; delete one or replace a named profile.";return false end
    local snapshot=s.profileSnapshot()
    if not snapshot then s.profile_status="Current settings are invalid; profile was not saved.";return false end
    config.profiles[name]=snapshot;s.revision=s.revision+1
    s.profile_status="Profile saved: "..name..". Save settings to keep it.";return true
  end
  function s.loadProfile(value)
    local name=Preferences.profileName(value)
    local snapshot=name and config.profiles[name]and Preferences.snapshot(config.profiles[name],true)or nil
    if not snapshot then s.profile_status="Choose a valid saved profile.";return false end
    -- A profile never changes the live reader or session mode. Lock placement
    -- before View explicitly cancels/repaints input for the new geometry.
    snapshot.view.locked=true
    local current=config.options.member_layout
    local ml=snapshot.options.member_layout
    for name in pairs(ml.raid_pins)do ml.assignments[name]=nil end
    ml.raid_pins={}
    for name in pairs(current.raid_pins)do
      ml.assignments[name]=current.assignments[name];ml.raid_pins[name]=true;ml.enabled=true;ml.manual_slots=true
    end
    if not MemberLayout.validate(ml)then s.profile_status="Profile exceeds the member limit with this raid's pinned placements. Current layout kept.";return false end
    config.settings=snapshot.settings;config.view=snapshot.view;config.options=snapshot.options
    s.page=1;s.revision=s.revision+1
    s.profile_status="Profile loaded: "..name..". Your hover choice is kept separately.";return true
  end
  function s.deleteProfile(value)
    local name=Preferences.profileName(value)
    if not name or config.profiles[name]==nil then s.profile_status="Choose a saved profile to delete.";return false end
    config.profiles[name]=nil;s.revision=s.revision+1
    s.profile_status="Profile deleted. Save settings to keep this change.";return true
  end
  function s.setPosition(x,y)
    if type(x)~="number" or type(y)~="number"
      or x~=x or y~=y or x<=-1/0 or x>=1/0 or y<=-1/0 or y>=1/0 then return false end
    local p=s.last_plan;if not p then return false end
    config.view.position="custom"
    config.view.x=math.floor(math.max(12,math.min(x,p.screen_w-p.width-12,32768)))
    config.view.y=math.floor(math.max(12,math.min(y,p.screen_h-p.height-12,32768)))
    s.revision=s.revision+1;return true
  end
  function s.action(name)
    local c=s.config;local layout=c.settings[c.view.layout]
    if name=="mode" then s.mode=s.mode=="preview" and "live" or "preview"
    elseif name=="lock" then c.view.locked=not (c.view.locked~=false)
    elseif name=="reset_layout" then
      resetLayout();return true
    elseif name=="compact" then c.view.compact=not c.view.compact
    elseif name=="preset" then
      local p=presets[presetIndex(c)%#presets+1]
      c.view.layout=p.mode;local l=c.settings[p.mode]
      l.width=p.width;l.height=p.height;l.columns=p.columns;l.gap_x=3;l.gap_y=p.width==62 and 0 or 3
    elseif name=="count" then c.view.preview_count=cycle(c.view.preview_count,{5,25,50})
    elseif name=="layout" then c.view.layout=c.view.layout=="raid" and "party" or "raid"
    elseif name=="size" then
      local presets=c.view.layout=="party" and {{180,40},{200,44},{240,52}} or {{62,34},{104,36},{132,44},{156,52},{240,44}}
      local found=0
      for i=1,#presets do if layout.width==presets[i][1] and layout.height==presets[i][2] then found=i end end
      local p=presets[found%#presets+1];layout.width=p[1];layout.height=p[2]
    elseif name=="gap" then layout.gap_x=cycle(layout.gap_x,{0,3,6,10});layout.gap_y=layout.gap_x
    elseif name=="columns" then layout.columns=cycle(layout.columns,c.view.layout=="party" and {1,2,3,5} or {5,8,10})
    elseif name=="mana" then c.settings.display.show_mana=not c.settings.display.show_mana
    elseif name=="health" then c.settings.display.health_text=cycle(c.settings.display.health_text,{"percent","current","missing","none"})
    elseif name=="position" then
      c.view.position=cycle(c.view.position,{"left","centre","right"});c.view.x=nil;c.view.y=nil
    elseif name=="previous" then s.page=math.max(1,s.page-1)
    elseif name=="next" then s.page=s.page+1
    else return false end
    if name~="previous" and name~="next" then s.page=1 end
    s.revision=s.revision+1;return true
  end
  function s.data()
    if s.mode=="preview" then return P.preview(s.config.view.preview_count) end
    return s.live or {source="live",rows={
      {name="You - waiting",health=F.resource(nil,nil),mana=F.resource(nil,nil),state="WAITING"},
      {name="Target - waiting",health=F.resource(nil,nil),mana=F.resource(nil,nil),state="WAITING"}},
      coverage="SELF_TARGET_ONLY_NO_ROSTER"}
  end
  function s.screen(w,h,priorityDrop)
    for name in pairs(priorityOrigins)do local a=config.options.member_layout.assignments[name]
      if not a or a.group~="priority"then priorityOrigins[name]=nil end
    end
    local data=s.data();if s.mode=="live"and data.source=="raid"and data.membershipEmptyConfirmed==true then s.confirmRaidEnded()end;local requested=type(s.page)=="number"and s.page==s.page and s.page>-1/0 and s.page<1/0 and math.floor(s.page)or 1
    local plan,err=P.memberLayout(data,s.config.view.layout,s.config.settings,w,h,requested,s.config.options.member_layout)
    if not plan then return nil,err end
    local priority=P.priorityLayout(plan.priority_rows or{},s.config.view.layout,s.config.settings,w,h,requested,priorityDrop==true)
    if priority then plan.pages=math.max(plan.pages,priority.pages);plan.page=math.max(1,math.min(requested,plan.pages))end
    s.page=plan.page
    local pos=s.config.view.position
    local x=20
    if pos=="centre" then x=math.floor((w-plan.width)/2)
    elseif pos=="right" then x=w-plan.width-20
    elseif pos=="custom" then x=s.config.view.x end
    x=math.max(12,math.min(x,w-plan.width-12))
    local y=pos=="custom" and s.config.view.y or 100
    y=math.max(12,math.min(y,h-plan.height-12))
    plan.x=x;plan.y=y;plan.data=data;plan.mode=s.mode;plan.screen_w=w;plan.screen_h=h
    if priority then
      local position=config.options.member_layout.priority
      priority.x=math.floor(math.max(12,math.min(position.custom_position and position.x or x+plan.width+12,w-priority.width-12)))
      priority.y=math.floor(math.max(12,math.min(position.custom_position and position.y or y,h-priority.height-12)))
      plan.priority=priority
    end
    s.last_plan=plan;return plan
  end
  return s
end
return C
