class("LightSync")

function LightSync:__init()
  self.globalLightTable = {}
  self.names = {}
  Network:Subscribe("cTableModified", self, self.Update)
  Network:Subscribe("RequestRemoveLight", self, self.RemoveLight)
  Network:Subscribe("RequestMoveLight", self, self.UpdatePosition)
  
  Events:Subscribe("LightLoaded", self, self.Update)
  Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
  Events:Subscribe("ModuleUnload", self, self.Save)
end



function LightSync:Update(args)
  if not self.globalLightTable[args.name] then
    self.globalLightTable[args.name] = args
    table.insert(self.names, args.name)
    Network:Broadcast("Syncing", args)

  else
  end
end

function LightSync:Save()
  LightManager:SaveObjectsToMainFile()
  
end


function LightSync:PlayerJoin(args)
  for i, v in ipairs(self.names) do
    Network:Send(args.player, "Syncing", self.globalLightTable[v])
  end
end

function LightSync:UpdatePosition(args)
  if self.globalLightTable[args.name] then
    self.globalLightTable[args.name].pos = args.newpos
    Network:Broadcast("MoveLight", args)
  end
end

function LightSync:RemoveLight(name)
  self.globalLightTable[name] = nil
  Network:Broadcast("RemoveLight", name)
end

LightSync = LightSync()