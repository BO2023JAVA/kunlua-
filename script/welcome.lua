--require "import"
require "kunlua"
import "layout.welcome_aly"
activity.setTheme(android.R.style.Theme_Material_NoActionBar_TranslucentDecor)
activity.setContentView(loadlayout(welcome_aly))
import "init"
welcome版本号.text = appver
import "android.graphics.Typeface"
local fontPath = activity.getLuaDir().."/assets/fonts/mono_bold.ttf"
local customFont = Typeface.createFromFile(fontPath)
first_title.setTypeface(customFont)
first_title2.setTypeface(customFont)
welcome版本号.setTypeface(customFont)
first_版权.setTypeface(customFont)

--设置属性动画
--对应参数分别是（id，需要改变的属性，{动画开始时需要改变的属性的值，动画结束时需要改变的属性的值}）
import "android.view.animation.DecelerateInterpolator"
import "android.view.animation.Animation"
import "android.animation.ObjectAnimator"
local y = activity.Height/8
卡片.setAlpha(0)
卡片1.setAlpha(0)
卡片2.setAlpha(0)

平移动画 = ObjectAnimator.ofFloat(卡片, "Y", {卡片.getY, y})
平移动画.setRepeatCount(1)
平移动画.setRepeatMode(Animation.REVERSE)
平移动画.setInterpolator(DecelerateInterpolator())
平移动画.setDuration(8000)
平移动画.start()
渐显动画 = ObjectAnimator.ofFloat(卡片, "alpha", {0, 1}) -- 从透明到不透明
渐显动画.setDuration(1500) -- 1.5秒渐显
渐显动画.start()

渐显动画1 = ObjectAnimator.ofFloat(卡片1, "alpha", {0, 1}) -- 从透明到不透明
渐显动画1.setDuration(1500) -- 1.5秒渐显
渐显动画1.start()

-- 卡片2的平移动画
平移动画2 = ObjectAnimator.ofFloat(卡片2, "Y", {activity.Height/8, 卡片2.getY})
平移动画2.setRepeatCount(1)
平移动画2.setRepeatMode(Animation.REVERSE)
平移动画2.setInterpolator(DecelerateInterpolator())
平移动画2.setDuration(8000)
平移动画2.start()
渐显动画2 = ObjectAnimator.ofFloat(卡片2, "alpha", {0, 1}) -- 从透明到不透明
渐显动画2.setDuration(1500) -- 1.5秒渐显
渐显动画2.start()
-- 创建定时器
local ti = Ticker()
ti.Period = 1500
ti.onTick = function()
  平移动画.cancel()
  平移动画2.cancel()
  渐显动画.cancel()
  渐显动画1.cancel()
  渐显动画2.cancel()
  ti.stop()
  activity.newActivity("script/home")
  activity.finish()

end

ti.start()