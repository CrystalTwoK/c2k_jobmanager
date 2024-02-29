local QBCore = exports['qb-core']:GetCoreObject()

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
TriggerServerEvent('c2k_jobmanager:server:syncJobs')
end)

RegisterNetEvent('c2k_jobmanager:client:openMenu', function()

    TriggerServerEvent('c2k_jobmanager:server:syncJobs')

    QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getJobs', function(serverJobs)
        
        local Jobs = {}

        for jobID,jobData in pairs(serverJobs) do
            Jobs[#Jobs + 1] = {
                id = jobID,
                label = jobData.label,
                grades = jobData.grades,
                author = jobData.author,
            }
            
        end

        SendNUIMessage({
            type = 'openMenu',
            jobs = Jobs
        })

        SetNuiFocus(true, true)

    end)
end)

RegisterNetEvent('c2k_jobmanager:client:updateNUIJobs', function()
    QBCore.Functions.TriggerCallback('c2k_jobmanager:callback:getJobs', function(serverJobs)

        local Jobs = {}

        for jobID,jobData in pairs(serverJobs) do
            Jobs[#Jobs + 1] = {
                id = jobID,
                label = jobData.label,
                grades = jobData.grades,
                author = jobData.author
            }

        end

        SendNUIMessage({
            type = 'updateJobs',
            jobs = Jobs
        })

    end)
end)

RegisterNUICallback('addJob', function(data, cb)
    local newJob = {
        label = data.newJobName,
        defaultDuty = true,
		offDutyPay = false,
        grades = {}
    }

    TriggerServerEvent('c2k_jobmanager:server:addJob', data.newJobID, newJob)
end)

RegisterNUICallback('updateJob', function(data, cb)

    local newGrades = {}

    local newJobData = {
        label = data.newJobData.label,
        newID = data.newJobData.id,
        defaultDuty = true,
		offDutyPay = false,
        grades = {}
    }

    for idx, jobData in pairs(data.newJobData.grades) do
        print('IDX: '..tostring(idx))
        newJobData.grades[tostring(idx)] = {
            name = jobData.name,
            payment = jobData.payment,
            isboss = jobData.isboss
        }
    end

    TriggerServerEvent('c2k_jobmanager:server:updateJob', data.selectedJobID, newJobData)

end)

RegisterNUICallback('deleteJob', function(data, cb)

    TriggerServerEvent('c2k_jobmanager:server:deleteJob', data.jobToDelete)

end)

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
end)