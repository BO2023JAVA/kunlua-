require "import"
require "kunlua"
import "android.os.Environment"

import "android.graphics.BitmapFactory"
import "layout.codepage_aly"
import "item.code_title_filelist_item"
import "item.code_title_list_item"
import "item.code_list_item"
import "item.file_aly"
import "init"
import "android.view.inputmethod.InputMethodManager"
import "android.graphics.drawable.ColorDrawable"
import "android.content.res.ColorStateList"
import "com.androlua.LuaUtil"
import "android.view.KeyEvent"
import "android.content.Context"
import "android.graphics.drawable.ColorDrawable"
import "android.view.WindowManager"
import "android.widget.PopupWindow"
import "android.graphics.*"

this.supportActionBar.hide()
--activity.setTheme(R.style.Theme_Material_NoActionBar_TranslucentDecor)
activity.setContentView(loadlayout(codepage_aly))
-- 导入您的pop模块
local popm = require ("script/popmin")
popup = require("script/pop")
--设置字体
local fontPath = activity.getLuaDir().."/assets/fonts/mono_bold.ttf"
local customFont = Typeface.createFromFile(fontPath)
title_text.setTypeface(customFont)
调试.setTypeface(customFont)
格式.setTypeface(customFont)
代码.setTypeface(customFont)
索引.setTypeface(customFont)
功能.setTypeface(customFont)
全选.setTypeface(customFont)
剪切.setTypeface(customFont)
复制.setTypeface(customFont)
粘贴.setTypeface(customFont)
代码块.setTypeface(customFont)

codeEdit
.setTypeface(customFont)
--.setBoldTypeface(Typeface)-- 设置粗体字体样式
--.setItalicTypeface(Typeface)-- 设置斜体字体样式
--.setTextSize(int)-- 设置字体大小（单位像素）
.setShowLineNumbers(true)-- 显示/隐藏行号栏
--.setHighlightCurrentRow(boolean)-- 高亮当前行
.setAutoIndentWidth(2)-- 设置自动缩进宽度
--.setNavigationMethod(v)-- 设置导航方式（触摸/键盘）
--.setColorScheme(c)-- 设置语法高亮配色方案
--.setEdited(boolean)-- 标记文档是否被修改
--.setSelection(int start, int end)-- 设置文本选中范围
--.setDocumentProvider(g)-- 设置文档数据提供器
--.setWordWrap(true)-- 启用/禁用自动换行（被子类覆盖）
--.setPanelBackgroundColor(0xffffffff)-- 设置侧边面板背景色
--.setPanelTextColor(0xFF8E96A9)-- 设置侧边面板文字颜色
--自定义
--.setWordWrap(false)-- 覆盖父类的自动换行设置
--.setDark(true)-- 切换暗黑模式
.setBackgroundDrawable(ColorDrawable(0xFF282C34)) --原生修改
.setBasewordColor(0xFFE96A71) --设置基础单词颜色（如局部变量）
.setTextColor(0xFFDCDFE4) -- 设置普通文本颜色。
.setKeywordColor(0xFFC674DC) -- 设置关键字颜色（如 Lua 的 `if`、`function`）。
.setCommentColor(0xFFB5BAC0) -- 设置注释颜色。
.setStringColor(0xFF6FB342) -- 设置字符串颜色。
.setTextHighlightColor(0xFF546FFE) -- 设置选中文本的高亮颜色。
.setUserwordColor(0xFF7B4DFF)-- 设置用户定义单词颜色

--.setText(CharSequence)-- 设置编辑器内容（无历史记录）
--.setText(CharSequence, boolean)-- 设置编辑器内容（可选是否记录历史）
--.setSelection(10)-- 移动光标到指定位置
--.setFilePath(String)-- 通过open()方法间接设置当前文件路径
.addNames({
  -- print
  [[print(v)]],[[print("")]],
  -- for
  [[for k,v in ipairs(tab) do
    print(v)
end]],[[for i = 1,10 do
   
end]],
  -- onClick
  [[onClick = function (v)

end]],

})-- 添加自动补全名称
--.addPackage(String, String[]) -- 添加代码包及其包含的名称
--removePackage(String) -- 移除指定代码包
--open(String) -- 打开指定路径文件
--save()  -- 保存到当前文件
--save(String)  -- 另存为指定路径
--undo()-- 撤销操作
--redo()  -- 重做操作
--findNext(String)-- 查找下一个匹配文本
--gotoLine() -- 显示跳转行对话框
--gotoLine(int)-- 跳转到指定行
--insert(int, String) -- 在指定位置插入文本  ]=]
----------------------------------
-- 在文件顶部定义所有控制变量（使用安全的命名）

local lastSelectTime = 0 -- 上次选择变化时间
local menuCooldown = 300 -- 菜单冷却时间(ms)
local selectDebounce = 50 -- 选择防抖时间(ms)
local programmaticSelect = false -- 是否程序触发的选择
local keyboardShown = false -- 输入法是否显示
local lastSelection = { -- 上次选择范围
  startPos = 0,
  endPos = 0,
}

-- 键盘状态检测和布局调整功能
import "android.graphics.Rect"
if Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT then
  -- 修改 Window 的软输入模式（放在 onCreate 或初始化部分）
  activity.getWindow().setSoftInputMode(
  WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN | -- 默认隐藏
  WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE -- 调整布局
  )
end

-- 添加键盘状态变化时的布局调整
local function checkKeyboard()
  local decorView = activity.getWindow().getDecorView()
  local rect = Rect()
  decorView.getWindowVisibleDisplayFrame(rect)
  local screenHeight = decorView.getHeight()
  local keyboardShown = (screenHeight - rect.bottom) > screenHeight * 0.15
  -- 计算需要上移的偏移量
  local offset = keyboardShown and -(screenHeight - rect.bottom) or 0
  -- 调整底部功能区位置
  右侧滑栏底部隐藏区.translationY = offset
  底部功能区.translationY = offset
  -- 调整代码编辑区高度
  local editLayoutParams = codeEdit.getLayoutParams()
  if keyboardShown then
    editLayoutParams.height = rect.height() - 底部功能区.getHeight() - 格式.getHeight() - 200
   else
    editLayoutParams.height = -1 -- MATCH_PARENT
  end
  codeEdit.setLayoutParams(editLayoutParams)
end
-- 全局布局监听器
local keyboardListener = ViewTreeObserver.OnGlobalLayoutListener {
  onGlobalLayout = checkKeyboard
}
activity.getWindow().getDecorView().getViewTreeObserver().addOnGlobalLayoutListener(keyboardListener)
function dp2px(dp)
  local metrics = activity.getResources().getDisplayMetrics()
  return math.floor(dp * metrics.density + 0.5)
end

-- 修改选择变化监听器，不再自动显示菜单
codeEdit.setOnSelectionChangedListener(function(selStart, selEnd)
  -- 更新最后选择范围
  lastSelection.startPos = codeEdit.getSelectionStart()
  lastSelection.endPos = codeEdit.getSelectionEnd()

  -- 跳过无效或程序触发的选择
  if programmaticSelect or selStart == selEnd then
    return
  end

  -- 防抖处理
  local currentTime = os.time()*1000
  if currentTime - lastSelectTime < selectDebounce then
    return
  end
  lastSelectTime = currentTime
end)



-- 关闭输入法的函数
local function hideKeyboard()
  local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
  local view = activity.getCurrentFocus()
  if view then
    imm.hideSoftInputFromWindow(view.getWindowToken(), 0)

  end
end

---------------------
--  文件处理
---------------------
local filesys = require("script.filesys")
-- 初始化存储路径
local project_path = Environment.getExternalStorageDirectory().toString().."/KunLua+/project/"
local backup_path = Environment.getExternalStorageDirectory().toString().."/KunLua+/backup/"
-- 接收项目名
local 项目名=...
title_text.text = 项目名;
local 私有目录 = project_path..项目名
-- 初始化
local 文件名flag = "main.lua"
local 打开的文件列表={"main.lua"} --初始化打开main
local 打开的文件内容={}
打开的文件内容["main.lua"] = filesys.fileRead(project_path..项目名.."/main.lua")
codeEdit.text = 打开的文件内容["main.lua"]

