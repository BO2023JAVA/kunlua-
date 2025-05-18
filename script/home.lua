require "import"
require "kunlua"
import "android.os.Environment"
import "layout.home_aly"
import "com.google.android.material.card.MaterialCardView"
import "item.home_list_item"
import "item.code_title_list_item"
import "android.graphics.Typeface"
import "android.graphics.drawable.ColorDrawable"
import "android.content.res.ColorStateList"
import "android.content.Intent"
import "android.content.Context"
import "init"
import "android.view.animation.DecelerateInterpolator"
import "android.view.animation.Animation"
import "android.animation.ObjectAnimator"
import "android.content.pm.*"
import "android.graphics.*"
import "script.bg_video"
local popm = require "script.popmin"
-- 在入口文件添加路径（确保使用正确的项目根目录）

activity.setTheme(android.R.style.Theme_Material_NoActionBar_TranslucentDecor)
activity.setContentView(loadlayout(home_aly))

--设置字体
local fontPath = activity.getLuaDir().."/assets/fonts/mono_bold.ttf"
local customFont = Typeface.createFromFile(fontPath)
home_title_text.setTypeface(customFont) --设置字体
--标题移入动画

卡片3.post(function()
  -- 确保视图已加载
  if 卡片3 == nil then return end

  local x = activity.Width/8
  卡片3.setAlpha(0)

  -- 平移动画（保留原有X轴动画）
  平移动画3 = ObjectAnimator.ofFloat(卡片3, "X", {x, 卡片3.getX()})
  平移动画3.setRepeatCount(1)
  平移动画3.setRepeatMode(Animation.REVERSE)
  平移动画3.setInterpolator(DecelerateInterpolator())
  平移动画3.setDuration(1500)

  -- 渐显动画（保持原有效果）
  渐显动画3 = ObjectAnimator.ofFloat(卡片3, "alpha", {0, 1})
  渐显动画3.setDuration(1000)

  -- 同时启动两个动画（保持原有并行效果）
  平移动画3.start()
  渐显动画3.start()

  -- 优化后的定时器（1500ms后停止动画）
  local ti = Ticker()
  ti.Period = 1500
  ti.onTick = function()
    -- 安全地停止动画
    pcall(function()
      平移动画3.cancel()
      渐显动画3.cancel()
      卡片3.setAlpha(1) -- 确保最终可见
      ti.stop()
    end)
  end
  ti.start()
end)

-- 防止内存泄漏
function onDestroy()
  if ti then ti.stop() end
  if 平移动画3 then 平移动画3.cancel() end
  if 渐显动画3 then 渐显动画3.cancel() end
end

local filesys = require("script.filesys")
版本号 = appver
local path = Environment.getExternalStorageDirectory().toString()
local project_path = path.."/KunLua+/project/"
local demo_path = path.."/KunLua+/projectDemo/"
local backup_path = path.."/KunLua+/backup/"
--文件权限再次打开
--[=[  if path == nil then
  import "android.content.Intent"
  import "android.provider.Settings"
  intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
  activity.startActivity(intent)
  Toast.makeText(activity, "访问文件权限", Toast.LENGTH_LONG).show()
  path = Environment.getExternalStorageDirectory().toString()
end  ]=]

function 刷新项目列表()
  -- 遍历所有项目目录
  home_list_name = {}
  home_list_v = {}
  home_list_bao = {}
  local projects = filesys.listDirectories(project_path) -- 获取所有子项目目录
  for _, project_name in ipairs(projects) do
    local main_path = project_path..project_name.."/main.lua"
    --  local layout_path = project_path..project_name.."/layout/layout.aly"  --非必备
    local init_path = project_path..project_name.."/init.lua"
    -- 先检查文件是否存在
    if filesys.fileExists(main_path) and filesys.fileExists(init_path)then
      -- 读取项目配置
      local appname = filesys.fileFind(init_path, "appname")
      local appv = filesys.fileFind(init_path, "appver")
      local appbao = filesys.fileFind(init_path, "packagename")
      if appname and appv and appbao then
        table.insert(home_list_name, appname)
        table.insert(home_list_v, appv)
        table.insert(home_list_bao, appbao)
      end
    end
  end
