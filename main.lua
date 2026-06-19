Class = require 'lib.classic'

if type(jit) == 'table' and lovr.system.getOS() ~= 'Android' and lovr.system.getOS() ~= 'Web' then
  lovr.mouse = require 'lib.lovr-mouse'
end

lovr.json = require 'lib.json'

debugHelper = require 'util.debug_helper'

debugBodyReferences = false
debugBodyProgressiveRender = false
debugBodyRenderDepth = 1

Player = require 'actor.player'

players = {}
activePlayer = nil

function lovr.load()

  players[1] = Player(vector(0, 0, 0), quaternion(0, 0, 0, 1), vector(1, 1, 1))
  players[1]:load()
  activePlayer = players[1]
end

function lovr.update(dt)
  activePlayer:update(dt)
end

function lovr.draw(pass)
  if not lovr.headset.isActive() then
    activePlayer:getActiveCamera():applyToPass(pass)
  end

  debugHelper.graphics.drawWorldAxisGrid(pass)

  activePlayer:draw(pass)
end

function lovr.keypressed(key, scancode, isrepeat)
  if activePlayer and activePlayer.inputHandler then
    activePlayer.inputHandler:keypressed(key, scancode, isrepeat)
  end
end

function lovr.keyreleased(key, scancode)
  if activePlayer and activePlayer.inputHandler then
    activePlayer.inputHandler:keyreleased(key, scancode)
  end
end

function lovr.mousepressed(x, y, button)
  if activePlayer and activePlayer.inputHandler then
    activePlayer.inputHandler:mousepressed(x, y, button)
  end
end

function lovr.mousereleased(x, y, button)
  if activePlayer and activePlayer.inputHandler then
    activePlayer.inputHandler:mousereleased(x, y, button)
  end
end

function lovr.mousemoved(x, y, dx, dy)
  if activePlayer and activePlayer.inputHandler then
    activePlayer.inputHandler:mousemoved(x, y, dx, dy)
  end
end

function lovr.focus(focused, display)
  if activePlayer and activePlayer.inputHandler then
    activePlayer.inputHandler:onFocus(focused, display)
  end
end

function lovr.simulate(dt)
  -- Keep the default VR simulator disabled on desktop. Mouse look uses lovr-mouse
  -- via the player input handler; real headset tracking is used when isActive().
end
