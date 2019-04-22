local luarpc = require("luarpc")

--[[
exemplo de client 4:
O cliente abre um proxy, seta a string global com um numero aleatorio, e imprime [n] vezes seguidas a string global que está no servidor. 

A ideia é que seja usada para demonstrar que é possível abrir mais de um servidor, em portas diferentes, usando o a biblioteca implementada. Se for aberto dois pares server-client4, cada cliente deve imprimir sua propria string.
Por outro lado, se você conectar um segundo client4 no mesmo servidor, será possível averiguar no primeiro client4 que a string global original foi sobrescrita.

Esse é o único exemplo para o qual eu não forneci o output obtido, já que, além de ser aleatório, o ponto de interesse só é reproduzível com dois terminais.

Se N não for passado, o default é 1

usage: com o servidor aberto no ip 'ip' e na porta 'port' fazer:
  lua client1.lua ip port [n]  

--]]

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

if(arg[1] == nil or arg[2] == nil) then
  print("usage: ip, port_to_connect, num_repetitions")
  return
end

ip = arg[1]
port = arg[2]
rep_num = arg[3] or 1

rep1 = luarpc.createProxy(idl, ip, port)

math.randomseed( os.time() )
my_number = math.floor(math.random() * 100)

rep1.setGlobalString("number:" .. my_number)
for i = 1, rep_num do
  print(rep1.getGlobalString())
  wait = io.read()
end