--全局变量来保存Ticker引用
local saveTicker = nil

----------撤销重做--------------
local MAX_UNDO_STEPS = 20 -- 最大撤销步数
local AUTO_SAVE_INTERVAL_MS = 1000 -- 自动保存间隔（毫秒）
local undoStacks = {} -- 撤销栈
local redoStacks = {} -- 重做栈
local lastSavedTexts = {}

-- 修改保存状态函数，增加防抖和优化
local lastSaveTime = 0
local SAVE_DEBOUNCE = 1000 -- 防抖时间(ms)
local function saveCurrentState()
  if not 文件名flag then return end

  -- 防抖处理
  local currentTime = os.time()*1000
  if currentTime - lastSaveTime < SAVE_DEBOUNCE then
    return
  end
  lastSaveTime = currentTime

  local currentText = codeEdit.text
  undoStacks[文件名flag] = undoStacks[文件名flag] or {}

  -- 只保存差异部分
  local lastState = undoStacks[文件名flag][#undoStacks[文件名flag]] or {}
  if lastState.text == currentText then
    return -- 内容未改变时不保存
  end

  -- 计算差异
  local diff = {}
  local len1, len2 = #(lastState.text or ""), #currentText
  local minLen = math.min(len1, len2)
  local startDiff = 1
  while startDiff <= minLen and lastState.text:sub(startDiff, startDiff) == currentText:sub(startDiff, startDiff) do
    startDiff = startDiff + 1
  end

  -- 如果有变化才保存
  if startDiff <= len1 or startDiff <= len2 then
    -- 限制历史记录长度
    if #(undoStacks[文件名flag] or {}) >= MAX_UNDO_STEPS then
      table.remove(undoStacks[文件名flag], 1)
    end

    table.insert(undoStacks[文件名flag], {
      text = currentText,
      diffPos = startDiff,
      oldText = lastState.text and lastState.text:sub(startDiff) or "",
      newText = currentText:sub(startDiff),
      selectionStart = codeEdit.getSelectionStart(),
    })

    -- 清空当前文件的重做栈
    redoStacks[文件名flag] = {}
  end
end
-- 修改定时保存的初始化部分
local function 启动定时保存()
  if saveTicker then
    saveTicker.stop()
    saveTicker = nil
  end

  -- 使用更高效的定时器实现
  saveTicker = Ticker()
  saveTicker.Period = AUTO_SAVE_INTERVAL_MS
  saveTicker.onTick = function()
    -- 只在有修改时保存
    if 文件名flag and (lastSavedTexts[文件名flag] ~= codeEdit.text) then
      saveCurrentState()
      filesys.fileWrite(私有目录.."/"..文件名flag, codeEdit.text)
      lastSavedTexts[文件名flag] = codeEdit.text
    end
  end
  saveTicker.start()
end

-- 添加退出清理函数
local function 清理退出()
  -- 停止定时保存
  if saveTicker then
    saveTicker.stop()
    saveTicker = nil
  end

  -- 保存当前文件
  if 文件名flag and codeEdit.text then
    filesys.fileWrite(私有目录.."/"..文件名flag, codeEdit.text)
  end

  -- 清空所有栈和缓存
  打开的文件列表 = {}
  打开的文件内容 = {}
  undoStacks = {}
  redoStacks = {}
  lastSavedTexts = {}
  文件名flag = nil

  -- 结束activity
  activity.finish()
end

-- 添加返回键监听
function onKeyDown(keyCode, event)

  if keyCode == KeyEvent.KEYCODE_BACK then

    local backLayout =
    {
      LinearLayout;
      layout_width='-1',
      layout_height='-1',
      Gravity="center";
      {
        CardView;
        radius='30dp',--圆角半径
        -- id='有描边的卡片',--控件ID
        layout_width='-2',
        layout_height='-2',
        layout_margin='8%w',--布局边距
        cardBackgroundColor='#FFEB9662',
        {
          CardView;
          radius='30dp',--圆角半径
          layout_width='-2',
          layout_height='-2',
          layout_margin="2dp";
          {
            LinearLayout;
            orientation="vertical";
            layout_width='80%w',
            layout_height='-1',
            Focusable=true,
            FocusableInTouchMode=true,
            layout_margin='8dp',--布局边距
            --    id='卡片背景动画',--控件ID
            {
              TextView;
              layout_width='-1',
              layout_height='-2',
              text="退出确认\n____________________";
              textSize="24sp";
              gravity='center',
              layout_marginTop='20dp',--布局顶距
              Typeface = customFont,
            },
            {
              TextView;
              layout_width='-1',
              layout_height='-2',
              textSize="16sp";
              layout_marginTop='20dp',--布局边距
              layout_marginLeft='20dp',--布局边距
              layout_marginRight='20dp',--布局边距
              text = "确定要退出编辑吗？";
              Typeface = customFont;
            },
            {
              LinearLayout;
              layout_width='-1',
              layout_height='-2',
              layout_marginTop='20dp',--布局边距
              layout_gravity='center',
              {
                CardView;
                layout_width="-1",
                layout_height="40dp",
                cardBackgroundColor='#FFEB9662',
                layout_margin='8dp',--布局边距
                radius='16dp',--圆角半径
                layout_weight='1',
                id='退出取消',--控件ID
                {
                  TextView;
                  text="取消";
                  layout_width='-2',
                  layout_height='-2',
                  textSize="16sp",
                  layout_gravity='center',
                };
              };
              {
                CardView;
                layout_width="-1",
                layout_height="40dp",
                cardBackgroundColor='#FFEB9662',
                layout_margin='8dp',--布局边距
                radius='16dp',--圆角半径
                layout_weight='1',
                id='退出确定',--控件ID
                {
                  TextView;
                  text="保存并退出";
                  layout_width='-2',
                  layout_height='-2',
                  textSize="16sp",
                  layout_gravity='center',
                };
              };
            };
          };
        };
      };
    };
    local popup = PopupWindow(activity)
    popup.setContentView(loadlayout(backLayout))
    popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
    popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
    popup.setFocusable(true)
    popup.setBackgroundDrawable(ColorDrawable(0x00000000))

    -- 设置窗口动画
    --popup.setAnimationStyle(android.R.style.Animation_Dialog)

    -- 显示弹窗
    popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)

    退出取消.onClick = function (v)
      popup.dismiss()
    end
    退出确定.onClick=function(v)
      清理退出()
      popup.dismiss()
    end
    return true
  end
  return false
end

-- 修改定时保存的启动方式
启动定时保存()

------------------------------------
--备份alp
local FileUtils = require "fun.ocss.FileUtils"
beifen.onClick = function(v)
  local 项目路径 = 私有目录.."/"
  local 备份目录 = backup_path
  local 时间戳 = os.date("-%m%d-%H-%M-%S")
  local 重命名 = 时间戳..".alp"
  FileUtils.zip(项目路径,备份目录)
  FileUtils.rename(备份目录..项目名..".zip", 备份目录..项目名..重命名)
  popm.tw("项目已备份:"..备份目录..项目名..重命名)
end


-- 初始化时改为按文件初始化
local function 撤销重做初始化()
  for _, filename in ipairs(打开的文件列表) do
    undoStacks[filename] = {
      {
        text = 打开的文件内容[filename] or "",
        selectionStart = 0,
        selectionEnd = 0
      }
    }
    redoStacks[filename] = {}
    lastSavedTexts[filename] = 打开的文件内容[filename] or ""
  end
end
撤销重做初始化()

-- 预加载图标
local DIR_ICON = activity.getLuaDir().."/res/img/file109.png"
local FILE_ICON = activity.getLuaDir().."/res/img/lua3.png"

-- 初始化文件适配器
function initFileAdapter()
  --侧滑栏初始化
  fileAdapter = LuaAdapter(activity, {}, file_aly)
  chl_lbx_list.Adapter = fileAdapter
  --打开的文件列表初始化
  newAdp_刷新打开的文件列表适配器 = LuaAdapter(activity, {} ,code_title_filelist_item)
  title_file_list.Adapter = newAdp_刷新打开的文件列表适配器
