local QBCore = exports['qb-core']:GetCoreObject()

local Jobs = {}

QBCore.Commands.Add("jobmanager", "Apri il Job Manager", {}, false, function(source)
    local src = source
    TriggerClientEvent('c2k_jobmanager:client:openMenu', source)
end, "dev")

QBCore.Commands.Add("syncqbjobs", "Sincronizza i lavori del di QB-CORE con il Job Manager", {}, false, function(source)
    local src = source
    TriggerEvent('c2k_jobmanager:server:syncQBJobs')
end, "dev")

QBCore.Commands.Add("listjobs", "Fai una lista dei Job", {}, false, function(source)
    QBCore.Debug(Jobs)
end, "dev")

RegisterNetEvent('c2k_jobmanager:server:addJob', function(newJobID, newJobData)
    if newJobData.grades == nil then newJobData.grades = {} end
    MySQL.insert.await('INSERT INTO `c2k_jobs` (`name`, `label`, `grades`,`author`, `defaultDuty`, `offDutyPay`) VALUES (?, ?, ?, ?, ?, ?)', { newJobID, newJobData.label, json.encode(newJobData.grades), GetPlayerName(source) or 'SERVER', true, false})

    TriggerEvent('c2k_jobmanager:server:syncJobs')

    if source then
        QBCore.Functions.Notify(source, "Lavoro inserito con successo!")
    end

end)

RegisterNetEvent('c2k_jobmanager:server:deleteJob', function(jobID)
    MySQL.query('DELETE FROM `c2k_jobs` WHERE name = ?', {jobID})

    TriggerEvent('c2k_jobmanager:server:syncJobs')

    QBCore.Functions.Notify(source, "Lavoro eliminato con successo!")
end)

RegisterNetEvent('c2k_jobmanager:server:updateJob', function(jobID, newJobData)

    MySQL.Async.execute("UPDATE `c2k_jobs` SET grades = @grades, label = @label WHERE name = @name", {
        ['@grades'] = json.encode(newJobData.grades), 
        ['@label'] = newJobData.label, 
        ['@name'] = jobID
    }, 
    function(result)
        if result == 1 then
            Wait(100)
            TriggerEvent('c2k_jobmanager:server:syncJobs')
        else
            TriggerClientEvent('QBCore:Notify', source, "ERRORE NEL DATABASE NELL'AGGIORNAMENTO DEL LAVORO")
        end
    end)
    
end)

RegisterNetEvent('c2k_jobmanager:server:syncJobs', function()

    local jobs = MySQL.query.await('SELECT * FROM c2k_jobs', {})

    for k,job in ipairs(jobs) do    
        local jobData = {
            label = job.label,
            defaultDuty = job.defaultDuty,
            offDutyPay = job.offDutyPay,
            grades = json.decode(job.grades)
        }

        Jobs[job.name] = jobData
    end

    TriggerClientEvent('c2k_jobmanager:client:updateSharedJobs', -1)

    TriggerClientEvent('c2k_jobmanager:client:updateNUIJobs', -1)

end)

RegisterNetEvent('c2k_jobmanager:server:syncQBJobs', function()

    local dbJobs = MySQL.query.await('SELECT * FROM c2k_jobs', {})

    local jobsToSync = {}

    -- QBCore.Debug(QBCore.Shared.Jobs)

    for jobID, currentJobData in pairs(Jobs) do

        local alreadyPresent = false

        local jobData = {}

        for k, dbJob in pairs(dbJobs) do

            if jobID == dbJob.name then 
                alreadyPresent = true 
                jobData = false
            end

            if alreadyPresent == false then
                jobData = {
                    name = jobID,
                    label = currentJobData.label, 
                    defaultDuty = currentJobData.defaultDuty, 
                    offDutyPay = currentJobData.offDutyPay, 
                    grades = currentJobData.grades
                }
            end

        end
        
        if jobData then 
            QBCore.Debug(jobData)
            jobsToSync[jobData.name] = {
                label = jobData.label,
                defaultDuty = jobData.defaultDuty,
                offDutyPay = jobData.offDutyPay,
                grades = jobData.grades
            }
        end

    end

    Wait(10)

    for jobID, jobData in pairs(jobsToSync) do
        TriggerEvent('c2k_jobmanager:server:addJob', jobID, jobData)
    end
end)

QBCore.Functions.CreateCallback('c2k_jobmanager:callback:getJobs', function(source, cb)
    cb(Jobs)
end)

function jobsList()
    return Jobs
end

exports("jobsList", jobsList)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end

    TriggerEvent('c2k_jobmanager:server:syncJobs')

    print('[' .. string.upper(resourceName) .. '] avviato con successo.')
end)