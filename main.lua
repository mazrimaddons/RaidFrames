-- Standalone lifecycle. Shared data reader and renderer are first-party modules.
local addon={name="Mazrim Raid Frames",author="Mazrim",version="0.2.75",
  desc="Self/target frames. Preview build."}
local current,generation,opening=nil,0,false
local function member(object,key)
  local ok,value=pcall(function()return object and object[key]end)
  return ok and value or nil
end
local function restartMessage(api)
  local log=member(api,"Log");local info=member(log,"Info")
  if type(info)=="function"then pcall(info,log,"Mazrim Raid Frames: Full game restart required to load the updated raid modules.")end
end
local function closeState(s)
  if not s then return true end
  s.live=false
  if s.panel then s.panel.active=false;s.panel.visible=false end
  if s.starting or s.closing then return false end
  s.closing=true
  if s.target then
    -- Feedback has no owned native resources. Revoked host guards make its
    -- cancellation best effort; it must never prevent listener teardown.
    local cancel=member(s.target,"cancel");s.target=nil
    if type(cancel)=="function"then pcall(cancel)end
  end
  -- These services own no widgets, listeners or jobs. Revoke their retained
  -- closures even if an optional pure close fails; critical cleanup continues.
  for _,key in ipairs({"trace","selection","auraSource","returnTarget","localMarker","nativeVisibility"})do
    local service=s[key];s[key]=nil
    local closeService=member(service,"close")
    if type(closeService)=="function"then pcall(closeService)end
  end
  if s.probe then
    local closeProbe=member(s.probe,"close")
    if type(closeProbe)~="function"then s.closing=false;return false end
    local ok,value=pcall(closeProbe)
    if not ok or value~=true then s.closing=false;return false end
    s.probe=nil
  end
  if s.raidTracker then
    local ok,value=pcall(s.raidTracker.close)
    if not ok or value~=true then
      if s.panel then pcall(s.panel.close)end
      s.closing=false;return false
    end
    s.raidTracker=nil
  end
  if s.raidAuraCheck then
    local ok,value=pcall(s.raidAuraCheck.close)
    if not ok or value~=true then
      if s.panel then pcall(s.panel.close)end
      s.closing=false;return false
    end
    s.raidAuraCheck=nil
  end
  if s.panel then
    local ok,value=pcall(s.panel.close)
    if not ok or value~=true then s.closing=false;return false end
    s.panel=nil
  end
  s.closing=false
  local ok,value=pcall(s.owner.release,true)
  if not ok or value~=true then return false end
  if current==s then current=nil end
  return true
end
local function close()
  generation=generation+1
  return closeState(current)