end

import "android.os.Handler"
import "android.os.Looper"
local handler = Handler()
-- 使用主线程的Looper创建Handler

function 刷新打开的文件列表适配器()
  newAdp_刷新打开的文件列表适配器.clear()

  for k,v in ipairs(打开的文件列表) do
    if 文件名flag == v then
      newAdp_刷新打开的文件列表适配器.add({
        title_file_list_text = {text=v, textColor=0xffffffff , Typeface = customFont },
        title_file_list_card = {cardBackgroundColor=0xFFEB9662}
      })
     else
      newAdp_刷新打开的文件列表适配器.add({
        title_file_list_text = {text=v, textColor=0xffffffff , Typeface = customFont },
        title_file_list_card = {cardBackgroundColor=0x00000000}
      })
    end
  end
  title_file_list.Adapter = newAdp_刷新打开的文件列表适配器

  title_file_list.onItemClick = function(l,v,p,i)
    -- 保存当前状态
    local oldFile = 文件名flag
    文件名flag = 打开的文件列表[i]

    -- 立即请求焦点（关键步骤1）
    codeEdit.requestFocus()

    -- 延迟确保焦点生效（关键步骤2）
    handler.postDelayed(function()
      -- 切换文件内容
      if oldFile then
        打开的文件内容[oldFile] = tostring(codeEdit.text)
      end
      codeEdit.setText(打开的文件内容[文件名flag] or "")

     -- 恢复光标位置
      if undoStacks[文件名flag] and #undoStacks[文件名flag] > 0 then
        local lastState = undoStacks[文件名flag][#undoStacks[文件名flag]]
        codeEdit.setSelection(lastState.selectionStart)
      end

      刷新打开的文件列表适配器()
      handler.postDelayed(function()
        codeEdit.clearFocus()
        codeEdit.requestFocus()
        local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
        imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0)
      end, 150)
    end, 50) -- 50ms延迟确保UI线程处理完成
  end
end

