
--this client repeats (number_of_repetitions) times:
  --opens connection in the specified port
  --sends a request
  --receives answer from server
--it measures the time taken to perform these operations, and prints it on the console

if(arg[2] == nil or arg[1] == nil) then
  print("usage: port_to_connect, number_of_repetitions")
end

local socket = require("socket")

local port = arg[1]
local number_of_repetitions = arg[2]

local start_time = socket.gettime()
for i = 1, number_of_repetitions do
  local client = socket.connect("localhost", port)
  if not client then error("connection error") end
  
  --sends request to server, checking if number of bytes sent differ from 0
  --message sent MUST HAVE end-of-line character at the end, because that's signaling the end of the message to the server
  local n_bytes = client:send("r\n")
  
  --reads entire string received, checking for errors
  local str, err_msg = client:receive()
  if not str then print(err_msg) end
  
  --closes connection after reply from server
  client:close()  
  
end
now = socket.gettime()
print(number_of_repetitions.." successive connect-request-get_reply iterations were performed in "..(now - start_time).." seconds")