end
local function open()
  if opening then return false end
  opening=true
  local function run()
    local s=current
    if s and s.live then
      if not s.owner.current()then closeState(s);return false end
      s.starting=true
      local ok,value=pcall(s.panel.open)
      s.starting=false
      if ok and value==true and s.live and current==s then return true end
      closeState(s);return false
    end
    if s and not closeState(s)then return false end
    local loaded,api=pcall(require,"api");if not loaded or not api then return false end
    local ownOK,Ownership=pcall(require,"Mazrim_Raid_Frames/shared/ownership")
    local dataOK,Native=pcall(require,"Mazrim_Raid_Frames/data/raid_composition_native")
    local consumerOK,Raid=pcall(require,"Mazrim_Raid_Frames/shared/raid_live")
    local viewOK,View=pcall(require,"Mazrim_Raid_Frames/standalone/view")
    local targetOK,Target=pcall(require,"Mazrim_Raid_Frames/standalone/target")
    local probeOK,Probe=pcall(require,"Mazrim_Raid_Frames/standalone/resource_probe")
    local selectionOK,Selection=pcall(require,"Mazrim_Raid_Frames/standalone/selection")
    local auraOK,AuraSource=pcall(require,"Mazrim_Raid_Frames/standalone/aura_source")
    local traceOK,Trace=pcall(require,"Mazrim_Raid_Frames/shared/target_trace")
    if viewOK and type(View)=="table"and View.targetBuffPolicyContract~=1 then restartMessage(api);return false end
    if not ownOK or type(Ownership)~="table"or Ownership.contract~=1 or type(Ownership.new)~="function"
      or not dataOK or type(Native)~="table"or Native.memberClassContract~=1 or Native.memberContract~=1 or Native.memberManaContract~=1 or Native.slotMetadataContract~=1 or Native.targetValidationContract~=1 or Native.distanceContract~=1 or Native.memberDisplayContract~=1 or Native.memberRoleContract~=1 or Native.memberAuraContract~=1 or Native.resourceEventDiagnosticContract~=1 or Native.resourceEventComparisonContract~=1 or type(Native.newResourceEventComparison)~="function"or type(Native.newResourceEventDiagnostic)~="function"or type(Native.new)~="function"
      or not consumerOK or type(Raid)~="table"or Raid.memberClassContract~=1 or Raid.slotMetadataContract~=1 or Raid.memberManaContract~=1 or Raid.hoverTokenContract~=1 or Raid.nativeDisplayContract~=1 or Raid.roleStyleExperimental~=1 or type(Raid.new)~="function"
      or not viewOK or type(View)~="table"or View.version~=addon.version or View.raidAdapterContract~=1 or View.slotMetadataContract~=1 or View.memberManaContract~=1 or View.wideNamesContract~=1 or View.hoverTargetContract~=1 or View.layoutToolsContract~=1 or View.healthEmphasisContract~=1 or View.placementContract~=1 or View.instantHoverContract~=1 or View.shiftDragContract~=1 or View.nativeRaidContract~=1 or View.dragRecoveryContract~=1 or View.nativeNameFeedbackContract~=1 or View.healingStudioContract~=1 or View.studioControlsContract~=2 or View.raidManagementContract~=1 or View.hudManagementContract~=2 or type(View.new)~="function"
      or not targetOK or type(Target)~="table"or Target.contract~=6 or Target.nameRefreshModeContract~=1 or Target.traceContract~=1 or Target.instantHoverContract~=1 or Target.nativeNameFeedbackContract~=1 or type(Target.new)~="function"
      or not probeOK or type(Probe)~="table"or Probe.contract~=1 or Probe.reasonContract~=4 or Probe.comparisonContract~=1 or type(Probe.new)~="function"
      or not selectionOK or type(Selection)~="table"or Selection.contract~=1 or type(Selection.new)~="function"
      or not viewOK or View.effectRulesContract~=1 or View.effectPriorityContract~=1 or View.selectedOnlyContract~=1 or View.targetTraceContract~=1 or View.nameRefreshModeContract~=1 or View.adaptiveEffectsContract~=1 or View.expandedStylesContract~=1 or View.colourPickerContract~=1 or View.alwaysShiftDragContract~=1 or View.tooltipLayerContract~=1 or View.roleIconToggleContract~=1 or View.inputRecoveryContract~=1 or View.overhaulContract~=1 or Native.targetAuraDepthContract~=1
      or not traceOK or type(Trace)~="table"or Trace.contract~=1 or Trace.saveFormatContract~=1 or type(Trace.new)~="function"
      or not auraOK or type(AuraSource)~="table"or AuraSource.contract~=1 or AuraSource.memberAuraContract~=1 or AuraSource.targetObservationContract~=1 or AuraSource.targetAuraDepthContract~=1 or type(AuraSource.new)~="function"then restartMessage(api);return false end
    generation=generation+1;local stamp=generation
    s={live=true,starting=true}
    s.owner=Ownership.new(api,"standalone")
    if type(s.owner)~="table"or s.owner.contract~=1 or type(s.owner.current)~="function"then return false end
    current=s
    local claimed,yes=pcall(s.owner.claim)
    if not claimed or yes~=true then s.starting=false;closeState(s);return false end
    local function alive()return current==s and s.live and generation==stamp and s.owner.current()end
    local made,reader=pcall(Native.new,api)
    if not made or type(reader)~="table"or reader.memberClassContract~=1 or reader.memberContract~=1 or reader.memberManaContract~=1 or reader.slotMetadataContract~=1 or reader.targetValidationContract~=1 or reader.distanceContract~=1 or reader.memberDisplayContract~=1 or reader.memberRoleContract~=1 or reader.memberAuraContract~=1 or reader.targetAuraDepthContract~=1
      or type(reader.observeMember)~="function"or type(reader.observeSlotMetadata)~="function"or type(reader.validateTarget)~="function"or type(reader.observeAuras)~="function"or not alive()then
      s.starting=false;closeState(s);restartMessage(api);return false
    end
    local joined,adapter=pcall(Raid.new,reader,alive)
    if not joined or type(adapter)~="table"or type(adapter.read)~="function"or not alive()then s.starting=false;closeState(s);return false end
    local traceMade,trace=pcall(Trace.new,addon.version)
    if type(trace)=="table"then s.trace=trace end
    local traceValid=traceMade and type(trace)=="table"and trace.contract==1 and trace.saveFormatContract==1
    if traceValid then for _,key in ipairs({"record","start","clock","stop","isActive","needsSave","captureId","export","acknowledge","summary","close"})do
      if type(trace[key])~="function"then traceValid=false end
    end end
    if not traceValid or not alive()then
      s.starting=false;closeState(s);restartMessage(api);return false
    end
    local targetMade,target=pcall(Target.new,api,reader,alive,trace)
    if not targetMade or type(target)~="table"or target.contract~=6 or target.nameRefreshModeContract~=1 or target.traceContract~=1 or target.nativeNameFeedbackContract~=1
      or type(target.setNameRefresh)~="function"or type(target.nameRefreshEnabled)~="function"
      or type(target.available)~="function"or type(target.attempt)~="function"or type(target.tick)~="function"or type(target.cancel)~="function"or not alive()then
      s.starting=false;closeState(s);restartMessage(api);return false
    end
    s.target=target
    local function selfReference()
      if not alive()then return nil end
      local reference=member(s.panel,"resource_reference")
      if type(reference)~="function"then return nil end
      local ok,value=pcall(reference)
      if not ok or not alive()then return nil end
      return value
    end
    local probeMade,probe=pcall(Probe.new,api,Native,alive,reader,selfReference)
    if type(probe)=="table"then s.probe=probe end
    if not probeMade or type(probe)~="table"or probe.contract~=1 or probe.reasonContract~=4 or probe.comparisonContract~=1
      or type(probe.available)~="function"or type(probe.start)~="function"or type(probe.stop)~="function"
      or type(probe.toggle)~="function"or type(probe.status)~="function"or type(probe.tick)~="function"
      or type(probe.report)~="function"or type(probe.close)~="function"or not alive()then
      s.starting=false;closeState(s);restartMessage(api);return false
    end
    local selectionMade,selection=pcall(Selection.new,api,alive)
    if type(selection)=="table"then s.selection=selection end
    if not selectionMade or type(selection)~="table"or selection.contract~=1 or type(selection.identity)~="function"or not alive()then
      s.starting=false;closeState(s);restartMessage(api);return false
    end
    local auraMade,auraSource=pcall(AuraSource.new,api,alive,reader)
    if type(auraSource)=="table"then s.auraSource=auraSource end
    if not auraMade or type(auraSource)~="table"or auraSource.contract~=1 or auraSource.memberAuraContract~=1 or auraSource.targetObservationContract~=1 or auraSource.targetAuraDepthContract~=1 or type(auraSource.target)~="function"or type(auraSource.sample)~="function"or not alive()then
      s.starting=false;closeState(s);restartMessage(api);return false
    end
    local capability,available=pcall(target.available)
    if not alive()then s.starting=false;closeState(s);return false end
    local targetAttempt
    if capability and available==true then targetAttempt=target.attempt end
    local nativeControls={selection=selection,auraSource=auraSource,trace=trace,rememberControls=true,firstUseTour=true}
    local visibilityOK,Visibility=pcall(require,"Mazrim_Raid_Frames/standalone/native_visibility")
    if visibilityOK and type(Visibility)=="table"and Visibility.contract==1 then
      local function visibilityAlive()
        return alive()and(not s.panel or(s.panel.active==true and not s.panel.failed))
      end
      local made,service=pcall(Visibility.new,ADDON,member(UIC,"RAID_MANAGER"),visibilityAlive)
      if made and type(service)=="table"and type(service.setVisible)=="function"then
        s.nativeVisibility=service
        nativeControls.setRaidVisible=function(visible)
          if not visibilityAlive()then return false end
          local cancelled,result=pcall(target.cancel)
          if not cancelled or result==false or not visibilityAlive()then return false end
          return service.setVisible(visible)
        end
      end
    end
    if reader.memberScreenPointContract==1 then
      local Marker=require("Mazrim_Raid_Frames/standalone/local_marker")
      s.localMarker=Marker.new(reader,alive);nativeControls.localMarker=s.localMarker
    end
    local returnOK,Return=pcall(require,"Mazrim_Raid_Frames/standalone/hover_return")
    if returnOK and type(Return)=="table"and Return.contract==1 then
      s.returnTarget=Return.new(api,reader,alive);nativeControls.returnTarget=s.returnTarget
    end
    local checkOK,Check=pcall(require,"Mazrim_Raid_Frames/standalone/raid_aura_check")
    local factoryOK,factory=pcall(function()return W_UNIT and W_UNIT.CreateBuffWindow end)
    if checkOK and type(Check)=="table"and Check.contract==1 and reader.raidAuraDiagnosticContract==1 then
      local Provider=require("Mazrim_Raid_Frames/standalone/raid_aura_provider")
      local pool=Provider.new(api,factoryOK and factory or nil,alive)
      local made,service=pcall(Check.new,api,reader,alive,factoryOK and factory or nil,pool)
      if made and type(service)=="table"and service.contract==1 then
        s.raidAuraCheck=service;nativeControls.raidAuraCheck=service
        if reader.raidAuraObserverContract==1 and auraSource.sharedBudgetContract==1 then
          local Tracker=require("Mazrim_Raid_Frames/standalone/raid_aura_tracker")
          s.raidTracker=Tracker.new(reader,pool,alive,service.setBlocked)
          nativeControls.raidTracker=s.raidTracker
        end
      end
    end
    local hotkeyOK,hotkey=pcall(function()return X2Hotkey end)
    local toggle=hotkeyOK and member(hotkey,"ExcuteActionHandler")or nil
    if type(toggle)=="function"then
      nativeControls.toggleRaid=function()
        if not alive()then return false end
        local cancel=member(target,"cancel")
        if type(cancel)~="function"then return false end
        local cancelled,value=pcall(cancel)
        if not cancelled or value==false or not alive()then return false end
        -- Explicit request only. A nil native return does not establish visibility.
        local ok,result=pcall(toggle,hotkey,"toggle_raid_frame")
        return ok and result~=false and alive()
      end
      local getContent=member(ADDON,"GetContent");local managerId=member(UIC,"RAID_MANAGER")
      if type(getContent)=="function"and managerId~=nil then
        nativeControls.openRaidManager=function(requestAlive)
          local function current()
            if not alive()or type(requestAlive)~="function"then return false end
            local ok,value=pcall(requestAlive);return ok and value==true and alive()
          end
          local function visibility()
            if not current()then return nil end
            local ok,frame=pcall(getContent,ADDON,managerId)
            if not current()or not ok or not frame then return nil end
            local visible=member(frame,"IsVisible");if type(visible)~="function"then return nil end
            local read,value=pcall(visible,frame)
            if not current()or not read or type(value)~="boolean"then return nil end
            return frame,value
          end
          local frame,shown=visibility()
          if not frame then return "UNAVAILABLE"end
          if shown then return "OPEN"end
          local cancel=member(target,"cancel")
          if type(cancel)~="function"or not current()then return "CANCELLED"end
          local cancelled,value=pcall(cancel)
          if not cancelled or value==false or not current()then return "CANCELLED"end
          local same,visible=visibility()
          if same~=frame then return "UNAVAILABLE"end
          if visible then return "OPEN"end
          if not current()then return "CANCELLED"end
          -- The management trigger has a different internal ID from its
          -- exposed widget. Use the allowlisted action only when observed hidden.
          local ok,result=pcall(toggle,hotkey,"toggle_raid_team_manager")
          if not current()then return "CANCELLED"end
          if not ok or result==false then return "FAILED"end
          local latest,isVisible=visibility()
          if not current()then return "CANCELLED"end
          return latest==frame and isVisible==true and "OPEN"or"REQUESTED"
        end
      end
    end
    local built,panel=pcall(View.new,api,adapter,targetAttempt,target,probe,alive,nativeControls)
    if built and type(panel)=="table"then s.panel=panel end
    if not built or not s.panel then s.starting=false;closeState(s);return false end
    if not alive()or type(panel.open)~="function"or type(panel.resource_reference)~="function"or type(panel.controller)~="table"or type(panel.controller.action)~="function"then
      s.starting=false;closeState(s);return false
    end
    if panel.controller.mode~="live"then
      local ok,value=pcall(panel.controller.action,"mode")
      if not ok or value~=true or not alive()then s.starting=false;closeState(s);return false end
    end
    if type(panel.sample_live)~="function"then s.starting=false;closeState(s);return false end
    local sampled=pcall(panel.sample_live,true)
    if not sampled or not alive()then s.starting=false;closeState(s);return false end
    local opened,value=pcall(panel.open)
    s.starting=false
    if not opened or value~=true or not alive()then closeState(s);return false end
    return true
  end
  local ok,value=pcall(run);opening=false
  if not ok then if current then current.starting=false end;closeState(current);return false end
  return value==true
end
function addon.OnLoad()return open()end
function addon.OnSettingToggle()return open()end
function addon.OnUnload()return close()end
return addon
