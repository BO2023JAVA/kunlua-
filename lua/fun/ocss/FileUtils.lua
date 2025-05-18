local _M = {}

_M.FileDialogSelect = function(StartPath, Callback)
  local File = luajava.bindClass "java.io.File"
  local LuaAdapter = luajava.bindClass "com.androlua.LuaAdapter"
  local ListView = luajava.bindClass "android.widget.ListView"
  local LinearLayoutCompat = luajava.bindClass "androidx.appcompat.widget.LinearLayoutCompat"
  local MaterialTextView = luajava.bindClass "com.google.android.material.textview.MaterialTextView"
  local MaterialAlertDialogBuilder = luajava.bindClass "com.google.android.material.dialog.MaterialAlertDialogBuilder"
  local dialog=MaterialAlertDialogBuilder(activity)
  .setTitle("选择文件")
  .setView(loadlayout({
    LinearLayoutCompat;--线性控件
    orientation='vertical';--布局方向
    layout_width='fill';--布局宽度
    layout_height='fill';--布局高度
    {
      MaterialTextView;--文本控件
      layout_width='fill';--控件宽度
      layout_height='wrap';--控件高度
      layout_margin='16dp';--布局左距
      textSize='16sp';--文字大小
      textColor='#333333';--文字颜色
      id='currentPath';--设置控件ID
      gravity='left|center';--重力
    };
    {
      ListView;--列表适配器
      layout_width='fill';--宽度
      layout_height='fill';--高度
      id="listPath";
      dividerHeight=1;
      fastScrollEnabled=true;
      verticalScrollBarEnabled=false;
    };
  }))
  .setCancelable(false)
  .setPositiveButton("取消",nil)
  .show()
  local data = {}
  local item = {
    LinearLayout;--线性控件
    orientation='vertical';--布局方向
    layout_width='fill';--布局宽度
    layout_height='fill';--布局高度
    {
      MaterialTextView;--文本控件
      layout_width='fill';--控件宽度
      layout_height='48dp';--控件高度
      textSize='16sp';--文字大小
      textColor='#333333';--文字颜色
      gravity='left|center';--重力
      layout_marginLeft='16dp';--布局左距
      layout_marginRight='16dp';--布局右距
      id='name';--设置控件ID
    }
  }
  local adp = LuaAdapter(activity, data, item)--设置适配器
  listPath.setAdapter(adp)

  function listFilesItem(path)
    adp.clear()
    currentPath.setText(tostring(path))

    local fileParentPath = File(tostring(path)).getParent()
    if(File(fileParentPath).canRead())then
      adp.add({
        name = "../",
        path = fileParentPath
      })
    end

    local function listFilePath(path)
      local ls = File(tostring(path)).listFiles()
      if(ls ~= nil)then
        ls = luajava.astable(File(tostring(path)).listFiles()) --全局文件列表变量
        table.sort(ls, function(a, b)
          return (a.isDirectory()~=b.isDirectory() and a.isDirectory()) or ((a.isDirectory()==b.isDirectory()) and a.Name<b.Name)
        end)
        return ls
       else
        return {}
      end
    end

    for index,value in ipairs(listFilePath(path)) do
      if(not value.isHidden())then
        local name = value.getName()
        if(value.isDirectory())then
          name = name.."/"
          adp.add({
            name = name,
            path = value.getAbsolutePath()
          })
         else
          if(name:find("%.md+$"))then
            adp.add({
              name = name,
              path = value.getAbsolutePath()
            })
          end
        end
      end
    end
  end

  listPath.onItemClick=function(l,view,pos,s)--列表点击事件
    local name = data[pos+1].name
    local path = data[pos+1].path
    local filePathObject = File(path)

    if(filePathObject.isDirectory())then
      if(filePathObject.canRead())then
        listFilesItem(path)
       else
        print("目录不可读")
      end
     elseif(filePathObject.isFile())then
      Callback(path)
      dialog.dismiss()
     else
      print("这很奇怪")
    end
  end

  if(not StartPath or not File(tostring(StartPath).isDirectory()))then
    local Environment = luajava.bindClass "android.os.Environment"
    StartPath = Environment.getExternalStoragePublicDirectory("").toString()
  end

  listFilesItem(StartPath)
end

_M.delete = function(path)
  local File = luajava.bindClass "java.io.File"
  local file = File(tostring(path))
  if file.exists() then
    if(file.isDirectory())then
      local list = _M.listFilePaths(path)
      for i = 1, #list do
        _M.delete(tostring(list[i]))
      end
      file.delete()
     else
      file.delete()
    end
  end
end

_M.listFilePaths = function(dir)
  local File = luajava.bindClass "java.io.File"
  local file =File(dir)
  if(file.exists() and file.isDirectory())then
    return luajava.astable(file.listFiles())
   else
    return {}
  end
end

_M.listFileNames = function(dir)
  local File = luajava.bindClass "java.io.File"
  local file =File(dir)
  if file.exists() and file.isDirectory() then
    return luajava.astable(file.list())
   else
    return {}
  end
