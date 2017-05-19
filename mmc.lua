math.randomseed(os.clock())

local TILE_W, TILE_H = 32, 32
local MAP_W, MAP_H = 7, 8
local POWER_COUNTER = 80
local DIGIT_W, DIGIT_H = 22, 26
local BTN_W, BTN_H = 72, 72
local BTN2_W, BTN2_H = 60, 60

local ColorPower = 363
local Color = {4, 6, 8, 10, 12, 14}
local next1, next2, next3 = 21, 22, 23

local fix = 0                           -- How many fix blocks in challenge mode.

hiscore = nil                           -- Global Hi-Score.
hiscore2 = nil                          -- Global Hi-Score challenge mode.
hilvl = 1                               -- Global Hi-Level.
local score = 0
local delta = 0
currlvl = 1
currPowCount = 20
enable_sound = 1

local W,H = Good.GetWindowSize()
local btnleft, btnright, btnup, btndown, btnenter
local btnLeftDown, btnRightDown, btnUpDown, btnDownDown, btnEnterDown = false, false, false, false, false

if (nil == hiscore) then
  local inf = io.open("mmc303.sav", "r")
  if (nil == inf) then
    hiscore = 0
    hiscore2 = 0
    hilvl = 1
    enable_sound = 1
  else
    hiscore,hiscore2,hilvl,enable_sound = inf:read("*number", "*number", "*number", "*number")
    inf:close()
  end
end

function SaveState()
  local outf = io.open("mmc303.sav", "w")
  outf:write(hiscore," ", hiscore2, " ", hilvl, " ", enable_sound)
  outf:close()
end

function PlaySound(id)
  if (1 == enable_sound) then
    Sound.PlaySound(id)
  end
end

function checkToggleSound()
  if (Input.IsKeyPushed(Input.LBUTTON)) then
    local mx,my = Input.GetMousePos()
    local x,y = Good.GetPos(btnSound)
    if (PtInRect(mx, my, x - 20, y - 20, x + 60, y + 60)) then
      if (1 == enable_sound) then
        enable_sound = 0
        Good.SetBgColor(btnSound, 0xff606060)
      else
        enable_sound = 1
        Good.SetBgColor(btnSound, 0xffffffff)
      end
      SaveState()
      return true
    end
  end
  return false
end

local hitMap = {}                       -- This map is for performance improvement.

ScoreBlock = {}

ScoreBlock.OnStep = function(param)
  if (param.time > param.step) then
    Good.KillObj(param._id)
    delta = delta + 1
    PlaySound(547)
    return
  end

  local dt = param.time / param.step
  local u2 = dt * dt
  local nu2 = (1 - dt) * (1 - dt)
  local ux = dt * (1 - dt)
  local x = param.x * nu2 + param.cx * 2 * ux + param.dx * u2;
  local y = param.y * nu2 + param.cy * 2 * ux + param.dy * u2;

  Good.SetPos(param._id, x, y)

  param.time = param.time + 1
end

FixBlock = {}

FixBlock.OnCreate = function(param)
  local id = param._id
  Good.SetDim(id, 0, 0, TILE_W, TILE_H)
  param.time = 0
end

FixBlock.OnStep = function(param)
  local id = param._id
  param.time = param.time + 1
  if (60 < param.time) then
    param.time = 0
  end
  local d = math.floor(0xf0 * (1 - math.sin(math.pi * param.time/60)))
  Good.SetBgColor(id, 0xffffff + d * 0x1000000)
end

BaseBlock = {}

BaseBlock.OnStep = function(param)
  if (nil == param.nextPlay) then
    param.nextPlay = 300 + math.random(500)
    Good.StopAnim(param._id)
    return
  end

  param.nextPlay = param.nextPlay - 1
  if (0 < param.nextPlay) then
    return
  end
  param.nextPlay = 300 + math.random(500)

  Good.PlayAnim(param._id)
end

