local camera = Class:extend()

function camera:new()
  self.position = vector(0, 0, 0)
  self.orientation = quaternion(0, 0, 0, 1)
end

function camera:load()

end

function camera:update(dt)

end

function camera:applyToPass(pass)
  for view = 1, pass:getViewCount() do
    pass:setViewPose(view, self.position, self.orientation)
  end
end

return camera
