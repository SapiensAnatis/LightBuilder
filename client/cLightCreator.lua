class("cLightCreator")

function cLightCreator:__init()
  self.activeLights = {}
  
  Events:Subscribe("ModuleUnload", self, self.Cleanup)
  Network:Subscribe("Syncing", self, self.SyncedCreate)
  Network:Subscribe("RemoveLight", self, self.Remove)
  Network:Subscribe("MoveLight", self, self.MoveLight)
end

function cLightCreator:GUICreate(colour, magnitude, size, pos, name)
  if self.activeLights[name] == nil then
    local light = ClientLight.Create{
      position = pos,
      color = colour,
      multiplier = magnitude,
      radius = size,
    }
    
    local args = {["color"] = light:GetColor(), ["mult"] = light:GetMultiplier(), ["radius"] = light:GetRadius(), ["pos"] = light:GetPosition(), ["name"] = name, ["playername"] = LocalPlayer:GetName()}
    
    self.activeLights[name] = light
    
    Network:Send("cTableModified", args)
    
    Events:Fire("cLightCreated", args)
    cLightBuilder.CreateButton:SetText("Create!")
  else
    
  end
end

function cLightCreator:SyncedCreate(args)
  if args then
    if not self.activeLights[args.name] then
      self:SilentCreate(args.color, args.mult, args.radius, args.pos, args.name, args.playername)
    end
  end
end

function cLightCreator:MoveLight(args)
  if self.activeLights[args.name] then
    local light = self.activeLights[args.name]
    light:SetPosition(args.newpos)
  end
end

function cLightCreator:SilentCreate(colour, magnitude, size, pos, name, playername)
  if self.activeLights[name] == nil then
    local light = ClientLight.Create{
      position = pos,
      color = colour,
      multiplier = magnitude,
      radius = size,
    }
    
    self.activeLights[name] = light
    
    local args = {["color"] = light:GetColor(), ["mult"] = light:GetMultiplier(), ["radius"] = light:GetRadius(), ["pos"] = light:GetPosition(), ["name"] = name, ["playername"] = playername}
    
    Events:Fire("cLightCreated", args)
  end
end


function cLightCreator:Remove(name)
  if self.activeLights[name] then
    self.activeLights[name]:Remove()
    self.activeLights[name] = nil
  end
end

function cLightCreator:Cleanup()
  for name, light in pairs(self.activeLights) do
    light:Remove()
    self.activeLights[name] = nil
  end
end

cLightCreator = cLightCreator()