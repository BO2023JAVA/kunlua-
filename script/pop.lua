--------- 弹窗模块 ---------------------
local M = {}

-- 导入模块
local Typeface = import "android.graphics.Typeface"
local ColorStateList = import "android.content.res.ColorStateList"
local WindowManager = import "android.view.WindowManager"

-- 常量定义
local POPUP_WIDTH = "192dp"
local ITEM_HEIGHT = "48dp"
local TITLE_TEXT_COLOR = "#FF313131" --主题色
local ITEM_TEXT_COLOR = "#FF313131"
local TITLE_TEXT_SIZE = "14sp"
local ITEM_TEXT_SIZE = "14sp"
local POPUP_CORNER_RADIUS = "4dp"
local POPUP_BG_COLOR = 0xfffafafa
local DISMISS_DELAY = 50 -- ms

-- 样式资源
local rippleBorderless, rippleNormal

-- 初始化样式资源（避免重复获取）
local function initStyles()
  if not rippleBorderless then
    rippleBorderless = activity.obtainStyledAttributes({android.R.attr.selectableItemBackgroundBorderless}).getResourceId(0,0)
    rippleNormal = activity.obtainStyledAttributes({android.R.attr.selectableItemBackground}).getResourceId(0,0)
  end
end

-- 设置窗口暗化效果
local function setWindowDim(alpha)
  local lp = activity.getWindow().getAttributes()
  lp.alpha = alpha
  activity.getWindow().setAttributes(lp)
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
end

-- 创建弹窗基础布局
local function createPopupLayout()
  return {
    LinearLayout;
    {
      CardView;
      Elevation="0";
      CardBackgroundColor=POPUP_BG_COLOR;
      Radius=POPUP_CORNER_RADIUS;
      layout_width=POPUP_WIDTH;
      layout_height="-2";
      layout_marginLeft="8dp";
      {
        LinearLayout;
        layout_height="-1";
        layout_width="-1";
        orientation="vertical";
        id="popup_content";
      };
    };
  }
end

-- 创建列表项布局
local function createItemLayout(isTitle)
  return {
    LinearLayout;
    layout_width="-1";
    layout_height=ITEM_HEIGHT;
    {
      TextView;
      id="item_text";
      textColor=isTitle and TITLE_TEXT_COLOR or ITEM_TEXT_COLOR;
      layout_width="-1";
      layout_height="-1";
      textSize=isTitle and TITLE_TEXT_SIZE or ITEM_TEXT_SIZE;
      gravity="left|center";
      paddingLeft="16dp";
      Typeface=isTitle and Typeface.DEFAULT_BOLD or nil;
      Enabled=isTitle and false or true;
    };
  }
end

-- 显示弹窗
function M.show(tab, anchorView, title)
  -- 初始化
  initStyles()
  setWindowDim(0.85)

  -- 创建弹窗
  local popup = PopupWindow(activity)
  local layout = loadlayout(createPopupLayout())
  popup.setContentView(layout)
  popup.setWidth(WindowManager.LayoutParams.WRAP_CONTENT)
  popup.setHeight(WindowManager.LayoutParams.WRAP_CONTENT)
  popup.setFocusable(true)
  popup.setOutsideTouchable(true)
  popup.setBackgroundDrawable(ColorDrawable(0x00000000))

  -- 弹窗关闭时恢复窗口亮度
  popup.onDismiss = function()
    setWindowDim(1.0)
  end

  -- 添加标题（如果有）
  if title then
    local titleView = loadlayout(createItemLayout(true))
    popup_content.addView(titleView)
    item_text.setText(title)
  end

  -- 收集并排序键
  local orderedKeys = {}
  for k in pairs(tab) do
    table.insert(orderedKeys, k)
  end
  table.sort(orderedKeys) -- 按字母顺序排序

  -- 或者使用以下方式保持原始插入顺序（需要Lua 5.2+或使用额外表记录顺序）
  -- 这里假设tab是一个数组式表，元素格式为{key=键, value=值}
  -- 如果不是这种结构，需要修改传入的数据结构

  -- 添加菜单项（按顺序）
  for _, k in ipairs(orderedKeys) do
    local v = tab[k]
    local itemView = loadlayout(createItemLayout(false))
    itemView.BackgroundDrawable = activity.Resources.getDrawable(rippleNormal)
    .setColor(ColorStateList(int[0].class{int{}}, int{10000000}))

    popup_content.addView(itemView)
    item_text.setText(k)

    -- 设置点击事件
    if type(v) == "table" then
      -- 子菜单
      itemView.onClick = function()
        popup.dismiss()
        task(DISMISS_DELAY, function()
          M.show(v, anchorView, k)
        end)
      end
     elseif type(v) == "function" then
      -- 功能项
      itemView.onClick = function()
        popup.dismiss()
        task(DISMISS_DELAY, function()
          v()
        end)
      end
    end
  end

  -- 显示弹窗
  popup.showAsDropDown(anchorView, 0, 0, Gravity.BOTTOM)
  return popup
end

return M