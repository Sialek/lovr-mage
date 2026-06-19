local debugHelper = Class:extend()

debugHelper.graphics = {}

function debugHelper:new()

end

local referenceKindColors = {
  origin = { 1, 1, 1, 1 },
  joint = { 1, 0.9, 0.2, 1 },
  slot = { 0.2, 0.9, 1, 1 },
}

function debugHelper.graphics.getDepthColor(depth)
  local hue = ((depth - 1) * 0.12) % 1.0
  local saturation = 0.85
  local value = 0.95

  local chroma = value * saturation
  local huePrime = hue * 6
  local x = chroma * (1 - math.abs(huePrime % 2 - 1))
  local r, g, b

  if huePrime < 1 then
    r, g, b = chroma, x, 0
  elseif huePrime < 2 then
    r, g, b = x, chroma, 0
  elseif huePrime < 3 then
    r, g, b = 0, chroma, x
  elseif huePrime < 4 then
    r, g, b = 0, x, chroma
  elseif huePrime < 5 then
    r, g, b = x, 0, chroma
  else
    r, g, b = chroma, 0, x
  end

  local m = value - chroma
  return r + m, g + m, b + m
end

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