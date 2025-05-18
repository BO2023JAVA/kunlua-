
local function ngde(view,Thickness,radiu,InsideColor,FrameColor)
  import "android.graphics.drawable.GradientDrawable"
  drawable = GradientDrawable()
  drawable.setShape(GradientDrawable.RECTANGLE)
  drawable.setStroke(Thickness, FrameColor)
  drawable.setColor(InsideColor)
  drawable.setCornerRadii({radiu,radiu,radiu,radiu,radiu,radiu,radiu,radiu});
  view.setBackgroundDrawable(drawable)
end

local utwin
local bindlg = {
  show=function(s)
    import "android.graphics.*"
    import "script.bin.binlayout"
    import "android.graphics.Paint"
    --  import "gif"

    local winlock = true
    utwin=Dialog(activity)
    utwin.setContentView(loadlayout(binlayout))
    --  loadGif(bin_gif,activity.getLuaDir("res/img/bin.gif"))
    ngde(bin_body, 5,20, 0x75000000, 0xFFEB9662)--0xFF406E64)

    bin_text.getPaint().setFakeBoldText(true)
    bin_title.getPaint().setFakeBoldText(true)

    pcall(function()
      bin_title.textColor=0xFFEB9662
      bin_text.textColor=manaset.gui.color.text_mini
      ngde(bin_body, 5,20, 0x75000000, 0xFFEB9662)
    end)

    utwin.getWindow().setBackgroundDrawableResource(android.R.color.transparent);
    utwin.getWindow().setGravity(Gravity.CENTER)--默认底部 CENTER中 TOP顶
    utwin.setCanceledOnTouchOutside(winlock);
    utwin.getWindow().getAttributes().width =(activity.getWidth()*0.85)
    utwin.show()
  end,

  update=function(s)
    bin_text.text = tostring(s)
  end,

  hide=function()
    utwin.hide()
    utwin.cancel()
  end
}

return bindlg
