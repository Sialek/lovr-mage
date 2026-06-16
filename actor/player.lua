local body = require 'actor.body'
local inputHandler = require 'system.input_handler'

local player = Class:extend()

function player:new()
  self.position = vector(0, 0, 0)
  self.rotation = quaternion(0, 0, 0, 1)
  self.scale = vector(1, 1, 1)
  self.bodyPlanFilename = "asset/character/player/body_plan.json"
  self.body = nil
  self.inputHandler = nil
end

function player:load()
  self.body = body(self.bodyPlanFilename)
  self.body:load()

  self.inputHandler = inputHandler(self)
  self.inputHandler:load()
end

function player:update(dt)

end

function player:draw(pass)

end

return player
