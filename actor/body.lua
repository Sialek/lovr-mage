local body = Class:extend()

function body:new(bodyPlanFilename, modelFilename)
  self.position = vector(0, 0, 0)
  self.rotation = quaternion(0, 0, 0, 1)
  self.scale = vector(1, 1, 1)

  self.bodyPlanFilename = bodyPlanFilename
  self.modelFilename = modelFilename

  self.model = nil
end

function body:load()
  self.bodyPlan = json.load(self.bodyPlanFilename)
  self.model = lovr.graphics.newModel(self.modelFilename)
end

function body:update(dt)
  for part in pairs(self.bodyParts) do
    part:update(dt)
  end
end

function body:draw(pass)
  for part in pairs(self.bodyParts) do
    part:draw(pass)
  end
end

return body
