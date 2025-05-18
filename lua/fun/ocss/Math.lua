local _M = {}

_M.round = function(num)
  return math.floor((tonumber(num) * ((10 ^ 0) * 10) + 5) / 10) / (10 ^ 0)
end

--四舍五入(奇进偶舍)
_M.round2 = function(num, i)
  local tmp = math.abs(num)*(10^(i+1))
  local cal = math.abs(num)*(10^(i+1))/(10^(i+1))
  local result = 0
  if(math.floor(tmp)-math.floor(tmp/10)*10==5) then
    if(tmp-math.floor(tmp)==0) then
      local numInt1,numInt2 = math.modf(math.floor(tmp/10))
      if(numInt1 % 2 == 0) then
        result = math.floor(tmp/10)/(10^i)
      end
    end
  end
  if(result==0) then
    result = math.floor((cal * ((10^(i or 0)) * 10) + 5)/10)/ (10^(i or 0))
  end
  return (num>0 and result) or (0-result)
end

_M.tointstr = function(num, str)
  return tostring(tointeger(num) or (str or "--"))
end

--相乘
_M.multi= function(num1,num2)
  if(num1==nil) then
    return 0
  end
  if(num2==nil) then
    return 0
  end
  return (tonumber(num1) * tonumber(num2))
end

--相除
_M.divi= function(denominator,numerator)
  if(numerator==nil) then
    return 0
  end
  if(denominator==nil) then
    return 0
  end
  if(numerator==0) then
    return 0
  end
  return tonumber(denominator)/tonumber(numerator)
end

--取整
_M.ceil= function(num)
  if(num==nil) then
    return 0
  end

  if (num <= 0) then
    return math.ceil(tonumber(num))
  end

  if (math.ceil(tonumber(num)) == tonumber(num)) then
    return math.ceil(tonumber(num))
   else
    return math.ceil(tonumber(num)) - 1
  end
end

--取整
_M.ceil2= function(num)
  if(num==nil) then
    return 0
  end

  local t1,t2 = math.modf(tonumber(num))
  return t1
end

return _M