local xinit = 50
local yinit = 50

function rectangle(x,y,w,h)
  local original_x, original_y, rx, ry, rw, rh = x,y,x,y,w,h
  
  local naimagem = function(mx, my) 
    return (mx > rx) and (mx < rx + rw) and (my > ry) and (my < ry + rh)
  end
  
  local keypressed = function (key)
    local mx, my = love.mouse.getPosition() 
    if naimagem (mx,my, rx, ry) then
      if key == 'b' then 
        ry = original_y
        rx = original_x
      elseif love.keyboard.isDown("down") then 
        ry = ry + 10
      elseif love.keyboard.isDown("right") then 
        rx = rx + 10
      end
    end
  end
  
  local update = function (dt)
    --nada
  end
  
  local draw = function()
    love.graphics.rectangle("line", rx, ry, rw, rh)
  end
  
  return { naimagem = naimagem, keypressed = keypressed, update = update, draw = draw }
end


function love.load()
  rects = {}
  for i = 1,3 do
    rects[i] = rectangle(xinit*i, yinit*(i - 1), 200, 300)
  end
end

function love.keypressed(key)
  for i = 1,3 do
    rects[i].keypressed(key)
  end
end

function love.update (dt)
  for i = 1,3 do
    rects[i].update(dt)
  end  
end

function love.draw ()
  for i = 1,3 do
    rects[i].draw()
  end 
end

