local QBCore = exports['qb-core']:GetCoreObject();

-- QBCore.Commands.Add("bossmenu", "Crea un territorio", {}, false, function(source, args)
--     TriggerClientEvent('c2k_jobmanager:client:openBossMenu', source)
-- end, "dev")

QBCore.Functions.CreateCallback('c2k_jobmanager:callback:getMembers', function(_, cb, job)
    
    -- local members = MySQL.query.await("SELECT * FROM players WHERE JSON_EXTRACT(jobs, '$[*].name') = ?", {job})
    local members = MySQL.query.await('SELECT * FROM players WHERE JSON_CONTAINS(jobs, \'{"name": "'..job..'"}\')')

    -- QBCore.Debug(members)

    local decodedMembers = {}

    for key, player in ipairs(members) do
        decodedMembers[key] = {
            citizenid = player.citizenid,
            license = player.license,
            name = player.name,
            metadata = player.metadata,
            charinfo = json.decode(player.charinfo),
            job = json.decode(player.job),
            jobs = json.decode(player.jobs)
        }
    end

    cb(decodedMembers)
end)

QBCore.Functions.CreateCallback('c2k_jobmanager:callback:getPlayers', function(_, cb)

    local Players = {}

    for idx, playersrc in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(playersrc)
        -- local pedCoords = GetEntityCoords(GetPlayerPed(playersrc))
        -- local localPedCoords = GetEntityCoords(GetPlayerPed(source))
        -- local distance = #(pedCoords - localPedCoords)
        -- if distance < 3.0 then
            Players[#Players + 1] = Player
        -- end
    end

    cb(Players)
end)

RegisterNetEvent('c2k_jobmanager:server:setJob', function(jobName, jobGrade, targetCID, setJobNow)
    if setJobNow == nil then setJobNow = false end
    if targetCID then
        local xPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCID)

        local jobs = exports['c2k_jobmanager']:jobsList()

        local stringtoboolean={ ["true"]=true, ["false"]=false }

        local targetJob = jobs[jobName]
        local targetJobName = jobName

        local jobGradeName = targetJob.grades[tostring(jobGrade)].name

        if jobGradeName == nil then
            jobGrade = 0
            jobGradeName = targetJob.grades[tostring(jobGrade)].name
        end

        local newJobData = {
            type = "none",
            onduty = true,
            name = targetJobName,
            label = targetJob.label,
            grade = {
                level = jobGrade, 
                name = jobGradeName
            },
            isboss = stringtoboolean[jobs[targetJobName].grades[tostring(jobGrade)].isboss],
            payment = jobs[targetJobName].grades[tostring(jobGrade)].payment
        }

        MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', {json.encode(newJobData), targetCID})
        

        if xPlayer and setJobNow then
            xPlayer.Functions.SetJob(jobName, jobGrade)
            xPlayer.Functions.SetJobDuty(true)
        end

        -- QBCore.Debug('JOBMANAGER JOBDATA: '..newJobData)
        if jobName ~= 'unemployed' then
            TriggerEvent('c2k_multijob:server:syncJob', targetJobName, newJobData, targetCID, nil)
        end
    end
end)

RegisterNetEvent('c2k_jobmanager:server:promote', function(targetCID, targetData, jobName)

    local Target = QBCore.Functions.GetPlayerByCitizenId(targetCID)

    local jobs = exports['c2k_jobmanager']:jobsList()

    local targetJob = {}
    for k, job in pairs(targetData.jobs) do
        if job.name == jobName then
            targetJob = job
            break;
        end
    end
    print('TARGET JOB')
    QBCore.Debug(targetJob)

    local targetJobName = targetJob.name

    local stringtoboolean={ ["true"]=true, ["false"]=false }

    local newGrade = targetJob.grade.level + 1;
    -- local newGradeName = jobs[targetJobName].grades[tostring(newGrade)].name;
    -- if newGradeName == nil then 
    --     newGrade = targetJob.grade.level
    --     newGradeName = targetJob.grade.name
    -- end
    -- local newGradeIsBoss = stringtoboolean[jobs[targetJobName].grades[tostring(newGrade)].isboss];
    -- local newGradePayment = jobs[targetJobName].grades[tostring(newGrade)].payment;

    -- local newJobData = {
    --     type = targetJob.type,
    --     onduty = true,
    --     name = targetJobName,
    --     label = targetJob.label,
    --     grade = {
    --         level = newGrade, 
    --         name = newGradeName
    --     },
    --     isboss = newGradeIsBoss,
    --     payment = newGradePayment
    -- }

    TriggerEvent('c2k_jobmanager:server:setJob', targetJobName, newGrade, targetCID, false)

    if Target then
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, "["..targetJob.label.."] Hai ricevuto una promozione!")
    end
end)

RegisterNetEvent('c2k_jobmanager:server:demote', function(targetCID, targetData, jobName)

    local Target = QBCore.Functions.GetPlayerByCitizenId(targetCID)

    local targetJob = {}
    for k, job in pairs(targetData.jobs) do
        if job.name == jobName then
            targetJob = job
            break;
        end
    end
    local targetJobName = targetJob.name

    local stringtoboolean={ ["true"]=true, ["false"]=false }

    local newGrade = targetJob.grade.level - 1;
    local jobs = exports['c2k_jobmanager']:jobsList()
    local newGradeName = jobs[targetJobName].grades[tostring(newGrade)].name;
    -- if newGrade < 0 then 
    --     newGrade = targetJob.grade.level
    --     newGradeName = targetJob.grade.name
    -- end
    -- local newGradeIsBoss = stringtoboolean[jobs[targetJobName].grades[tostring(newGrade)].isboss];
    -- local newGradePayment = jobs[targetJobName].grades[tostring(newGrade)].payment;

    -- local newJobData = {
    --     type = targetJob.type,
    --     onduty = targetJob.onduty,
    --     name = targetJobName,
    --     label = targetJob.label,
    --     grade = {level = newGrade, name = newGradeName},
    --     isboss = newGradeIsBoss,
    --     payment = newGradePayment
    -- }

    TriggerEvent('c2k_jobmanager:server:setJob', targetJobName, newGrade, targetCID, false)

    if Target then
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, "["..targetJob.label.."] Sei stato degradato!")
    end
end)

RegisterNetEvent('c2k_jobmanager:server:removeJob', function(targetCID, jobName)

    local Target = QBCore.Functions.GetPlayerByCitizenId(targetCID)

    local jobs = exports['c2k_jobmanager']:jobsList();
    local stringtoboolean={ ["true"]=true, ["false"]=false }

    local targetJobName = "unemployed"

    local newGrade = 0;

    TriggerEvent('c2k_multijob:server:removeJob', jobName, targetCID)
    TriggerEvent('c2k_jobmanager:server:setJob', targetJobName, newGrade, targetCID, true)

    if Target then
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, "["..jobs[jobName].label.."] Lavoro Rimosso!")
    end
end)