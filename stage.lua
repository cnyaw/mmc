local BLOCK = 80
local MAX_COL = 6

SelStage = {}

SelStage.OnCreate = function(param)
  SetBkg(param._id, false)

  local dummy = Good.GenDummy(-1)
  Good.SetPos(dummy, 0, 170)

  param.p = {}

  local lv = 18                         -- First level.
  local idx = 0
  while true do
    local o
    if (idx + 1 > hilvl) then
      o = GenTexObj(dummy, 530, 32, 32)
    else
      o = Good.GenObj(dummy, 4, 'BaseBlock')
    end
    local s = GenNumbers(2, idx + 1)
    Good.SetPos(s, -5, 35)
    Good.AddChild(o, s)
    local row = math.floor(idx / MAX_COL)
    local col = idx % MAX_COL
    Good.SetPos(o, col * BLOCK + (BLOCK - 32)/2, row * BLOCK)
    param.p[idx] = lv
    idx = idx + 1
    lv = Resource.GetNextLevelId(lv)
    if (-1 >= lv) then
      break
    end
  end
end

SelStage.OnStep = function(param)
  if (Input.IsKeyPushed(Input.LBUTTON)) then
    local x,y = Input.GetMousePos()
    local W,H = Good.GetWindowSize()
    if (not PtInRect(x, y, 0, 170, W, H)) then
      return
    end
    local col = math.floor(x / BLOCK)
    if (MAX_COL <= col) then
      return
    end
    local row = math.floor((y - 170) / BLOCK)
    local idx = col + row * MAX_COL
    if (#param.p < idx) then
      return
    end
    local lv = param.p[idx] 
    if (idx + 1 > hilvl) then
      return
    end
    currlvl = idx + 1
    Good.GenObj(-1, lv)                 -- Start lv.
    PlaySound(552)
  elseif (Input.IsKeyPushed(Input.ESCAPE)) then
    Good.GenObj(-1, 141)                -- Back to title.
  end
end
