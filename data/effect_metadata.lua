-- Original fixed-field metadata adapter. No schema or native art success assumed.
-- Read only relevant fields: unrelated tooltip fields cannot discard valid art.
local Meta={version="0.0.24"}
local keys={"icon","iconPath","icon_path","path"}
function Meta.label(v)
    if type(v)=="string"and #v>0 and #v<=48 and not v:find("[%z\1-\31\127|]")then return v end
end
function Meta.path(v)
    if type(v)~="string"or #v==0 or #v>192 then return end
    -- Preserve the native resource spelling; normalize only for validation.
    local check=v:gsub("\\","/")
    if check:sub(1,1)=="/"or check:find("..",1,true)or check:find("//",1,true)or
        check:sub(-1)=="/"or not check:match("^[%w_./-]+$")then return end
    local low=check:lower()
    if low:sub(-4)==".dds"or low:sub(-4)==".tga"then return v end
    -- Generic native setters accept opaque paths. A supplied extensionless
    -- relative resource is tried verbatim; no suffix/resource is invented.
    local tail=check:match("([^/]+)$")
    if check:find("/",1,true)and tail and not tail:find(".",1,true)then return v end
end
local function candidate(value)
    if type(value)~="table"then return Meta.path(value)end
    local selected
    for i=1,#keys do
        local p=Meta.path(value[keys[i]])
        if p then if selected and selected~=p then return nil,"ambiguous"end;selected=p end
    end
    return selected
end
function Meta.read(raw)
    if type(raw)~="table"then return {reason="metadata_unavailable"}end
    local ok,result=pcall(function()
        local info={label=Meta.label(raw.name)}
        local selected,issue,supplied=nil,nil,false
        for i=1,#keys do
            local value=raw[keys[i]]
            if value~=nil then supplied=true end
            local p,why=candidate(value)
            if why then issue=why end
            if p then if selected and selected~=p then issue="ambiguous"end;selected=p end
        end
        info.icon=not issue and selected or nil
        info.reason=info.icon and "path_supplied"or issue=="ambiguous"and "ambiguous_path"or supplied and "path_rejected"or "path_unavailable"
        return info
    end)
    if ok then return result end
    return {reason="metadata_unavailable"}
end
return Meta
