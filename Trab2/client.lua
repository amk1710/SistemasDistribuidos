local binser = require ("binser")
local mime = require("mime")
local luarpc = require("luarpc")


if(arg[1] == nil) then
  print("usage: port_to_connect")
end

port = arg[1]

rep1 = luarpc.createProxy(nil, "localhost", port)
ret = rep1:foo()
print(ret)


