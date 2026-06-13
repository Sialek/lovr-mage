function lovr.load()

end

function lovr.update(dt)

end

function lovr.draw(pass)

end

function lovr.keypressed(key, scancode, isrepeat)
  if key == 'escape' then
    lovr.event.quit()
  end
end