BaseBlock.OnDestroy = function(param)
  local id = param._id
  if (Good.SPRITE == Good.GetType(id) and 0 < fix) then
    if (nil ~= Good.GetParam(id).fix) then
      fix = fix - 1
    end
  end
end

function randColor()
  return Color[math.random(6)]
end

function newNext(param)
  local a,b,c = Good.GetSpriteId(next1), Good.GetSpriteId(next2), Good.GetSpriteId(next3)
  if (POWER_COUNTER <= currPowCount) then
    Good.SetSpriteId(next1, ColorPower)
    Good.SetSpriteId(next2, ColorPower)
    Good.SetSpriteId(next3, ColorPower)
    if (0 == MainMenu) then             -- Normal mode.
      currPowCount = currPowCount - POWER_COUNTER
      GenPowerMeter(param)
    end
  else
    Good.SetSpriteId(next1, randColor())
    Good.SetSpriteId(next2, randColor())
    Good.SetSpriteId(next3, randColor())
  end
  return a,b,c
end

function moveBar(param, ox, oy)
  for i = 1, 3 do
    local x, y = Good.GetPos(param.bar[i])
    Good.SetPos(param.bar[i], x + ox, y + oy)
  end
end

function checkFreeze(param, x, y)
  if (param.mapy + (2 + MAP_H) * TILE_H <= y or
      -1 ~= Good.PickObj(x, y + TILE_H, Good.SPRITE)) then
    param.timer = 15
    param.stage = stageFreeze
    PlaySound(571)
    return true
  end

  return false
end

Level = {}

Level.OnCreate = function(param)
  PlaySound(576)

  local map = Good.FindChild(param._id, 'map')
  local x, y = Good.GetPos(map)
  param.mapx = x
  param.mapy = y
  param.gameover = false
  param.timer = 0
  param.stage = stageFall

  SetBkg(param._id)
  Good.SetBgColor(map, 0xffff4040)

  param.map = Good.GenDummy(map)
  Good.SetPos(param.map, -param.mapx, -param.mapy)

  fix = 0
  local om = {}
  local nc = Good.GetChildCount(param._id)
  for i = 0, nc - 1 do
    om[i] = Good.GetChild(param._id, i)
  end
  for i = 0, nc - 1 do
    local o = om[i]
    if (Good.SPRITE == Good.GetType(o)) then
      local dummy = Good.GenDummy(param.map)
      Good.SetScript(o, 'BaseBlock')
      local p = Good.GetParam(o)
      p.fix = true
      Good.AddChild(dummy, o)
      local o2 = Good.GenObj(dummy, -1, 'FixBlock')
      Good.SetPos(o2, Good.GetPos(o))
      p.o2 = o2
      fix = fix + 1
    end
  end

  next1 = Good.GenObj(param.map, 4, 'BaseBlock')
  Good.SetPos(next1, x - TILE_W, y + 2 * TILE_H)
  next2 = Good.GenObj(param.map, 4, 'BaseBlock')
  Good.SetPos(next2, x - TILE_W, y + 3 * TILE_H)
  next3 = Good.GenObj(param.map, 4, 'BaseBlock')
  Good.SetPos(next3, x - TILE_W, y + 4 * TILE_H)

  newNext(param)

  local yy = y - 3 * TILE_H
  local msgScore = Good.GenObj(-1, 340)
  Good.SetPos(msgScore, TILE_W, TILE_H/2)
  local msgHiScore = Good.GenObj(-1, 339)
  Good.SetPos(msgHiScore, W - 5 * TILE_W, TILE_H/2)

  local msgNext = Good.GenObj(-1, 362)
  Good.SetPos(msgNext, x - TILE_W, y)

  score = 0
  delta = 0
  UpdateScore(param)
  UpdateLevel(param)

  btnleft = Good.GenObj(-1, 365)
  Good.SetPos(btnleft, (W - BTN_W)/2 - 1.3 * BTN_W, H - 2.3 * BTN_H)
  btnright = Good.GenObj(-1, 366)
  Good.SetPos(btnright, (W - BTN_W)/2 + 1.3 * BTN_W, H - 2.3 * BTN_H)
  btnup = Good.GenObj(-1, 367)
  Good.SetPos(btnup, (W - BTN_W)/2, H - 3.3 * BTN_H)
  btndown = Good.GenObj(-1, 0)
  Good.SetPos(btndown, (W - BTN_W)/2, H - 1.1 * BTN_H)
  btnenter = Good.GenObj(-1, 370)
  Good.SetPos(btnenter, (W - BTN2_W)/2, H - 2.1 * BTN_H)

  if (0 == MainMenu) then               -- Normal mode.
    local m1 = GenTexObj(-1, 520, 16, 100)
    Good.SetPos(m1, x + 8, y + 2 * TILE_H - 2)
    Good.SetBgColor(m1, 0x40ffffff)
    GenPowerMeter(param)
  end
