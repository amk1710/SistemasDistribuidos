
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

		method.resultype = string.match(method_string, "resulttype%s*=%s*\"(%w+)\"")
		if not (method.resultype or method.resultype == "") then error("Method with no resulttype specification isn't permitted. Aborting") end

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

--função para serialização de uma table request/reply
local function serialize(values)
  return mime.b64(binser.serialize(table.unpack(values)))
end

--deserialização
local function deserialize(str)
  return binser.deserialize(mime.unb64(str))
end

--funções exportadas pela biblioteca: registerServant, waitIncoming, serialize, deserialize


--função que dada a idl e um servente, o registra e disponibiliza através da porta
function luarpc.registerServant(idl, object)

  interface, structs = parser(idl)
  tprint(interface)
  
  
  --verifica se a implementação fornecida pelo objeto está de acordo com a especificação fornecida na idl
  --como? (pra que?)   
  
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
      local req, err = client:receive()  

      --tendo recebido a requisição, atende-a e envia de volta a resposta
      --(por enquanto, uma resposta qualquer)
      if not err then
        --deserializa
        values = binser.deserialize(mime.unb64(req))
        func_name = table.remove(values, 1) --values[1] é o nome da função, pelo protocolo
        --tenta chamar função com parametros dados
        if object[func_name] and type(object[func_name]) == "function" then
          ret = object[func_name](table.unpack(values))
          
          ret_values = {true, ret} --true indica que rpc deu certo
          -- (to-do: botar params inout)
          
          
        else
          --função não é implementada pelo objeto, retorna erro
          ret_values = {false, "function" .. func_name .."was not implemented by the provided object"}
          
        end
        
        -- codifica retorno
        reply = serialize(ret_values)
        
        --envia reply
        client:send(reply .. "\n")        
      
        
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
          param = params[i]
        --checa se parametro passado é compatível com o definido pelo cabeçalho
        -- a principio não aceita nil como parametro nunca (a menos que se defina um parametro do tipo nil na idl, mas pra que?)
        local arg_type = method.args[i].type
        if type(param) == "number" then
          --trata caso especial de número
          
          if arg_type == "number" or arg_type == "double" then 
            --se for tipo double, aceita direto, pq o lua vai se tratar certo sendo inteiro ou ponto flutuante, não importa
            --estou também aceitando na idl a especificação como number genérico
            table.insert(req_values, param)
          elseif arg_type == "int" then
            --se a idl restringir a um inteiro, aceita só se conversão para int funcionou
            param_as_int = math.tointeger(param)
            if param_as_int then
              table.insert(req_values, param)
            else
              --senão, aponta erro
              return nil, "Error: value cannot be converted to integer"
            end
          else
            return nil, "Error: idl defines invalid type:" .. arg_type
          end
        --to do: tratar structs
        elseif type(param) == arg_type then
          --aceita o argumento passado, o adicionando ao array
          table.insert(req_values, param)
        else
          --aponta erro ao chamador
          return nil, "Error: passed parameters are not compatible with the function's signature provided in the idl"
        end

      end

      --chamada do procedimento remoto:
      
      --empacota valores para a request
      req = serialize(req_values)
      
      
      --to do: proteger proxy contra o servidor ter fechado a conexão
      --envia request
      client:send(req.."\n")
      
      --recebe resposta do server
      local str, err_msg = client:receive()
      if not str then
        return false, err_msg
      else
        --desempacota reply
        ret_values = deserialize(str)
        
        return table.unpack(ret_values) --já inclui true, indicando sucesso
      end
      
    end
  end

  return functions
  
end


--return da biblioteca
return luarpc
