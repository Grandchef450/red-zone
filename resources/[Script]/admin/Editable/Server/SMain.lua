local garageResources = { "vms_garagesv2", "jg-advancedgarages", "qs-advancedgarages", "okokGarage", "op-garages", "origen_garages", "qb-garages", "esx_garage" }
local housingResources = { "vms_housing", "qs-housing", "bcs_housing", "qb-houses", "esx_property", "origen_housing", "brutal_housing", "rtx_housing" }
local gangResources = { "jc_organizaciones", "op-crime", "av_gangs" }

local function getResolvedGarageSystem()
    local cfg = Config.GarageSystem or "auto"
    if cfg ~= "auto" then return cfg end
    for _, res in ipairs(garageResources) do
        if GetResourceState(res) == "started" then
            return res
        end
    end
    return nil
end

local function getResolvedGangSystem()
    local cfg = Config.GangSystem or "auto"
    if cfg ~= "auto" then return cfg end
    for _, res in ipairs(gangResources) do
        if GetResourceState(res) == "started" then
            return res
        end
    end
    return nil
end

local function getResolvedHousingSystem()
    local cfg = Config.HousingSystem or "auto"
    if cfg ~= "auto" then return cfg end
    for _, res in ipairs(housingResources) do
        if GetResourceState(res) == "started" then
            return res
        end
    end
    return nil
end

