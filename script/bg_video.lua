local base = {}

collectgarbage("setpause", 250)
collectgarbage("setstepmul", 250)

function base.newbg(cardView)
  -- 私有变量
  local scr_w, scr_h = 0, 0
  local connect_range, split_range = 0, 0
  local paint_point, paint_line = Paint(), Paint()
  local points = {}
  local wall = true
  local touch_pos = {}
  local is_running = false
  local frame_delay =1600 -- ~60fps

  -- 私有方法
  local function distance(x, y)
    return (x^2 + y^2)^0.5
  end

  local function initPaints()
    paint_point = Paint()
    .setColor(0x757575)
    .setStrokeWidth(2)
    .setStrokeCap(Paint.Cap.ROUND)
    .setDither(true)

    paint_line = Paint()
    .setColor(0x757575)
    .setStrokeWidth(1)
    .setStrokeCap(Paint.Cap.ROUND)
    .setDither(true)
  end

  local function generateParticles()
    points = {}
    for i = 1, 200 do
      table.insert(points, {
        sv = {
          x = math.random() * 4 - 2,
          y = math.random() * 4 - 2,
        },
        x = math.random(0, scr_w),
        y = math.random(0, scr_h),
      })
    end
  end

  local function updateParticles()
    for k, point in ipairs(points) do
      local x, y = point.x, point.y
      local sx, sy = point.sv.x, point.sv.y

      -- 更新位置
      x = x + sx
      y = y + sy

      -- 修改后的速度控制逻辑
      if distance(sx, sy) > 4 then
        -- 如果速度过快，则减速
        sy = sy * 0.97
        sx = sx * 0.97
       else
        -- 如果速度较慢，则小幅随机扰动，而不是加速
        sx = sx + (math.random() - 0.5) * 0.1
        sy = sy + (math.random() - 0.5) * 0.1
      end
      -- 边界碰撞
      if wall then
        if x < 0 then
          x = 0
          sx = -sx * 0.8
          sy = sy + (math.random()-0.5)*0.2
         elseif x > scr_w then
          x = scr_w
          sx = -sx * 0.8
          sy = sy + (math.random()-0.5)*0.2
        end

        if y < 0 then
          y = 0
          sy = -sy * 0.8
          sx = sx + (math.random()-0.5)*0.2
         elseif y > scr_h then
          y = scr_h
          sy = -sy * 0.8
          sx = sx + (math.random()-0.5)*0.5
        end
      end

      point.x, point.y = x, y
      point.sv.x, point.sv.y = sx, sy
    end
  end

  local function drawParticles(canvas)
    -- 绘制连接线
    for k, point in ipairs(points) do
      local x, y = point.x, point.y
      local connect_strength = 0
      local connected = {}

      for r, spoint in ipairs(points) do
        if r == k then goto continue end

        local dx, dy = spoint.x - x, spoint.y - y
        local dist = distance(dx, dy)

        if dist < connect_range then
          if #connected < 4 then
            table.insert(connected, spoint)
          end

          local pstrength = (1 - dist/connect_range)^2
          connect_strength = connect_strength + pstrength
          if connect_strength > 0.5 then break end
        end

::continue::
      end

      local alpha = math.min(connect_strength * 512, 255)

      for r, spoint in ipairs(connected) do
        paint_line.setAlpha(alpha / 3)
        canvas.drawLine(x, y, spoint.x, spoint.y, paint_line)
      end

      paint_point.setAlpha(alpha)
      canvas.drawPoint(x, y, paint_point)
    end
  end

  local last_time = os.clock() -- 记录上一帧时间

  local function animationLoop(drawable)
    if not is_running then return end
    local current_time = os.clock()
    local delta_time = current_time - last_time -- 计算时间差
    last_time = current_time
    -- 根据 delta_time 调整更新逻辑（可选）
    updateParticles()
    drawable.invalidateSelf()
    -- cardView.post(animationLoop, drawable)  -- 直接 post，不延迟
  end

  -- 公共接口
  local particleSystem = {}

  function particleSystem.init()
    scr_w = cardView.getWidth()
    scr_h = cardView.getHeight()

    if scr_w == 0 or scr_h == 0 then
      scr_w, scr_h = cardView.getMeasuredWidth(), cardView.getMeasuredHeight()
    end

    connect_range = scr_w / 9
    split_range = connect_range / 2

    initPaints()
    generateParticles()
  end

  function particleSystem.start()
    if is_running then return end

    is_running = true
    cardView.setBackground(LuaDrawable(function(canvas, paint, drawable)
      canvas.drawColor(0xff313131)
      drawParticles(canvas)
      animationLoop(drawable)
    end))
  end

  function particleSystem.stop()
    is_running = false
  end

  function particleSystem.setWallMode(enabled)
    wall = enabled
  end

  function particleSystem.resize(w, h)
    scr_w = w
    scr_h = h
    connect_range = scr_w / 9
    split_range = connect_range / 2
    generateParticles()
  end

  return particleSystem
end

return base
-- 可以通过以下方式控制：
-- particleSystem.stop()
-- particleSystem.setWallMode(false)
-- particleSystem.resize(newWidth, newHeight)