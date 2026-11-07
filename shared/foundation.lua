-- Original Mazrim's Tools source. Offline foundation, NOT an AAC entry point.
-- No game/UI calls, loader, polling, saved-file IO, targeting or aura reads.
-- Both future hosts are intended to use these exact bytes after HQ review.
local M = { version = "0.1.0-foundation", schema = 1, overhaulContract = 1 }
local MAX_CELLS = 100 -- bounded model input, NOT a claim about AAC raid capacity

local function finite(v)
    return type(v) == "number" and v == v and v > -1/0 and v < 1/0
end
local function integer(v, lo, hi)
    return finite(v) and v >= lo and v <= hi and v % 1 == 0
end
local function warn(warnings, path)
    warnings[#warnings + 1] = path
end
local function number(v, fallback, lo, hi, warnings, path)
    if v == nil then return fallback end
    if integer(v, lo, hi) then return v end
    warn(warnings, path .. ": invalid integer; default used")
    return fallback
end
local function bool(v, fallback, warnings, path)
    if v == nil then return fallback end
    if type(v) == "boolean" then return v end
    warn(warnings, path .. ": invalid boolean; default used")
    return fallback
end
local function enum(v, fallback, allowed, warnings, path)
    if v == nil then return fallback end
    if type(v) == "string" and allowed[v] then return v end
    warn(warnings, path .. ": invalid choice; default used")
    return fallback
end
local function keys(t, allowed, warnings, path)
    -- Unknown keys are not echoed; imported keys could contain private text.
    for k in pairs(t) do
        if not allowed[k] then warn(warnings, path .. ": unknown field ignored") end
    end
end
local function section(value, warnings, path)
    if value == nil then return {} end
    if type(value) == "table" then return value end
    warn(warnings, path .. ": invalid section; defaults used")
    return {}
end
local function layout_settings(raw, party, warnings, path)
    local t = section(raw, warnings, path)
    keys(t, {width=true,height=true,columns=true,gap_x=true,gap_y=true,
             grow_x=true,grow_y=true}, warnings, path)
    return {
        width = number(t.width, party and 200 or 104, 40, 480, warnings, path..".width"),
        height = number(t.height, party and 44 or 36, 20, 100, warnings, path..".height"),
        columns = number(t.columns, party and 1 or 5, 1, 20, warnings, path..".columns"),
        gap_x = number(t.gap_x, 3, 0, 24, warnings, path..".gap_x"),
        gap_y = number(t.gap_y, 3, 0, 24, warnings, path..".gap_y"),
        grow_x = enum(t.grow_x,"right",{left=true,right=true},warnings,path..".grow_x"),
        grow_y = enum(t.grow_y,"down",{up=true,down=true},warnings,path..".grow_y")
    }
end

-- Returns a new normalized settings table plus warning strings, or nil/error.
-- Unknown schemas must not be saved over. No input tables are mutated/retained.
-- Callers must apply their own file-size/depth limits before parsing imports.
function M.settings(input)
    if input == nil then input = {} end
    if type(input) ~= "table" then return nil, "SETTINGS_NOT_TABLE" end
    if input.schema ~= nil and input.schema ~= M.schema then
        return nil, "UNSUPPORTED_SCHEMA"
    end
    local warnings = {}
    keys(input,{schema=true,party=true,raid=true,display=true,experimental=true},warnings,"settings")
    local d = section(input.display,warnings,"display")
    keys(d,{show_names=true,show_mana=true,health_text=true,font_size=true},warnings,"display")
    local e = section(input.experimental,warnings,"experimental")
    keys(e,{remember_auras=true,hover_raid=true,hover_overhead=true},warnings,"experimental")
    return {
        schema = M.schema,
        party = layout_settings(input.party,true,warnings,"party"),
        raid = layout_settings(input.raid,false,warnings,"raid"),
        display = {
            show_names=bool(d.show_names,true,warnings,"display.show_names"),
            show_mana=bool(d.show_mana,true,warnings,"display.show_mana"),
            health_text=enum(d.health_text,"percent",{percent=true,current=true,missing=true,none=true},warnings,"display.health_text"),
            font_size=number(d.font_size,12,10,24,warnings,"display.font_size")
        },
        -- Preferences only. This module contains NO implementation of these.
        -- Native adapters must separately gate capability and runtime consent.
        experimental = {
            remember_auras=bool(e.remember_auras,false,warnings,"experimental.remember_auras"),
            hover_raid=bool(e.hover_raid,false,warnings,"experimental.hover_raid"),
            hover_overhead=bool(e.hover_overhead,false,warnings,"experimental.hover_overhead")
        }
    }, warnings
end

-- Pure geometry in logical units. Caller supplies count; no roster discovery.
-- Stable row-major order. Index is a DISPLAY index, never a target token/ID.
-- Anchor (0,0) is the outside top/left or bottom/right edge for each direction.
-- Negative coordinates intentionally extend left/up from that anchor.
function M.plan_grid(count, mode, input)
    if not integer(count,0,MAX_CELLS) then return nil,"INVALID_CELL_COUNT" end
    if mode ~= "party" and mode ~= "raid" then return nil,"INVALID_MODE" end
    local settings, warnings = M.settings(input)
    if not settings then return nil,warnings end
    local s = settings[mode]
    local columns = count < s.columns and count or s.columns
    local rows = count == 0 and 0 or ((count - 1) - ((count - 1) % s.columns)) / s.columns + 1
    local width = columns == 0 and 0 or columns*s.width+(columns-1)*s.gap_x
    local height = rows == 0 and 0 or rows*s.height+(rows-1)*s.gap_y
    local out = {cells={},count=count,columns=columns,rows=rows,width=width,height=height,
                 mode=mode,min_x=0,min_y=0,max_x=width,max_y=height,warnings=warnings}
    if s.grow_x == "left" then out.min_x=-width;out.max_x=0 end
    if s.grow_y == "up" then out.min_y=-height;out.max_y=0 end
    for i=1,count do
        local col=(i-1)%s.columns
        local row=((i-1)-col)/s.columns
        local x=col*(s.width+s.gap_x)
        local y=row*(s.height+s.gap_y)
        if s.grow_x == "left" then x=-x-s.width end
        if s.grow_y == "up" then y=-y-s.height end
        out.cells[i]={index=i,x=x,y=y,width=s.width,height=s.height}
    end
    return out
end

-- Only arithmetic on a caller-validated, identity-coherent sample. This does
-- not validate a native getter, identity, freshness, range, or offline status.
-- Unknown is never represented by a zero-filled resource bar.
function M.resource(current, maximum)
    if not finite(current) or not finite(maximum) then
        return {known=false,reason="UNAVAILABLE"}
    end
    if maximum <= 0 or current < 0 or current > maximum then
        return {known=false,reason="INVALID_READING"}
    end
    local fraction=current/maximum
    return {known=true,current=current,maximum=maximum,fraction=fraction,
            percent=fraction*100,missing=maximum-current}
end
return M
