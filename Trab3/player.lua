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

local playerModule = {}

--global for all players
local radius = 20
local movement_speed = 10

function playerModule.newPlayer(ID, initialX, initialY)
  local player = {}
  player.objType = "player"
  player.ID = ID
  player.posX, player.posY = initialX, initialY
  
  player.desiredX, player.desiredY = initialX, initialY -- as posições dejadas do player
  
  local update_coroutine = function(player, dt)
    --tenta se ajustar à posição desejada
    while(true) do
      --por ora, literalmente teleporta
      player.posX, player.posY = player.desiredX, player.desiredY
      coroutine.yield()
    end
  end
  
  player.update = coroutine.wrap(update_coroutine)
  
  player.draw = function(player)
    love.graphics.circle("fill", player.posX, player.posY, radius)
  end
  
  player.SetDesiredPosition = function(player, x, y)
    player.desiredX, player.desiredY = x, y
  end
  
  return player
  
end

local serializeQtd = 6
--função serializa player para string
playerModule.ToString = function(player)
    str = binser.serialize(player.objType, player.ID, player.posX, player.posY, player.desiredX, player.desiredY)
    str = mime.b64(str)
    return str
end

--recupera player a partir de string serializada
playerModule.stringToPlayer = function(string)
  str = mime.unb64(string)
  
  local type_str, id, posx, posy, dx, dy = binser.deserializeN(str, serializeQtd)
  if type_str ~= "player" then error("object string is not a player") end
  local player = playerModule.newPlayer(id, posx, posy)
  player.desiredX = dx
  player.desiredY = dy
  
  return player
end

return playerModule