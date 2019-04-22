
local input_file = io.open("idl.txt", "r")


idl = input_file:read("*a")
--print(ibl)


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
local function parser_struct(struct_string)
  struct = {}
  
  struct.name = string.match(struct_string, "name%s*=%s*\"(%w*)\"")
  if (not struct.name or struct.name == "") then error("struct without a name field isn't permitted. Aborting") end
  
  fields_string = string.match(struct_string, "fields%s*=%s*(%b{})")
  fields_string = string.sub(fields_string, 2, -2) -- remove {} de abrir e fechar
  --print(fields_string)
  struct.fields = {}
  for field_string in string.gmatch(fields_string, "%{[^{}]*%}") do
    field = {}
    field.name = string.match(field_string, "name%s*=%s*\"(%w*)\"")
    field.type = string.match(field_string, "type%s*=%s*\"(%w*)\"")
    table.insert(struct.fields, field)
    
  end
  
  return struct
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
  structs = {}
  for struct_string in string.gmatch(idl_string, "struct%s*(%b{})") do
	  table.insert(structs, parser_struct(struct_string))
  end

  --trata somente uma interface. Se houver mais de uma, a primeira é considerada e as demais ignoradas
  interface_string = string.match(idl_string, "interface%s*(%b{})")
  interface = interface_parser(interface_string)

  --retorna table com a interface (e as structs)
  return interface, structs
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

--verifica se a struct bate com a especificação fornecida 
local function structs_match(struct, spec)
  --nomes são iguais?
  if (struct.name ~= spec.name and struct.type ~= spec.name) then -- permite que a struct informe seu tipo com um campo "name" ou "type"
    return false, "struct's type doesn't match the specification"
  end
  
  --todos os campos pedidos na spec estão na struct? (permite campos "sobrando" na struct)
  for i, field in ipairs(spec.fields) do
    if not struct[field.name] then
      return false, "Field " .. field.name .. " not present in struct"
    elseif not types_match(struct[field.name], field.type) then
      return false, "Field ".. field.name .. " is present in the struct but has an incompatible type. Wanted " .. field.type
    end
  end
  
  --se nada está errado, tá certo
  return true
  
end

interface, structs = parser(idl)

struct1 = {name = "minhaStruct", nome = "", peso = 10.5, idade = 10}

print(structs_match(struct1, structs[1]))

