local luarpc = require("luarpc")

--[[
exemplo de client 1:
O cliente abre um proxy, e chama n vezes seguidas a função 'inc' do servidor. Por último, imprime o retorno obtido da última função, demonstrando o valor incrementado
Testa a capacidade do servidor de atender diversas vezes seguidas à mesma conexão, sem o processo de fechar e abrir de novo. 
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

num = 0
for i = 1, rep_num do
  num = rep1.inc(num)
end

print("Incremented num up to: " .. num)




