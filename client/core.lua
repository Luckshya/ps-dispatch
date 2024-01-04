Core = nil

if Config.Core == "QBCore" then Core = exports['qb-core']:GetCoreObject()
elseif Config.Core == "ESX" then Core = exports['es_extended']:getSharedObject() end

Functions = {}

-- QBCore
Functions.QBCore = {}
Functions.QBCore.UpdateCachedPlayerData = function()
    local playerInfo = Functions.QBCore.GetPlayerData()
    PlayerData = {
        charinfo = {
            firstname = playerInfo.charinfo.firstname,
            lastname = playerInfo.charinfo.lastname
        },
        metadata = {
            callsign = playerInfo.metadata.callsign
        },
        citizenid = playerInfo.citizenid,
        job = {
            type = playerInfo.job.type,
            name = playerInfo.job.name,
            label = playerInfo.job.label
        },
    }

    return PlayerData
end
Functions.QBCore.GetCachedPlayerData = function()
    return PlayerData
end
Functions.QBCore.GetPlayerData = function()
    return Core.Functions.GetPlayerData()
end
Functions.QBCore.GetGender = function(playerData)
    return playerData.charinfo.gender == 1 and 'Female' or 'Male'
end
Functions.QBCore.GetOnDuty = function(playerData)
    return playerData.job.onduty
end
Functions.QBCore.Notify = function(msg, type, ...)
    lib.notify({ description = msg, position = 'top', type = type })
    -- Core.Functions.Notify(msg, type, ...)
end
Functions.QBCore.GetName = function(playerData)
    return playerData.charinfo.firstname, playerData.charinfo.lastname
end
Functions.QBCore.GetFormattedName = function(playerData)
    local firstname, lastname = Functions.QBCore.GetName(playerData or Functions.QBCore.GetPlayerData())
    return firstname:sub(1,1):upper()..firstname:sub(2) .. " ".. lastname:sub(1,1):upper()..lastname:sub(2)
end
Functions.QBCore.HasPhone = function()
    for _, item in ipairs(Config.PhoneItems) do
        if Core.Functions.HasItem(item) then
            return true
        end
    end
    return false
end
Functions.QBCore.GetPhoneNumber = function(playerData)
    return playerData.charinfo.phone
end
Functions.QBCore.GetCallSign = function(playerData)
    return playerData.metadata["callsign"]
end
Functions.QBCore.IsHandcuffed = function()
    return exports['qb-policejob']:IsHandcuffed()
end

-- ESX
Functions.ESX = {}
Functions.ESX.UpdateCachedPlayerData = function()
    local playerInfo = Functions.ESX.GetPlayerData()
    PlayerData = {
        charinfo = {
            firstname = playerInfo.charinfo.firstname,
            lastname = playerInfo.charinfo.lastname
        },
        metadata = {
            callsign = playerInfo.metadata.callsign
        },
        citizenid = playerInfo.citizenid,
        job = {
            type = playerInfo.job?.type,
            name = playerInfo.job?.name,
            label = playerInfo.job?.label
        },
    }

    return PlayerData
end

Functions.ESX.GetPlayerData = function()
    local playerData = Core.PlayerData
    if playerData then
        playerData.citizenid = playerData.identifier
        playerData.metadata = { callsign = Functions.ESX.GetCallSign() }

        local firstname, lastname = Functions.ESX.GetName(playerData)
        playerData.charinfo = { firstname = firstname, lastname = lastname }
        
        if playerData.job then
            playerData.job.type = Config.ESXJobTypeMap[playerData.job.name] or "unknown"
        end
    end

    return playerData
end
Functions.ESX.GetCachedPlayerData = function()
    return Functions.ESX.GetPlayerData()
end
Functions.ESX.GetGender = function(playerData)
    return playerData.sex == "m" and 'Male' or 'Female'
end
Functions.ESX.GetOnDuty = function()
    return true
end
Functions.ESX.Notify = function(msg, type, ...)
    lib.notify({ description = msg, position = 'top', type = type })
    -- Core.ShowNotification(msg, type, ...)
end

local esxFirstName = nil
local esxLastName = nil

Functions.ESX.GetName = function(playerData)
    return (playerData.firstName or esxFirstName or ""), (playerData.lastName or esxLastName or "")
end
Functions.ESX.GetFormattedName = function(playerData)
    local firstname, lastname = Functions.ESX.GetName(playerData or Functions.ESX.GetPlayerData())
    return firstname:sub(1,1):upper()..firstname:sub(2) .. " ".. lastname:sub(1,1):upper()..lastname:sub(2)
end
Functions.ESX.HasPhone = function()
    return true
end
Functions.ESX.GetPhoneNumber = function()
    return ''
end
Functions.ESX.GetCallSign = function()
    return ''
end
Functions.ESX.IsHandcuffed = function()
    return false
end
Functions.ESX.LoadPlayerName = function()
    Core.TriggerServerCallback('ps-dispatch:server:esx:getPlayerName', function(firstName, lastName)
        esxFirstName = firstName
        esxLastName = lastName
    end)
end

AddEventHandler('esx:setPlayerData', function(key, val, last)
    if GetInvokingResource() == 'es_extended' then
        Core.PlayerData[key] = val
        PlayerData = Functions.Core.UpdateCachedPlayerData()
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    Core.PlayerData = xPlayer

    Functions.ESX.LoadPlayerName()
    setupDispatch()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    PlayerData = {}
    Core.PlayerData = {}

    removeZones()
end)

RegisterNetEvent('esx:setJob', function(job)
    Core.PlayerData.job = job

    setupDispatch()
end)

Functions.Core = Functions[Config.Core]