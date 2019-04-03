--this client first connects to the server, and then repeats (number_of_repetitions) times:
  --sends a request
  --receives reply from server
--it measures the time taken to perform these operations, and prints it on the console

if(arg[2] == nil or arg[1] == nil) then
  print("usage: port_to_connect, number_of_repetitions")
end

local socket = require("socket")

local port = arg[1]
local number_of_repetitions = arg[2]

local start_time = socket.gettime()

--opens connection to server
local client = socket.connect("localhost", port)
if not client then error("connection error") end
  
for i = 1, number_of_repetitions do
  
  --sends request to server, checking if number of bytes sent differ from 0
  --message sent MUST HAVE end-of-line character at the end, because that's signaling the end of the message to the server
  local n_bytes = client:send("r\n")
  
  --reads entire string received, checking for errors
  local str, err_msg = client:receive()
  if not str then error(err_msg) end
  
end

--closes connection after communication with server
client:close()


now = socket.gettime()
print(number_of_repetitions.." successive request-get_reply iterations were performed in "..(now - start_time).." seconds")
