require "import"
import "android.os.Environment"
import "java.io.File"
import "com.androlua.LuaUtil"

--local path = Environment.getExternalStorageDirectory().toString()
--解压依赖
--local jarPath =activity.getLuaDir().."/lualibs/lualibs.jar"
--local 依赖库 = path.."/KunLua/lualibs/"
--ZipUtil.unzip(jarPath,依赖库)

activity.newActivity("script/welcome")
activity.finish()







