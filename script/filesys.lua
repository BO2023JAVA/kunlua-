local M={}

-- 创建文件夹(可多级)
function M.newDir(path)
  import "java.io.File"
  local success = File(path).mkdirs() -- 尝试创建目录
  if not success then
    print("警告: 目录创建失败或目录已存在 - " .. path)
  end
  return success
end
--删除文件
function M.fileDel(path)
  import "java.io.File"--导入File类
  File(path).delete()
end

function M.rmDir(path)
  import "java.io.File"
  import "com.androlua.LuaUtil"

  -- 添加重试机制
  local retry = 0
  while retry < 3 do
    if LuaUtil.rmDir(File(path)) then
      return true
    end
    retry = retry + 1
    os.execute("sleep 0.2") -- 等待 200ms 重试
  end
  return false
end
--如果仍有残留，可在删除前添加路径校 验:
--print("待删除路径是否存在：", filesys.fileExists(project_path..home_list_name[i_flag]))


-- 创建文件
function M.fileWrite(path, content)
  import "java.io.File"
  -- 确保文件所在目录存在
  local dir = File(tostring(File(tostring(path)).getParentFile()))
  if not dir.exists() and not dir.mkdirs() then
    print("警告: 无法创建文件所在的目录 - " .. tostring(dir.getAbsolutePath()))
    return false
  end

  -- 写入文件内容
  local file, err = io.open(tostring(path), "w")
  if not file then
    print("错误: 打开文件失败 - " .. (err or "未知原因"))
    return false
  end

  file:write(tostring(content))
  file:close()

  return true
end

-- 追加更新
function M.fileWriteAdd(path, content)
  local file, err = io.open(path, "a+")
  if not file then
    print("错误: 打开文件失败 - " .. (err or "未知原因"))
    return false
  end

  file:write(content)
  file:close()

  return true
end

--读取文件
function M.fileRead(path)
  -- 打开文件，使用 'a' 模式表示以追加方式打开，但实际上我们只是读取，因此使用 'r'
  local file, err = io.open(path, "r")
  if not file then -- 如果文件打开失败
    print("读取文件失败: " .. (err or "未知错误"))
    return nil -- 返回 nil 表示读取失败
  end

  -- 读取文件所有内容
  local content = file:read("*a")

  -- 关闭文件
  file:close()

  -- 返回文件内容
  return content
end

---查找文件内字符串并提取
function M.fileFind(path, var_name)
  local content = M.fileRead(path) -- 假设这是正确的文件读取函数
  if not content then return end

  -- 构造匹配模式：变量名 + 任意空格 + 等号 + 任意空格 + 引号包裹的内容
  local pattern = var_name .. "%s*=%s*\"([^\"]+)\""

  -- 使用string.match进行模式匹配
  local value = string.match(content, pattern)

  if value then
    --   print("找到:", value)
    return value
   else
    print("没找到")
    return nil
  end
end
-- 检查文件/目录是否存在
function M.fileExists(path)
  import "java.io.File"
  return File(path).exists()
end

-- 列出目录下所有子目录
function M.listDirectories(path)
  -- 检查路径是否为空
  if not path or path == "" then
    return {}
  end
  
  import "java.io.File"
  local dir = File(path)
  
  -- 检查目录是否存在且确实是目录
  if not dir.exists() or not dir.isDirectory() then
    return {}
  end
  
  local files = dir.listFiles()
  -- 检查是否成功获取文件列表
  if not files then
    return {}
  end
  
  local dirs = {}
  for i = 0, #files-1 do
    local file = files[i]
    if file.isDirectory() then
      table.insert(dirs, file.getName())
    end
  end
  return dirs
end


-- 文件复制函数
function M.fileCopy(srcPath, dstPath)
    import "java.io.File"
    import "java.io.FileInputStream"
    import "java.io.FileOutputStream"
    
    -- 检查源文件是否存在
    local srcFile = File(srcPath)
    if not srcFile.exists() then
        print("错误: 源文件不存在 - " .. srcPath)
        return false
    end
    
    -- 检查是否是目录
    if srcFile.isDirectory() then
        print("错误: 源路径是目录，请使用copyDirectory函数 - " .. srcPath)
        return false
    end
    
    -- 创建目标文件的父目录
    local dstFile = File(dstPath)
    local parentDir = dstFile.getParentFile()
    if parentDir and not parentDir.exists() then
        if not parentDir.mkdirs() then
            print("错误: 无法创建目标目录 - " .. tostring(parentDir.getAbsolutePath()))
            return false
        end
    end
    
    -- 执行文件复制
    local success = false
    local input, output = nil, nil
    
    -- 使用重试机制
    local retry = 0
    while retry < 3 and not success do
        pcall(function()
            input = FileInputStream(srcFile)
            output = FileOutputStream(dstFile)
            
            local buffer = byte[1024]
            local length
            while true do
                length = input.read(buffer)
                if length <= 0 then break end
                output.write(buffer, 0, length)
            end
            
            success = true
        end)
        
        if not success then
            print("文件复制出错(尝试 " .. (retry + 1) .. ")")
            retry = retry + 1
            -- 等待一小段时间再重试
            os.execute("sleep 0.1")
        end
    end
    
    -- 确保流被关闭
    if input ~= nil then
        pcall(function() input.close() end)
    end
    if output ~= nil then
        pcall(function() output.close() end)
    end
    
    if not success then
        print("错误: 文件复制失败 - 从 " .. srcPath .. " 到 " .. dstPath)
        -- 删除可能已经创建的不完整文件
        if dstFile.exists() then
            dstFile.delete()
        end
    end
    
    return success
