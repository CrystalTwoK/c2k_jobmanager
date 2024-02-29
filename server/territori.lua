local QBCore = exports['qb-core']:GetCoreObject();

local C = Config.Territories

local currentAttacks = {}

QBCore.Commands.Add("createrritorio", "Crea un territorio", {{name = "Fazione", help = "Fazione a cui assegnare il territorio"}, {name = "Item da Dare", help = "Nome spawn dell'item da consegnare durante la raccolta"}}, false, function(source, args)
    local src = source
    
    if args then
        if args[1] and args[2] then
            local markerID = 'territorio_'..args[1]..'_'..args[2];
            local coords = GetEntityCoords(GetPlayerPed(source));
            saveMarkerOnDatabase(markerID, coords, 'horde_2', 'INTERAGISCI CON TERRITORIO', args[1], args[2])
            creaMarkerTerritorio(markerID, coords, 'horde_2', 'INTERAGISCI CON TERRITORIO', args[1], args[2])
        end
    end

end, "dev")

local currentUsedMarkers = {}

RegisterNetEvent('c2k_jobmanager:server:markerUpdate', function(markerID, newFaction)

    print('MARKER ID: '..markerID)

    local old = MySQL.Sync.fetchSingle('SELECT * FROM c2k_territories WHERE markerid = ?', {markerID})

    local new = {
        markerid = "territorio_"..newFaction.."_"..old.item,
        position = json.decode(old.position),
        type = old.type,
        label = old.label,
        jobname = newFaction,
        item = old.item
    }

    local newCoords = vector3(new.position.x, new.position.y, new.position.z)

    saveMarkerOnDatabase(new.markerid, newCoords, new.type, new.label, new.jobname, new.item)
    creaMarkerTerritorio(new.markerid, newCoords, new.type, new.label, new.jobname, new.item)

    Wait(100)
    deleteMarkerOnDatabase(markerID)
    eliminaMarkerTerritorio(markerID)
end)

RegisterNetEvent('c2k_jobmanager:server:giveFarmedItems', function(itemToGive, qty)
    if exports.ox_inventory:CanCarryItem(source, itemToGive, qty) then
        exports.ox_inventory:AddItem(source, itemToGive, qty)
    else
        TriggerClientEvent("QBCore:Notify", source, "Non puoi portare altri oggetti!")
    end
end)

