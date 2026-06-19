local inputHandler = Class:extend()

function inputHandler:new(target)
  self.inputDisplay = false
  self.target = target
  self.mouseCaptured = false
  self.lookDX = 0
  self.lookDY = 0
end

function inputHandler:load()
  self:setMouseCapture(true)
end

function inputHandler:update(dt)
  if self.mouseCaptured and not self:usesDesktopMouse() then
    self:setMouseCapture(false)
  end
end

function inputHandler:onFocus(focused, display)
  if display ~= 'window' or not self:usesDesktopMouse() then
    return
  end

  self:setMouseCapture(focused)
end

function inputHandler:usesDesktopMouse()
  return lovr.mouse and not lovr.headset.isActive()
end

function inputHandler:consumeLookDelta()
  local dx, dy = self.lookDX, self.lookDY
  self.lookDX, self.lookDY = 0, 0
  return dx, dy
end

function inputHandler:setMouseCapture(enable)
  if not self:usesDesktopMouse() then
    return
  end

  self.mouseCaptured = enable
  lovr.mouse.setRelativeMode(enable)
  if not enable then
    self.lookDX, self.lookDY = 0, 0
  end
end

function inputHandler:draw(pass)
  if self.inputDisplay then
    pass:push()
    -- TODO: Draw input display
    pass:pop()
  end
end

function inputHandler:keypressed(key, scancode, isrepeat)
  if key == 'escape' then
    if self.mouseCaptured then
      self:setMouseCapture(false)
      return
    end
    lovr.event.quit()
  end

  if key == 'f3' then
    debugBodyReferences = not debugBodyReferences
    return
  end

  if key == 'v' then
    if self.target.toggleCameraMode then
      self.target:toggleCameraMode()
    end
    return
  end

  if self.target.keypressed then
    self.target:keypressed(key, scancode, isrepeat)
  end
end

function inputHandler:keyreleased(key, scancode)
  if self.target.keyreleased then
    self.target:keyreleased(key, scancode)
  end
end

function inputHandler:mousepressed(x, y, button)
  if self:usesDesktopMouse() then
    self:setMouseCapture(true)
  end

  if self.target.mousepressed then
    self.target:mousepressed(x, y, button)
  end
end

function inputHandler:mousereleased(x, y, button)
  if self.target.mousereleased then
    self.target:mousereleased(x, y, button)
  end
end

function inputHandler:mousemoved(x, y, dx, dy)
  if self:usesDesktopMouse() and self.mouseCaptured then
    self.lookDX = self.lookDX + dx
    self.lookDY = self.lookDY + dy
  end

  if self.target.mousemoved then
    self.target:mousemoved(x, y, dx, dy)
  end
end

return inputHandler
