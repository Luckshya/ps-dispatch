local calls = {}
local recentCalls = {}

function _U(entry)
	return Locales[Config.Locale][entry] 
end

RegisterServerEvent("dispatch:server:notify", function(data)
	local newId = #calls + 1
	calls[newId] = data
    calls[newId]['source'] = source
    calls[newId]['callId'] = newId
    calls[newId]['units'] = {}
    calls[newId]['responses'] = {}
    calls[newId]['time'] = os.time() * 1000

    local recentSize = #recentCalls

    if recentSize >= Config.RecentCallsSize then
        table.remove(recentCalls, 1)
    end

    table.insert(recentCalls, calls[newId])

	TriggerClientEvent('dispatch:clNotify', -1, data, newId, source)
    if not data.alert then 
        TriggerClientEvent("ps-dispatch:client:AddCallBlip", -1, data.origin, dispatchCodes[data.dispatchcodename], newId)
    else
        TriggerClientEvent("ps-dispatch:client:AddCallBlip", -1, data.origin, data.alert, newId)
    end
end)

function GetRecentDispatchCalls() return recentCalls end
exports('GetRecentDispatchCalls', GetRecentDispatchCalls) -- 

function GetDispatchCalls() return calls end
exports('GetDispatchCalls', GetDispatchCalls) -- 

-- this is mdt call
AddEventHandler("dispatch:addUnit", function(callid, player, cb)
    if calls[callid] then
        if #calls[callid]['units'] > 0 then
            for i=1, #calls[callid]['units'] do
                if calls[callid]['units'][i]['cid'] == player.cid then
                    cb(#calls[callid]['units'])
                    return
                end
            end
        end

        local Player = Functions[Config.Core].GetPlayerByCitizenId(player.cid)
        if not Player then
            cb(#calls[callid]['units'])
            return
        end

        local playerData = Functions[Config.Core].GetPlayerData(Player)
        if Config.AuthorizedJobs.LEO.Check(playerData) then
            calls[callid]['units'][#calls[callid]['units']+1] = { cid = player.cid, fullname = player.fullname, job = 'Police', callsign = player.callsign }
        elseif Config.AuthorizedJobs.EMS.Check(playerData) then
            calls[callid]['units'][#calls[callid]['units']+1] = { cid = player.cid, fullname = player.fullname, job = 'EMS', callsign = player.callsign }
        end
        cb(#calls[callid]['units'])
    end
end)

AddEventHandler("dispatch:sendCallResponse", function(player, callid, message, time, cb)
    local Player = Functions[Config.Core].GetPlayer(player)
    local name = Functions[Config.Core].GetName(Player)
    if calls[callid] then
        calls[callid]['responses'][#calls[callid]['responses']+1] = {
            name = name,
            message = message,
            time = time
        }
        local player = calls[callid]['source']
        if GetPlayerPing(player) > 0 then
            TriggerClientEvent('dispatch:getCallResponse', player, message)
        end
        cb(true)
    else
        cb(false)
    end
end)

-- this is mdt call
AddEventHandler("dispatch:removeUnit", function(callid, player, cb)
    if calls[callid] then
        local newCallUnits = {}
        local oldCallUnits = calls[callid]['units']

        for k, v in ipairs(oldCallUnits) do
            if v['cid'] ~= player.cid then
                table.insert(newCallUnits, v)
            end
        end

        calls[callid]['units'] = newCallUnits
        cb(#calls[callid]['units'])
    end    
end)


RegisterCommand('togglealerts', function(source, args, user)
	local source = source
    local Player = Functions[Config.Core].GetPlayer(source)
    local playerData = Functions[Config.Core].GetPlayerData(Player)

	if Config.AuthorizedJobs.FirstResponder.Check(playerData) then
		TriggerClientEvent('dispatch:manageNotifs', source, args[1])
	end
end)

-- Explosion Handler
local ExplosionCooldown = false
AddEventHandler('explosionEvent', function(source, info)
    if ExplosionCooldown then return end

    for i = 1, (#Config.ExplosionTypes) do
        if info.explosionType == Config.ExplosionTypes[i] then
            TriggerClientEvent("ps-dispatch:client:Explosion", source)
            ExplosionCooldown = true
            SetTimeout(1500, function()
                ExplosionCooldown = false
            end)
        end
    end
end)

Functions[Config.Core].RegisterCommand("cleardispatchblips", "Clear all dispatch blips", {}, false, function(player, args)
    local playerData = Functions[Config.Core].GetPlayerData(player)

    if Config.AuthorizedJobs.FirstResponder.Check(playerData) then
        TriggerClientEvent('ps-dispatch:client:clearAllBlips', src)
    end
end)