end
刷新项目列表()

function home列表样式(v)
  if home_list_name[v] ~= nil then
    return {
      biaoge_title={text=home_list_name[v], textColor=0xFF000000, Typeface = customFont},
      biaoge_img={src=activity.getLuaDir().."/res/drawable/icon.png", ColorFilter=0xFF313131}, -- ico样式
      biaoge_v={text="[v"..home_list_v[v].."]", textColor=0xFF000000 , Typeface = customFont},
      biaoge_bao={text=home_list_bao[v], textColor=0xFF000000, Typeface = customFont},
    }
   else
    return {
      biaoge_title={text="正在开发...", textColor=0x80FFFFFF},}
  end
end
----------工程列表，初始化数据表和适配器-------
function 刷新适配器()
  -- 检查数据是否存在
  if not home_list_name or #home_list_name == 0 then
    -- 清空适配器
    if home_list.Adapter then
      home_list.Adapter.clear()
      home_list.Adapter.notifyDataSetChanged() -- 通知适配器数据已改变
    end
    return
  end
  -- 如果适配器已存在，则清空并重用
  if not home_list.Adapter then
    home_list.Adapter = LuaAdapter(activity, {}, home_list_item)
  end
  local adp = home_list.Adapter
  adp.clear()
  -- 向适配器中添加列表项
  for i = 1, #home_list_name do
    local item = home列表样式(i)
    if item then -- 确保列表项有效
      adp.add(item)
     else
      print("警告：第"..i.."项列表样式返回nil")
    end
  end
  adp.notifyDataSetChanged() -- 通知适配器数据已改变
end
刷新适配器()

--列表项标识初始化
i_flag=0;
-- 网格列表点击事件处理器
home_list.onItemClick = function(l, v, p, i)
  --  if click_flag == false then
  activity.newActivity("script/codepage",{home_list_name[i]}) --跳转到对应页
  --  end
