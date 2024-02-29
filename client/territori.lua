local QBCore = exports['qb-core']:GetCoreObject();
local attackBlips = {}
local C = Config.Territories

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getTerritories', function(territories)
        for k,t in ipairs(territories) do
            TriggerEvent('c2k_jobmanager:client:territori:createMarker', t.markerid, json.decode(t.position), t.type, t.label, t.jobname, t.item)
        end
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getTerritories', function(territories)
            for k,t in ipairs(territories) do
                TriggerEvent('c2k_jobmanager:client:territori:createMarker', t.markerid, json.decode(t.position), t.type, t.label, t.jobname, t.item)
            end
        end)
    end
end)

RegisterNetEvent("c2k_jobmanager:client:territoryFarming", function(itemToGive, qty)
    QBCore.Functions.Progressbar("territory_farming", "Raccogliendo...", 10000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "mini@repair",
        anim = "fixing_a_player",
        flags = 16,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_player", 1.0)
        TriggerServerEvent("c2k_jobmanager:server:giveFarmedItems", itemToGive, qty)
    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), "mini@repair", "fixing_a_player", 1.0)
        QBCore.Functions.Notify(Lang:t('error.canceled'), "error")
    end)
end)

RegisterNetEvent('c2k_jobmanager:client:territori:createMarker', function(markerID, pos, markerType, label, jobName, itemToGive)
    TriggerEvent('c2k_interactions:client:registerMarker', {
        id = markerID,
        pos = vector3(pos.x, pos.y, pos.z),
        type = markerType,
        label = label,
        action = function(marker)
            print("markerInteraction", marker, itemToGive, jobName)
            TriggerServerEvent('c2k_jobmanager:server:markerInteraction', marker, itemToGive, jobName)
        end
    })
end)

RegisterNetEvent('c2k_jobmanager:client:showAttackBlip', function(markerID, pos)
    attackBlips[markerID] = AddBlipForRadius(pos.x, pos.y, pos.z, 250.0)
    SetBlipSprite(attackBlips[markerID], 161)
    SetBlipColour(attackBlips[markerID], 1)
    SetBlipAsShortRange(attackBlips[markerID], false)
end)

RegisterNetEvent('c2k_jobmanager:client:hideAttackBlip', function(markerID)
    for k,blip in pairs(attackBlips) do
        if k == markerID then
            RemoveBlip(attackBlips[markerID])
            attackBlips[markerID] = nil
        end
    end
end)

-- AddEventHandler('onResourceStart', function(resourceName)
--     if resourceName == GetCurrentResourceName() then
--         QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getTerritories', function(territories)
--             for k,t in ipairs(territories) do
--                 TriggerEvent('c2k_jobmanager:client:createMarker', t.markerid, json.decode(t.position), t.type, t.label, t.jobname, t.item)
--             end
--         end)
--     end
-- end)