local 更多Menu = {
  ["关闭"] = function()
    local fileName = 打开的文件列表[openfile]
    -- 保存当前文件内容
    打开的文件内容[文件名flag] = tostring(codeEdit.text)
    -- 从列表中移除文件
    table.remove(打开的文件列表, openfile)
    -- 处理当前活动文件被关闭的情况
    if fileName == 文件名flag then
      -- 优先尝试切换到左侧文件
      local newIndex = math.max(1, math.min(openfile-1, #打开的文件列表))
      if #打开的文件列表 > 0 then
        文件名flag = 打开的文件列表[newIndex]
        codeEdit.text = 打开的文件内容[文件名flag] or ""
       else
        -- 没有其他打开的文件，打开默认文件
        文件名flag = "main.lua"
        local defaultContent = filesys.fileRead(私有目录.."/main.lua") or ""
        codeEdit.text = defaultContent
        打开的文件内容[文件名flag] = defaultContent
        table.insert(打开的文件列表, 文件名flag)
      end
    end
    刷新打开的文件列表适配器()
  end,

  ["全部关闭"] = function()
    打开的文件列表={} --初始化打开main
    文件名flag = "main.lua"
    local defaultContent = filesys.fileRead(私有目录.."/main.lua") or ""
    codeEdit.text = defaultContent
    打开的文件内容[文件名flag] = defaultContent
    table.insert(打开的文件列表, 文件名flag)
    刷新打开的文件列表适配器()
  end,
}
-- 添加长按菜单功能
title_file_list.onItemLongClick = function(l,v,p,i)
  openfile = i
  popup.show(更多Menu,title_file_list,"文件操作")
  return true
end


function 刷新侧滑栏列表适配器(currentPath)
  -- 确保路径始终以分隔符结尾
  import "java.io.File"
  local function normalizePath(path)
    return path:gsub("[\\/]$", "")..File.separator -- 移除末尾分隔符后重新添加
  end
  -- 存当前文件夹路径（规范化处理）
  currentDirPath = normalizePath(currentPath or 私有目录.."/")

  -- 获取规范化的项目根目录路径
  local projectRootFile = File(私有目录.."/")
  canonicalProjectRoot = normalizePath(projectRootFile.getCanonicalPath())

  -- 强制路径在项目范围内
  local currentFile = File(currentDirPath)
  local canonicalCurrent = normalizePath(currentFile.getCanonicalPath())

  -- 路径越界检查
  if not (canonicalCurrent:find(canonicalProjectRoot, 1, true) == 1) then
    popm.tw("路径越界，已重置到项目根目录")
    currentDirPath = canonicalProjectRoot
    currentFile = File(currentDirPath)
    canonicalCurrent = currentDirPath
  end

  -- 有效性检查
  if not currentFile.exists() or not currentFile.isDirectory() then
    currentPath = canonicalProjectRoot
    currentFile = File(currentPath)
  end

  fileAdapter.clear()

  -- 添加返回上级（智能显示）
  local parent = currentFile.getParent()
  if parent then
    local parentCanonical = File(parent).getCanonicalPath()..File.separator
    -- 允许返回项目根目录的上级，但限制导航
    if parentCanonical:find(canonicalProjectRoot, 1, true) or canonicalProjectRoot:find(parentCanonical, 1, true) then
      fileAdapter.add({
        img_icon = {src = DIR_ICON, ColorFilter=0xFFEEEEEE},
        chl_file_list_text = {text = "返回上一层", textColor = 0xFFEEEEEE, Typeface = customFont},
      })
    end
  end

  -- 获取并处理文件列表
  local files = {}
  pcall(function()
    files = luajava.astable(currentFile.listFiles() or {})
    -- 增强排序：目录优先且按名称排序
    table.sort(files, function(a,b)
      if a.isDirectory() == b.isDirectory() then
        return a.Name:lower() < b.Name:lower()
      end
      return a.isDirectory()
    end)
  end)

  -- 填充适配器（带安全检查）
  for _, f in ipairs(files) do
    local isDir = f.isDirectory()
    local fileCanonical = f.getCanonicalPath()..(isDir and File.separator or "")

    -- 严格子路径检查
    if fileCanonical:find(canonicalProjectRoot, 1, true) == 1 then
      fileAdapter.add({
        img_icon = {src = isDir and DIR_ICON or FILE_ICON, ColorFilter=0xFFEEEEEE },
        chl_file_list_text = {
          text = isDir and f.Name.."/" or f.Name,
          textColor = 0xFFEEEEEE,
          Typeface = customFont,
        }
      })
    end
  end

  chl_lbx_list.onItemClick = function(_, view, pos)
    -- 保存当前编辑内容
    if 文件名flag and codeEdit.text then
      打开的文件内容[文件名flag] = tostring(codeEdit.text)
    end

    local item = fileAdapter.getItem(pos)
    local fileName = item.chl_file_list_text.text:gsub("/$", "")

    -- 处理导航
    if fileName == "返回上一层" then
      local parentFile = currentFile.getParentFile()
      if parentFile then
        刷新侧滑栏列表适配器(parentFile.getAbsolutePath())
      end
     else
      local target = File(currentFile, fileName)
      local targetCanonical = target.getCanonicalPath()..(target.isDirectory() and File.separator or "")

      if target.isDirectory() then
        刷新侧滑栏列表适配器(target.getAbsolutePath())
       else
        -- 文件打开逻辑

        if not undoStacks[文件名flag] then
          undoStacks[文件名flag] = {content}
          redoStacks[文件名flag] = {}
          lastSavedTexts[文件名flag] = content
        end

        local relativePath = targetCanonical:sub(canonicalProjectRoot:len() + 1)
        文件名flag = relativePath

        local success, content = pcall(filesys.fileRead, targetCanonical)
        if success then
          -- 检查是否已在打开列表中
          local alreadyOpen = false
          for _,v in ipairs(打开的文件列表) do
            if v == 文件名flag then
              alreadyOpen = true
              break
            end
          end

          if not alreadyOpen then
            -- 新打开文件插入到列表首位
            table.insert(打开的文件列表, 1, 文件名flag)
            打开的文件内容[文件名flag] = content
          end

          codeEdit.text = 打开的文件内容[文件名flag]
          刷新打开的文件列表适配器()
         else
          print("读取失败："..content)
        end
      end
    end
  end

  -- 侧滑栏添加长按监听
  chl_lbx_list.onItemLongClick = function(_, view, pos, id)
    print("长按位置 pos="..pos)

    -- 检测当前长按的文件对象
    local targetFile = files[pos]
    if targetFile then
      print("目标文件："..targetFile.getName())

      -- 检查是否为受保护文件（不可删除的关键文件）
      local protectedFiles = {"main.lua", "init.lua", "layout.aly"}
      local isProtected = false

      for _, protectedFile in ipairs(protectedFiles) do
        if targetFile.getName() == protectedFile then
          isProtected = true
          break
        end
      end

      if isProtected then
        popm.tw("此文件为系统关键文件，不可删除或重命名")
        return true
      end
    end

    currentDirPath = currentPath
    local projectRootFile = File(私有目录)
    local canonicalProjectRoot = projectRootFile.getCanonicalPath()..File.separator
    currentPath = currentPath or canonicalProjectRoot
    local currentDir = File(currentPath)

    -- 处理父目录项
    local hasParent = currentDir.getParent() ~= nil
    if hasParent then
      if pos == 0 then return true end
      pos = pos - 1
    end

    -- 获取文件列表
    local files = luajava.astable(currentDir.listFiles() or {})
    table.sort(files, function(a,b)
      if a.isDirectory() == b.isDirectory() then
        return a.Name:lower() < b.Name:lower()
      end
      return a.isDirectory()
    end)

    -- 确保调整后的pos在有效范围内
    if pos < 0 or pos >= #files then return true end

    local targetFile = files[pos+1]
    if not targetFile then return true end

    -- 获取文件的相对路径
    local targetRelativePath = targetFile.getCanonicalPath():sub(canonicalProjectRoot:len() + 1)

    -- 创建菜单项
    local 文件操作Menu = {
      ["删除"] = function()
        -- 如果是文件夹且非空，询问是否强制删除
        if targetFile.isDirectory() and #luajava.astable(targetFile.listFiles() or {}) > 0 then
          AlertDialog.Builder(activity)
          .setTitle("文件夹非空")
          .setMessage("该文件夹包含文件，确定要强制删除吗？")
          .setPositiveButton("强制删除", function()
            强制删除文件夹(targetFile, targetRelativePath)
          end)
          .setNegativeButton("取消", nil)
          .show()
         else
          -- 普通删除
          local success, err = pcall(function()
            if not targetFile.delete() then
              error("删除失败")
            end
          end)

          if success then
            处理删除后操作(targetFile, targetRelativePath)
            popm.tw("删除成功")
           else
            popm.tw("删除失败: "..tostring(err))
          end
        end
      end,

      ["强制删除"] = function()
        -- 直接强制删除
        强制删除文件夹(targetFile, targetRelativePath)
      end,
      ["重命名"] = function()
        local renameDialogView =
        {
          LinearLayout;
          layout_width='-1',
          layout_height='-1',
          Gravity = "center";
          {
            CardView;
            radius='30dp',--圆角半径
            -- id='有描边的卡片',--控件ID
            layout_width='-2',
            layout_height='-2',
            layout_margin='8%w',--布局边距
            cardBackgroundColor='#FFEB9662',
            {
              CardView;
              radius='30dp',--圆角半径
              layout_width='-2',
              layout_height='-2',
              layout_margin="2dp";
              {
                LinearLayout;
                orientation="vertical";
                layout_width='80%w',
                layout_height='-1',
                Focusable=true,
                FocusableInTouchMode=true,
                layout_margin='8dp',--布局边距
                --    id='卡片背景动画',--控件ID
                {
                  TextView;
                  layout_width='-1',
                  layout_height='-2',
                  text="重命名\n____________________";
                  textSize="24sp";
                  gravity='center',
                  layout_marginTop='20dp',--布局顶距
                  Typeface = customFont,
                },
                {
                  TextView;
                  layout_width='-1',
                  layout_height='-2',
                  text="当前名称: "..targetFile.Name;
                  textSize="15sp",
                  layout_marginLeft='20dp',--布局左距
                  layout_marginTop='10dp',--布局顶距
                },
                {
                  EditText;
                  hint="输入新名称";
                  text=targetFile.Name;
                  singleLine=true;--设置单行输入
                  id='new_name',--控件ID
                  layout_width='-1',
                  layout_height='-2',
                  Typeface = customFont,
                  focusable = true,
                  focusableInTouchMode=true, -- 阻止子控件自动获取焦点
                },
                {
                  LinearLayout;
                  layout_width='-1',
                  layout_height='-2',
                  layout_gravity='center',
                  layout_marginTop='15dp',--布局顶距
                  {
                    CardView;
                    layout_width="-1",
                    layout_height="40dp",
                    cardBackgroundColor='#FFEB9662',
                    layout_margin='8dp',--布局边距
                    radius='16dp',--圆角半径
                    layout_weight='1',
                    id='重命名返回',--控件ID
                    {
                      TextView;
                      text="返回";
                      layout_width='-2',
                      layout_height='-2',
                      textSize="16sp",
                      layout_gravity='center',
                    }
                  };
                  {
                    CardView;
                    layout_width="-1",
                    layout_height="40dp",
                    layout_weight='1',
                    cardBackgroundColor='#FFEB9662',
                    layout_margin='8dp',--布局边距
                    radius='16dp',--圆角半径
                    id='重命名确定',--控件ID
                    {
                      TextView;
                      text="确定";
                      layout_width='-2',
                      layout_height='-2',
                      textSize="16sp",
                      layout_gravity='center',
                    };
                  };
                };
              };
            };
          };
        };
        local popup = PopupWindow(activity)
        popup.setContentView(loadlayout(renameDialogView))
        popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
        popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
        popup.setFocusable(true)
        popup.setBackgroundDrawable(ColorDrawable(0x00000000))
        -- 设置窗口动画
        popup.setAnimationStyle(android.R.style.Animation_Dialog)
        -- 显示弹窗（替换原来的 tc.show()）
        popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)

        重命名确定.onClick = function(v)
          local newName = new_name.text
          if newName == "" then
            popm.tw("名称不能为空")
            return
          end

          -- 如果是文件且没有扩展名，自动添加原扩展名
          if not targetFile.isDirectory() and not newName:match("%..+$") then
            local _, ext = targetFile.Name:match("(.+)(%..+)$")
            if ext then
              newName = newName .. ext
            end
          end

          -- 检查新文件名是否与旧文件名相同
          if newName == targetFile.Name then
            popm.tw("新名称与旧名称相同")
            return
          end

          local newFile = File(targetFile.getParent(), newName)

          -- 检查目标文件是否已存在
          if newFile.exists() then
            popm.tw("名称已存在，请使用其他名称")
            return
          end

          -- 检查是否已在打开的文件列表中
          local isOpen = false
          local openIndex = 0
          for i,v in ipairs(打开的文件列表) do
            if v == targetRelativePath then
              isOpen = true
              openIndex = i
              break
            end
          end

          local success, err = pcall(function()
            if not targetFile.renameTo(newFile) then
              error("重命名失败")
            end
          end)

          if success then
            -- 获取新文件的相对路径
            local newRelativePath = newFile.getCanonicalPath():sub(canonicalProjectRoot:len() + 1)

            -- 更新打开的文件列表和内容
            if isOpen then
              -- 更新打开的文件列表
              打开的文件列表[openIndex] = newRelativePath

              -- 更新文件内容缓存
              打开的文件内容[newRelativePath] = 打开的文件内容[targetRelativePath] or ""
              打开的文件内容[targetRelativePath] = nil

              -- 如果重命名的是当前文件
              if 文件名flag == targetRelativePath then
                文件名flag = newRelativePath
                codeEdit.text = 打开的文件内容[newRelativePath]
              end
            end

            -- 刷新界面
            刷新打开的文件列表适配器()
            刷新侧滑栏列表适配器(currentDirPath)
            popm.tw("重命名成功")
           else
            popm.tw("重命名失败")
          end
          popup.dismiss()
        end
        重命名返回.onClick = function (v)
          popup.dismiss()
        end
      end
    }
    -- 如果是文件夹，添加"强制删除"选项
    if targetFile.isDirectory() then
      文件操作Menu["强制删除"] = 文件操作Menu["强制删除"]
    end
    -- 显示菜单
    popup.show(文件操作Menu, view, "文件操作")
    return true
  end
end


-- 在文件删除操作中添加更彻底的清理逻辑
function 强制删除文件夹(folder, folderRelativePath)
  local success, err = pcall(function()
    -- 递归删除文件夹内容
    local function deleteRecursive(file)
      if file.isDirectory() then
        for _, child in ipairs(luajava.astable(file.listFiles() or {})) do
          deleteRecursive(child)
        end
      end
      if not file.delete() then
        error("删除失败: "..file.getName())
      end
    end

    deleteRecursive(folder)
  end)

  if success then
    -- 检查并关闭所有子文件的打开项
    local toRemove = {}
    for i,v in ipairs(打开的文件列表) do
      if v:find(folderRelativePath, 1, true) == 1 then
        table.insert(toRemove, i)
        -- 彻底清理相关数据
        打开的文件内容[v] = nil
        undoStacks[v] = nil
        redoStacks[v] = nil
        lastSavedTexts[v] = nil
      end
    end

    -- 从后往前删除，避免索引错位
    for i=#toRemove,1,-1 do
      table.remove(打开的文件列表, toRemove[i])
    end

    -- 如果当前文件被删除
    if 文件名flag and 文件名flag:find(folderRelativePath, 1, true) == 1 then
      if #打开的文件列表 > 0 then
        文件名flag = 打开的文件列表[1]
        codeEdit.text = 打开的文件内容[文件名flag] or ""
       else
        -- 重置为初始状态
        文件名flag = "main.lua"
        local defaultContent = filesys.fileRead(私有目录.."/main.lua") or ""
        codeEdit.text = defaultContent
        -- 重新初始化main.lua的状态
        打开的文件内容 = {["main.lua"] = defaultContent}
        打开的文件列表 = {"main.lua"}
        undoStacks = {["main.lua"] = {defaultContent}}
        redoStacks = {["main.lua"] = {}}
        lastSavedTexts = {["main.lua"] = defaultContent}
      end
    end

    刷新打开的文件列表适配器()
    新侧滑栏列表适配器(currentDirPath)
    popm.tw("强制删除成功")
   else
    popm.tw("强制删除失败："..tostring(err))
  end
end

-- 修改初始化部分，确保每次启动都从干净状态开始
local function 初始化项目状态()
  -- 重置所有状态变量
  文件名flag = "main.lua"
  打开的文件列表 = {"main.lua"}
  打开的文件内容 = {}
  undoStacks = {}
  redoStacks = {}
  lastSavedTexts = {}

  -- 读取main.lua内容
  local mainContent = filesys.fileRead(私有目录.."/main.lua") or ""
  打开的文件内容["main.lua"] = mainContent
  codeEdit.text = mainContent

  -- 初始化撤销重做栈
  撤销重做初始化()
end

-- 在activity启动时调用初始化
初始化项目状态()
-- 处理删除后的通用操作
function 处理删除后操作(targetFile, targetRelativePath)
  刷新侧滑栏列表适配器(currentDirPath)

  -- 检查是否在打开的文件列表中
  local isOpen = false
  local openIndex = 0
  for i,v in ipairs(打开的文件列表) do
    if v == targetRelativePath then
      isOpen = true
      openIndex = i
      break
    end
  end

  -- 如果删除的是打开的文件
  if isOpen then
    -- 从打开列表中移除
    table.remove(打开的文件列表, openIndex)

    -- 从内容缓存和撤销重做栈中移除
    打开的文件内容[targetRelativePath] = nil
    undoStacks[targetRelativePath] = nil
    redoStacks[targetRelativePath] = nil
    lastSavedTexts[targetRelativePath] = nil

    -- 如果删除的是当前文件
    if 文件名flag == targetRelativePath then
      if #打开的文件列表 > 0 then
        文件名flag = 打开的文件列表[1]
        codeEdit.text = 打开的文件内容[文件名flag] or ""
       else
        文件名flag = "main.lua"
        codeEdit.text = filesys.fileRead(私有目录.."/main.lua") or ""
        -- 初始化main.lua的撤销重做栈
        undoStacks[文件名flag] = {codeEdit.text}
        redoStacks[文件名flag] = {}
        lastSavedTexts[文件名flag] = codeEdit.text
      end
    end

    刷新打开的文件列表适配器()
  end
end




-- 初始化并刷新
initFileAdapter()
刷新侧滑栏列表适配器()
刷新打开的文件列表适配器()

----------------------------------


-- 修改撤销操作
function chexiao.onClick()
  if not 文件名flag or not undoStacks[文件名flag] then return end
  
  if #undoStacks[文件名flag] > 1 then
    local lastState = table.remove(undoStacks[文件名flag])
    table.insert(redoStacks[文件名flag], lastState)
    local prevState = undoStacks[文件名flag][#undoStacks[文件名flag]]
    -- 恢复文本和光标位置
    codeEdit.setText(prevState.text)
    codeEdit.setSelection(prevState.selectionStart)
    lastSavedTexts[文件名flag] = prevState.text
  end

end
-- 修改重做操作
function chongzuo.onClick()
  if not 文件名flag or not redoStacks[文件名flag] then return end

  if #redoStacks[文件名flag] > 0 then
    local nextState = table.remove(redoStacks[文件名flag])
    undoStacks[文件名flag] = undoStacks[文件名flag] or {}
    table.insert(undoStacks[文件名flag], nextState)
    -- 恢复文本和光标位置
    codeEdit.setText(nextState.text)
    codeEdit.setSelection(nextState.selectionStart)
    lastSavedTexts[文件名flag] = nextState.text
  end
end
------------------------------------------------

--侧滑栏按钮cehua1
cehua1.onClick = function(v)
  chlMain.openDrawer(3) -- 开左
  hideKeyboard()
end

menu.onClick = function(v)
  chlMain.openDrawer(5) -- 开右
  hideKeyboard()
end
右侧滑栏底部隐藏区.onClick = function(v)
  chlMain.closeDrawer(5) -- 关
  hideKeyboard()
end

add_file.onClick = function (v)
  -- 获取当前目录路径（在刷新侧滑栏时更新）
  local currentDir = currentDirPath or 私有目录.."/"

  -- 构建对话框布局
  local newfilewin =
  {
    LinearLayout;
    layout_width='-1',
    layout_height='-1',
    Gravity="center",
    {
      CardView;
      radius='30dp',--圆角半径
      -- id='有描边的卡片',--控件ID
      layout_width='-2',
      layout_height='-2',
      layout_margin='8%w',--布局边距
      cardBackgroundColor='#FFEB9662',
      {
        CardView;
        radius='30dp',--圆角半径
        layout_width='-2',
        layout_height='-2',
        layout_margin="2dp";
        {
          LinearLayout;
          orientation="vertical";
          layout_width='-1',
          layout_height='-1',
          Focusable=true,
          FocusableInTouchMode=true,
          layout_margin='8dp',--布局边距
          id='卡片背景动画2',--控件ID
          {
            TextView;
            layout_width='-1',
            layout_height='-2',
            text="新建文件\n____________________";
            textSize="24sp";
            gravity='center',
            layout_marginTop='20dp',--布局顶距
            Typeface = customFont,
          },
          {
            TextView;
            id="prompt",
            textSize="15sp",
            layout_marginTop="10dp";
            layout_marginLeft="20dp",
            layout_marginRight="20dp",
            text="当前路径: "..currentDir;
          };
          {
            TextView,
            text="文件名或文件夹名:",
            layout_marginTop="40dp";
            layout_marginLeft="20dp",
            textSize="16sp",
          };
          {
            EditText;
            hint="请输入";
            layout_marginLeft="3dp",
            layout_width="68%w";
            layout_gravity="center";
            singleLine=true;--设置单行输入
            id="new_file";
          };
          {
            LinearLayout;
            layout_width='-1',
            layout_height='-2',
            layout_gravity='center',
            layout_marginTop='15dp',--布局顶距
            {
              CardView;
              layout_width="-1",
              layout_height="40dp",
              cardBackgroundColor='#FFEB9662',
              layout_margin='8dp',--布局边距
              radius='16dp',--圆角半径
              layout_weight='1',
              id='新建文件',--控件ID
              {
                TextView;
                text="新建文件";
                layout_width='-2',
                layout_height='-2',
                textSize="16sp",
                layout_gravity='center',
              }
            };
            {
              CardView;
              layout_width="-1",
              layout_height="40dp",
              layout_weight='1',
              cardBackgroundColor='#FFEB9662',
              layout_margin='8dp',--布局边距
              radius='16dp',--圆角半径
              id='新建文件夹',--控件ID
              {
                TextView;
                text="新建文件夹";
                layout_width='-2',
                layout_height='-2',
                textSize="16sp",
                layout_gravity='center',
              };
            };
          };
        };
      };
    };
  };

  local popup = PopupWindow(activity)
  popup.setContentView(loadlayout(newfilewin))
  popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setFocusable(true)
  popup.setBackgroundDrawable(ColorDrawable(0x00000000))

  -- 设置窗口动画
  popup.setAnimationStyle(android.R.style.Animation_Dialog)

  -- 显示弹窗
  popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)

  新建文件夹.onClick = function(v)
    local name = new_file.text

    if name:match("^[%w_%-%. ]+$") and name ~= "" then
      local File = luajava.bindClass("java.io.File")
      local targetDir = File(currentDir)
      local newDir = File(targetDir, name)
      if newDir.mkdir() then
        刷新侧滑栏列表适配器(currentDir) -- 刷新显示
       else
        popm.tw("创建文件夹失败，请检查权限")
      end
     else
      popm.tw("名称包含非法字符或为空")
    end
    popup.dismiss()
  end

  新建文件.onClick = function(v)
    local name = new_file.text

    if name == "" then
      popm.tw("名称不能为空")
      return
    end
    -- 自动添加.lua扩展名
    if not name:match(".*()%.%w+$") then
      name = name .. ".lua"
    end

    local targetDir = File(currentDir) -- 已确保带分隔符
    local newFile = File(targetDir, name)
    if newFile.createNewFile() then
      local relativePath = newFile.getCanonicalPath():sub(canonicalProjectRoot:len() + 1)
      刷新侧滑栏列表适配器(currentDir) -- 刷新显示
      -- 自动打开新创建的文件
      文件名flag = relativePath
      if not 打开的文件内容[文件名flag] then
        打开的文件内容[文件名flag] = filesys.fileRead(newFile.getPath()) or ""
        table.insert(打开的文件列表, 1, 文件名flag)
      end
      codeEdit.text = 打开的文件内容[文件名flag]

      刷新打开的文件列表适配器()
     else
      popm.tw("创建文件失败，可能已存在")
    end
    print("当前目录："..currentDirPath)
    print("目标文件："..newFile.getAbsolutePath())
    popup.dismiss()
  end
end

-- 初始化调试开关状态
local function 初始化调试开关()
  -- 读取init.lua文件内容
  local initFile = 私有目录.."/init.lua"
  local content = filesys.fileRead(initFile) or ""
  -- 检查debugmode的值
  local debugmode = content:match("debugmode%s*=%s*(%w+)")
  -- require "fun.ocss.debug"
  if debugmode then
    调试.checked = debugmode == "true"
   else
    -- 如果不存在debugmode设置，默认为false
    调试.checked = false
  end
end

-- 在界面初始化时调用
初始化调试开关()

--运行预览
yunxing.onClick = function ()
  local success,a = pcall(saveCurrentState)
  if success then
    activity.newActivity(私有目录.."/main.lua") --跳到对应工程名的main
  end
end

调试.setOnCheckedChangeListener{
  onCheckedChanged=function(buttonView, isChecked)
    -- 1. 检查并关闭已打开的init.lua文件
    local initOpenIndex = nil
    for i, filename in ipairs(打开的文件列表) do
      if filename == "init.lua" then
        initOpenIndex = i
        break
      end
    end

    -- 如果init.lua已打开，先关闭它
    if initOpenIndex then
      -- 保存当前文件内容
      if 文件名flag then
        打开的文件内容[文件名flag] = tostring(codeEdit.text)
      end

      -- 从打开列表中移除init.lua
      table.remove(打开的文件列表, initOpenIndex)

      -- 清理相关数据
      打开的文件内容["init.lua"] = nil
      undoStacks["init.lua"] = nil
      redoStacks["init.lua"] = nil
      lastSavedTexts["init.lua"] = nil

      -- 如果当前正在编辑的就是init.lua，切换到其他文件
      if 文件名flag == "init.lua" then
        if #打开的文件列表 > 0 then
          文件名flag = 打开的文件列表[1] or "main.lua"
          codeEdit.text = 打开的文件内容[文件名flag] or ""
         else
          文件名flag = "main.lua"
          local defaultContent = filesys.fileRead(私有目录.."/main.lua") or ""
          codeEdit.text = defaultContent
          打开的文件内容[文件名flag] = defaultContent
          table.insert(打开的文件列表, 文件名flag)
        end
      end

      刷新打开的文件列表适配器()
    end

    -- 2. 读取并修改init.lua文件内容
    local initFile = 私有目录.."/init.lua"
    local content = filesys.fileRead(initFile) or ""

    -- 修改debugmode值
    if isChecked then
      -- 设置为true
      if content:find("debugmode%s*=") then
        content = content:gsub("debugmode%s*=%s*[%w]+", "debugmode=true")
       else
        -- 确保添加到app表中
        if content:find("app%s*=%s*%b{}") then
          content = content:gsub("(app%s*=%s*%b{})", "%1\ndebugmode=true,")
         else
          content = content.."\ndebugmode=true"
        end
      end
     else
      -- 设置为false
      if content:find("debugmode%s*=") then
        content = content:gsub("debugmode%s*=%s*[%w]+", "debugmode=false")
       else
        -- 确保添加到app表中
        if content:find("app%s*=%s*%b{}") then
          content = content:gsub("(app%s*=%s*%b{})", "%1\ndebugmode=false,")
         else
          content = content.."\ndebugmode=false"
        end
      end
    end

    -- 3. 写回文件
    local success, err = pcall(function()
      filesys.fileWrite(initFile, content)

      -- 如果文件之前是打开的，重新加载内容到内存但不重新打开
      if initOpenIndex then
        打开的文件内容["init.lua"] = content
        undoStacks["init.lua"] = {content}
        redoStacks["init.lua"] = {}
        lastSavedTexts["init.lua"] = content
      end
    end)

    if success then
      popm.tw("调试模式已"..(isChecked and "开启" or "关闭"))
     else
      popm.tw("操作失败: "..tostring(err))
      调试.checked = not isChecked -- 回滚状态
    end
  end
}

-----------------------------------
--快捷代码按钮
local 快捷代码列表 = {"设置布局场景","私有目录","SD卡路径","跳转界面","跳转界面传参",
  "跳转界面动画","Toast提示","设置标题","设置主题","关闭界面","关闭程序","重构界面","屏幕高度",
  "屏幕宽度","关闭全屏","设置全屏","设置全屏异形屏","屏幕方向","隐藏状态栏",
  "程序最小化","沉浸状态栏","播放音频","播放视频"}

local 快捷代码列表项 = {
  设置布局场景 = [[activity.setContentView(loadlayout(layout))]],
  私有目录 = [[activity.getLuaDir()]],
  SD卡路径 = [[Environment.getExternalStorageDirectory().toString()]],
  跳转界面 = [[activity.newActivity("main")]],
  跳转界面传参 = [[activity.newActivity("main",{"参数"})]],
  跳转界面动画 = [[activity.newActivity("main",android.R.anim.fade_in,android.R.anim.fade_out,{"参数"})]],
  Toast提示 = [[Toast.makeText(activity, "Toast",Toast.LENGTH_SHORT).show()]],
  设置标题 = [[activity.setTitle('Kunlua')]],
  设置主题 = [[activity.setTheme(android.R.style.Theme_DeviceDefault_Light)]],
  关闭界面 = [[activity.finish()]],
  关闭程序 = [[os.exit()]],
  重构界面 = [[activity.recreate()]],
  屏幕高度 = [[activity.getHeight()]],
  屏幕宽度 = [[activity.getWidth()]],
  关闭全屏 = [[activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)]],
  设置全屏 = [[activity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN)]],
  设置全屏异形屏 = [[local window = activity.getWindow();
window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
xpcall(function()
  lp = window.getAttributes();
  lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
  window.setAttributes(lp);
end,function(e)end)

--可能需要隐藏ActionBar
]],
  屏幕方向 = [[activity.setRequestedOrientation(0) --横屏0--竖屏1]],
  隐藏状态栏 = [[activity.getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN)]],
  程序最小化 = [[import "android.content.Intent"
intent=Intent();
intent.setAction("android.intent.action.MAIN");
intent.addCategory("android.intent.category.HOME");
activity.startActivity(intent)
]],
  沉浸状态栏 = [[if Build.VERSION.SDK_INT >= 21 then activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xff4285f4) end
if Build.VERSION.SDK_INT >= 19 then activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS) end
]],
  播放音频 = [[import "android.media.MediaPlayer"
mediaPlayer =  MediaPlayer()

--初始化参数
mediaPlayer.reset()

--设置播放资源
mediaPlayer.setDataSource("storage/sdcard0/a.mp3")

--开始缓冲资源
mediaPlayer.prepare()

--是否循环播放该资源
mediaPlayer.setLooping(true)

--缓冲完成的监听
mediaPlayer.setOnPreparedListener(MediaPlayer.OnPreparedListener() {
    onPrepared=function(mediaPlayer)
        mediaPlayer.start()
   end});

--是否在播放
mediaPlayer.isPlaying()

--暂停播放
mediaPlayer.pause()

--从30位置开始播放
mediaPlayer.seekTo(30)

--停止播放
mediaPlayer.stop()

]],

  播放视频 = [[import "android.media.MediaPlayer"
mediaPlayer =  MediaPlayer()
--初始化参数
mediaPlayer.reset()

--设置播放资源
mediaPlayer.setDataSource("storage/sdcard0/a.mp4")

--获取SurfaceView
sh = surfaceView.getHolder()
sh.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS)

--设置显示SurfaceView
mediaPlayer.setDisplay(sh)

--设置音频流格式
mediaPlayer.setAudioStreamType(AudioManager.Stream_Music)

--开始缓冲资源
mediaPlayer.prepare()

--缓冲完成的监听
mediaPlayer.setOnPreparedListener(MediaPlayer.OnPreparedListener{
   onPrepared=function(mediaPlayer)
		--开始播放
        mediaPlayer.start()
   end
});

--释放播放器
mediaPlayer.release()
]],

}