function GetPlayerVehiclesForDbOwner(id)
    local list = {}
    if not id or type(id) ~= "string" then return list end
    id = id:gsub("^%s+", ""):gsub("%s+$", "")
    if id == "" then return list end
    local garageSystem = getResolvedGarageSystem()
    local useVmsGarages = (garageSystem == "vms_garagesv2")
    local useJgGarage = (garageSystem == "jg-advancedgarages")
    local useQsGarage = (garageSystem == "qs-advancedgarages")
    local useOkokGarage = (garageSystem == "okokGarage")
    local useOrigenGarages = (garageSystem == "origen_garages")
    local useQbGarage = (garageSystem == "qb-garages")
    local useEsxGarage = (garageSystem == "esx_garage")
    local useOpGarages = (garageSystem == "op-garages")
    if Config.Framework == "esx" then
        local rows = {}
        local queryOk = true
        if useVmsGarages then
            queryOk, rows = pcall(function()
                return MySQL and MySQL.query.await("SELECT vehicle, plate, type, garage FROM owned_vehicles WHERE owner = ?", { id }) or {}
            end)
        elseif useEsxGarage then
            queryOk, rows = pcall(function()
                return MySQL and MySQL.query.await("SELECT vehicle, plate, type, parking, pound FROM owned_vehicles WHERE owner = ?", { id }) or {}
            end)
        elseif useOrigenGarages then
            queryOk, rows = pcall(function()
                return MySQL and MySQL.query.await("SELECT vehicle, plate, type, label FROM owned_vehicles WHERE owner = ?", { id }) or {}
            end)
        elseif useOkokGarage then
            queryOk, rows = pcall(function()
                return MySQL and MySQL.query.await("SELECT vehicle, plate, type, location FROM owned_vehicles WHERE owner = ?", { id }) or {}
            end)
        elseif useQsGarage then
            queryOk, rows = pcall(function()
                return MySQL and MySQL.query.await("SELECT vehicle, plate, type, garage FROM owned_vehicles WHERE owner = ?", { id }) or {}
            end)
        elseif useJgGarage then
            local jgEsxSql = {
                "SELECT vehicle, plate, type, garage, garage_id FROM owned_vehicles WHERE owner = ?",
                "SELECT vehicle, plate, type, garage_id FROM owned_vehicles WHERE owner = ?",
                "SELECT vehicle, plate, type, garage FROM owned_vehicles WHERE owner = ?",
                "SELECT vehicle, plate, type FROM owned_vehicles WHERE owner = ?",
            }
            queryOk, rows = false, {}
            for s = 1, #jgEsxSql do
                local success, r = pcall(function()
                    return MySQL and MySQL.query.await(jgEsxSql[s], { id }) or {}
                end)
                if success and r and type(r) == "table" then
                    queryOk, rows = true, r
                    break
                end
            end
        elseif useOpGarages then
            queryOk, rows = pcall(function()
                return MySQL and MySQL.query.await("SELECT vehicle, plate, type, garage FROM owned_vehicles WHERE owner = ?", { id }) or {}
            end)
        else
            queryOk, rows = pcall(function()
                return MySQL and MySQL.query.await("SELECT vehicle, plate, type FROM owned_vehicles WHERE owner = ?", { id }) or {}
            end)
        end
        if not queryOk or not rows or type(rows) ~= "table" then
            rows = {}
        end
        if rows and #rows > 0 then
            for _, row in ipairs(rows) do
                local name = "Vehicle"
                if row.vehicle and row.vehicle ~= "" then
                    local success, data = pcall(json.decode, row.vehicle)
                    if success and type(data) == "table" then
                        name = data.modelName or data.model or (row.type and row.type ~= "" and row.type or name)
                    else
                        name = row.type and row.type ~= "" and row.type or name
                    end
                elseif row.type and row.type ~= "" then
                    name = row.type
                end
                local loc
                if useVmsGarages and row.garage ~= nil and row.garage ~= "" then
                    loc = tostring(row.garage)
                elseif useEsxGarage then
                    loc = (row.parking and row.parking ~= "") and row.parking or (row.pound and row.pound ~= "" and ("Pound: " .. row.pound) or "—")
                elseif useOrigenGarages and row.label ~= nil and row.label ~= "" then
                    loc = tostring(row.label)
                elseif useOkokGarage and row.location ~= nil and row.location ~= "" then
                    loc = tostring(row.location)
                elseif useQsGarage and row.garage ~= nil and row.garage ~= "" then
                    loc = tostring(row.garage)
                elseif useOpGarages and row.garage ~= nil and row.garage ~= "" then
                    loc = tostring(row.garage)
                elseif useJgGarage then
                    if row.garage_id ~= nil and tostring(row.garage_id) ~= "" then
                        loc = tostring(row.garage_id)
                    elseif row.garaje_id ~= nil and tostring(row.garaje_id) ~= "" then
                        loc = tostring(row.garaje_id)
                    elseif row.garage ~= nil and row.garage ~= "" then
                        loc = tostring(row.garage)
                    end
                else
                    local gid = row.garage_id or row.garaje_id
                    if gid ~= nil and gid ~= "" then
                        loc = tostring(gid)
                    end
                end
                if not loc then
                    loc = (row.parking and row.parking ~= "") and row.parking or (row.pound and row.pound ~= "" and ("Pound: " .. row.pound) or "—")
                end
                list[#list + 1] = {
                    name = name,
                    plate = row.plate or "—",
                    parking = loc
                }
            end
        end
    elseif Config.Framework == "qb" then
        local qbSql = {}
        if useOrigenGarages then
            qbSql[1] = "SELECT vehicle, plate, garage, label, garage_id FROM player_vehicles WHERE citizenid = ?"
            qbSql[2] = "SELECT vehicle, plate, garage, label FROM player_vehicles WHERE citizenid = ?"
        elseif useOkokGarage then
            qbSql[1] = "SELECT vehicle, plate, garage, location, garage_id FROM player_vehicles WHERE citizenid = ?"
            qbSql[2] = "SELECT vehicle, plate, garage, location FROM player_vehicles WHERE citizenid = ?"
        elseif useJgGarage then
            qbSql[1] = "SELECT vehicle, plate, garage, garage_id FROM player_vehicles WHERE citizenid = ?"
            qbSql[2] = "SELECT vehicle, plate, garage_id FROM player_vehicles WHERE citizenid = ?"
            qbSql[3] = "SELECT vehicle, plate, garage FROM player_vehicles WHERE citizenid = ?"
            qbSql[4] = "SELECT vehicle, plate FROM player_vehicles WHERE citizenid = ?"
        elseif useQsGarage then
            qbSql[1] = "SELECT vehicle, plate, garage, garage_id FROM player_vehicles WHERE citizenid = ?"
            qbSql[2] = "SELECT vehicle, plate, garage FROM player_vehicles WHERE citizenid = ?"
        else
            qbSql[1] = "SELECT vehicle, plate, garage, garage_id, state FROM player_vehicles WHERE citizenid = ?"
            qbSql[2] = "SELECT vehicle, plate, garage, state FROM player_vehicles WHERE citizenid = ?"
            qbSql[3] = "SELECT vehicle, plate, garage FROM player_vehicles WHERE citizenid = ?"
        end
        local rows = {}
        for q = 1, #qbSql do
            local success, r = pcall(function()
                return MySQL and MySQL.query.await(qbSql[q], { id }) or {}
            end)
            if success and r and type(r) == "table" then
                rows = r
                break
            end
        end
        if rows and #rows > 0 then
            for _, row in ipairs(rows) do
                local loc
                if useVmsGarages and row.garage ~= nil and row.garage ~= "" then
                    loc = tostring(row.garage)
                elseif useOrigenGarages and row.label ~= nil and row.label ~= "" then
                    loc = tostring(row.label)
                elseif useOkokGarage and row.location ~= nil and row.location ~= "" then
                    loc = tostring(row.location)
                elseif useQsGarage and row.garage ~= nil and row.garage ~= "" then
                    loc = tostring(row.garage)
                elseif useOpGarages and row.garage ~= nil and row.garage ~= "" then
                    loc = tostring(row.garage)
                elseif useJgGarage then
                    if row.garage_id ~= nil and tostring(row.garage_id) ~= "" then
                        loc = tostring(row.garage_id)
                    elseif row.garaje_id ~= nil and tostring(row.garaje_id) ~= "" then
                        loc = tostring(row.garaje_id)
                    elseif row.garage ~= nil and row.garage ~= "" then
                        loc = tostring(row.garage)
                    end
                elseif useQbGarage and row.garage ~= nil and row.garage ~= "" then
                    loc = tostring(row.garage)
                end
                if not loc and row.garage_id ~= nil and tostring(row.garage_id) ~= "" then
                    loc = tostring(row.garage_id)
                end
                if not loc and row.garaje_id ~= nil and tostring(row.garaje_id) ~= "" then
                    loc = tostring(row.garaje_id)
                end
                -- Use state to determine parking label when garage name is absent
                if not loc then
                    local state = tonumber(row.state)
                    if state == 1 and row.garage and row.garage ~= "" then
                        loc = tostring(row.garage)
                    elseif state == 2 then
                        loc = "Impounded"
                    elseif state == 0 then
                        loc = "Out"
                    else
                        loc = (row.garage and row.garage ~= "") and tostring(row.garage) or "—"
                    end
                end
                -- Decode vehicle model name from JSON if needed
                local vName = "Vehicle"
                if row.vehicle and row.vehicle ~= "" then
                    local ok, vData = pcall(json.decode, row.vehicle)
                    if ok and type(vData) == "table" then
                        vName = vData.model or vData.modelName or vData.name or "Vehicle"
                    else
                        vName = row.vehicle
                    end
                end
                list[#list + 1] = {
                    name = vName,
                    plate = row.plate or "—",
                    parking = loc
                }
            end
        end
    end
    return list