end

function GenPowerMeter(param)
  if (nil ~= param.m2) then
    Good.KillObj(param.m2)
  end
  local dy = math.floor(100 * currPowCount / POWER_COUNTER)
  local m2 = GenTexObj(-1, 520, 16, dy, 0, 100 - dy)
  Good.SetPos(m2, param.mapx + 8, param.mapy + 2 * TILE_H + 100 - dy - 2)
  param.m2 = m2
end

function ShowMenu(param)
  local dummy = Good.GenDummy(-1)
  Good.SetPos(dummy, param.mapx + 2 * TILE_W, param.mapy + TILE_H)
  local b = Good.GenObj(dummy, -1)
  Good.SetDim(b, 0, 0, TILE_W * MAP_W, TILE_H * (1 + MAP_H))
  Good.SetBgColor(b, 0xc0000000)
  Good.SetPos(b, 0, TILE_H)
  local o = Good.GenObj(dummy, 329)
  if (param.gameover) then
    Good.SetDim(o, 0, 35, 154, 70)
  end
  Good.SetPos(o, 42, 110)
  local tri = Good.GenObj(dummy, 331)
  Good.SetPos(tri, 0, 105)
  Good.SetRot(tri, 90)
  Good.SetAnchor(tri, 0.5, 0.5)
  param.menu = dummy
  param.menu2 = o
  param.tri = tri
  param.sel = 0
  Good.PauseAnim(param.map)
end

Level.OnStep = function(param)
  if (checkToggleSound()) then
    return
  end

  local mx,my = Input.GetMousePos()
  local MouseDown = Input.IsKeyPushed(Input.LBUTTON)
  local bx,by = Good.GetPos(btnleft)
  btnLeftDown = MouseDown and PtInRect(mx, my, bx - 2 * TILE_W, by - 5, bx + BTN_W + 10, by + BTN_H + 10)
  bx,by = Good.GetPos(btnright)
  btnRightDown = MouseDown and PtInRect(mx, my, bx - 10, by - 5, bx + 2 * BTN_W, by + BTN_H + 10)
  bx,by = Good.GetPos(btnup)
  btnUpDown = MouseDown and PtInRect(mx, my, bx - 5, by - 5, bx + BTN_W + 10, by + BTN_H + 10)
  bx,by = Good.GetPos(btndown)
  btnDownDown = MouseDown and PtInRect(mx, my, bx - 5, by - 5, bx + BTN_W + 10, by + BTN_H + 10)
  bx,by = Good.GetPos(btnenter)
  btnEnterDown = MouseDown and PtInRect(mx, my, bx - 5, by - 5, bx + BTN2_W + 10, by + BTN2_H + 10)

  if (nil ~= param.menu) then
    local x, y = Good.GetPos(param.tri)
    if (Input.IsKeyPushed(Input.UP) or btnUpDown) then
      if (0 < param.sel) then
        param.sel = param.sel - 1
        Good.SetPos(param.tri, x, y - 34)
        PlaySound(552)
      end
    elseif (Input.IsKeyPushed(Input.DOWN) or btnDownDown) then
      local m = 2
      if (param.gameover) then
        m = 1
      end
      if (m > param.sel) then
        param.sel = param.sel + 1
        Good.SetPos(param.tri, x, y + 34)
        PlaySound(552)
      end
    elseif (Input.IsKeyPushed(Input.ESCAPE)) then
      if (not param.gameover) then
        Good.KillObj(param.menu)
        param.menu = nil
        Good.PlayAnim(param.map)
      end
    else
      local click = CheckTouchMenuItem(param, param.tri, param.menu2, 34)
      if (click or Input.IsKeyPushed(Input.RETURN + Input.BTN_A) or btnEnterDown) then
        if (param.gameover) then
          if (0 == param.sel) then        -- New game.
            Good.GenObj(-1, param._id)
          elseif (1 == param.sel) then    -- Back to title.
            Good.GenObj(-1, 141)
          end
        else
          if (0 == param.sel) then        -- Resume.
            Good.KillObj(param.menu)
            param.menu = nil
            Good.PlayAnim(param.map)
          elseif (1 == param.sel) then    -- New game.
            Good.GenObj(-1, param._id)
          elseif (2 == param.sel) then    -- Back to title.
            Good.GenObj(-1, 141)
          end
        end
      end
    end
    return
  end

  if (0 < delta) then
    UpdateScore(param)
  end

  param.stage(param)

  if (Input.IsKeyPushed(Input.ESCAPE)) then
    if (nil == param.msg) then          -- Not game finish.
      ShowMenu(param)
    end
  end
