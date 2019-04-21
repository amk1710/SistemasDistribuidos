local binser = require ("binser")
local mime = require("mime")
local luarpc = require("luarpc")

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

o1 = {
		foo = function(d, s, i)
			return d+i
		end

}

ip, p = luarpc.registerServant(idl, o1)
print("estou esperando reqs para xxx na porta " .. p)
luarpc.waitIncoming()
