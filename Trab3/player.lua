--[[

modulo player:
  responsável por implementar o movimentação e renderização de um único player. Não interage com as componentes em rede do jogo, 
  somente trata os efeitos delas localmente. No caso, disponibiliza a funcionalidade de um único jogador do server, que pode:
  
  - Se locomover:
    o player expõe a função SetDesiredPosition, que permite à main e, consequentemente, às callbacks em rede, a setar a posição
    desejada para cada player. O player então se ajustará, local e gradativamente, à essa mudança.
  
--]]

local binser = require("binser")
local mime = require("mime")

local width, height = 800, 600

local playerModule = {}

--global for all players
local radius = 20
local movement_speed = 100

function playerModule.newPlayer(ID, initialX, initialY)
  initialX = initialX or width/2
  initialY = initialY or height/2
  
  
  local player = {}
  player.objType = "player"
  player.ID = ID
  
  player.posX = initialX
  player.posY = initialY
  
  player.desiredX, player.desiredY = initialX, initialY -- as posições dejadas do player
  
  player.lastPing = -math.huge
  
  local update_coroutine = function(player, dt)
    --tenta se ajustar à posição desejada
    while(true) do
      
      --calcula vetor de movimento:
      local dirX, dirY = player.desiredX - player.posX , player.desiredY - player.posY -- direção é pos inicial menos final
      --normaliza:
      local mag = math.sqrt(dirX * dirX + dirY * dirY)
      dirX, dirY = dirX / mag, dirY / mag
      
       --esses ifs aparentemente sem sentido protegem do caso em que a conta acima é NaN para X ou Y,
       -- o que é um bem comum. Em particular, dirX e dirY seriam NaN quando desiredX == positionX e ...Y == ...Y
       if dirX ~= dirX then dirX = 0 end
       if dirY ~= dirY then dirY = 0 end

      --move
      player.posX, player.posY = player.posX + (dirX * movement_speed * dt), player.posY + (dirY * movement_speed * dt)
      
      --decrementa tempo de display da fala
      player.shouldDisplay = math.max(0, player.shouldDisplay - dt)
      
      coroutine.yield()
    end
  end
  
  player.update = coroutine.wrap(update_coroutine)
  
  local displayTime = 4
  player.shouldDisplay = -1
  player.message = ""
  player.displayMessage = function(player, str)
    player.message = str
    player.shouldDisplay = displayTime
  end
  
  local inc = 4
  local t_offsetX = -40
  local t_offsetY = -40
  local max_width = 200
  player.draw = function(player, isLocalPlayer)
    
    if isLocalPlayer then
      --se for o player local, desenha um 'halo' em volta, pra mostrar ao jogador
      love.graphics.setColor( 255, 255, 0, 1)
      love.graphics.circle("fill", player.posX, player.posY, radius + inc)
    end
    love.graphics.setColor( 255, 255, 255, 1)
    love.graphics.circle("fill", player.posX, player.posY, radius)
    
    --mostra texto de fala
    if player.shouldDisplay > 0 then
      love.graphics.printf(player.message, player.posX + t_offsetX, player.posY + t_offsetY, max_width)
    end
    
  end
  
  player.SetDesiredPosition = function(player, x, y)
    player.desiredX, player.desiredY = x, y
  end
  
  return player
  
end

local serializeQtd = 4
--função serializa player para string
playerModule.ToString = function(player)
    str = binser.serialize(player.objType, player.ID, player.desiredX, player.desiredY) --optei por não compartilhar a posição corrente, em nenhuma ocasião. A movimentação é calculada localmente, sempre
    str = mime.b64(str)
    return str
end

--recupera player a partir de string serializada
playerModule.stringToPlayer = function(string)
  str = mime.unb64(string)
  
  local type_str, id, dx, dy = binser.deserializeN(str, serializeQtd)
  if type_str ~= "player" then error("object string is not a player") end
  local player = playerModule.newPlayer(id)
  player.desiredX = dx
  player.desiredY = dy
  
  return player
end

return playerModule