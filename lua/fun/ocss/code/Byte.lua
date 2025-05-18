local _M={}

function _M.encode(data)
  local byteArray = {}
  for i = 1, #data do
    local byteValue = string.byte(data, i)
    table.insert(byteArray, byteValue)
  end
  return table.concat(byteArray, ",")
end

function _M.decode(data)
  local bytes = {}
  for byte in string.gmatch(data, "%d+") do
    table.insert(bytes, string.char(tonumber(byte)))
  end
  return table.concat(bytes)
end

return _M