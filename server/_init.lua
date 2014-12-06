Events:Subscribe("ReadyToLoad", function()
  print("Starting file loading...")
  LightManager:LoadObjects()
end)