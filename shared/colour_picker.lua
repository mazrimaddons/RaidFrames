-- Pure HSV/RGB and pointer geometry. No UI, native calls, settings or IO.
local C={contract=1}
local function finite(v)return type(v)=="number"and v==v and v>-1/0 and v<1/0 end
local function unit(v)return finite(v)and v>=0 and v<=1 end
local function hue(v)return v==1 and 0 or v end
function C.fromHex(value)
 if type(value)~="string"or #value~=6 or value:find("[^0-9A-F]")then return nil end
 local function channel(at)
  local n=0
  for i=at,at+1 do local b=string.byte(value,i);n=n*16+(b<=57 and b-48 or b-55)end
  return n/255
 end
 local r,g,b=channel(1),channel(3),channel(5)
 local maximum,minimum=math.max(r,g,b),math.min(r,g,b)
 local delta=maximum-minimum;local h=0
 if delta>0 then
  if maximum==r then h=((g-b)/delta)%6/6
  elseif maximum==g then h=((b-r)/delta+2)/6
  else h=((r-g)/delta+4)/6 end
 end
 return h,maximum==0 and 0 or delta/maximum,maximum
end
function C.hex(h,s,v)
 if not unit(h)or not unit(s)or not unit(v)then return nil end
 h=hue(h)*6
 local sector=math.floor(h);local fraction=h-sector
 local p,q,t=v*(1-s),v*(1-s*fraction),v*(1-s*(1-fraction))
 local r,g,b
 if sector==0 then r,g,b=v,t,p
 elseif sector==1 then r,g,b=q,v,p
 elseif sector==2 then r,g,b=p,v,t
 elseif sector==3 then r,g,b=p,q,v
 elseif sector==4 then r,g,b=t,p,v
 else r,g,b=v,p,q end
 return string.format("%02X%02X%02X",math.floor(r*255+0.5),math.floor(g*255+0.5),math.floor(b*255+0.5))
end
-- atan2(y,x), using only the standard Lua5.1 one-argument atan.
local function angle(y,x)
 if x>0 then return math.atan(y/x)end
 if x<0 then return math.atan(y/x)+(y>=0 and math.pi or-math.pi)end
 if y>0 then return math.pi/2 end
 if y<0 then return-math.pi/2 end
 return 0
end
function C.wheel(x,y,cx,cy,r)
 if not finite(x)or not finite(y)or not finite(cx)or not finite(cy)or not finite(r)or r<=0 then return nil end
 local dx,dy=(x-cx)/r,(y-cy)/r
 if not finite(dx)or not finite(dy)or math.abs(dx)>1 or math.abs(dy)>1 then return nil end
 local s=math.sqrt(dx*dx+dy*dy)
 if s>1 then return nil end
 if s==0 then return 0,0 end
 return(angle(dx,-dy)/(2*math.pi))%1,s
end
function C.value(y,top,height)
 if not finite(y)or not finite(top)or not finite(height)or height<=0 then return nil end
 if y<=top then return 1 end
 local offset=(y-top)/height
 if offset>=1 then return 0 end
 return 1-offset
end
function C.marker(h,s,cx,cy,r)
 if not unit(h)or not unit(s)or not finite(cx)or not finite(cy)or not finite(r)or r<=0 then return nil end
 if s==0 then return cx,cy end
 local a=hue(h)*2*math.pi
 local x,y=cx+math.sin(a)*r*s,cy-math.cos(a)*r*s
 if not finite(x)or not finite(y)then return nil end
 return x,y
end
return C
