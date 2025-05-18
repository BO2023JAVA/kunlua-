--构建加解密方法类
local _M={}
--定义RC4加解密函数库
----------------------------
--定义交换两个元素的函数
function swap(list, i, j)
  list[i], list[j] = list[j], list[i]
end
--初始化密钥流
function ksa(key)
  local key_length = #key
  local S = {}
  --初始置换过程
  for i = 0, 255 do
    S[i] = i
  end
  local j = 0
  --密钥与初始置换的混合
  for i = 0, 255 do
    j = (j + S[i] + key:byte((i % key_length) + 1)) % 256
    swap(S, i, j)
  end
  return S
end

--伪随机生成算法 (PRGA - Pseudo-Random Generation Algorithm)
function prga(S, text)
  local i, j, K = 0, 0, {}
  --根据密钥流生成密文或明文
  for l = 1, #text do
    i = (i + 1) % 256
    j = (j + S[i]) % 256
    swap(S, i, j)
    K[l] = string.char(bit32.bxor(text:byte(l), S[(S[i] + S[j]) % 256]))
  end
  return table.concat(K)
end

--RC4 加密解密函数
--由于RC4是一个可逆加密算法
--因此可以使用相同的函数进行加密和解密操作
function mRC4(key, text)
  local S = ksa(key)
  return prga(S, text)
end

--将字符串转换为十六进制
function toHex(string)
  return (string:gsub(".", function(c)
    return string.format("%02X", c:byte())
  end))
end

--将十六进制转换为字符串
function fromHex(hex)
  return (hex:gsub("..", function(cc)
    return string.char(tonumber(cc, 16))
  end))
end

--使用 RC4 加密函数
function _M.encrypt(key, text)
  local encrypted = mRC4(key, text)
  return toHex(encrypted):upper()
end

--使用 RC4 解密函数
function _M.decrypt(key, encrypted_text)
  local text = fromHex(encrypted_text)
  return mRC4(key, text)
end

return _M