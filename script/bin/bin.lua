require "import"
import "android.os.Environment"
import "java.util.zip.ZipOutputStream"
import "android.net.Uri"
import "java.io.File"
import "android.widget.Toast"
import "java.util.zip.CheckedInputStream"
import "java.io.FileInputStream"
import "android.content.Intent"
import "java.security.Signer"
import "java.util.ArrayList"
import "java.io.FileOutputStream"
import "java.io.BufferedOutputStream"
import "java.util.zip.ZipInputStream"
import "java.io.BufferedInputStream"
import "java.util.zip.ZipEntry"
import "android.app.ProgressDialog"
import "java.util.zip.CheckedOutputStream"
import "java.util.zip.Adler32"
import "script.bin.bindlg"


local sddir = Environment.getExternalStorageDirectory().toString()
local manadir = sddir.."/KunLua+/"
local bindir = manadir.."bin/"
local error_dlg
local function update(s)
  bindlg.update(s)
end


local function callback(s)
  LuaUtil.rmDir(File(bindir .. ".cache"))
  LuaUtil.rmDir(File(bindir .. ".temp"))
  bindlg.hide()
  Toast.makeText(activity, s, Toast.LENGTH_LONG).show()
  if not s:find("成功") then
    error_dlg.Message = s
    error_dlg.show()
  end
end



local function create_error_dlg2()
  if error_dlg then
    return
  end
  error_dlg = AlertDialogBuilder(activity)
  error_dlg.Title = "出错"
  error_dlg.setPositiveButton("确定", nil)
end


