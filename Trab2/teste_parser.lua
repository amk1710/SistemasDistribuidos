
local input_file = io.open("ibl.txt", "r")


ibl = input_file:read("*a")
--print(ibl)

--funções auxiliares, não exportadas
local function parser(idl_string)
  --if type(idl_string) ~= "string" then error("wrong param type: idl_string " .. type(idl_string)) end

  --trata todas as structs
  --for elem in string.gmatch(idl_string, "struct%s*{[%s%w]*}")
  i = 0
  for elem in string.gmatch(idl_string, "struct%s*%b{}") do
	print(elem)
  end

  --trata somente uma interface. Se houver mais de uma, a primeira é considerada e as demais ignoradas

end


parser(ibl)
