local B=require("Mazrim_Raid_Frames/standalone/bridge")
local F=require("Mazrim_Raid_Frames/shared/foundation")
local Preferences=require("Mazrim_Raid_Frames/shared/preferences")
local S={PATH="Mazrim_Raid_Frames/.data/settings.txt",TUTORIAL_PATH="Mazrim_Raid_Frames/.data/tutorial.txt",TRACE_PATH="Mazrim_Raid_Frames/.data/target-check.txt",managerDataContract=1,SCHEMA="mazrim.raid.basics.settings.v1",compactContract=1,placementContract=1,nativeRaidContract=1,overhaulContract=1,
  preferencesContract=Preferences.contract==1 and 1 or 0,profileContract=Preferences.contract==1 and 1 or 0,
  managementHintContract=Preferences.helpContract==1 and 1 or 0,watchlistContract=Preferences.watchlistContract==1 and 1 or 0,
  priorityContract=Preferences.priorityContract==1 and 1 or 0}
S.targetBuffPolicyContract=Preferences.targetBuffPolicyContract==2 and 2 or 0
function S.defaults()
  return {schema=S.SCHEMA,settings=F.settings(),view={layout="raid",preview_count=25,position="left",compact=false,locked=true},
    options=Preferences.defaults(),profiles={},help=Preferences.helpDefaults(),visibility=Preferences.visibilityDefaults(),controls={hover=false,native_frames="unchanged"}}
end
local function controls(raw)
  if raw==nil then return {hover=false,native_frames="unchanged"}end
  if type(raw)~="table"then return nil end
  for key in pairs(raw)do if key~="hover"and key~="native_frames"then return nil end end
  if type(raw.hover)~="boolean"or(type(raw.native_frames)~="boolean"and raw.native_frames~="unchanged")then return nil end
  return {hover=raw.hover,native_frames=raw.native_frames}
end
function S.equal(a,b)
  local budget=Preferences.MAX_COPY_NODES
  local function compare(x,y,depth)
    budget=budget-1
    if budget<0 or depth>10 or type(x)~=type(y) then return false end
    if type(x)~="table" then return (type(x)=="string" or type(x)=="boolean" or B.finite(x) or x==nil) and x==y end
    local nx,ny=0,0
    for k,v in pairs(x) do
      nx=nx+1
      if nx>Preferences.MAX_TABLE_FIELDS or type(k)~="string" or not compare(v,y[k],depth+1) then return false end
    end
    for _ in pairs(y) do ny=ny+1;if ny>Preferences.MAX_TABLE_FIELDS then return false end end
    return nx==ny
  end
  return compare(a,b,0)