end
----------------------------------
--  新建项目弹窗逻辑处理
----------------------------------
function showPopWindow()
  local 模板选择 = "1"
  local demoname_num=1
  local demoname = "Demo"..tointeger(demoname_num)
  local projects = filesys.listDirectories(project_path) -- 获取所有子项目目录
  ----项目文件自动命名
  for i =1,10000 do
    for _, project_name in ipairs(projects) do
      if demoname == project_name then
        local num = project_name:match("Demo(%d+)")
        demoname_num=num+1
        demoname = "Demo".. tointeger(demoname_num)
      end
    end
  end
  ---包名自己随机命名
  math.randomseed(os.time())
  local demobao = math.random(1, 10000)

  --新建项目弹窗
  InputLayout=
  {
    LinearLayout;
    layout_width='-1',
    layout_height='-1',
    gravity="center";
    {
      CardView;
      radius='30dp',--圆角半径
      --  id='有描边的卡片',--控件ID
      layout_width='-2',
      layout_height='-2',
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
          id='卡片背景动画',--控件ID
          {
            TextView;
            layout_width='-1',
            layout_height='-2',
            text="新建项目\n____________________";
            textSize="24sp";
            gravity='center',
            layout_marginTop='20dp',--布局顶距
            Typeface = customFont,
          },
          {
            TextView;
            id="Prompt",
            textSize="15sp",
            layout_marginTop="10dp";
            layout_marginLeft="20dp",
            layout_marginRight="20dp",
            text="工程项目路径:\n"..Environment.getExternalStorageDirectory().toString().."/KunLua+/project/ \nSDK21-29";
          };
          {
            TextView,
            text="项目名:",
            layout_marginTop="10dp";
            layout_marginLeft="20dp",
            textSize="16sp",
          };
          {
            EditText;
            hint="项目名";
            layout_marginLeft="3dp",
            layout_width="68%w";
            layout_gravity="center";
            singleLine=true;--设置单行输入
            id="xmm";
            text=demoname;
          };
          {
            TextView,
            text="SDK版本:",
            layout_marginTop="10dp";
            layout_marginLeft="20dp",
            textSize="16sp",
          };
          {
            EditText;
            hint="SDK版本";
            layout_marginLeft="3dp",
            layout_width="68%w";
            layout_gravity="center";
            singleLine=true;--设置单行输入
            id="sdk";
            text="28";
          };
          {
            TextView,
            text="包名:",
            layout_marginTop="10dp";
            layout_marginLeft="20dp",
            textSize="16sp",
          };
          {
            EditText;
            hint="包名";
            layout_marginLeft="3dp",
            layout_width="68%w";
            layout_gravity="center";
            singleLine=true;--设置单行输入
            id="bao";
            text="com.kunluap.app"..demobao;
          };
          {
            TextView,
            text="模板:",
            layout_marginTop="10dp";
            layout_marginLeft="20dp",
            textSize="16sp",
          };
          {
            LinearLayoutCompat;
            layout_marginTop="10dp";
            layout_marginLeft="20dp",
            layout_height="-2",
            layout_width="68%w";
            layout_gravity="center";
            {
              MaterialCardView;
              layout_marginLeft="3dp",
              layout_width="-2",
              layout_height="50dp",
              layout_gravity="center";
              cardBackgroundColor='#00000000';--卡片颜色
              cardElevation='0dp';--卡片阴影
              strokeWidth="1dp", --边框宽度
              strokeColor="#ffffff", --边框颜色
              clickable=true;--点击效果
              radius='5dp';--卡片圆角
              id = "newdemo1";
              onClick = function()
                popm.tw("已选择【空白页】\n模板编号:1")
                模板选择="1"
              end,
              {
                TextView;
                text="空白";
                layout_width="-2",
                layout_height="-2",
                textSize="16sp",
                layout_gravity="center",
                layout_marginLeft="5dp",
                layout_marginRight="5dp",
              },
            },

            {
              MaterialCardView;
              layout_marginLeft="3dp",
              layout_width="-2",
              layout_height="50dp",
              layout_gravity="center";
              cardBackgroundColor='#00000000';--卡片颜色
              cardElevation='0dp';--卡片阴影
              strokeWidth="1dp", --边框宽度
              strokeColor="#ffffff", --边框颜色
              clickable=true;--点击效果
              radius='5dp';--卡片圆角
              id = "newdemo2";
              onClick = function()
                popm.tw("已选择【底部三页】\n模板编号:2")
                模板选择="2"
              end,
              {
                TextView;
                text="底部三页";
                layout_width="-2",
                layout_height="-2",
                textSize="16sp",
                layout_gravity="center",
                layout_marginLeft="5dp",
                layout_marginRight="5dp",
              };
            };
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
              layout_weight='1',
              cardBackgroundColor='#FFEB9662',
              layout_margin='8dp',--布局边距
              radius='16dp',--圆角半径
              id='新建取消',--控件ID
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
              id='新建确定',--控件ID
              {
                TextView;
                text="确定";
                layout_width='-2',
                layout_height='-2',
                textSize="16sp",
                layout_gravity='center',
              }
            };
          };
        };
      };
    };
  };
  local popup = PopupWindow(activity)
  popup.setContentView(loadlayout(InputLayout))
  popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setFocusable(true)
  popup.setBackgroundDrawable(ColorDrawable(0x00000000))
  -- 设置窗口动画
  popup.setAnimationStyle(android.R.style.Animation_Dialog)
  -- 显示弹窗
  popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)
  -- 按钮事件处理（示例）


  新建取消.onClick = function()
    popup.dismiss()
  end
  新建确定.onClick = function(v)
    for i,j in ipairs(home_list_name) do
      if xmm.text == j then
        nameflag = true
      end
    end
    for n,m in ipairs(home_list_bao) do
      if bao.text == m then
        baoflag = true
      end
    end

    if filesys.fileExists(project_path..xmm.text) or baoflag or nameflag then
      if nameflag then
        popm.tw("项目名已存在")
        nameflag =false
      end
      if baoflag then
        popm.tw("包名已存在")
        baoflag = false
      end
      if filesys.fileExists(project_path..xmm.text) and not nameflag and not baoflag then
        popm.tw("KunLua+/project/里项目不能同名")
        nameflag =false
        baoflag = false
      end
     else
      ---新项目init文件
      local newinit=[[appname="]]..tostring(xmm.text)..[["
appver="1.0.0"
appcode="1"
appsdk="]]..tostring(sdk.text)..[["
path_pattern=""
packagename="]]..tostring(bao.text)..[["
theme="Theme_Material_Light_NoActionBar_TranslucentDecor"
app_key=""
app_channel=""
developer=""
description=""
debugmode=true
user_permission={
"INTERNET",
"WRITE_EXTERNAL_STORAGE",
}]]

      local newkunlua = [[require "import"

--全局导入放这个文件

import {
  "android.app.*",
  "android.os.*",
  "android.widget.*",
  "android.view.*",
  "java.io.File",
}
import {
  "init",
}
--在lua文件夹里
require "fun.ocss.debug"

--隐藏标题
this.supportActionBar.hide()















]]
      --解压资源依赖到本地kunlua+
      local libs_path = activity.getLuaDir().."/libs/"
      local libs_path_projectDemo = libs_path.."projectDemo.zip"
      local libs_path_fun = libs_path.."fun.zip"
      local libs_path_androidx = libs_path.."androidx.jar"
      local libs_path_luajava = libs_path.."luajava.jar"

      local libs_topath_projectDemo = demo_path
      local libs_topath_fun = project_path..xmm.text.."/lua/"
      local libs_topath_androidx = project_path..xmm.text.."/libs/androidx.jar"
      local libs_topath_luajava = project_path..xmm.text.."/libs/luajava.jar"

      local FileUtils = require "fun.ocss.FileUtils"
      FileUtils.unZip(libs_path_projectDemo, libs_topath_projectDemo)
      FileUtils.unZip(libs_path_fun, libs_topath_fun)

      -- 从模板工程复制文件
      local templatePath = demo_path..模板选择.."/"
      local newProjectPath = project_path..xmm.text.."/"

      -- 复制整个工程目录
      filesys.copyDirectory(templatePath, newProjectPath)
      filesys.fileCopy(libs_path_androidx, libs_topath_androidx)
      filesys.fileCopy(libs_path_luajava, libs_topath_luajava)
      filesys.fileWrite(project_path..xmm.text.."/init.lua",newinit)
      filesys.fileWrite(project_path..xmm.text.."/kunlua.lua",newkunlua)
      -- filesys.fileWrite(project_path..xmm.text.."/main.lua",newmain)


      刷新项目列表()
      刷新适配器()
    end
    popup.dismiss()
  end

  -----卡片动画
  local particleSystem = bg_video.newbg(卡片背景动画)
  卡片背景动画.post(function()
    particleSystem.init()
    particleSystem.start()
  end)
  ----------
