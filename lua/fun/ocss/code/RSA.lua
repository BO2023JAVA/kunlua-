local _M={}

function doLongerCipherFinal(opMode, cipher, source)
  local ByteArrayOutputStream = luajava.bindClass "java.io.ByteArrayOutputStream"
  local Cipher = luajava.bindClass "javax.crypto.Cipher"

  local out = ByteArrayOutputStream()
  if (opMode == Cipher.DECRYPT_MODE) then
    out.write(cipher.doFinal(source))
   else
    local offset = 0
    local totalSize = #source
    while (totalSize - offset > 0) do
      local size = math.min(cipher.getOutputSize(0) - 11, totalSize - offset)
      out.write(cipher.doFinal(source, offset, size))
      offset = offset + size
    end
  end
  out.close()
  return out.toByteArray()
end

--获取公钥和私钥
--publicKeyString, privateKeyString
function _M.generateKeyPair()
  local KeyPairGenerator = luajava.bindClass "java.security.KeyPairGenerator"
  local Base64 = luajava.bindClass "android.util.Base64"

  local keyPairGenerator = KeyPairGenerator.getInstance("RSA")
  keyPairGenerator.initialize(1024)
  local keyPair = keyPairGenerator.generateKeyPair()
  local rsaPublicKey = keyPair.getPublic()
  local rsaPrivateKey = keyPair.getPrivate()
  local publicKeyString = Base64.encodeToString(rsaPublicKey.getEncoded(),Base64.DEFAULT)
  local privateKeyString = Base64.encodeToString(rsaPrivateKey.getEncoded(),Base64.DEFAULT)
  return publicKeyString, privateKeyString
end

--使用公钥加密
function _M.encryptByPublicKey(publicKeyText, text)
  local X509EncodedKeySpec = luajava.bindClass "java.security.spec.X509EncodedKeySpec"
  local Base64 = luajava.bindClass "android.util.Base64"
  local KeyFactory = luajava.bindClass "java.security.KeyFactory"
  local Cipher = luajava.bindClass "javax.crypto.Cipher"
  local String = luajava.bindClass "java.lang.String"

  local x509EncodedKeySpec = X509EncodedKeySpec(Base64.decode(publicKeyText,Base64.DEFAULT))
  local keyFactory = KeyFactory.getInstance("RSA")
  local publicKey = keyFactory.generatePublic(x509EncodedKeySpec)
  local cipher = Cipher.getInstance("RSA")
  cipher.init(Cipher.ENCRYPT_MODE, publicKey)
  local result = doLongerCipherFinal(Cipher.ENCRYPT_MODE, cipher, String(text).getBytes())
  return Base64.encodeToString(result,Base64.DEFAULT)
end
--使用公钥解密
function _M.decryptByPublicKey(publicKeyText, text)
  local X509EncodedKeySpec = luajava.bindClass "java.security.spec.X509EncodedKeySpec"
  local Base64 = luajava.bindClass "android.util.Base64"
  local KeyFactory = luajava.bindClass "java.security.KeyFactory"
  local Cipher = luajava.bindClass "javax.crypto.Cipher"
  local String = luajava.bindClass "java.lang.String"

  local x509EncodedKeySpec = X509EncodedKeySpec(Base64.decode(publicKeyText,Base64.DEFAULT))
  local keyFactory = KeyFactory.getInstance("RSA")
  local publicKey = keyFactory.generatePublic(x509EncodedKeySpec)
  local cipher = Cipher.getInstance("RSA")
  cipher.init(Cipher.DECRYPT_MODE, publicKey)
  local result = doLongerCipherFinal(Cipher.DECRYPT_MODE, cipher, Base64.decode(text,Base64.DEFAULT))
  return String(result)
end

--使用私钥解密
function _M.decryptByPrivateKey(privateKeyText, text)
  local PKCS8EncodedKeySpec = luajava.bindClass "java.security.spec.PKCS8EncodedKeySpec"
  local Base64 = luajava.bindClass "android.util.Base64"
  local KeyFactory = luajava.bindClass "java.security.KeyFactory"
  local Cipher = luajava.bindClass "javax.crypto.Cipher"
  local String = luajava.bindClass "java.lang.String"

  local pkcs8EncodedKeySpec = PKCS8EncodedKeySpec(Base64.decode(privateKeyText,Base64.DEFAULT))
  local keyFactory = KeyFactory.getInstance("RSA")
  local privateKey = keyFactory.generatePrivate(pkcs8EncodedKeySpec)
  local cipher = Cipher.getInstance("RSA")
  cipher.init(Cipher.DECRYPT_MODE, privateKey)
  local result = doLongerCipherFinal(Cipher.DECRYPT_MODE, cipher, Base64.decode(text,Base64.DEFAULT))
  return String(result)
end

--使用私钥加密
function _M.encryptByPrivateKey(privateKeyText, text)
  local PKCS8EncodedKeySpec = luajava.bindClass "java.security.spec.PKCS8EncodedKeySpec"
  local Base64 = luajava.bindClass "android.util.Base64"
  local KeyFactory = luajava.bindClass "java.security.KeyFactory"
  local Cipher = luajava.bindClass "javax.crypto.Cipher"
  local String = luajava.bindClass "java.lang.String"

  local pkcs8EncodedKeySpec = PKCS8EncodedKeySpec(Base64.decode(privateKeyText,Base64.DEFAULT))
  local keyFactory = KeyFactory.getInstance("RSA")
  local privateKey = keyFactory.generatePrivate(pkcs8EncodedKeySpec)
  local cipher = Cipher.getInstance("RSA")
  cipher.init(Cipher.ENCRYPT_MODE, privateKey)
  local result = doLongerCipherFinal(Cipher.ENCRYPT_MODE, cipher, String(text).getBytes())
  return Base64.encodeToString(result,Base64.DEFAULT)
end




return _M