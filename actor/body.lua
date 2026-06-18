local body = Class:extend()

function body:new(bodyPlanFilename, modelFilename)
  self.position = vector(0, 0, 0)
  self.rotation = quaternion(0, 0, 0, 1)
  self.scale = vector(1, 1, 1)

  self.bodyPlanFilename = bodyPlanFilename
  self.bodyPlan = nil

  self.modelFilename = modelFilename
  self.model = nil
  
  self.bodyParts = {}
end

function body:load()
  local bodyPlanFile, error = lovr.filesystem.read(self.bodyPlanFilename)
  if not bodyPlanFile or error then
    print(error)
    return
  end
  self.bodyPlan = lovr.json.decode(self.bodyPlanFilename)
  self.model = lovr.graphics.newModel(self.modelFilename)
end

function body:update(dt)
  for part in pairs(self.bodyParts) do
    part:update(dt)
  end
end

function body:draw(pass)
  pass:push()
  
  pass:translate(self.position)
  pass:rotate(self.rotation)
  pass:scale(self.scale)

  if self.bodyParts then
    for part in pairs(self.bodyParts) do
      part:draw(pass)
    end
  elseif self.model then
    pass:draw(self.model)
  else
    lovr.graphics.setColor(0.5, 0.5, 0.5, 1)
    pass:sphere(vector(0, 1.6, 0), 0.25)
    pass:cube(vector(0, 1.3, 0), 0.25)
  end

  pass:pop()
end

return body
