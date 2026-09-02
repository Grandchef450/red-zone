fx_version 'bodacious'
game 'gta5'
author 'dullpear'
version '1.0.0'
description 'dpClothing+'

client_scripts {
	'Client/Functions.lua', 		-- Global Functions / Events / Debug and Locale start.
	'Locale/*.lua', 				-- Locales.
	'Client/Config.lua',			-- Configuration.
	'Client/Variations.lua',		-- Variants, this is where you wanan change stuff around most likely.
	'Client/Clothing.lua',
	'Client/GUI.lua',				-- The GUI.
}

-- Logo RedZone au centre de la roue (GUI.lua). Un fichier non
-- déclaré ici n'est pas servi au client : le sprite resterait
-- invisible sans qu'aucune erreur ne s'affiche.
files {
	'img/redzone_logo.png',
}