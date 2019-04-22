local binser = require ("binser")
local mime = require("mime")
local luarpc = require("luarpc")

--função auxiliar debug, imprime uma table
local function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. tostring(v))
    end
  end
end

--idl file specifies interface
local input_file = io.open("idl.txt", "r")
idl = input_file:read("*a")

if(arg[1] == nil) then
  print("usage: port_to_connect")
  return
end

port = arg[1]
rep_num = arg[2] or 1

struct1 = {name = "minhaStruct", nome = "", peso = 10.5, idade = 1}

rep1 = luarpc.createProxy(idl, "localhost", port)

tprint(rep1)

ok, struct = rep1.newstruct("José", 70.5, 30)

ok = rep1.printstruct(struct)

--[[
for i = 1, rep_num do
  --local wait = io.read()
  --success, ret, ret2 = rep1.foo(10, "asdf", struct1, 10)
  success, ret, ret2 = rep1.bar(7)
  if success then
	  print(ret, ret2)
  else
	  print("error", ret)
  end

end

--]]


