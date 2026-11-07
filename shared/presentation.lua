-- Original shared feature code. These are local feature interfaces, NOT HQ APIs.
local F=require("Mazrim_Raid_Frames/shared/foundation")
local MemberLayout=require("Mazrim_Raid_Frames/shared/member_layout")
local P={version="0.2.72",MAX_ROWS=50,compactContract=1,nativeRaidContract=1,hudManagementContract=2,overhaulContract=1,bankLayoutContract=1}
local function finite(v)return type(v)=="number" and v==v and v>-1/0 and v<1/0 end
-- Clip by UTF-8 character boundaries; never split a multibyte display name.
function P.text(value,limit)
  if type(value)~="string" then return "Unknown" end
  local s=string.gsub(value,"[%c|]"," ")
  local i,n,last=1,0,0
  while i<=#s and n<limit do
    local c=string.byte(s,i);local size=1
    if c>=194 and c<=223 then size=2 elseif c>=224 and c<=239 then size=3 elseif c>=240 and c<=244 then size=4 end
    if i+size-1>#s then break end
    local valid=true
    for j=1,size-1 do local b=string.byte(s,i+j);if b<128 or b>191 then valid=false end end
    if not valid then size=1 end
    last=i+size-1;i=i+size;n=n+1
  end
  local out=string.sub(s,1,last)
  if i<=#s then out=out.."..." end
  if out=="" then return "Unknown" end
  return out
end
function P.health(resource,mode)
  if mode=="none" then return "" end
  if type(resource)~="table" or resource.known~=true then return "--" end
  if mode=="current" then return string.format("%.0f",resource.current) end
  if mode=="missing" then return "-"..string.format("%.0f",resource.missing) end
  return string.format("%.0f%%",resource.percent)
end
function P.preview(count)
  if count~=5 and count~=25 and count~=50 then count=25 end
  local rows={}
  for i=1,count do
    local hp=(i*17+23)%101
    rows[i]={name=string.format("Member %02d",i),kind="preview",selected=i==2,
      health=F.resource(hp,100),mana=F.resource((i*11)%101,100),state="PREVIEW",
      roleKnown=true,role=({"none","tank","healer","damage"})[(i-1)%4+1],
      rangeKnown=true,outOfRange=i%4==0,selfKnown=true,isSelf=i==5,
      authorityKnown=i==1,authority=i==1 and "leader" or nil}
  end
  -- Deliberately demonstrate unknown versus a true zero value.
  rows[1].health=F.resource(100,100)
  if count>=4 then rows[4].health=F.resource(nil,nil);rows[4].state="EXAMPLE_UNKNOWN" end
  if count>=5 then rows[5].health=F.resource(0,100);rows[5].state="EXAMPLE_ZERO" end
  return {source="preview",rows=rows,coverage="SYNTHETIC_NOT_A_RAID"}
end
-- Screen-fit pagination, never dropping a row silently or shrinking text unreadably.
-- The selected party/raid layout is a display preference, not a native group claim.
function P.layout(count,mode,settings,screen_w,screen_h,page,compact)
  if not finite(count) or count%1~=0 or count<0 or count>P.MAX_ROWS then return nil,"ROW_LIMIT" end
  if mode~="party" and mode~="raid" then return nil,"LAYOUT_MODE" end
  if not finite(screen_w) or not finite(screen_h) or screen_w<680 or screen_h<400 then return nil,"SCREEN_TOO_SMALL" end
  local clean=F.settings(settings);if not clean then return nil,"SETTINGS_INVALID" end
  local c=clean[mode]
  compact=compact==true
  local header=compact and 48 or 196
  local footer=compact and 76 or 64
  local available_w=screen_w-56;local available_h=screen_h-header-footer-24
  local fit_cols=math.max(1,math.floor((available_w+c.gap_x)/(c.width+c.gap_x)))
  c.columns=math.min(c.columns,fit_cols)
  local fit_rows=math.max(1,math.floor((available_h+c.gap_y)/(c.height+c.gap_y)))
  local capacity=c.columns*fit_rows
  local pages=math.max(1,math.ceil(count/capacity))
  page=finite(page) and math.floor(page) or 1;page=math.max(1,math.min(page,pages))
  local first=(page-1)*capacity+1
  local visible=math.max(0,math.min(capacity,count-first+1))
  local g=F.plan_grid(visible,mode,clean)
  if not g then return nil,"GRID_INVALID" end
  local width=math.max(compact and 400 or 644,g.width+32)
  local height=header+g.height+footer
  for i=1,#g.cells do
    local cell=g.cells[i];cell.x=16+cell.x-g.min_x;cell.y=header+cell.y-g.min_y
    cell.row_index=first+i-1
  end
  return {grid=g,width=width,height=height,page=page,pages=pages,first=first,
    last=visible==0 and 0 or first+visible-1,capacity=capacity,columns=c.columns,
    toolbar_y=height-46,settings=clean,compact=compact,header=header}
