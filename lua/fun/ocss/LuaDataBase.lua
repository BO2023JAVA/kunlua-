local _M = {}
local File = luajava.bindClass "java.io.File"
local cjson = require "cjson"
local Utils = require "fun.ocss.Utils"
local FileUtils = require "fun.ocss.FileUtils"
local LuaTableUtil= require "fun.ocss.LuaTableUtil"

--初始化数据库
_M.startDataBase = function(databaseName)
  --初始化关键信息
  local databaseName = tostring(databaseName) or "default"
  local PackageName = tostring(activity.getPackageName()) or "fun.ocss.db.default"
  local ApplicationName = tostring(Utils.getApplicationName()) or "ocssdatabase"
  --获取应用对应Android/data目录
  local ExternalFilesDir = activity.getExternalFilesDir(nil).toString()
  --拼接得到设置配置文件储存目录
  local dataBaseFilesDir = ExternalFilesDir.."/database_"..ApplicationName.."/"
  --拼接得到数据库文件目录
  local dataBaseFilePath = dataBaseFilesDir.. databaseName ..".db.ocss"
  --创建多级文件夹
  File(dataBaseFilesDir).mkdirs()
  --创建对应的File对象
  local file = File(dataBaseFilePath)
  --初始化返回值
  local msg = {}
  --判断数据储存目录内是否存有对应文件
  if file.exists() and file.isFile() and file.canRead() then
    --读取数据
    local data = FileUtils.ioread(dataBaseFilePath)
    --初始化参数
    local result = true
    local dataTable = {}
    table.insert(msg,"database is exists")
    --解析数据表
    if pcall(function()dataTable = cjson.decode(data)end) then
      table.insert(msg,"datatable analysis success")
     else
      result = false
      dataTable = {}
      table.insert(msg,"datatable analysis failed")
    end
    --返回数据
    return dataTable, result, msg
   else
    --写入初始数据
    local result = FileUtils.iowrite(dataBaseFilePath, "[]")
    table.insert(msg,"database is invalid")
    if result then
      table.insert(msg,"datatable create success")
     else
      table.insert(msg,"datatable create failed")
    end
    --返回数据
    return {}, result, msg
  end
end

--更新数据记录模块
_M.updateDataBase = function(databaseName, data, isOverWrite)
  --初始化关键信息
  local databaseName = tostring(databaseName) or "default"
  local PackageName = tostring(activity.getPackageName()) or "fun.ocss.db.default"
  local ApplicationName = tostring(Utils.getApplicationName()) or "ocssdatabase"
  --获取应用对应Android/data目录
  local ExternalFilesDir = activity.getExternalFilesDir(nil).toString()
  --拼接得到设置配置文件储存目录
  local dataBaseFilesDir = ExternalFilesDir.."/database_"..ApplicationName.."/"
  --拼接得到数据库文件目录
  local dataBaseFilePath = dataBaseFilesDir.. databaseName ..".db.ocss"
  --创建多级文件夹
  File(dataBaseFilesDir).mkdirs()
  --创建对应的File对象
  local file = File(dataBaseFilePath)
  --初始化返回值
  local msg = {}
  --判断数据储存目录内是否存有对应文件
  if file.exists() and file.isFile() and file.canRead() then
    --初始化参数
    local result = true
    local dataTableString = "[]"
    table.insert(msg,"database is exists")
    --编码数据表
    if pcall(function()dataTableString = cjson.encode(data)end) then
      table.insert(msg,"datatable encode success")
     else
      result = false
      dataTableString = "[]"
      table.insert(msg,"datatable encode failed")
    end
    --写入数据
    if result then
      io.open(dataBaseFilePath,"w+"):write(dataTableString):close()
      table.insert(msg,"datatable is update")
     else
      if isOverWrite then
        io.open(dataBaseFilePath,"w+"):write(dataTableString):close()
        table.insert(msg,"datatable is overwrite")
       else
        table.insert(msg,"datatable is not modify")
      end
    end
    --返回数据
    return result, msg
   else
    --初始化参数
    local result = true
    local dataTableString = "[]"
    table.insert(msg,"database is invalid")
    --编码数据表
    if pcall(function()dataTableString = cjson.encode(data)end) then
      table.insert(msg,"datatable encode success")
     else
      result = false
      dataTableString = "[]"
      table.insert(msg,"datatable encode failed")
    end
    --写入数据
    if result then
      io.open(dataBaseFilePath,"w"):write(dataTableString):close()
      table.insert(msg,"datatable is update")
     else
      if isOverWrite then
        io.open(dataBaseFilePath,"w"):write(dataTableString):close()
        table.insert(msg,"datatable is overwrite")
       else
        table.insert(msg,"datatable is not modify")
      end
    end
    --返回数据
    return result, msg
  end
end

