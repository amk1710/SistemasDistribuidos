
unpack = unpack or table.unpack --problemas de versionamento

local mqtt = require("mqtt_library")
local socket = require("socket")

--tenta publicar N vezes seguidas, e checa se as mensagens vão chegar na ordem certa

local N = 100

--reads a 1K string from given file
local input_file = io.open("randomString.txt", "r")

--reads 1K bytes from it into string

local KString = input_file:read(1024)


--o servidor mosquitto não estava conectando em vários momentos quando estava desenvolvendo
--mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
mqtt_client = mqtt.client.create("iot.eclipse.org", 1883, mqttcb)

local reg = {}
local qtd_sent = 0
local qtd_arr = 0

function mqttcb(topic, message)
   --print("Received from topic: " .. topic .. " - message:" .. message)
   if topic == "test7777" then
     qtd_arr = qtd_arr + 1
	 reg[qtd_arr].arrTime = socket.gettime()

   end
end

--o servidor mosquitto não estava conectando em vários momentos quando estava desenvolvendo
local mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
--local mqtt_client = mqtt.client.create("iot.eclipse.org", 1883, mqttcb)

mqtt_client:connect("cliente love 7777") --esse identificador provavelmente seria trocado por um identificador único de usuário em uma implementação séria

mqtt_client:subscribe({"test7777"})

local pre_time = socket.gettime()
for i = 1, N do
	reg[i] = {msgSent = i, sendTime = socket.gettime()}
	mqtt_client:publish("test7777", KString)
	qtd_sent = qtd_sent + 1
	while(reg[i].arrTime == nil) do
		mqtt_client:handler()
	end
end
local post_time = socket.gettime()

--calcula media de tempo
local avg = 0
for i = 1, N do
	avg = avg + (reg[i].arrTime - reg[i].sendTime)
end



print("avg_time1: " .. avg / N)
print("avg_time2: " .. (post_time - pre_time)/N)