end

----------------------------------
--  导入项目弹窗逻辑处理
----------------------------------

local FileUtils = require("lua/fun/ocss/FileUtils")
if not FileUtils then
  popm.tw("Failed to load FileUtils module")
  return
end

function showPopWindow2()
  --导入的弹窗布局
  local 导入layout = {
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
            text="导入项目(.alp格式)\n____________________";
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
            id = "文件选择列表";
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
              id='close_daoru',--控件ID
              {
                TextView;
                text="Close";
                layout_width='-2',
                layout_height='-2',
                textSize="16sp",
                layout_gravity='center',
                Typeface = customFont;
              };
            };
          };
        };
      };
    };
  };

  local popup = PopupWindow(activity)
  popup.setContentView(loadlayout(导入layout))
  popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setFocusable(true)
  popup.setBackgroundDrawable(ColorDrawable(0x00000000))
  -- 设置窗口动画
  --popup.setAnimationStyle(android.R.style.Animation_Dialog)
  -- 显示弹窗
  popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)
  close_daoru.onClick = function (v)
    popup.dismiss()
  end

  local 根目录 = path .."/"
  local 当前路径 = backup_path
  local 工程路径 = project_path

  local function 筛选列表(path)
    local 所有文件 = luajava.astable(File(path).listFiles() or {})
    local 已筛选列表 = {"../"}
    for _, v in pairs(所有文件) do
      local 文件项 = File(tostring(v))
      local 文件名 = 文件项.getName()
      if 文件项.isDirectory() then
        table.insert(已筛选列表, 文件名)
       elseif 文件名:lower():match("%.alp$") then
        table.insert(已筛选列表, 文件名)
      end
    end
    return 已筛选列表
  end

  -- 显示文件选择对话框（持续显示）
  local function 显示对话框()
    local 文件列表 = 筛选列表(当前路径)
    local adpData = {}
    local newAdp = LuaAdapter(activity, adpData, code_title_list_item)
    for _, v in ipairs(文件列表) do
      newAdp.add({
        title_list_text = { text = v, textColor = 0xffffffff, gravity = 0x11, Typeface = customFont },
        title_list_card = { cardBackgroundColor = 0xFF272727 },
      })
    end
    文件选择列表.Adapter = newAdp
    文件选择列表.onItemClick = function(l, v, p, i)
      local 选择项 = 文件列表[i]
      if 选择项 == "../" then
        -- 返回上一级目录
        if 当前路径 == 根目录 then
          popm.tw("已经在根目录")
         else
          当前路径 = 当前路径:gsub("/+$", ""):match("(.*/)") or 根目录
        end
       else
        local 新路径 = 当前路径 .. 选择项
        if File(新路径).isDirectory() then
          当前路径 = 新路径 .. "/"
         else
          -- 1. 先解压到临时目录
          local 临时目录 = activity.getExternalFilesDir("temp_unzip").getAbsolutePath() .. "/"
          FileUtils.unZip(新路径, 临时目录)

          -- 2. 读取 init.lua 获取 appname
          local init_file = 临时目录 .. "init.lua"
          local appname = nil
          if File(init_file).exists() then
            local init_content = io.open(init_file):read("*a")
            -- 尝试匹配 appname = "xxx" 或 appname='xxx'
            appname = init_content:match('appname%s*=%s*["\'](.-)["\']')
          end

          -- 3. 如果 appname 存在，就使用它，否则用文件名（去掉 .alp）
          local 项目名 = appname or 选择项:gsub("%.alp$", ""):gsub("%s*%(%d+%)$", "")

          -- 4. 检查项目是否已存在
          local nameflag = false
          for _, j in ipairs(home_list_name) do
            if 项目名 == j then
              nameflag = true
              break
            end
          end

          if nameflag then
            popm.tw("项目【" .. 项目名 .. "】已存在或名称冲突")
            -- 删除临时目录
            File(临时目录).delete()
           else
            -- 5. 正式解压到项目目录
            local 解压到 = project_path .. 项目名 .. "/"
            FileUtils.unZip(新路径, 解压到)
            popm.tw("已导入项目: " .. 项目名)
            刷新项目列表()
            刷新适配器()
          end
          popup.dismiss()
        end
      end
      显示对话框()
    end
  end
  显示对话框()