代码按钮.onClick = function()
  hideKeyboard()
  代码layout = {
    LinearLayout;
    layout_width='-1',
    layout_height='-1',
    Gravity="center";
    {
      CardView;
      radius='30dp',--圆角半径
      -- id='有描边的卡片',--控件ID
      layout_width='-2',
      layout_height='-2',
      layout_margin='8dp',--布局边距
      cardBackgroundColor='#FFEB9662',
      {
        CardView;
        radius='30dp',--圆角半径
        layout_width='-2',
        layout_height='-2',
        layout_margin="2dp";
        {
          LinearLayout;
          orientation="vertical";
          layout_width='80%w',
          layout_height='-1',
          Focusable=true,
          FocusableInTouchMode=true,
          --  id='卡片背景动画3',--控件ID
          {
            TextView;
            layout_width='-1',
            layout_height='-2',
            text="快捷代码\n____________________";
            textSize="24sp";
            gravity='center',
            layout_marginTop='20dp',--布局顶距
            Typeface = customFont;
          },
          {
            ListView;
            layout_width='-1',
            layout_height='60%h',
            layout_marginTop='20dp',--布局边距
            layout_marginLeft='20dp',--布局边距
            layout_marginRight='20dp',--布局边距
            id = "快捷代码内容";
          },
          {
            LinearLayout;
            layout_width='-1',
            layout_height='-2',
            layout_marginTop='15dp',--布局边距
            layout_gravity='center',
            layout_margin='8dp',--布局边距
            {
              CardView;
              layout_width="-1",
              layout_height="40dp",
              cardBackgroundColor='#FFEB9662',
              layout_margin='8dp',--布局边距
              radius='16dp',--圆角半径
              layout_weight='1',
              id='close_charu',--控件ID
              {
                TextView;
                text="Close";
                layout_width='-2',
                layout_height='-2',
                textSize="16sp",
                layout_gravity='center',
              };
            };
          };
        };
      };
    };
  };

  local popup = PopupWindow(activity)
  popup.setContentView(loadlayout(代码layout))
  popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setFocusable(true)
  popup.setBackgroundDrawable(ColorDrawable(0x00000000))
  -- 设置窗口动画
  -- popup.setAnimationStyle(android.R.style.Animation_Dialog)
  -- 显示弹窗
  popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)
  close_charu.onClick = function (v)
    popup.dismiss()
    return
  end

  local adpData = {}
  local newAdp = LuaAdapter(activity,adpData,code_title_list_item)
  for _,k in ipairs(快捷代码列表) do
    newAdp.add({
      title_list_text = {text= k..": "..快捷代码列表项[k],gravity=3, textColor=0xffffffff , Typeface = customFont },
      title_list_card = {cardBackgroundColor=0xFF272727},
    })
  end
  快捷代码内容.Adapter = newAdp
  快捷代码内容.onItemClick = function(l,v,p,i)
    -- popm.tw(快捷代码列表项[快捷代码列表[i]])

    local start = codeEdit.getSelectionStart()
    local selectedChar = 快捷代码列表项[快捷代码列表[i]]

    local success, err = pcall(function()
      if codeEdit.insert then
        codeEdit.insert(start, selectedChar)
       else
        -- 备用文本操作方案
        local text = tostring(codeEdit.getText())
        local newText = text:sub(1, start) .. selectedChar .. text:sub(codeEdit.getSelectionEnd() + 1)
        codeEdit.setText(newText)
      end

      -- 设置新光标位置
      local newPos = start + #selectedChar
      codeEdit.setSelection(newPos)

      -- 延迟确保界面更新
      codeEdit.postDelayed(function()
        codeEdit.setSelection(newPos) -- 重新设置确保可见
        codeEdit.requestFocus() -- 确保获得焦点
      end, 100)
    end)

    popup.dismiss()
    return
  end

