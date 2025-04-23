resource.AddWorkshop("3010264401") -- Impulse: Enhanced framework Content

DeriveGamemode("sandbox")

MsgC(Color(83, 143, 239), '[impulse] Starting boot sequence...')

print('\n\n\nCopyright (c) 2021 2i games (www.2i.games)')
print('No permission is granted to USE, REPRODUCE, EDIT or SELL this software.\n\n\n')

MsgC( Color( 83, 143, 239 ), "[impulse] Starting server load...\n" )
impulse = impulse or {} -- defining global function table

impulse.meta = FindMetaTable("Player")
impulse.lib = {}

-- load the framework bootstrapper

AddCSLuaFile("shared.lua")
include("shared.lua")

MsgC( Color( 0, 255, 0 ), "[impulse] Completed server load...\n" )

-- security overrides, people should have these set anyway, but this is just in case
RunConsoleCommand("sv_allowupload", "0")
RunConsoleCommand("sv_allowdownload", "0")
RunConsoleCommand("sv_allowcslua", "0")