end
-- 目录复制函数
function M.copyDirectory(srcDir, dstDir)
    import "java.io.File"
    
    -- 检查源目录是否存在
    local srcFile = File(srcDir)
    if not srcFile.exists() then
        print("错误: 源目录不存在 - " .. srcDir)
        return false
    end
    
    if not srcFile.isDirectory() then
        print("错误: 源路径不是目录 - " .. srcDir)
        return false
    end
    
    -- 创建目标目录
    local dstFile = File(dstDir)
    if not dstFile.exists() and not dstFile.mkdirs() then
        print("错误: 无法创建目标目录 - " .. dstDir)
        return false
    end
    
    -- 获取目录内容
    local files = srcFile.listFiles()
    if not files then
        return true  -- 空目录
    end
    
    -- 复制每个文件/子目录
    for i = 0, #files - 1 do
        local file = files[i]
        local dest = File(dstFile, file.getName())
        
        if file.isDirectory() then
            if not M.copyDirectory(file.getAbsolutePath(), dest.getAbsolutePath()) then
                return false
            end
        else
            if not M.fileCopy(file.getAbsolutePath(), dest.getAbsolutePath()) then
                return false
            end
        end
    end
    
    return true
end










--------------选择文件---------------
function M.ChoiceFile(startPath, callback)
  -- 初始化UI组件
  local dialog = AlertDialog.Builder(activity)
  local listView = ListView(activity).setFastScrollEnabled(true)
  local pathLabel = TextView(activity)
  local adapter = ArrayAdapter(activity, android.R.layout.simple_list_item_1)

  -- 创建主布局
  local mainLayout = LinearLayout(activity)
  mainLayout.setOrientation(LinearLayout.VERTICAL)
  mainLayout.addView(pathLabel)
  mainLayout.addView(listView)

  -- 配置对话框
  dialog.setTitle("选择文件")
  .setView(mainLayout)
  .setNegativeButton("取消", nil)
  local fileDialog = dialog.show()
  listView.setAdapter(adapter)

  -- 文件排序比较函数
  local function fileComparator(a, b)
    if a.isDirectory() ~= b.isDirectory() then
      return a.isDirectory()
    end
    return a.Name:lower() < b.Name:lower()
  end

  -- 更新目录内容函数
  local function updateDirectory(currentPath)
    adapter.clear()
    pathLabel.Text = currentPath.getAbsolutePath()

    -- 添加返回上级目录
    if currentPath.getParent() then
      adapter.add("../")
    end

    -- 获取并处理文件列表
    local files = currentPath.listFiles() or {}
    files = luajava.astable(files)
    table.sort(files, fileComparator)

    for _, file in ipairs(files) do
      adapter.add(file.isDirectory() and file.Name.."/" or file.Name)
    end
  end

  -- 列表点击处理
  listView.onItemClick = function(_, view, position)
    local selectedName = tostring(view.Text)
    local currentDir = File(pathLabel.Text)
    local targetFile

    if selectedName == "../" then
      targetFile = currentDir.getParentFile()
     else
      -- 修正位置索引（考虑../项）
      local fileIndex = currentDir.getParent() and position or position - 1
      targetFile = File(currentDir, selectedName)
    end

    if targetFile.isDirectory() then
      updateDirectory(targetFile)
     elseif targetFile.isFile() then
      callback(targetFile.getAbsolutePath())
      fileDialog.dismiss()
    end
  end

  -- 初始化显示
  updateDirectory(File(startPath or "/"))

  -- 返回对话框对象以便外部控制
  return fileDialog
end
--ChoiceFile(Environment.getExternalStorageDirectory().toString(),callback)
--第一个参数为初始化路径,第二个为回调函数

return M