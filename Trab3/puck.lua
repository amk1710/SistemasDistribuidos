--[[

modulo puck:
  responsável por implementar a puckzinha que corre de um lado pro outro, igual no club penguin
  
--]]

local puckModule = {}

local width, height = 800, 600

local movement_speed = 500
local radius = 7

puckModule.createPuck = function()
  
  local puck = {}
  
  local positionsList = {
    {x = width - 50, y = height - 50},
    {x = width, y = 0},
    {x = 1*width/3, y = height}
    
  }
  
  local randomPosition = function()
    local r = math.random(1, #positionsList)
    return positionsList[r].x, positionsList[r].y
  end
  
  puck.posX, puck.posY = randomPosition()
  puck.desiredX, puck.desiredY = puck.posX, puck.posY
  
  
  local update_coroutine = function(puck, dt)
    --tenta se ajustar à posição desejada
    while(true) do
      
      --calcula vetor de movimento:
      local dirX, dirY = puck.desiredX - puck.posX , puck.desiredY - puck.posY -- direção é pos inicial menos final
      --normaliza:
      local mag = math.sqrt(dirX * dirX + dirY * dirY)
      dirX, dirY = dirX / mag, dirY / mag
      
       --esses ifs aparentemente sem sentido protegem do caso em que a conta acima é NaN para X ou Y,
       -- o que é um bem comum. Em particular, dirX e dirY seriam NaN quando desiredX == positionX e ...Y == ...Y
       if dirX ~= dirX then dirX = 0 end
       if dirY ~= dirY then dirY = 0 end

      --move
      puck.posX, puck.posY = puck.posX + (dirX * movement_speed * dt), puck.posY + (dirY * movement_speed * dt)
      
      coroutine.yield()
    end
  end
  
  puck.update = coroutine.wrap(update_coroutine)
  
  puck.draw = function(puck)
    
    love.graphics.setColor( 0, 0, 255, 1)
    love.graphics.circle("fill", puck.posX, puck.posY, radius)
    
  end
  
  return puck 
  
  
end

return puckModule