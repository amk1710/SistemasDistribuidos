local binser = require ("binser")
local mime = require("mime")
local luarpc = require("luarpc")

--ibl file specifies interface
local input_file = io.open("ibl.txt", "r")
ibl = input_file:read("*a")

if(arg[1] == nil) then
  print("usage: port_to_connect")
  return
end

port = arg[1]

rep1 = luarpc.createProxy(ibl, "localhost", port)
ret, err = rep1.foo(10, "serser",20)
if err then
	print(err)
else
	print(ret)
end
	--print(ret)