end

function stageFall(param)
  local m = param.map
  local a,b,c = newNext(param)
  param.bar = {Good.GenObj(m,a),Good.GenObj(m,b),Good.GenObj(m,c)}

  for i = 1, 3 do
    Good.SetPos(param.bar[i], param.mapx + 5 * TILE_W, param.mapy + 2 * TILE_H + TILE_H * (i - 4))
    Good.SetScript(param.bar[i], 'BaseBlock')
  end

  param.stage = stageFalling
end

local CROSS_DIR = {-1, 0, -2, 0, 1, 0, 2, 0, 0, 1, 0, 2, 0, -1, 0, -2, -1, 1, -2, 2, 1, -1, 2, -2, -1, -1, -2, -2, 1, 1, 2, 2}

function GenNumbers(digit, n)
  local s = string.format('%d', n)
  if (digit > string.len(s)) then
    for i = 1, digit - string.len(s) do
      s = '0' .. s
    end
  end

  local dummy = Good.GenDummy(-1)

  for i = 1, digit do
    local o = Good.GenObj(dummy, 153)
    Good.SetDim(o, DIGIT_W * (string.byte(s, i) - 48), 0, DIGIT_W, DIGIT_H)
    Good.SetPos(o, DIGIT_W * (i - 1), 0)
    Good.SetBgColor(o, 0xffffffff)
  end

  return dummy
end

function UpdateScore(param)
  score = score + delta
  if (999999 < score) then
    score = 999999
  end

  if (0 == MainMenu) then               -- Normal mode.
    currPowCount = currPowCount + delta
    if (POWER_COUNTER <= currPowCount) then
      newNext(param)
    else
      GenPowerMeter(param)
    end
  end

  if (1 == MainMenu) then               -- Challenge mode.
    if (score > hiscore2) then
      hiscore2 = score
      SaveState()
    end
  else
    if (score > hiscore) then
      hiscore = score
      SaveState()
    end
  end

  if (nil ~= param.hiscore) then
    Good.KillObj(param.hiscore)
  end
  if (1 == MainMenu) then
    param.hiscore = GenNumbers(6, hiscore2)
  else
    param.hiscore = GenNumbers(6, hiscore)
  end
  Good.SetPos(param.hiscore, W - 5 * TILE_W, 2 * TILE_H)

  if (nil ~= param.score) then
    Good.KillObj(param.score)
  end
  param.score = GenNumbers(6, score)
  Good.SetPos(param.score, TILE_W, 2 * TILE_H)

  delta = 0
