
local binser = require("binser")
local mime = require ("mime")
local socket = require ("socket")


values_o = {}

--função para serialização de uma table request/reply
local function serialize(values)
  return (mime.b64(binser.serialize((values))))
end

--deserialização
local function deserialize(str)
  return (binser.deserialize((mime.unb64(str))))[1]
end


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


t = {1,2,3}

tprint(deserialize(serialize(t)))