--添加数据到数据库
_M.putData = function(databaseName, dataTable, data, limit)
  --添加新数据
  table.insert(dataTable, 1, data)
  --处理数据
  if not limit or limit == "" or limit == nil then
    limit = #dataTable + 1
   else
    limit = tointeger(limit)
  end
  --如果总数超过limit条
  if #dataTable > limit then
    --直接保留最后limit条
    local data = {table.unpack(dataTable, 1, limit)}
    --刷新数据记录
    return _M.updateDataBase(databaseName, data)
   else
    --刷新数据记录
    return _M.updateDataBase(databaseName, dataTable)
  end
end

--获取数据（仅针对一般表
_M.getData = function(databaseName, key, defaultValue)
  --初始化关键信息
  local databaseName = tostring(databaseName) or "default"
  local PackageName = tostring(activity.getPackageName()) or "fun.ocss.db.default"
  local ApplicationName = tostring(Utils.getApplicationName()) or "ocssdatabase"
  --获取应用对应Android/data目录
  local ExternalFilesDir = activity.getExternalFilesDir(nil).toString()
  --拼接得到设置配置文件储存目录
  local dataBaseFilesDir = ExternalFilesDir.."/database_"..ApplicationName.."/"
  --拼接得到数据库文件目录
  local dataBaseFilePath = dataBaseFilesDir.. databaseName ..".db.ocss"
  --创建多级文件夹
  File(dataBaseFilesDir).mkdirs()
  --创建对应的File对象
  local file = File(dataBaseFilePath)
  --初始化返回值
  local msg = {}
  --判断数据储存目录内是否存有对应文件
  if file.exists() and file.isFile() and file.canRead() then
    --读取数据
    local data = FileUtils.ioread(dataBaseFilePath)
    --初始化参数
    local result = true
    local dataTable = {}
    table.insert(msg,"database is exists")
    --解析数据表
    if pcall(function()dataTable = cjson.decode(data)end) then
      table.insert(msg,"datatable analysis success")
     else
      result = false
      dataTable = {}
      table.insert(msg,"datatable analysis failed")
    end
    --获取键值
    if dataTable == {} then
      return defaultValue or nil, result, msg
     else
      --再次初始化数据
      result = false
      local value = defaultValue
      --解析谁有数据得到所需键
      table.foreach(dataTable, function(dataKey, dataValue)
        if(dataKey == key)then
          value, result = dataValue, true
        end
      end)
      --判断状态
      if result then
        table.insert(msg,"data obtained success")
       else
        table.insert(msg,"datakey is invalid")
      end
      return value, result, msg
    end
   else
    --啥也没有，读取个毛线
    table.insert(msg,"database is invalid")
    --返回异常
    return defaultValue or nil, false, msg
  end
end

--配置修改数据函数
_M.alterData = function(databaseName, key, data)
  --初始化关键信息
  local databaseName = tostring(databaseName) or "default"
  local PackageName = tostring(activity.getPackageName()) or "fun.ocss.db.default"
  local ApplicationName = tostring(Utils.getApplicationName()) or "ocssdatabase"
  --获取应用对应Android/data目录
  local ExternalFilesDir = activity.getExternalFilesDir(nil).toString()
  --拼接得到设置配置文件储存目录
  local dataBaseFilesDir = ExternalFilesDir.."/database_"..ApplicationName.."/"
  --拼接得到数据库文件目录
  local dataBaseFilePath = dataBaseFilesDir.. databaseName ..".db.ocss"
  --创建多级文件夹
  File(dataBaseFilesDir).mkdirs()
  --创建对应的File对象
  local file = File(dataBaseFilePath)
  --初始化返回值
  local msg = {}
  --判断数据储存目录内是否存有对应文件
  if file.exists() and file.isFile() and file.canRead() then
    --读取数据
    local data = FileUtils.ioread(dataBaseFilePath)
    --初始化参数
    local result = true
    local dataTable = {}
    table.insert(msg,"database is exists")
    --解析数据表
    if pcall(function()dataTable = cjson.decode(data)end) then
      table.insert(msg,"datatable analysis success")
     else
      result = false
      dataTable = {}
      table.insert(msg,"datatable analysis failed")
    end
    --添加数据
    dataTable[key] = data
    --储存新的表 更新数据
    io.open(dataBaseFilePath,"w+"):write(cjson.encode(dataTable)):close()
    --更新消息
    table.insert(msg,"newdata saved success")
    --返回值
    return result, msg
   else
    --提示数据库不存在
    table.insert(msg,"database is invalid")
    --依据key添加对应数据
    local dataTable = LuaTableUtil:new():putItem(key, data):sort():getTable()
    local content = cjson.encode(dataTable)
    --储存数据表 更新数据库
    io.open(dataBaseFilePath,"w"):write(content):close()
    --更新消息
    table.insert(msg,"newdata saved success")
    --返回值
    return false, msg
  end
end







return _M