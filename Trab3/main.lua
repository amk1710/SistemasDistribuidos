unpack = unpack or table.unpack --problemas de versionamento

local mqtt = require("mqtt_library")
local plMod = require("player")
local tbMod = require("textbox")
local pkMod = require("puck")
local binser = require("binser")
local mime = require ("mime")

local width, height = 800, 600

local pingTime = 2 -- o intervalo de tempo em que uma instância tenta dar ping
local disconnectTime = 5 -- o intervalo de tempo que configura desconexão por inatividade
local instanceID --o id do meu jogo local

--dicionário de players conectados
--a chave é o ID de um player, e o valor é um objeto player
local players = {}
local textbox = 0
local puck = 0


--helper serialize and deserialize functions
local function serialize(...)
  local str = binser.serialize(...)
  str = mime.b64(str)
  return str
end

local function deserialize(string)
  local str = mime.unb64(string)
  local t = binser.deserialize(str)
  return unpack(t)
end

--helper function que dá o ping do player
local function pingPlayer(player)
  mqtt_client:publish("players_ping", plMod.ToString(players[instanceID]))
  players[instanceID].lastPing = love.timer.getTime()
end


--essa função é a callback para qualquer subscription. 
function mqttcb(topic, message)
   print("Received from topic: " .. topic .. " - message:" .. message)
   if topic == "players_ping" then
     players_pingCB(message)  
   elseif topic == "textbox" then
     textboxCB(message)
   end
end

function players_pingCB(message)
  player = plMod.stringToPlayer(message)
  player.lastPing = love.timer.getTime()
  
  --se este player já estava registrado localmente, 
  if players[player.ID] ~= nil then
    --ignoramos a posição X e Y que ele me passou, já que a movimentação é resolvida localmente pra ficar mais fluida
    player.posX, player.posY = players[player.ID].posX, players[player.ID].posY
  end
  
  players[player.ID] = player
end

function love.mousepressed( x, y, button, istouch, presses )
    if button == 1 and players[instanceID] ~= nil then    
      
      local old_x, old_y = players[instanceID].desiredX, players[instanceID].desiredY
      players[instanceID]:SetDesiredPosition(x,y) --isso tá violando o princípio de bater no servidor e voltar de novo...
      --dá um ping só pra informar a nova posição desejada
      pingPlayer(players[instanceID])
      
      players[instanceID]:SetDesiredPosition(old_x, old_y) --então eu desfaço a mudança acima, pra não violar o princípio
    
    end
end

function textboxCB(message)
  playerID, text_message = deserialize(message)
  if players[playerID] ~= nil then
    players[playerID]:displayMessage(text_message)
  end
end

function love.keypressed(key)
  --se o jogador apertou enter, 
  if key == "kpenter" or key == "return" then
    --aproveita e dá ping no player?
    
    --envia texto da textbox
    
    mqtt_client:publish("textbox", serialize(instanceID, textbox:getTextForSending()))
  end
end

function love.textinput(t)
    textbox:textInput(t)
end

function love.load()
  
  math.randomseed(os.clock())
  instanceID = math.floor(math.random() * 10000) --to do: sempre checar antes se já há outra instancia com esse ID
  
  --cria textbox
  textbox = tbMod.createTextbox(50, 600 - 50, "Type your message")
  
  --cria puck
  puck = pkMod.createPuck()
  
  --mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
  mqtt_client = mqtt.client.create("iot.eclipse.org", 1883, mqttcb)
  mqtt_client:connect("cliente love " .. instanceID) --esse identificador provavelmente seria trocado por um identificador único de usuário em uma implementação séria
  
  mqtt_client:subscribe({"players_ping"}) --optei por ter duas filas nesse caso mesmo, pq de forma geral são informações desrelacionadas. A textbox só depende de que o player esteja ativo, nada mais
  mqtt_client:subscribe({"textbox"})
  
  
  --sempre há no mínimo um player, eu mesmo. O seu ID é o ID dessa sessão do jogo
  local player1 = plMod.newPlayer(instanceID, width / 2, height / 2)
  --publico o primeiro ping desse player
  mqtt_client:publish("players_ping", plMod.ToString(player1))
  
  
end

function love.draw()
  
  --pra desenhar, me asseguro de que o player local seja sempre desenhado por último, para mantê-lo sempre visível
   for k, player in pairs(players) do
     if k ~= instanceID then player:draw() end
   end
   
   -- true indica à draw que este é o player local. De novo, tenho que me proteger de ser null por causa da ida e volta ao mosquitto
   if players[instanceID] ~= nil then players[instanceID]:draw(true) end 
   
   textbox:draw()
   puck:draw()
   
   
end

function love.update(dt)
  mqtt_client:handler()  
  
  now = love.timer.getTime()
  
  local to_disconect = {} --lista de players a serem desconectados. Estou usando isso por medo de alterar uma lista enquanto a estou percorrendo com ipairs
  for k, player in pairs(players) do
    if k ~= instanceID and player.lastPing + disconnectTime < now then
      --"desconecta" player inativo
      players[k] = nil
    end
    player:update(dt)
  end
  
  --se este player não deu ping nos últimos pingTime segundos,
  --players[instanceID] pode acabar sendo nil por alguns frames pq antes de registrar ele na table, ele vai lá no servidor, bate e volta
  if players[instanceID] ~= nil and players[instanceID].lastPing + pingTime < now then
    --dá o ping
    pingPlayer(players[instanceID])
    
  end
  
  puck:update(dt)
  
end
  
