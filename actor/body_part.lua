local bodyPart = Class:extend()

function bodyPart:new(modelFilename)
  self.position = vector(0, 0, 0)
  self.rotation = quaternion(0, 0, 0, 1)
  self.scale = vector(1, 1, 1)
  self.model = nil
  self.modelFilename = modelFilename
  self.referencePoints = {}
  self.placeholderShape = nil
end

function bodyPart:load()
  self.model = lovr.graphics.newModel(self.modelFilename)
end

function bodyPart:update(dt)

end

function bodyPart:draw(pass)
  if self.model then
    pass:draw(self.model)
  else
    draw
end

return bodyPart