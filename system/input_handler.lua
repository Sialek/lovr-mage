local inputHandler = Class:extend()

function inputHandler:new(target)
  self.inputDisplay = false
  self.target = target
end

function inputHandler:load()

end

function inputHandler:update(dt)

end

function inputHandler:draw(pass)
  if self.inputDisplay then
    pass:push()
    -- TODO: Draw input display
    pass:pop()
  end
end

function inputHandler:keypressed(key, scancode, isrepeat)
  self.target:keypressed(key, scancode, isrepeat)
  
  if key == "escape" then
    lovr.event.quit()
  end

end

function inputHandler:keyreleased(key, scancode)
  self.target:keyreleased(key, scancode)
end

function inputHandler:mousepressed(x, y, button)
  self.target:mousepressed(x, y, button)
end

return inputHandler
