local _M={}
local Cipher = luajava.bindClass "javax.crypto.Cipher"
local SecretKeySpec = luajava.bindClass "javax.crypto.spec.SecretKeySpec"
local Base64 = luajava.bindClass "android.util.Base64"
local MessageDigest = luajava.bindClass "java.security.MessageDigest"
local String = luajava.bindClass "java.lang.String"
function generateKey(key)
  local md = MessageDigest.getInstance("SHA-256")
  local keyBytes = md.digest(String(key).getBytes("UTF-8"))
  if #keyBytes == 32 then
    return keyBytes
   elseif #keyBytes >= 24 then
    return keyBytes:sub(1,24)
   else
    return keyBytes:sub(1,16)
  end
end

function _M.encrypt(key, data)
  local cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
  local keySpec = SecretKeySpec(generateKey(key), "AES")
  cipher.init(Cipher.ENCRYPT_MODE, keySpec)
  local encryptedBytes = cipher.doFinal(String(data).getBytes("UTF-8"))
  return tostring(Base64.encodeToString(encryptedBytes, Base64.DEFAULT))
end

function _M.decrypt(key, data)
  local cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
  local keySpec = SecretKeySpec(generateKey(key), "AES")
  cipher.init(Cipher.DECRYPT_MODE, keySpec)
  local encryptedBytes = Base64.decode(data, Base64.DEFAULT)
  local decryptedBytes = cipher.doFinal(encryptedBytes)
  return tostring(String(decryptedBytes, "UTF-8"))
end

return _M