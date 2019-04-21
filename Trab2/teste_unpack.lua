
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

local function func2(a)
	a = 10
end

b = 5
_, val = func2(b)
print(b)
