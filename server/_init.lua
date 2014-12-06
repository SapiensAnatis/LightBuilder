firstTime = true

Events:Subscribe("ClientModuleLoad", function()
  
  if firstTime then
    LightManager:LoadObjects()
    firstTime = false
  end
  
end)
