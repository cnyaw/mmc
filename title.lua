BG_COLOR = 0xffc0c0c0
btnSound = nil

function SetBkg(id, sound)
  Good.SetBgColor(id, BG_COLOR)
  local o = GenTexObj(-1, 369, 0, 0)
  local w,h = Resource.GetTexSize(369)
  local W,H = Good.GetWindowSize()
  local sw,sh = W/w, H/h
  Good.SetScale(o, sw, sh)
  Good.AddChild(id, o, 0)
  if (nil == sound) then
    btnSound = GenTexObj(-1, 559, 40, 40)
    Good.SetPos(btnSound, W - 2 * 32, H/2 + 32)
    if (1 == enable_sound) then
      Good.SetBgColor(btnSound, 0xffffffff)
    else
      Good.SetBgColor(btnSound, 0xff606060)
    end
  end
end

MainMenu = 0  -- Global menu index

function GetAbsPos(obj)
  local x, y = Good.GetPos(obj)
  local lvl = Good.GetLevelId()
  while true do
    obj = Good.GetParent(obj)
    if (lvl == obj) then
      break;
    end
    local x1, y1 = Good.GetPos(obj)
    x = x + x1
    y = y + y1
  end
  return x, y
end

function CheckTouchMenuItem(param, cursor, obj, cy)
  local click = false
  if (Input.IsKeyPushed(Input.LBUTTON)) then
    local x, y = Input.GetMousePos()
    if (obj == Good.PickObj(x, y, Good.TEXBG)) then
      local px, py = GetAbsPos(obj)
      local index = math.floor((y - py) / cy)
      PlaySound(552)
      if (index ~= param.sel) then
        local mx, my = Good.GetPos(cursor)
        if (index > param.sel) then
          Good.SetPos(cursor, mx, my + cy * (index - param.sel))
        else
          Good.SetPos(cursor, mx, my - cy * (param.sel - index))
        end
        param.sel = index
      else
        click = true
      end
    end
  end
  return click
end

Title = {}

Title.OnCreate = function(param)
  SetBkg(param._id)
  param.time = 0
  MainMenu = 0
  Good.SetBgColor(333, 0xaaff9b9b)
end

Title.OnStep = function(param)
  param.time = param.time + 1
  if (200 <= param.time) then
    param.time = 0
  end
  if (180 <= param.time and 200 > param.time) then
    Good.SetVisible(146, 1)
  else
    Good.SetVisible(146, 0)
  end

  local sel = 332
  local mx, my = Good.GetPos(sel)
  if (Input.IsKeyPushed(Input.UP)) then
    if (0 < MainMenu) then
      MainMenu = MainMenu - 1
      Good.SetPos(sel, mx, my - 40)
      PlaySound(552)
    end
  elseif (Input.IsKeyPushed(Input.DOWN)) then
    if (3 > MainMenu) then
      MainMenu = MainMenu + 1
      Good.SetPos(sel, mx, my + 40)
      PlaySound(552)
    end
  elseif (Input.IsKeyPushed(Input.ESCAPE)) then
    -- Skip.
  else
    local x = {}
    x.sel = MainMenu
    local click = CheckTouchMenuItem(x, sel, 151, 40)
    MainMenu = x.sel
    if (click or Input.IsKeyPushed(Input.RETURN + Input.BTN_A)) then
      if (0 == MainMenu) then
        Good.GenObj(-1, 155)              -- Normal mode.
      elseif (1 == MainMenu) then
        currlvl = 1
        Good.GenObj(-1, 526)              -- Challenge mode.
      elseif (2 == MainMenu) then         -- Help.
        Good.GenObj(-1, 334)
      elseif (3 == MainMenu) then         -- Exit game.
        Good.Exit()
      end
    end
  end

  checkToggleSound()
end
