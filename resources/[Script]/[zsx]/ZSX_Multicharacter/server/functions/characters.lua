Characters = {}
Characters.ActiveUsers = {}
Characters.Jobs = {}
Characters.JobGrades = {}

if FrameworkSelected == 'ESX' then
    MySQL.ready(function()
        local jobs = MySQL.query.await('SELECT * FROM `jobs`')
        local job_grades = MySQL.query.await('SELECT `job_name`, `grade`, `label` FROM `job_grades`')
        for k,v in ipairs(jobs) do
            Characters.Jobs[v.name] = v.label
        end
        for k,v in ipairs(job_grades) do
            if not Characters.JobGrades[v.job_name] then
                Characters.JobGrades[v.job_name] = {}
            end
            Characters.JobGrades[v.job_name][tonumber(v.grade)] = v.label 
        end
        debugPrint('Done loading JOBS')

        MySQL.query.await('CREATE TABLE IF NOT EXISTS `zsx_multicharacter_slots` (`identifier` varchar(255) NOT NULL, `amount` int(1) NOT NULL, PRIMARY KEY (`identifier`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')
        Wait(1000)
        local length = tonumber(MySQL.query.await("SELECT COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'zsx_multicharacter_slots' AND COLUMN_NAME = 'identifier' AND DATA_TYPE = 'varchar'")[1].CHARACTER_MAXIMUM_LENGTH)
        assert(length == 255, '^5Invalid VARCHAR length for table zsx_multicharacter_slots!\n^2Please refer to the docs: https://zsx-development.gitbook.io/docs/multicharacter/common-issues/database\n\n')
    end)
end

Characters.GetIdentifier = function(src, noCut)
    local identifier = GetPlayerIdentifierByType(src, Config.Characters.IdentifierType)
    if IsQBOXEnabled then
        identifier = GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license')
    end
    assert(identifier ~= nil, '^5Invalid identifier type for config value Config.Characters.IdentifierType!\n^2Please refer to the docs: https://zsx-development.gitbook.io/docs/multicharacter/common-issues/other\n\n')
    local convertedIdentifier
    if FrameworkSelected == 'ESX' then
        if not noCut then
            local colonIndex = string.find(identifier, ":")
            convertedIdentifier = string.sub(identifier, colonIndex + 1)
        elseif noCut then
            convertedIdentifier = identifier
        end
    elseif FrameworkSelected == 'QBCore' then
        convertedIdentifier = identifier
    end
    debugPrint("[^2CHARACTERS.GETIDENTIFIER^7] Return of identifier ["..convertedIdentifier.."]")
    return convertedIdentifier
end

