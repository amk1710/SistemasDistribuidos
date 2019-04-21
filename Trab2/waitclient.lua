local binser = require ("binser")
local mime = require("mime")
local luarpc = require("luarpc")

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

if(arg[1] == nil) then
  print("usage: port_to_connect")
  return
end

port = arg[1]
rep_num = arg[2] or 1

rep1 = luarpc.createProxy(idl, "localhost", port)
for i = 1, rep_num do
  local wait = io.read()
  success, ret = rep1.foo(10, "serser",20)
  if success then
	  print(ret)
  else
	  print("error", ret)
  end

end


