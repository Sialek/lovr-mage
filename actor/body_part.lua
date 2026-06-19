local bodyReferencePoint = require 'actor.body_reference_point'

local bodyPart = Class:extend()

local defaultVisual = {
  shape = 'sphere',
  size = { 0.1, 0.1, 0.1 },
  offset = { 0, 0, 0 },
  color = { 0.5, 0.5, 0.5, 1 },
}

local function inferReferenceKind(name)
  if name == 'origin' then
    return 'origin'
  end
  if name:match('^slot_') then
    return 'slot'
  end
  return 'joint'
end

function bodyPart:new(partDefinition)
  self.id = partDefinition.id
  self.vital = partDefinition.vital
  self.visual = partDefinition.visual or defaultVisual
  self.attachJoint = partDefinition.attachJoint
  self.extensionRoot = partDefinition.extensionRoot or false
  self.extensionAttach = partDefinition.attach

  self.position = vector(0, 0, 0)
  self.rotation = quaternion(0, 0, 0, 1)
  self.referencePoints = {}
  self.children = {}

  for name, position in pairs(partDefinition.references) do
    self.referencePoints[name] = bodyReferencePoint(
      name,
      position,
      inferReferenceKind(name)
    )
  end
end

function bodyPart:addChild(child, attachJoint)
  child.attachJoint = attachJoint
  table.insert(self.children, child)
end

function bodyPart:resolveTransform(parentPosition, parentRotation, parentAttachJoint)
  if not parentAttachJoint then
    self.position = parentPosition or vector(0, 0, 0)
    self.rotation = parentRotation or quaternion(0, 0, 0, 1)
    return
  end

  if parentPosition and parentRotation and parentAttachJoint then
    local attachRef = self.parent.referencePoints[parentAttachJoint]
    if attachRef then
      self.position = attachRef:getWorldPosition(parentPosition, parentRotation)
      self.rotation = attachRef:getWorldRotation(parentRotation)
    else
      print('Warning: missing attach reference "' .. tostring(parentAttachJoint) .. '" on part "' .. self.parent.id .. '"')
      self.position = parentPosition
      self.rotation = parentRotation
    end
  end
end

function bodyPart:getReferenceWorld(referenceName)
  local ref = self.referencePoints[referenceName]
  if not ref then
    return nil
  end
  return ref:getWorldPosition(self.position, self.rotation)
end

function bodyPart:drawPlaceholder(pass)
  local visual = self.visual
  local color = visual.color or defaultVisual.color
  local offset = visual.offset or defaultVisual.offset
  local size = visual.size or defaultVisual.size
  local shape = visual.shape or defaultVisual.shape

  pass:setColor(color[1], color[2], color[3], color[4] or 1)
  pass:translate(offset[1] or 0, offset[2] or 0, offset[3] or 0)

  if shape == 'box' then
    pass:box(size[1] or 0.1, size[2] or 0.1, size[3] or 0.1)
  elseif shape == 'capsule' then
    local radius = size[1] or 0.1
    local length = size[2] or 0.2
    pass:capsule(vector(0, 0, 0), radius, length, 0, 90, 0, 0, 8)
  else
    local radius = size[1] or 0.1
    pass:sphere(vector(0, 0, 0), radius)
  end
end

function bodyPart:draw(pass)
  pass:push()
  pass:translate(self.position)
  pass:rotate(self.rotation)
  self:drawPlaceholder(pass)
  pass:pop()
end

function bodyPart:drawDebugReferences(pass, showOrigin)
  for _, ref in pairs(self.referencePoints) do
    local worldPosition = ref:getWorldPosition(self.position, self.rotation)
    ref:drawDebug(pass, worldPosition, showOrigin)
  end
end

function bodyPart:update(dt)
end

return bodyPart
