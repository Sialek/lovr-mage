local bodyReferencePoint = Class:extend()

function bodyReferencePoint:new(name, position, kind, rotation)
  self.name = name
  self.position = position or vector(0, 0, 0)
  self.kind = kind or 'joint'
  self.rotation = rotation or quaternion(0, 0, 0, 1)
end

function bodyReferencePoint:getWorldPosition(partPosition, partRotation)
  return partPosition + partRotation * self.position
end

function bodyReferencePoint:getWorldRotation(partRotation)
  return partRotation * self.rotation
end

function bodyReferencePoint:drawDebug(pass, worldPosition, showOrigin)
  if self.kind == 'origin' and not showOrigin then
    return
  end
  debugHelper.graphics.drawReferencePoint(pass, worldPosition, self.kind)
end

return bodyReferencePoint