end
local function validateCore(raw,profile)
  if type(raw)~="table"or(not profile and raw.schema~=S.SCHEMA)or type(raw.view)~="table"then return nil end
  local c=Preferences.snapshot(raw,false);if not c then return nil end
  local v=raw.view
  if not profile then c.schema=S.SCHEMA end
  if not profile then c.controls=controls(raw.controls);if not c.controls then return nil end end
  if not profile and raw.help~=nil then
    c.help=Preferences.validateHelp(raw.help);if not c.help then return nil end
  end
  if not profile and raw.visibility~=nil then
    c.visibility=Preferences.validateVisibility(raw.visibility);if not c.visibility then return nil end
  end
  if not profile and raw.profiles~=nil then
    if type(raw.profiles)~="table"then return nil end
    c.profiles={};local count=0
    for name,snapshot in pairs(raw.profiles)do
      count=count+1
      if count>Preferences.MAX_PROFILES or Preferences.profileName(name)~=name then return nil end
      local p=validateCore(snapshot,true);if not p then return nil end
      c.profiles[name]=p
    end
  end
  local comparable=Preferences.copy(c)
  if not comparable then return nil end
  if not profile and raw.controls==nil then comparable.controls=nil end
  -- Reconstruct only reviewed legacy representations for strict comparison.
  -- Validators have already rejected malformed/unknown fields. Return `c` in
  -- canonical form, leaving the original file untouched until explicit Save.
  local function legacyWatch(checked,original)
    local a=checked.options and checked.options.auras
    local old=original.options and original.options.auras
    if type(a)=="table"and type(old)=="table"then
      for _,key in ipairs({"selected_only","watch","debuff_colours","priorities","frame_rules","raid_tracker","large_alerts","alerts","scan_policy","target_buffs_only","hot_helper_ids"})do if old[key]==nil then a[key]=nil end end
      if old.debuff_colours~=nil then a.debuff_colours=Preferences.copy(old.debuff_colours)end
      if old.frame_rules~=nil then a.frame_rules=Preferences.copy(old.frame_rules)end
    end
    local options,oldOptions=checked.options,original.options
    if oldOptions==nil then checked.options=nil end
    if type(options)=="table"and type(oldOptions)=="table"then
      -- v0.2.43 added icon placement and the warning style. Older saved
      -- setups/profiles omit them; compare their reviewed legacy shape while
      -- returning the validated defaults in `c`, without rewriting the file.
      if oldOptions.aura_icons==nil then options.aura_icons=nil end
      if type(options.aura_icons)=="table"and type(oldOptions.aura_icons)=="table"then
        for _,key in ipairs({"grouped","anchor","positions"})do if oldOptions.aura_icons[key]==nil then options.aura_icons[key]=nil end end
      end
      if oldOptions.text_positions==nil then options.text_positions=nil end
      if type(options.text_positions)=="table"and type(oldOptions.text_positions)=="table"then
        for _,key in ipairs({"name","health","distance"})do if oldOptions.text_positions[key]==nil then options.text_positions[key]=nil end end
      end
      if type(options.indicators)=="table"and type(oldOptions.indicators)=="table"then
        for _,key in ipairs({"health_style","hatch_mode","hatch_opacity"})do if oldOptions.indicators[key]==nil then options.indicators[key]=nil end end
      end
      if oldOptions.member_layout==nil then options.member_layout=nil end
      if type(oldOptions.member_layout)=="table"and type(options.member_layout)=="table"then
        for _,key in ipairs({"dock","sort","manual_slots","ordering","raid_pins"})do if oldOptions.member_layout[key]==nil then options.member_layout[key]=nil end end
      end
      if oldOptions.alerts==nil then options.alerts=nil end
      if oldOptions.colours==nil then options.colours=nil
      elseif type(options.colours)=="table"and type(oldOptions.colours)=="table"then
        for key in pairs(options.colours)do if oldOptions.colours[key]==nil then options.colours[key]=nil end end
        if oldOptions.colours.palette_version==nil or oldOptions.colours.palette_version==1 then
          options.colours.palette_version=oldOptions.colours.palette_version
          if oldOptions.colours.healer=="A36EBA"then options.colours.healer="A36EBA"end
        end
      end
      if type(options.input)=="table"and type(oldOptions.input)=="table"and oldOptions.input.return_target==nil then options.input.return_target=nil end
      local appearance,oldAppearance=options.appearance,oldOptions.appearance
      if type(appearance)=="table"and type(oldAppearance)=="table"then
        if oldAppearance.opacity==nil then appearance.opacity=nil end
        if oldAppearance.role_icon==nil then appearance.role_icon=nil end
        if oldAppearance.show_distance==nil then appearance.show_distance=nil end
        if oldAppearance.theme~=nil then appearance.theme=oldAppearance.theme end
      end
    end
    if checked.profiles then for name,p in pairs(checked.profiles)do legacyWatch(p,original.profiles[name])end end
  end
  legacyWatch(comparable,raw)
  if not S.equal(comparable,raw) then return nil end
  -- Legacy files load without rewriting or discarding any settings.
  c.view.compact=v.compact==true
  c.view.locked=v.locked~=false
  c.options=c.options or Preferences.defaults()
  if not profile then
    c.profiles=c.profiles or {};c.help=c.help or Preferences.helpDefaults()
    c.visibility=c.visibility or Preferences.visibilityDefaults()
  end
  return c
