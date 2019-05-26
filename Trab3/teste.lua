
unpack = unpack or table.unpack --problemas de versionamento

local mqtt = require("mqtt_library")

--tenta publicar N vezes seguidas, e checa se as mensagens vão chegar na ordem certa

local N = 10000

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
	 reg[qtd_arr].arrTime = os.time()
	 reg[qtd_arr].orderArr = qtd_arr

   end
end

--o servidor mosquitto não estava conectando em vários momentos quando estava desenvolvendo
--local mqtt_client = mqtt.client.create("test.mosquitto.org", 1883, mqttcb)
local mqtt_client = mqtt.client.create("iot.eclipse.org", 1883, mqttcb)

mqtt_client:connect("cliente love 7777") --esse identificador provavelmente seria trocado por um identificador único de usuário em uma implementação séria

mqtt_client:subscribe({"test7777"})

for i = 1, N do
	reg[i] = {msgSent = i, sendTime = os.time()}
	mqtt_client:publish("test7777", i)
	qtd_sent = qtd_sent + 1
	mqtt_client:handler()
end


--espera até todos chegarem
while(qtd_sent ~= qtd_arr) do
	mqtt_client:handler()
end


--indica se houve violação de ordem

local order_violations = 0
for i = 1, N do
	if tonumber(reg[i].msgSent) ~= tonumber(reg[i].orderArr) then
		order_violations = order_violations + 1
		print("order violation: " .. reg[i].msgSent .. ", " .. reg[i].msgArr)
	end
end

print("Houve " .. order_violations .." violações de ordenamento")




