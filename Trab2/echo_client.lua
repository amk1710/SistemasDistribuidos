local socket = require("socket")


-- Conectando os clientes aos servidores
local client1 = socket.connect("localhost", 5500)
local client2 = socket.connect("localhost", 5501)

local text = "Amarelinha Vermelhinha Azulzinha Abobrinha"

-- Enviando o texto para o servidor 1
client1:send(text .. "\n")

-- Recebendo a resposta do servidor 1
local recv, err = client1:receive()
print("Servidor 1 (Capital Echo) \n\tTexto enviado: " .. text .. "\n\tTexto recebido " .. recv)
print()


-- Enviando o texto para o servidor 2
client2:send(text .. "\n")

-- Recebendo a resposta do servidor 2
local recv, err = client2:receive()
print("Servidor 2 (Inverted Echo) \n\tTexto enviado: " .. text .. "\n\tTexto recebido " .. recv)



-- Fechando as conexões
client1:close()
client2:close()
