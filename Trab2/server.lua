local binser = require ("binser")
local mime = require("mime")
local luarpc = require("luarpc")

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

o1 = {
		foo = function(d, s, i)
			return d+i
		end,
		
		--se uma função tem retorno void e parametros inout, ela deve retornar nil e depois os parametros inout
		--de maneira geral, deve retornar nil primeiro, sempre que for void. 
		--Mas se ela por acaso for nil sem params inout, não faz diferença dar um return vazio ou mesmo não retornar. Porém, não recomendado por não ser claro
		bar = function()
		  return nil
		end

}

--arg[1] e arg[2] opcionalmente indicam qual ip e porta o servant deve usar
ip, p = luarpc.registerServant(idl, o1, arg[1], arg[2])
print("estou esperando reqs para xxx na porta " .. p)
luarpc.waitIncoming()
