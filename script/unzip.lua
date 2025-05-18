
--[=[  zipfile = "/storage/emulated/0/ManaLua/project/kunlua/libs/lualibs.jar"
--压缩文件路径和文件名
sdpath = "/storage/emulated/0/KunLua/lualibs/loadlayout.lua"
--解压后路径和文件名
zipfilepath = "loadlayout.lua"--需要解压的文件名  ]=]
local M={}
function M.unzip(zippath , outfilepath , filename)
  import "java.io.FileOutputStream"
  import "java.util.zip.ZipFile"
  import "java.io.File"
  local time=os.clock()
  task(function(zippath,outfilepath,filename)
    require "import"
    import "java.util.zip.*"
    import "java.io.*"
    local file = File(zippath)
    local outFile = File(outfilepath)
    local zipFile = ZipFile(file)
    local entry = zipFile.getEntry(filename)
    local input = zipFile.getInputStream(entry)
    local output = FileOutputStream(outFile)
    local byte=byte[entry.getSize()]
    local temp=input.read(byte)
    while temp ~= -1 do
      output.write(byte)
      temp=input.read(byte)
    end
    input.close()
    output.close()
  end,zippath,outfilepath,filename,
  function()
    print("解压完成，耗时 "..os.clock()-time.." s")
  end)
end
return M