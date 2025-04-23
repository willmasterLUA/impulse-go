-- Define gamemode information.
GM.Name = "impulse"
GM.Author = "vin"
GM.Website = "https://2i.games"
impulse.Version = 1.74
MsgC( Color( 83, 143, 239 ), "[impulse] Starting shared load...\n" )
meta = FindMetaTable("Player")

local name = engine.ActiveGamemode()
SCHEMA_NAME = name

-- Called after the gamemode has loaded.
function GM:Initialize()
	impulse.reload()
end

-- Called when a file has been modified.
function GM:OnReloaded()
	impulse.reload()
end

if (SERVER) then
	concommand.Remove("gm_save")
	concommand.Remove("gmod_admin_cleanup")
	RunConsoleCommand("sv_defaultdeployspeed", 1)
end

-- disable widgets cause it uses like 30% server cpu lol
function widgets.PlayerTick()
end

hook.Remove("PlayerTick", "TickWidgets")

function impulse.lib.LoadFile(fileName)
	if (!fileName) then
		error("[impulse] File to include has no name!")
	end

	if fileName:find("sv_") then
		if (SERVER) then
			include(fileName)
		end
	elseif fileName:find("sh_") then
		if (SERVER) then
			AddCSLuaFile(fileName)
		end
		include(fileName)
	elseif fileName:find("cl_") then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			include(fileName)
		end
	elseif fileName:find("rq_") then
		if (SERVER) then
			AddCSLuaFile(fileName)
		end

		_G[string.sub(fileName, 26, string.len(fileName) - 4)] = include(fileName)
	end
end

function impulse.lib.includeDir(directory, hookMode, variable, uid)
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
    	if hookMode then
    		impulse.Schema.LoadHooks(directory.."/"..v, variable, uid)
    	else
    		impulse.lib.LoadFile(directory.."/"..v)
    	end
	end
end

-- Loading 3rd party libs
impulse.lib.includeDir(SCHEMA_NAME .. "/gamemode/libs")
-- Load config
impulse.Config = impulse.Config or {}

-- Create impulse folder
file.CreateDir("impulse")

local isPreview = CreateConVar("impulse_ispreview", 0, FCVAR_REPLICATED, "If the current build is in preview mode.")

if SERVER then
	impulse.YML = {}
	local dbFile = "impulse/config.yml"

	impulse.DB = {
		ip = "localhost",
		username = "root",
		password = "",
		database = "impulse_development",
		port = 3306
	}

	local dbConfLoaded = false

	if file.Exists(dbFile, "DATA") then
		local worked, err = pcall(function() impulse.Yaml.Read("data/"..dbFile) end) 

		if worked then
			local dbConf = impulse.Yaml.Read("data/"..dbFile)

			if dbConf and type(dbConf) == "table" then
				if dbConf.db and type(dbConf.db) == "table" then
					table.Merge(impulse.DB, dbConf.db)
					print("[impulse] [config.yml] Loaded release database config file!")
					dbConfLoaded = true

					if dbConf.dev and type(dbConf.dev) == "table" then
						if dbConf.dev.preview then
							isPreview:SetInt(1)
						end
					end
				end

				if dbConf.schemadb and dbConf.schemadb[engine.ActiveGamemode()] then
					impulse.DB.database = dbConf.schemadb[engine.ActiveGamemode()]
				end

				impulse.YML = dbConf
			end
		else
			print("[impulse] [config.yml] Error: "..err)
			SetGlobalString("impulse_fatalerror", "Failed to load config.yml, error: "..err)
		end
	end

	impulse.YML = impulse.YML or {}
	impulse.YML.apis = impulse.YML.apis or {}

	if not dbConfLoaded then
		print("[impulse] [config.yml] No database configuration found. Assuming development database configuration. If this is a live server please setup this file!")
		isPreview:SetInt(1) -- assume we're running a preview build then i guess?
	end
end

-- Load DB
if SERVER then
	mysql:Connect(impulse.DB.ip, impulse.DB.username, impulse.DB.password, impulse.DB.database, impulse.DB.port)
