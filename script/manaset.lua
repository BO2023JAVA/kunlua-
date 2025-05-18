import "java.io.File"

local jsonApi = import "cjson";
local sddir = Environment.getExternalStorageDirectory().toString()
local manadir = sddir.."/KunLua+/"
local setpath = manadir.."base/seting.json"


local function write_file(p,s)
  local c = File(tostring(File(tostring(p)).getParentFile())).mkdirs()
  io.open(tostring(p),"w"):write(tostring(s)):close()
end

local function read_file(p)
  return io.open(p):read("*a")
end


local haveset = false
local json2table = {}
pcall(function()
  if File(setpath).isFile() then
    json2table = jsonApi.decode(read_file(setpath))
    if json2table.gui.color then
      haveset = true
    end
  end
end)



local defaultSeting={

  gui={
    color={--4玛娜蓝
      name="清新绿",
      head = 0xFFEB9662,--顶部颜色
      body = 0xFFFFFFFF,--主题颜色
      line = 0xFFEB9662,--线条颜色
      ripple=0x22000000,--波纹颜色
      ripple_light=0x22ffffff,--顶部波纹颜色
      editor=0x11000000,--编辑框
      editor_light=0x44000000,--顶部编辑框
      icon=0xFF6E6E6E,--图标颜色
      icon_light=0xFFFFFFFF,--顶部图标颜色
      text=0xFF6E6E6E,--文字颜色
      text_light=0xFFFFFFFF,--高亮文字颜色
      text_mini=0xFFEB9662,--次级文字颜色
      text_mini_light=0xFFEB9662,--高亮次级文字颜色
      tray=0xFF58D9FF,--托盘颜色
    },
  },

  compile={
    encrypt=1,
    lualibs="/storage/emulated/0/KunLua+/lualibs",
    solibs="/storage/emulated/0/KunLua+/solibs",
    solibs64="/storage/emulated/0/KunLua+/solibs64",
    skipc="",
    openapk=true,
    shell=false,
    mix=false,
    sign=true,
    res=true,
  },


  filelist={
    pull=false;
    luatop=true,
    showimg=true,
    together=true,
  },


  layout={
    model=3,
    save=false,
    del=false,
  },

  editor= {
    ["size"] = 38.0 ;
    ["hlbc"] = "0xFF2D5EBB" ;--选中
    ["debug"] = true ;
    ["soc"] = "0xFFFF0000" ;
    ["line"] = true ;
    ["backup"] = 0.0 ;
    ["kbc"] = "0xFFFFFFFF" ;
    ["ac"] = "0xFFEB9662" ;
    ["fc"] = "0xFF0055FF" ;
    ["hlc"] = "0xFFFF6400" ;
    ["code"] = 2 ;
    ["bug"] = true ;
    ["bugmodel"] = 1 ;
    ["magnifier"]=true;
    ["back"] = "0xFFFFFFFF" ;
    ["kbtc"] = "0xFFEB9662" ;
    ["tc"] = "0xFF727272" ;
    ["sc"] = "0xFFEB9662" ;
  },


  tag={
    tticon=true,
    model=false,
    futag=2,
    fuc=[[( ) [ ] { } " = : . _ , ; + - ' # ! ? / \ % < > ~ 结束]],
    modelc=[[javaApi 分析api]],
  },
}


local manaset = {}
if haveset then
  manaset = json2table else
  manaset = defaultSeting
  write_file(setpath, tostring(jsonApi.encode(manaset)))
end



function saveSet()
  control_hide= not manaset.editor.debug
  write_file(setpath, tostring(jsonApi.encode(manaset)))
  return true
end


for k,v in pairs(manaset.gui.color) do
  if k ~= "name" then
    manaset.gui.color[k] = tointeger(v)
  end
end

local function nextTab(t,k)
  for key,value in pairs(t)
    if key == k then
      return true
    end
  end
end


local temp = {}
local function checkset(t, t2)
  for k,v in pairs(t) do
    if not nextTab(t2, k) then
      t2[k] = v
    end
    if type(v) == "table" then
      table.insert(temp, k)
      checkset(v, t2[k])
      temp = {}
    end
  end
end

--调试助手
control_hide= not manaset.editor.debug
checkset(defaultSeting, manaset)
return manaset