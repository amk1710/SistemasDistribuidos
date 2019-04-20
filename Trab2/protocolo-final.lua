local mime = require("mime")
local binser = require("binser")

function printValues(tab)
    for k,v in pairs(tab) do
        print(k,v)
        if type(v) == "table" then
            for k,v in pairs(v) do
                print("\t",k,v)
                if type(v) == "table" then
                    for k,v in pairs(v) do
                        print("\t\t",k,v)
                    end
                end
            end
        end
    end
end

local mystruct = { 
    name = "minhaStruct", 
    fields = {
        nome = "Fulano da Silva",
        peso = "67",
        idade = "42"
    }
}

-- Tabela com o nome da função e os parêmetros que serão enviados para o servidor
local values = {
    "foobar",   -- nome da função
    1,          -- primeiro parâmetro
    2,          -- segundo parâmetro
    mystruct,   -- terceiro parâmentro
    "TExto Com \n quebra de LinHa" -- vc entenderam :-)
}

print("ANTES DO ENVIO")
printValues(values)
print("\n==========================================================\n")

-- Serializando os dados
local data = binser.serialize(table.unpack(values))

-- Codificando os dados em base64 para o envio
local req = mime.b64(data)

-- Envia para o servidor (NÃO ESQUECER DO \n)
-- _, err = client:send( req .. "\n") 

-- ...

-- Recebendo os dados no servidor
-- local req, err = server:receive()
local res = mime.unb64(req)
local data = binser.deserialize(res)

print("DEPOIS DO RECEBIMENTO")
printValues(data)