end

function UpdateLevel(param)
  if (0 == MainMenu) then
    return
  end
  if (nil ~= param.currlvl) then
    Good.KillObj(param.currlvl)
  end
  param.currlvl = GenNumbers(2, currlvl)
  Good.SetPos(param.currlvl, (W - 2 * DIGIT_W)/2, TILE_H/2)
end

function checkClearCross(c, r, spr)
  local match, hit
  for i = 0, 3 do
    match = 1
    hit = pickObj(c + CROSS_DIR[8 * i + 1], r + CROSS_DIR[8 * i + 2])
    if (-1 ~= hit and
        (Good.GetSpriteId(hit) == spr or
         Good.GetSpriteId(hit) == spr + 1)) then
      match = match + 1
      hit = pickObj(c + CROSS_DIR[8 * i + 3], r + CROSS_DIR[8 * i + 4])
      if (-1 ~= hit and
          (Good.GetSpriteId(hit) == spr or
           Good.GetSpriteId(hit) == spr + 1)) then
        return true
      end
    end

    hit = pickObj(c + CROSS_DIR[8 * i + 5], r + CROSS_DIR[8 * i + 6])
    if (-1 ~= hit and
        (Good.GetSpriteId(hit) == spr or
         Good.GetSpriteId(hit) == spr + 1)) then
      match = match + 1
      if (2 < match) then
        return true
      end
      hit = pickObj(c + CROSS_DIR[8 * i + 7], r + CROSS_DIR[8 * i + 8])
      if (-1 ~= hit and
          (Good.GetSpriteId(hit) == spr or
           Good.GetSpriteId(hit) == spr + 1)) then
        return true
      end
    end
  end

  return false
end

function stageClear(param)
  param.timer = param.timer - 1
  if (0 < param.timer) then
    return
  end

  for i = 0, MAP_W - 1 do
    local x = 2 * TILE_W + TILE_W * i
    for j = -1, MAP_H - 1 do
      local y = 2 * TILE_H + TILE_H * j
      local hit = pickObj(i, j)
      if (-1 ~= hit and nil ~= Good.GetParam(hit).markClear) then
        Good.KillObj(hit)
        local o = Good.GenObj(param.map, -1, 'ScoreBlock')
        Good.SetDim(o, 0, 0, 5, 5)
        Good.SetBgColor(o, 0xffff0000)
        local p = Good.GetParam(o)
        p.x = param.mapx + x
        p.y = param.mapy + y
        p.dx = 4.5 * TILE_W
        p.dy = 2 * TILE_H
        p.cx = (p.x + p.dx)/2 + 15 - math.random(30)
        p.cy = (p.y + p.dy)/2 + 15 - math.random(30)
        p.step = 30 + math.random(30)
        p.time = 0
      end
    end
  end

  param.stage = stageArrange
end

function stageArrange(param)
  local nArrange = false
  for i = 0, MAP_W - 1 do
    for j = MAP_H - 1, -1, -1 do
      local hit = pickObj(i, j - 1)
      if (-1 ~= hit) then
        if (Good.GetParent(hit) == param.map) then
          local x, y = Good.GetPos(hit)
          if (param.mapy + (2 + MAP_H) * TILE_H > y and
              -1 == Good.PickObj(x, y + TILE_H, Good.SPRITE)) then
            local x2, y2 = Good.GetPos(hit)
            Good.SetPos(hit, x2, y2 + 8)
            nArrange = true
          end
        end
      end
    end
  end

  if (not nArrange) then
    buildHitMap(param)
    param.stage = stageCheck
  end
end

function DestroyMap(param)
  Good.AddChild(param._id, next1)
  Good.AddChild(param._id, next2)
  Good.AddChild(param._id, next3)
  local nc = Good.GetChildCount(param.map)
  for i = 0, nc - 1 do
    local id = Good.GetChild(param.map, i)
    Good.StopAnim(id)
    Good.SetSpriteId(id, Good.GetSpriteId(id) + 1)
    Good.PlayAnim(id)
  end
