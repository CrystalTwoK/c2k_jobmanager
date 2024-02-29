local QBCore = exports['qb-core']:GetCoreObject()

local menulocation = "bottomright"

RegisterNetEvent('c2k_jobmanager:client:openGarageMenu', function(garageID)

    local ped = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(ped, false)

    if IsPedInAnyVehicle(ped, true) then
        SetEntityAsMissionEntity(currentVehicle, true, true)
        TaskLeaveVehicle(ped, currentVehicle, 0)
        Wait(1500)
        DeleteVehicle(currentVehicle)
    else
        QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getGarageData', function(garageData)
            local Vehicles = MenuV:CreateMenu(false, "GARAGE VEICOLI", menulocation, 255, 12, 40, 'size-125', 'horde_default', 'menuv') -- Sub Menu giocatori
            Vehicles:ClearItems()
            MenuV:OpenMenu(Vehicles)
            for _, car in pairs(garageData.cars) do
                Vehicles:AddButton({
                    label = car:upper(),
                    value = car,
                    description = "Spawna "..car:upper(),
                    select = function(btn)
                        local carName = btn.Value
                        -- print(carName)
                        -- print(json.encode(garageData.spawncoords))
                        -- print(json.encode(garageData.spawnheading))
                        spawnVehicle(carName, garageData.spawncoords, garageData.spawnheading)
                        -- ExecuteCommand('car '..carName) -- con il comando funziona invece
                        

                        MenuV:CloseMenu(Vehicles)
                    end
                })
            end
        end, garageID)
    end
end)

function spawnVehicle(vehName, coords, heading)

    local hash = GetHashKey(vehName)
    local ped = PlayerPedId()

    if not IsModelInCdimage(hash) then return end
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end

    local vehicle = CreateVehicle(vehName, coords.x, coords.y, coords.z, heading, true, false)
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetModelAsNoLongerNeeded(hash)
    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(vehicle))

end