end

---  home页菜单选项 ---------------------------
local popup = require("script/pop")

--  新建项目
local projectMenu = {
  ["新建项目"] = function()
    local ActivityCompat = luajava.bindClass("androidx.core.app.ActivityCompat")
    local Manifest = luajava.bindClass("android.Manifest$permission")
    -- 检查是否已有权限
    if ActivityCompat.checkSelfPermission(activity, Manifest.WRITE_EXTERNAL_STORAGE) ~= 0 then
      -- 动态申请权限（会弹系统弹窗）
      popm.tw("新建工程需要文件权限")
      ActivityCompat.requestPermissions(
      activity,
      { Manifest.WRITE_EXTERNAL_STORAGE },
      100 -- 请求码
      )
     else
      showPopWindow()
    end
  end,
  ["导入项目"] = function()
    local ActivityCompat = luajava.bindClass("androidx.core.app.ActivityCompat")
    local Manifest = luajava.bindClass("android.Manifest$permission")
    -- 检查是否已有权限
    if ActivityCompat.checkSelfPermission(activity, Manifest.WRITE_EXTERNAL_STORAGE) ~= 0 then
      -- 动态申请权限（会弹系统弹窗）
      popm.tw("导入工程需要文件权限")
      ActivityCompat.requestPermissions(
      activity,
      { Manifest.WRITE_EXTERNAL_STORAGE },
      100 -- 请求码
      )
     else
      showPopWindow2()
    end
  end
}