end

function buildHitMap(param)
  hitMap = {}
  for i = 0, MAP_W - 1 do
    local x = 2 * TILE_W + TILE_W * i
    for j = -1, MAP_H - 1 do
      local y = 3 * TILE_H + TILE_H * j
      local hit = Good.PickObj(param.mapx + x, param.mapy + y, Good.SPRITE)
      local xy = i + j * (4 * MAP_W)
      hitMap[xy] = hit
    end
  end
end

function pickObj(x, y)
  local xy = x + y * (4 * MAP_W)
  local hit = hitMap[xy]
  if (nil == hit) then
    return -1
  else
    return hit
  end
end

function stageCheck(param)
  if (nil ~= param.powClr) then
    for i = 0, MAP_W - 1 do
      for j = -1, MAP_H - 1 do
        local hit = pickObj(i, j)
        if (-1 ~= hit) then
          local spr = Good.GetSpriteId(hit)
          if (param.powClr == spr or ColorPower == spr) then
            Good.StopAnim(hit)
            Good.SetSpriteId(hit, spr + 1)
            Good.PlayAnim(hit)
            Good.GetParam(hit).markClear = true
          end
        end
      end
    end
    param.timer = 35
    param.stage = stageClear
    param.powClr = nil
    PlaySound(553)
    return
  end

  local nClear = 0
  for i = 0, MAP_W - 1 do
    for j = -1, MAP_H - 1 do
      local hit = pickObj(i, j)
      if (-1 ~= hit) then
        local spr = Good.GetSpriteId(hit)
        if (checkClearCross(i, j, spr)) then
          local p = Good.GetParam(hit)
          if (nil ~= p.o2) then
            Good.KillObj(p.o2)
          end
          Good.StopAnim(hit)
          Good.SetSpriteId(hit, spr + 1)
          p.markClear = true
          Good.PlayAnim(hit)
          nClear = nClear + 1
        end
      end
    end
  end

  if (0 ~= nClear) then
    param.timer = 35
    param.stage = stageClear
    PlaySound(553)
    return
  end

  if (0 ~= fix or 0 == MainMenu) then   -- Normal mode.
    param.stage = stageFall
  elseif (1 == MainMenu) then           -- Challenge mode.
    DestroyMap(param)
    param.timer = 45
    param.stage = stageComplete
    PlaySound(572)
  end
end

function stageFreeze(param)
  local x, y = Good.GetPos(param.bar[3])
  param.timer = param.timer - 1
  if (0 >= param.timer) then
    local pick = Good.PickObj(x, y + TILE_H, Good.SPRITE)
    if (param.mapy + (2 + MAP_H) * TILE_H <= y or -1 ~= pick) then
      if (-1 ~= pick and param.mapy + 3 * TILE_H >= y) then
        DestroyMap(param)
        param.timer = 45
        param.stage = stageOver
      else
        if (ColorPower == Good.GetSpriteId(param.bar[3])) then
          param.powClr = Good.GetSpriteId(pick)
        end
        param.stage = stageCheck
        buildHitMap(param)
      end
    else
      param.stage = stageFalling
    end
  elseif (Input.IsKeyPushed(Input.LEFT) or btnLeftDown) then
    x = x - TILE_W
    if (param.mapx + 2 * TILE_W <= x and
        -1 == Good.PickObj(x, y, Good.SPRITE)) then
      moveBar(param, -TILE_W, 0)
      param.timer = 15
      PlaySound(552)
    end
  elseif (Input.IsKeyPushed(Input.RIGHT) or btnRightDown) then
    x = x + TILE_W
    if (param.mapx + (2 + MAP_W) * TILE_W > x and
        -1 == Good.PickObj(x, y, Good.SPRITE)) then
      moveBar(param, TILE_W, 0)
      param.timer = 15
      PlaySound(552)
    end
  end
