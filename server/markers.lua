local QBCore = exports['qb-core']:GetCoreObject();

QBCore.Commands.Add("creamarkerfazione", "Crea un Marker privato", {{name = "Tipologia", help = "'deposito', 'vestiti', 'outfit', 'garage', 'boss'"}, {name = "Fazione", help = "Fazione a cui legare il marker"}, {name = "Gradi", help = "'tutti' per tutti gradi"}, {name = "Veicoli", help = "'Inserisci lista veicolo solo in caso di un Garage. Divisi da una virgola"}}, false, function(source, args)
    local src = source
    
    if args then
        if args[1] and args[2] then
            if Config.Debug then QBCore.Debug(args) end
            local _type = args[1]:lower()
            local job = args[2]:lower()
            if args[3] ~= nil then 
                local seriale = math.random(100000, 999999)
                local markerID = args[1].."_"..args[2].."_"..seriale
                local ped = GetPlayerPed(source)
                local coords = GetEntityCoords(ped)
                local sprite = "horde_default";
                local label = 'INTERAGISCI';
                local img = 'https://i.imgur.com/CInzFzP.png'
                local Jobs = exports['c2k_jobmanager']:jobsList()
                local roles = {}

                if _type == "deposito" then
                    if job == 'hexa' then sprite = 'hexa_1'; img = 'https://i.imgur.com/QL8WWiY.png' else sprite = 'horde_3' end
                    label = 'APRI DEPOSITO'
                    TriggerEvent('c2k_jobmanager:server:registerStashes', markerID, seriale, coords)
                elseif _type == "vestiti" then
                    if job == 'hexa' then sprite = 'hexa_3'; img = 'https://i.imgur.com/QL8WWiY.png'  else sprite = 'horde_4' end
                    label = 'MENU VESTITI'
                elseif _type == 'outfit' then
                    if job == 'hexa' then sprite = 'hexa_3'; img = 'https://i.imgur.com/QL8WWiY.png' else sprite = 'horde_4' end
                    label = 'MENU OUTFIT'
                elseif _type == 'boss' then
                    if job == 'hexa' then sprite = 'hexa_4'; img = 'https://i.imgur.com/QL8WWiY.png' else sprite = 'horde_5' end
                    label = 'BOSS MENU'
                elseif _type == 'garage' then
                    if job == 'hexa' then sprite = 'hexa_5'; img = 'https://i.imgur.com/QL8WWiY.png' else sprite = 'horde_7' end
                    label = 'GARAGE'
                    TriggerEvent('c2k_jobmanager:server:registerGarage', markerID, args[4] or Config.Markers.Garages.DefaultCar, coords, GetEntityHeading(ped))
                else return end
                
                if args[3] == 'tutti' then

                    for k, grade in pairs(Jobs[job].grades) do
                        roles[#roles + 1] = tonumber(k)
                    end

                    salvaMarkerDB(_type, markerID, coords, sprite, label, job, roles, seriale, img)
                    creaMarker(_type, markerID, coords, sprite, label, job, roles, img)
                elseif args[3] ~= 'tutti' then
                    
                    for role in string.gmatch(args[3], '([^,]+)') do
                        table.insert(roles, tonumber(role))
                    end

                    salvaMarkerDB(_type, markerID, coords, sprite, label, job, roles, seriale, img)
                    creaMarker(_type, markerID, coords, sprite, label, job, roles, img)
                end
            else
                TriggerClientEvent('QBCore:Notify', source, 'Non hai inserito i gradi a cui consentire accesso!')
            end

        else
            TriggerClientEvent('QBCore:Notify', source, 'Inserisci tutti i parametri richiesti!')
        end
    end

end, "dev")

QBCore.Commands.Add("eliminamarker", "Elimina il marker piu' vicino a te nel raggio di 1.5 metri", {}, false, function(source, args)
    local src = source
    TriggerClientEvent('c2k_jobmanager:client:deleteCloserMarker', src)
end, "dev")

RegisterNetEvent('c2k_jobmanager:server:registerStashes', function(markerID, seriale, coords)
    exports.ox_inventory:RegisterStash(markerID, 'Deposito '..seriale, Config.Markers.Stashes.Slots, Config.Markers.Stashes.MaxWeight, nil, nil, coords)
end)

RegisterNetEvent('c2k_jobmanager:server:eliminaMarkerDB', function(markerID)
    local markers = MySQL.query.await('SELECT * FROM c2k_markers WHERE markerid = ?', {markerID})
    if markers[1] then
        local result = MySQL.query('DELETE FROM `c2k_markers` WHERE markerid = ?', {markerID})
        TriggerClientEvent('c2k_interactions:client:deleteMarker', -1, markerID)
        TriggerClientEvent('QBCore:Notify', source, "Marker eliminato con successo!")
    elseif markers[1] == nil then 
        TriggerClientEvent('QBCore:Notify', source, "Impossibile eliminare il marker. Probabilmente inserito da script!") 
    end
end)

QBCore.Functions.CreateCallback('c2k_jobmanager:callback:getMarkers', function(_, cb)
    local markers = MySQL.query.await('SELECT * FROM c2k_markers', {})
    cb(markers)
end)

function salvaMarkerDB(_type, markerID, pos, sprite, label, jobName, roles, seriale, img)
    MySQL.insert.await('INSERT INTO `c2k_markers` (`type`, `markerid`, `position`, `sprite`, `label`, `jobname`, `roles`, `seriale`, `img`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {_type, markerID, json.encode(pos), sprite, label, jobName, json.encode(roles), seriale, img})

end

function creaMarker(_type, markerID, pos, sprite, label, jobName, roles, img)
    TriggerClientEvent('c2k_jobmanager:client:markers:createMarker', -1, _type, markerID, pos, sprite, label, jobName, roles, img)

end

function eliminaMarker(markerID)
    TriggerEvent('c2k_interactions:server:deleteMarker', -1, markerID)

end