RegisterNetEvent('c2k_jobmanager:server:markerInteraction', function(marker, itemToGive, defendingJob)
    local activePlayers = QBCore.Functions.GetQBPlayers()
    local interactedPlayer = QBCore.Functions.GetPlayer(source)
    local attackingJob = interactedPlayer.PlayerData.job.name

    print('Player JOB: '..interactedPlayer.PlayerData.job.name)

    if attackingJob == defendingJob then
        local quantity = math.random(C.MinItems, C.MaxItems)
        if exports.ox_inventory:CanCarryItem(source, itemToGive, quantity) then
            TriggerClientEvent("c2k_jobmanager:client:territoryFarming", source, itemToGive, quantity)
        else
            TriggerClientEvent("QBCore:Notify", source, "Non puoi portare altri oggetti!")
        end
        -- TO DO
    elseif attackingJob ~= defendingJob and attackingJob ~= 'unemployed' then
        local currentAttackingPlayers = {}
        local currentActiveDefendingPlayers = {}
        for k,Player in pairs(activePlayers) do
            if Player.PlayerData.job.name == defendingJob then 
                currentActiveDefendingPlayers[#currentActiveDefendingPlayers + 1] = Player 
            elseif Player.PlayerData.job.name == attackingJob then
                print(Player.PlayerData.source)
                local playerPed = GetPlayerPed(Player.PlayerData.source);
                local playerPosition = GetEntityCoords(playerPed);
                local markerCoords = marker.pos;

                if (#markerCoords - #playerPosition) <= C.MaxRadius then
                    currentAttackingPlayers[#currentAttackingPlayers + 1] = Player;
                    print('Giocatore Aggiunto')
                end

            end
        end

        Wait(100)

        if #currentActiveDefendingPlayers >= C.MinimumDefendingPlayers then
            print('NUMERO DI DIFENSORI SUFFICIENTE')
            print(#currentAttackingPlayers)
            if #currentAttackingPlayers <= C.MaxAttackingPlayers then
                if #currentAttackingPlayers >= C.MinAttackingPlayers then
                    print('ATTACCO INIZIATO')

                    currentAttacks[marker.id] = {
                        attackTimer = (C.AttackTimer * 60) * 1000, -- Ottengo i minuti da AttackTimer e li converto in millisecondi
                        attackingFaction = attackingJob,
                        defendingFaction = defendingJob,
                        position = marker.pos,

                    }

                    currentAttacks[marker.id].attaccanti = {}
                    currentAttacks[marker.id].difensori = {}

                    for k,attaccante in pairs(currentAttackingPlayers) do
                        if attaccante.Functions.GetMetaData('isdead') == false then
                            currentAttacks[marker.id].attaccanti[k] = {
                                id = attaccante.PlayerData.source,
                                citizenid = attaccante.PlayerData.citizenid,
                                ped = GetPlayerPed(attaccante.PlayerData.source),
                                isdead = false
                            }
                            TriggerClientEvent('c2k_announcement:send', attaccante.PlayerData.source, "","CONQUISTA TERRITORIO INIZIATA")
                            TriggerClientEvent('c2k_jobmanager:client:showAttackBlip', attaccante.PlayerData.source, marker.id, marker.pos)
                        end
                    end

                    for kD,difensore in pairs(currentActiveDefendingPlayers) do
                        currentAttacks[marker.id].difensori[kD] = {
                            id = difensore.PlayerData.source,
                            citizenid = difensore.PlayerData.citizenid,
                            ped = GetPlayerPed(difensore.PlayerData.source),
                            isdead = false
                        }
                        TriggerClientEvent('c2k_announcement:send', difensore.PlayerData.source, "","TERRITORIO SOTTO ATTACCO")
                        TriggerClientEvent('c2k_jobmanager:client:showAttackBlip', difensore.PlayerData.source, marker.id, marker.pos)
                    end

                else
                    TriggerClientEvent('QBCore:Notify', source, "Minimo "..C.MinAttackingPlayers.." possono attaccare un territorio.")
                end
            else
                TriggerClientEvent('QBCore:Notify', source, "Massimo "..C.MaxAttackingPlayers.." possono attaccare un territorio.")
            end
        else
            TriggerClientEvent('QBCore:Notify', source, "Difensori non sufficienti")
        end
    end
end)

QBCore.Functions.CreateCallback('c2k_jobmanager:callback:getTerritories', function(_, cb)
    local territories = MySQL.query.await('SELECT * FROM c2k_territories', {})
    cb(territories)
end)

function saveMarkerOnDatabase(markerID, pos, markerType, label, jobName, itemToGive)
    MySQL.insert.await('INSERT INTO `c2k_territories` (`markerid`, `position`, `type`, `label`, `jobname`, `item`) VALUES (?, ?, ?, ?, ?, ?)', {markerID, json.encode(pos), markerType, label, jobName, itemToGive})
    print('MARKER TERRITORIO SALVATO CON SUCCESSO')
end

function deleteMarkerOnDatabase(markerID)
    MySQL.query('DELETE FROM `c2k_territories` WHERE markerid = ?', {markerID})
    print('MARKER TERRITORIO ELIMINATO CON SUCCESSO')
end

function creaMarkerTerritorio(markerID, pos, markerType, label, jobName, itemToGive)
    TriggerClientEvent('c2k_jobmanager:client:territori:createMarker', -1, markerID, pos, markerType, label, jobName, itemToGive)
    print('MARKER TERRITORIO CREATO CON SUCCESSO')
end

function eliminaMarkerTerritorio(markerID)
    TriggerEvent('c2k_interactions:server:deleteMarker', -1, markerID)
    print('MARKER TERRITORIO ELIMINATO CON SUCCESSO')
end

function checkWinner(territoryID)
    local attackersAlive = 0
    local defendersAliveInTheArea = 0
    for k, player in pairs(currentAttacks[territoryID].attaccanti) do
        if player.isdead == false then 
            attackersAlive = attackersAlive + 1;
        end
    end

    for k,player in pairs(currentAttacks[territoryID].difensori) do
        local playerCoords = GetEntityCoords(player.ped)
        if (#playerCoords - #currentAttacks[territoryID].position) <= C.MaxRadius and player.isdead == false then
            defendersAliveInTheArea = defendersAliveInTheArea + 1;
        end
    end

    Wait(10)

    if attackersAlive > 0 and defendersAliveInTheArea > 0 then 
        return 'incorso'
    elseif attackersAlive == 0 and defendersAliveInTheArea > 0 then 
        return 'difensori'
    elseif defendersAliveInTheArea == 0 and attackersAlive > 0 then 
        return 'attaccanti' 
    end
end

function isEmpty(t)
    for _,_ in pairs(t) do
        return false
    end
    return true
end

local delay = 1000

Citizen.CreateThread(function()
    while true do
        Wait(delay)

        if isEmpty(currentAttacks) == false then
            for territoryID, attackInfo in pairs(currentAttacks) do
                if attackInfo.attackTimer == 0 then
                    if checkWinner(territoryID) == 'attaccanti' then
                        TriggerEvent('c2k_jobmanager:server:markerUpdate', territoryID, attackInfo.attackingFaction)
                        hideClientBlips(territoryID)
                        winnerNotification(territoryID, 'attaccanti')
                        print('GLI ATTACCANTI HANNO VINTO')
                        Wait(100)
                        currentAttacks[territoryID] = nil
                        break 
                    elseif checkWinner(territoryID) == 'difensori' then
                        hideClientBlips(territoryID)
                        winnerNotification(territoryID, 'difensori')
                        print('I DIFENSORI HANNO VINTO')
                        Wait(100)
                        currentAttacks[territoryID] = nil
                        break 
                    end
                else
                    currentAttacks[territoryID].attackTimer = attackInfo.attackTimer - delay;
                    if Config.Debug then
                        print('Conquista per '..territoryID..' in corso--------')
                        print('Tempo Rimanente per la Conquista: '..tostring(attackInfo.attackTimer/1000))
                        QBCore.Debug(currentAttacks[territoryID])
                        for idx,attacker in pairs(currentAttacks[territoryID].attaccanti) do
                            print('Attaccante #'..idx..": "..attacker.citizenid);
                        end
                        for idx,defender in pairs(currentAttacks[territoryID].difensori) do
                            print('Difensore #'..idx..": "..defender.citizenid);
                        end
                        print('------------------------')
                    end
                end
            end
        else
            -- print('Nessun territorio sotto Attacco')
        end
    end

end)

function hideClientBlips(markerID)
    for k, attaccante in pairs(currentAttacks[markerID].attaccanti) do
        TriggerClientEvent('c2k_jobmanager:client:hideAttackBlip', attaccante.id, markerID)
        print('BLIP CREATO PER ID: '..tostring(attaccante.id))
    end

    for k,difensore in pairs(currentAttacks[markerID].difensori) do
        TriggerClientEvent('c2k_jobmanager:client:hideAttackBlip', difensore.id, markerID)
    end
end

function winnerNotification(markerID, winner)
    for k, attaccante in pairs(currentAttacks[markerID].attaccanti) do
        if winner == 'attaccanti' then
            TriggerClientEvent('c2k_announcement:send', attaccante.id, "","TERRITORIO CONQUISTATO!")
        else
            TriggerClientEvent('c2k_announcement:send', attaccante.id, "","CONQUISTA TERRITORIO PERSA!")
        end
    end

    for k,difensore in pairs(currentAttacks[markerID].difensori) do
        if winner == 'difensori' then
            TriggerClientEvent('c2k_announcement:send', difensore.id, "","TERRITORIO DIFESO CON SUCCESSO!")
        else
            TriggerClientEvent('c2k_announcement:send', difensore.id, "","TERRITORIO PERSO!")
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(10)
        if isEmpty(currentAttacks) == false then
            
            for territoryID, attackInfo in pairs(currentAttacks) do

                for k,attacker in pairs(currentAttacks[territoryID].attaccanti) do
                    local xPlayer = QBCore.Functions.GetPlayer(attacker.id)
                    if xPlayer.PlayerData.metadata['isdead'] == true or xPlayer.PlayerData.metadata['inlaststand'] == true then 
                        currentAttacks[territoryID].attaccanti[k].isdead = true 
                    end
                end

                for kD,defender in pairs(currentAttacks[territoryID].difensori) do
                    local xPlayer = QBCore.Functions.GetPlayer(defender.id)
                    if xPlayer.PlayerData.metadata['isdead'] == true or xPlayer.PlayerData.metadata['inlaststand'] == true then 
                        currentAttacks[territoryID].difensori[kD].isdead = true 
                    end
                end

                -- local currentOnlinePlayers = QBCore.Functions.GetQBPlayers()

                -- for k,player in pairs(currentOnlinePlayers) do
                --     if player.PlayerData.Job.name == attackInfo.defendingFaction then
                --         local alreadyExists = false
                --         for k, difensore in pairs(currentAttacks[territoryID].difensori) do
                --             if difensore.id == player.PlayerData.source then alreadyExists = true end
                --         end
                --         if alreadyExists == false then 
                --             currentAttacks[territoryID].difensori[#currentAttacks[territoryID].difensori] = {
                --                 id = player.PlayerData.source,
                --                 citizenid = player.PlayerData.citizenid,
                --                 ped = GetPlayerPed(player.PlayerData.source)
                --             }
                --         end
                --     end
                -- end
            end
        end
    end
end)

-- while true do
--     Wait(10)
--     print('INSIDE WHILE')
--     if isEmpty(currentAttacks) == false then
--         print('CONTROLLO DIFENSORI / ATTACCANTI')
--         for territoryID, attackInfo in pairs(currentAttacks) do
--             print('CURRENT ATTACKS FOR')
--             for k,attacker in pairs(currentAttacks[territoryID].attaccanti) do
--                 local xPlayer = QBCore.Functions.GetPlayer(attacker.id)
--                 QBCore.Debug(xPlayer.PlayerData.metadata)
--                 if xPlayer.PlayerData.metadata['isdead'] == true or xPlayer.PlayerData.metadata['inlaststand'] == true then 
--                     currentAttacks[territoryID].attaccanti[k].isdead = true 
--                 end
--             end

--             for kD,defender in pairs(currentAttacks[territoryID].difensori) do
--                 local xPlayer = QBCore.Functions.GetPlayer(defender.id)
--                 QBCore.Debug(xPlayer.PlayerData.metadata)
--                 if xPlayer.PlayerData.metadata['isdead'] == true or xPlayer.PlayerData.metadata['inlaststand'] == true then 
--                     print('Difensore Atterrato')
--                     currentAttacks[territoryID].difensori[kD].isdead = true 
--                 end
--             end

--             local currentOnlinePlayers = QBCore.Functions.GetQBPlayers()

--             for k,player in pairs(currentOnlinePlayers) do
--                 if player.PlayerData.Job.name == attackInfo.defendingFaction then
--                     local alreadyExists = false
--                     for k, difensore in pairs(currentAttacks[territoryID].difensori) do
--                         if difensore.id == player.PlayerData.source then alreadyExists = true end
--                     end
--                     if alreadyExists == false then 
--                         currentAttacks[territoryID].difensori[#currentAttacks[territoryID].difensori] = {
--                             id = player.PlayerData.source,
--                             citizenid = player.PlayerData.citizenid,
--                             ped = GetPlayerPed(player.PlayerData.source)
--                         }
--                     end
--                 end
--             end
--         end
--     end
-- end