function 复制(内容)
  import "android.content.*"
  activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(内容)
end
--  关于菜单
local aboutMenu = {
  ["开发者: 鲲宝"] = {
    ["你干嘛,哎呦!"] = function() end,
    ["Q:410380438"] = function()
      复制("410380438")
      popm.tw("已复制")
    end,
    ["V:bbqcxk"] = function()
      复制("bbqcxk")
      popm.tw("已复制")
    end,
  },
  ["开发者日志"] = function()
    local x = filesys.fileRead(activity.getLuaDir().."/logs/KunLuaLog.md")

    local logLayout =
    {
      LinearLayout;
      layout_width='-1',
      layout_height='-1',
      Gravity = "center",
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
              text="开发者日志\n___________________";
              textSize="24sp";
              gravity='center',
              layout_marginTop='20dp',--布局顶距
              Typeface = customFont,
            },
            {
              TextView;
              layout_width='-1',
              layout_height='40%h',
              layout_marginTop='20dp',--布局边距
              layout_marginLeft='20dp',--布局边距
              layout_marginRight='20dp',--布局边距
              text = x,
              Typeface = customFont,
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
                id='开发者确定',--控件ID
                {
                  TextView;
                  text="确定";
                  layout_width='-2',
                  layout_height='-2',
                  textSize="16sp",
                  layout_gravity='center',
                }
              };
            };
          };
        };
      };
    };
    local popup = PopupWindow(activity)
    popup.setContentView(loadlayout(logLayout))
    popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
    popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
    popup.setFocusable(true)
    popup.setBackgroundDrawable(ColorDrawable(0x00000000))
    -- 设置窗口动画
    popup.setAnimationStyle(android.R.style.Animation_Dialog)
    -- 显示弹窗
    popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)
    -- 按钮事件处理（示例）

    开发者确定.onClick=function(v)
      popup.dismiss()
    end

  end,
  ["版本号V"..版本号] = function() end,
}

home_new.onClick = function()
  popup.show(projectMenu, home_new, "项目工程")
end
home_open.onClick = function()
  popup.show(aboutMenu, home_open, "关于")
end
home_list.onItemLongClick = function(l, v, p, i)
  i_flag = i
  local home_文件操作 =
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
            text="删除工程\n____________________";
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
            text = "确定要删除["..home_list_name[i_flag].."]这个工程吗？";
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
              id='删除取消',--控件ID
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
              id='删除工程',--控件ID
              {
                TextView;
                text="确认删除";
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
  popup.setContentView(loadlayout(home_文件操作))
  popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
  popup.setFocusable(true)
  popup.setBackgroundDrawable(ColorDrawable(0x00000000))
  -- 设置窗口动画
  popup.setAnimationStyle(android.R.style.Animation_Dialog)
  -- 显示弹窗
  popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)
  删除取消.onClick = function (v)
    i_flag = 0
    popup.dismiss()
  end
  删除工程.onClick=function(v)
    filesys.rmDir(project_path..home_list_name[i_flag])
    os.execute("sleep 0.3") -- 增加延迟时间
    刷新项目列表()
    刷新适配器()
    -- 强制刷新列表视图
    home_list.invalidate()
    i_flag = 0
    popup.dismiss()
  end
  return true
