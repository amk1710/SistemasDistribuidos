local luarpc = require("luarpc")

--[[
exemplo de client 2:
O cliente abre um proxy, e chama várias funções que utilizam paramtros diversos, de tipos diversos, com args in e inout, funções void e sem retorno
Testa a capacidade do servidor de atender chamadas corretas de vários tipos 

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

--cria o proxy
rep1 = luarpc.createProxy(idl, ip, port)

--funções com structs
struct1 = {name = "minhaStruct", nome = "", peso = 10.5, idade = 1}

struct = rep1.newstruct("José", 70.5, 30)
print(rep1.structToString(struct))

--função com todos tipos de parametros e mais de um parametro inout
print(rep1.foo(1.3, 5, "string", struct1))


--função void com param inout (primeiro retorno é nil, segundo é 10)
print(rep1.echoInt(10))

-- função sem retorno nenhum, mas com efeito colateral
rep1.setGlobalString("example string")
print(rep1.getGlobalString())

--testa detecção de erro de parametros pelo proxy, protegendo o server
--parametros de menos
print(pcall(function () rep1.foo(1.3, 5) end))

--parametros a mais
print(pcall(function () rep1.echoInt(10, 20, 30) end))

--parametros do tipo errado
print(pcall(function () rep1.setGlobalString(struct1) end))

--conversão numérica: int é aceito no lugar de double
print(pcall(function () rep1.foo(1, 5, "string", struct1) end))

--mas double não é aceito no lugar de int:
print(pcall(function () rep1.foo(10/3, 5/2, "string", struct1) end))












