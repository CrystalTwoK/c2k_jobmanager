local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getMarkers', function(markers)
        for k,m in ipairs(markers) do
            TriggerEvent('c2k_jobmanager:client:markers:createMarker', m.type, m.markerid, json.decode(m.position), m.sprite, m.label, m.jobname, json.decode(m.roles), m.img) 
            TriggerServerEvent('c2k_jobmanager:server:registerStashes', m.markerid, m.seriale, json.decode(m.position))
        end
    end)
end)

RegisterNetEvent('c2k_jobmanager:client:markers:createMarker', function(_type, markerID, pos, sprite, label, jobName, roles, interactionImage)

    TriggerEvent('c2k_interactions:client:registerMarker', {
        id = markerID,
        pos = vector3(pos.x, pos.y, pos.z),
        type = sprite,
        label = label,
        interactionDistance = 1.0,
        img = interactionImage,
        job = {
            name = jobName,
            grade = roles
        } or nil,
        action = function(marker)
            print('INSIDE')
            if _type == 'deposito' then
                exports.ox_inventory:openInventory('stash', marker.id)
            elseif _type == 'vestiti' then
                TriggerEvent("illenium-appearance:client:openClothingShopMenu", false) -- se settato su 'false' apre il menu vestiti di default senza pedmenu
                -- TriggerEvent("qb-clothing:client:openMenu") -- APRE SOLO SHOP VESTITI
            elseif _type == 'outfit' then
                TriggerEvent('qb-clothing:client:openOutfitMenu')
            elseif _type == 'boss' then
                print('PREMUTO DA MARKERS.LUA')
                TriggerEvent('c2k_jobmanager:client:openBossMenu', jobName, marker.id)
            elseif _type == 'garage' then
                TriggerEvent('c2k_jobmanager:client:openGarageMenu', marker.id)
                print('Marker ID: '..marker.id)
            else return end
        end
    })

end)

RegisterNetEvent('c2k_jobmanager:client:deleteCloserMarker', function()
    local marker, distance = exports.c2k_interactions:getCloserMarker()
    if marker then
        if distance <= 1.5 then
            TriggerServerEvent('c2k_jobmanager:server:eliminaMarkerDB', marker.id)
        else TriggerEvent("QBCore:Notify", "Nessun marker nelle vicinanze!") end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getMarkers', function(markers)
            for k,m in ipairs(markers) do
                TriggerEvent('c2k_jobmanager:client:markers:createMarker', m.type, m.markerid, json.decode(m.position), m.sprite, m.label, m.jobname, json.decode(m.roles), m.img) 
                
            end
        end)
    end
end)