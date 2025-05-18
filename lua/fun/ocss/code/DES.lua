local _M={}

local String = luajava.bindClass "java.lang.String"
local SecretKeySpec = luajava.bindClass "javax.crypto.spec.SecretKeySpec"
local Cipher = luajava.bindClass "javax.crypto.Cipher"
local Base64 = luajava.bindClass "android.util.Base64"

--加密函数
function _M.encrypt(Str, key)
  local raw = String(key).getBytes();
  local skey = SecretKeySpec(raw, "DES");
  local cipher = Cipher.getInstance("DES/ECB/PKCS5Padding");
  cipher.init(Cipher.ENCRYPT_MODE, skey);
  local byte_content = String(Str).getBytes("utf-8");
  local encode_content = cipher.doFinal(byte_content);
  return Base64.encodeToString(encode_content,Base64.DEFAULT);
end

--解密函数
function _M.decrypt(key,Str)
  local raw = String(key).getBytes();
  local skey = SecretKeySpec(raw, "DES");
  local cipher = Cipher.getInstance("DES/ECB/PKCS5Padding");
  cipher.init(Cipher.DECRYPT_MODE, skey);
  local encode_content = Base64.decode(Str,Base64.DEFAULT);
  local byte_content = cipher.doFinal(encode_content);
  return tostring(String(byte_content,"utf-8"))
end


return _M