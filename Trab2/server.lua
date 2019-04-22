local luarpc = require("luarpc")

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

global_string = ""

o1 = {
		foo = function(d, i, s, struct)
			return d+struct.peso, i+struct.idade, s .. "!!!"
		end,
		
		--se uma função tem retorno void e parametros inout, ela deve retornar nil e depois os parametros inout
		--de maneira geral, deve retornar nil primeiro, sempre que for void. 
		--Mas se ela por acaso for nil sem params inout, não faz diferença dar um return vazio ou mesmo não retornar. Porém, não recomendado por não ser claro
		echoInt = function(i)
		  return nil, i
		end,
		
		newstruct = function(str, d, i)
		  struct = {name = "minhaStruct", nome = str, peso = d, idade = i}
		  return struct
		end,
		
		structToString = function(struct)
		  return "nome: " .. struct.name .. ", peso: " .. struct.peso .. ", idade: " .. struct.idade
		end,
		
		inc = function(i)
		  return i + 1
		end,
		
		setGlobalString = function(str)
		  global_string = str
		  return nil
		end,
		
		getGlobalString = function()
		  return global_string
		end

}

--arg[1] e arg[2] opcionalmente indicam qual ip e porta o servant deve usar
ip, p = luarpc.registerServant(idl, o1, arg[1], arg[2])
print("estou esperando reqs para xxx na porta " .. p)
luarpc.waitIncoming()