Characters.Get = function(src)
    local identifier = Characters.GetIdentifier(src)
    local PREFIX = Config.Prefix or 'char'
    local query
    if FrameworkSelected == 'ESX' then
        query = "SELECT * FROM `users` WHERE identifier LIKE '%"..identifier.."'"
    elseif FrameworkSelected == 'QBCore' then
        query = "SELECT * FROM `players` WHERE `license` = '"..identifier.."'"
    end
    
    local response = MySQL.query.await(query)
    local characters = {}
    local startTime = GetGameTimer()
    debugPrint("[^2CHARACTERS.GET^7] Gathering NUI Data [/]")
    for k,v in ipairs(response) do
        if FrameworkSelected == 'ESX' then
            local checkMulticharacterMode = string.sub(v.identifier, 1, string.len(PREFIX)) == PREFIX
            assert(checkMulticharacterMode, '^5Your es_extended does not use Config.Multichar. Player identifier: ^3'..v.identifier..'\n^2Please refer to the docs: https://zsx-development.gitbook.io/docs/multicharacter/common-issues/esx\n\n')
        end
        local id = FrameworkSelected == 'ESX' and tonumber(string.sub(v.identifier, #PREFIX+1, string.find(v.identifier, ':')-1)) or FrameworkSelected == 'QBCore' and tonumber(v.cid)
        if FrameworkSelected == 'ESX' then
            local job = v.job
            local grade = v.job_grade
            if GetResourceState('origen_masterjob') == 'started' then
                if not Characters.Jobs[job] then
                    local business = exports["origen_masterjob"]:GetBusiness(job)
                    if business then
                        local gradeObject = business.Functions.GetGrade(grade)
                        if gradeObject then
                            if not Characters.JobGrades[job] then
                                Characters.JobGrades[job] = {}
                            end
                            Characters.Jobs[job] = business.Data.label
                            Characters.JobGrades[job][tonumber(grade)] = gradeObject.label or ''
                            debugPrint('[ORIGEN_MASTERJOB] Applied changes to the Jobs and JobGrades objects. Job: ['..job..']')
                        else
                            debugPrint('[ORIGEN_MASTERJOB] No business grade has been found for: ['..job..']')
                        end
                    else
                        debugPrint('[ORIGEN_MASTERJOB] No business has been found for: ['..job..']')
                    end
                end
            end
           
            assert(v.position ~= nil and v.position ~= '', '^5Failed to get player position. Player identifier: ^3'..v.identifier..'\n^2Please refer to the docs: https://zsx-development.gitbook.io/docs/multicharacter/common-issues/esx\n\n')
            v.job = {
                name = job,
                label = Characters.Jobs[job] or 'Unemployed',
                grade_label = Characters.JobGrades[job] and Characters.JobGrades[job][tonumber(grade)] or ''
            }
            local coords = json.decode(v.position)
            v.position = coords
            v.id = id
            v.skin = Characters.ConvertSkin(v.identifier)
            table.insert(characters, v)
        elseif FrameworkSelected == 'QBCore' then
            local skinResponse = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = '"..v.citizenid.."' AND active = 1")
            local responseCharData = json.decode(v.charinfo)
            local responseJobData = json.decode(v.job)
            local characterData = {
                sex = tonumber(response[1].gender) == 0 and 'm' or 'f',
                skin = Characters.ConvertSkin(v.citizenid),
                model = skinResponse[1] and tonumber(skinResponse[1].model) or false,
                position = json.decode(v.position),
                firstname = responseCharData.firstname,
                lastname = responseCharData.lastname,
                job = {
                    name = responseJobData.name,
                    label = responseJobData.label,
                    grade_label = responseJobData.grade and responseJobData.grade.name or ''
                },
                id = id
            }
            table.insert(characters, characterData)
        end
    end
    if Config.DebugTimers then
        print('[CHARACTERS.GET] Took: ^3'..(GetGameTimer() - startTime)..'ms^7')
    end
    debugPrint("[^2CHARACTERS.GET^7] Gathered NUI Data")
    return characters
end

Characters.GetFirst = function(src)
    local identifier = Characters.GetIdentifier(src)
    local query
    if FrameworkSelected == 'ESX' then
        query = "SELECT * FROM `users` WHERE identifier LIKE '%"..identifier.."'"
    elseif FrameworkSelected == 'QBCore' then
        query = "SELECT * FROM `players` WHERE `license` = '"..identifier.."' ORDER BY `id`"
    end
    local response = MySQL.query.await(query)
    local startTime = GetGameTimer()
    
    debugPrint("[^2CHARACTERS.GETFIRST^7] Gathering first character data [/]")
    if FrameworkSelected == 'ESX' then
        local PREFIX = Config.Prefix
        for k,v in ipairs(response) do
            local checkMulticharacterMode = string.sub(v.identifier, 1, string.len(PREFIX)) == PREFIX
            assert(checkMulticharacterMode, '^5Your es_extended does not use Config.Multichar. Player identifier: ^3'..v.identifier..'\n^2Please refer to the docs: https://zsx-development.gitbook.io/docs/multicharacter/common-issues/esx\n\n')

            local job = v.job
            local grade = v.job_grade
            if GetResourceState('origen_masterjob') == 'started' then
                if not Characters.Jobs[job] then
                    local business = exports["origen_masterjob"]:GetBusiness(job)
                    if business then
                        local gradeObject = business.Functions.GetGrade(grade)
                        if gradeObject then
                            if not Characters.JobGrades[job] then
                                Characters.JobGrades[job] = {}
                            end
                            Characters.Jobs[job] = business.Data.label
                            Characters.JobGrades[job][tonumber(grade)] = gradeObject.label or ''
                            debugPrint('[ORIGEN_MASTERJOB] Applied changes to the Jobs and JobGrades objects. Job: ['..job..']')
                        else
                            debugPrint('[ORIGEN_MASTERJOB] No business grade has been found for: ['..job..']')
                        end
                    else
                        debugPrint('[ORIGEN_MASTERJOB] No business has been found for: ['..job..']')
                    end
                end
            end
            assert(v.position ~= nil, '^5Failed to get player position. Player identifier: ^3'..v.identifier..'\n^2Please refer to the docs: https://zsx-development.gitbook.io/docs/multicharacter/common-issues/esx\n\n')
            v.skin = Characters.ConvertSkin(v.identifier)
            v.job = {
                name = job,
                label = Characters.Jobs[job] or 'Unemployed',
                grade_label = Characters.JobGrades[job] and Characters.JobGrades[job][tonumber(grade)] or ''
            }
            v.id = tonumber(string.sub(v.identifier, #PREFIX+1, string.find(v.identifier, ':')-1))
        end
        if Config.DebugTimers then
            print('[CHARACTERS.FIRST] Took: ^3'..(GetGameTimer() - startTime)..'ms^7')
        end
        
        debugPrint("[^2CHARACTERS.GETFIRST^7] Gathered first character data")
        return response[1]
    elseif FrameworkSelected == 'QBCore' then
        local skinResponse = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = '"..response[1].citizenid.."' AND active = 1")
        local responseCharData = json.decode(response[1].charinfo)
        local responseJobData = json.decode(response[1].job)
        local characterData = {
            sex = tonumber(response[1].gender) == 0 and 'm' or 'f',
            skin = Characters.ConvertSkin(response[1].citizenid),
            model = skinResponse[1] and tonumber(skinResponse[1].model) or false,
            position = json.decode(response[1].position),
            firstname = responseCharData.firstname,
            lastname = responseCharData.lastname,
            job = {
                name = responseJobData.name,
                label = responseJobData.label,
                grade_label = responseJobData.grade and responseJobData.grade.name or ''
            },
            id = response[1].cid
        }
        
        if Config.DebugTimers then
            print('[CHARACTERS.FIRST] Took: ^3'..(GetGameTimer() - startTime)..'ms^7')
        end
        debugPrint("[^2CHARACTERS.GETFIRST^7] Gathered first character data")
        return characterData
    end
end

Characters.GetNum = function(src, num)
    local identifier = Characters.GetIdentifier(src)
    local query
    if FrameworkSelected == 'ESX' then
        query = "SELECT * FROM `users` WHERE identifier LIKE '%"..Config.Prefix..''..num..':'..identifier.."'"
    elseif FrameworkSelected == 'QBCore' then
        query = "SELECT * FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = "..num..""
    end
    local response = MySQL.query.await(query)
    local PREFIX = Config.Prefix
    if FrameworkSelected == 'ESX' then
        for k,v in ipairs(response) do
            local checkMulticharacterMode = string.sub(v.identifier, 1, string.len(PREFIX)) == PREFIX
            assert(checkMulticharacterMode, '^5Your es_extended does not use Config.Multichar. Player identifier: ^3'..v.identifier..'\n^2Please refer to the docs: https://zsx-development.gitbook.io/docs/multicharacter/common-issues/esx\n\n')
            local job = v.job
            local grade = v.job_grade
            if GetResourceState('origen_masterjob') == 'started' then
                if not Characters.Jobs[job] then
                    local business = exports["origen_masterjob"]:GetBusiness(job)
                    if business then
                        local gradeObject = business.Functions.GetGrade(grade)
                        if gradeObject then
                            if not Characters.JobGrades[job] then
                                Characters.JobGrades[job] = {}
                            end
                            Characters.Jobs[job] = business.Data.label
                            Characters.JobGrades[job][tonumber(grade)] = gradeObject.label or ''
                            debugPrint('[ORIGEN_MASTERJOB] Applied changes to the Jobs and JobGrades objects. Job: ['..job..']')
                        else
                            debugPrint('[ORIGEN_MASTERJOB] No business grade has been found for: ['..job..']')
                        end
                    else
                        debugPrint('[ORIGEN_MASTERJOB] No business has been found for: ['..job..']')
                    end
                end
            end
            assert(v.position ~= nil, '^5Failed to get player position. Player identifier: ^3'..v.identifier..'\n^2Please refer to the docs: https://zsx-development.gitbook.io/docs/multicharacter/common-issues/esx\n\n')
            v.skin = Characters.ConvertSkin(v.identifier)
            v.job = {
                name = job,
                label = Characters.Jobs[job] or 'Unemployed',
                grade_label = Characters.JobGrades[job] and Characters.JobGrades[job][tonumber(grade)] or ''
            }
        end
        
        return {character = response[1], id = num}
    elseif FrameworkSelected == 'QBCore' then
        local skinResponse = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = '"..response[1].citizenid.."' AND active = 1")
        local responseCharData = json.decode(response[1].charinfo)
        local responseJobData = json.decode(response[1].job)
        local characterData = {
            sex = tonumber(response[1].gender) == 0 and 'm' or 'f',
            skin = Characters.ConvertSkin(response[1].citizenid),
            model = skinResponse[1] and tonumber(skinResponse[1].model) or false,
            position = json.decode(response[1].position),
            firstname = responseCharData.firstname,
            lastname = responseCharData.lastname,
            job = {
                name = responseJobData.name,
                label = responseJobData.label,
                grade_label = responseJobData.grade and responseJobData.grade.name or ''
            }
        }
        return {character = characterData, id = num}
    end
    
end

Characters.DoesUserHaveCharacters = function(src)
    local identifier = Characters.GetIdentifier(src)
    local query
    local startTime = GetGameTimer()
    if FrameworkSelected == 'ESX' then
        query = "SELECT * FROM `users` WHERE identifier LIKE '%"..identifier.."'"
    elseif FrameworkSelected == 'QBCore' then
        query = "SELECT * FROM `players` WHERE `license` = '"..identifier.."'"
    end
    debugPrint("[^2CHARACTERS.DOESUSERHAVECHARACTERS^7] Checking if player has any characters [/]")
    local response = MySQL.query.await(query)
    if Config.DebugTimers then
        print('[CHARACTERS.DoesUserHaveCharacters] Took: ^3'..(GetGameTimer() - startTime)..'ms^7')
    end
    
    debugPrint("[^2CHARACTERS.DOESUSERHAVECHARACTERS^7] Player "..(#response > 0 and "does" or "does not").." have character.")
    return #response > 0
end

Characters.GetSlots = function(src)
	local identifier = Characters.GetIdentifier(src, true)
	local override = Config.CustomSlots[identifier]

	local startTime = GetGameTimer()

	-- This returns the number directly (not a table)
	local amount =
		MySQL.prepare.await("SELECT `amount` FROM `zsx_multicharacter_slots` WHERE `identifier` = ?", { identifier })

	if override then
		-- Override present in config
		if not amount then
			MySQL.insert.await(
				"INSERT INTO `zsx_multicharacter_slots` (`identifier`, `amount`) VALUES (?, ?)",
				{ identifier, override }
			)
		elseif amount ~= override then
			MySQL.update.await(
				"UPDATE `zsx_multicharacter_slots` SET `amount` = ? WHERE `identifier` = ?",
				{ override, identifier }
			)
		end
		amount = override
	elseif not amount then
		-- No row found, fallback to default
		amount = Config.Characters.Free
		MySQL.insert.await(
			"INSERT INTO `zsx_multicharacter_slots` (`identifier`, `amount`) VALUES (?, ?)",
			{ identifier, amount }
		)
	end

	if Config.DebugTimers then
		print(("[CHARACTERS.GetSlots] Took: ^3%dms^7"):format(GetGameTimer() - startTime))
	end

	return amount
end

Characters.GetAmount = function(src)
    local identifier = Characters.GetIdentifier(src)
    local query
    local startTime = GetGameTimer()
    if FrameworkSelected == 'ESX' then
        query = "SELECT COUNT(*) FROM `users` WHERE identifier LIKE '%"..identifier.."'"
    elseif FrameworkSelected == 'QBCore' then
        query = "SELECT COUNT(*) FROM `players` WHERE `license` = '"..identifier.."'"
    end
    if Config.DebugTimers then
        print('[CHARACTERS.GetAmount] Took: ^3'..(GetGameTimer() - startTime)..'ms^7')
    end
    debugPrint("[^2CHARACTERS.GETAMOUNT^7] Checking players slots [/]")
    local response = MySQL.query.await(query)
    debugPrint("[^2CHARACTERS.GETAMOUNT^7] Player slots checked!")
    return tonumber(response[1]['COUNT(*)'])
end

Characters.ConvertProperties = function(identifier, charId)
    local properties = {}
    local startTime = GetGameTimer()
    debugPrint("[^2CHARACTERS.CONVERTPROPERTIES^7] Checking player properties [/]")
    if GetResourceState('qb-apartments') == 'started' then
        --only for QBCore
        local citizenResponse = MySQL.query.await("SELECT `citizenid` FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = ?", {charId})
        local query = "SELECT * FROM `apartments` WHERE `citizenid` = ?"
        local response = MySQL.query.await(query, {citizenResponse[1].citizenid})
        for k,v in ipairs(response) do
            if Apartments.Locations[v.type] then
                properties[v.name] = {
                    name = v.name,
                    type = "property",
                    label = v.label,
                    coords = Apartments.Locations[v.type].coords.enter,
                }
            end
        end
    end
    if GetResourceState('qb-houses') == 'started' then
        --only for QBCore
        local citizenResponse = MySQL.query.await("SELECT `citizenid` FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = ?", {charId})
        local query = "SELECT * FROM `player_houses` WHERE `citizenid` = ?"
        local response = MySQL.query.await(query, {citizenResponse[1].citizenid})
        
        for k,v in ipairs(response) do
            if Characters.QBHouses[v.house] then
                properties[v.house] = {
                    name = v.house,
                    type = "property",
                    label = v.label,
                    coords = vector3(Characters.QBHouses[v.house].coords.enter.x, Characters.QBHouses[v.house].coords.enter.y, Characters.QBHouses[v.house].coords.enter.z),
                }
            end
        end
    end
    if GetResourceState('qs-housing') == 'started' then
        local response 
        if FrameworkSelected == 'QBCore' then
            local citizenResponse = MySQL.query.await("SELECT `citizenid` FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = ?", {charId})
            response = MySQL.query.await("SELECT * FROM `player_houses` WHERE `citizenid` = ?", {citizenResponse[1].citizenid})
        elseif FrameworkSelected == 'ESX' then
            response = MySQL.query.await("SELECT * FROM `player_houses` WHERE `citizenid` = ?", {Config.Prefix..''..charId..':'..identifier})
        end
        for k,v in ipairs(response) do
            if Characters.QSHouses[v.house] then
                properties[v.house] = {
                    name = v.house,
                    type = "property",
                    label = Characters.QSHouses[v.house].label,
                    coords = vector3(Characters.QSHouses[v.house].coords.enter.x, Characters.QSHouses[v.house].coords.enter.y, Characters.QSHouses[v.house].coords.enter.z),
                }
            end
        end
    end
    if GetResourceState('0r-apartments') == 'started' then
        local response
        if FrameworkSelected == 'QBCore' then
            local citizenResponse = MySQL.query.await("SELECT `citizenid` FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = ?", {charId})
            response = MySQL.query.await("SELECT * FROM `0resmon_apartment_rooms` WHERE `citizenid` = ?", {citizenResponse[1].citizenid})
        elseif FrameworkSelected == 'ESX' then
            response = MySQL.query.await("SELECT * FROM `0resmon_apartment_rooms` WHERE `citizenid` = ?", {Config.Prefix..''..charId..':'..identifier})
        end
        if not response then debugPrint("[CONVERT PROPERTIES] No appartments are owned.") return {} end
        for k,v in ipairs(response) do
            if Apartments.Locations[v.apartment_id] then
                local apartmentData = Apartments.Locations[v.apartment_id]
                properties[tostring(v.id)] = {
                    name = v.id,
                    type = "property",
                    label = apartmentData.label,
                    coords = vector3(apartmentData.coords.enter.x, apartmentData.coords.enter.y, apartmentData.coords.enter.z),
                }
            end
        end
    end
    if GetResourceState('ps-housing') == 'started' then
        --only for QBCore
        local citizenResponse = MySQL.query.await("SELECT `citizenid` FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = ?", {charId})
        local query = "SELECT * FROM `properties` WHERE `owner_citizenid` = ?"
        response = MySQL.query.await(query, {citizenResponse[1].citizenid})
        for k,v in ipairs(response) do
            local coords = json.decode(v.door_data)
            if coords and coords.x and coords.y and coords.z then
                properties['house_'..v.property_id] = {
                    name = 'house_'..v.property_id,
                    type = "property",
                    label = v.apartment,
                    coords = vector3(coords.x, coords.y, coords.z),
                }
            end
        end
    end
    if GetResourceState('bcs_housing') == 'started' then
        local response
        local identifier_to_use

        if FrameworkSelected == 'ESX' then
            identifier_to_use = Config.Prefix..''..charId..':'..identifier
            response = exports['bcs_housing']:GetOwnedHomes(identifier_to_use)
        elseif FrameworkSelected == 'QBCore' then
            local citizenResponse = MySQL.query.await("SELECT `citizenid` FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = ?", {charId})
            if citizenResponse and citizenResponse[1] then
                identifier_to_use = citizenResponse[1].citizenid
                response = exports['bcs_housing']:GetOwnedHomes(identifier_to_use)
            end
        end

        local ownedResponse = MySQL.query.await([[
            SELECT h.*, h.data as houseData, ho.owner 
            FROM house h 
            INNER JOIN house_owned ho ON h.identifier = ho.identifier 
            WHERE ho.owner = ?
        ]], {identifier_to_use})

        if ownedResponse then
            for k,v in ipairs(ownedResponse) do
                if v.complex == 'Flat' then
                    local houseData = json.decode(v.houseData)
                    if houseData and houseData.flat and houseData.flat.coords then
                        properties[v.identifier] = {
                            name = v.identifier,
                            type = "property",
                            label = v.name,
                            coords = vector3(houseData.flat.coords.x, houseData.flat.coords.y, houseData.flat.coords.z),
                        }
                    end
                elseif v.entry and v.entry ~= 'null' then
                    local entryCoords = type(v.entry) == 'string' and json.decode(v.entry) or v.entry
                    if entryCoords then
                        properties[v.identifier] = {
                            name = v.identifier,
                            type = "property",
                            label = v.name,
                            coords = vector3(entryCoords.x, entryCoords.y, entryCoords.z),
                        }
                    end
                end
            end
        end

        local apartmentResponse = MySQL.query.await([[
            SELECT h.*, ha.apartment 
            FROM house h 
            INNER JOIN house_apartment ha ON h.identifier = ha.identifier 
            WHERE ha.owner = ? AND h.complex = 'Apartment'
        ]], {identifier_to_use})

        if apartmentResponse then
            for k,v in ipairs(apartmentResponse) do
                if v.entry and v.entry ~= 'null' then
                    local entryCoords = type(v.entry) == 'string' and json.decode(v.entry) or v.entry
                    if entryCoords then
                        properties[v.identifier..'_'..v.apartment] = {
                            name = v.identifier..'_'..v.apartment,
                            type = "property",
                            label = v.name..' - Unit '..v.apartment
                        }
                    end
                end
            end
        end
    end
    
    if Config.DebugTimers then
        print('[CHARACTERS.ConvertProperties] Took: ^3'..(GetGameTimer() - startTime)..'ms^7')
    end
    
    debugPrint("[^2CHARACTERS.CONVERTPROPERTIES^7] Player properties checked.")
    return properties
end

local function mergeTables(...)
    local mergedTable = {}
    for _, tbl in ipairs({...}) do
        if type(tbl) == "table" then
            for index, value in pairs(tbl) do
                mergedTable[index] = value
            end
        end
    end
    return mergedTable
end

Characters.ConvertSkin = function(convertedIdentifier)
    local skin = nil
    local startTime = GetGameTimer()
    
    debugPrint("[^2CHARACTERS.CONVERTSKIN^7] Checking player skin [/]")
    local appearanceResource = Config.ForceAppereance ~= false and Config.ForceAppereance or (GetResourceState('skinchanger') == 'started' and 'skinchanger' or GetResourceState('skinchanger') == 'fivem-appearance' and 'fivem-appearance' or GetResourceState('illenium-appearance') == 'started' and 'illenium-appearance' or GetResourceState('qb-clothing') == 'started' and 'qb-clothing' or GetResourceState('crm-appearance') == 'started' and 'crm-appearance' or GetResourceState('bl_appearance') == 'started' and 'bl_appearance' or GetResourceState('tgiann-clothing') == 'started' and 'tgiann-clothing' or GetResourceState('rcore_clothing') == 'started' and 'rcore_clothing')
    if appearanceResource == 'skinchanger' then
        if FrameworkSelected == 'ESX' then
            local result = MySQL.query.await("SELECT `skin` FROM `users` WHERE `identifier` = ?", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
        elseif FrameworkSelected == 'QBCore' then
            local result = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = ? AND active = 1", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
        end
    elseif appearanceResource == 'fivem-appearance' then
        if FrameworkSelected == 'ESX' then
            local result = MySQL.query.await("SELECT `skin` FROM `users` WHERE `identifier` = ?", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
        elseif FrameworkSelected == 'QBCore' then
            local result = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = ? AND active = 1", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
        end
    elseif appearanceResource == 'illenium-appearance' then
        if FrameworkSelected == 'ESX' then
            local result = MySQL.query.await("SELECT `skin` FROM `users` WHERE `identifier` = ?", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
        elseif FrameworkSelected == 'QBCore' then
            local result = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = ? AND active = 1", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end 
        end
    elseif appearanceResource == 'qb-clothing' then
        if FrameworkSelected == 'ESX' then
            debugPrint('Tried to access qb-clothing in ESX. Are you sure you added proper resource to your framework?')
        elseif FrameworkSelected == 'QBCore' then
            local result = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = ? AND active = 1", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
        end
    elseif appearanceResource == 'crm-appearance' then
        if FrameworkSelected == 'ESX' then
            local result = MySQL.query.await("SELECT `skin` FROM `users` WHERE `identifier` = ?", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
        elseif FrameworkSelected == 'QBCore' then
            local result = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = ? AND active = 1", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin = json.decode(result[1].skin)
            end
        end
    elseif appearanceResource == 'bl_appearance' then
        local result = MySQL.query.await("SELECT * FROM `appearance` WHERE `id` = ?", {convertedIdentifier})
        if result and result[1] and result[1].skin then
            local decodedSkin = json.decode(result[1].skin)
            skin = mergeTables(json.decode(result[1].skin), json.decode(result[1].clothes), json.decode(result[1].tattoos))
        end
    elseif appearanceResource == 'tgiann-clothing' then
        local result = MySQL.query.await("SELECT * FROM tgiann_skin WHERE citizenid = ?", { convertedIdentifier })
        if result and result[1] and result[1].skin then
            skin = {
                skin = json.decode(result[1].skin),
                model = tonumber(result[1].model)
            }
        end
    elseif appearanceResource == 'rcore_clothing' then
        local rcoreSkin = exports["rcore_clothing"]:getSkinByIdentifier(convertedIdentifier)
        skin = {
            skin = rcoreSkin.skin,
            model =  rcoreSkin.ped_model,
        }

    elseif appearanceResource == 'dx_clothing' then
        skin = {
            skin = false,
            tattoos = false
        }
        if FrameworkSelected == 'ESX' then
            local result = MySQL.query.await("SELECT `skin` FROM `users` WHERE `identifier` = ?", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin.skin = json.decode(result[1].skin)
            end
        elseif FrameworkSelected == 'QBCore' then
            local result = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = ? AND active = 1", {convertedIdentifier})
            if result and result[1] and result[1].skin then
                skin.skin = json.decode(result[1].skin)
            end
        end
        skin.tattoos = exports['dx_clothing']:getTattoosByIdentifier(convertedIdentifier) 
    elseif appearanceResource == 'karma_clothing' then
        local result = MySQL.query.await("SELECT * FROM `playerskins` WHERE `citizenid` = ? AND active = 1", {convertedIdentifier})
        if result and result[1] and result[1].skin then
            skin = {
                skin = {
                    newSkin = json.decode(result[1].skin),
                    newHead = {
                        headblend = {},
                        features = {},
                        overlays = {},
                        eyeColor = 0,
                        fade = 0,
                        tattoos = {}
                    }
                }
            }
            local headDataQuery = MySQL.single.await('SELECT citizenid, model, head_blend, head_features, head_overlays, fade, tattoos, eye_color FROM karma_head_clothing WHERE citizenid = ? LIMIT 1', { convertedIdentifier })
            if headDataQuery then
                skin.skin.newHead = {
                    headblend = json.decode(headDataQuery.head_blend),
                    features = json.decode(headDataQuery.head_features),
                    overlays = json.decode(headDataQuery.head_overlays),
                    eyeColor = headDataQuery.eye_color,
                    fade = headDataQuery.fade,
                    tattoos = json.decode(headDataQuery.tattoos)
                }
            end
        end
    end

    if GetResourceState('rcore_tattoos') == 'started' then
        local rcoreTattooPromise = promise:new()
        debugPrint('[^2CHARACTERS.CONVERTSKIN^7] Awaiting rcore tattoo [/]')
        TriggerEvent('rcore_tattoos:getPlayerTattoosByIdentifier', convertedIdentifier, function(tattoos)
            if not skin then 
                skin = {} 
            end
            skin.tattoo = tattoos
            rcoreTattooPromise:resolve()
            debugPrint('[^2CHARACTERS.CONVERTSKIN^7] Rcore tattoo loaded!')
        end)

        Citizen.CreateThread(function()
            Wait(100)
            local startTime = GetGameTimer()
            local endTime = startTime + 3000
            local currentTime = startTime
            while rcoreTattooPromise and rcoreTattooPromise.state == 0 do
                currentTime = GetGameTimer()
                if currentTime >= endTime then
                    rcoreTattooPromise:resolve()
                    debugPrint('[RCORE_TATTOO] Force resolved promise.')
                    break
                end
                Wait(100)
            end
        end)
       
        Citizen.Await(rcoreTattooPromise)
    end


    if Config.DebugTimers then
        print('[CHARACTERS.CONVERTSKIN] Took: ^3'..(GetGameTimer() - startTime)..'ms^7')
    end
    
    debugPrint("[^2CHARACTERS.CONVERTSKIN^7] Checked player skin.")
    return skin
end

Characters.RemoveUserOtherData = function(convertedIdentifier)
    debugPrint('[CHARACTERS.RemoveUserOtherData] Attempting to remove table data for identifier [^2'..convertedIdentifier..'^7] [/]')
    local count = 0
    for k,v in ipairs(Config.DB_TablesToRemove) do
        local query = ('DELETE FROM `%s` WHERE `%s` = "%s"'):format(v.table, v.identifierColumn, convertedIdentifier)
        MySQL.query.await(query)
        count = count + 1
    end
    debugPrint('[CHARACTERS.RemoveUserOtherData] Wiped data of [^2'..convertedIdentifier..'^7] from '..count..' tables')
end

Characters.Remove = function(src, charid)
    local identifier = Characters.GetIdentifier(src)
    local query
    local convertedIdentifier
    local citizenResponse
    if FrameworkSelected == 'ESX' then
        convertedIdentifier = Config.Prefix..""..charid..":"..identifier
    else
        citizenResponse = MySQL.query.await("SELECT `citizenid` FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = ?", {charid})
        convertedIdentifier = citizenResponse[1].citizenid
    end

    Characters.RemoveUserOtherData(convertedIdentifier)
    if FrameworkSelected == 'ESX' then
        query = "DELETE FROM `users` WHERE `identifier` = '"..convertedIdentifier.."'"
    elseif FrameworkSelected == 'QBCore' then
        query = "DELETE FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = "..charid..""
    end
    MySQL.query.await(query)
    return FrameworkSelected == 'QBCore' and citizenResponse[1].citizenid or FrameworkSelected == 'ESX' and convertedIdentifier
end

Characters.GetProperties = function(src, charId)
    if not charId then charId = 1 end
    local identifier = Characters.GetIdentifier(src)
    local properties = Characters.ConvertProperties(identifier, charId)

    return properties
end

Framework.RegisterServerCallback("ZSX_Multicharacter:CheckNameAvailability", function(source, cb, firstName, lastName)
	debugPrint("=== NAME CHECK DEBUG ===")
	debugPrint("Config.IdentityDuplicateCheck:", Config.IdentityDuplicateCheck)
	debugPrint("FrameworkSelected:", FrameworkSelected)
	debugPrint("FirstName:", firstName)
	debugPrint("LastName:", lastName)

	if not Config.IdentityDuplicateCheck then
		debugPrint("Name checking is disabled in config")
		cb(true)
		return
	end

	local query
	local params = { firstName, lastName }

	if FrameworkSelected == "ESX" then
		query = "SELECT COUNT(*) as count FROM `users` WHERE `firstname` = ? AND `lastname` = ?"
		debugPrint("Using ESX query:", query)
	elseif FrameworkSelected == "QBCore" then
		query =
			"SELECT COUNT(*) as count FROM `players` WHERE JSON_EXTRACT(`charinfo`, '$.firstname') = ? AND JSON_EXTRACT(`charinfo`, '$.lastname') = ?"
		debugPrint("Using QBCore query:", query)
	else
		debugPrint("Unknown framework!")
		cb(true)
		return
	end

	debugPrint("Query params:", json.encode(params))

	local result = MySQL.query.await(query, params)
	debugPrint("MySQL result:", json.encode(result))

	local count = result[1] and result[1].count or 0
	debugPrint("Found count:", count)

	local isAvailable = count == 0
	debugPrint("Is name available:", isAvailable)
	debugPrint("=== END DEBUG ===")

	cb(isAvailable)
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:IsPlayerActive', function(source, cb)
    debugPrint("[^2CHARACTERS.ISPLAYERACTIVE^7] Checking if player is active [/]")
    local xPlayer = FrameworkSelected == 'ESX' and ESX.GetPlayerFromId(source) or FrameworkSelected == 'QBCore' and QBCore.Functions.GetPlayer(source) or false
    
    debugPrint("[^2CHARACTERS.ISPLAYERACTIVE^7] Checked if player is active.")
    cb(xPlayer)
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Get:Characters', function(source, cb)
    cb(Characters.Get(source))
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Get:FirstChar', function(source, cb)
    cb(Characters.GetFirst(source))
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Get:NumChar', function(source, cb, num)
    cb(Characters.GetNum(source, num))
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Get:PlayerSlots', function(source, cb)
    cb(Characters.GetSlots(source))
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Get:CharactersExists', function(source, cb)
    cb(Characters.DoesUserHaveCharacters(source))
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Get:Properties', function(source, cb, id)
    cb(Characters.GetProperties(source, id))
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Event:SelectedCharacter', function(source, cb, id)
    local isTimedOut = Player(source).state['ZSX_isPlayerTimedOut']
    if isTimedOut then
        if isTimedOut > GetGameTimer() then
            return debugPrint('[TIME OUT] Awaiting player selecting because the time out is active.')
        end
    else
        Player(source).state:set('ZSX_isPlayerTimedOut', GetGameTimer() + 2000, true)
    end

    if FrameworkSelected == 'ESX' then
        TriggerEvent('esx:onPlayerJoined', source, Config.Prefix..''..id)
        while ESX.GetPlayerFromId(source) == nil do
            Wait(0)
        end
        Characters.ActiveUsers[tostring(source)] = {
            id = id,
            identifier = Characters.GetIdentifier(source),
        }
        cb('DONE')
    elseif FrameworkSelected == 'QBCore' then
        local identifier = Characters.GetIdentifier(source)
        local response = MySQL.query.await("SELECT `citizenid` FROM `players` WHERE `license` = '"..identifier.."' AND `cid` = "..id)
        if QBCore.Player.Login(source, response[1].citizenid) then
            repeat
                Wait(0)
            until QBCore.Functions.GetPlayerByCitizenId(response[1].citizenid)
            Characters.ActiveUsers[tostring(source)] = {
                id = id,
                identifier = Characters.GetIdentifier(source),
            }
            TriggerClientEvent('ZSX_Multicharacter:CreateQBInstance', source)
            cb('DONE')
            print('^2[qb-core]^7 '..GetPlayerName(source)..' has succesfully loaded!')
            QBCore.Commands.Refresh(source)
            TriggerEvent("qb-log:server:CreateLog", "joinleave", "Loaded", "green", "**".. GetPlayerName(source) .. "** ("..(QBCore.Functions.GetIdentifier(source, 'discord') or 'undefined') .." |  ||"  ..(QBCore.Functions.GetIdentifier(source, 'ip') or 'undefined') ..  "|| | " ..(QBCore.Functions.GetIdentifier(source, 'license') or 'undefined') .." | "..source..") loaded..")
        end
    end
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Event:RemoveCharacter', function(source, cb, id)
    local convertedIdentifier = Characters.Remove(source, id)
    cb(Characters.DoesUserHaveCharacters(source), convertedIdentifier)
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Event:Logout', function(source, cb)
    if FrameworkSelected == 'ESX' then
        debugPrint('[LOGOUT] Awaiting Player to be unloaded [/]')
        TriggerEvent('esx:playerLogout', source, function()
            cb()
            debugPrint('[LOGOUT] Player unloaded.')
        end)
    elseif FrameworkSelected == 'QBCore' then
        QBCore.Player.Logout(source)
        cb()
    end
end)


RegisterNetEvent('ZSX_Multicharacter:Save:Appereance')
AddEventHandler('ZSX_Multicharacter:Save:Appereance', function(skin)
    if not skin then return debugPrint('There was an error saving player skin') end
    if FrameworkSelected == 'ESX' then
		local xPlayer = ESX.GetPlayerFromId(source)
		MySQL.query.await('UPDATE users SET skin = ? WHERE identifier = ?', {json.encode(skin), xPlayer.identifier})
	elseif FrameworkSelected == 'QBCore' then
		local Player = QBCore.Functions.GetPlayer(source)
        MySQL.query('DELETE FROM playerskins WHERE citizenid = ?', { Player.PlayerData.citizenid }, function()
            MySQL.insert('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, ?)', {Player.PlayerData.citizenid, skin.model, json.encode(skin), 1})
        end)
	end
end)

Framework.RegisterServerCallback('ZSX_Multicharacter:Create:Player', function(source, cb, data)
    local isTimedOut = Player(source).state['ZSX_isPlayerTimedOut']
    if isTimedOut then
        if isTimedOut > GetGameTimer() then
            return debugPrint('[TIME OUT] Awaiting player character creation because the time out is active.')
        end
    else
        Player(source).state:set('ZSX_isPlayerTimedOut', GetGameTimer() + 2000, true)
    end
    local src = source
    local playerSlots = Characters.GetSlots(src)
    local playerCharacters = Characters.GetAmount(src)
    if playerCharacters + 1 > playerSlots then return debugPrint('User: '..GetPlayerName(src)..' ['..src..']'..' attempt to create a character with max amount of slots.') end
    local firstName = data.firstname:sub(1,1):upper() .. data.firstname:sub(2)
    local lastName = data.lastname:sub(1,1):upper() .. data.lastname:sub(2)
    if FrameworkSelected == 'ESX' then
        TriggerEvent('esx:onPlayerJoined', source, Config.Prefix..''..(data.charIndex or playerCharacters + 1), {
            firstname = data.firstname,
            lastname = data.lastname,
            sex = data.gender == 'male' and 'm' or 'f',
            height = tonumber(data.height),
            dateofbirth = data.date,
            nationality = data.nationality
        })

        while ESX.GetPlayerFromId(source) == nil do
            Wait(100)
        end
        Wait(1000)
        Characters.ActiveUsers[tostring(source)] = {
            id = data.charIndex or (playerCharacters + 1),
            identifier = Characters.GetIdentifier(source),
        }
        Addon.StarterItems(source)

        cb({id = data.charIndex or playerCharacters + 1})
    elseif FrameworkSelected == 'QBCore' then
        local identifier = Characters.GetIdentifier(source)
        if QBCore.Player.Login(source, false, {
            cid = data.charIndex or playerCharacters + 1,
            charinfo = {
                firstname = data.firstname,
                lastname = data.lastname,
                birthdate = data.date,
                gender = data.gender == 'male' and 0 or 1,
                height = tonumber(data.height),
                nationality = data.nationality
            }
        }) then

            repeat
                Wait(10)
            until QBCore.Functions.GetPlayer(source)

            Addon.StarterItems(source)

            TriggerClientEvent('ZSX_Multicharacter:CreateQBInstance', source, {
                firstname = data.firstname,
                lastname = data.lastname,
                birthdate = data.date,
                gender = data.gender == 'male' and 0 or 1,
                height = tonumber(data.height),
                nationality = data.nationality,
                cid = data.charIndex or playerCharacters + 1
            })
            Characters.ActiveUsers[tostring(source)] = {
                id = data.charIndex or (playerCharacters + 1),
                identifier = Characters.GetIdentifier(source),
            }
            cb({id = data.charIndex or playerCharacters + 1})
            print('^2[qb-core]^7 '..GetPlayerName(source)..' has succesfully loaded!')
            QBCore.Commands.Refresh(source)
            TriggerEvent("qb-log:server:CreateLog", "joinleave", "Loaded", "green", "**".. GetPlayerName(source) .. "** ("..(QBCore.Functions.GetIdentifier(source, 'discord') or 'undefined') .." |  ||"  ..(QBCore.Functions.GetIdentifier(source, 'ip') or 'undefined') ..  "|| | " ..(QBCore.Functions.GetIdentifier(source, 'license') or 'undefined') .." | "..source..") loaded..")
        end
    end
end)

if FrameworkSelected == 'QBCore' then
    MySQL.ready(function()
        MySQL.query.await('CREATE TABLE IF NOT EXISTS `zsx_multicharacter_slots` (`identifier` varchar(255) NOT NULL, `amount` int(1) NOT NULL, PRIMARY KEY (`identifier`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8;')
        if GetResourceState('qb-houses') == 'started' then
            local housesList = MySQL.query.await('SELECT * FROM houselocations', {})
            Characters.QBHouses = {}
            for k,v in ipairs(housesList) do
                if v.owned == 1 then
                    Characters.QBHouses[v.name] = {
                        label = v.label,
                        coords = json.decode(v.coords),
                    }
                end
            end
        end
    end)
    function loadHouseData(src) -- function to load data to other resources for QBCore
        local HouseGarages = {}
        local Houses = {}
        local result = MySQL.query.await('SELECT * FROM houselocations', {})
        if result[1] ~= nil then
            for _, v in pairs(result) do
                local owned = false
                if tonumber(v.owned) == 1 then
                    owned = true
                end
                local house_coords = json.decode(v.coords)
                local garage = v.garage ~= nil and json.decode(v.garage) or {}
                Houses[v.name] = {
                    name = v.name,
                    coords = house_coords.enter,
                    owned = owned,
                    price = v.price,
                    locked = true,
                    type = 'property',
                    adress = v.label,
                    tier = v.tier,
                    garage = garage,
                    decorations = {},
                }
                HouseGarages[v.name] = {
                    label = v.label,
                    takeVehicle = garage,
                }
            end
        end
        TriggerClientEvent("qb-garages:client:houseGarageConfig", src, HouseGarages)
        TriggerClientEvent("qb-houses:client:setHouseConfig", src, Houses)
        return Houses
    end
end

if FrameworkSelected == 'ESX' then
    RegisterCommand('multicharacter_esx_remove_users', function(source, raw, args)
        if source == 0 then
            local result = MySQL.query.await("DELETE FROM users WHERE identifier NOT REGEXP '^"..Config.Prefix.."[0-9]+:'")
            debugPrint(('[ESX USERS REMOVAL] Deleted %s rows from the users table'):format(result.affectedRows))
        end
    end)
end
 
function Logout(source)
    TriggerClientEvent('ZSX_Multicharacter:LogoutPlayer', source)
end

exports('Logout', Logout)


MySQL.ready(function()
    Wait(1000)
    if GetResourceState('qs-housing') == 'started' then
        local housesList = MySQL.query.await('SELECT * FROM houselocations', {})
        Characters.QSHouses = {}
        for k,v in ipairs(housesList) do
            Characters.QSHouses[v.name] = {
                label = v.label,
                coords = json.decode(v.coords),
            }
        end
    end
end)