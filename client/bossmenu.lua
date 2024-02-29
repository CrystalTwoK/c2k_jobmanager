local QBCore = exports['qb-core']:GetCoreObject();

local menuLocation = "bottomright"
local Job = "none"
local bossmenuID = ""

-- Main Menus
local menu1 = MenuV:CreateMenu(false, "BOSS MENU", menuLocation, 255, 12, 40, 'size-125', 'horde_default', 'menuv', 'test1')
local menu2 = MenuV:CreateMenu(false, "GESTIONE MEMBRI", menuLocation, 255, 12, 40, 'size-125', 'horde_default', 'menuv', 'test2')
local menu3 = MenuV:CreateMenu(false, "RECLUTA MEMBRO", menuLocation, 255, 12, 40, 'size-125', 'horde_default', 'menuv', 'test3')

local player_management = menu1:AddButton({
    label = "GESTISCI MEMBRI",
    value = menu2,
    description = "GESTISCI I MEMBRI DELLA FAZIONE"
})

local recluta_membro = menu1:AddButton({
    label = "RECLUTA MEMBRO",
    value = menu3,
    description = "RECLUTA UN NUOVO MEMBRO DELLA TUA FAZIONE"
})

player_management:On('select', function(_)
    menu2:ClearItems()
    QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getMembers', function(members)
        for idx, member in pairs(members) do

            local memberJob = {}

            print(json.encode(member.jobs))

            for jobIdx, job in pairs(member.jobs) do
                if job.name == Job then
                    memberJob = job
                    break;
                end
            end

            local clientPlayerData = QBCore.Functions.GetPlayerData()
            menu2:AddButton({
                label = '[' ..idx.. '] ' ..tostring(member.charinfo.firstname).." "..tostring(member.charinfo.lastname).." ["..memberJob.grade.level.."] - "..memberJob.grade.name,
                value = member,
                description = "SELEZIONA "..tostring(member.charinfo.firstname).." "..tostring(member.charinfo.lastname).." ["..memberJob.grade.level.."] - "..memberJob.grade.name,
                select = function(btn)
                    OpenPlayerMenus(btn.Value)
                end
                })
        end
    end, Job)
end)

recluta_membro:On('select', function(_)
    menu3:ClearItems()
    QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getPlayers', function(players)
        local playersNearby = 0
        for _, p in pairs(players) do
            playersNearby = playersNearby + 1
            local PlayerData = p.PlayerData;
            local playerIdx = GetPlayerFromServerId(PlayerData.source)
            local clientIdx = GetPlayerFromServerId(PlayerId())
            local clientPlayerData = QBCore.Functions.GetPlayerData()
            local ped = GetPlayerPed(playerIdx)
            local clientPed = GetPlayerPed(clientIdx)
            local playerCoords = GetEntityCoords(ped)
            local clientCoords = GetEntityCoords(clientPed)
            local defaultJobGrade = 0
            local distance = #(playerCoords - clientCoords)
            if distance < 3 and PlayerData.job.name ~= Job then
                menu3:AddButton({
                    label = '[' ..tostring(PlayerData.source).. '] SCONOSCIUTO',
                    value = PlayerData,
                    description = "ASSUMI LA PERSONA SELEZIONATA",
                    select = function(btn)
                        local Player = btn.Value
                        QBCore.Functions.Notify('Hai assunto una persona.')
                        -- ExecuteCommand("setjob "..Player.source.." "..Job.." "..tostring(defaultJobGrade))
                        TriggerServerEvent('c2k_jobmanager:server:setJob', Job, tostring(defaultJobGrade), Player.citizenid, true)
                    end
                })
            end

            if playersNearby == 0 then
                menu3:AddButton({
                    label = 'NESSUNA PERSONA NELLE VICINANZE',
                    value = "none",
                    description = "NESSUNA PERSONA NELLE VICINANZE",
                })
            end
        end
    end)
end)



function OpenPlayerMenus(player)
    local Players = MenuV:CreateMenu(false, player.charinfo.firstname.." "..player.charinfo.lastname, menuLocation, 255, 12, 40, 'size-125', 'horde_default', 'menuv') -- Sub Menu giocatori
    Players:ClearItems()
    MenuV:OpenMenu(Players)
    local elements = {
        [1] = {
            label = "PROMUOVI",
            value = "promuovi",
            description = "Promuovi "..player.charinfo.firstname.." "..player.charinfo.lastname
        },
        [2] = {
            label = "DEGRADA",
            value = "degrada",
            description = "Degrada "..player.charinfo.firstname.." "..player.charinfo.lastname
        },
        [3] = {
            label = "RIMUOVI",
            value = "rimuovi",
            description = "Rimuovi "..player.charinfo.firstname.." "..player.charinfo.lastname
        },
    }
    for _, v in ipairs(elements) do
        Players:AddButton({
            label = v.label,
            value = v.value,
            description = v.description,
            select = function(btn)
                local value = btn.Value
                local targetCID = player.citizenid

                if value == 'promuovi' then
                    print('PROMOSSO ID: '..targetCID)
                    TriggerServerEvent('c2k_jobmanager:server:promote', targetCID, player, Job)
                    QBCore.Functions.Notify('MEMBRO PROMOSSO')
                    MenuV:CloseMenu(Players)
                elseif value == 'degrada' then
                    print('DEGRADATO ID: '..targetCID)
                    TriggerServerEvent('c2k_jobmanager:server:demote', targetCID, player, Job)
                    QBCore.Functions.Notify('MEMBRO DEGRADATO')
                    MenuV:CloseMenu(Players)
                elseif value == 'rimuovi' then
                    print('RIMOSSO ID: '..targetCID)
                    TriggerServerEvent('c2k_jobmanager:server:removeJob', targetCID, Job)
                    QBCore.Functions.Notify('MEMBRO RIMOSSO')
                    MenuV:CloseMenu(Players)
                end
                
            end
        })
    end
end

RegisterNetEvent('c2k_jobmanager:client:openBossMenu', function(bossMenuJob, markerID)
    print("INSIDE")
    if bossMenuJob ~= 'unemployed' then
        print(bossMenuJob)
        MenuV:OpenMenu(menu1)
        Job = bossMenuJob or QBCore.Functions.GetPlayerData().job.name
        bossmenuID = markerID
    else 
        print('returnato')
        return
    end
end)