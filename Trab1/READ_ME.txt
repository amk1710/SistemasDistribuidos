SOBRE A ORGANIZAÇÃO DOS ARQUIVOS:

O arquivo relatorio.txt contém o relatório de desempenho dos dois pares server-client

Os pares server1.lua e client1.lua implementam a versão em que a conexão é fechada e reaberta a cada ciclo request-reply

Os pares server2.lua e client2.lua implementam a versão em que a conexão só é fechada a pedido do cliente, possibilitando múltiplos request-replys por conexão aberta

Os arquivos com output no nome tem os outputs que utiilizei para o relatório

O arquivo echoServer.lua é uma implementação de um simples servidor echo, retirada do próprio site do Lua Socket e usada por mim como base