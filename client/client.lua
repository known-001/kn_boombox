ESX = nil
local activeBoomBox = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

xSound = exports.xsound

RegisterNetEvent("kn:boombox:soundStatus")
AddEventHandler("kn:boombox:soundStatus", function(type, musicId, data)
    Citizen.CreateThread(function()
        if type == "position" then
            if xSound:soundExists(musicId) then
                xSound:Position(musicId, data.position)
            end
        end
    
        if type == "play" then
            xSound:PlayUrlPos(musicId, data.link, data.volume, data.position)
            xSound:Distance(musicId, data.distance)
            xSound:setVolume(musicId, data.volume)
        end

        if type == "volume" then
            xSound:setVolume(musicId, data.volume)
        end
    
        if type == "stop" then
            xSound:Destroy(musicId)
        end
    end)
end)

local cooldown = false

function openMenu(data)
    if not cooldown then 
        cooldown = true
        if not Config.Speakers[data.id].data.playing then 
            local elements = {}
            table.insert(elements, {id = 1, header = "Speaker (id: "..data.id..")", txt = '', params = {event = "kn:boombox:playMenu", args = {type = 'play', id = data.id}}})
            table.insert(elements, {id = 2, header = 'Play Music', txt = 'Play Music On Speaker', params = {event = "kn:boombox:playMenu", args = {type = 'play', id = data.id}}})
            TriggerEvent('nh-context:sendMenu', elements)
        else
            local elements = {}
            table.insert(elements, {id = 1, header = "Speaker (id: "..data.id..")", txt = '', params = {event = "kn:boombox:playMenu", args = {type = 'play', id = data.id}}})
            table.insert(elements, {id = 1, header = "Stop Music", txt = 'Stop Music', params = {event = "kn:boombox:playMenu", args = {type = 'stop', id = data.id}}})
            table.insert(elements, {id = 2, header = "Change Volume", txt = 'Change Music Volume', params = {event = "kn:boombox:playMenu", args = {type = 'volume', id = data.id}}})
            table.insert(elements, {id = 3, header = "Change Distance", txt = 'Change Music Distance', params = {event = "kn:boombox:playMenu", args = {type = 'distance', id = data.id}}})      
            TriggerEvent('nh-context:sendMenu', elements)
        end
        cooldown = false
    end
end

RegisterNetEvent('kn:boombox:playMenu')
AddEventHandler('kn:boombox:playMenu',function(data)
    local musicId = 'id_'..data.id
    if data.type == 'play' then
        local keyboard, url, distance, volume = exports["nh-keyboard"]:Keyboard({
            header = "Play Music", 
            rows = {"Youtube URL", "Distance (Max 40)", "Volume (0.0 -1.0)"}
        })
    
        if keyboard then
            if url and tonumber(distance) <= 40 and tonumber(volume) <= 1.0 then
                TriggerServerEvent("kn:boombox:soundStatus", "play", musicId, { position = Config.Speakers[data.id].pos, link = url, volume = volume, distance = distance })
                Config.Speakers[data.id].data = {playing = true, currentId = 'id_'..PlayerId()}
                TriggerServerEvent('kn:boombox:syncConfig', Config)
            end
        end
    elseif data.type == 'stop' then
        TriggerServerEvent("kn:boombox:soundStatus", "stop", musicId, {})
        Config.Speakers[data.id].data = {playing = false}
        TriggerServerEvent('kn:boombox:syncConfig', Config)
    elseif data.type == 'volume' then
        local keyboard, volume = exports["nh-keyboard"]:Keyboard({
            header = "Change Volume", 
            rows = {"Volume (0.0 -1.0)"}
        })
    
        if keyboard then
            if tonumber(volume) and tonumber(volume) <= 1.0 then
                TriggerServerEvent("kn:boombox:soundStatus", "volume", musicId, {volume = volume})
            end
        end
    elseif data.type == 'distance' then
        local keyboard, distance = exports["nh-keyboard"]:Keyboard({
            header = "Change Distance", 
            rows = {"Distance (Max 40)"}
        })
    
        if keyboard then
            if tonumber(distance) and tonumber(distance) <= 40 then
                TriggerServerEvent("kn:boombox:soundStatus", "distance", musicId, {distance = distance})
            end
        end
    end
end)

RegisterNetEvent('kn:boombox:syncConfig')
AddEventHandler('kn:boombox:syncConfig', function(config)
    Config = config
end)

--BOOM BOX

RegisterNetEvent('kn:boombox:settings')
AddEventHandler('kn:boombox:settings',function(data)
    openMenu({id = ObjToNet(data.entity), boombox = true})
end)

RegisterCommand('boombox', function(source, args)
    TriggerEvent('kn:boombox:boombox')
end)

RegisterNetEvent('kn:boombox:boombox')
AddEventHandler('kn:boombox:boombox',function()
    startAnimation("anim@heists@money_grab@briefcase","put_down_case")
    Citizen.Wait(1000)
    ClearPedTasks(PlayerPedId())
    ESX.Game.SpawnObject("prop_boombox_01", GetEntityCoords(PlayerPedId()), function(obj)
        SetEntityHeading(obj, GetEntityHeading(PlayerPedId()))
        PlaceObjectOnGroundProperly(obj)
        TriggerServerEvent('kn:extraitems:useSpeaker', false)

        Config.Speakers[obj] = {
            id = ObjToNet(obj),
            pos = GetEntityCoords(obj),
            boombox = true,
            data = {playing = false}
        }

        TriggerServerEvent('kn:boombox:syncConfig', Config)
    end)
end)

RegisterNetEvent('kn:boombox:pickUp')
AddEventHandler('kn:boombox:pickUp',function(data)
    ESX.Game.DeleteObject(NetToObj(data.entity))
    Config.Speakers[NetToObj(data.entity)] = nil
    if xSound:soundExists('id'_..NetToObj(data.entity)) then
        TriggerEvent('kn:boombox:playMenu', {id = objToNet(data.entity), type = 'stop'})
    end
    TriggerServerEvent('kn:extraitems:useSpeaker', true)
    TriggerServerEvent('kn:boombox:syncConfig', Config)
end)

function startAnimation(lib,anim)
    ESX.Streaming.RequestAnimDict(lib, function()
        TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end)
end

Citizen.CreateThread(function()
    exports.qtarget:AddTargetModel({"prop_boombox_01"}, {
        options = {
            {
                event = "kn:boombox:settings",
                icon = "fas fa-box-circle-check",
                label = "Boom Box Settings",
            },
            {
                event = "kn:boombox:pickUp",
                icon = "fas fa-box-circle-check",
                label = "Pick Up",
            },
        },
        distance = 2
    })
end)