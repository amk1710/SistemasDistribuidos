unpack = unpack or table.unpack --problemas de versionamento

local mqtt = require("mqtt_library")
local plMod = require("player")

local binser = require("binser")
local mime = require ("mime")

local width, height = 800, 600

--dicionário de players conectados
--a chave é o ID de um player, e o valor é um objeto player
players = {}

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

--o id do meu jogo local

local instanceID

--essa função é a callback para qualquer subscription. 
function mqttcb(topic, message)
   print("Received from topic: " .. topic .. " - message:" .. message)
   if topic == "players_ping" then
     players_pingCB(message)  
   elseif topic == "players_movement" then
     players_movementCB(message)
   end
end

function players_pingCB(message)
  player = plMod.stringToPlayer(message)
  players[player.ID] = player
end

function players_movementCB(message)
  --unpack message
  id, x, y = deserialize(message)
  print(id, x, y)
  if(players[id] and type(x) == "number" and type(y) == "number" 
    and x >= 0 and x < width
    and y >= 0 and y <= height) then
      
      players[id]:SetDesiredPosition(x,y)
  else print("fail")
  end
end

function love.mousepressed( x, y, button, istouch, presses )
    if button == 1 then    
      --players[instanceID]:SetDesiredPosition(x,y)
      --prepara mensagem para o envio
      local msg = {instanceID, x, y}
      local str = serialize(instanceID, x, y)
      mqtt_client:publish("players_movement", str)
    
    end
end

function love.keypressed(key)
  
end

function love.load()
  
  math.randomseed(os.clock())
  instanceID = math.floor(math.random() * 10000) --to do: sempre checar antes se já há outra instancia com esse ID
  
  mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
  mqtt_client:connect("cliente love " .. instanceID)
  
  mqtt_client:subscribe({"players_ping"})
  mqtt_client:subscribe({"players_movement"})
  
  
  --sempre há no mínimo um player, eu mesmo. O seu ID é o ID dessa sessão do jogo
  local player1 = plMod.newPlayer(instanceID, width / 2, height / 2)
  --publico o primeiro ping desse player
  mqtt_client:publish("players_ping", plMod.ToString(player1))
  
  --players["local"] = player1 -- o player local usa a chave especial "local" --estou violando a divisão de publicar infos e reagir localmente
  
  
end

function love.draw()
  
   for _, player in pairs(players) do
     player:draw()
   end
   
end

function love.update(dt)
  mqtt_client:handler()  
  
  for _, player in pairs(players) do
     player:update(dt)
   end
  
end
  
