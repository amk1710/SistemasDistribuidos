--reads a 1K string from given file
local input_file = io.open("randomString.txt", "r")

--reads 1K bytes from it into string

local KString = input_file:read(1024)

-- load namespace
local socket = require("socket")
-- create a TCP socket and bind it to the (local) host, at any port
local server = assert(socket.bind("*", 0))

-- find out which port the OS chose for us
local ip, port = server:getsockname()

-- print a message informing what's up
print("Please telnet to localhost on port " .. port)
print("After connecting, you have 10s to enter a line to be echoed")
-- loop forever waiting for clients
while 1 do
  -- wait for a connection from any client
  local client = server:accept()


  client:send(KString .. "\n")
  -- done with client, close the object
  client:close()
end
