
local binser = require("binser")
local mime = require ("mime")
local socket = require ("socket")

local luarpc = {}

--próximos passos:
  -- implementar idl, chamada e retorno de funções genéricas
  -- implementar várias portas ativas

--funções auxiliares, não exportadas

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

--retorna uma table preenchida com definições de structs
--to-do
local function parser_struct(struct_string)

end

--retorna uma table preenchida com as informações da interface
local function interface_parser(interface_string)
	local interface = {}

	interface.name = string.match(interface_string, "name%s*=%s*\"(%w*)\"")
	if (not interface.name or interface.name == "") then error("IDL without a name field isn't permitted. Aborting") end
	methods_string = string.match(interface_string, "methods%s*=%s*(%b{})")

	--array de métodos
	interface.methods = {}
	for method_string in string.gmatch(methods_string, "%w*%s* =%s*%b{}") do
		method = {}

		method.name = string.match(method_string, "(%w*)%s*=%s*%b{}")
		if (not method.name or method.name == "") then error("Unnamed method isn't permitted. Aborting") end

		method.result_type = string.match(method_string, "resulttype%s*=%s*\"(%w+)\"")
		if not (method.result_type or method.result_type == "") then error("Method with no resulttype specification isn't permitted. Aborting") end

		method.args = {}

		args_string = string.match(method_string, "args%s*=%s*(%b{})")
		args_string = string.sub(args_string, 2, -2) -- remove {} de abrir e fechar
		for arg_string in string.gmatch(args_string, "(%b{})") do
			arg = {}
			arg.direction = string.match(arg_string, "direction%s*=%s*\"(%w*)\"")
			arg.type = string.match(arg_string, "type%s*=%s*\"(%w*)\"")
			table.insert(method.args, arg)
		end

		table.insert(interface.methods, method)

	end

	if #interface.methods == 0 then error("Interface specifies no methods. Aborting") end

	return interface

end


--função parser recebe uma string idl(que deve estar no formato especificado no enunciado),
--e retorna uma table com as informações dos métodos da idl
local function parser(idl_string)
  --if type(idl_string) ~= "string" then error("wrong param type: idl_string " .. type(idl_string)) end

  --trata todas as structs
  i = 0
  for struct_string in string.gmatch(idl_string, "struct%s*%b{}") do
	parser_struct(struct_string)
  end

  --trata somente uma interface. Se houver mais de uma, a primeira é considerada e as demais ignoradas
  interface_string = string.match(idl_string, "interface%s*(%b{})")
  interface = interface_parser(interface_string)

  --retorna table com a interface (e as structs)
  return interface
end


--ps: preferi serializar os valores dentro de uma lista. Dessa maneira, é possível indicar um retorno vazio pela lista vazia, o que não era possivel antes (pq dando table.unpack({}), obtemos *nada*, o que quebrava a de/serialização) 
--função para serialização de uma table request/reply
local function serialize(values)
  return (mime.b64(binser.serialize((values))))
end

--deserialização
local function deserialize(str)
  return (binser.deserialize((mime.unb64(str))))[1] -- retorno de binser.deserialize é uma lista, o [1] é só pra tirar essa camada extra
end

--funções exportadas pela biblioteca: registerServant, waitIncoming, serialize, deserialize

--vars globais

local ip = "localhost" --mudar depois para pegar da linha de comando:


local sockets = {} -- array com os sockets de todos os servants aberto
local servants = {} -- table (indexada por socket) com informações do servant: ip, port, função listen, open_conections

local max_connections = 3 --num maximo de conexões abertas permitidas ao mesmo servant/socket