end


----------------------------------
local 自定义符号栏 = [[ \" = ; . , _ - : / ~ ( ) [ ] { } < > \ + ' # ! ? % ]]

local function 解析符号栏(str)
  local 符号表 = {}
  for 符号 in str:gmatch("[^%s]+") do
    符号 = 符号:gsub([[\\]], [[\]]):gsub([[\"]], [["]])
    table.insert(符号表, 符号)
  end
  return 符号表
end

local 字符键 = 解析符号栏(自定义符号栏)

function 刷新字符样式()
  local adpData_字符键 = {}
  local newAdp_字符键 = LuaAdapter(activity, adpData_字符键, code_title_list_item)

  -- 初始化适配器数据
  for k, v in ipairs(字符键) do
    newAdp_字符键.add({
      title_list_text = {text=v, textColor=0xffffffff, Typeface=customFont},
      title_list_card = {cardBackgroundColor=0x00000000},
      itemId = k -- 添加唯一标识
    })
  end

  char_list.Adapter = newAdp_字符键

  char_list.onItemClick = function(l, view, position, id)
    -- 使用position而不是id，因为id可能与实际位置不符
    local actualPos = position + 1 -- 转换为Lua的1-based索引
    if not codeEdit or not 字符键 or not 字符键[actualPos] then return end

    -- 获取正确的适配器项
    local itemData = newAdp_字符键.getItem(position)
    if not itemData then return end

    -- 保存当前点击的字符
    local selectedChar = 字符键[actualPos]

    -- 1. 执行点击动画
    itemData.title_list_card.cardBackgroundColor = 0xFF555555
    newAdp_字符键.notifyDataSetChanged()

    -- 2. 延迟恢复颜色（确保动画可见）
    view.postDelayed(function()
      itemData.title_list_card.cardBackgroundColor = 0x00000000
      newAdp_字符键.notifyDataSetChanged()

      -- 3. 执行插入操作
      view.post(function()
        pcall(function()
          local start = codeEdit.getSelectionStart()
          if codeEdit.insert then
            codeEdit.insert(start, selectedChar)
           else
            local text = tostring(codeEdit.getText())
            local newText = text:sub(1, start) .. selectedChar .. text:sub(codeEdit.getSelectionEnd() + 1)
            codeEdit.setText(newText)
          end

          local newPos = start + #selectedChar
          codeEdit.setSelection(newPos)
          codeEdit.requestFocus()
        end)

        if saveCurrentState then pcall(saveCurrentState) end
      end)
    end, 100) -- 100毫秒的动画持续时间
  end
end

刷新字符样式()
----------------------------------
--  解析代码文件
--  实际文件名配置对应中文名
----------------------------------
local 代码路径 = activity.getLuaDir().."/code/"
local 代码块文件名 = {"base","file","book","layoutcode","popular","intent","androlua","net","win","FAS","other"}
local 代码块文件昵称 = {"基础","文件","功能","动画","常用","意图","alua","网络","控件","FAS","其他"}
local 存在的代码文件名 = {}
local 存在的代码文件昵称 = {}
for k, v in ipairs(代码块文件名) do
  local path = 代码路径..v
  -- 先检查文件是否存在
  if filesys.fileExists(path) then
    table.insert(存在的代码文件名, v)
    table.insert(存在的代码文件昵称, 代码块文件昵称[k])
  end
end

-- 提取文件内《《》》内为标题
-- 提取文件内【 【】 】内为内容
local function loadCodeData(v)
  local f = io.open(代码路径..存在的代码文件名[v])
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local 功能块标题, 功能块内容 = {}, {}
  for title, code in content:gmatch("《《(.-)》》%s*【【(.-)】】") do
    功能块标题[#功能块标题+1] = title
    功能块内容[#功能块内容+1] = code

  end
  return 功能块标题, 功能块内容
end

-- 初始化
功能块标题, 功能块内容 = loadCodeData(1)
if not 功能块标题 then
  popm.tw("数据加载失败")
end

----------------------------
-- 右侧滑栏功能
function 右侧滑栏列表()
  local adpData_右侧滑栏 = {}
  local newAdp_右侧滑栏 = LuaAdapter(activity,adpData_右侧滑栏,code_list_item)
  for k,v in ipairs(功能块标题) do
    newAdp_右侧滑栏.add({code_biaoge_title = {text=v, textColor=0xFFFFFFFF, Typeface = customFont }})
  end
  chl_lbx_list_right.Adapter = newAdp_右侧滑栏
  chl_lbx_list_right.onItemClick = function(l,v,p,i)
    local selectedCode = 功能块内容[p + 1] -- 注意Lua数组从1开始计数
    local dialogView =
    {
      LinearLayout;
      layout_width='-1',
      layout_height='-1',
      Gravity="center",
      {
        CardView;
        radius='30dp',--圆角半径
        -- id='有描边的卡片',--控件ID
        layout_width='-2',
        layout_height='-2',
        layout_margin='8%w',--布局边距
        cardBackgroundColor='#FFEB9662',
        {
          CardView;
          radius='30dp',--圆角半径
          layout_width='-2',
          layout_height='-2',
          layout_margin="2dp";
          {
            LinearLayout;
            orientation="vertical";
            layout_width='80%w',
            layout_height='-1',
            Focusable=true,
            FocusableInTouchMode=true,
            layout_margin='8dp',--布局边距
            --    id='卡片背景动画',--控件ID
            {
              TextView;
              layout_width='-1',
              layout_height='-2',
              text=功能块标题[p+1].."\n____________________";
              textSize="24sp";
              gravity='center',
              layout_marginTop='20dp',--布局顶距
              Typeface = customFont,
            },
            {
              EditText;
              layout_width='-1',
              layout_height='40%h',
              layout_gravity='center',
              text = selectedCode,
              Typeface = customFont,
              focusable = true,
              focusableInTouchMode=true, -- 阻止子控件自动获取焦点
            },
            {
              LinearLayout;
              layout_width='-1',
              layout_height='-2',
              layout_gravity='center',
              layout_marginTop='15dp',--布局顶距
              {
                CardView;
                layout_width="-1",
                layout_height="40dp",
                cardBackgroundColor='#FFEB9662',
                layout_margin='8dp',--布局边距
                radius='16dp',--圆角半径
                layout_weight='1',
                id='代码块返回',--控件ID
                {
                  TextView;
                  text="返回";
                  layout_width='-2',
                  layout_height='-2',
                  textSize="16sp",
                  layout_gravity='center',
                }
              };
              {
                CardView;
                layout_width="-1",
                layout_height="40dp",
                layout_weight='1',
                cardBackgroundColor='#FFEB9662',
                layout_margin='8dp',--布局边距
                radius='16dp',--圆角半径
                id='代码块复制',--控件ID
                {
                  TextView;
                  text="全部复制";
                  layout_width='-2',
                  layout_height='-2',
                  textSize="16sp",
                  layout_gravity='center',
                };
              };
            };
          };
        };
      };
    };
    local popup = PopupWindow(activity)
    popup.setContentView(loadlayout(dialogView))
    popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
    popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
    popup.setFocusable(true)
    popup.setBackgroundDrawable(ColorDrawable(0x00000000))

    -- 设置窗口动画
    popup.setAnimationStyle(android.R.style.Animation_Dialog)

    -- 显示弹窗（替换原来的 tc.show()）
    popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)
    代码块复制.onClick = function (v)
      activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(selectedCode)
      popm.tw("全部复制")
      chlMain.closeDrawer(5) -- 关
      hideKeyboard()
      popup.dismiss()
    end
    代码块返回.onClick = function(v)
      hideKeyboard() -- 再隐藏键盘
      popup.dismiss()
    end
  end
end

local 右侧滑栏文件_flag = "0"
function 右侧滑栏文件()
  local adpData_解析代码文件 = {}
  local newAdp_解析代码文件 = LuaAdapter(activity,adpData_解析代码文件,code_title_list_item)
  for k,v in ipairs(存在的代码文件名) do
    if 右侧滑栏文件_flag == k then
      newAdp_解析代码文件.add({
        title_list_text = {text=存在的代码文件昵称[k], textColor=0xffffffff , Typeface = customFont },
        title_list_card = {cardBackgroundColor=0xFF272727}
      })
     else
      newAdp_解析代码文件.add({
        title_list_text = {text=存在的代码文件昵称[k], textColor=0xffffffff , Typeface = customFont },
      })
    end
  end
  chl_lbx_title_right.Adapter = newAdp_解析代码文件
  chl_lbx_title_right.onItemClick = function(l,v,p,i)
    右侧滑栏文件_flag = i
    右侧滑栏文件()
    功能块标题, 功能块内容 = loadCodeData(i)
    if not 功能块标题 then
      popm.tw("数据加载失败")
    end
    右侧滑栏列表()
  end
end

右侧滑栏文件()
右侧滑栏列表()


--打包----------------
dabao.onClick = function ()
  import "java.io.File"
  import "java.lang.String"
  import "script.manaset"
  import "console"
  import "script.bin.bin"
  local app = {}
  local e = pcall(loadfile(私有目录.."/init.lua", "bt", app))
  if not e then
    popm.tw("工程发生错误！")
    return
  end

  if app.debugmode then
    popm.tw("未关闭调试模式！")
    return
  end

  --[=[  if manaset.compile.encrypt == 3 then
      popm.tw("不加密模式下禁止正式打包！")
      return
    end  ]=]
  bin(私有目录.."/",manaset.compile)
end