local function binapk(luapath, apkpath, manaset_compile)
  require "import"
  import "android.os.Environment"
  import "console"
  compile "script/bin/mao"
  compile "script/bin/sign"
  import "java.util.zip.*"
  import "java.io.*"
  import "mao.res.*"
  import "apksigner.*"
  --lua自定义依赖
  --[=[  local sddir = Environment.getExternalStorageDirectory().toString()
  local manadir = sddir.."/KunLua+/"
  manaset_compile.lualibs = manadir.."lualibs/"
  ]=]
  local sddir = activity.getLuaDir()
  local manadir = sddir.."/lua/"
  manaset_compile.lualibs = manadir

  local b = byte[2 ^ 16]
  local function copy(input, output)
    LuaUtil.copyFile(input, output)
    pcall(function() input.close() end)
    --[[local l=input.read(b)
      while l>1 do
        output.write(b,0,l)
        l=input.read(b)
      end]]
  end

  local function copy2(input, output)
    LuaUtil.copyFile(input, output)
  end

  local temp = File(apkpath).getParentFile();
  if (not temp.exists()) then
    if (not temp.mkdirs()) then
      error("create file " .. temp.getName() .. " fail");
    end
  end

  local tmp = activity.getLuaPath("tmp.apk")
  local info = activity.getApplicationInfo()
  local ver = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).versionName
  local code = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).versionCode


  --local zip=ZipFile(info.publicSourceDir)
  local zipFile = File(info.publicSourceDir)
  local fis = FileInputStream(zipFile);
  --local checksum = CheckedInputStream(fis, Adler32());
  local zis = ZipInputStream(BufferedInputStream(fis));

  local fot = FileOutputStream(tmp)
  --local checksum2 = CheckedOutputStream(fot, Adler32());

  local out = ZipOutputStream(BufferedOutputStream(fot))
  local f = File(luapath)
  local errbuffer = {}
  local replace = {}
  local checked = {}
  local lualib = {}
  local md5s = {}
  local libs = File(activity.ApplicationInfo.nativeLibraryDir).list()
  libs = luajava.astable(libs)
  for k, v in ipairs(libs) do
    --libs[k]="lib/armeabi/"..libs[k]
    replace[v] = true
  end

  local mdp = activity.Application.MdDir
  local function getmodule(dir)
    local mds = File(activity.Application.MdDir .. dir).listFiles()
    mds = luajava.astable(mds)
    for k, v in ipairs(mds) do
      if mds[k].isDirectory() then
        getmodule(dir .. mds[k].Name .. "/")
       else
        mds[k] = "lua" .. dir .. mds[k].Name
        replace[mds[k]] = true
      end
    end
  end

  getmodule("/")

  local function checklib(path)
    if checked[path] then
      return
    end
    local cp, lp
    checked[path] = true
    local f = io.open(path)
    local s = f:read("*a")
    f:close()
    for m, n in s:gmatch("require *%(? *\"([%w_]+)%.?([%w_]*)") do
      cp = string.format("lib%s.so", m)
      if n ~= "" then
        lp = string.format("lua/%s/%s.lua", m, n)
        m = m .. '/' .. n
       else
        lp = string.format("lua/%s.lua", m)
      end
      if replace[cp] then
        replace[cp] = false
      end
      if replace[lp] then
        checklib(mdp .. "/" .. m .. ".lua")
        replace[lp] = false
        lualib[lp] = mdp .. "/" .. m .. ".lua"
      end
    end
    for m, n in s:gmatch("import *%(? *\"([%w_]+)%.?([%w_]*)") do
      cp = string.format("lib%s.so", m)
      if n ~= "" then
        lp = string.format("lua/%s/%s.lua", m, n)
        m = m .. '/' .. n
       else
        lp = string.format("lua/%s.lua", m)
      end
      if replace[cp] then
        replace[cp] = false
      end
      if replace[lp] then
        checklib(mdp .. "/" .. m .. ".lua")
        replace[lp] = false
        lualib[lp] = mdp .. "/" .. m .. ".lua"
      end
    end
  end

  local dirtemp = {}
  local function customLualibs(p)
    local luaname = ""
    local lualibsDir = luajava.astable(File(p).listFiles() or File{})
    for name, v in pairs(lualibsDir) do
      if v.isFile() and tostring(v.name):find("%.lua$") then
        luaname = table.concat(dirtemp, "/")
        if table.size(dirtemp) > 0 then
          luaname = table.concat(dirtemp, "/") .. "/"
        end
        local luapools = "lua/" .. luaname .. tostring(v.name)
        lualib[luapools] = tostring(v)
       elseif v.isDirectory() then
        table.insert(dirtemp, tostring(v.name))
        customLualibs(tostring(v))
        dirtemp = {}
      end
    end
  end

  --自定义lua依赖库
  if File(manaset_compile.lualibs).isDirectory() then
    customLualibs(manaset_compile.lualibs)
  end




  replace["libluajava.so"] = false


  --lua加密方式
  local function LuaEncrypt(lp, m)
    local path, err,newlp
    local function LuaMix(p)
      --混淆内容
    end

    if tointeger(manaset_compile.encrypt) == 2 then --Mana
      LuaMix(lp)
      path, err = console.build(lp)
     elseif tointeger(manaset_compile.encrypt) == 3 then --开源
      if tostring(lp):find("%.aly$") then
        newlp = tostring(lp):gsub("aly$", "lua")
       elseif tostring(lp):find("%.lua$") then
        newlp = tostring(lp):gsub("lua$", "luac")
      end
      LuaMix(lp)
      copy(lp, newlp)
      path, err = newlp,nil
     else --Androlua
      LuaMix(lp)
      path, err = console.build(lp)
    end
    return path, err
  end




  local function addDir(out, dir, f)
    local entry = ZipEntry("assets/" .. dir)
    out.putNextEntry(entry)
    local ls = f.listFiles()
    for n = 0, #ls - 1 do
      local name = ls[n].getName()
      this.update("正在编译：" ..name);
      if name==(".using") then
        checklib(luapath .. dir .. name)
       elseif name:find("%.apk$") or name:find("%.luac$") or name:find("^%.") then

       elseif name:find("%.lua$") then
        checklib(luapath .. dir .. name)
        local path, err = LuaEncrypt(luapath .. dir .. name)
        if path then
          if replace["assets/" .. dir .. name] then
            table.insert(errbuffer, dir .. name .. "/.aly")
          end
          local entry = ZipEntry("assets/" .. dir .. name)
          out.putNextEntry(entry)

          replace["assets/" .. dir .. name] = true
          copy(FileInputStream(File(path)), out)
          table.insert(md5s, LuaUtil.getFileMD5(path))
          os.remove(path)
         else
          table.insert(errbuffer, err)
        end

       elseif name:find("%.aly$") then
        local path, err = LuaEncrypt(luapath .. dir .. name, "aly")
        if path then
          name = name:gsub("aly$", "lua")
          if replace["assets/" .. dir .. name] then
            table.insert(errbuffer, dir .. name .. "/.aly")
          end
          local entry = ZipEntry("assets/" .. dir .. name)
          out.putNextEntry(entry)

          replace["assets/" .. dir .. name] = true
          copy(FileInputStream(File(path)), out)
          table.insert(md5s, LuaUtil.getFileMD5(path))
          os.remove(path)
         else
          table.insert(errbuffer, err)
        end

       elseif ls[n].isDirectory() then
        addDir(out, dir .. name .. "/", ls[n])
       else
        local entry = ZipEntry("assets/" .. dir .. name)
        out.putNextEntry(entry)
        replace["assets/" .. dir .. name] = true
        copy(FileInputStream(ls[n]), out)
        table.insert(md5s, LuaUtil.getFileMD5(ls[n]))
      end
    end
  end





  -- 修改so库处理部分，确保包含主流架构
  local function customSolibs(p)
    local soname = ""
    local lualibsDir = luajava.astable(File(p).listFiles() or File{})
    for name, v in pairs(lualibsDir) do
      soname = tostring(v.name)
      if v.isFile() and soname:find("%.so$") then
        -- 为所有主流架构添加so文件
        local archs = {
          "armeabi-v7a",
          "arm64-v8a",
          "x86",
          "x86_64"
        }
        for _, arch in ipairs(archs) do
          local spath = "lib/"..arch.."/"..soname
          local entry = ZipEntry(spath)
          out.putNextEntry(entry)
          replace[spath] = true
          copy(FileInputStream(tostring(v)), out)
          table.insert(md5s, LuaUtil.getFileMD5(tostring(v)))
        end
       elseif v.isDirectory() then
        customSolibs(tostring(v))
      end
    end
  end

  --自定义so依赖库(32位)

  if File(manaset_compile.solibs).isDirectory() then
    customSolibs(manaset_compile.solibs)
  end



  local function customSolibs64(p)
    local soname = ""
    local lualibsDir = luajava.astable(File(p).listFiles() or File{})
    for name, v in pairs(lualibsDir) do
      soname = tostring(v.name)
      if v.isFile() and soname:find("%.so$") then
        local spath = "lib/arm64-v8a/" .. soname
        local entry = ZipEntry(spath)
        out.putNextEntry(entry)
        replace[spath] = true
        copy(FileInputStream(tostring(v)), out)
        table.insert(md5s, LuaUtil.getFileMD5(tostring(v)))
       elseif v.isDirectory() then
        customSolibs64(tostring(v))
      end
    end
  end

  --自定义so依赖库(64位)

  if File(manaset_compile.solibs64).isDirectory() then
    customSolibs64(manaset_compile.solibs64)
  end



  this.update("正在编译...");
  if f.isDirectory() then
    require "permission"
    dofile(luapath .. "init.lua")
    if user_permission then
      for k, v in ipairs(user_permission) do
        user_permission[v] = true
      end
    end


    local ss, ee = pcall(addDir, out, "", f)
    if not ss then
      table.insert(errbuffer, ee)
    end

    local wel = File(luapath .. "icon.png")
    if wel.exists() then
      local entry = ZipEntry("res/drawable/icon.png")
      out.putNextEntry(entry)
      replace["res/drawable/icon.png"] = true
      copy(FileInputStream(wel), out)
    end
    local wel = File(luapath .. "welcome.png")
    if wel.exists() then
      local entry = ZipEntry("res/drawable/welcome.png")
      out.putNextEntry(entry)
      replace["res/drawable/welcome.png"] = true
      copy(FileInputStream(wel), out)
    end
   else
    return "error"
  end




  --编译lua依赖库
  for name, v in pairs(lualib) do
    local path, err = LuaEncrypt(v)
    if path then
      local entry = ZipEntry(name)
      out.putNextEntry(entry)
      copy(FileInputStream(File(path)), out)
      table.insert(md5s, LuaUtil.getFileMD5(path))
      os.remove(path)
     else
      table.insert(errbuffer, err)
    end
  end






  function touint32(i)
    local code = string.format("%08x", i)
    local uint = {}
    for n in code:gmatch("..") do
      table.insert(uint, 1, string.char(tonumber(n, 16)))
    end
    return table.concat(uint)
  end

  this.update("正在打包...");
  local entry = zis.getNextEntry();
  while entry do
    local name = entry.getName()
    local lib = name:match("([^/]+%.so)$")
    if replace[name] then
     elseif lib and replace[lib] then
     elseif name:find("^assets/") then
     elseif name:find("^lua/") then
     elseif name:find("META%-INF") then
     elseif !name:find("%a") then
     else
      local entry = ZipEntry(name)
      out.putNextEntry(entry)
      if entry.getName() == "AndroidManifest.xml" then
        if path_pattern and #path_pattern > 1 then
          path_pattern = ".*\\\\." .. path_pattern:match("%w+$")
        end
        local list = ArrayList()
        --AndroidmlManifest.xml处理
        local xml = AXmlDecoder.read(list, zis)


        -- 在bin.lua中找到AndroidManifest.xml处理部分
        local function generateUniqueAuthority(packageName, providerType)
          -- 使用包名+时间戳+随机数生成唯一authority
          local timestamp = os.time()
          local random = math.random(10000, 99999)
          return packageName .. "." .. providerType .. "." .. timestamp .. "." .. random
        end

        -- 修改替换规则
        local req = {
          [activity.getPackageName()] = packagename,
          [info.nonLocalizedLabel] = appname,
          [ver] = appver,
          [".*\\\\.lua"] = "",
          [".*\\\\.luac"] = "",
          -- InitializationProvider authority
          ["com.kunbao.kunluap.androidx-startup"] = generateUniqueAuthority(packagename, "startup")
        }
        if path_pattern==nil or path_pattern=="" then
          req[".*\\\\.alp"] = ""
          req["application/alp"] = "application/1234567890"
         else
          path_pattern=path_pattern:match("%w+$") or path_pattern
          req[".*\\\\.alp"] = ".*\\\\."..path_pattern
          req["application/alp"] = "application/"..path_pattern
        end

        for n = 0, list.size() - 1 do
          local v = list.get(n)
          if req[v] then
            list.set(n, req[v])
           elseif user_permission then
            local p = v:match("%.permission%.([%w_]+)$")
            if p and (not user_permission[p]) then
              list.set(n, "android.permission.UNKNOWN")
            end
          end
        end
        local pt = activity.getLuaPath(".tmp")
        local fo = FileOutputStream(pt)
        xml.write(list, fo)
        local code = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).versionCode
        fo.close()
        local f = io.open(pt)
        local s = f:read("a")
        f:close()
        s = string.gsub(s, touint32(code), touint32(tointeger(appcode) or 1),1)
        s = string.gsub(s, touint32(15), touint32(tointeger(appsdk) or 15),1)
        local f = io.open(pt, "w")
        f:write(s)
        f:close()
        local fi = FileInputStream(pt)
        copy(fi, out)
        os.remove(pt)
       elseif not entry.isDirectory() then
        copy2(zis, out)
      end
    end
    entry = zis.getNextEntry()
  end




  out.setComment(table.concat(md5s))
  --print(table.concat(md5s,"/n"))
  zis.close();
  out.closeEntry()
  out.close()

  if #errbuffer == 0 then
    os.remove(apkpath)


    if manaset_compile.sign then
      this.update("正在签名...");
      Signer.sign(tmp, apkpath)
     else
      this.update("正在生成APK...");
      os.execute("mv "..tmp.." "..apkpath)
    end

    --[[修改签名部分
    if manaset_compile.sign then
      this.update("正在签名...")
      -- 为每个项目生成唯一的调试密钥指纹
      local projectKey = "debug_"..string.lower(string.gsub(packagename, "[^%w]", ""))
      local signConfig = {
        keystore = manaset_compile.keystore or (activity.getLuaDir().."/"..projectKey..".keystore"),
        storepass = manaset_compile.storepass or "android",
        keypass = manaset_compile.keypass or "android",
        alias = manaset_compile.alias or "androiddebugkey"
      }

      -- 如果不存在则创建调试密钥
      if not File(signConfig.keystore).exists() then
        os.execute("keytool -genkey -v -keystore "..signConfig.keystore..
        " -alias "..signConfig.alias..
        " -keyalg RSA -keysize 2048 -validity 10000"..
        " -storepass "..signConfig.storepass..
        " -keypass "..signConfig.keypass..
        " -dname 'CN=Android Debug,O=Android,C=US'")
      end

      Signer.sign(tmp, apkpath, signConfig)
    end]]

    os.remove(tmp)

    if manaset_compile.openapk then
      activity.installApk(apkpath)
    end

    --[[  import "android.net.*"
    import "android.content.*"
    i = Intent(Intent.ACTION_VIEW);
    i.setDataAndType(activity.getUriForFile(File(apkpath)), "application/vnd.android.package-archive");
    i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    this.update("正在打开...");
    activity.startActivityForResult(i, 0);
]]

    return "打包成功:" .. apkpath
   else
    os.remove(tmp)
    this.update("打包出错:\n " .. table.concat(errbuffer, "\n"));
    return "打包出错:\n " .. table.concat(errbuffer, "\n")
  end
end





--luabindir=activity.getLuaExtDir("bin")
--print(activity.getLuaExtPath("bin","a"))
local function bin(path, manaset_compile)
  local p = {}
  local e, s = pcall(loadfile(path .. "init.lua", "bt", p))
  if e then
    create_error_dlg2()
    bindlg.show()
    local binCache = bindir .. ".cache/"
    bindlg.update("正在配置环境...")
    task(300,function()
      import "java.io.File"
      if File(binCache).isDirectory() then
        os.remove(binCache)
      end
      if LuaUtil.copyDir(path, binCache) then
        local skipc = manaset_compile.skipc .. "#n#"
        for k skipc:gmatch("(.-)#n#") do
          if k ~= "" then
            if File(binCache .. k).isDirectory() or File(binCache .. k).isFile() then
              LuaUtil.rmDir(File(binCache .. k))
            end
          end
        end
        activity.newTask(binapk, update, callback).execute { binCache, (bindir .. p.appname .. "_" .. p.appver .. ".apk"), manaset_compile}
      end
    end)
   else
    Toast.makeText(activity, "工程配置文件错误." .. s, Toast.LENGTH_SHORT).show()
  end
end

--bin(activity.getLuaExtDir("project/demo").."/")
return bin