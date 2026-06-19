local bodyPart = require 'actor.body_part'
local bodyPlanLoader = require 'system.body_plan_loader'

local body = Class:extend()

function body:new(characterMappingPath)
  self.characterMappingPath = characterMappingPath
  self.position = vector(0, 0, 0)
  self.rotation = quaternion(0, 0, 0, 1)
  self.scale = vector(1, 1, 1)

  self.planData = nil
  self.partsById = {}
  self.rootPart = nil
  self.rootOffset = vector(0, 0, 0)
end

function body:load()
  self.planData = bodyPlanLoader.loadCharacterMapping(self.characterMappingPath)
  local rootOffset = self.planData.mapping.root_offset or { 0, 0, 0 }
  self.rootOffset = vector(rootOffset[1] or 0, rootOffset[2] or 0, rootOffset[3] or 0)
  self:buildPartTree()
end

function body:buildPartTree()
  local partInstances = {}

  for partId, partDefinition in pairs(self.planData.parts) do
    partInstances[partId] = bodyPart(partDefinition)
    self.partsById[partId] = partInstances[partId]
  end

  for partId, partDefinition in pairs(self.planData.parts) do
    local partInstance = partInstances[partId]
    for childId, childLink in pairs(partDefinition.children) do
      local childPart = partInstances[childId]
      if childPart then
        partInstance:addChild(childPart, childLink.attach)
        childPart.parent = partInstance
      else
        print('Warning: missing child part "' .. childId .. '" for parent "' .. partId .. '"')
      end
    end
  end

  for _, partInstance in pairs(partInstances) do
    if partInstance.extensionRoot and partInstance.extensionAttach then
      local parentPart = partInstances[partInstance.extensionAttach.part]
      if parentPart then
        parentPart:addChild(partInstance, partInstance.extensionAttach.reference)
        partInstance.parent = parentPart
      else
        print('Warning: extension attach parent "' .. partInstance.extensionAttach.part .. '" not found')
      end
    end
  end

  self.rootPart = partInstances[self.planData.root]
  if not self.rootPart then
    error('Root part "' .. tostring(self.planData.root) .. '" not found in body plan')
  end
end

function body:resolvePartTransforms(part, parentPosition, parentRotation, parentAttachJoint)
  part:resolveTransform(parentPosition, parentRotation, parentAttachJoint)
  for _, child in ipairs(part.children) do
    self:resolvePartTransforms(child, part.position, part.rotation, child.attachJoint)
  end
end

function body:update(dt)
  if not self.rootPart then
    return
  end
  self:resolvePartTransforms(self.rootPart, self.rootOffset, quaternion(0, 0, 0, 1), nil)
  for _, part in pairs(self.partsById) do
    part:update(dt)
  end
end

function body:drawPartTree(pass, part)
  part:draw(pass)
  for _, child in ipairs(part.children) do
    self:drawPartTree(pass, child)
  end
end

function body:drawDebugReferences(pass, part, showOrigin)
  part:drawDebugReferences(pass, showOrigin)
  for _, child in ipairs(part.children) do
    self:drawDebugReferences(pass, child, showOrigin)
  end
end

function body:draw(pass)
  if not self.rootPart then
    return
  end

  pass:push()
  pass:translate(self.position)
  pass:rotate(self.rotation)
  pass:scale(self.scale)

  self:drawPartTree(pass, self.rootPart)

  if debugBodyReferences then
    self:drawDebugReferences(pass, self.rootPart, false)
  end

  pass:pop()
end

function body:getReferenceLocal(partId, referenceName)
  local part = self.partsById[partId]
  if not part then
    return nil
  end
  return part:getReferenceWorld(referenceName)
end

function body:getReferenceWorld(partId, referenceName)
  local localPosition = self:getReferenceLocal(partId, referenceName)
  if not localPosition then
    return nil
  end
  return self.position + self.rotation * localPosition
end

function body:getEyeOffset()
  local eyeLocal = self:getReferenceLocal('head', 'slot_eyes')
  if not eyeLocal then
    return vector(0, 1.8, 0)
  end
  return eyeLocal
end

return body
