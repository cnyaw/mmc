Help = {}

local function GenFix(o)
  local dummy = Good.GenDummy(-1)
  Good.AddChild(dummy, o)
  local o2 = Good.GenObj(dummy, -1, 'FixBlock')
  Good.SetPos(o2, Good.GetPos(o))
end

Help.OnCreate = function(param)
  SetBkg(param._id, false)
  GenFix(342)
  GenFix(343)
  GenFix(344)
  param.time = 0
  for i = 345, 353 do
    Good.StopAnim(i)
  end
end

Help.OnStep = function(param)
  if (40 == param.time) then
    for i = 345, 353 do
      local spr = Good.GetSpriteId(i)
      Good.SetSpriteId(i, spr + 1)
      Good.PlayAnim(i)
    end
  elseif (80 == param.time) then
    for i = 345, 353 do
      Good.SetVisible(i, 0)
    end
  elseif (120 <= param.time) then
    param.time = 0
    for i = 345, 353 do
      local spr = Good.GetSpriteId(i)
      Good.StopAnim(i)
      Good.SetSpriteId(i, spr - 1)
      Good.SetVisible(i, 1)
    end
  end
  param.time = param.time + 1

  if (Input.IsKeyPushed(Input.ESCAPE + Input.RETURN + Input.LBUTTON)) then
    Good.GenObj(-1, 141)
  end
end
