
local binser = require("binser")
local mime = require ("mime")
local socket = require ("socket")

local luarpc = {}

--pr�ximos passos:
  -- implementar idl, chamada e retorno de fun��es gen�ricas
  -- implementar v�rias portas ativas

--fun��es auxiliares, n�o exportadas

--fun��o auxiliar debug, imprime uma table
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

--retorna uma table preenchida com defini��es de structs
local function parser_struct(struct_string)
  struct = {}
  
  struct.name = string.match(struct_string, "name%s*=%s*\"(%w*)\"")
  if (not struct.name or struct.name == "") then error("struct without a name field isn't permitted. Aborting") end
  if (struct.name == "int" or struct.name == "double" or struct.name == "number" or struct.name == "string") then
    error("structs's name cannot be " .. struct.name .. "!!!")
  end
  
  fields_string = string.match(struct_string, "fields%s*=%s*(%b{})")
  fields_string = string.sub(fields_string, 2, -2) -- remove {} de abrir e fechar
  struct.fields = {}
  for field_string in string.gmatch(fields_string, "%{[^{}]*%}") do
    field = {}
    field.name = string.match(field_string, "name%s*=%s*\"(%w*)\"")
    if field.name == "name" then error("Struct's field cannot be named 'name'!") end
    field.type = string.match(field_string, "type%s*=%s*\"(%w*)\"")
    table.insert(struct.fields, field)
    
  end
  
  return struct
end

--retorna uma table preenchida com as informa��es da interface
local function interface_parser(interface_string, structs)
	local interface = {}

	interface.name = string.match(interface_string, "name%s*=%s*\"(%w*)\"")
	if (not interface.name or interface.name == "") then error("IDL without a name field isn't permitted. Aborting") end
	methods_string = string.match(interface_string, "methods%s*=%s*(%b{})")

	--array de m�todos
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


--fun��o parser recebe uma string idl(que deve estar no formato especificado no enunciado),
--e retorna uma table com as informa��es dos m�todos da idl
local function parser(idl_string)
  --if type(idl_string) ~= "string" then error("wrong param type: idl_string " .. type(idl_string)) end

  --trata todas as structs
  structs = {}
  for struct_string in string.gmatch(idl_string, "struct%s*(%b{})") do
	  struct = parser_struct(struct_string)
	  structs[struct.name] = struct
  end

  --trata somente uma interface. Se houver mais de uma, a primeira � considerada e as demais ignoradas
  interface_string = string.match(idl_string, "interface%s*(%b{})")
  interface = interface_parser(interface_string, structs)

  --retorna table com a interface (e as structs)
  return interface, structs
end

--truquezinho de declarar antes pq ambas fun��es usam a outra
local structs_match
local types_match

--verifica se a struct bate com a especifica��o fornecida 
structs_match = function(struct, spec)
  --nomes s�o iguais?
  if (struct.name ~= spec.name and struct.type ~= spec.name) then -- permite que a struct informe seu tipo com um campo "name" ou "type"
    return false, "struct's type doesn't match the specification"
  end
  
  --todos os campos pedidos na spec est�o na struct? (permite campos "sobrando" na struct)
  for i, field in ipairs(spec.fields) do
    if not struct[field.name] then
      return false, "Field " .. field.name .. " not present in struct"
    elseif not types_match(struct[field.name], field.type) then
      return false, "Field ".. field.name .. " is present in the struct but has an incompatible type. Wanted " .. field.type
    end
  end
  
  --se nada est� errado, t� certo
  return true
  
end

--checa se tipo fornecido est� OK com especifica��o da idl
types_match = function(val, spec)
  
  if spec == "void" then
    if type(val) == "nil" then return true
    else return false, "Void return expects a nil" end
  
  elseif structs[spec] then
    --trata caso de struct
    local ok, err = structs_match(val, structs[spec])
    if ok then
      return true
    else
      return false, err
    end  
  elseif type(val) == "number" then
    --trata caso especial de n�mero
    
    if spec == "number" or spec == "double" then 
      --se for tipo double, aceita direto, pq o lua vai se tratar certo sendo inteiro ou ponto flutuante, n�o importa
      --estou tamb�m aceitando na idl a especifica��o como 'number', gen�rico
      return true
    elseif spec == "int" then
      --se a idl restringir a um inteiro, aceita s� se convers�o para int funcionou
      val_as_int = math.tointeger(val)
      if val_as_int then
        return true
      else
        --sen�o, aponta erro
        return false, "Error: value cannot be converted to integer"
      end
    else
      return false, "Error: wrong parameter type: " .. type(val) .. " x " .. spec
    end
  elseif type(val) == spec then
    return true
  else
    --aponta erro ao chamador
    return false, "Error: passed parameters are not compatible with the function's signature provided in the idl"
  end
  
