local calls = {}
local callCount = 0
local callIds = {}

-- Functions
exports('GetDispatchCalls', function()
    return calls
end)

-- Events
RegisterServerEvent('ps-dispatch:server:notify', function(data)
    callCount = callCount + 1
    data.callId = callCount
    data.id = callCount
    data.source = source
    data.time = os.time() * 1000
    data.units = {}
    data.responses = {}

    if #callIds >= Config.MaxCallList then
        calls[callIds[1]] = nil
        table.remove(callIds, 1)
    end

    calls[callCount] = data

    TriggerClientEvent('ps-dispatch:client:notify', -1, data)
end)

RegisterServerEvent('ps-dispatch:server:attach', function(id, player, cb)
    if not calls[id] then return end

    for j = 1, #calls[id]['units'] do
        if calls[id]['units'][j]['citizenid'] == player.citizenid then
            return
        end
    end
    
    calls[id]['units'][#calls[id]['units'] + 1] = player
    if cb then cb('ok') end
end)

RegisterServerEvent('ps-dispatch:server:detach', function(id, player, cb)
    if not calls[id] then return end

    for j = 1, #calls[id]['units'] do
        if calls[id]['units'][j]['citizenid'] == player.citizenid then
            table.remove(calls[id]['units'], j)
        end
    end

    if cb then cb('ok') end
end)

AddEventHandler("ps-dispatch:server:sendCallResponse", function(player, callid, message, time, cb)
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
            TriggerClientEvent('ps-dispatch:client:getCallResponse', player, message)
        end
        cb(true)
    else
        cb(false)
    end
end)

-- Callbacks
lib.callback.register('ps-dispatch:callback:getLatestDispatch', function(source)
    return calls[#calls]
end)

lib.callback.register('ps-dispatch:callback:getCalls', function(source)
    return calls
end)

-- Commands
lib.addCommand('dispatch', {
    help = locale('open_dispatch')
}, function(source, raw)
    TriggerClientEvent("ps-dispatch:client:openMenu", source, calls)
end)

local last911Used = 0
lib.addCommand('911', {
    help = 'Send a message to 911',
    params = { { name = 'message', type = 'string', help = '911 Message' }},
}, function(source, args, raw)
    local timeNow = os.time()

    -- if timeNow - last911Used <= Config.Cooldown911 then
    --     return Functions.Core.Notify(source, "Please wait before using it again", "error")
    -- end

    last911Used = timeNow

    local fullMessage = raw:sub(5)
    TriggerClientEvent('ps-dispatch:client:sendEmergencyMsg', source, fullMessage, "911", false)
end)
lib.addCommand('911a', {
    help = 'Send an anonymous message to 911',
    params = { { name = 'message', type = 'string', help = '911 Message' }},
}, function(source, args, raw)
    local timeNow = os.time()

    if timeNow - last911Used <= Config.Cooldown911 then
        return Functions.Core.Notify(source, "Please wait before using it again", "error")
    end

    last911Used = timeNow

    local fullMessage = raw:sub(5)
    TriggerClientEvent('ps-dispatch:client:sendEmergencyMsg', source, fullMessage, "911", true)
end)

local last311Used = 0
lib.addCommand('311', {
    help = 'Send a message to 311',
    params = { { name = 'message', type = 'string', help = '311 Message' }},
}, function(source, args, raw)
    local timeNow = os.time()

    if timeNow - last311Used <= Config.Cooldown311 then
        return Functions.Core.Notify(source, "Please wait before using it again", "error")
    end

    last311Used = timeNow

    local fullMessage = raw:sub(5)
    TriggerClientEvent('ps-dispatch:client:sendEmergencyMsg', source, fullMessage, "311", false)
end)

lib.addCommand('311a', {
    help = 'Send an anonymous message to 311',
    params = { { name = 'message', type = 'string', help = '311 Message' }},
}, function(source, args, raw)
    local timeNow = os.time()

    if timeNow - last311Used <= Config.Cooldown311 then
        return Functions.Core.Notify(source, "Please wait before using it again", "error")
    end

    last311Used = timeNow

    local fullMessage = raw:sub(5)
    TriggerClientEvent('ps-dispatch:client:sendEmergencyMsg', source, fullMessage, "311", true)
end)

