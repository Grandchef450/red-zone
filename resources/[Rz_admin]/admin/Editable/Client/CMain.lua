local function getAmbulanceSystem()
	local cfg = Config.AmbulanceSystem or 'standalone'
	if cfg == 'auto' then
		if GetResourceState('sky_ambulancejob') == 'started' then
			return 'sky_ambulancejob'
		end
		if GetResourceState('ars_ambulancejob') == 'started' then
			return 'ars_ambulancejob'
		end
		if GetResourceState('osp_ambulance') == 'started' then
			return 'osp_ambulance'
		end
		if GetResourceState('p_ambulancejob') == 'started' then
			return 'p_ambulancejob'
		end
		if GetResourceState('esx_ambulancejob') == 'started' then
			return 'esx_ambulancejob'
		end
		if GetResourceState('qb-ambulancejob') == 'started' or GetResourceState('qbx_ambulancejob') == 'started' then
			return 'qb-ambulancejob'
		end
		return 'standalone'
	end
	return cfg
end

local function doStandaloneRevive()
	local ped = PlayerPedId()
	local x, y, z = table.unpack(GetEntityCoords(ped))
	local heading = GetEntityHeading(ped)
	NetworkResurrectLocalPlayer(x, y, z + 1.0, heading, true, true, false)
	ped = PlayerPedId()
	SetEntityHealth(ped, GetEntityMaxHealth(ped))
	SetPedArmour(ped, 0)
	ClearPedBloodDamage(ped)
	if lib and lib.notify then
		lib.notify({ title = _L("notify_revive_title"), description = _L("notify_revive_desc"), type = "success" })
	end
end

RegisterNetEvent('admin:revive', function(playerId)
	local myServerId = GetPlayerServerId(playerId)
	local system = getAmbulanceSystem()

	if system == 'ars_ambulancejob' then
		TriggerServerEvent('ars_ambulancejob:revivePlayer', {targetServerId = myServerId})
	elseif system == 'osp_ambulance' then
		TriggerServerEvent('osp_ambulance:revive', playerId)
	elseif system == 'p_ambulancejob' then
		if Config.Framework == 'esx' then
			TriggerServerEvent('esx_ambulancejob:revive', playerId)
		end
	elseif system == 'esx_ambulancejob' then
		TriggerServerEvent('esx_ambulancejob:revive', playerId)
	else
		doStandaloneRevive()
	end
end)

local function getClothingSystem()
	local cfg = Config.ClothingSystem or 'auto'
	if cfg ~= 'auto' then return cfg end
	if GetResourceState('tgiann-clothing') == 'started' then return 'tgiann-clothing' end
	if GetResourceState('illenium-appearance') == 'started' then return 'illenium-appearance' end
	if GetResourceState('fivem-appearance') == 'started' then return 'fivem-appearance' end
	if GetResourceState('qs-appearance') == 'started' then return 'qs-appearance' end
	if GetResourceState('qb-clothing') == 'started' then return 'qb-clothing' end
	if GetResourceState('esx_skin') == 'started' then return 'esx_skin' end
	if GetResourceState('origen_clothing') == 'started' then return 'origen_clothing' end
	return nil
end

function OpenClothingMenu()
	local system = getClothingSystem()
	if system == 'tgiann-clothing' then
		exports['tgiann-clothing']:openMenu({
			allowedMenus = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true },
			clotheList = nil,
			adminMode = true
		})
	elseif system == 'esx_skin' or system == 'illenium-appearance' or system == 'qs-appearance' or system == 'rcore_clothing' or system == 'qb-clothing' or system == 'origen_clothing' then
		if Config.Framework == 'esx' then
			TriggerEvent('esx_skin:resetFirstSpawn')
			TriggerEvent('esx_skin:playerRegistered')
		elseif Config.Framework == 'qb' then
			TriggerEvent('qb-clothes:client:CreateFirstCharacter')
		end
	elseif system == 'fivem-appearance' then
		exports['fivem-appearance']:startPlayerCustomization()
	end
end


-- Enter here the tuning system you want to use when you select "tune vehicle" in the Kick Actions menu
function TuneVehicle()
	local ped = PlayerPedId()
	if not IsPedInAnyVehicle(ped, false) then
		ShowNotification((_L("notify_tune_vehicle_no_vehicle_title") or "") .. (((_L("notify_tune_vehicle_no_vehicle_title") or "") ~= "" and (_L("notify_tune_vehicle_no_vehicle_desc") or "") ~= "") and " - " or "") .. (_L("notify_tune_vehicle_no_vehicle_desc") or ""), "error")
		return
	end
end

-- Give vehicle keys to the local player. Tries every common key resource in order, falls back to native unlock.
function GiveKeysToPlayer(veh, plate)
	if GetResourceState('jc_vehiclekeys') == 'started' then
		pcall(function() exports['jc_vehiclekeys']:ExcludeVehicle(plate) end)
		return
	end

	if GetResourceState('qbx_vehiclekeys') == 'started' then
		pcall(function() exports['qbx_vehiclekeys']:addKey(plate) end)
		return
	end

	if GetResourceState('qb-vehiclekeys') == 'started' then
		pcall(function() TriggerEvent('vehiclekeys:client:SetOwner', plate) end)
		return
	end

	if GetResourceState('qs-vehiclekeys') == 'started' then
		pcall(function() exports['qs-vehiclekeys']:AddKey(plate) end)
		return
	end

	if GetResourceState('mf-vehiclekeys') == 'started' then
		pcall(function() exports['mf-vehiclekeys']:addKey(plate) end)
		return
	end

	if GetResourceState('wasabi_carlock') == 'started' then
		pcall(function() exports['wasabi_carlock']:GiveKeys(plate) end)
		return
	end

	if GetResourceState('Renewed-Vehiclekeys') == 'started' then
		pcall(function() exports['Renewed-Vehiclekeys']:addKey(plate) end)
		return
	end

	-- Fallback: force unlock the vehicle directly via native
	if veh and veh ~= 0 and DoesEntityExist(veh) then
		SetVehicleDoorsLocked(veh, 1)
	end
end