end

function stageFallDirect(param)
  local x, y = Good.GetPos(param.bar[3])
  if (checkFreeze(param, x, y)) then
    return
  end
  moveBar(param, 0, 16)
end

function stageFalling(param)
  local x, y = Good.GetPos(param.bar[3])
  if (checkFreeze(param, x, y)) then
    return
  end

  if (Input.IsKeyPushed(Input.UP + Input.BTN_A) or btnUpDown) then -- Rotate bar.
    local spr1 = Good.GetSpriteId(param.bar[1])
    Good.SetSpriteId(param.bar[1], Good.GetSpriteId(param.bar[2]))
    Good.SetSpriteId(param.bar[2], Good.GetSpriteId(param.bar[3]))
    Good.SetSpriteId(param.bar[3], spr1)
    PlaySound(552)
  elseif (Input.IsKeyPushed(Input.LEFT) or btnLeftDown) then -- Move bar left.
    x = x - TILE_W
    if (param.mapx + 2 * TILE_W <= x and
        -1 == Good.PickObj(x, y + TILE_H - 1, Good.SPRITE)) then
      moveBar(param, -TILE_W, 0)
      PlaySound(552)
    end
  elseif (Input.IsKeyPushed(Input.RIGHT) or btnRightDown) then -- Move bar right.
    x = x + TILE_W
    if (param.mapx + (2 + MAP_W) * TILE_W > x and
        -1 == Good.PickObj(x, y + TILE_H - 1, Good.SPRITE)) then
      moveBar(param, TILE_W, 0)
      PlaySound(552)
    end
  elseif (Input.IsKeyPushed(Input.DOWN) or btnDownDown) then -- Move bar down immediately.
    moveBar(param, 0, TILE_H - (math.floor(y - param.mapy) % TILE_H))
    param.stage = stageFallDirect
    PlaySound(552)
    return
  end

  moveBar(param, 0, 0.5)
end

function stageOver(param)
  param.timer = param.timer - 1
  if (0 < param.timer) then
    return
  end
  PlaySound(570)
  param.gameover = true
  Good.KillObj(param.map)
  ShowMenu(param)
end

function stageComplete(param)
  param.timer = param.timer - 1
  if (0 < param.timer) then
    return
  end

  Good.KillObj(param.map)

  local o = Good.GenObj(-1, 147)
  local x,y,w,h = Good.GetDim(o)
  Good.SetScale(o, 0, 0)
  Good.SetPos(o, (W - w)/2, param.mapy + 5 * TILE_H)
  Good.SetAnchor(o, 0.5, 0.5)

  param.msg = o
  param.time = 0

  param.stage = stageComplete2
end

local bcolor = {0xffff0000,0xff00ff00,0xffffff00,0xff0000ff,0xffff00ff,0xffffffff}
local fragment = {525, 574, 575}

Level.OnNewParticle = function(param, particle)
  local o = Good.GenObj(-1, fragment[math.random(3)])
  Good.SetBgColor(o, bcolor[math.random(6)])
  Stge.BindParticle(particle, o)
end

Level.OnKillParticle = function(param, particle)
  Good.KillObj(Stge.GetParticleBind(particle))
end

function stageComplete2(param)
  if (30 > param.time) then
    param.time = param.time + 1
    local s = math.sin(math.pi * param.time/40)
    Good.SetScale(param.msg, s, s)
  elseif (nil == param.fx) then
    param.fx = Stge.RunScript('_rain')
  end

  if (Input.IsKeyPushed(Input.ANY)) then
    local nextLvl = Resource.GetNextLevelId(param._id)
    if (-1 ~= nextLvl) then
      currlvl = currlvl + 1
      Good.GenObj(-1, nextLvl)
      if (currlvl > hilvl) then
        hilvl = currlvl
        SaveState()
      end
    else
      Good.GenObj(-1, 141)              -- All stages clear, back to title.
    end
  end
end
