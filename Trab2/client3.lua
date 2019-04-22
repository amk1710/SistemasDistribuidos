local luarpc = require("luarpc")

--[[
exemplo de client 3:
O cliente abre três proxies na mesma porta, e utiliza os três com sucesso. Ao abrir o quarto proxy, nota-se que o primeiro foi desconectado pelo servidor

Testa o limite do servidor de atender proxies distintos na mesma porta 

usage: com o servidor aberto no ip 'ip' e na porta 'port' fazer:
  lua client1.lua ip port

--]]

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

if(arg[1] == nil or arg[2] == nil) then
  print("usage: ip port_to_connect")
  return
end

ip = arg[1]
port = arg[2]

--cria os proxies
rep1 = luarpc.createProxy(idl, ip, port)
rep2 = luarpc.createProxy(idl, ip, port)
rep3 = luarpc.createProxy(idl, ip, port)

--usa os três com sucesso (note que os três se remetem ao mesmo servidor. Os três compartilham a mesma string global)
rep1.setGlobalString("global string!!!")
print("proxy 1 :" .. rep1.getGlobalString())
print("proxy 2 :" .. rep2.getGlobalString())
print("proxy 3 :" .. rep3.getGlobalString())

--tento conectar um quarto proxy, e consigo. Porém, ao fazê-lo, eu desconectei o primeiro(pq ele é o mais antigo)
rep4 = luarpc.createProxy(idl, ip, port)

print("proxy 4 :" .. rep4.getGlobalString())
success, err = pcall(rep1.getGlobalString)
print(success, err)
print("proxy 2 :" .. rep2.getGlobalString())
print("proxy 3 :" .. rep3.getGlobalString())



