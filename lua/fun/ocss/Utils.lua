local _M={}

function _M.setContext(context)
  _M.mContext = context or activity
end

function _M.dp2px(dpValue)
  local scale = activity.getResources().getDisplayMetrics().scaledDensity
  return dpValue * scale + 0.5
end

function _M.maxLength(id, length)
  local length = tointeger(length)
  if(type(length)=="number")then
    id.setFilters({luajava.bindClass "android.text.InputFilter$LengthFilter"(math.abs(length))})
   else
    _M.Toast("[异常] length is not a number")
  end
end

--获取文件Drawable方法
function _M.getFileDrawable(filePath)
  local FileInputStream = luajava.bindClass "java.io.FileInputStream"
  local BitmapFactory = luajava.bindClass "android.graphics.BitmapFactory"
  local BitmapDrawable = luajava.bindClass "android.graphics.drawable.BitmapDrawable"
  local fis = FileInputStream(activity.getLuaDir(filePath))
  local bitmap = BitmapFactory.decodeStream(fis)
  fis.close()
  return BitmapDrawable(activity.getResources(), bitmap)
end

function _M.getIconDrawable(filePath, viewSize)
  local PorterDuffColorFilter = luajava.bindClass "android.graphics.PorterDuffColorFilter"
  local PorterDuff = luajava.bindClass "android.graphics.PorterDuff"
  local BitmapDrawable = luajava.bindClass "android.graphics.drawable.BitmapDrawable"
  local Bitmap = luajava.bindClass "android.graphics.Bitmap"
  local Matrix = luajava.bindClass "android.graphics.Matrix"
  local TypedValue = luajava.bindClass "android.util.TypedValue"
  local bitmap = LuaBitmap.getLocalBitmap(filePath)
  local scale = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, viewSize or 24, activity.getResources().getDisplayMetrics()) / bitmap.getWidth()
  local matrix = Matrix() matrix.postScale(scale, scale)
  local drawable = BitmapDrawable(activity.Resources, Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getWidth(), matrix, true))
  return drawable
end

--文件分享函数
function _M.shareFile(filePath)
  --导入所需类
  local File = luajava.bindClass "java.io.File"
  local Uri = luajava.bindClass "android.net.Uri"
  local Intent = luajava.bindClass "android.content.Intent"
  local MimeTypeMap = luajava.bindClass "android.webkit.MimeTypeMap"
  local FileProvider = luajava.bindClass "androidx.core.content.FileProvider"
  --获取文件名
  local fileName = File(filePath).getName()
  --获取mime类型
  local mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileName:match("%.(.+)"))
  --构建文件uri
  local authorities = activity.getPackageName()
  local fileUri = FileProvider.getUriForFile(activity, authorities, File(filePath))
  --构建intent
  local shareIntent = Intent(Intent.ACTION_VIEW)
  shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
  --判断一下 mimeType 是否有获取到
  if mimeType then
    --设置intent数据
    shareIntent.setDataAndType(fileUri, mimeType)
   else
    _M.Toast("无法找到打开此文件类型的程序")
    --结束函数进程
    return
  end
  --激活 intent 开始分享
  activity.startActivity(shareIntent)
end

function _M.clearTable(tab)
  for k, _ in pairs(tab) do
    tab[k] = nil
  end
end
function _M.getGradientDrawable(color,topLeft,topRight,bottomLeft,bottomRight)
  return luajava.bindClass "android.graphics.drawable.GradientDrawable"()
  .setShape(0)
  .setColor(color)
  .setCornerRadii({
    _M.dp2px(topLeft),_M.dp2px(topLeft),
    _M.dp2px(topRight),_M.dp2px(topRight),
    _M.dp2px(bottomRight),_M.dp2px(bottomRight),
    _M.dp2px(bottomLeft),_M.dp2px(bottomLeft)
  })
end

