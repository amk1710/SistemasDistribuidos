
local binser = require("binser")
local mime = require ("mime")
local socket = require ("socket")

local luarpc = {}

--vars globais
local ip = "localhost"
local servants = {}

--próximos passos:
  -- implementar idl, chamada e retorno de funções genéricas
  -- implementar várias portas ativas

--funções auxiliares, não exportadas
local function parser(idl_string)
  --if type(idl_string) ~= "string" then error("wrong param type: idl_string " .. type(idl_string)) end

  --trata todas as structs
  --for elem in string.gmatch(idl_string, "struct%s*{[%s%w]*}")
  for elem in string.gmatch(idl_string, "struct%s*%b{}") do
	print(elem)
  end

  --trata somente uma interface. Se houver mais de uma, a primeira é considerada e as demais ignoradas

end


--funções exportadas pela biblioteca: registerServant, waitIncoming, serialize, deserialize


--função que dada a idl e um servente, o registra e disponibiliza através da porta
function luarpc.registerServant(idl, object)

  --por enquanto, não faz nada com a idl


  --abre um socket pra esse servant, salva ele numa lista local

  -- create a TCP socket and bind it to the (local) host, at any port
  local server = assert(socket.bind("*", 0))
  -- find out which port the OS chose for us
  local ip, port = server:getsockname()
  server:settimeout(1)

  listen = function()

    --checa por conexão de cliente, com timeout de um segundo
    local client, timeout = server:accept()

    --se cliente conectou,
    if client then

      --tenta receber requisição:
      local line, err = client:receive()

      --tendo recebido a requisição, atende-a e envia de volta a resposta
      --(por enquanto, uma resposta qualquer)
      if not err then
        client:send("answer" .. "\n")
      end


    end




  end

  servant = {ip = ip, port = port, listen = listen}

  table.insert(servants, servant)

  return ip, port

end

--após se registrar, um servente deve aguardar ser acionado
function luarpc.waitIncoming()
  while(true) do
    for _, servant in pairs(servants) do
      servant.listen()
    end
  end

end


--cria um proxy que requerirá as chamadas remotas
function luarpc.createProxy(idl, ip, port)
  --por enquanto, não faz nada com a idl

  --client novo para o proxy
  local client = socket.connect(ip, port)
  if not client then return nil, "connection error" end


  return {foo = function(proxy, ...)

    --faz a request
    client:send("request \n")

    --aguarda resposta do server
    local str, err_msg = client:receive()
    if not str then
      return nil, err_msg
    else
      return str
    end

  end}
end

return luarpc
