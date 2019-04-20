local socket = require("socket")

-- Funções que serão chamadas por cada servidor
local function capitalEcho(text)
    return string.upper(text)
end

local function invertedEcho(text)
    return string.reverse(text)
end

-- Criação dos servidores
local server1 = socket.bind("*", 5500)
local server2 = socket.bind("*", 5501)

print("Servidor Capital Echo está escutando na porta 5500")
print("Servidor Inverted Echo está escutando na porta 5501")
print()

-- Lista dos servidores
local servers = {server1, server2}

-- lista indexada por sockets já conectados
local response = {}

-- Associando um servidor com uma determinada função
local functions = {}
functions[server1] = capitalEcho
functions[server2] = invertedEcho


-- Lista dos servidores que serão passados para o select
local reading = {server1, server2}

while true do
    local canread = socket.select(servers)
    for _,server in ipairs(canread) do

        -- Verifica se este server existe na lista de funções
        -- onde cada servidor está associado a uma função
        if functions[server] then

            -- O servidor aceita a conexão
            local conn = server:accept()

            -- Coloca a conexão na lista de servers que é usada pelo select
            table.insert(servers, conn)

            -- Associa a conexão com a função relacionada a esse servidor
            response[conn] = functions[server]

        else
            -- Recebe o texto enviado pelo cliente
            local text, err = server:receive()
            if not err then
                -- Pega a função de resposta associada com o servidor
                local method = response[server]
                -- Executa a função
                local res = method(text)
                server:send(res .. "\n")
            else
                -- Avisa que houve um erro
                print("Erro:", err)

                -- Se o socket estiver fechado, então tem que fechar a conexão
                -- e remover a conexão da lista de servers
                if err == "closed" then
                    server:close()
                    -- TODO: Remover a conexão da lista de servers
                end
            end
        end
    end
end
