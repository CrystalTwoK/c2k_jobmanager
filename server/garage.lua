local QBCore = exports['qb-core']:GetCoreObject()

local menulocation = Config.Markers.Garages.MenuLocation

QBCore.Functions.CreateCallback('c2k_jobmanager:callback:getGarageData', function(_, cb, garageID)
    QBCore.Debug("Garage ID:"..garageID)
    local garageData = MySQL.query.await("SELECT * FROM c2k_garages WHERE garageid = ?", {garageID})

    QBCore.Debug(garageData)

    local decodedData = {
        garageid = garageData[1].garageid,
        cars = json.decode(garageData[1].cars),
        spawncoords = json.decode(garageData[1].spawncoords),
        spawnheading = tonumber(garageData[1].spawnheading)
    }

    QBCore.Debug(decodedData)

    cb(decodedData)
end)

RegisterNetEvent('c2k_jobmanager:server:registerGarage', function(garageID, carsToSpawn, coordinates, heading)
    local cars = {}
    for car in string.gmatch(carsToSpawn, '([^,]+)') do
        cars[#cars + 1] = car
    end

    QBCore.Debug(cars)

    MySQL.insert.await('INSERT INTO `c2k_garages` (`garageid`, `cars`, `spawncoords`, `spawnheading`) VALUES (?, ?, ?, ?)', {garageID, json.encode(cars), json.encode(coordinates), heading})

end)