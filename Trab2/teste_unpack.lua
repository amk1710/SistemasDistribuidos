
binser = require("binser")
mime = require("mime")

values_o = {"nome", "asdasd", "sfsdf", nil, "qwqwe"}

local function func(...)
	local values = {...}
	print(#values)
	print(table.maxn(values))
	print(unpack(values))
	print(unpack(values, 1,5))
end


func("nome", "asdasd", "sfsdf", nil, "qwqwe")

print(type(nil))