end
function S.validate(raw)return validateCore(raw,false)end
function S.new(api,alive)
  local f=B.member(api,"File")
  local s={blocked=false,status="Not saved yet.",managementHintContract=S.managementHintContract}
  local function active(guard)
    for _,fn in ipairs({alive or false,guard or false})do
      if type(fn)=="function"then local ok,v=pcall(fn);if not ok or v~=true then return false end end
    end
    return true
  end
  local function fileCall(guard,key,...)
    if not active(guard)then return false end
    local fn=B.member(f,key)
    if not active(guard)or type(fn)~="function"then return false end
    local ok,value=pcall(fn,f,...)
    if not active(guard)then return false end
    return ok,value
  end
  local function tutorial(value)
    if type(value)~="table"or value.schema~="mazrim.raid.tutorial.v1"or value.shown~=true then return false end
    for key in pairs(value)do if key~="schema"and key~="shown"then return false end end
    return true
  end
  -- The manual transition keeps the old root files. If one remains, migrate
  -- only validated data, keep an exact semantic backup, and verify both writes.
  -- This cannot recover root files removed by a manager BEFORE this code runs.
  local resolved={}
  local function read(path,guard)
    local ok,value=fileCall(guard,"Read",path)
    if not ok then return false end
    local tried=resolved[path];resolved[path]=true
    -- A readback failure must never trigger another migration or replace a
    -- partially written primary with stale legacy data.
    if value~=nil or tried then return true,value end
    local legacy=path==S.PATH and"Mazrim_Raid_Frames/settings.txt"
      or path==S.TUTORIAL_PATH and"Mazrim_Raid_Frames/tutorial.txt"
    if not legacy then return true,nil end
    local good,raw=fileCall(guard,"Read",legacy)
    if not good or raw==nil then return good,raw end
    if(path==S.PATH and not S.validate(raw))or(path==S.TUTORIAL_PATH and not tutorial(raw))then return true,raw end
    local copy=Preferences.copy(raw)
    if not copy or not S.equal(raw,copy)then return false end
    local backup=path==S.PATH and"Mazrim_Raid_Frames/.data/legacy-settings.txt"or"Mazrim_Raid_Frames/.data/legacy-tutorial.txt"
    local known,existing=fileCall(guard,"Read",backup)
    if not known or(existing~=nil and not S.equal(existing,copy))then return false end
    local function checkedWrite(target)
      local written,result=fileCall(guard,"Write",target,copy)
      if not written or result==false then return false end
      local checked,after=fileCall(guard,"Read",target)
      return checked and S.equal(copy,after)
    end
    if existing==nil and not checkedWrite(backup)then return false end
    if not checkedWrite(path)then return false end
    return true,copy
  end
  function s.tutorialSeen(current)
    if not current()then return nil end
    local ok,value=read(S.TUTORIAL_PATH,current)
    if not current()or not ok then return nil end
    if value==nil then return false end
    if type(value)~="table"or value.schema~="mazrim.raid.tutorial.v1"or value.shown~=true then return nil end
    for key in pairs(value)do if key~="schema"and key~="shown"then return nil end end
    return true
  end
  function s.rememberTutorialSeen(current)
    local seen=s.tutorialSeen(current)
    if seen~=false then return seen==true end
    local value={schema="mazrim.raid.tutorial.v1",shown=true}
    local ok,written=B.call(f,"Write",S.TUTORIAL_PATH,value)
    if not current()or not ok or written==false then return false end
    local read,confirmed=B.call(f,"Read",S.TUTORIAL_PATH)
    return current()and read and S.equal(value,confirmed)
  end
  function s.load()
    local ok,v=read(S.PATH)
    if not ok then s.blocked=true;s.status="Settings unreadable; saving blocked.";return S.defaults() end
    if v==nil then s.status="Default layout. Use Save settings to keep changes.";return S.defaults() end
    local cleaned=S.validate(v)
    if not cleaned then s.blocked=true;s.status="Unrecognised settings preserved; saving blocked.";return S.defaults() end
    -- Loading returns control intent only; the owning host applies it.
    s.status=cleaned.controls.hover and"Saved layout and control choices loaded."or"Saved layout loaded. Hover targeting stays off until enabled.";return cleaned
  end
  function s.save(config)
    if s.blocked then return false end
    local c=S.validate(config)
    if not c then s.status="Invalid settings; nothing written.";return false end
    -- Sorting templates persist; Ctrl-drag placements belong to this admitted
    -- raid context only. Saving never removes them from the running controller.
    local members=c.options.member_layout
    for name in pairs(members.raid_pins)do members.assignments[name]=nil end
    members.raid_pins={}
    local ok,v=B.call(f,"Write",S.PATH,c)
    if not ok or v==false then s.status="Save failed; changes remain in this session.";return false end
    local good,copy=B.call(f,"Read",S.PATH)
    if not good or not S.equal(c,copy) then s.status="Save attempted; read-back NOT confirmed.";return false end
    s.status="Saved and checked: "..S.PATH;return true
  end
  -- Add one saved profile while leaving unrelated disk data intact.
  function s.saveNewProfile(name,profile,current,owner)
    if s.blocked or not current()then return false,"Settings are unavailable for saving."end
    if name==nil or Preferences.profileName(name)~=name then return false,"Invalid profile name."end
    local function fileCall(guard,key,...)
      if key=="Read"then return read(...,guard)end
      local fn=B.member(f,key)
      if not guard()or type(fn)~="function"then return false end
      return pcall(fn,f,...)
    end
    local good,raw=fileCall(current,"Read",S.PATH)
    if not current()then return false,"Profile save cancelled."end
    if not good or(raw~=nil and not S.validate(raw))then
      s.blocked=true;return false,"Saved settings could not be read."
    end
    local payload=Preferences.copy(raw or S.defaults())
    if not payload then return false,"Saved settings could not be copied."end
    payload.profiles=payload.profiles or{}
    if payload.profiles[name]then return false,"That name is already saved. Choose a different one."end
    payload.profiles[name]=profile
    if not S.validate(payload)then return false,"Could not add the profile. Check the eight-profile limit."end
    local ok,written=fileCall(current,"Write",S.PATH,payload)
    if not ok or written==false then return false,"Profile save failed."end
    if not owner()then return false,"Profile save cancelled."end
    local confirmed,readback=fileCall(owner,"Read",S.PATH)
    if not confirmed or not S.equal(payload,readback)then
      s.blocked=true;return false,"Profile save could not be verified. Reopen the addon before saving again."
    end
    return owner()
  end
  -- This explicit dismissal persists only global help, never the live layout
  -- or profile collection. Reread the disk so other valid saved changes survive.
  -- Preserve its legacy shape rather than implicitly writing migration defaults.
  function s.rememberManagementHint(value,current)
    if type(current)~="function"then return false end
    local function active()local ok,live=pcall(current);return ok and live==true end
    if not active()then return false end
    if s.blocked then return false end
    if value~=false then s.status="Invalid help preference; nothing written.";return false end
    local function fileCall(key,...)
      if not active()then return false,nil,false end
      if key=="Read"then local ok,value=read(...,current);return ok,value,active()end
      local fn=B.member(f,key)
      if not active()then return false,nil,false end
      if type(fn)~="function"then return false,nil,true end
      local ok,result=pcall(fn,f,...)
      if not active()then return false,nil,false end
      return ok,result,true
    end
    local good,raw,live=fileCall("Read",S.PATH)
    if not live then return false end
    if not good then s.blocked=true;s.status="Settings unreadable; saving blocked.";return false end
    if raw==nil then raw=S.defaults()
    elseif not S.validate(raw)then
      s.blocked=true;s.status="Unrecognised settings preserved; saving blocked.";return false
    end
    if type(raw.help)=="table"and raw.help.raid_management==false then
      s.status="Raid management explanation already hidden.";return true
    end
    local payload=Preferences.copy(raw)
    if not payload then s.status="Invalid settings; nothing written.";return false end
    payload.help={raid_management=false}
    if not S.validate(payload)then s.status="Invalid settings; nothing written.";return false end
    local ok,written,live=fileCall("Write",S.PATH,payload)
    if not live then return false end
    if not ok or written==false then s.status="Help preference save failed; other changes remain unsaved.";return false end
    local confirmed,readback,live=fileCall("Read",S.PATH)
    if not live then return false end
    if not confirmed or not S.equal(payload,readback)then
      s.blocked=true;s.status="Help preference read-back NOT confirmed; saving blocked.";return false
    end
    s.status="Raid management explanation hidden. Other changes remain unsaved.";return true
  end
  -- Only explicit global control choices use this narrow write. Reread and
  -- clone the saved file; never accept or auto-save the live frame options.
  function s.rememberControls(patch,current)
    if type(current)~="function"then return false end
    local function active()local ok,live=pcall(current);return ok and live==true end
    if not active()or s.blocked then return false end
    local choice={};local count=0
    if type(patch)~="table"then s.status="Invalid control choice; nothing written.";return false end
    for key,value in pairs(patch)do
      if(key~="hover"and key~="native_frames")or(key=="hover"and type(value)~="boolean")
        or(key=="native_frames"and type(value)~="boolean"and value~="unchanged")then
        s.status="Invalid control choice; nothing written.";return false
      end
      choice[key]=value;count=count+1
    end
    if count==0 then s.status="Invalid control choice; nothing written.";return false end
    local function fileCall(key,...)
      if not active()then return false,nil,false end
      if key=="Read"then local ok,value=read(...,current);return ok,value,active()end
      local fn=B.member(f,key)
      if not active()then return false,nil,false end
      if type(fn)~="function"then return false,nil,true end
      local ok,result=pcall(fn,f,...)
      if not active()then return false,nil,false end
      return ok,result,true
    end
    local good,raw,live=fileCall("Read",S.PATH)
    if not live then return false end
    if not good then s.blocked=true;s.status="Settings unreadable; control choice not saved.";return false end
    local existing=raw~=nil and type(raw)=="table"and type(raw.controls)=="table"
    if raw==nil then raw=S.defaults()
    elseif not S.validate(raw)then s.blocked=true;s.status="Unrecognised settings preserved; saving blocked.";return false end
    local nextControls=controls(raw.controls)
    if not nextControls then s.blocked=true;s.status="Unrecognised settings preserved; saving blocked.";return false end
    for key,value in pairs(choice)do nextControls[key]=value end
    if existing and S.equal(nextControls,raw.controls)then s.status="Control choice already saved. Other changes remain unsaved.";return true end
    local payload=Preferences.copy(raw)
    if not payload then s.status="Invalid settings; control choice not saved.";return false end
    payload.controls=nextControls
    if not S.validate(payload)then s.status="Invalid settings; control choice not saved.";return false end
    local ok,written,live=fileCall("Write",S.PATH,payload)
    if not live then return false end
    if not ok or written==false then s.status="Control choice save failed; other changes remain unsaved.";return false end
    local confirmed,readback,live=fileCall("Read",S.PATH)
    if not live then return false end
    if not confirmed or not S.equal(payload,readback)then s.blocked=true;s.status="Control choice read-back NOT confirmed; saving blocked.";return false end
    s.status="Control choice saved. Other changes remain unsaved.";return true
  end
  return s
end
return S
