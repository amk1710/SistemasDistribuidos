local binser = require ("binser")
local mime = require("mime")
local luarpc = require("luarpc")

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

o1 = {
		foo = function(d, s, struct, i)
			return struct.peso, struct.idade
		end,
		
		--se uma função tem retorno void e parametros inout, ela deve retornar nil e depois os parametros inout
		--de maneira geral, deve retornar nil primeiro, sempre que for void. 
		--Mas se ela por acaso for nil sem params inout, não faz diferença dar um return vazio ou mesmo não retornar. Porém, não recomendado por não ser claro
		bar = function(i)
		  return nil, i+1
		end,
		
		newstruct = function(str, d, i)
		  struct = {name = "minhaStruct", nome = str, peso = d, idade = i}
		  return struct
		end,
		
		printstruct = function(struct)
		  print("nome: " .. struct.name .. ", peso: " .. struct.peso .. ", idade: " .. struct.idade)
		  return nil
		end		

}

--arg[1] e arg[2] opcionalmente indicam qual ip e porta o servant deve usar
ip, p = luarpc.registerServant(idl, o1, arg[1], arg[2])
print("estou esperando reqs para xxx na porta " .. p)
luarpc.waitIncoming()