end

--ps: preferi serializar os valores dentro de uma lista. Dessa maneira, � poss�vel indicar um retorno vazio pela lista vazia, o que n�o era possivel antes (pq dando table.unpack({}), obtemos *nada*, o que quebrava a de/serializa��o) 
--fun��o para serializa��o de uma table request/reply
local function serialize(values)
  return (mime.b64(binser.serialize((values))))
end

--deserializa��o
local function deserialize(str)
  return (binser.deserialize((mime.unb64(str))))[1] -- retorno de binser.deserialize � uma lista, o [1] � s� pra tirar essa camada extra
end

--fun��es exportadas pela biblioteca: registerServant, waitIncoming, serialize, deserialize

--vars globais

local ip = "localhost" --mudar depois para pegar da linha de comando:


local sockets = {} -- array com os sockets de todos os servants aberto
local servants = {} -- table (indexada por socket) com informa��es do servant: ip, port, fun��o listen, open_conections

local max_connections = 3 --num maximo de conex�es abertas permitidas ao mesmo servant/socket

--fun��o que dada a idl e um servente, o registra e disponibiliza atrav�s da porta
function luarpc.registerServant(idl, object, p_ip, p_port)
  
  --se ip e porta desejados n�o foram especificados, escolhe qualquer porta no localhost
  p_ip = p_ip or "localhost"
  p_port = p_port or 0 -- 0 indica qualquer porta
  
  interface, structs = parser(idl)
  tprint(interface)
  
  
  --verifica se a implementa��o fornecida pelo objeto est� de acordo com a especifica��o fornecida na idl
  --como? (pra que?)   
  
  --abre um socket pra esse servant, salva ele numa lista local

  -- create a TCP socket and bind it to the (local) host, at any port
  
  local server = assert(socket.bind(p_ip, p_port))
  -- find out which port the OS chose for us
  local ip, port = server:getsockname()
  
  server:settimeout(0.1)
  
  local connected_clients = {}
  
  local receive_and_reply = function (client)
    --tenta receber requisi��o:
      local req, err = client:receive()  

      --tendo recebido a requisi��o, atende-a e envia de volta a resposta
      if not err then
        --deserializa
        values = deserialize(req)
        
        func_name = table.remove(values, 1) --values[1] � o nome da fun��o, pelo protocolo
        
        --tenta chamar fun��o com parametros dados
        if object[func_name] and type(object[func_name]) == "function" then
          
          ret_values = table.pack(object[func_name](table.unpack(values)))
          
          -- (to-do: botar params inout)
        else
          --fun��o n�o � implementada pelo objeto.
          -- isso s� acontece se o objeto fornecido como implementador n�o obedece � idl, o que n�o � verificado pelo luarpc
          -- dada essa situa��o, decidi por fechar o server.
          
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
    
    --checa se h� novos clientes tentando conectar(o que pode ser a causa do select ter disparado essa fun��o listen)
    local client, timeout = server:accept()
    
    --se novo cliente conectou,
    if client then
      client:settimeout(0.1)
      if #connected_clients >= max_connections then
        --remove a conex�o mais antiga
        connected_clients[1]:close()
        table.remove(connected_clients, 1)
      end
      table.insert(connected_clients, client)
    end
    
    --checa clientes que j� est�o conectados
    for i = #connected_clients, 1, -1 do --percorre ao contr�rio pra poder fazer a remo��o da tabela sem problemas
      local client = connected_clients[i]
      --receive de 0 bytes serve para apontar se: 
      --a. este cliente est� tentando mandar mensagem; 
      --b. este cliente fechou a conex�o (ou teve a conex�o fechada?)
      --c. n�o � este cliente que est� tentando mandar mensagem (timeout)
      
      local msg, err = client:receive(0)
      if msg then
        --caso a
        receive_and_reply(client)
      elseif err == "closed" then
        --caso b
        table.remove(connected_clients, i) --remove cliente da lista de clientes abertos
      elseif err == "timeout" then
        --caso c
        --n�o preciso fazer nada com este cliente agora
      end
    
    end
    
  end

  servant = {ip = ip, port = port, listen = listen}
  servants[server] = servant

  table.insert(sockets, server)

  return ip, port