end
-- Load core
impulse.lib.includeDir(SCHEMA_NAME .. "/gamemode/core")
-- Load core vgui elements
impulse.lib.includeDir(SCHEMA_NAME .. "/gamemode/core/vgui")
-- Load hooks
impulse.lib.includeDir(SCHEMA_NAME .. "/gamemode/core/hooks")

function impulse.reload()
	GM = GM or GAMEMODE
    MsgC( Color( 83, 143, 239 ), "[impulse] Reloading gamemode...\n" )
    impulse.lib.includeDir(SCHEMA_NAME .. "/gamemode/core")

	impulse.reloadPlugins()

	GM = nil
end

function impulse.reloadPlugins()
	local files, plugins = file.Find(SCHEMA_NAME.."/plugins/*", "LUA")

	for v, dir in ipairs(plugins) do
		if impulse.Config.DisabledPlugins and impulse.Config.DisabledPlugins[dir] then
			continue
		end

		MsgC(Color( 83, 143, 239 ), "[impulse] ["..SCHEMA_NAME.."] Loading plugin '"..dir.."'\n")
		impulse.Schema.LoadPlugin(SCHEMA_NAME.."/plugins/"..dir, dir)
	end
end


MsgC( Color( 0, 255, 0 ), "[impulse] Completeing shared load...\n" )

MsgC(Color( 83, 143, 239 ), "[impulse] Loading '"..SCHEMA_NAME.."' schema files...\n")

if SERVER and not file.Exists(SCHEMA_NAME, "LUA") then
	SetGlobalString("impulse_fatalerror", "Failed to load Schema '"..name.."', does not exist.")
end

local bootController = SCHEMA_NAME.."/schema/bootcontroller.lua"

if file.Exists(bootController, "LUA") then
	MsgC(Color( 83, 143, 239 ), "[impulse] Loading bootcontroller...\n")

	if SERVER then
		include(bootController)
		AddCSLuaFile(bootController)
	else
		include(bootController)
	end
end

impulse.lib.includeDir(SCHEMA_NAME.."/schema/teams")
impulse.lib.includeDir(SCHEMA_NAME.."/schema/items")
impulse.lib.includeDir(SCHEMA_NAME.."/schema/benches")
impulse.lib.includeDir(SCHEMA_NAME.."/schema/mixtures")
impulse.lib.includeDir(SCHEMA_NAME.."/schema/buyables")
impulse.lib.includeDir(SCHEMA_NAME.."/schema/vendors")
impulse.lib.includeDir(SCHEMA_NAME.."/schema/config")

local mapPath = SCHEMA_NAME.."/schema/config/maps/"..game.GetMap()..".lua"

if SERVER and file.Exists("gamemodes/"..mapPath, "GAME") then
	MsgC(Color( 83, 143, 239 ), "[impulse] Loading map config for '"..game.GetMap().."'\n")
	include(mapPath)
	AddCSLuaFile(mapPath)
	
	if impulse.Config.MapWorkshopID then
		resource.AddWorkshop(impulse.Config.MapWorkshopID)
	end

	if impulse.Config.MapContentWorkshopID then
		resource.AddWorkshop(impulse.Config.MapContentWorkshopID)
	end
elseif CLIENT then
	include(mapPath)
	AddCSLuaFile(mapPath) 
else
	MsgC(Color(255, 0, 0), "[impulse] No map config found!'\n")
end

hook.Run("PostConfigLoad")

impulse.lib.includeDir(SCHEMA_NAME.."/schema/scripts", true, "SCHEMA", name)
impulse.lib.includeDir(SCHEMA_NAME.."/schema/scripts/vgui", true, "SCHEMA", name)
impulse.lib.includeDir(SCHEMA_NAME.."/schema/scripts/hooks", true, "SCHEMA", name)


GM.Name = "impulse: "..impulse.Config.SchemaName

timer.Simple(1, function() -- hackyfix needs changing to something reliable
	hook.Run("OnSchemaLoaded")
end)