end

_M.create = function(path, content)
  local File = luajava.bindClass "java.io.File"
  local file = File(tostring(path))
  if(file.isDirectory())then
    if(not file.exists())then
      file.mkdirs()
    end
    return;
   else
    local parentFile = file.getParentFile()
    if(not parentFile.exists())then
      parentFile.mkdirs()
    end
  end
  if not file.exists() then
    file.createNewFile()
    if(content and content ~= "")then
      _M.iowrite(path, tostring(content))
    end
  end
end

_M.bufferedread = function(filePath, lines)
  local File = luajava.bindClass "java.io.File"
  local StringBuilder = luajava.bindClass "java.lang.StringBuilder"
  local FileReader = luajava.bindClass "java.io.FileReader"
  local BufferedReader = luajava.bindClass "java.io.BufferedReader"
  local fileObject = File(tostring(filePath))
  if(fileObject.isFile() and fileObject.length() > 0)then
    local bfr = BufferedReader(FileReader(tostring(filePath)))
    local line = bfr.readLine()
    local result = StringBuilder(line or " ")
    if(not lines or type(lines)~="number" or lines<=0)then
      while(line ~= nil)do
        result.append("\n").append(line)
        line = bfr.readLine()
      end
     else
      local count = 1
      while(count < lines)do
        result.append("\n").append(line)
        line = bfr.readLine()
        lines = lines + 1
      end
    end
    bfr.close()
    return result.toString()
  end
  return " "
end

_M.nioread = function(path)
  local File = luajava.bindClass "java.io.File"
  local FileInputStream = luajava.bindClass "java.io.FileInputStream"
  local ByteBuffer = luajava.bindClass "java.nio.ByteBuffer"
  local file = File(path)
  local input = FileInputStream(file)
  local fileChannel = input.getChannel()
  local buffer = ByteBuffer.allocate(file.length())
  fileChannel.read(buffer)
  fileChannel.close()
  input.close()
  buffer.clear()
  return String(buffer.array())
end

_M.ioread = function(filePath)
  local File = luajava.bindClass "java.io.File"
  local fileObject = File(tostring(filePath))
  if(fileObject.isFile() and fileObject.length() > 0)then
    return io.open(tostring(filePath)):read("*a")
  end
  return ""
end

_M.rawioread = function(filePath)
  local File = luajava.bindClass "java.io.File"
  local fileObject = File(tostring(filePath))
  if(fileObject.isFile() and fileObject.length() > 0)then
    local rawio = require "rawio"
    return rawio.iotsread(tostring(filePath))
  end
  return " "
end


_M.bufferedwrite = function(filePath, content, isCreate)
  local File = luajava.bindClass "java.io.File"
  local FileWriter = luajava.bindClass "java.io.FileWriter"
  local BufferedWriter = luajava.bindClass "java.io.BufferedWriter"
  local fileObject = File(tostring(filePath))
  if(utf8.len(tostring(content)) > 0)then
    if(fileObject.isFile())then
      local bfw = BufferedWriter(FileWriter(tostring(filePath)))
      bfw.write(tostring(content))
      bfw.close()
     else
      if isCreate then
        local bfw = BufferedWriter(FileWriter(tostring(filePath)))
        bfw.write(tostring(content))
        bfw.close()
      end
    end
   else
    return false
  end
  return true
end

_M.rawiowrite = function(filePath, content)
  local rawio = require "rawio"
  if(utf8.len(tostring(content)) > 0)then
    rawio.iowrite(tostring(filePath), tostring(content))
   else
    return false
  end
  return true
end

_M.iowrite = function(filePath, content)
  local File = luajava.bindClass "java.io.File"
  local fileObject = File(tostring(filePath))
  if(utf8.len(tostring(content)) > 0)then
    if(fileObject.isFile())then
      io.open(tostring(filePath),"w+"):write(tostring(content)):close()
     else
      io.open(tostring(filePath),"w"):write(tostring(content)):close()
    end
   else
    return false
  end
  return true
end


_M.rename = function(old, new)
  local File = luajava.bindClass "java.io.File"
  return File(old).renameTo(File(new))
end

_M.zip = function(inpath, outpath)
  local ZipUtil = luajava.bindClass "com.androlua.ZipUtil"
  return ZipUtil.zip(inpath, outpath)
end

_M.unZip = function(inpath, outpath)
  local ZipUtil = luajava.bindClass "com.androlua.ZipUtil"
  return ZipUtil.unzip(inpath, outpath)
end

_M.copy = function(inpath, outpath)
  local LuaUtil = luajava.bindClass "com.androlua.LuaUtil"
  return LuaUtil.copyFile(inpath, outpath)
end

_M.remove = function(path)
  return os.execute([[rm -rf "]]..tostring(path)..[["]])
end

_M.md5 = function(path)
  local LuaUtil = luajava.bindClass "com.androlua.LuaUtil"
  return LuaUtil.getFileMD5(path)
end

