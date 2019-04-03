--reads a 1K string from given file
local input_file = io.open("randomString.txt", "r")

--reads 1K bytes from it into string

local KString = input_file:read(1024)

-- load namespace
local socket = require("socket")

local ip, port
local server
if(arg[1] == nil) then
  --não foi passado argumento pela linha de comando, abre me qualquer porta
  
  -- create a TCP socket and bind it to the (local) host, at any port
  server = assert(socket.bind("*", 0))

  -- find out which port the OS chose for us
  ip, port = server:getsockname()
else
  -- foi passado um argumento na linha de comando, tenta abrir a porta com esse número
  -- create a TCP socket and bind it to the (local) host, at any port
  server = assert(socket.bind("*", arg[1]))
 
  -- find out which port the OS chose for us
  ip, port = server:getsockname()
end


-- print a message informing what's up
print("Please connect to localhost on port " .. port)
-- loop forever waiting for clients
while 1 do
  -- wait for a connection from any client
  local client = server:accept()
   
  -- receive as many requests as necessary from the same client
  --connection is closed when client closes the connection,
  --or when 10s pass without a request
  -- receive the request
  
  client:settimeout(10)
  local line, err
  repeat 
    line, err = client:receive()
    --if no error ocurred, ignore the request's content and simply send the 1K randomString
    if not err then client:send(KString .. "\n") end
    
  until not line or err
  
  
  
  
  --client:close()
end
