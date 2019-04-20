local binser = require ("binser")
local mime = require("mime")
local luarpc = require("luarpc")

o1 = {
		foo = function(a,b)
			return a+b, "alo, alo"
		end

}

ip, p = luarpc.registerServant(idl, o1)
print("estou esperando reqs para xxx na porta " .. p)
luarpc.waitIncoming()
