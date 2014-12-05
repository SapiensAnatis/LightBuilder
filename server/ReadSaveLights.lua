class("LightManager")

function LightManager:__init()
end

function LightManager:LoadObjects()
	self:LoadObjectsFromFile("SaveFile.txt")
	return true
end
		
function LightManager:LoadObjectsFromSemiSave()
	self:LoadObjectsFromFile("SemiSave.txt")
	return true
end

function LightManager:LoadObjectsFromBackup()
  
	self:LoadObjectsFromFile("Save.txt.backup")
	return true
end

function LightManager:LoadObjectsFromFile(fileName)
	print("Loading " .. fileName .. "...")
	local file = io.open(fileName, "r" )
	if file == nil then
		print("'" .. fileName .. "' Doesn't exist!")
		return false
	end
	local count = 0
	local timer = Timer()
	for line in file:lines() do
		if line:sub(1,1) == "C" then
			count = count + 1
			line = line:gsub( "ClientLight%(", "" )
			line = line:gsub( "%)", "" )
			line = line:gsub( " ", "" )
			local tokens = line:split( "," )
      local name_str      = tokens[1]
			local pos_str       = { tokens[4], tokens[5], tokens[6] }
			local color_str       = { tokens[7], tokens[8], tokens[9] }
			local creator_str		= tokens[2]
			local mult_str		= tokens[3]
      local rad_str = tokens[11]
			local args = {}
			args.pos       = Vector3(	tonumber( pos_str[1] ), 
											tonumber( pos_str[2] ),
											tonumber( pos_str[3] ) )

			args.color          = Color(	tonumber(color_str[1] ),
											tonumber( color_str[2] ),
											tonumber( color_str[3] ))
                    
			args.playername			= tostring(creator_str)
			args.mult = tonumber(mult_str)
      args.radius = tonumber(rad_str)
      args.name = tostring(name_str)

      local newArgs = {["color"] = args.color, ["mult"] = args.mult, ["radius"] = args.radius, ["pos"] = args.pos, ["name"] = args.name, ["playername"] = args.playername}
			Events:Fire("LightLoaded", newArgs)


		end
	end
	file:close()
	local LoadTime	=	timer:GetSeconds()
	local AvgLoadPerSecond = 4
	return true
end

function LightManager:SaveObjectsToFile(fileName)
  local oldFile = io.open(fileName, "r")
  local oldContent = oldFile:read("*all")
  oldFile:close()
  
  local backup = io.open(fileName .. ".backup", "w")
  
  if oldContent == nil then
    oldContent = "There was nothing last time"
  end
  
  backup:write(oldContent)
  
	local wipe = io.open(fileName,"w")
	wipe:close()
	local timer = Timer()
	local count = 0
	local file = io.open(fileName,"a")

	for i, v in pairs(LightSync.globalLightTable) do
		count = count + 1
		local name 	= v.name
		local playername 	= v.playername
		local multiplier = v.mult
		local position 	= string.format(" %s", v.pos,"," )
		local color 	= string.format(" %s", v.color, "," )
    local radius = v.radius
		file:write("\n", "ClientLight(", name, ",", playername, ",", multiplier, "," , position, ",", color, ",", radius, ")")
	end
	file:close()

	return true, 1, 2
end

function LightManager:SaveObjectsToMainFile()
	local FileToSave	=	"SaveFile.txt"
	local Success, Efficiency, Time	=	self:SaveObjectsToFile(FileToSave)
	if Success then
		AutoSaveEfficiency	=	Efficiency
		AutosaveLastTime	=	Time
		return true
	else
		print("Fatal Error Saving '" .. FileToSave .. "'!")
		return false
	end
end

LightManager = LightManager()