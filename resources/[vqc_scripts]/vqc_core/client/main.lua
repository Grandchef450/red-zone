local math = require 'glm'
-- local table = lib.table
-- local player = Ox.GetPlayer()
-- local playerState = LocalPlayer.state -- Access client's own StateBag

--print(variable)
--print(json.encode(variable, { indent = true }))

DensityMultiplier = 0.0	-- Density values from 0.0 to 1.0.
local isCrouching = false
local crouchKey = 36 --default 26 = C (lookback)

Citizen.CreateThread(function()
	while true do

		-- Désactiver les sons ambiants
        StartAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE")
        
        -- Empêche certains rapports de police (utile si tu veux aussi désactiver ce bruit-là)
        CancelCurrentPoliceReport()

		-------

		
		Citizen.Wait(0)

		--lib.disableControls()

	   --HIDE HUD COMPONENT HERE, UNCOMMENT TO HIDE
		HideHudComponentThisFrame(1)	--WANTED_STARS
		HideHudComponentThisFrame(2)	--WEAPON_ICON
		HideHudComponentThisFrame(3)	--CASH
		HideHudComponentThisFrame(4)	--MP_CASH
		HideHudComponentThisFrame(5)	--MP_MESSAGE
		HideHudComponentThisFrame(6)	--VEHICLE_NAME
		HideHudComponentThisFrame(7)	--AREA_NAME
		HideHudComponentThisFrame(8)	--VEHICLE_CLASS
		HideHudComponentThisFrame(9)	--STREET_NAME
		--HideHudComponentThisFrame(10)	--HELP_TEXT
		--HideHudComponentThisFrame(11)	--FLOATING_HELP_TEXT_1
		--HideHudComponentThisFrame(12)	--FLOATING_HELP_TEXT_2
		HideHudComponentThisFrame(13)	--CASH_CHANGE
		--HideHudComponentThisFrame(14)	--RETICLE
		--HideHudComponentThisFrame(15)	--SUBTITLE_TEXT
		--HideHudComponentThisFrame(16)	--RADIO_STATIONS
		HideHudComponentThisFrame(17)	--SAVING_GAME
		HideHudComponentThisFrame(18)	--GAME_STREAM
		HideHudComponentThisFrame(19)	--WEAPON_WHEEL
		HideHudComponentThisFrame(20)	--WEAPON_WHEEL_STATS
		--HideHudComponentThisFrame(21)	--HUD_COMPONENTS
		--HideHudComponentThisFrame(22)	--HUD_WEAPONS	

	   --NPCs DENSITY
	    SetVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetPedDensityMultiplierThisFrame(DensityMultiplier)
	    SetRandomVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetParkedVehicleDensityMultiplierThisFrame(DensityMultiplier)
	    SetScenarioPedDensityMultiplierThisFrame(DensityMultiplier, DensityMultiplier)

	   --ANTI STEALTH, BUT FORCE CROUCH
	   	-- Prevent stealth mode while allowing crouch
		if GetPedStealthMovement(playerPed) then
			SetPedStealthMovement(playerPed, 0)
		end
        --Toggle crouch with a key press (e.g., Left Control)
		local ped = GetPlayerPed( -1 )
		if ( DoesEntityExist( ped ) and not IsEntityDead( ped ) ) then 
			DisableControlAction( 0, crouchKey, true ) 
			if ( not IsPauseMenuActive() ) then 
				if ( IsDisabledControlJustPressed( 0, crouchKey ) and not proned ) then 
					RequestAnimSet( "move_ped_crouched" )
					RequestAnimSet("MOVE_M@TOUGH_GUY@")
					
					while ( not HasAnimSetLoaded( "move_ped_crouched" ) ) do 
						Citizen.Wait( 100 )
					end 
					while ( not HasAnimSetLoaded( "MOVE_M@TOUGH_GUY@" ) ) do 
						Citizen.Wait( 100 )
					end 		
					if ( isCrouching and not proned ) then 
						ResetPedMovementClipset( ped )
						ResetPedStrafeClipset(ped)
						SetPedMovementClipset( ped,"MOVE_M@TOUGH_GUY@", 0.5)
						isCrouching = false 
					elseif ( not isCrouching and not proned ) then
						SetPedMovementClipset( ped, "move_ped_crouched", 0.55 )
						SetPedStrafeClipset(ped, "move_ped_crouched_strafing")
						isCrouching = true 
					end 
				end
			end
		else
			isCrouching = false
		end

	end

end)