--função que dada a idl e um servente, o registra e disponibiliza através da porta
function luarpc.registerServant(idl, object, p_ip, p_port)
  
  --se ip e porta desejados não foram especificados, escolhe qualquer porta no localhost
  p_ip = p_ip or "localhost"
  p_port = p_port or 0 -- 0 indica qualquer porta
  
  print(p_ip, p_port)

  interface, structs = parser(idl)
  tprint(interface)
  
  
  --verifica se a implementação fornecida pelo objeto está de acordo com a especificação fornecida na idl
  --como? (pra que?)   
  
  --abre um socket pra esse servant, salva ele numa lista local

  -- create a TCP socket and bind it to the (local) host, at any port
  
  local server = assert(socket.bind(p_ip, p_port))
  -- find out which port the OS chose for us
  local ip, port = server:getsockname()
  
  server:settimeout(0)
  
  local connected_clients = {}
  
  local receive_and_reply = function (client)
    --tenta receber requisição:
      local req, err = client:receive()  

      --tendo recebido a requisição, atende-a e envia de volta a resposta
      if not err then
        --deserializa
        values = deserialize(req)
        print("values:")
        tprint(values)
        func_name = table.remove(values, 1) --values[1] é o nome da função, pelo protocolo
        --tenta chamar função com parametros dados
        print(func_name)
        if object[func_name] and type(object[func_name]) == "function" then
          ret_values = table.pack(object[func_name](table.unpack(values)))
          
          -- (to-do: botar params inout)
        else
          --função não é implementada pelo objeto.
          -- isso só acontece se o objeto fornecido como implementador não obedece à idl, o que não é verificado pelo luarpc
          -- dada essa situação, decidi por fechar o server.
          
          client:close()
          server:close() --fecha socket todo
          error("Server closed because provide implementer didn't implement funcion provided in the idl")
          
        end
        
        -- codifica retorno
        reply = serialize(ret_values)
        
        --envia reply
        client:send(reply .. "\n")
        
      end
  end

  local listen = function()
    
    --checa se há novos clientes tentando conectar(o que pode ser a causa do select ter disparado essa função listen)
    local client, timeout = server:accept()
    
    --se novo cliente conectou,
    if client then
      client:settimeout(1)
      if #connected_clients >= max_connections then
        --remove a conexão mais antiga
        print("clientes demais nesse socket!")
        table.remove(connected_clients, 1)
      end
      table.insert(connected_clients, client)
    end
    
    --checa clientes que já estão conectados
    for i = #connected_clients, 1, -1 do --percorre ao contrário pra poder fazer a remoção da tabela sem problemas
      local client = connected_clients[i]
      --receive de 0 bytes serve para apontar se: 
      --a. este cliente está tentando mandar mensagem; 
      --b. este cliente fechou a conexão (ou teve a conexão fechada?)
      --c. não é este cliente que está tentando mandar mensagem (timeout)
      
      local msg, err = client:receive(0)
      print(msg == "", err, i)
      if msg then
        --caso a
        print("cliente antigo veio de novo")
        receive_and_reply(client)
      elseif err == "closed" then
        --caso b
        print("cliente antigo fechou a conexão")
        table.remove(connected_clients, i) --remove cliente da lista de clientes abertos
      elseif err == "timeout" then
        --caso c
        print("cliente antigo não fechou ainda")
        --não preciso fazer nada com este cliente agora
      end
    
    end
    
  end

  servant = {ip = ip, port = port, listen = listen}
  servants[server] = servant

  table.insert(sockets, server)

  return ip, port

end

--após se registrar, um servente deve aguardar ser acionado
function luarpc.waitIncoming()
  while(true) do
    for _, socket in ipairs(sockets) do
      servants[socket].listen()
    end
    
    --[[
    --detecta servants que tiveram alguma alteração no status
    local canread = socket.select(sockets, nil, 1) --timeout de 0.1 obriga select a checar várias vezes, impedindo wait de travar no caso do mesmo cliente fazendo varias reqs seguidas
    for _, socket in ipairs(canread) do
      servants[socket].listen() --manda o servant tratar o cliente(vai realizar o accept, receive etc.)
    end
    --]]
  
  
  end

end

