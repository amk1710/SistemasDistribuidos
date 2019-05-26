--[[

modulo textbox:
  responsável por implementar uma textbox simplíssima
  
--]]


local textboxModule = {}

textboxModule.createTextbox = function(posX, posY, displayText)

  textbox = {}
  
  local posX = posX
  local posY = posY
  local displayText = displayText
  local enteredText = ""
  
  local banned_words = {}
  --preenche dicionário de palavras banidas
  -- para cada linha, 
  for line in io.lines("bannedwords.txt") do 
    banned_words[line] = true
  end
  
  textbox.textInput = function(textbox, t)
    enteredText = enteredText .. t
  end
  
  textbox.draw = function(textbox)
    love.graphics.printf(displayText .. ": " .. enteredText, posX, posY, love.graphics.getWidth())
  end
  
  local max_length = 50
  textbox.getTextForSending = function(textbox)
    
    --checa se há alguma palavra banida na mensagem
    for word in string.gmatch(enteredText, "%w+") do
      if banned_words[word] then
        enteredText = ""
        return false, "---"
      end
    end
    
    --já limpa, isso vai ser enviado
    old = string.sub(enteredText, 1, max_length)
    enteredText = ""
    
    return true, old
  end
  
  return textbox
  
end

return textboxModule
