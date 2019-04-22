local luarpc = require("luarpc")

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

--faulty server: usado para experimentar os efeitos de um objeto implementador que não respeita o protocolo delimitado pela comunicação server-proxy e pela idl. Como isso é uma quebra explícita do protocolo, que não deveria ser violado, tem efeitos adversos relativamente imprevisíveis: alguns podem ser detectados pelo servidor, que deve encerrar a comunicação com o proxy e derrubar o servidor; outros podem ser detectados pelo proxy, que então encerra a comunicação com o server defeituoso e levanta um erro; outros ainda podem não ser detectados, e propagarem uma informação faltosa até o script cliente, ou mesmo derrubar o servidor por levantar um erro.

global_string = ""

o1 = {
		
		foo = function(d, i, s, struct)
			--retorno errado
			return
		end,
		
		--não implementada
		--[[
		echoInt = function(i)
		  return nil, i
		end,
		--]]
		
		
		newstruct = function(str, d, i)
		  struct = {name = "minhaStruct", nome = str, peso = d, idade = i}
		  --retorna tipo errado
		  return 10
		end,
		
		--crasha por acessar campo errado
		structToString = function(struct)
		  return "nome: " .. struct.XXX .. ", peso: " .. struct.YYY .. ", idade: " .. struct.ZZZ
		end,
		
		inc = function(i)
		  --retorna mais do que deveria
		  return i + 1, 10, 2, 3
		end,
		
		-- tenta usar mais params do que deveria
		setGlobalString = function(str, str2, str3)
		  global_string = str..str2..str3
		  return nil
		end,
		
		--essa aqui realmente faz o que deveria
		getGlobalString = function()
		  return global_string
		end

}

--arg[1] e arg[2] opcionalmente indicam qual ip e porta o servant deve usar
ip, p = luarpc.registerServant(idl, o1, arg[1], arg[2])
print("estou esperando reqs para xxx na porta " .. p)
luarpc.waitIncoming()
