local binser = require "binser"
local lua_socket = require "socket"
local mime = require "mime"
print(binser)

--print(binser.serialize({foo = "ASDFASDF", bar = "func"}))

print(mime.b64(binser.serialize({foo = "gsdfgsdf", bar = "func"})))
