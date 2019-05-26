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
  
  textbox.textInput = function(textbox, t)
    enteredText = enteredText .. t
  end
  
  textbox.draw = function(textbox)
    love.graphics.printf(displayText .. ": " .. enteredText, posX, posY, love.graphics.getWidth())
  end
  
  local max_length = 50
  textbox.getTextForSending = function(textbox)
    --já limpa, isso vai ser enviado
    old = string.sub(enteredText, 1, max_length)
    enteredText = ""
    return old
  end
  
  return textbox
  
end

return textboxModule