end

--ap�s se registrar, um servente deve aguardar ser acionado
function luarpc.waitIncoming()
  while(true) do
    for _, socket in ipairs(sockets) do
      servants[socket].listen()
    end
    
    --[[
    --detecta servants que tiveram alguma altera��o no status
    local canread = socket.select(sockets, nil, 1) --timeout de 0.1 obriga select a checar v�rias vezes, impedindo wait de travar no caso do mesmo cliente fazendo varias reqs seguidas
    for _, socket in ipairs(canread) do
      servants[socket].listen() --manda o servant tratar o cliente(vai realizar o accept, receive etc.)
    end
    --]]
  
  
  end

end


--cria um proxy que requerir� as chamadas remotas
--comunica��o entre o proxy e o requerente obedece ao formato da pcall, 
--comunica��o entre o proxy e o server usa checks de timeout e erro, e dispensa o parametro true/false
function luarpc.createProxy(idl, ip, port)
  --table de fun��es a serem retornadas
  local functions = {}
  local interface, structs = parser(idl)
  
  --abre conex�o para este proxy
  local client = socket.connect(ip, port)
  client:settimeout(1)
  if not client then error("connection error") end

  

  for _, method in ipairs(interface.methods) do
    functions[method.name] = function(...) -- ... � uma jogada bem esperta tirada dos slides
      --valida��o de parametros:
      local params = {...}
      local req_values = {method.name} -- um array com os valores a serem passados adiante ao servidor, por meio da requisi��o

      if(#params ~= #method.args) then
        error("Error: too many or too few arguments(consult idl)")
      end

      --for dessa maneira � necess�rio para se proteger de nils na tabela(funciona?)
      --ps: est� aceitando nils que vem "sobrando" como parametros em excesso
      for i = 1, #params do
        local ok, err = types_match(params[i], method.args[i].type)
        
        if ok then
          table.insert(req_values, params[i])
        else
          error(err)
        end
      end
        

      --chamada do procedimento remoto:
      
      --empacota valores para a request
      local req = serialize(req_values)      
      
      --to do: proteger proxy contra o servidor ter fechado a conex�o
      --envia request
      local bytes_sent = client:send(req.."\n")
      if not bytes_sent or bytes_sent ~= string.len(req.."\n") then
        error("Error: proxy couldn't send message to server.")
      end
      
      --recebe resposta do server
      local str, err_msg = client:receive()
      if err_msg then
        error(err_msg)
      else
        --desempacota reply
        local ret_values = deserialize(str)
        
        -- validar retorno com idl. S� estar� falso se implementador fornecido n�o implementar corretamente a fun��o
        
        --checa tipo do primeiro retorno
        
        local ok, err = types_match(ret_values[1], method.result_type)
        if not ok then error("Implementer object returned invalid types(2)") end
        
        --monta uma tabela com os tipos esperados, considerando s� inout
        local expected_types = {}        
        for i, arg in ipairs(method.args) do
          if arg.direction == "inout" then
            table.insert(expected_types, arg.type)
          end
        end
        
        --ret_values.n � constru�do pela table.pack no retorno da fun��o rpc. Acaba sendo bem �til aqui para n�o ter problemas com nils
        -- +1 pq expected types n�o tem o tipo do primeiro retorno, mas o .n tem
        if #expected_types + 1 ~= ret_values.n then 
          --s� acontece se implementador desobedece protocolo.
          client:close()          
          error("Implementer object returned too many/few parameters")
        end        
        
        for i, val in ipairs(expected_types) do
          local ok, err = types_match(ret_values[i+1], val) -- i+1 pq no ter_values o 1 � o retorno "normal"(sem ser param inout)
                    
          if not ok then
            client:close()
            error("Implementer object returned invalid types(3)")
          end
        end        
        
        --se nada at� agora deu errado, � pq deu certo
        return table.unpack(ret_values, 1, ret_values.n)
        
      end
      
    end
  end

  return functions
  
end


--return da biblioteca
return luarpc