function _M.modifyItemOffsets(outRect, view, parent, state, spanCount)
  -- 获取RecyclerView的LayoutManager，用于判断当前布局类型
  local layoutManager = parent.getLayoutManager()

  -- 获取当前item的位置
  local position = parent.getChildAdapterPosition(view)
  -- 获取当前item的布局参数
  local layoutParams = view.getLayoutParams()
  -- 获取当前item在瀑布流布局中的跨度索引
  local spanIndex = layoutParams.getSpanIndex()

  local function dp2px(dpValue)
    local scale = activity.getResources().getDisplayMetrics().scaledDensity
    return dpValue * scale + 0.5
  end

  -- 设置每个方向的间距
  local spacing = dp2px(5) -- 定义总间距
  local halfSpacing = spacing / 2 -- 计算间距的一半，用于更灵活的间距设置
  -- 根据列的索引设置左右间距
  if spanIndex == 0 then
    -- 如果视图在第一列
    outRect.left = 0 -- 左边有完整的间距
    outRect.right = halfSpacing -- 右边有一半的间距
   elseif spanIndex == (spanCount -1) then
    -- 如果视图在最后一列
    outRect.left = halfSpacing -- 左边有一半的间距
    outRect.right = 0 -- 右边有完整的间距
   else
    -- 如果视图在中间列
    outRect.left = halfSpacing -- 左边有一半的间距
    outRect.right = halfSpacing -- 右边有一半的间距
  end

  -- 设置item的上下间距
  outRect.top = halfSpacing
  outRect.bottom = spacing
end

function _M.getApplicationName()
   return activity.getPackageManager().getApplicationLabel(activity.getPackageManager().getApplicationInfo(activity.getPackageName(), 0)) 
end

--弹出Toast消息提示
function _M.Toast(...)
  --判断数据类型
  if type(...) == "table" then
    --dump解析一下
    toastText = dump(...)
   else
    --初始化表
    local contentTable = table.pack(...)
    --获取表长度
    local max = table.maxn(contentTable)
    --初始化第一项内容
    toastText = tostring(contentTable[1])
    --循环遍历表数据
    for i = 2, max do
      --读取数据表内容
      local temp = contentTable[i]
      --判断该项数据类型
      if type(temp) == "table" then
        --dump 解析一下
        local temp = dump(temp)
        --拼接到原有字符串后部
        toastText = toastText.."\n"..temp
       else
        --拼接到原有字符串后部
        toastText = toastText.."\n".. tostring(temp)
      end
    end
  end
  --输出内容
  local Toast = luajava.bindClass "android.widget.Toast"
  Toast.makeText(activity,tostring(toastText),Toast.LENGTH_SHORT).show()
end

--弹出Snackbar消息提示
function _M.Snack(content,condition)
  local Snackbar = luajava.bindClass "com.google.android.material.snackbar.Snackbar"
  local anchor=activity.findViewById(android.R.id.content)
  if condition ==true then
    Snackbar.make(anchor, tostring(content), Snackbar.LENGTH_LONG).show()
   else
    Snackbar.make(anchor, tostring(content), Snackbar.LENGTH_SHORT).show()
  end
end

--弹出Toast消息提示
function _M.toast(...)
  --判断数据类型
  if type(...) == "table" then
    --dump解析一下
    toastText = dump(...)
   else
    --初始化表
    local contentTable = table.pack(...)
    --获取表长度
    local max = table.maxn(contentTable)
    --初始化第一项内容
    toastText = tostring(contentTable[1])
    --循环遍历表数据
    for i = 2, max do
      --读取数据表内容
      local temp = contentTable[i]
      --判断该项数据类型
      if type(temp) == "table" then
        --dump 解析一下
        local temp = dump(temp)
        --拼接到原有字符串后部
        toastText = toastText.."\n"..temp
       else
        --拼接到原有字符串后部
        toastText = toastText.."\n".. tostring(temp)
      end
    end
  end
  --输出内容
  local Toast = luajava.bindClass "android.widget.Toast"
  Toast.makeText(activity,tostring(toastText),Toast.LENGTH_SHORT).show()
end

--弹出Snackbar消息提示
function _M.snack(content,condition)
  local Snackbar = luajava.bindClass "com.google.android.material.snackbar.Snackbar"
  local anchor=activity.findViewById(android.R.id.content)
  if condition ==true then
    Snackbar.make(anchor, tostring(content), Snackbar.LENGTH_LONG).show()
   else
    Snackbar.make(anchor, tostring(content), Snackbar.LENGTH_SHORT).show()
  end
end

return _M
