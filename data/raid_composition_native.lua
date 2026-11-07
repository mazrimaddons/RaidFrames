-- Declaration-backed, explicitly invoked diagnostics. No subscriptions or files.
-- A matching pair of scans is NOT a native atomic/revision guarantee.
local M={version="RC-20261028-06",memberContract=1,memberManaContract=1,slotMetadataContract=1,targetValidationContract=1,distanceContract=1,memberDisplayContract=1,memberRoleContract=1,resourceEventDiagnosticContract=1,resourceEventComparisonContract=1,memberAuraContract=1,targetAuraDepthContract=1,memberClassContract=1,raidAuraDiagnosticContract=1,raidAuraObserverContract=1,memberScreenPointContract=1,memberMovementPointContract=1,raidAuraCoverageContract=1}
local function integer(v)
    return type(v)=="number" and v==v and v>=0 and v<=9007199254740991 and v==math.floor(v)
end
local function identity(v)
    -- D91 owner evidence establishes string returns. Keep the exact opaque value:
    -- no tonumber/tostring, trimming, slot/name fallback or persisted identity.
    if type(v)=="string" then
        return #v>0 and #v<=128 and not v:find("%c") and not v:match("^%s*$")
    end
    return integer(v) and v>0
end
local function decimalText(v)
    -- Classification only; do not return the parsed score or infer freshness.
    -- Matches the bounded Public target reader, with controls excluded.
    if #v>32 or v:find("%c") or not v:match("^ *%d+%.?%d* *$")
        or type(tonumber)~="function" then return false end
    local n=tonumber(v)
    return type(n)=="number" and n==n and n>=0 and n<10000000
