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
  self.moveSpeed = 5
  self.lookSpeed = 0.002
  self.eyeOffset = vector(0, 1.8, 0)

  self.inputHandler = nil
  self.firstPersonCamera = nil
  self.thirdPersonCamera = nil

  self.bodyPlanFilename = "asset/character/player/body_plan.json"
  self.body = nil
end

function player:load()
  self.body = body(self.bodyPlanFilename)
  self.body:load()

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

  local lookRotation = self:getLookRotation()
  local forward = lookRotation * vector(0, 0, -1)
  local pivot = self.position + self.orientation * self.thirdPersonPivotOffset
  self.thirdPersonCamera.position = pivot - forward * self.thirdPersonDistance
  self.thirdPersonCamera.orientation = lookRotation
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
  else
    self.cameraMode = 'first'
  end
end

function player:isThirdPerson()
  return self.cameraMode == 'third' and not lovr.headset.isActive()
end

function player:updateLook(dt)
  if lovr.headset.isActive() then
    return
  end

  if self.inputHandler and lovr.mouse then
    local dx, dy = self.inputHandler:consumeLookDelta()
    self.yaw = self.yaw - dx * self.lookSpeed
    self.pitch = math.max(-math.pi / 2, math.min(math.pi / 2, self.pitch - dy * self.lookSpeed))
  end

  self.orientation = quaternion(self.yaw, 0, 1, 0)
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
  local worldDirection = self.orientation * inputDirection
  worldDirection.y = 0
  if worldDirection:length() > 0 then
    worldDirection = worldDirection:normalize()
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
  self:syncThirdPersonCamera()
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
  pass:setColor(1, 0, 0, 1)
  pass:capsule(vector(0, 0, 0), 0.5, 1.5, 0, 90, 0.0, 0, 8)
  pass:pop()

end

return player