end

------------------------------------------------------
function 加QQ群(群号)
  import "android.content.Intent"
  import "android.net.Uri"
  activity.startActivity(Intent(Intent.ACTION_VIEW,Uri.parse("mqqapi://card/show_pslcard?src_type=internal&version=1&uin="..群号.."&card_type=group&source=qrcode")))
end
--[=[  function 浏览器打开(链接)
  import "android.content.Intent"
  import "android.net.Uri"
  viewIntent = Intent("android.intent.action.VIEW",Uri.parse(链接))
  activity.startActivity(viewIntent)
end
  ]=]
local 更多Menu = {
  ["打赏作者0.1元"] = function()

    local monayLayout =
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
            layout_height='-2',
            Focusable=true,
            FocusableInTouchMode=true,
            layout_margin='8dp',--布局边距
            {
              TextView;
              layout_width='-1',
              layout_height='-2',
              text="打赏作者\n____________________";
              textSize="24sp";
              gravity='center',
              Typeface = customFont,
              layout_marginTop='10dp',--布局顶距
            },
            {
              TextView;
              layout_width='-1',
              layout_height='-2',
              layout_marginTop='20dp',--布局边距
              layout_marginLeft='20dp',--布局边距
              layout_marginRight='20dp',--布局边距
              text = "Kunlua+永久免费更新，爱心助力做出更多好用好玩的软件。截图保存，立即助力！\n助力1元 少写一个bug\n助力10元 奖励作者一杯奶茶\n助力100元 作者教你写bug\n助力1000元 作者会的都教你\n助力3000元 爹";
              Typeface = customFont;
            },
            {
              ImageView;
              src='res/drawable/pay.jpg',--视图路径
              layout_width='-1',
              layout_height='300dp',
            },
            {
              LinearLayout;
              layout_width='-1',
              layout_height='-2',
              layout_gravity='center',
              layout_weight='1',
              {
                CardView;
                layout_width="-1",
                layout_height="40dp",
                cardBackgroundColor='#FFEB9662',
                layout_margin='8dp',--布局边距
                radius='16dp',--圆角半径
                id='捐助确定',--控件ID
                {
                  TextView;
                  text="确定";
                  layout_width='-1',
                  layout_height='-1',
                  Gravity="center";
                  textSize="16sp",
                  layout_gravity='center',
                }
              };
            };
          };
        };
      };
    };
    local popup = PopupWindow(activity)
    popup.setContentView(loadlayout(monayLayout))
    popup.setWidth(WindowManager.LayoutParams.MATCH_PARENT)
    popup.setHeight(WindowManager.LayoutParams.MATCH_PARENT)
    popup.setFocusable(true)
    popup.setBackgroundDrawable(ColorDrawable(0x00000000))
    -- 设置窗口动画
    popup.setAnimationStyle(android.R.style.Animation_Dialog)
    -- 显示弹窗
    popup.showAtLocation(activity.getWindow().getDecorView(), Gravity.CENTER, 0, 0)
    -- 按钮事件处理（示例）
    捐助确定.onClick=function(v)
      popup.dismiss()
    end

  end,
  ["加QQ群"] = function()
    加QQ群(761083976)
  end,
  ["软件更新"] = function()
    加QQ群(761083976)
  end,
}
home_menu.onClick=function(v)
  popup.show(更多Menu,home_menu,"其他")
end


function onDestroy()
  if 平移动画3 and 平移动画3.isRunning() then
    平移动画3.cancel()
  end
end