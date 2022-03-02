ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterNetEvent("kn:boombox:soundStatus")
AddEventHandler("kn:boombox:soundStatus", function(type, musicId, data)
    TriggerClientEvent("kn:boombox:soundStatus", -1, type, musicId, data)
end)

RegisterNetEvent("kn:boombox:syncConfig")
AddEventHandler("kn:boombox:syncConfig", function(config)
    TriggerClientEvent("kn:boombox:syncConfig", -1, config)
end)