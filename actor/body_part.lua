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

local function buildVisualOrientation(visual)
  local rotation = visual.rotation or { 0, 0, 0 }
  return quaternion(
    math.rad(rotation[2] or 0), 0, 1, 0
  ) * quaternion(
    math.rad(rotation[1] or 0), 1, 0, 0
  ) * quaternion(
    math.rad(rotation[3] or 0), 0, 0, 1
  )
end

-- LÖVR capsules extend along local +Z by default (see Pass:capsule notes).
local function buildCapsuleOrientation(visual)
  local orientation = buildVisualOrientation(visual)
  local axis = visual.axis or 'y'
  if axis == 'y' then
    orientation = orientation * quaternion(-math.pi / 2, 1, 0, 0)
  end
  return orientation
end

local function buildVisualPosition(offset)
  return vector(offset[1] or 0, offset[2] or 0, offset[3] or 0)
end

function bodyPart:drawPlaceholder(pass, drawOptions)
  local visual = self.visual
  local offset = visual.offset or defaultVisual.offset
  local size = visual.size or defaultVisual.size
  local shape = visual.shape or defaultVisual.shape

  local r, g, b, a
  if drawOptions and drawOptions.progressive then
    r, g, b = debugHelper.graphics.getDepthColor(drawOptions.depth)
    a = drawOptions.alpha or 1
  else
    local color = visual.color or defaultVisual.color
    r, g, b = color[1], color[2], color[3]
    a = color[4] or 1
  end

  pass:setColor(r, g, b, a)

  local position = buildVisualPosition(offset)

  if shape == 'box' then
    pass:box(
      position,
      vector(size[1] or 0.1, size[2] or 0.1, size[3] or 0.1),
      buildVisualOrientation(visual)
    )
  elseif shape == 'capsule' then
    pass:capsule(
      position,
      size[1] or 0.1,
      size[2] or 0.2,
      buildCapsuleOrientation(visual)
    )
  else
    pass:sphere(position, size[1] or 0.1, buildVisualOrientation(visual))
  end
end

function bodyPart:draw(pass, drawOptions)
  pass:push()
  pass:translate(self.position)
  pass:rotate(self.rotation)
  self:drawPlaceholder(pass, drawOptions)
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