end
-- Five parties per bank: slots1..25 above26..50. A missing slot never
-- compacts a later occupant. Width overflow pages whole party columns;
-- only an authored five-row party taller than the screen uses row slices.
function P.nativeLayout(data,mode,settings,screen_w,screen_h,page)
  if not finite(screen_w) or not finite(screen_h) or screen_w<680 or screen_h<400 then return nil,"SCREEN_TOO_SMALL" end
  if type(data)~="table" or type(data.rows)~="table" or #data.rows>50 then return nil,"ROW_LIMIT" end
  local clean=F.settings(settings);if not clean then return nil,"SETTINGS_INVALID" end
  local c=clean[mode];if not c then return nil,"LAYOUT_MODE" end
  local slots,maxslot,seen={},0,{}
  for i=1,#data.rows do
    local slot=data.source=="raid" and data.rows[i].slot or i
    if not finite(slot) or slot%1~=0 or slot<1 or slot>50 or seen[slot] then return nil,"SLOT_INVALID" end
    seen[slot]=true;slots[i]=slot;maxslot=math.max(maxslot,slot)
  end
  local groups=math.ceil(maxslot/5);local banks=math.ceil(groups/5)
  local fit=math.max(1,math.min(5,math.floor((screen_w-100+c.gap_x)/(c.width+c.gap_x))))
  local rowFit=math.max(1,math.min(5,math.floor((screen_h-24-19+c.gap_y)/(c.height+c.gap_y))))
  local bankHeight=19+5*c.height+4*c.gap_y;local bankGap=12
  local maxBankRow={0,0}
  for i=1,#slots do local bank=math.floor((slots[i]-1)/25)+1;maxBankRow[bank]=math.max(maxBankRow[bank],(slots[i]-1)%5+1)end
  local secondHeight=19+maxBankRow[2]*c.height+math.max(0,maxBankRow[2]-1)*c.gap_y
  local together=banks==2 and rowFit==5 and bankHeight+bankGap+secondHeight<=screen_h-24
  local sections={}
  local function populated(bs,be,colStart,rowStart,rowCount)
    for i=1,#slots do
      local bank=math.floor((slots[i]-1)/25)+1;local col=math.floor(((slots[i]-1)%25)/5);local row=(slots[i]-1)%5
      if bank>=bs and bank<=be and col>=colStart and col<colStart+fit and row>=rowStart and row<rowStart+rowCount then return true end
    end
    return false
  end
  local function add(bs,be,colStart,rowStart,rowCount)
    if populated(bs,be,colStart,rowStart,rowCount)then sections[#sections+1]={bs=bs,be=be,col=colStart,row=rowStart,count=rowCount}end
  end
  if together then
    for col=0,4,fit do add(1,2,col,0,5)end
  else
    for bank=1,banks do
      local bankCols=math.min(5,groups-(bank-1)*5)
      for col=0,bankCols-1,fit do
        for row=0,4,rowFit do add(bank,bank,col,row,math.min(rowFit,5-row))end
      end
    end
  end
  if #sections==0 then sections[1]={bs=1,be=1,col=0,row=0,count=5}end
  local pages=#sections
  page=finite(page) and math.floor(page) or 1;page=math.max(1,math.min(page,pages))
  local section=sections[page];local grid={cells={},columns=0,rows=0,width=0,height=0}
  local labels={};local first,last=0,0
  for bank=section.bs,section.be do
    local cols=math.max(0,math.min(fit,groups-(bank-1)*5-section.col,5-section.col))
    local by=together and(bank-1)*(bankHeight+bankGap)or 0
    grid.columns=math.max(grid.columns,cols)
    grid.width=math.max(grid.width,cols>0 and cols*c.width+(cols-1)*c.gap_x or 0)
    for j=1,cols do labels[#labels+1]={text=(bank-1)*5+section.col+j,x=(j-1)*(c.width+c.gap_x)+c.width-34,y=by}end
    for i=1,#slots do
      local memberBank=math.floor((slots[i]-1)/25)+1
      local col=math.floor(((slots[i]-1)%25)/5);local row=(slots[i]-1)%5
      if memberBank==bank and col>=section.col and col<section.col+fit and row>=section.row and row<section.row+section.count then
        local x=(col-section.col)*(c.width+c.gap_x);local y=by+19+(row-section.row)*(c.height+c.gap_y)
        grid.cells[#grid.cells+1]={x=x,y=y,width=c.width,height=c.height,row_index=i,group=(bank-1)*5+col+1,slot=slots[i]}
        grid.rows=math.max(grid.rows,(together and(bank-1)*5 or 0)+row-section.row+1)
        grid.height=math.max(grid.height,y+c.height-19)
        first=first==0 and i or math.min(first,i);last=math.max(last,i)
      end
    end
  end
  return {grid=grid,width=math.max(112,grid.width+52),height=math.max(41,grid.height+19),
    page=page,pages=pages,first=first,last=last,columns=grid.columns,capacity=fit*section.count*(section.be-section.bs+1),
    groups=labels,settings=clean,compact=true,header=19,native=true,
    bank_first=section.bs,bank_last=section.be,row_first=section.row+1,row_last=section.row+section.count}
end
-- Custom assignments retain original row indexes. Source membership slots and
-- identities remain data-reader facts; only display placement changes.
function P.memberLayout(data,mode,settings,screen_w,screen_h,page,options)
  local checked=MemberLayout.validate(options)
  if not checked or type(data)~="table"then return nil,"MEMBER_LAYOUT_INVALID"end
  if data.source~="raid"then return P.nativeLayout(data,mode,settings,screen_w,screen_h,page)end
  if not checked.enabled then
    local priority=false;for _,a in pairs(checked.assignments)do if a.group=="priority"then priority=true;break end end
    if not priority then return P.nativeLayout(data,mode,settings,screen_w,screen_h,page)end
  end
  if not finite(screen_w)or not finite(screen_h)or screen_w<680 or screen_h<400 then return nil,"SCREEN_TOO_SMALL"end
  if type(data.rows)~="table"or #data.rows>50 then return nil,"ROW_LIMIT"end
  local seen={};for _,r in ipairs(data.rows)do
    if type(r)~="table"or not finite(r.slot)or r.slot%1~=0 or r.slot<1 or r.slot>50 or seen[r.slot]then return nil,"SLOT_INVALID"end
    seen[r.slot]=true
  end
  local projection=MemberLayout.project(data.rows,checked);if not projection then return nil,"MEMBER_LAYOUT_INVALID"end
  if projection.applied==0 and not checked.manual_slots then return P.nativeLayout(data,mode,settings,screen_w,screen_h,page)end
  local clean=F.settings(settings);if not clean or not clean[mode]then return nil,"SETTINGS_INVALID"end
  local c=clean[mode];local counts,maxGroup,maxRows={},0,0
  for _,p in ipairs(projection.main)do counts[p.group]=(counts[p.group]or 0)+1;maxGroup=math.max(maxGroup,p.group);maxRows=math.max(maxRows,counts[p.group])end
  local result
  if maxRows<=5 then
    local synthetic={source="raid",rows={}};local at={}
    for n,p in ipairs(projection.main)do at[p.group]=(at[p.group]or 0)+1;synthetic.rows[n]={slot=(p.group-1)*5+(projection.fixed_slots and p.order or at[p.group])}end
    result=P.nativeLayout(synthetic,mode,clean,screen_w,screen_h,page)
    if not result then return nil,"LAYOUT_INVALID"end
    for _,cell in ipairs(result.grid.cells)do local p=projection.main[cell.row_index];cell.row_index=p.row_index;cell.slot=p.slot end
  else
    local fit=math.max(1,math.min(5,math.floor((screen_w-100+c.gap_x)/(c.width+c.gap_x))))
    local rowFit=math.max(1,math.floor((screen_h-43+c.gap_y)/(c.height+c.gap_y)))
    local sections={}
    for bank=0,math.max(0,math.ceil(maxGroup/5)-1)do
      for start=0,4,fit do
        local rows=0
        for col=start,math.min(4,start+fit-1)do rows=math.max(rows,counts[bank*5+col+1]or 0)end
        for first=1,rows,rowFit do sections[#sections+1]={bank=bank,col=start,first=first,last=first+rowFit-1}end
      end
    end
    if #sections==0 then sections[1]={bank=0,col=0,first=1,last=rowFit}end
    local selected=finite(page)and math.floor(page)or 1;selected=math.max(1,math.min(selected,#sections))
    local section=sections[selected];local grid={cells={},columns=0,rows=0,width=0,height=0};local labels={};local at={};local first,last=0,0
    for col=section.col,math.min(4,section.col+fit-1)do
      local group=section.bank*5+col+1
      if (counts[group]or 0)>=section.first then
        local x=(col-section.col)*(c.width+c.gap_x);grid.width=math.max(grid.width,x+c.width);grid.columns=col-section.col+1
        labels[#labels+1]={text=group,x=x+c.width-34,y=0}
      end
    end
    for _,p in ipairs(projection.main)do
      at[p.group]=(at[p.group]or 0)+1;local row=at[p.group]
      local col=(p.group-1)%5;local bank=math.floor((p.group-1)/5)
      if bank==section.bank and col>=section.col and col<section.col+fit and row>=section.first and row<=section.last then
        local x=(col-section.col)*(c.width+c.gap_x);local y=19+(row-section.first)*(c.height+c.gap_y)
        grid.cells[#grid.cells+1]={x=x,y=y,width=c.width,height=c.height,row_index=p.row_index,slot=p.slot,group=p.group}
        grid.rows=math.max(grid.rows,row-section.first+1);grid.height=math.max(grid.height,y+c.height-19)
        first=first==0 and p.row_index or math.min(first,p.row_index);last=math.max(last,p.row_index)
      end
    end
    result={grid=grid,width=math.max(112,grid.width+52),height=math.max(41,grid.height+19),page=selected,pages=#sections,
      first=first,last=last,columns=grid.columns,capacity=fit*rowFit,groups=labels,settings=clean,compact=true,header=19,native=true}
  end
  result.custom_members=true;result.priority_rows=projection.priority
  return result
end
function P.priorityLayout(placements,mode,settings,screen_w,screen_h,page,showDrop)
  if type(placements)~="table"or(#placements==0 and not showDrop)then return nil end
  local clean=F.settings(settings);local c=clean and clean[mode]
  if not c or not finite(screen_w)or not finite(screen_h)or screen_w<680 or screen_h<400 then return nil end
  local rowFit=math.max(1,math.floor((screen_h-24+c.gap_y)/(c.height+c.gap_y)))
  local total=math.min(50,#placements+(showDrop and 1 or 0))
  local fit=math.max(1,math.floor((screen_w-24+c.gap_x)/(c.width+c.gap_x)))
  local cols=math.max(1,math.min(5,fit,math.ceil(total/rowFit)))
  local capacity=cols*rowFit;local pages=math.max(1,math.ceil(total/capacity))
  page=finite(page)and math.floor(page)or 1;page=math.max(1,math.min(page,pages))
  local first=(page-1)*capacity+1;local count=math.min(capacity,#placements-first+1)
  local grid={cells={},columns=math.min(cols,count),rows=math.min(rowFit,count),width=0,height=0}
  for i=1,count do
    local p=placements[first+i-1];local col=math.floor((i-1)/rowFit);local row=(i-1)%rowFit
    local x=col*(c.width+c.gap_x);local y=row*(c.height+c.gap_y)
    grid.cells[#grid.cells+1]={x=x,y=y,width=c.width,height=c.height,row_index=p.row_index,slot=p.slot,panel="priority"}
    grid.width=math.max(grid.width,x+c.width);grid.height=math.max(grid.height,y+c.height)
  end
  local drop
  if showDrop and #placements<50 and #placements+1>=first and #placements+1<first+capacity then
    local i=#placements+1-first;local col=math.floor(i/rowFit);local row=i%rowFit
    drop={x=col*(c.width+c.gap_x),y=row*(c.height+c.gap_y),width=c.width,height=c.height,order=#placements+1}
    grid.width=math.max(grid.width,drop.x+drop.width);grid.height=math.max(grid.height,drop.y+drop.height)
  end
  return{grid=grid,cells=grid.cells,drop=drop,width=math.max(1,grid.width),height=math.max(1,grid.height),page=page,pages=pages,first=first,last=first+count-1,header=0,empty=#placements==0}
end
return P
