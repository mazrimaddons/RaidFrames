-- Frontend consumer of lane02 memberContract1. No native API access or retained
-- member samples. Host owns one reader, cadence, lifetime and packaging.
local F=require("Mazrim_Raid_Frames/shared/foundation")
local I=require("Mazrim_Raid_Frames/shared/identity")
local P=require("Mazrim_Raid_Frames/shared/presentation")
local M={slotMetadataContract=1,memberManaContract=1,hoverTokenContract=1,nativeDisplayContract=1,roleStyleExperimental=1,memberClassContract=1}
function M.new(reader,alive)
  local s={memberClassContract=M.memberClassContract}
  local function displayFields(row,r,identified)
    if identified and reader.memberClassContract==1 and r.classKnown==true
      and type(r.className)=="string"and #r.className>0 and #r.className<=128
      and not r.className:find("[%c|]")and not r.className:match("^%s*$")then
      row.classKnown=true;row.className=r.className
    end
    -- Native baselib UNIT_VISIBLE_MAX_DISTANCE=130; this is NOT healing range.
    if reader.distanceContract==1 and r.distanceKnown==true and type(r.distanceM)=="number"
      and r.distanceM==r.distanceM and r.distanceM>=0 and r.distanceM<1/0 then
      row.distanceM=r.distanceM;row.rangeKnown=true;row.outOfRange=r.distanceM>=130
    end
    if identified and reader.memberDisplayContract==1 then
      if r.authorityKnown==true and (r.authority=="leader" or r.authority=="subleader") then
        row.authorityKnown=true;row.authority=r.authority
      end
      if r.selfKnown==true and type(r.isSelf)=="boolean" then row.selfKnown=true;row.isSelf=r.isSelf end
    end
    if identified and reader.memberRoleContract==1 and r.declaredRoleKnown==true
      and type(r.declaredRoleID)=="number" and r.declaredRoleID%1==0
      and r.declaredRoleID>=0 and r.declaredRoleID<=3 then
      -- AAEmu's protocol enum supports this compatibility interpretation.
      -- AAC TMROLE_* globals are not exported; native parity is still unverified.
      row.declaredRoleID=r.declaredRoleID;row.roleStyleEstimated=true
      row.roleStyle=({"HP_RAID","HP_RAID_TANKER","HP_RAID_HEALER","HP_RAID_DEALER"})[r.declaredRoleID+1]
    end
  end
  local function unknown(i)
    return {name="Slot "..i.." unresolved",kind="raid",slot=i,state="UNRESOLVED",
      health=F.resource(nil,nil),mana=F.resource(nil,nil),selected=false}
  end
  function s.unavailable()
    return {source="raid",rows={},coverage="ROSTER_UNAVAILABLE",identified=0,unresolved=0,healthKnown=0}
  end
  local function current()
    if type(alive)~="function" then return false end
    local ok,v=pcall(alive);return ok and v==true
  end
  local function unresolvedRow(i,token)
    local row=unknown(i)
    if reader.slotMetadataContract~=1 or type(reader.observeSlotMetadata)~="function" then return row end
    if not current() then return row end
    local ok,r=pcall(reader.observeSlotMetadata,token,current)
    if not current() or not ok or type(r)~="table" or r.contract~=1 or r.token~=token then return row end
    if r.state=="unresolved" and r.clear==true and r.reason=="not_member" then return nil end
    if r.state=="slot_metadata" and r.clear==false and r.attributed==false then
      if r.nameKnown==true and type(r.name)=="string" and #r.name>0 and #r.name<=128
        and not r.name:find("[%c|]") and not r.name:match("^%s*$") then
        row.name=P.text(r.name,128);row.nameKnown=true;row.state="SLOT_METADATA"
      end
      if r.offlineKnown==true and type(r.offline)=="boolean" then
        if not row.nameKnown then row.name="Slot "..i end
        row.state="SLOT_METADATA";row.offlineKnown=true;row.offline=r.offline
      end
      if row.nameKnown then displayFields(row,r,false) end
    end
    return row
  end
  local readGeneration=0
  function s.read()
    readGeneration=readGeneration+1;local generation=readGeneration
    if not current() or type(reader)~="table" or reader.memberContract~=1
      or type(reader.observeMember)~="function" then return s.unavailable() end
    local rows,seen,duplicates={},{},{};local nonmembers=0
    for i=1,50 do
      if not current()or readGeneration~=generation then return s.unavailable() end
      local token="team"..i
      local ok,r=pcall(reader.observeMember,token,current)
      if not current()or readGeneration~=generation then return s.unavailable() end
      if ok and type(r)=="table"and r.contract==1 and r.token==token and r.state=="unresolved"and r.clear==true and r.reason=="not_member"and r.calls==1 then nonmembers=nonmembers+1 end
      if not (ok and type(r)=="table" and r.contract==1 and r.token==token) then
        local row=unresolvedRow(i,token);if row then rows[#rows+1]=row end
      elseif r.state=="partial" and r.clear==false and I.accepts(r.identity) then
        local row=unknown(i)
        row.identity=r.identity;row.token=r.token;row.name="Member slot "..i;row.state="HEALTH_UNAVAILABLE"
        if r.nameKnown==true and type(r.name)=="string" then row.name=P.text(r.name,128);row.nameKnown=true end
        if r.hpKnown==true then row.health=F.resource(r.hp,r.maxHp) end
        if reader.memberManaContract==1 and r.manaKnown==true then row.mana=F.resource(r.mana,r.maxMana) end
        if r.offlineKnown==true and type(r.offline)=="boolean" then
          row.offlineKnown=true;row.offline=r.offline
          if r.offline then row.health=F.resource(nil,nil);row.mana=F.resource(nil,nil) end
        end
        if row.health.known then row.state="OBSERVED" end
        displayFields(row,r,true)
        if seen[r.identity] then duplicates[r.identity]=true end
        seen[r.identity]=true;rows[#rows+1]=row
      elseif not (r.state=="unresolved" and r.clear==true and r.reason=="not_member") then
        local row=unresolvedRow(i,token);if row then rows[#rows+1]=row end
      end
    end
    if not current() then return s.unavailable() end
    local identified,unresolved,hp,statusKnown,offline,named,mana=0,0,0,0,0,0,0
    for i=1,#rows do
      local row=rows[i]
      if row.identity and duplicates[row.identity] then row=unknown(row.slot);rows[i]=row end
      if row.identity then identified=identified+1 else unresolved=unresolved+1 end
      if row.health.known then hp=hp+1 end
      if row.mana.known then mana=mana+1 end
      if row.nameKnown then named=named+1 end
      if row.offlineKnown then statusKnown=statusKnown+1;if row.offline then offline=offline+1 end end
    end
    if not current()or readGeneration~=generation then return s.unavailable()end
    return {source="raid",rows=rows,membershipEmptyConfirmed=nonmembers==50,coverage="PARTIAL_OBSERVATIONS",identified=identified,
      unresolved=unresolved,healthKnown=hp,manaKnown=mana,statusKnown=statusKnown,offlineCount=offline,named=named,
      complete=false,coherent=false,cacheAgeKnown=false}
  end
  return s
end
return M