_M.sha1 = function(path)
  local LuaUtil = luajava.bindClass "com.androlua.LuaUtil"
  return LuaUtil.getFileSha1(path)
end

function _M.download(data)
  local function toast(toastText)
    local Toast = luajava.bindClass "android.widget.Toast"
    Toast.makeText(activity,tostring(toastText),Toast.LENGTH_SHORT).show()
  end
  if(data == nil or data == "" or type(data) ~= "table")then
    toast("下载任务信息类型异常")
    return false
  end
  local fileUrl, externalStoragePublicDirectoryType, fileDirectory, fileName = data["url"], data["type"], data["dir"],data["name"]
  local Context = luajava.bindClass "android.content.Context"
  local DownloadManager = luajava.bindClass "android.app.DownloadManager"
  local Uri = luajava.bindClass "android.net.Uri"
  local MimeTypeMap = luajava.bindClass "android.webkit.MimeTypeMap"
  local LuaBroadcastReceiver = luajava.bindClass "com.androlua.LuaBroadcastReceiver"
  local IntentFilter = luajava.bindClass "android.content.IntentFilter"
  local OnReceiveListener = luajava.bindClass "com.androlua.LuaBroadcastReceiver$OnReceiveListener"
  local function filterFilePath(dir, name)
    if(dir == nil or dir == "" or type(dir) ~= "string")then
      return name
    end
    return dir .."/"..name
  end
  local function filterPublicDirectory(externalStoragePublicDirectoryType)
    local Environment = luajava.bindClass "android.os.Environment"
    local PublicDirectorys = {
      Environment.DIRECTORY_MUSIC,
      Environment.DIRECTORY_PODCASTS,
      Environment.DIRECTORY_RINGTONES,
      Environment.DIRECTORY_ALARMS,
      Environment.DIRECTORY_NOTIFICATIONS,
      Environment.DIRECTORY_PICTURES,
      Environment.DIRECTORY_MOVIES,
      Environment.DIRECTORY_DOWNLOADS,
      Environment.DIRECTORY_DCIM,
      Environment.DIRECTORY_DOCUMENTS
    }
    if(externalStoragePublicDirectoryType == nil or externalStoragePublicDirectoryType == "" or type(externalStoragePublicDirectoryType) ~= "number")then
      return PublicDirectorys[8]
    end
    if(externalStoragePublicDirectoryType > #PublicDirectorys or externalStoragePublicDirectoryType <= 0)then
      return PublicDirectorys[8]
    end
    return PublicDirectorys[externalStoragePublicDirectoryType]
  end
  if(fileUrl == nil or fileUrl == "" or type(fileUrl) ~= "string")then
    toast("下载地址类型异常")
    return false
  end
  if(fileName == nil or fileName == "" or type(fileName) ~= "string")then
    local UUID = luajava.bindClass "java.util.UUID"
    fileName = tostring(UUID.randomUUID())..".txt"
  end
  -- 替换掉系统不支持作为文件名的字符
  -- 当然您也可以使用这行更全面的
  -- fileName:gsub("\\",""):gsub(":",""):gsub("*",""):gsub("?",""):gsub("|",""):gsub("<",""):gsub(">",""):gsub("#",""):gsub("/", "")
  local fileName = fileName:gsub("/", "、"):gsub("#", "♯")
  local downloadManager=activity.getSystemService(Context.DOWNLOAD_SERVICE);
  local request=DownloadManager.Request(Uri.parse(fileUrl));
  local mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileName:match("%.(.+)"))
  local filePath = tostring(filterFilePath(fileDirectory, fileName))
  request.setTitle(fileName);
  request.setMimeType(mimeType);
  request.setAllowedNetworkTypes(DownloadManager.Request.NETWORK_MOBILE|DownloadManager.Request.NETWORK_WIFI);
  request.setDestinationInExternalPublicDir(filterPublicDirectory(externalStoragePublicDirectoryType), filePath);
  request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
  local download_id = downloadManager.enqueue(request);
  toast("下载任务已创建,打开通知栏查看下载进度")
  local intentFilter = IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
  local broadcastReceiver = LuaBroadcastReceiver(LuaBroadcastReceiver.OnReceiveListener{
    onReceive=function(context, intent)
      local intent_id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID,-1);
      if (intent_id == download_id) then
        local externalStoragePublicDirectory = Environment.getExternalStoragePublicDirectory(filterPublicDirectory(externalStoragePublicDirectoryType)).toString()
        local path = externalStoragePublicDirectory.."/"..filterFilePath(fileDirectory, fileName)
        toast("保存成功 保存路径："..path)
        --activity.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE,Uri.parse("file://"..path)))
      end
    end
  })
  activity.registerReceiver(broadcastReceiver,intentFilter)
end

--[[
Utils.download({
  url = "https://example.com", --下载地址
  name = "example.txt", -- 文件名 [可选]
  type = 8, -- 公开文件夹类型 [可选]
  dir = "exmple" -- 二级目录名称 [可选]
})
--]]

return _M