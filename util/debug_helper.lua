local debugHelper = Class:extend()

debugHelper.graphics = {}

function debugHelper:new()

end

function debugHelper.graphics.drawEmpty(pass, position, orientation, scale)
  local position = position or vector(0, 0, 0)
  local orientation = orientation or quaternion(0, 0, 0, 1)
  local scale = scale or vector(1, 1, 1)
  
  pass:push()

  pass:translate(position)
  pass:rotate(orientation)
  pass:scale(scale)

  -- Draw RGB XYZ axis
  pass:setColor(1, 0, 0, 1)
  pass:line(vector(0, 0, 0), vector(1, 0, 0))
  pass:setColor(0, 1, 0, 1)
  pass:line(vector(0, 0, 0), vector(0, 1, 0))
  pass:setColor(0, 0, 1, 1)
  pass:line(vector(0, 0, 0), vector(0, 0, 1))
  
  pass:pop()
end

return debugHelper