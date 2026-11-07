-- Pure display decisions. No API reads, target effects or retained observations.
local I=require("Mazrim_Raid_Frames/shared/identity")
local M={contract=1}
local function finite(v)return type(v)=="number"and v==v and v>-1/0 and v<1/0 end
function M.fraction(value)
  if type(value)~="table"or value.known~=true or not finite(value.current)or not finite(value.maximum)
    or value.maximum<=0 or value.current<0 or value.current>value.maximum then return nil end
  return value.current/value.maximum
end
local function threshold(v,fallback)
  if finite(v)and v>=1 and v<=100 then return v end
  return fallback
end
function M.state(row,options,state,hover,showMana)
  options=type(options)=="table"and options or {}
  state=type(state)=="table"and state or {}
  local prefs=type(options.indicators)=="table"and options.indicators or {}
  local offline=row.offlineKnown==true and row.offline==true
  local hp,mp=M.fraction(row.health),M.fraction(row.mana)
  -- Empty/name-only presentation requires an accepted, observed zero HP.
  -- Missing resources and explicit offline status never imply death.
  local dead=not offline and hp==0
  local selected=state.selected==true and(I.accepts(row.identity)or state.preview==true)
  local alpha=offline and 0.5 or(row.rangeKnown==true and row.outOfRange==true and 0.5 or 1)
  local range=type(options.range)=="table"and options.range or {}
  if not offline and range.enabled==true then
    alpha=1
    local distance=range.distance
    if not finite(distance)or distance<1 or distance>500 then distance=30 end
    local dim=range.alpha
    if not finite(dim)or dim<0.1 or dim>1 then dim=0.5 end
    if row.rangeKnown==true and finite(row.distanceM)and row.distanceM>=0 and row.distanceM>distance then alpha=dim end
  end
  if offline then hp=nil;mp=nil end
  return {dead=dead,target=not dead and prefs.target==true and selected,
    hover=not dead and prefs.hover==true and hover==true,
    lowHealth=not dead and prefs.low_health==true and not offline and hp~=nil and hp*100<=threshold(prefs.health_threshold,25),
    lowMana=not dead and prefs.low_mana==true and showMana==true and not offline and mp~=nil and mp*100<=threshold(prefs.mana_threshold,20),
    alpha=alpha,hp=hp,mana=mp}
end
return M
