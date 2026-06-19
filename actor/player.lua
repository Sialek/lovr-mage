local body = require 'actor.body'
local inputHandler = require 'system.input_handler'
local camera = require 'system.camera'

local player = Class:extend()

function player:new(position, rotation, scale)

  self.position = position or vector(0, 0, 0)
  self.orientation = rotation or quaternion(0, 0, 0, 1)
  self.scale = scale or vector(1, 1, 1)
  self.velocity = vector(0, 0, 0)
  self.yaw = 0
  self.pitch = 0
  self.cameraYaw = 0
  self.cameraPitch = 0.25
  self.cameraPitchLimit = 89 * math.pi / 180
  self.moveSpeed = 5
  self.lookSpeed = 0.002
  self.eyeOffset = vector(0, 1.8, 0)

  self.inputHandler = nil
  self.firstPersonCamera = nil
  self.thirdPersonCamera = nil
  self.cameraMode = 'third'
  self.thirdPersonDistance = 3.0
  self.thirdPersonPivotOffset = vector(0, 1.65, 0)

  self.characterMappingPath = 'asset/character/player/wolf_default.json'
  self.body = nil
end

function player:load()
  self.body = body(self.characterMappingPath)
  self.body:load()
  self.body:update(0)
  self.eyeOffset = self.body:getEyeOffset()
  self.thirdPersonPivotOffset = vector(0, self.eyeOffset.y + 0.08, 0)

  self.inputHandler = inputHandler(self)
  self.inputHandler:load()

  self.firstPersonCamera = camera()
  self.firstPersonCamera:load()
  self:syncFirstPersonCamera()

  self.thirdPersonCamera = camera()
  self.thirdPersonCamera:load()
  self:syncThirdPersonCamera()
end

function player:getLookRotation()
  return self.orientation * quaternion(self.pitch, 1, 0, 0)
end

function player:syncFirstPersonCamera()
  if lovr.headset.isActive() then
    self.firstPersonCamera.position = vector(lovr.headset.getPosition('head'))
    self.firstPersonCamera.orientation = quaternion(lovr.headset.getOrientation('head'))
    return
  end

  self.firstPersonCamera.position = self.position + self.orientation * self.eyeOffset
  self.firstPersonCamera.orientation = self:getLookRotation()
end

function player:syncThirdPersonCamera()
  if lovr.headset.isActive() then
    return
  end

  local pivot = self.position + self.thirdPersonPivotOffset
  local orbitRotation = quaternion(self.cameraYaw, 0, 1, 0) * quaternion(-self.cameraPitch, 1, 0, 0)
  local offset = orbitRotation * vector(0, 0, self.thirdPersonDistance)

  self.thirdPersonCamera.position = pivot + offset
  -- Match orientation to orbit so the view always looks back toward the pivot.
  -- Do not use mat4:target here; it flips 180 degrees on the far side of the orbit.
  self.thirdPersonCamera.orientation = orbitRotation
end

function player:getActiveCamera()
  if self.cameraMode == 'third' and not lovr.headset.isActive() then
    return self.thirdPersonCamera
  end
  return self.firstPersonCamera
end

function player:toggleCameraMode()
  if lovr.headset.isActive() then
    return
  end

  if self.cameraMode == 'first' then
    self.cameraMode = 'third'
    self.cameraYaw = self.yaw
    self.cameraPitch = self.pitch
  else
    self.cameraMode = 'first'
    self.yaw = self.cameraYaw
    self.pitch = self.cameraPitch
    self.orientation = quaternion(self.yaw, 0, 1, 0)
  end
end

function player:isThirdPerson()
  return self.cameraMode == 'third' and not lovr.headset.isActive()
end

function player:updateLook(dt)
  if lovr.headset.isActive() then
    return
  end

  if not self.inputHandler or not lovr.mouse then
    return
  end

  local dx, dy = self.inputHandler:consumeLookDelta()

  if self:isThirdPerson() then
    self.cameraYaw = self.cameraYaw - dx * self.lookSpeed
    self.cameraPitch = math.max(-self.cameraPitchLimit, math.min(self.cameraPitchLimit, self.cameraPitch + dy * self.lookSpeed))
    return
  end

  self.yaw = self.yaw - dx * self.lookSpeed
  self.pitch = math.max(-self.cameraPitchLimit, math.min(self.cameraPitchLimit, self.pitch - dy * self.lookSpeed))
  self.orientation = quaternion(self.yaw, 0, 1, 0)
end

function player:getCameraRelativeDirection(inputDirection)
  self:syncThirdPersonCamera()

  local forward = self.thirdPersonCamera.orientation * vector(0, 0, -1)
  forward.y = 0
  if forward:length() > 0 then
    forward = forward:normalize()
  end

  local right = self.thirdPersonCamera.orientation * vector(1, 0, 0)
  right.y = 0
  if right:length() > 0 then
    right = right:normalize()
  end

  local worldDirection = forward * -inputDirection.z + right * inputDirection.x
  worldDirection.y = 0
  if worldDirection:length() > 0 then
    worldDirection = worldDirection:normalize()
  end

  return worldDirection
end

function player:faceDirection(worldDirection)
  if worldDirection:length() == 0 then
    return
  end

  -- Body model forward is +Z (snout/head extend toward +Z).
  local yaw = math.atan2(worldDirection.x, worldDirection.z)
  self.yaw = yaw
  self.orientation = quaternion(yaw, 0, 1, 0)
end

function player:updateMovement(dt)
  local inputDirection = vector(0, 0, 0)
  if lovr.system.isKeyDown('w') then
    inputDirection.z = -1
  end
  if lovr.system.isKeyDown('s') then
    inputDirection.z = 1
  end
  if lovr.system.isKeyDown('a') then
    inputDirection.x = -1
  end
  if lovr.system.isKeyDown('d') then
    inputDirection.x = 1
  end

  if inputDirection:length() == 0 then
    self.velocity = vector(0, 0, 0)
    return
  end

  inputDirection = inputDirection:normalize()

  local worldDirection
  if self:isThirdPerson() then
    worldDirection = self:getCameraRelativeDirection(inputDirection)
    if worldDirection:length() == 0 then
      self.velocity = vector(0, 0, 0)
      return
    end
    self:faceDirection(worldDirection)
  else
    worldDirection = self.orientation * inputDirection
    worldDirection.y = 0
    if worldDirection:length() > 0 then
      worldDirection = worldDirection:normalize()
    end
  end

  self.velocity = worldDirection * self.moveSpeed
  self.position = self.position + self.velocity * dt
end

function player:update(dt)
  self.inputHandler:update(dt)
  self:updateLook(dt)
  self:updateMovement(dt)
  self.body:update(dt)
  self:syncFirstPersonCamera()
  if self:isThirdPerson() then
    self:syncThirdPersonCamera()
  end
end

function player:draw(pass)
  if not self:isThirdPerson() then
    return
  end

  pass:push()
  pass:translate(self.position)
  pass:rotate(self.orientation)
  pass:scale(self.scale)
  self.body:draw(pass)
  pass:pop()
end

return player
