--[[

modulo puck:
  responsável por implementar a puckzinha que corre de um lado pro outro, igual no club penguin
  
--]]

local puckModule = {}

local width, height = 800, 600

local movement_speed = 1000
local pos_tolerance = 10

puckModule.createPuck = function()
  
  local puck = {}
  
  local limit_boundary = 25
  puck.randomPosition = function()
    --seed já vem setado lá da love.load
    return math.random(limit_boundary, width - limit_boundary) , math.random(limit_boundary, height - limit_boundary)    
  end
  
  puck.posX, puck.posY = puck.randomPosition()
  puck.desiredX, puck.desiredY = puck.posX, puck.posY  
  puck.radius = 7
  
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

      --move, só se a magnitude do movimento for maior do que a tolerância
      if mag > pos_tolerance then
        puck.posX, puck.posY = puck.posX + (dirX * movement_speed * dt), puck.posY + (dirY * movement_speed * dt)
      else
        --se já estou próximo o suficiente, teleporto
        puck.posX, puck.posY = puck.desiredX, puck.desiredY
      end
      
      coroutine.yield()
    end
  end
  
  puck.update = coroutine.wrap(update_coroutine)
  
  puck.draw = function(puck)
    
    love.graphics.setColor( 0, 0, 255, 1)
    love.graphics.circle("fill", puck.posX, puck.posY, puck.radius)
    
  end
  
  return puck 
  
  
end

return puckModule