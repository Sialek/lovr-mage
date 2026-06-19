local debugHelper = Class:extend()

debugHelper.graphics = {}

function debugHelper:new()

end

local referenceKindColors = {
  origin = { 1, 1, 1, 1 },
  joint = { 1, 0.9, 0.2, 1 },
  slot = { 0.2, 0.9, 1, 1 },
}

function debugHelper.graphics.drawReferencePoint(pass, position, kind)
  local color = referenceKindColors[kind] or referenceKindColors.joint
  pass:setColor(color[1], color[2], color[3], color[4])
  pass:sphere(position, kind == 'origin' and 0.015 or 0.025)
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

function debugHelper.graphics.drawWorldAxisGrid(pass, extent)
  local extent = extent or 100
  local step = 10

  local origin = vector(0, 0, 0)
  local xAxis = vector(1, 0, 0)
  local yAxis = vector(0, 1, 0)
  local zAxis = vector(0, 0, 1)

  pass:push()

  pass:setColor(1, 1, 1, 1)
  pass:sphere(origin, 1)
  
  -- Draw Main axis
  pass:setColor(1, 0, 0, 1)
  pass:line(xAxis * -extent, xAxis * extent)
  pass:setColor(0, 1, 0, 1)
  pass:line(yAxis * -extent, yAxis * extent)
  pass:setColor(0, 0, 1, 1)
  pass:line(zAxis * -extent, zAxis * extent)


  -- Draw plane grids
  for i = -extent, extent, step do
    if i ~= 0 then
      pass:setColor(0.9, 0, 0, 0.5)
      pass:line(vector(-extent, i, 0), vector(extent, i, 0))
      pass: line(vector(-extent, 0, i), vector(extent, 0, i))

      pass:setColor(0, 0.9, 0, 0.5)
      pass:line(vector(i, -extent, 0), vector(i, extent, 0))
      pass: line(vector(0, -extent, i), vector(0, extent, i))
      
      pass:setColor(0, 0, 0.9, 0.5)
      pass:line(vector(i, 0, -extent), vector(i, 0, extent))
      pass: line(vector(0, i, -extent), vector(0, i, extent))
    end
  end

  pass:pop()

end

return debugHelper