local calls = {}
local recentCalls = {}

-- Functions
exports('GetDispatchCalls', function()
    return calls
end)

function GetRecentDispatchCalls() return recentCalls end
exports('GetRecentDispatchCalls', GetRecentDispatchCalls)

-- Events
RegisterServerEvent('ps-dispatch:server:notify', function(data)
    data.id = #calls + 1
    data.time = os.time() * 1000
    data.units = {}
    data.responses = {}
    calls[#calls + 1] = data

    local recentSize = #recentCalls

    if recentSize >= Config.RecentCallsSize then
        table.remove(recentCalls, 1)
    end

    table.insert(recentCalls, data)

    TriggerClientEvent('ps-dispatch:client:notify', -1, data)
end)

RegisterServerEvent('ps-dispatch:server:attach', function(id, player)
    for i=1, #calls[id]['units'] do
        if calls[id]['units'][i]['citizenid'] == player.citizenid then return end
    end

    calls[id]['units'][#calls[id]['units'] + 1] = player
end)

RegisterServerEvent('ps-dispatch:server:detach', function(id, player)
    if not calls[id] then return end
    if not calls[id]['units'] then return end
    if (#calls[id]['units'] or 0) > 0 then
        for i = #calls[id]['units'], 1, -1 do
            if calls[id]['units'][i]['citizenid'] == player.citizenid then
                table.remove(calls[id]['units'], i)
            end
        end
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

    if timeNow - last911Used <= Config.Cooldown911 then
        return Functions.Core.Notify(source, "Please wait before using it again", "error")
    end

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