end

function GetPlayerVehicles(targetId)
    local player = GetPlayer(targetId)
    if not player then return {} end
    local id = GetIdentifier(player)
    if not id then return {} end
    return GetPlayerVehiclesForDbOwner(id)
end

function GetPlayerVehiclesByIdentifier(identifier)
    if not identifier or type(identifier) ~= "string" then return {} end
    return GetPlayerVehiclesForDbOwner(identifier:gsub("^%s+", ""):gsub("%s+$", ""))
end

function AddVehicleToPlayerGarage(targetId, model, plate)
    if not model or type(model) ~= "string" or model == "" then return false end
    local player = GetPlayer(targetId)
    if not player then return false end
    local id = GetIdentifier(player)
    if not id then return false end
    model = model:gsub("^%s*(.-)%s*$", "%1"):lower()
    plate = (type(plate) == "string" and plate ~= "") and plate:gsub("^%s*(.-)%s*$", "%1") or nil
    local function randomPlate8()
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        local p = ""
        for i = 1, 8 do
            p = p .. chars:sub(math.random(1, #chars), math.random(1, #chars))
        end
        return p
    end
    if not plate or plate == "" then
        plate = randomPlate8()
    end
    if #plate > 8 then plate = plate:sub(1, 8) end
    local garageSystem = getResolvedGarageSystem()
    local useVmsGarages = (garageSystem == "vms_garagesv2")
    local useJgGarage = (garageSystem == "jg-advancedgarages")
    local useOpGarages = (garageSystem == "op-garages")
    local license = (GetPlayerIdentifierByType and GetPlayerIdentifierByType(targetId, "license")) or nil
    local vehicleHash = nil
    local vehicleHashNum = nil
    if GetHashKey and model and model ~= "" then
        local success, h = pcall(GetHashKey, model)
        if success and h then
            vehicleHashNum = h
            vehicleHash = tostring(h)
        end
    end
    local function defaultModsForVehicle(plateStr, modelHashNum)
        return {
            modSubwoofer = -1, pearlescentColor = 2, modDoorR = -1, modPlateHolder = -1, fuelLevel = 100,
            modFender = -1, modDoorSpeaker = -1, paintType2 = 7, modFrame = -1, modRearBumper = -1, modTrimA = -1,
            modTank = -1, windowTint = -1, modHorns = -1, modTrunk = -1, plate = plateStr or "",
            modSmokeEnabled = false, modBackWheels = -1, tankHealth = 1000, color2 = 0, modTurbo = false,
            modOrnaments = -1, modBrakes = -1, plateIndex = 0, modRightFender = -1, modSpoilers = -1,
            modCustomTiresF = false, extras = {}, modAerials = -1, modFrontWheels = -1,
            windows = {0, 1, 2, 3, 4, 5, 6, 7}, doors = {}, wheelColor = 0, bodyHealth = 1000, interiorColor = 0,
            modSteeringWheel = -1, modXenon = false, modExhaust = -1, modTrimB = -1, color1 = 0, modSeats = -1,
            modSideSkirt = -1, modCustomTiresR = false, modLightbar = -1, livery = -1, modAirFilter = -1,
            modDial = -1, modShifterLeavers = -1, modEngineBlock = -1, modWindows = -1, dashboardColor = 0,
            wheelWidth = 0.0, modHydrolic = -1, modFrontBumper = -1, bulletProofTyres = true,
            tyreSmokeColor = {255, 255, 255}, modRoof = -1, tyres = {}, driftTyres = false, neonColor = {255, 0, 255},
            modAPlate = -1, modArchCover = -1, modEngine = -1, oilLevel = 5, modSuspension = -1, modLivery = -1,
            engineHealth = 1000, modNitrous = -1, modGrille = -1, modTransmission = -1, modStruts = -1,
            dirtLevel = 0, xenonColor = 255, modHood = -1, modHydraulics = false, model = modelHashNum or 0,
            modSpeakers = -1, modArmor = -1, modDashboard = -1, wheelSize = 0.0, modRoofLivery = -1,
            modVanityPlate = -1, wheels = 4, neonEnabled = {false, false, false, false}, paintType1 = 7
        }
    end
    local function isDuplicateKeyError(msg)
        local s = tostring(msg or ""):lower()
        return s:find("duplicate", 1, true) ~= nil or s:find("1062", 1, true) ~= nil or s:find("er_dup_entry", 1, true) ~= nil
    end
    if Config.Framework == "esx" then
        if MySQL then
            for _ = 1, 25 do
                local success, err = pcall(function()
                    local vehicleJson = json.encode({ model = model })
                    if useVmsGarages then
                        local garage = "pillboxgarage"
                        MySQL.insert.await("INSERT INTO owned_vehicles (owner, vehicle, plate, type, garage) VALUES (?, ?, ?, ?, ?)", { id, vehicleJson, plate, model, garage })
                    elseif useJgGarage then
                        local jgOk = pcall(function()
                            MySQL.insert.await("INSERT INTO owned_vehicles (owner, vehicle, plate, type, garage_id) VALUES (?, ?, ?, ?, ?)", { id, vehicleJson, plate, model, "Legion Square" })
                        end)
                        if not jgOk then
                            MySQL.insert.await("INSERT INTO owned_vehicles (owner, vehicle, plate, type) VALUES (?, ?, ?, ?)", { id, vehicleJson, plate, model })
                        end
                    elseif useOpGarages then
                        local opOk = pcall(function()
                            MySQL.insert.await("INSERT INTO owned_vehicles (owner, vehicle, plate, type, garage) VALUES (?, ?, ?, ?, ?)", { id, vehicleJson, plate, model, "1" })
                        end)
                        if not opOk then
                            MySQL.insert.await("INSERT INTO owned_vehicles (owner, vehicle, plate, type) VALUES (?, ?, ?, ?)", { id, vehicleJson, plate, model })
                        end
                    else
                        MySQL.insert.await("INSERT INTO owned_vehicles (owner, vehicle, plate, type) VALUES (?, ?, ?, ?)", { id, vehicleJson, plate, model })
                    end
                end)
                if success then return true end
                if isDuplicateKeyError(err) then
                    plate = randomPlate8()
                else
                    return false
                end
            end
            return false
        end
    elseif Config.Framework == "qb" then
        if MySQL then
            local garage = "pillboxgarage"
            local useOrigenGarages = (garageSystem == "origen_garages")
            for _ = 1, 25 do
                local success, err = pcall(function()
                    if useOrigenGarages then
                        local modsTbl = defaultModsForVehicle(plate, vehicleHashNum)
                        local defaultMods = (json.encode and json.encode(modsTbl)) or "{}"
                        MySQL.insert.await("INSERT INTO player_vehicles (citizenid, license, vehicle, hash, plate, garage, mods) VALUES (?, ?, ?, ?, ?, ?, ?)", { id, license or nil, model, vehicleHash or nil, plate, garage, defaultMods })
                    elseif useJgGarage then
                        local jgOk = pcall(function()
                            MySQL.insert.await("INSERT INTO player_vehicles (citizenid, license, vehicle, hash, plate, garage, garage_id) VALUES (?, ?, ?, ?, ?, ?, ?)", { id, license or nil, model, vehicleHash or nil, plate, garage, "Legion Square" })
                        end)
                        if not jgOk then
                            MySQL.insert.await("INSERT INTO player_vehicles (citizenid, license, vehicle, hash, plate, garage) VALUES (?, ?, ?, ?, ?, ?)", { id, license or nil, model, vehicleHash or nil, plate, garage })
                        end
                    elseif useOpGarages then
                        local opOk = pcall(function()
                            MySQL.insert.await("INSERT INTO player_vehicles (citizenid, license, vehicle, hash, plate, garage) VALUES (?, ?, ?, ?, ?, ?)", { id, license or nil, model, vehicleHash or nil, plate, "1" })
                        end)
                        if not opOk then
                            MySQL.insert.await("INSERT INTO player_vehicles (citizenid, license, vehicle, hash, plate, garage) VALUES (?, ?, ?, ?, ?, ?)", { id, license or nil, model, vehicleHash or nil, plate, garage })
                        end
                    else
                        MySQL.insert.await("INSERT INTO player_vehicles (citizenid, license, vehicle, hash, plate, garage) VALUES (?, ?, ?, ?, ?, ?)", { id, license or nil, model, vehicleHash or nil, plate, garage })
                    end
                end)
                if success then return true end
                if isDuplicateKeyError(err) then
                    plate = randomPlate8()
                else
                    return false
                end
            end
            return false
        end
    end
    return false
end

-- Function Housing System

function GetPlayerProperties(targetId)
    local list = {}
    local housing = getResolvedHousingSystem()
    if housing == "vms_housing" then
        local success, raw = pcall(function()
            return exports["vms_housing"]:GetPlayerProperties(targetId)
        end)
        if success and raw and type(raw) == "table" then
            local props = raw[1] and raw or { raw }
            for _, prop in ipairs(props) do
                if type(prop) == "table" and (prop.id or prop.name) then
                    list[#list + 1] = {
                        name = prop.name or prop.region or "—",
                        houseNumber = prop.id or prop.address or "—"
                    }
                end
            end
        end
    elseif housing == "qs-housing" then
        local idByHouse = {}
        local xPlayerQs = GetPlayer(targetId)
        if xPlayerQs then
            local identQs = GetIdentifier(xPlayerQs)
            if identQs and identQs ~= "" and MySQL and MySQL.query and MySQL.query.await then
                local qOk, dbRows = pcall(function()
                    return MySQL.query.await("SELECT id, house FROM player_houses WHERE citizenid = ? OR owner = ?", { identQs, identQs })
                end)
                if qOk and dbRows and type(dbRows) == "table" then
                    for _, row in ipairs(dbRows) do
                        if row and row.house and row.id ~= nil then
                            idByHouse[tostring(row.house)] = row.id
                        end
                    end
                end
            end
        end
        local success, houses = pcall(function()
            return exports["qs-housing"]:GetPlayerHouses(targetId)
        end)
        if success and houses and type(houses) == "table" then
            local rows = {}
            if #houses > 0 then
                for _, h in ipairs(houses) do
                    rows[#rows + 1] = h
                end
            else
                for _, h in pairs(houses) do
                    if type(h) == "table" then
                        rows[#rows + 1] = h
                    end
                end
            end
            for _, house in ipairs(rows) do
                if type(house) == "string" then
                    local dbId = idByHouse[tostring(house)]
                    list[#list + 1] = {
                        name = house,
                        houseNumber = (dbId ~= nil and tostring(dbId) ~= "") and tostring(dbId) or house
                    }
                elseif type(house) == "table" then
                    local raw = house
                    if type(house.data) == "table" then
                        raw = house.data
                    end
                    local hid = raw.house or raw.house_id or raw.id or raw.name or raw.key
                    local display = raw.label or raw.address or raw.houseName or raw.apartment or raw.property or raw.title or raw.name
                    if (not display or display == "") and hid then
                        display = tostring(hid)
                    end
                    if (not display or display == "") then
                        for _, v in pairs(raw) do
                            if type(v) == "string" and v ~= "" and v ~= raw.citizenid and v ~= raw.identifier and v ~= raw.owner then
                                display = v
                                break
                            end
                        end
                    end
                    local slug = raw.house or raw.house_id or hid
                    local dbId = slug and idByHouse[tostring(slug)]
                    local num = dbId or raw.houseNumber or raw.number or raw.house or raw.id or raw.name or hid
                    list[#list + 1] = {
                        name = (display and display ~= "" and tostring(display)) or "—",
                        houseNumber = (num ~= nil and tostring(num) ~= "") and tostring(num) or "—"
                    }
                end
            end
        end
    elseif housing == "origen_housing" then
        local xPlayer = GetPlayer(targetId)
        if xPlayer then
            local identifier = GetIdentifier(xPlayer)
            if identifier then
                local ownedHouses = exports["origen_housing"]:getOwnedHouses(identifier)
                if ownedHouses and #ownedHouses > 0 then
                    for _, houseID in ipairs(ownedHouses) do
                        local house = exports["origen_housing"]:getHouse(houseID)
                        if house then
                            list[#list + 1] = {
                                name = house.name or "—",
                                houseNumber = house.id or house.houseNumber or house.number or "—"
                            }
                        end
                    end
                end
            end
        end
    elseif housing == "esx_property" then
        local xPlayer = GetPlayer(targetId)
        if xPlayer then
            local identifier = GetIdentifier(xPlayer)
            if identifier then
                local playerProps = exports["esx_property"]:GetPlayerProperties(identifier)
                if playerProps and #playerProps > 0 then
                    for idx, prop in ipairs(playerProps) do
                        local name = (prop.setName and prop.setName ~= "") and prop.setName or (prop.Name or "—")
                        list[#list + 1] = { name = name, houseNumber = "#" .. idx }
                    end
                end
            end
        end
    elseif housing == "bcs_housing" then
        local player = GetPlayer(targetId)
        if player then
            local identifier = GetIdentifier(player)
            if identifier and identifier ~= "" then
                local success, homes = pcall(function()
                    return exports["bcs_housing"]:GetOwnedHomes(identifier)
                end)
                if success and homes and type(homes) == "table" then
                    for _, home in pairs(homes) do
                        if type(home) == "table" and (home.identifier or home.name) then
                            list[#list + 1] = {
                                name = home.name or home.complex or "—",
                                houseNumber = tostring(home.identifier or home.name or "—")
                            }
                        end
                    end
                end
            end
        end
    end
    return list
end

function GetPlayerPropertiesByIdentifier(identifier)
    local list = {}
    if not identifier or type(identifier) ~= "string" then return list end
    local id = identifier:gsub("^%s+", ""):gsub("%s+$", "")
    if id == "" then return list end
    local housing = getResolvedHousingSystem()
    if housing == "origen_housing" then
        pcall(function()
            local ownedHouses = exports["origen_housing"]:getOwnedHouses(id)
            if ownedHouses and #ownedHouses > 0 then
                for _, houseID in ipairs(ownedHouses) do
                    local house = exports["origen_housing"]:getHouse(houseID)
                    if house then
                        list[#list + 1] = {
                            name = house.name or "—",
                            houseNumber = house.id or house.houseNumber or house.number or "—"
                        }
                    end
                end
            end
        end)
    elseif housing == "esx_property" then
        pcall(function()
            local playerProps = exports["esx_property"]:GetPlayerProperties(id)
            if playerProps and #playerProps > 0 then
                for idx, prop in ipairs(playerProps) do
                    local name = (prop.setName and prop.setName ~= "") and prop.setName or (prop.Name or "—")
                    list[#list + 1] = { name = name, houseNumber = "#" .. idx }
                end
            end
        end)
    elseif housing == "bcs_housing" then
        local success, homes = pcall(function()
            return exports["bcs_housing"]:GetOwnedHomes(id)
        end)
        if success and homes and type(homes) == "table" then
            for _, home in pairs(homes) do
                if type(home) == "table" and (home.identifier or home.name) then
                    list[#list + 1] = {
                        name = home.name or home.complex or "—",
                        houseNumber = tostring(home.identifier or home.name or "—")
                    }
                end
            end
        end
    elseif housing == "qs-housing" and MySQL and MySQL.query and MySQL.query.await then
        pcall(function()
            local qOk, dbRows = pcall(function()
                return MySQL.query.await("SELECT id, house FROM player_houses WHERE citizenid = ? OR owner = ?", { id, id })
            end)
            if qOk and dbRows and type(dbRows) == "table" then
                for _, row in ipairs(dbRows) do
                    if row and row.house then
                        list[#list + 1] = {
                            name = tostring(row.house),
                            houseNumber = (row.id ~= nil and tostring(row.id) ~= "") and tostring(row.id) or tostring(row.house)
                        }
                    end
                end
            end
        end)
    end
    return list
end

-- Function Character Delete
function CharacterCK(targetSrc)
	if not targetSrc or targetSrc == 0 then return end
	if not MySQL then return end
    
	if Config.Framework == "esx" then
		local identifier = nil
		local player = GetPlayer(targetSrc)
		if player then
			identifier = GetIdentifier(player)
		end
		if not identifier then
			identifier = GetPlayerIdentifierByType and GetPlayerIdentifierByType(targetSrc, "license") or nil
		end
		if identifier and identifier ~= "" then
			MySQL.query.await("DELETE FROM users WHERE identifier = ?", { identifier })
		end
	elseif Config.Framework == "qb" then
		local citizenid = nil
		local player = GetPlayer(targetSrc)
		if player and player.PlayerData and player.PlayerData.citizenid then
			citizenid = player.PlayerData.citizenid
		end
		if citizenid and citizenid ~= "" then
			MySQL.query.await("DELETE FROM players WHERE citizenid = ?", { citizenid })
		end
	end
    
	DropPlayer(targetSrc, "Character deleted")
end

function CharacterCKOffline(identifier)
	if not identifier or type(identifier) ~= "string" or not MySQL or not MySQL.query or not MySQL.query.await then return false end
	identifier = identifier:gsub("^%s+", ""):gsub("%s+$", "")
	if identifier == "" then return false end
	if Config.Framework == "esx" then
		MySQL.query.await("DELETE FROM users WHERE identifier = ?", { identifier })
		return true
	elseif Config.Framework == "qb" then
		MySQL.query.await("DELETE FROM players WHERE citizenid = ? OR license = ?", { identifier, identifier })
		return true
	end
	return false
end

-- Function Report System
function GetReportsStatsForStatistics()
    if GetResourceState("jc_reports") ~= "started" then return nil end
    local success, stats = pcall(function()
        return exports["jc_reports"]:GetReportsStats()
    end)
    if success and stats and type(stats) == "table" then
        return stats
    end
    return nil
end

-- Function Gang System
function GetAllGangs()
    local system = getResolvedGangSystem()
    if system == "jc_organizaciones" then
        local success, names = pcall(function()
            return exports["jc_organizaciones"]:GetAllOrgs()
        end)
        if not success or type(names) ~= "table" then return {} end
        local result = {}
        for _, name in ipairs(names) do
            if type(name) == "string" and name ~= "" then
                result[#result + 1] = {
                    name = name,
                    label = name,
                    grades = { { grade = 0, label = "Miembro" } }
                }
            end
        end
        table.sort(result, function(a, b) return (a.label or a.name) < (b.label or b.name) end)
        return result
    end
    if system == "op-crime" then
        local success, list = pcall(function()
            return exports["op-crime"]:getOrganisationsList()
        end)
        if not success or type(list) ~= "table" then return {} end
        local result = {}
        for _, item in ipairs(list) do
            if type(item) ~= "table" then goto continue end
            local id = item.identifier
            local label = item.label
            local name = (id ~= nil and tostring(id) ~= "") and tostring(id) or nil
            if not name then goto continue end
            result[#result + 1] = {
                name = name,
                label = (type(label) == "string" and label ~= "" and label) or name,
                grades = { { grade = 0, label = "Miembro" } }
            }
            ::continue::
        end
        table.sort(result, function(a, b) return (a.label or a.name) < (b.label or b.name) end)
        return result
    end
    if system == "av_gangs" then
        local success, names = pcall(function()
            return exports["av_gangs"]:getGangNames()
        end)
        if not success or type(names) ~= "table" then return {} end
        local result = {}
        for _, name in ipairs(names) do
            if type(name) == "string" and name ~= "" then
                result[#result + 1] = {
                    name = name,
                    label = name,
                    grades = { { grade = 0, label = "Miembro" } }
                }
            end
        end
        table.sort(result, function(a, b) return (a.label or a.name) < (b.label or b.name) end)
        return result
    end
    if Config.Framework == "qb" and QBCore and QBCore.Shared and type(QBCore.Shared.Gangs) == "table" then
        local result = {}
        for gangName, gangData in pairs(QBCore.Shared.Gangs) do
            if gangName ~= "none" and type(gangData) == "table" and gangData.label then
                local gradesList = {}
                if type(gangData.grades) == "table" then
                    for gKey, gInfo in pairs(gangData.grades) do
                        local gNum = tonumber(gKey)
                        if gNum == nil then
                            gNum = gKey
                        end
                        local glabel = "—"
                        if type(gInfo) == "table" then
                            glabel = gInfo.name or gInfo.label or tostring(gKey)
                        elseif type(gInfo) == "string" then
                            glabel = gInfo
                        end
                        gradesList[#gradesList + 1] = { grade = gNum, label = tostring(glabel) }
                    end
                    table.sort(gradesList, function(a, b)
                        return (tonumber(a.grade) or 0) < (tonumber(b.grade) or 0)
                    end)
                end
                if #gradesList == 0 then
                    gradesList = { { grade = 0, label = "Miembro" } }
                end
                result[#result + 1] = {
                    name = tostring(gangName),
                    label = tostring(gangData.label),
                    grades = gradesList
                }
            end
        end
        table.sort(result, function(a, b) return (a.label or a.name) < (b.label or b.name) end)
        return result
    end
    return {}
end

function GetPlayerOrganization(targetId)
    if not targetId or tonumber(targetId) == nil then return "None" end
    targetId = tonumber(targetId)
    local player = GetPlayer(targetId)
    if not player then return "None" end
    local system = getResolvedGangSystem()
    if system == "jc_organizaciones" then
        local identifier = GetIdentifier(player)
        if not identifier or identifier == "" then return "None" end
        local success, name = pcall(function()
            return exports["jc_organizaciones"]:GetOrgName(identifier)
        end)
        if success and type(name) == "string" and name ~= "" then return name end
        return "None"
    end
    if system == "op-crime" then
        local identifier = GetIdentifier(player)
        if not identifier or identifier == "" then return "None" end
        local success, data = pcall(function()
            return exports["op-crime"]:getPlayerOrganisation(identifier)
        end)
        if success and type(data) == "table" and data.orgData then
            local orgData = data.orgData
            if orgData.label and tostring(orgData.label) ~= "" then return tostring(orgData.label) end
            if orgData.name and tostring(orgData.name) ~= "" then return tostring(orgData.name) end
        end
        return "None"
    end
    if system == "av_gangs" then
        local success, data = pcall(function()
            return exports["av_gangs"]:getGang(targetId)
        end)
        if success and type(data) == "table" then
            if data.label and tostring(data.label) ~= "" then return tostring(data.label) end
            if data.name and tostring(data.name) ~= "" then return tostring(data.name) end
        end
        return "None"
    end
    if Config.Framework == "qb" and player.PlayerData and player.PlayerData.gang then
        local g = player.PlayerData.gang
        local n = g.name and tostring(g.name):lower() or ""
        if n ~= "" and n ~= "none" then
            if g.label and tostring(g.label) ~= "" then return tostring(g.label) end
            if g.name and tostring(g.name) ~= "" then return tostring(g.name) end
        end
    end
    return "None"
end

function ApplyGangToPlayer(targetId, gangName, grade)
    local system = getResolvedGangSystem()
    if system == "jc_organizaciones" then
        local player = GetPlayer(targetId)
        if not player then return end
        local identifier = GetIdentifier(player)
        if not identifier or identifier == "" then return end
        local playerName = GetPlayerName and GetPlayerName(targetId) or "Jugador"
        local rango = (grade ~= nil and tostring(grade) ~= "") and tostring(grade) or "Miembro"
        local success, ret = pcall(function()
            return exports["jc_organizaciones"]:SetPlayerOrg(identifier, gangName, playerName, rango)
        end)
        success = success and ret
        if success then return end
    end
    if system == "op-crime" then
    end
    if system == "av_gangs" then
        local success, ret = pcall(function()
            return exports["av_gangs"]:addToGang(targetId, gangName)
        end)
        success = success and ret
        if success then return end
    end
    if Config.Framework == "qb" then
        local player = GetPlayer(targetId)
        if not player or not player.Functions or not player.Functions.SetGang then return end
        if not gangName or gangName == "" then return end
        local g = tonumber(grade)
        if g == nil then
            g = 0
        end
        player.Functions.SetGang(gangName, g)
    end
end

local function getAmbulanceSystemServer()
    local cfg = Config.AmbulanceSystem or 'standalone'
    if cfg ~= 'auto' then return cfg end
    if GetResourceState('sky_ambulancejob') == 'started' then return 'sky_ambulancejob' end
    if GetResourceState('qs-medical-creator') == 'started' then return 'qs-medical-creator' end
    if GetResourceState('wasabi_ambulance_v2') == 'started' then return 'wasabi_ambulance_v2' end
    if GetResourceState('wasabi_ambulance') == 'started' then return 'wasabi_ambulance' end
    if GetResourceState('ars_ambulancejob') == 'started' then return 'ars_ambulancejob' end
    if GetResourceState('osp_ambulance') == 'started' then return 'osp_ambulance' end
    if GetResourceState('p_ambulancejob') == 'started' then return 'p_ambulancejob' end
    if GetResourceState('esx_ambulancejob') == 'started' then return 'esx_ambulancejob' end
    if GetResourceState('qb-ambulancejob') == 'started' or GetResourceState('qbx_ambulancejob') == 'started' then return 'qb-ambulancejob' end
    return 'standalone'
end

RegisterNetEvent("adminpanel:revivePlayer", function(targetId)
    local src = source
    if not src or src == 0 then return end
    local success = hasAllowedGroup(src)
    if not success then return end

    targetId = tonumber(targetId)
    if not targetId then return end

    local system = getAmbulanceSystemServer()
    if system == 'qs-medical-creator' then
        TriggerClientEvent("ambulance:revivePlayer", targetId)
    elseif system == 'sky_ambulancejob' then
        exports["sky_ambulancejob"]:revive(targetId)
    elseif system == 'wasabi_ambulance' then
        exports.wasabi_ambulance:RevivePlayer(targetId)
    elseif system == 'wasabi_ambulance_v2' then
        exports.wasabi_ambulance_v2:RevivePlayer(targetId)
    elseif system == 'qb-ambulancejob' or system == 'qbx_ambulancejob' then
        TriggerClientEvent("hospital:client:Revive", targetId)
    elseif system == 'p_ambulancejob' then
		if Config.Framework == 'qb' then
            TriggerClientEvent('hospital:client:Revive', targetId)		
        end
    else
        TriggerClientEvent("admin:revive", targetId, targetId)
    end
    if LogAdminAction then LogAdminAction(src, "revive", targetId, GetPlayerName(targetId)) end
end)
