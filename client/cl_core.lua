Core = nil

if Config.Core == "QBCore" then Core = exports['qb-core']:GetCoreObject()
elseif Config.Core == "ESX" then Core = exports['es_extended']:getSharedObject() end

Functions = {}

-- QBCore
Functions.QBCore = {}
Functions.QBCore.GetPlayerData = function()
    return Core.Functions.GetPlayerData()
end
Functions.QBCore.GetGender = function(playerData)
    return playerData.charinfo.gender
end
Functions.QBCore.GetOnDuty = function(playerData)
    return playerData.job.onduty
end
Functions.QBCore.Notify = function(...)
    Core.Functions.Notify(...)
end
Functions.QBCore.GetName = function(playerData)
    return playerData.charinfo.firstname, playerData.charinfo.lastname
end
Functions.QBCore.HasPhone = function()
    return Core.Functions.HasItem("phone")
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
Functions.ESX.GetPlayerData = function()
    local playerData = Core.PlayerData
    if playerData and playerData.job then
        playerData.job.type = "unknown"
    end

    return playerData
end
Functions.ESX.GetGender = function(playerData)
    return playerData.sex == "m" and 0 or 1
end
Functions.ESX.GetOnDuty = function()
    return true
end
Functions.ESX.Notify = function(...)
    Core.ShowNotification(...)
end

local esxFirstName = nil
local esxLastName = nil

Functions.ESX.GetName = function(playerData)
    return (playerData.firstName or esxFirstName or ""), (playerData.lastName or esxLastName or "")
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

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        isLoggedIn = true
        PlayerData = Functions[Config.Core].GetPlayerData()
        PlayerJob = PlayerData.job

        if Config.Core == "ESX" then
            Functions.ESX.LoadPlayerName()
        end
    end
end)

function onPlayerLoaded()
    -- Create Hunting Zone Blips --
	if not Config.Locations['hunting'][1] then return end
	for _, hunting in pairs(Config.Locations["hunting"]) do
		local blip = AddBlipForCoord(hunting.coords.x, hunting.coords.y, hunting.coords.z)
		local huntingradius = AddBlipForRadius(hunting.coords.x, hunting.coords.y, hunting.coords.z, hunting.radius)
		SetBlipSprite(blip, 442)
		SetBlipAsShortRange(blip, true)
		SetBlipScale(blip, 0.8)
		SetBlipColour(blip, 0)
		SetBlipColour(huntingradius, 0)
		SetBlipAlpha(huntingradius, 40)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(hunting.label)
		EndTextCommandSetBlipName(blip)
	end
end

function onPlayerUnload()
    local blip = GetFirstBlipInfoId(442)
  repeat RemoveBlip(blip); blip = GetNextBlipInfoId(442) until not DoesBlipExist(blip)
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    isLoggedIn = true
    PlayerData = Functions[Config.Core].GetPlayerData()
    PlayerJob = PlayerData.job

    onPlayerLoaded()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isLoggedIn = false
    currentCallSign = ""

    onPlayerUnload()
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(JobInfo)
    PlayerData = Functions[Config.Core].GetPlayerData()
    PlayerJob = JobInfo
end)

AddEventHandler('esx:setPlayerData', function(key, val, last)
    if GetInvokingResource() == 'es_extended' then
        PlayerData[key] = val
        Core.PlayerData[key] = val
        PlayerJob = Core.PlayerData.job
    end
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    Core.PlayerData = xPlayer
    Core.PlayerLoaded = true
    isLoggedIn = true
    PlayerJob = xPlayer.job

    Functions.ESX.LoadPlayerName()
    onPlayerLoaded()
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    PlayerData = {}
    Core.PlayerLoaded = false
    Core.PlayerData = {}
    isLoggedIn = false

    onPlayerUnload()
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerJob = job
    PlayerData.job = job
    Core.PlayerData.job = job
end)