--checa se tipo fornecido está OK com especificação da idl
local function types_match(val, spec)
  --to do: tratar structs
  
  if type(val) == "number" then
    --trata caso especial de número
    
    if spec == "number" or spec == "double" then 
      --se for tipo double, aceita direto, pq o lua vai se tratar certo sendo inteiro ou ponto flutuante, não importa
      --estou também aceitando na idl a especificação como 'number', genérico
      return true
    elseif spec == "int" then
      --se a idl restringir a um inteiro, aceita só se conversão para int funcionou
      val_as_int = math.tointeger(val)
      if val_as_int then
        return true
      else
        --senão, aponta erro
        return false, "Error: value cannot be converted to integer"
      end
    else
      return false, "Error: wrong parameter type: " .. type(val) .. " x " .. spec
    end
  --to do: tratar structs
  elseif type(val) == spec then
    return true
  else
    --aponta erro ao chamador
    return false, "Error: passed parameters are not compatible with the function's signature provided in the idl"
  end
  
end

--cria um proxy que requerirá as chamadas remotas
--comunicação entre o proxy e o requerente obedece ao formato da pcall, 
--comunicação entre o proxy e o server usa checks de timeout e erro, e dispensa o parametro true/false
function luarpc.createProxy(idl, ip, port)
  --table de funções a serem retornadas
  local functions = {}
  local interface, structs = parser(idl)
  
  --abre conexão para este proxy
  local client = socket.connect(ip, port)
  if not client then return nil, "connection error" end
  

  for _, method in ipairs(interface.methods) do
    functions[method.name] = function(...) -- ... é uma jogada bem esperta tirada dos slides
      --validação de parametros:
      local params = {...}
      local req_values = {method.name} -- um array com os valores a serem passados adiante ao servidor, por meio da requisição

      if(#params ~= #method.args) then
        return nil, "Error: too many or too few arguments(consult idl)"
      end

      --for dessa maneira é necessário para se proteger de nils na tabela(funciona?)
      --ps: está aceitando nils que vem "sobrando" como parametros em excesso
      for i = 1, #params do
        local ok, err = types_match(params[i], method.args[i].type)
        
        if ok then
          table.insert(req_values, param)
        else
          return false, err
        end
      end
        

      --chamada do procedimento remoto:
      
      --empacota valores para a request
      local req = serialize(req_values)      
      
      --to do: proteger proxy contra o servidor ter fechado a conexão
      --envia request
      local bytes_sent = client:send(req.."\n")
      if bytes_sent ~= string.len(req.."\n") then
        return false, "Error: proxy couldn't send message to server."
      end
      
      --recebe resposta do server
      local str, err_msg = client:receive()
      if not str then
        return false, err_msg
      else
        --desempacota reply
        local ret_values = deserialize(str)
        
        tprint(ret_values)
        -- validar retorno com idl. Só estará falso se implementador fornecido não implementar corretamente a função
        
        --checa tipo do primeiro retorno
        if type(ret_values[1]) == "nil" and method.result_type ~= "void" then
          return false, "Implementer object returned invalid types(1)"
        elseif not types_match(ret_values[1], method.result_type) then
          return false, "Implementer object returned invalid types(2)"
        end
        
        --monta uma tabela com os tipos esperados, considerando só inout
        local expected_types = {}        
        for i, arg in ipairs(method.args) do
          if arg.direction == "inout" then
            table.insert(expected_types, arg.type)
          end
        end
        
        print("qtds:" ,#expected_types, ret_values.n)
        --ret_values.n é construído pela table.pack no retorno da função rpc. Acaba sendo bem útil aqui para não ter problemas com nils
        -- +1 pq expected types não tem o tipo do primeiro retorno, mas o .n tem
        if #expected_types + 1 ~= ret_values.n then 
          --só acontece se implementador desobedece protocolo.
          client:close()          
          return false, "Implementer object returned too many/few parameters"
        end        
        
        for i, val in ipairs(expected_types) do
          local ok, err = types_match(ret_values[i+1], val) -- i+1 pq no ter_values o 1 é o retorno "normal"(sem ser param inout)
                    
          if not ok then
            client:close()
            return false, "Implementer object returned invalid types(3)"
          end
        end        
        
        --se nada até agora deu errado, é pq deu certo
        print("ret_values:")
        tprint(ret_values)
        return true, table.unpack(ret_values, 1, ret_values.n) --inclui true, indicando sucesso
        --se a função rpc for void, o retorno normal é omitido e se passa diretamente para os inout
      end
      
    end
  end

  return functions
  
end


--return da biblioteca
return luarpc