end
function M.new(api)
    local busy=false
    local function probe(alive)
        if busy then return {state="unavailable",reason="busy",calls=0} end
        busy=true
        local calls=0
        local function current()
            if alive==nil then return true end
            if type(alive)~="function" then return false end
            local ok,value=pcall(alive);return ok and value==true
        end
        local function read(section,method,arg)
            if not current() then return false,nil,"cancelled" end
            local ok,service,fn=pcall(function()
                local s=api and api[section];return s,s and s[method]
            end)
            if not ok or type(fn)~="function" then return false,nil,"missing" end
            calls=calls+1
            local safe,value=pcall(fn,service,arg)
            if not current() then return false,nil,"cancelled" end
            if not safe then return false,nil,"failed" end
            return true,value
        end
        local function run()
            local baseline,seen={},{}
            local report={state="diagnostic",complete=false,coherent=false,tokens=50,
                memberTrue=0,memberFalse=0,idUnavailable=0,
                idMissing=0,idFailed=0,idNil=0,idText=0,idNumberRejected=0,idOther=0,
                scoreNumeric=0,scoreZero=0,
                scoreText=0,scoreTextDecimal=0,scoreTextUnsupported=0,scoreUnavailable=0,scoreMissing=0,scoreFailed=0,scoreNil=0,scoreInvalid=0,offline=0,offlineUnknown=0,
                roleNumeric=0,roleUnavailable=0,
                nilIdSampled=0,nilIdScoreNumeric=0,nilIdScoreDecimal=0,
                nilIdScoreTextUnsupported=0,nilIdScoreUnavailable=0,
                nilIdOfflineTrue=0,nilIdOfflineUnknown=0,
                nilIdInfoAvailable=0,nilIdInfoUnavailable=0,
                nilIdDistanceAvailable=0,nilIdDistanceUnavailable=0}
            local function reject(reason) return {state="unavailable",reason=reason} end
            for i=1,50 do
                local token="team"..i
                local ok,member,why=read("Unit","UnitIsTeamMember",token)
                if not ok then return reject(why) end
                if type(member)~="boolean" then return reject("membership_format") end
                local idOK,id,idWhy=read("Unit","GetUnitId",token)
                if idWhy=="cancelled" then return reject(idWhy) end
                baseline[i]={member=member,id=idOK and identity(id) and id or false,nilIdentity=idOK and id==nil}
                if member then
                    report.memberTrue=report.memberTrue+1
                    if not baseline[i].id then
                        report.idUnavailable=report.idUnavailable+1
                        -- Count the failure kind only; never expose, parse or stringify the ID.
                        if idWhy=="missing" then report.idMissing=report.idMissing+1
                        elseif idWhy=="failed" then report.idFailed=report.idFailed+1
                        elseif id==nil then report.idNil=report.idNil+1
                        elseif type(id)=="string" then report.idText=report.idText+1
                        elseif type(id)=="number" then report.idNumberRejected=report.idNumberRejected+1
                        else report.idOther=report.idOther+1 end
                    elseif seen[id] then return reject("duplicate_identity")
                    else seen[id]=true end
                else report.memberFalse=report.memberFalse+1 end
            end
            for i=1,50 do
                local b=baseline[i];local token="team"..i
                if b.member and b.id then
                    local ok,id=read("Unit","GetUnitId",token)
                    if not ok or id~=b.id then return reject("membership_changed") end
                    local offOK,offline,offWhy=read("Unit","UnitIsOffline",token)
                    if offWhy=="cancelled" then return reject(offWhy) end
                    if offOK and offline==true then report.offline=report.offline+1
                    elseif not offOK or offline~=false then report.offlineUnknown=report.offlineUnknown+1 end
                    -- Read returned format only. Never classify offline/cached zero as a known statistic.
                    local scoreOK,score,scoreWhy=read("Unit","UnitGearScore",token)
                    if scoreWhy=="cancelled" then return reject(scoreWhy) end
                    if scoreOK and type(score)=="number" and score==score and score>=0 and score<math.huge then
                        report.scoreNumeric=report.scoreNumeric+1
                        if score==0 then report.scoreZero=report.scoreZero+1 end
                    elseif scoreOK and type(score)=="string" then
                        report.scoreText=report.scoreText+1
                        if decimalText(score) then report.scoreTextDecimal=report.scoreTextDecimal+1
                        else report.scoreTextUnsupported=report.scoreTextUnsupported+1 end
                    else
                        report.scoreUnavailable=report.scoreUnavailable+1
                        if scoreWhy=="missing" then report.scoreMissing=report.scoreMissing+1
                        elseif scoreWhy=="failed" then report.scoreFailed=report.scoreFailed+1
                        elseif score==nil then report.scoreNil=report.scoreNil+1
                        else report.scoreInvalid=report.scoreInvalid+1 end
                    end
                    local nameOK,name,nameWhy=read("Unit","GetUnitNameById",b.id)
                    if nameWhy=="cancelled" then return reject(nameWhy) end
                    local roleKnown=false
                    if nameOK and type(name)=="string" and #name>0 and #name<=128 then
                        local indexOK,index,indexWhy=read("Team","GetMemberIndexByName",name)
                        if indexWhy=="cancelled" then return reject(indexWhy) end
                        if indexOK and integer(index) then
                            local roleOK,role,roleWhy=read("Team","GetRole",index)
                            if roleWhy=="cancelled" then return reject(roleWhy) end
                            roleKnown=roleOK and integer(role)
                        end
                    end
                    if roleKnown then report.roleNumeric=report.roleNumeric+1 else report.roleUnavailable=report.roleUnavailable+1 end
                    local same,after=read("Unit","GetUnitId",token)
                    local memberOK,member=read("Unit","UnitIsTeamMember",token)
                    if not same or after~=b.id or not memberOK or member~=true then return reject("membership_changed") end
                elseif b.member and b.nilIdentity then
                    -- Token APIs do not require an ID. These counters are deliberately
                    -- UNATTRIBUTED; repeated nil is not a stable actor or atomic snapshot.
                    local idOK,id,idWhy=read("Unit","GetUnitId",token)
                    if idWhy=="cancelled" then return reject(idWhy) end
                    local memberOK,member,memberWhy=read("Unit","UnitIsTeamMember",token)
                    if memberWhy=="cancelled" then return reject(memberWhy) end
                    if not idOK or id~=nil or not memberOK or member~=true then return reject("membership_changed") end
                    local offOK,offline,offWhy=read("Unit","UnitIsOffline",token)
                    if offWhy=="cancelled" then return reject(offWhy) end
                    if offOK and offline==true then report.nilIdOfflineTrue=report.nilIdOfflineTrue+1
                    elseif not offOK or offline~=false then report.nilIdOfflineUnknown=report.nilIdOfflineUnknown+1 end
                    local scoreOK,score,scoreWhy=read("Unit","UnitGearScore",token)
                    if scoreWhy=="cancelled" then return reject(scoreWhy) end
                    if scoreOK and type(score)=="number" and score==score and score>=0 and score<math.huge then
                        report.nilIdScoreNumeric=report.nilIdScoreNumeric+1
                    elseif scoreOK and type(score)=="string" then
                        if decimalText(score) then report.nilIdScoreDecimal=report.nilIdScoreDecimal+1
                        else report.nilIdScoreTextUnsupported=report.nilIdScoreTextUnsupported+1 end
                    else report.nilIdScoreUnavailable=report.nilIdScoreUnavailable+1 end
                    local infoOK,info,infoWhy=read("Unit","UnitInfo",token)
                    if infoWhy=="cancelled" then return reject(infoWhy) end
                    if infoOK and type(info)=="table" then report.nilIdInfoAvailable=report.nilIdInfoAvailable+1
                    else report.nilIdInfoUnavailable=report.nilIdInfoUnavailable+1 end
                    -- Do not inspect any UnitInfo keys, names, IDs or nested content.
                    local distanceOK,distance,distanceWhy=read("Unit","UnitDistance",token)
                    if distanceWhy=="cancelled" then return reject(distanceWhy) end
                    if distanceOK and type(distance)=="number" and distance==distance and distance>=0 and distance<math.huge then
                        report.nilIdDistanceAvailable=report.nilIdDistanceAvailable+1
                    else report.nilIdDistanceUnavailable=report.nilIdDistanceUnavailable+1 end
                    local afterOK,after,afterWhy=read("Unit","GetUnitId",token)
                    if afterWhy=="cancelled" then return reject(afterWhy) end
                    local stillOK,stillMember,stillWhy=read("Unit","UnitIsTeamMember",token)
                    if stillWhy=="cancelled" then return reject(stillWhy) end
                    if not afterOK or after~=nil or not stillOK or stillMember~=true then return reject("membership_changed") end
                    report.nilIdSampled=report.nilIdSampled+1
                end
            end
            for i=1,50 do
                local token="team"..i;local b=baseline[i]
                local ok,member,why=read("Unit","UnitIsTeamMember",token)
                if why=="cancelled" then return reject(why) end
                local idOK,id,idWhy=read("Unit","GetUnitId",token)
                if idWhy=="cancelled" then return reject(idWhy) end
                local normalized=idOK and identity(id) and id or false
                if not ok or member~=b.member or normalized~=b.id or (b.nilIdentity and (not idOK or id~=nil)) then return reject("membership_changed") end
            end
            return report
        end
        local ok,result=pcall(run)
        busy=false
        if not ok then result={state="unavailable",reason="probe_failed"} end
        result.calls=calls
        return result
    end
    local function observeMember(token,alive)
        local calls=0
        local function unresolved(reason)
            return {contract=1,state="unresolved",reason=reason,token=token,clear=true,
                nameKnown=false,hpKnown=false,manaKnown=false,distanceKnown=false,
                authorityKnown=false,selfKnown=false,declaredRoleKnown=false,classKnown=false,
                cacheAgeKnown=false,complete=false,coherent=false,calls=calls}
        end
        -- Native member.lua binds teamN and GetRole(N) to the same memberIndex.
        -- Canonical documented domain only; no name or self-position inference.
        local valid,memberIndex=false,nil
        if type(token)=="string" then
            for i=1,50 do if token=="team"..i then valid=true;memberIndex=i;break end end
        end
        if not valid then token=nil;return unresolved("invalid_token") end
        if busy then return unresolved("busy") end
        if type(alive)~="function" then return unresolved("lifetime_unverified") end
        busy=true
        local function current()
            local ok,v=pcall(alive);return ok and v==true
        end
        local function read(method,arg,section)
            if not current() then return false,nil,"cancelled" end
            local ok,unit,fn=pcall(function()
                local u=api and api[section or "Unit"];return u,u and u[method]
            end)
            if not ok or type(fn)~="function" then return false,nil,"read_unavailable" end
            calls=calls+1
            local safe,v=pcall(fn,unit,arg)
            if not current() then return false,nil,"cancelled" end
            if not safe then return false,nil,"read_failed" end
            return true,v
        end
        local function run()
            local memberOK,member,why=read("UnitIsTeamMember",token)
            if not memberOK then return unresolved(why) end
            if member==false then return unresolved("not_member") end
            if member~=true then return unresolved("membership_unknown") end
            local idOK,id,idWhy=read("GetUnitId",token)
            if not idOK then return unresolved(idWhy) end
            if not identity(id) then return unresolved("identity_unknown") end
            local playerOK,playerID,playerWhy=read("GetUnitId","player")
            if playerWhy=="cancelled" then return unresolved(playerWhy) end
            local playerKnown=playerOK and identity(playerID)
            local nameOK,name,nameWhy=read("GetUnitNameById",id)
            if nameWhy=="cancelled" then return unresolved(nameWhy) end
            local nameKnown=nameOK and type(name)=="string" and #name>0 and #name<=128
                and not name:find("%c") and not name:find("|",1,true) and not name:match("^%s*$")
            if not nameKnown then name=nil end
            local healthOK,hp,healthWhy=read("UnitHealth",token)
            if healthWhy=="cancelled" then return unresolved(healthWhy) end
            local maxHP,hpKnown=nil,false
            if healthOK and type(hp)=="number" and hp==hp and hp>=0 and hp<=1000000000 then
                local maxOK,value,maxWhy=read("UnitMaxHealth",token)
                if maxWhy=="cancelled" then return unresolved(maxWhy) end
                if maxOK and type(value)=="number" and value==value and value>0
                    and value<=1000000000 and hp<=value then maxHP=value;hpKnown=true end
            end
            if not hpKnown then hp=nil;maxHP=nil end
            -- Optional mana pair stays within the same actor/membership bracket.
            local manaOK,mana,manaWhy=read("UnitMana",token)
            if manaWhy=="cancelled" then return unresolved(manaWhy) end
            local maxMana,manaKnown=nil,false
            if manaOK and type(mana)=="number" and mana==mana and mana>=0 and mana<=1000000000 then
                local maxOK,value,maxWhy=read("UnitMaxMana",token)
                if maxWhy=="cancelled" then return unresolved(maxWhy) end
                if maxOK and type(value)=="number" and value==value and value>0
                    and value<=1000000000 and mana<=value then maxMana=value;manaKnown=true end
            end
            if not manaKnown then mana=nil;maxMana=nil end
            local distanceOK,distance,distanceWhy=read("UnitDistance",token)
            if distanceWhy=="cancelled" then return unresolved(distanceWhy) end
            local distanceKnown=distanceOK and type(distance)=="number" and distance==distance
                and distance>=0 and distance<math.huge
            if not distanceKnown then distance=nil end
            local authorityOK,authority,authorityWhy=read("UnitTeamAuthority",token)
            if authorityWhy=="cancelled" then return unresolved(authorityWhy) end
            local authorityKnown=authorityOK and (authority=="leader" or authority=="subleader")
            if not authorityKnown then authority=nil end
            local roleOK,declaredRoleID,roleWhy=read("GetRole",memberIndex,"Team")
            if roleWhy=="cancelled" then return unresolved(roleWhy) end
            -- Raw bounded observation only; semantic role/colour mapping belongs
            -- to the reviewed consumer, not an inferred engine enum here.
            local declaredRoleKnown=roleOK and integer(declaredRoleID) and declaredRoleID<=3
            if not declaredRoleKnown then declaredRoleID=nil end
            -- Dedicated class descriptor; never derive class from the role ID.
            local classOK,className,classWhy=read("GetUnitClassName",token,"Ability")
            if classWhy=="cancelled" then return unresolved(classWhy) end
            local classKnown=classOK and type(className)=="string" and #className>0 and #className<=128
                and not className:find("%c") and not className:find("|",1,true) and not className:match("^%s*$")
            if not classKnown then className=nil end
            local selfKnown,isSelf=false,nil
            if playerKnown then
                local playerAfterOK,playerAfter,playerAfterWhy=read("GetUnitId","player")
                if playerAfterWhy=="cancelled" then return unresolved(playerAfterWhy) end
                if playerAfterOK and playerAfter==playerID then selfKnown=true;isSelf=id==playerID end
            end
            local afterOK,after,afterWhy=read("GetUnitId",token)
            if not afterOK then return unresolved(afterWhy) end
            local stillOK,stillMember,stillWhy=read("UnitIsTeamMember",token)
            if not stillOK then return unresolved(stillWhy) end
            if after~=id or stillMember~=true then return unresolved("member_changed") end
            return {contract=1,state="partial",token=token,identity=id,name=name,nameKnown=nameKnown,
                hp=hp,maxHp=maxHP,hpKnown=hpKnown,mana=mana,maxMana=maxMana,manaKnown=manaKnown,
                distanceM=distance,distanceKnown=distanceKnown,
                authority=authority,authorityKnown=authorityKnown,selfKnown=selfKnown,isSelf=isSelf,
                declaredRoleID=declaredRoleID,declaredRoleKnown=declaredRoleKnown,
                className=className,classKnown=classKnown,
                clear=false,cacheAgeKnown=false,
                complete=false,coherent=false,calls=calls}
        end
        local ok,result=pcall(run)
        -- Always release the shared synchronous guard, including throws/revocation.
        busy=false
        if not ok then return unresolved("read_failed") end
        return result
    end
    local function observeSlotMetadata(token,alive)
        local calls=0
        local function unresolved(reason)
            return {contract=1,state="unresolved",reason=reason,token=token,attributed=false,clear=true,
                nameKnown=false,offlineKnown=false,distanceKnown=false,
                cacheAgeKnown=false,complete=false,coherent=false,calls=calls}
        end
        local valid=false
        if type(token)=="string" then
            for i=1,50 do if token=="team"..i then valid=true;break end end
        end
        if not valid then token=nil;return unresolved("invalid_token") end
        if busy then return unresolved("busy") end
        if type(alive)~="function" then return unresolved("lifetime_unverified") end
        busy=true
        local function current()
            local ok,v=pcall(alive);return ok and v==true
        end
        local function read(method)
            if not current() then return false,nil,"cancelled" end
            local ok,unit,fn=pcall(function()
                local u=api and api.Unit;return u,u and u[method]
            end)
            if not ok or type(fn)~="function" then return false,nil,"read_unavailable" end
            calls=calls+1
            local safe,v=pcall(fn,unit,token)
            if not current() then return false,nil,"cancelled" end
            if not safe then return false,nil,"read_failed" end
            return true,v
        end
        local function run()
            local ok,member,why=read("UnitIsTeamMember")
            if not ok then return unresolved(why) end
            if member==false then return unresolved("not_member") end
            if member~=true then return unresolved("membership_unknown") end
            -- Verified generic AAC wrapper proto41 routes UnitName(token)
            -- directly to X2Unit, without a GetUnitId prerequisite.
            local nameOK,name,nameWhy=read("UnitName")
            if nameWhy=="cancelled" then return unresolved(nameWhy) end
            local nameKnown=nameOK and type(name)=="string" and #name>0 and #name<=128
                and not name:find("%c") and not name:find("|",1,true) and not name:match("^%s*$")
            if not nameKnown then name=nil end
            local statusOK,offline,statusWhy=read("UnitIsOffline")
            if statusWhy=="cancelled" then return unresolved(statusWhy) end
            local offlineKnown=statusOK and type(offline)=="boolean"
            if not offlineKnown then offline=nil end
            -- An unloaded slot may still provide distance. Require its known
            -- label to agree around that read, without treating the label as ID.
            local distance,distanceKnown=nil,false
            if nameKnown then
                local distanceOK,value,distanceWhy=read("UnitDistance")
                if distanceWhy=="cancelled" then return unresolved(distanceWhy) end
                if distanceOK and type(value)=="number" and value==value and value>=0 and value<math.huge then
                    local verifyOK,verifyName,verifyWhy=read("UnitName")
                    if verifyWhy=="cancelled" then return unresolved(verifyWhy) end
                    if not verifyOK then return unresolved("name_unverified") end
                    if verifyName~=name then return unresolved("name_changed") end
                    distance=value;distanceKnown=true
                end
            end
            local afterOK,after,afterWhy=read("UnitIsTeamMember")
            if not afterOK then return unresolved(afterWhy) end
            if after~=true then return unresolved("member_changed") end
            -- Slot metadata is not actor identity. Never guess an info field or
            -- turn token, member index, name or explicit offline into actor identity.
            return {contract=1,state="slot_metadata",token=token,attributed=false,clear=false,
                name=name,nameKnown=nameKnown,offline=offline,offlineKnown=offlineKnown,cacheAgeKnown=false,
                distanceM=distance,distanceKnown=distanceKnown,
                complete=false,coherent=false,calls=calls}
        end
        local ok,result=pcall(run)
        busy=false
        if not ok then return unresolved("read_failed") end
        return result
    end
    local function validateTarget(token,expectedID,alive)
        local calls=0
        local function unavailable(reason)
            return {contract=1,token=token,state="unavailable",reason=reason,calls=calls}
        end
        local valid=false
        if type(token)=="string" then
            for i=1,50 do if token=="team"..i then valid=true;break end end
        end
        if not valid then token=nil;return unavailable("invalid_token") end
        if not identity(expectedID) then return unavailable("invalid_identity") end
        if busy then return unavailable("busy") end
        if type(alive)~="function" then return unavailable("lifetime_unverified") end
        busy=true
        local function current()
            local ok,v=pcall(alive);return ok and v==true
        end
        local function read(method)
            if not current() then return false,nil,"cancelled" end
            local ok,unit,fn=pcall(function()
                local u=api and api.Unit;return u,u and u[method]
            end)
            if not ok or type(fn)~="function" then return false,nil,"read_unavailable" end
            calls=calls+1
            local safe,value=pcall(fn,unit,token)
            if not current() then return false,nil,"cancelled" end
            if not safe then return false,nil,"read_failed" end
            return true,value
        end
        local function run()
            local memberOK,member,why=read("UnitIsTeamMember")
            if not memberOK then return unavailable(why) end
            if member==false then return unavailable("not_member") end
            if member~=true then return unavailable("membership_unknown") end
            local idOK,id,idWhy=read("GetUnitId")
            if not idOK then return unavailable(idWhy) end
            if id~=expectedID then return unavailable("identity_changed") end
            local offlineOK,offline,offlineWhy=read("UnitIsOffline")
            if not offlineOK then return unavailable(offlineWhy) end
            if offline==true then return unavailable("offline") end
            if offline~=false then return unavailable("offline_unknown") end
            local afterOK,after,afterWhy=read("GetUnitId")
            if not afterOK then return unavailable(afterWhy) end
            if after~=expectedID then return unavailable("identity_changed") end
            local stillOK,stillMember,stillWhy=read("UnitIsTeamMember")
            if not stillOK then return unavailable(stillWhy) end
            if stillMember~=true then return unavailable("member_changed") end
            return {contract=1,token=token,state="valid",reason="validated",calls=calls}
        end
        local ok,result=pcall(run)
        busy=false
        if not ok then return unavailable("read_failed") end
        return result
    end
    local function observeScreenPoint(token,expectedID,alive)
        local calls=0
        local function unresolved(reason)
            return {contract=1,state="unresolved",reason=reason,token=token,calls=calls,clear=true,
                positionKnown=false,nameTagOffsetKnown=false,cacheAgeKnown=false,coherent=false,complete=false,
                coordinateScaleKnown=false,offsetUnitsKnown=false,renderedKnown=false,depthKnown=false}
        end
        local valid=false
        for i=1,50 do if token=="team"..i then valid=true;break end end
        if not valid then token=nil;return unresolved("invalid_token") end
        if not identity(expectedID) then return unresolved("invalid_identity") end
        if busy then return unresolved("busy") end
        if type(alive)~="function" then return unresolved("lifetime_unverified") end
        busy=true
        local function current()
            local ok,value=pcall(alive);return ok and value==true
        end
        local function read(section,method,arg)
            if not current() then return false,nil,nil,"cancelled" end
            local ok,object,fn=pcall(function()
                local object=api and api[section];return object,object and object[method]
            end)
            if not current() then return false,nil,nil,"cancelled" end
            if not ok or type(fn)~="function" then return false,nil,nil,"read_unavailable" end
            calls=calls+1
            local safe,a,b
            if arg==nil then safe,a,b=pcall(fn,object) else safe,a,b=pcall(fn,object,arg) end
            if not current() then return false,nil,nil,"cancelled" end
            if not safe then return false,nil,nil,"read_failed" end
            return true,a,b
        end
        local function finite(value)
            return type(value)=="number" and value==value and value>-math.huge and value<math.huge
        end
        local function run()
            local memberOK,member,_,memberWhy=read("Unit","UnitIsTeamMember",token)
            if not memberOK then return unresolved(memberWhy) end
            if member~=true then return unresolved(member==false and "not_member" or "membership_unknown") end
            local idOK,id,_,idWhy=read("Unit","GetUnitId",token)
            if not idOK then return unresolved(idWhy) end
            if not identity(id) then return unresolved("identity_unknown") end
            if id~=expectedID then return unresolved("identity_changed") end
            -- Public wrapper takes token, not world ID. Only first TWO outputs.
            local pointOK,x,y,pointWhy=read("Unit","GetUnitScreenPosition",token)
            if not pointOK then return unresolved(pointWhy) end
            if not finite(x) or not finite(y) or x<=0 or y<=0 then return unresolved("position_unavailable") end
            local widthOK,width,_,widthWhy=read("Interface","GetScreenWidth")
            if not widthOK then return unresolved(widthWhy) end
            local heightOK,height,_,heightWhy=read("Interface","GetScreenHeight")
            if not heightOK then return unresolved(heightWhy) end
            if not finite(width) or not finite(height) or width<=0 or height<=0 then
                return unresolved("bounds_unavailable")
            end
            if x>width or y>height then return unresolved("outside_bounds") end
            -- Optional scalar only. Axis, units and scale relationship unverified.
            local offsetOK,offset,_,offsetWhy=read("Unit","GetUnitScreenNameTagOffset",token)
            if offsetWhy=="cancelled" then return unresolved(offsetWhy) end
            local offsetKnown=offsetOK and finite(offset)
            if not offsetKnown then offset=nil end
            local afterOK,after,_,afterWhy=read("Unit","GetUnitId",token)
            if not afterOK then return unresolved(afterWhy) end
            local stillOK,still,_,stillWhy=read("Unit","UnitIsTeamMember",token)
            if not stillOK then return unresolved(stillWhy) end
            if after~=id or still~=true then return unresolved("member_changed") end
            return {contract=1,state="screen_point",token=token,identity=id,identityBracketed=true,calls=calls,clear=false,
                positionKnown=true,x=x,y=y,screenWidth=width,screenHeight=height,
                nameTagOffsetKnown=offsetKnown,nameTagOffset=offset,cacheAgeKnown=false,coherent=false,complete=false,
                coordinateScaleKnown=false,offsetUnitsKnown=false,renderedKnown=false,depthKnown=false}
        end
        local ok,result=pcall(run);busy=false
        if not ok then return unresolved("read_failed") end
        return result
    end
    -- Caller supplies a viewport in raw screen-API coordinates and owns the
    -- single-marker frame budget. Keep membership checks; no offset/UI reads.
    local function observeMovementPoint(token,expectedID,alive,width,height)
        local calls=0
        local function unresolved(reason)
            return {contract=1,state="unresolved",reason=reason,token=token,calls=calls,clear=true,positionKnown=false,
                viewportSource="caller",viewportCurrentKnown=false,cacheAgeKnown=false,coherent=false,complete=false,
                coordinateScaleKnown=false,renderedKnown=false,depthKnown=false}
        end
        local function finite(value)
            return type(value)=="number" and value==value and value>-math.huge and value<math.huge
        end
        local valid=false
        for i=1,50 do if token=="team"..i then valid=true;break end end
        if not valid then token=nil;return unresolved("invalid_token") end
        if not identity(expectedID) then return unresolved("invalid_identity") end
        if not finite(width) or not finite(height) or width<=0 or height<=0 then return unresolved("invalid_viewport") end
        if busy then return unresolved("busy") end
        if type(alive)~="function" then return unresolved("lifetime_unverified") end
        busy=true
        local function current()
            local ok,value=pcall(alive);return ok and value==true
        end
        local function read(method)
            if not current() then return false,nil,nil,"cancelled" end
            local ok,unit,fn=pcall(function()
                local unit=api and api.Unit;return unit,unit and unit[method]
            end)
            if not current() then return false,nil,nil,"cancelled" end
            if not ok or type(fn)~="function" then return false,nil,nil,"read_unavailable" end
            calls=calls+1
            local safe,a,b=pcall(fn,unit,token)
            if not current() then return false,nil,nil,"cancelled" end
            if not safe then return false,nil,nil,"read_failed" end
            return true,a,b
        end
        local function run()
            local memberOK,member,_,memberWhy=read("UnitIsTeamMember")
            if not memberOK then return unresolved(memberWhy) end
            if member~=true then return unresolved(member==false and "not_member" or "membership_unknown") end
            local idOK,id,_,idWhy=read("GetUnitId")
            if not idOK then return unresolved(idWhy) end
            if not identity(id) then return unresolved("identity_unknown") end
            if id~=expectedID then return unresolved("identity_changed") end
            local pointOK,x,y,pointWhy=read("GetUnitScreenPosition")
            if not pointOK then return unresolved(pointWhy) end
            if not finite(x) or not finite(y) or x<=0 or y<=0 then return unresolved("position_unavailable") end
            if x>width or y>height then return unresolved("outside_bounds") end
            local afterOK,after,_,afterWhy=read("GetUnitId")
            if not afterOK then return unresolved(afterWhy) end
            local stillOK,still,_,stillWhy=read("UnitIsTeamMember")
            if not stillOK then return unresolved(stillWhy) end
            if after~=id or still~=true then return unresolved("member_changed") end
            return {contract=1,state="screen_point",token=token,identity=id,identityBracketed=true,calls=calls,clear=false,
                positionKnown=true,x=x,y=y,screenWidth=width,screenHeight=height,
                viewportSource="caller",viewportCurrentKnown=false,cacheAgeKnown=false,coherent=false,complete=false,
                coordinateScaleKnown=false,renderedKnown=false,depthKnown=false}
        end
        local ok,result=pcall(run);busy=false
        if not ok then return unresolved("read_failed") end
        return result
    end
    local function observeAuras(token,expectedID,alive)
        local calls=0
        local function unresolved(reason)
            return {contract=1,state="unresolved",reason=reason,token=token,clear=true,
                buffsKnown=false,debuffsKnown=false,buffs={},debuffs={},buffsTruncated=false,debuffsTruncated=false,
                complete=false,coherent=false,cacheAgeKnown=false,absenceVerified=false,calls=calls}
        end
        local valid=token=="target" or token=="player"
        if type(token)=="string" then
            for i=1,50 do if token=="team"..i then valid=true;break end end
        end
        if not valid then token=nil;return unresolved("invalid_token") end
        if not identity(expectedID) then return unresolved("invalid_identity") end
        -- Deeper observation is confined to the already selected target/self.
        local sampleLimit=(token=="target" or token=="player") and 32 or 8
        if busy then return unresolved("busy") end
        if type(alive)~="function" then return unresolved("lifetime_unverified") end
        busy=true
        local function current()
            local ok,value=pcall(alive);return ok and value==true
        end
        local function read(method,index)
            if not current() then return false,nil,"cancelled" end
            local ok,unit,fn=pcall(function()
                local u=api and api.Unit;return u,u and u[method]
            end)
            if not ok or type(fn)~="function" then return false,nil,"read_unavailable" end
            calls=calls+1
            local safe,value
            if index==nil then safe,value=pcall(fn,unit,token) else safe,value=pcall(fn,unit,token,index) end
            if not current() then return false,nil,"cancelled" end
            if not safe then return false,nil,"read_failed" end
            return true,value
        end
        local function plain(value,limit)
            return type(value)=="string" and #value>0 and #value<=limit
                and not value:find("%c") and not value:find("|",1,true) and not value:match("^%s*$")
        end
        local function project(raw,index,kind)
            if type(raw)~="table" then return nil end
            if not current() then return nil,"cancelled" end
            local id=raw.buff_id
            if not current() then return nil,"cancelled" end
            if not integer(id) or id<=0 then return nil end
            local record={id=id,index=index,kind=kind,iconKnown=false,remainingMsKnown=false,stacksKnown=false,
                casterKnown=false,mineKnown=false,dispelKnown=false,durationKnown=false,expiryKnown=false}
            local path=raw.path
            if not current() then return nil,"cancelled" end
            if plain(path,512) then record.iconKnown=true;record.iconPath=path end
            local left=raw.timeLeft
            if not current() then return nil,"cancelled" end
            local unit=raw.timeUnit
            if not current() then return nil,"cancelled" end
            if type(left)=="number" and left==left and left>=0 and left<math.huge then
                local scale
                -- Native FormatRemainTime uses seconds only for explicit "sec".
                if unit=="sec" then scale=1000
                elseif unit==nil or type(unit)=="string" and #unit<=16 and not unit:find("%c") then scale=1 end
                if scale and left*scale<=1000000000000 then
                    record.remainingMsKnown=true;record.remainingMs=left*scale
                end
            end
            local stack=raw.stack
            if not current() then return nil,"cancelled" end
            if integer(stack) and stack<=1000000 then record.stacksKnown=true;record.stacks=stack end
            return record
        end
        local function sample(countMethod,entryMethod,kind)
            local ok,count,why=read(countMethod)
            if why=="cancelled" then return false,nil,{},false,why end
            if not ok or not integer(count) or count>256 then return false,nil,{},false,"count_unavailable" end
            local limit=count;if limit>sampleLimit then limit=sampleLimit end
            local records={}
            for i=1,limit do
                local entryOK,raw,entryWhy=read(entryMethod,i)
                if entryWhy=="cancelled" then return false,nil,{},false,entryWhy end
                if not entryOK then return false,nil,{},false,"entry_unavailable" end
                local projected,record,projectWhy=pcall(project,raw,i,kind);raw=nil
                if projected and projectWhy=="cancelled" then return false,nil,{},false,projectWhy end
                if not projected or not record then return false,nil,{},false,"entry_unavailable" end
                records[#records+1]=record
            end
            local afterOK,after,afterWhy=read(countMethod)
            if afterWhy=="cancelled" then return false,nil,{},false,afterWhy end
            if not afterOK or after~=count then return false,nil,{},false,"count_changed" end
            return true,count,records,count>sampleLimit,"observed"
        end
        local function run()
            local memberOK,member,memberWhy=read("UnitIsTeamMember")
            if not memberOK then return unresolved(memberWhy) end
            if member==false then return unresolved("not_member") end
            if member~=true then return unresolved("membership_unknown") end
            local idOK,id,idWhy=read("GetUnitId")
            if not idOK then return unresolved(idWhy) end
            if not identity(id) then return unresolved("identity_unknown") end
            if id~=expectedID then return unresolved("identity_changed") end
            local bk,bc,buffs,bt,br=sample("UnitBuffCount","UnitBuff","buff")
            if br=="cancelled" then return unresolved(br) end
            local dk,dc,debuffs,dt,dr=sample("UnitDeBuffCount","UnitDeBuff","debuff")
            if dr=="cancelled" then return unresolved(dr) end
            local afterOK,after,afterWhy=read("GetUnitId")
            if not afterOK then return unresolved(afterWhy) end
            local stillOK,stillMember,stillWhy=read("UnitIsTeamMember")
            if not stillOK then return unresolved(stillWhy) end
            if after~=id or stillMember~=true then return unresolved("member_changed") end
            return {contract=1,state="partial",token=token,identity=id,clear=false,
                source=token=="target" and "target" or token=="player" and "player" or "team",identityBracketed=true,
                buffsKnown=bk,buffCount=bc,buffs=buffs,buffsTruncated=bt,buffsReason=br,
                debuffsKnown=dk,debuffCount=dc,debuffs=debuffs,debuffsTruncated=dt,debuffsReason=dr,
                complete=false,coherent=false,cacheAgeKnown=false,absenceVerified=false,calls=calls}
        end
        local ok,result=pcall(run);busy=false
        if not ok then return unresolved("read_failed") end
        return result
    end
    -- Explicit one-shot only. The injected provider owns even partial admission.
    -- release=true confirms inactive lease, never destruction of a retained pool.
    -- No factory/global/native-window lookup occurs in this data boundary.
    local function newRaidAuraDiagnostic(provider)
        local state,reason="ready","not_started"
        local consumed,running,revoked,pending,collecting=false,false,false,false,false
        local observationReason
        local releaseFn,calls,cleanupAttempts=nil,0,0
        local result={}
        local function clear()
            result={entries={},infoKnown=false,tooltipKind="unobserved",targetUnchangedKnown=false}
        end
        clear()
        local function report()
            local out={contract=1,state=state,reason=reason,calls=calls,itemLimit=4,callLimit=13,timeLimitMs=250,
                cleanupPending=pending,cleanupAttempts=cleanupAttempts,samplingActive=collecting and not revoked,
                releaseScope="lease",resourcesFreedKnown=false,
                observationReason=observationReason,
                infoKnown=result.infoKnown,count=result.count,truncated=result.truncated or false,
                tooltipKind=result.tooltipKind,targetUnchangedKnown=result.targetUnchangedKnown,
                targetUnchanged=result.targetUnchanged,nonTargetKnown=result.nonTargetKnown or false,
                nonTarget=result.nonTarget,entries={},complete=false,coherent=false,
                cacheAgeKnown=false,absenceVerified=false,classificationKnown=false,expiryKnown=false}
            local fields={"id","index","iconKnown","iconPath","timeLeftKnown","timeLeft","timeUnitKind",
                "remainingMsKnown","remainingMs","stacksKnown","stacks"}
            for i=1,#result.entries do
                local copy={};out.entries[i]=copy
                for j=1,#fields do local key=fields[j];copy[key]=result.entries[i][key] end
            end
            return out
        end
        local function cleanup()
            if not pending then return true end
            cleanupAttempts=cleanupAttempts+1
            local ok,done=pcall(releaseFn)
            if ok and done==true then pending=false;releaseFn=nil;provider=nil;return true end
            clear();state="cleanup_pending";reason="cleanup_failed";return false
        end
        local function run(token,expectedID,alive)
            if running or busy then
                return {contract=1,state="unavailable",reason="busy",calls=0,entries={},infoKnown=false,
                    cleanupPending=pending,targetUnchangedKnown=false,nonTargetKnown=false}
            end
            if consumed then return report() end
            consumed=true;state="unavailable";reason="invalid_token"
            local valid=false
            for i=1,50 do if token=="team"..i then valid=true;break end end
            if not valid then provider=nil;return report() end
            if not identity(expectedID) then reason="invalid_identity";provider=nil;return report() end
            if type(alive)~="function" then reason="lifetime_unverified";provider=nil;return report() end
            running=true;busy=true;collecting=true
            local start,last,clock,acquire,targetBefore
            local sampling=true
            local function current()
                if revoked then reason="cancelled";return false end
                local ok,live=pcall(alive)
                if revoked or not ok or live~=true then reason="cancelled";return false end
                local safe,now=pcall(clock)
                if revoked then reason="cancelled";return false end
                if not safe or type(now)~="number" or now~=now or now<0 or now>9007199254740991
                    or last and now<last then reason="clock_unavailable";return false end
                if not start then start=now end
                last=now
                if now-start>250 then reason="time_limit";return false end
                local finalOK,finalLive=pcall(alive)
                if revoked or not finalOK or finalLive~=true then reason="cancelled";return false end
                return true
            end
            local function read(object,method,arg,index,audit)
                if not audit and not sampling then reason="cancelled";return false end
                if not current() then return false end
                local ok,fn=pcall(function()return object and object[method]end)
                if not ok or type(fn)~="function" then reason="getter_unavailable";return false end
                if not current() then return false end
                if calls>=13 then reason="call_limit";return false end
                calls=calls+1
                local safe,value
                if index==nil then safe,value=pcall(fn,object,arg) else safe,value=pcall(fn,object,arg,index) end
                if not current() then return false end
                if not safe then reason="getter_failed";return false end
                return true,value
            end
            local function plain(value,limit)
                return type(value)=="string" and #value>0 and #value<=limit
                    and not value:find("%c") and not value:find("|",1,true) and not value:match("^%s*$")
            end
            local function project(raw,index)
                if type(raw)~="table" then reason="entry_unavailable";return nil end
                local keys={"buff_id","path","timeLeft","timeUnit","stack"};local values={}
                for i=1,5 do
                    if not current() then return nil end
                    local ok,value=pcall(function()return raw[keys[i]]end)
                    if not current() then return nil end
                    if not ok then reason="entry_unavailable";return nil end
                    values[i]=value
                end
                local id,path,left,unit,stack=values[1],values[2],values[3],values[4],values[5]
                if not integer(id) or id<=0 then reason="entry_unavailable";return nil end
                local entry={id=id,index=index,iconKnown=false,timeLeftKnown=false,remainingMsKnown=false,
                    stacksKnown=false,timeUnitKind="invalid"}
                if plain(path,512) then entry.iconKnown=true;entry.iconPath=path end
                local scale
                if unit==nil then entry.timeUnitKind="nil";scale=1
                elseif unit=="sec" then entry.timeUnitKind="sec";scale=1000
                elseif type(unit)=="string" and #unit<=16 and not unit:find("%c") then
                    entry.timeUnitKind="other_string";scale=1
                end
                if type(left)=="number" and left==left and left>=0 and left<=1000000000000 then
                    entry.timeLeftKnown=true;entry.timeLeft=left
                    if scale and left*scale<=1000000000000 then
                        entry.remainingMsKnown=true;entry.remainingMs=left*scale
                    end
                end
                if integer(stack) and stack<=1000000 then entry.stacksKnown=true;entry.stacks=stack end
                return entry
            end
            local unit
            local ok=pcall(function()
                local admitted=type(provider)=="table" and provider.contract==1
                acquire=admitted and provider.acquire;releaseFn=admitted and provider.release
                clock=admitted and provider.nowMs
                if type(acquire)~="function" or type(releaseFn)~="function" or type(clock)~="function" then
                    reason="provider_unavailable";return
                end
                if not current() then return end
                unit=api and api.Unit
                local beforeOK,before=read(unit,"GetUnitId","target")
                if not beforeOK then
                    if reason=="cancelled" or reason=="time_limit" or reason=="clock_unavailable" then return end
                elseif identity(before) then targetBefore=before end
                if targetBefore==expectedID then reason="selected_member";return end
                local memberOK,member=read(unit,"UnitIsTeamMember",token)
                if not memberOK then return end
                if member~=true then reason=member==false and "not_member" or "membership_unknown";return end
                local idOK,id=read(unit,"GetUnitId",token)
                if not idOK then return end
                if not identity(id) or id~=expectedID then reason="identity_changed";return end
                if not current() then return end
                -- Set ownership obligation BEFORE admission can partially allocate/throw.
                pending=true
                local created,g=pcall(acquire)
                if not current() then return end
                if not created or type(g)~="table" then reason="admission_failed";return end
                local countOK,count=read(g,"count",token)
                if not countOK then return end
                if not integer(count) or count>256 then reason="count_unavailable";return end
                local entries={};local limit=count;if limit>4 then limit=4 end
                for i=1,limit do
                    local infoOK,raw=read(g,"info",token,i)
                    if not infoOK then return end
                    local entry=project(raw,i);raw=nil
                    if not entry then return end
                    entries[i]=entry
                end
                if limit>0 then
                    local tipOK,tip=read(g,"tooltip",token,1)
                    if not tipOK then
                        if reason=="cancelled" or reason=="time_limit" or reason=="clock_unavailable" then return end
                        result.tooltipKind="unavailable"
                    else
                        local kind=type(tip)
                        result.tooltipKind=(kind=="string" or kind=="table" or kind=="nil") and kind or "other"
                    end
                    tip=nil
                end
                local afterCountOK,afterCount=read(g,"count",token)
                if not afterCountOK then return end
                if afterCount~=count then reason="count_changed";return end
                local afterOK,after=read(unit,"GetUnitId",token)
                if not afterOK then return end
                local stillOK,still=read(unit,"UnitIsTeamMember",token)
                if not stillOK then return end
                if after~=id or still~=true then reason="member_changed";return end
                result.entries=entries;result.count=count;result.truncated=count>4;result.infoKnown=true
                result.nonTargetKnown=targetBefore~=nil
                if targetBefore then result.nonTarget=true end
                state="diagnostic";reason="observed"
            end)
            if not ok then state="unavailable";reason="probe_failed" end
            if state~="diagnostic" then clear() end
            -- Revoke all effect reads before release, including on callback throws.
            sampling=false;collecting=false;observationReason=reason
            local released=cleanup()
            -- A final target-only audit includes release side effects; it is skipped
            -- after stop, owner revocation, deadline, or unresolved cleanup.
            if released and clock and unit and not revoked then
                local savedReason=reason
                local safe,auditOK,after=pcall(read,unit,"GetUnitId","target",nil,true)
                if safe and auditOK then
                    if targetBefore and identity(after) then
                        result.targetUnchangedKnown=true;result.targetUnchanged=after==targetBefore
                        if after~=targetBefore then
                            clear();result.targetUnchangedKnown=true;result.targetUnchanged=false
                            state="unavailable";reason="target_changed"
                        end
                    end
                    if reason~="target_changed" then reason=savedReason end
                else
                    if reason=="cancelled" or reason=="time_limit" or reason=="clock_unavailable" or not safe then
                        clear();state="unavailable";if not safe then reason="probe_failed" end
                    else reason=savedReason end
                end
            end
            if revoked then clear();state="unavailable";reason="cancelled" end
            if not pending then provider=nil;releaseFn=nil end
            running=false;busy=false
            return report()
        end
        local function stop()
            revoked=true;collecting=false
            if running then return false,"stopping" end
            consumed=true;clear();state="unavailable";reason="cancelled"
            if busy then return false,"busy" end
            busy=true;local done=cleanup();busy=false
            if not pending then provider=nil;releaseFn=nil end
            return done
        end
        local function retryCleanup()
            if running or busy then return false,"busy" end
            local wasPending=pending
            busy=true;local done=cleanup();busy=false
            if wasPending and done then state="finished";reason="cleanup_recovered" end
            return done
        end
        return {contract=1,run=run,stop=stop,report=report,retryCleanup=retryCleanup}
    end
    -- Caller drives this opt-in service from the EXISTING shared scheduler.
    -- No independent timers, roster discovery, target changes or alert output.
    local function newRaidAuraObserver(provider)
        local state,reason="disabled","not_started"
        local started,enabled,running,leaseHeld,cleanupPending=false,false,false,false,false
        local selected,selectedCount,seen,cursor={},0,{},0
        local alive,acquire,releaseFn,clock,getters,lastClock,nextDue
        local cleanupAttempts,steps,latchedActors=0,0,0
        local latchLimitReached=false
        local coverage,clockAttempts,unitGetterAttempts="prefix",0,0
        local queue,windows,lastActor={},{},nil
        local epoch,epochLimit,epochAttempts,epochActors,epochBegan=nil,nil,0,{},nil
        local epochClockCalls,epochUnitCalls=0,0
        local function report()
            return {contract=1,state=state,reason=reason,enabled=enabled,leaseHeld=leaseHeld,
                cleanupPending=cleanupPending,cleanupAttempts=cleanupAttempts,steps=steps,
                selectedCount=selectedCount,itemLimit=8,callLimit=14,intervalMs=250,timeLimitMs=coverage=="rotating" and 6 or 25,
                coverage=coverage,unitGetterLimit=14,unitGetterCallsTotal=unitGetterAttempts,clockCallsTotal=clockAttempts,
                totalPublicAttemptsTotal=unitGetterAttempts+clockAttempts,
                clockCallLimit=coverage=="rotating" and (getters and 30 or 32) or (getters and 125 or 127),
                windowId=epoch,filteredLimit=epochLimit,windowAttempts=epochAttempts,
                windowClockCalls=epochClockCalls,windowUnitCalls=epochUnitCalls,
                windowPublicAttempts=epochClockCalls+epochUnitCalls,
                releaseScope="lease",resourcesFreedKnown=false,cacheAgeKnown=false,complete=false,
                coherent=false,absenceVerified=false,classificationKnown=false,instanceIdentityKnown=false,
                durationKnown=false,expiryKnown=false,refreshKnown=false,firstObservedScope="enabled_generation",
                latchActorLimit=64,latchedActors=latchedActors,latchLimitReached=latchLimitReached}
        end
        local function cleanup()
            getters=nil
            if not leaseHeld then provider=nil;return true end
            cleanupAttempts=cleanupAttempts+1
            local ok,done=pcall(releaseFn)
            if ok and done==true then
                leaseHeld=false;cleanupPending=false;provider=nil;releaseFn=nil;return true
            end
            cleanupPending=true;state="cleanup_pending";reason="cleanup_failed";return false
        end
        local function start(ids,live,options)
            if started then return false,"already_started" end
            if busy or running then return false,"busy" end
            if type(live)~="function" then return false,"lifetime_unverified" end
            local requested="prefix"
            if options~=nil then
                local safe,valid=pcall(function()
                    return type(options)=="table" and options.contract==1 and options.coverage=="rotating"
                end)
                if not safe or not valid then return false,"invalid_coverage" end
                requested="rotating"
            end
            local ok,choice,count=pcall(function()
                if type(ids)~="table" or #ids<1 or #ids>64 then return nil end
                local set,n={},0
                for i=1,#ids do
                    local id=ids[i];if not integer(id) or id<=0 then return nil end
                    if not set[id] then set[id]=true;n=n+1 end
                end
                return set,n
            end)
            if not ok or not choice then return false,"invalid_selection" end
            local safe=pcall(function()
                if type(provider)~="table" or provider.contract~=1 then return end
                acquire=provider.acquire;releaseFn=provider.release;clock=provider.nowMs
            end)
            if not safe or type(acquire)~="function" or type(releaseFn)~="function" or type(clock)~="function" then
                return false,"provider_unavailable"
            end
            coverage=requested
            selected=choice;selectedCount=count;alive=live;started=true;enabled=true
            state="enabled";reason="armed";return true
        end
        local function stop()
            enabled=false;started=true;seen={}
            queue={};windows={};lastActor=nil;epochActors={}
            state="stopped";reason="stopped"
            if leaseHeld then cleanupPending=true end
            if running then return false,"stopping" end
            if busy then return false,"busy" end
            busy=true;local done=cleanup();busy=false;return done
        end
        local function retryCleanup()
            if running or busy then return false,"busy" end
            if not cleanupPending then return not leaseHeld end
            busy=true;local done=cleanup();busy=false
            if done then state="stopped";reason="cleanup_recovered" end
            return done
        end
        local function step(rows,budget)
            local out={contract=1,state="unavailable",reason="disabled",calls=0,entries={},infoKnown=false,
                clockCalls=0,clockCallLimit=getters and 125 or 127,totalPublicAttempts=0,unitGetterLimit=14,coverage="prefix",
                truncated=false,budgetAccepted=false,reservedCalls=0,cleanupPending=cleanupPending,cacheAgeKnown=false,complete=false,
                coherent=false,absenceVerified=false,classificationKnown=false,instanceIdentityKnown=false,
                durationKnown=false,expiryKnown=false,refreshKnown=false,source="raid_filtered",
                firstObservedScope="enabled_generation",latchLimitReached=latchLimitReached}
            if running or busy then out.reason="busy";return out end
            if not enabled then out.reason=reason;return out end
            if coverage~="prefix" then out.reason="mode_conflict";return out end
            running=true;busy=true
            local clockStart=clockAttempts
            local began,now
            local function current()
                if not enabled then out.reason="cancelled";return false end
                local ok,live=pcall(alive)
                if not enabled or not ok or live~=true then out.reason="cancelled";return false end
                clockAttempts=clockAttempts+1
                local safe,time=pcall(clock)
                if not enabled then out.reason="cancelled";return false end
                if not safe or type(time)~="number" or time~=time or time<0 or time>9007199254740991
                    or lastClock and time<lastClock then out.reason="clock_unavailable";return false end
                now=time;lastClock=time
                if not began then began=time end
                if time-began>25 then out.reason="time_limit";return false end
                local finalOK,finalLive=pcall(alive)
                if not enabled or not finalOK or finalLive~=true then out.reason="cancelled";return false end
                return true
            end
            local function read(object,method,arg,index)
                if not current() then return false end
                local ok,fn=pcall(function()return object and object[method]end)
                if not ok or type(fn)~="function" then out.reason="getter_unavailable";return false end
                if not current() then return false end
                if out.calls>=14 then out.reason="call_limit";return false end
                out.calls=out.calls+1
                local safe,value
                if index==nil then safe,value=pcall(fn,object,arg)else safe,value=pcall(fn,object,arg,index)end
                if not current() then return false end
                if not safe then out.reason="getter_failed";return false end
                return true,value
            end
            local function field(raw,key)
                if not current() then return false end
                local ok,value=pcall(function()return raw[key]end)
                if not current() then return false end
                if not ok then out.reason="entry_unavailable";return false end
                return true,value
            end
            local function plain(value,limit)
                return type(value)=="string" and #value>0 and #value<=limit
                    and not value:find("%c") and not value:find("|",1,true) and not value:match("^%s*$")
            end
            local ok=pcall(function()
                local claim=type(budget)=="table" and budget.contract==1 and budget.claim
                if type(claim)~="function" then out.reason="budget_unavailable";return end
                if type(rows)~="table" or #rows>50 then out.reason="invalid_rows";return end
                local accepted,identities,tokens={},{},{}
                for i=1,#rows do
                    local row=rows[i]
                    if type(row)~="table" or not identity(row.identity) then out.reason="invalid_rows";return end
                    local token=row.token;local valid=false
                    for j=1,50 do if token=="team"..j then valid=true;break end end
                    if not valid or tokens[token] or identities[row.identity] then out.reason="invalid_rows";return end
                    accepted[i]={token=token,identity=row.identity};tokens[token]=true;identities[row.identity]=true
                end
                if not current() then return end
                if #accepted==0 then out.reason="no_members";return end
                if nextDue and now<nextDue then out.reason="not_due";return end
                cursor=cursor%#accepted+1
                local row=accepted[cursor];out.token=row.token;out.identity=row.identity
                local granted=claim(row.token,row.identity,14)
                if granted==true then out.budgetAccepted=true;out.reservedCalls=14 end
                if not current() then return end
                if granted~=true then out.reason="budget_blocked";return end
                nextDue=now+250;steps=steps+1
                local unit=api and api.Unit
                local memberOK,member=read(unit,"UnitIsTeamMember",row.token)
                if not memberOK then return end
                if member~=true then out.reason=member==false and "not_member" or "membership_unknown";return end
                local idOK,id=read(unit,"GetUnitId",row.token)
                if not idOK then return end
                if id~=row.identity then out.reason="identity_changed";return end
                if not getters then
                    if not current() then return end
                    leaseHeld=true
                    local admitted,g=pcall(acquire)
                    if admitted and type(g)=="table" then getters=g end
                    if not current() then return end
                    if not getters then out.reason="admission_failed";return end
                end
                local countOK,count=read(getters,"count",row.token)
                if not countOK then return end
                if not integer(count) or count>256 then out.reason="count_unavailable";return end
                local limit=count;if limit>8 then limit=8 end
                local entries={}
                for i=1,limit do
                    local infoOK,raw=read(getters,"info",row.token,i)
                    if not infoOK then return end
                    if type(raw)~="table" then out.reason="entry_unavailable";return end
                    local idRead,effectID=field(raw,"buff_id")
                    if not idRead then return end
                    if not integer(effectID) or effectID<=0 then out.reason="entry_unavailable";return end
                    if selected[effectID] then
                        local entry={id=effectID,index=i,iconKnown=false,remainingMsKnown=false,stacksKnown=false}
                        local pathOK,path=field(raw,"path");if not pathOK then return end
                        if plain(path,512) then entry.iconKnown=true;entry.iconPath=path end
                        local leftOK,left=field(raw,"timeLeft");if not leftOK then return end
                        local unitOK,timeUnit=field(raw,"timeUnit");if not unitOK then return end
                        local scale
                        if timeUnit=="sec" then scale=1000
                        elseif timeUnit==nil or type(timeUnit)=="string" and #timeUnit<=16 and not timeUnit:find("%c") then scale=1 end
                        if type(left)=="number" and left==left and left>=0 and scale and left*scale<=1000000000000 then
                            entry.remainingMsKnown=true;entry.remainingMs=left*scale
                        end
                        local stackOK,stack=field(raw,"stack");if not stackOK then return end
                        if integer(stack) and stack<=1000000 then entry.stacksKnown=true;entry.stacks=stack end
                        entries[#entries+1]=entry
                    end
                    raw=nil
                end
                local countAfterOK,countAfter=read(getters,"count",row.token)
                if not countAfterOK then return end
                if countAfter~=count then out.reason="count_changed";return end
                local afterOK,after=read(unit,"GetUnitId",row.token)
                if not afterOK then return end
                local stillOK,still=read(unit,"UnitIsTeamMember",row.token)
                if not stillOK then return end
                if after~=id or still~=true then out.reason="member_changed";return end
                if not current() then return end
                -- Unknown reads/temporary row loss never rearm an alert. Keep a
                -- bounded generation-wide latch; saturation suppresses new alerts.
                local prior=seen[id]
                if not prior and #entries>0 then
                    if latchedActors<64 then prior={};seen[id]=prior;latchedActors=latchedActors+1
                    else latchLimitReached=true end
                end
                for i=1,#entries do
                    local entry=entries[i];entry.firstObservationKnown=prior~=nil
                    entry.firstObserved=prior~=nil and not prior[entry.id]
                    if prior then prior[entry.id]=true end
                end
                out.state="partial";out.reason="observed";out.infoKnown=true;out.count=count
                out.truncated=count>8;out.entries=entries;out.observedAtMs=now;out.latchLimitReached=latchLimitReached
            end)
            if not ok then out.reason="observer_failed" end
            if out.state~="partial" then out.entries={};out.infoKnown=false end
            if not enabled or out.reason=="cancelled" or out.reason=="clock_unavailable" or out.reason=="admission_failed" then
                enabled=false;started=true;seen={};state="stopped";reason=out.reason
                cleanup()
            else reason=out.reason end
            out.cleanupPending=cleanupPending
            if cleanupPending then out.state="unavailable";out.reason="cleanup_failed";out.entries={};out.infoKnown=false end
            out.clockCalls=clockAttempts-clockStart;out.totalPublicAttempts=out.calls+out.clockCalls
            unitGetterAttempts=unitGetterAttempts+out.calls
            running=false;busy=false
            return out
        end
        local function stepRotating(rows,grant)
            local out={contract=1,state="unavailable",reason="disabled",calls=0,clockCalls=0,clockCallLimit=getters and 30 or 32,
                unitGetterLimit=14,
                totalPublicAttempts=0,entries={},infoKnown=false,truncated=false,budgetAccepted=false,reservedCalls=0,
                cleanupPending=cleanupPending,source="raid_filtered",coverage="rotating",windowVerified=false,
                windowStart=0,windowEnd=0,sampleStart=0,sampleEnd=0,sampledCount=0,cursorAdvanced=false,wrapped=false,
                cacheAgeKnown=false,complete=false,coherent=false,absenceVerified=false,classificationKnown=false,
                instanceIdentityKnown=false,durationKnown=false,expiryKnown=false,refreshKnown=false,
                firstObservedScope="enabled_generation",latchLimitReached=latchLimitReached}
            if running or busy then out.reason="busy";return out end
            if not enabled then out.reason=reason;return out end
            if coverage~="rotating" then out.reason="mode_conflict";return out end
            running=true;busy=true
            local clockStart=clockAttempts
            local now,requestedEpoch,row,actorVerified
            local function live()
                if not enabled then out.reason="cancelled";return false end
                local ok,value=pcall(alive)
                if not enabled or not ok or value~=true then out.reason="cancelled";return false end
                return true
            end
            local function time(checkDeadline)
                if not live() then return false end
                if clockAttempts-clockStart>=out.clockCallLimit then out.reason="clock_limit";return false end
                clockAttempts=clockAttempts+1
                local safe,value=pcall(clock)
                if not live() then return false end
                if not safe or type(value)~="number" or value~=value or value<0 or value>9007199254740991
                    or lastClock and value<lastClock then out.reason="clock_unavailable";return false end
                now=value;lastClock=value
                if checkDeadline and epochBegan and value-epochBegan>6 then out.reason="time_limit";return false end
                return true
            end
            local function read(object,method,index)
                if not live() then return false end
                local ok,fn=pcall(function()return object and object[method]end)
                if not live() then return false end
                if not ok or type(fn)~="function" then out.reason="getter_unavailable";return false end
                if not time(true) then return false end
                if out.calls>=14 then out.reason="call_limit";return false end
                out.calls=out.calls+1
                local safe,value
                if index==nil then safe,value=pcall(fn,object,row.token)else safe,value=pcall(fn,object,row.token,index)end
                if not live() or not time(true) then return false end
                if not safe then out.reason="getter_failed";return false end
                return true,value
            end
            local function field(raw,key)
                if not live() then return false end
                local ok,value=pcall(function()return raw[key]end)
                if not live() then return false end
                if not ok then out.reason="entry_unavailable";return false end
                return true,value
            end
            local function fatal()
                return out.reason=="cancelled" or out.reason=="clock_unavailable" or out.reason=="time_limit"
                    or out.reason=="clock_limit" or out.reason=="call_limit"
            end
            local function plain(value,limit)
                return type(value)=="string" and #value>0 and #value<=limit
                    and not value:find("%c") and not value:find("|",1,true) and not value:match("^%s*$")
            end
            local function project(raw,index)
                if type(raw)~="table" then out.reason="entry_unavailable";return false end
                local idOK,id=field(raw,"buff_id");if not idOK then return false end
                if not integer(id) or id<=0 then out.reason="entry_unavailable";return false end
                if not selected[id] then return true end
                local entry={id=id,index=index,iconKnown=false,remainingMsKnown=false,stacksKnown=false}
                local pathOK,path=field(raw,"path");if not pathOK then return false end
                if plain(path,512) then entry.iconKnown=true;entry.iconPath=path end
                local leftOK,left=field(raw,"timeLeft");if not leftOK then return false end
                local unitOK,unit=field(raw,"timeUnit");if not unitOK then return false end
                local scale
                if unit=="sec" then scale=1000
                elseif unit==nil or type(unit)=="string" and #unit<=16 and not unit:find("%c") then scale=1 end
                if type(left)=="number" and left==left and left>=0 and scale and left*scale<=1000000000000 then
                    entry.remainingMsKnown=true;entry.remainingMs=left*scale
                end
                local stackOK,stack=field(raw,"stack");if not stackOK then return false end
                if integer(stack) and stack<=1000000 then entry.stacksKnown=true;entry.stacks=stack end
                return true,entry
            end
            local ok=pcall(function()
                local claim=type(grant)=="table" and grant.contract==1 and grant.claim
                if type(claim)~="function" then out.reason="budget_unavailable";return end
                requestedEpoch=grant.windowId
                local limit=grant.filteredLimit
                if type(requestedEpoch)~="number" or requestedEpoch~=requestedEpoch or requestedEpoch<0
                    or requestedEpoch>9007199254740991 then out.reason="invalid_epoch";return end
                if not integer(limit) or limit>3 then out.reason="invalid_quota";return end
                out.windowId=requestedEpoch;out.filteredLimit=limit
                if limit==0 then out.reason="filtered_quota_zero";return end
                if epoch and requestedEpoch<epoch then out.reason="stale_epoch";return end
                if epoch and requestedEpoch~=epoch and requestedEpoch-epoch<250 then out.reason="invalid_epoch";return end
                if epoch==requestedEpoch and epochLimit~=limit then out.reason="policy_changed";return end
                if epoch==requestedEpoch and epochAttempts>=limit then out.reason="window_limit";return end
                if type(rows)~="table" or #rows>50 then out.reason="invalid_rows";return end
                local ordered,byID,tokens={},{},{}
                for i=1,#rows do
                    if not live() then return end
                    local item=rows[i]
                    if type(item)~="table" then out.reason="invalid_rows";return end
                    local id=item.identity;if not live() then return end
                    local token=item.token;if not live() then return end
                    local valid=false
                    for j=1,50 do if token=="team"..j then valid=true;break end end
                    if not valid or not identity(id) or byID[id] or tokens[token] then out.reason="invalid_rows";return end
                    local copy={identity=id,token=token};ordered[i]=copy;byID[id]=copy;tokens[token]=true
                end
                if #ordered==0 then queue={};windows={};out.reason="no_members";return end
                local nextQueue,nextWindows,added={},{},{}
                for i=1,#queue do
                    local item=byID[queue[i].identity]
                    if item then nextQueue[#nextQueue+1]=item;added[item.identity]=true end
                end
                for i=1,#ordered do
                    local item=ordered[i]
                    if not added[item.identity] then nextQueue[#nextQueue+1]=item end
                    local old=windows[item.identity]
                    if old and old.token==item.token then nextWindows[item.identity]=old
                    else nextWindows[item.identity]={token=item.token,nextIndex=1,
                        resetReason=old and "token_changed" or "new_actor"}end
                end
                local already=epoch==requestedEpoch and epochActors or {}
                local lastIndex=0
                for i=1,#nextQueue do if nextQueue[i].identity==lastActor then lastIndex=i;break end end
                for n=1,#nextQueue do
                    local item=nextQueue[(lastIndex+n-1)%#nextQueue+1]
                    if not already[item.identity] then row=item;break end
                end
                if not row then out.reason="no_eligible_members";return end
                if not time(false) then return end
                if requestedEpoch>now or now-requestedEpoch>=250 then
                    if epoch==requestedEpoch then epochAttempts=epochLimit end
                    out.reason="epoch_expired";return
                end
                if epoch~=requestedEpoch then
                    epoch=requestedEpoch;epochLimit=limit;epochAttempts=0;epochActors={};epochBegan=now
                    epochClockCalls=0;epochUnitCalls=0
                end
                queue=nextQueue;windows=nextWindows
                epochAttempts=epochAttempts+1;epochActors[row.identity]=true;lastActor=row.identity
                out.token=row.token;out.identity=row.identity
                if now-epochBegan>6 then out.reason="time_limit";return end
                local granted=claim(row.token,row.identity,14)
                if granted==true then out.budgetAccepted=true;out.reservedCalls=14;steps=steps+1 end
                if not live() then return end
                if granted~=true then out.reason="budget_blocked";return end
                local unit=api and api.Unit
                local memberOK,member=read(unit,"UnitIsTeamMember")
                if not memberOK then return end
                if member~=true then out.reason=member==false and "not_member" or "membership_unknown";return end
                local idOK,id=read(unit,"GetUnitId")
                if not idOK then return end
                if id~=row.identity then out.reason="identity_changed";return end
                if not getters then
                    if not time(true) then return end
                    leaseHeld=true
                    local admitted,g=pcall(acquire)
                    if admitted and type(g)=="table" then getters=g end
                    if not time(true) then return end
                    if not getters then out.reason="admission_failed";return end
                end
                local countOK,count=read(getters,"count")
                if not countOK then return end
                if not integer(count) or count>256 then out.reason="count_unavailable";return end
                local position=windows[id]
                local first=position.nextIndex
                if first>count then first=1 end
                local last=first+7;if last>count then last=count end
                if count==0 then first=0;last=0 end
                out.count=count;out.windowStart=first;out.windowEnd=last
                out.cursorResetReason=position.resetReason
                out.countChangedSincePrior=position.lastCount~=nil and position.lastCount~=count
                local entries={};local windowReason
                if count>0 then
                    for i=first,last do
                        local before=out.calls
                        local infoOK,raw=read(getters,"info",i)
                        if out.calls>before then
                            out.sampledCount=out.sampledCount+1
                            if out.sampleStart==0 then out.sampleStart=i end
                            out.sampleEnd=i
                        end
                        if not infoOK then
                            if fatal() then return end
                            windowReason=windowReason or out.reason
                        else
                            local projected,entry=project(raw,i)
                            if not projected then
                                if fatal() then return end
                                windowReason=windowReason or out.reason
                            elseif entry then entries[#entries+1]=entry end
                        end
                        raw=nil
                    end
                end
                local afterCountOK,afterCount=read(getters,"count")
                if not afterCountOK then
                    if fatal() then return end
                    windowReason=windowReason or out.reason
                elseif not integer(afterCount) or afterCount>256 then
                    afterCountOK=false;windowReason="count_unavailable"
                elseif afterCount~=count then windowReason="count_changed" end
                local afterOK,after=read(unit,"GetUnitId")
                if not afterOK then return end
                local stillOK,still=read(unit,"UnitIsTeamMember")
                if not stillOK then return end
                if after~=id or still~=true then out.reason="member_changed";return end
                actorVerified=true
                if not time(true) then return end
                local domain=afterCountOK and afterCount or count
                local nextIndex=last+1
                if domain==0 or nextIndex>domain then nextIndex=1;out.wrapped=true end
                windows[id]={token=row.token,nextIndex=nextIndex,lastCount=domain}
                out.nextIndex=nextIndex;out.cursorAdvanced=true
                out.truncated=count>out.sampledCount
                if windowReason then out.reason=windowReason;return end
                local prior=seen[id]
                if not prior and #entries>0 then
                    if latchedActors<64 then prior={};seen[id]=prior;latchedActors=latchedActors+1
                    else latchLimitReached=true end
                end
                for i=1,#entries do
                    local entry=entries[i];entry.firstObservationKnown=prior~=nil
                    entry.firstObserved=prior~=nil and not prior[entry.id]
                    if prior then prior[entry.id]=true end
                end
                out.state="partial";out.reason="observed";out.infoKnown=true;out.windowVerified=true
                out.entries=entries;out.observedAtMs=now;out.latchLimitReached=latchLimitReached
            end)
            if not ok then out.reason="observer_failed" end
            if row and not actorVerified and out.budgetAccepted and
                (out.reason=="not_member" or out.reason=="membership_unknown" or out.reason=="identity_changed" or out.reason=="member_changed") then
                windows[row.identity]={token=row.token,nextIndex=1,resetReason="actor_unverified"}
            end
            if out.state~="partial" then out.entries={};out.infoKnown=false end
            if not enabled or out.reason=="cancelled" or out.reason=="clock_unavailable" or out.reason=="admission_failed" then
                enabled=false;started=true;seen={};queue={};windows={};lastActor=nil;epochActors={};state="stopped";reason=out.reason
                cleanup()
            else reason=out.reason end
            out.cleanupPending=cleanupPending
            if cleanupPending then out.state="unavailable";out.reason="cleanup_failed";out.entries={};out.infoKnown=false end
            out.clockCalls=clockAttempts-clockStart;out.totalPublicAttempts=out.calls+out.clockCalls
            unitGetterAttempts=unitGetterAttempts+out.calls
            if epoch==requestedEpoch then
                epochClockCalls=epochClockCalls+out.clockCalls;epochUnitCalls=epochUnitCalls+out.calls
            end
            out.windowAttempts=epochAttempts;out.windowClockCalls=epochClockCalls;out.windowUnitCalls=epochUnitCalls
            out.windowPublicAttempts=epochClockCalls+epochUnitCalls
            running=false;busy=false
            return out
        end
        return {contract=1,start=start,step=step,stepRotating=stepRotating,stop=stop,report=report,retryCleanup=retryCleanup}
    end
    return {snapshot=function() return nil,"roster_unverified" end,probe=probe,
        memberContract=1,memberManaContract=1,observeMember=observeMember,
        slotMetadataContract=1,observeSlotMetadata=observeSlotMetadata,
        targetValidationContract=1,validateTarget=validateTarget,distanceContract=1,memberDisplayContract=1,memberRoleContract=1,
        memberAuraContract=1,targetAuraDepthContract=1,observeAuras=observeAuras,memberClassContract=1,
        raidAuraDiagnosticContract=1,newRaidAuraDiagnostic=newRaidAuraDiagnostic,
        raidAuraObserverContract=1,newRaidAuraObserver=newRaidAuraObserver,
        memberScreenPointContract=1,observeScreenPoint=observeScreenPoint,
        memberMovementPointContract=1,observeMovementPoint=observeMovementPoint,raidAuraCoverageContract=1}
end
-- Pure passive collector. HQ owns the dedicated listener, deadline and teardown;
-- this object never registers events, reads units or retains event arguments.
function M.newResourceEventDiagnostic(alive)
    local fields={"nilArgs","booleanArgs","numberArgs","stringArgs","tableArgs","functionArgs",
        "userdataArgs","threadArgs","otherArgs","numberInteger","numberFractional","numberNonfinite",
        "stringEmpty","stringBounded","stringLong"}
    local topics={"health","mana"}
    local function empty()
        local result={}
        for t=1,2 do
            local topic={count=0,positions={}};result[topics[t]]=topic
            for i=1,8 do
                local row={};topic.positions[i]=row
                for j=1,#fields do row[fields[j]]=0 end
            end
        end
        return result
    end
    local counters=empty();local total=0;local busy=false
    local state,reason="collecting","collecting"
    if type(alive)~="function" then state="unavailable";reason="lifetime_unverified" end
    local function current()
        if state~="collecting" then return false end
        local ok,value=pcall(alive)
        if state~="collecting" then return false end
        if not ok or value~=true then
            state="cancelled";reason="cancelled";total=0;counters=empty();return false
        end
        return true
    end
    local function shape(value)
        local kind=type(value);local key="otherArgs";local detail
        if kind=="nil" then key="nilArgs"
        elseif kind=="boolean" then key="booleanArgs"
        elseif kind=="number" then
            key="numberArgs"
            if value~=value or value<=-math.huge or value>=math.huge then detail="numberNonfinite"
            elseif value==math.floor(value) then detail="numberInteger" else detail="numberFractional" end
        elseif kind=="string" then
            key="stringArgs"
            if #value==0 then detail="stringEmpty" elseif #value<=128 then detail="stringBounded" else detail="stringLong" end
        elseif kind=="table" then key="tableArgs"
        elseif kind=="function" then key="functionArgs"
        elseif kind=="userdata" then key="userdataArgs"
        elseif kind=="thread" then key="threadArgs" end
        return {key=key,detail=detail}
    end
    local function observe(event,a1,a2,a3,a4,a5,a6,a7,a8)
        if busy then return false,"busy" end
        if state~="collecting" then return false,reason end
        local topic
        if event=="TEAM_HEALTH_CHANGED" then topic="health"
        elseif event=="TEAM_MANA_CHANGED" then topic="mana" else return false,"ignored" end
        busy=true
        local ok,accepted,why=pcall(function()
            if not current() then return false,reason end
            -- Only primitive descriptors are staged; payloads are not saved.
            local staged={shape(a1),shape(a2),shape(a3),shape(a4),shape(a5),shape(a6),shape(a7),shape(a8)}
            if not current() then return false,reason end
            local data=counters[topic];data.count=data.count+1;total=total+1
            for i=1,8 do
                local row=data.positions[i];local descriptor=staged[i]
                row[descriptor.key]=row[descriptor.key]+1
                if descriptor.detail then row[descriptor.detail]=row[descriptor.detail]+1 end
            end
            if total==64 then state="complete";reason="event_cap" end
            return true,reason
        end)
        busy=false
        if not ok then
            state="unavailable";reason="diagnostic_failed";total=0;counters=empty();return false,reason
        end
        return accepted,why
    end
    local function report()
        if busy then return {contract=1,state="unavailable",reason="busy"} end
        if state=="collecting" then busy=true;current();busy=false end
        local result={contract=1,state=state,reason=reason,eventLimit=64,positionLimit=8,eventsSeen=total,
            argumentCountKnown=false,payloadSchemaVerified=false,actorAttributed=false,
            freshnessKnown=false,resourceCoverageKnown=false,events=empty()}
        for t=1,2 do
            local key=topics[t];result.events[key].count=counters[key].count
            for i=1,8 do
                for j=1,#fields do
                    local field=fields[j];result.events[key].positions[i][field]=counters[key].positions[i][field]
                end
            end
        end
        return result
    end
    local function stop()
        if state=="collecting" then state="stopped";reason="manual_stop" end
        return true
    end
    return {contract=1,observe=observe,report=report,stop=stop}
end
-- Anonymous equality experiment only. Dependencies are the existing model/self
-- reference and reader; this factory creates no reader, listener or timer.
function M.newResourceEventComparison(alive,selfReference,observeMember)
    local fields={"payloadRejected","referenceUnavailable","invalidReference","numericIdIncomparable",
        "neither","both","tokenEqual","idEqual","topicLimit","readUnavailable","referenceChanged",
        "resourceUnknown","resourceFull","resourceUnstable","numbersCurrentMax","numbersMaxCurrent",
        "pairMismatch","interrupted"}
    local topics={"health","mana"}
    local function empty()
        local result={}
        for i=1,2 do
            local data={count=0,attempts=0,readerCalls=0};result[topics[i]]=data
            for j=1,#fields do data[fields[j]]=0 end
        end
        return result
    end
    local data=empty();local total,attempts,referenceCalls,readerCalls=0,0,0,0
    local state,reason,busy="collecting","collecting",false
    local function finish(nextState,nextReason,discard)
        state=nextState;reason=nextReason
        alive=nil;selfReference=nil;observeMember=nil
        if discard then data=empty();total=0;attempts=0;referenceCalls=0;readerCalls=0 end
    end
    if type(alive)~="function" then finish("unavailable","lifetime_unverified",true)
    elseif type(selfReference)~="function" or type(observeMember)~="function" then
        finish("unavailable","dependency_unverified",true)
    end
    local function current()
        if state~="collecting" then return false end
        local ok,value=pcall(alive)
        if state~="collecting" then return false end
        if not ok or value~=true then finish("cancelled","cancelled",true);return false end
        return true
    end
    local function canonical(token)
        if type(token)~="string" then return false end
        for i=1,50 do if token=="team"..i then return true end end
        return false
    end
    local function finite(value)
        return type(value)=="number" and value==value and value>-math.huge and value<math.huge
    end
    local function rowPair(row,token,id,topic)
        if type(row)~="table" then return nil,nil,"readUnavailable" end
        local ok,kind,value,max=pcall(function()
            if row.contract~=1 or row.state~="partial" or row.clear~=false then return "readUnavailable" end
            if row.token~=token or row.identity~=id or row.selfKnown~=true or row.isSelf~=true then
                return "referenceChanged"
            end
            local known,currentValue,maximum
            if topic=="health" then known=row.hpKnown;currentValue=row.hp;maximum=row.maxHp
            else known=row.manaKnown;currentValue=row.mana;maximum=row.maxMana end
            if known~=true or not finite(currentValue) or not finite(maximum)
                or currentValue<0 or maximum<=0 or currentValue>maximum or maximum>1000000000 then
                return "resourceUnknown"
            end
            return "pair",currentValue,maximum
        end)
        if not ok then return nil,nil,"readUnavailable" end
        if kind~="pair" then return nil,nil,kind end
        return value,max
    end
    local function observe(event,first,second,third)
        if busy then return false,"busy" end
        if state~="collecting" then return false,reason end
        local topic
        if event=="TEAM_HEALTH_CHANGED" then topic="health"
        elseif event=="TEAM_MANA_CHANGED" then topic="mana" else return false,"ignored" end
        busy=true
        local ok,accepted,why=pcall(function()
            if not current() then return false,reason end
            local counts=data[topic];total=total+1;counts.count=counts.count+1
            local function interrupted()
                if state=="stopped" then counts.interrupted=counts.interrupted+1 end
                return false,reason
            end
            local function done(field)
                if field then counts[field]=counts[field]+1 end
                if attempts==4 then finish("complete","attempt_cap",false)
                elseif total==64 then finish("complete","event_cap",false) end
                return true,reason
            end
            -- Caps are checked before any model or reader dependency call.
            if counts.attempts==2 then return done("topicLimit") end
            if type(first)~="string" or not finite(second) or not finite(third) then return done("payloadRejected") end
            referenceCalls=referenceCalls+1
            local refOK,reference=pcall(selfReference)
            if not current() then return interrupted() end
            if not refOK or reference==nil then return done("referenceUnavailable") end
            if type(reference)~="table" then return done("invalidReference") end
            local fieldsOK,token,id,selfKnown,isSelf=pcall(function()
                return reference.token,reference.identity,reference.selfKnown,reference.isSelf
            end)
            reference=nil
            if not current() then return interrupted() end
            if not fieldsOK or not canonical(token) or not identity(id) or selfKnown~=true or isSelf~=true then
                return done("invalidReference")
            end
            local tokenEqual,idEqual=first==token,false
            if type(id)=="string" then idEqual=first==id
            else
                counts.numericIdIncomparable=counts.numericIdIncomparable+1
                if not tokenEqual then return done() end
            end
            if tokenEqual and idEqual then return done("both") end
            if not tokenEqual and not idEqual then return done("neither") end
            counts[tokenEqual and "tokenEqual" or "idEqual"]=counts[tokenEqual and "tokenEqual" or "idEqual"]+1
            -- Reserve the entire read-pair attempt before invoking the reader.
            attempts=attempts+1;counts.attempts=counts.attempts+1
            readerCalls=readerCalls+1;counts.readerCalls=counts.readerCalls+1
            local beforeOK,before=pcall(observeMember,token,current)
            if not current() then return interrupted() end
            if not beforeOK then return done("readUnavailable") end
            local value,max,pairWhy=rowPair(before,token,id,topic);before=nil
            if not current() then return interrupted() end
            if pairWhy then return done(pairWhy) end
            if value==max then return done("resourceFull") end
            readerCalls=readerCalls+1;counts.readerCalls=counts.readerCalls+1
            local afterOK,after=pcall(observeMember,token,current)
            if not current() then return interrupted() end
            if not afterOK then return done("readUnavailable") end
            local afterValue,afterMax,afterWhy=rowPair(after,token,id,topic);after=nil
            if not current() then return interrupted() end
            if afterWhy then return done(afterWhy) end
            if value~=afterValue or max~=afterMax then return done("resourceUnstable") end
            if second==value and third==max then return done("numbersCurrentMax") end
            if second==max and third==value then return done("numbersMaxCurrent") end
            return done("pairMismatch")
        end)
        busy=false
        if not ok then finish("unavailable","comparison_failed",true);return false,reason end
        return accepted,why
    end
    local function report()
        if busy then return {contract=1,state="unavailable",reason="busy"} end
        if state=="collecting" then busy=true;current();busy=false end
        local result={contract=1,state=state,reason=reason,eventLimit=64,positionLimit=3,attemptLimit=4,
            topicAttemptLimit=2,eventsSeen=total,attempts=attempts,referenceCalls=referenceCalls,readerCalls=readerCalls,
            argumentCountKnown=false,payloadSchemaVerified=false,actorAttributed=false,
            freshnessKnown=false,resourceCoverageKnown=false,events=empty()}
        for i=1,2 do
            local name=topics[i];local source=data[name];local target=result.events[name]
            target.count=source.count;target.attempts=source.attempts;target.readerCalls=source.readerCalls
            for j=1,#fields do target[fields[j]]=source[fields[j]] end
        end
        return result
    end
    local function stop()
        if state=="collecting" then finish("stopped","manual_stop",false) end
        return true
    end
    return {contract=1,observe=observe,report=report,stop=stop}
end
return M
