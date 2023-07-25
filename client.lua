ESX = exports['es_extended']:getSharedObject()

Queue = {}
RegisterNetEvent('almez-zone:client:JoinQueue', function (data)
    Queue = data
end)
RegisterNetEvent('almez-zone:client:QueueBool', function (bool)
    if canQue then 
        queueStarted = bool
        inQueue = false
        print("started " .. tostring(queueStarted))
    end
end)

queueStarted = false
inQueue = false
canQue = true
Citizen.CreateThread(function ()
    while true do 
        if queueStarted then
            local sleep = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(coords - ZoneConfig.queueArea)
            if distance <= 25 then
                DrawMarker(1, ZoneConfig.queueArea, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 7.5, 7.5, 2.5, 255, 255, 0, 100, false, true, 2, false, false, false, false)
                if distance <= 5 then
                    sleep = 5
                    if inQueue then 
                        ESX.Game.Utils.DrawText3D(ZoneConfig.queueText, "Press [~g~E~w~] to leave queue", 5.0, 4)
                        if IsControlJustPressed(0, 38) then
                            inQueue = false
                            TriggerServerEvent('almez-zone:server:LeaveQueue', {name = "zone"})
                        end
                    else
                        ESX.Game.Utils.DrawText3D(ZoneConfig.queueText, "Press [~g~E~w~] to enter queue", 5.0, 4)
                        if IsControlJustPressed(0, 38) then
                            inQueue = true
                            TriggerServerEvent('almez-zone:server:JoinQueue', {name = "zone"})
                        end
                    end
                    
                end
                sleep = 5
            end
            Citizen.Wait(sleep)
        else
            Citizen.Wait(1000)
        end
    end
end)

zoneData = {}
RegisterNetEvent('almez-zone:client:TeleportPlayers', function(data)
    SetEntityCoords(PlayerPedId(), data.zoneCoords)
    SetEntityHeading(PlayerPedId(), 0.0)
    zoneData = data
    gameStarted = true
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    ESX.TriggerServerCallback('almez-zone:CheckGang', function(res) 
        if res then 
            canQue = true
        end
    end)
end)

RegisterNetEvent('almez-zone:client:UpdateZone', function(data)
    if gameStarted then 
        zoneData.zoneRadius = data
    end
end)

RegisterNetEvent('almez-zone:client:sendToHub', function(data)
    if gameStarted then 
        gameStarted = false
        queueStarted = false
        zoneData = {}
        Wait(3000)
        SetEntityCoords(PlayerPedId(), ZoneConfig.hubCoords)
        TriggerEvent('esx_ambulancejob:cloudhatesmoddersrevive1209client')
        TriggerServerEvent('almez-zone:server:FixBucket')
    end
end)

RegisterNetEvent('almez-zone:client:ResetZone', function(data)
    if gameStarted then 
        print("game finished")
        SetEntityCoords(PlayerPedId(), ZoneConfig.queueArea)
        TriggerServerEvent('almez-zone:server:FixBucket')
        queueStarted = false
        gameStarted = false
        zoneData = {}
    end
end)

Citizen.CreateThread(function ()
    --draw marker with zoneRadius and zoneCoords if gameStarted
    while true do 
        if gameStarted then
            local sleep = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(coords - zoneData.zoneCoords)
            sleep = 5
            inzone = false
            DrawMarker(1, zoneData.zoneCoords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, zoneData.zoneRadius, zoneData.zoneRadius, 25.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
            if distance <= (zoneData.zoneRadius / 2)  then
                inzone = true
            end
            Citizen.Wait(sleep)
        else
            Citizen.Wait(1000)
        end
    end
end)

inzone = false
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if gameStarted then
            if not inzone then
                print("losing health")
                local ped = PlayerPedId()
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, health - 10)
            end
        end
        Citizen.Wait(sleep)
    end
end)

RegisterNetEvent('esx:onPlayerDeath', function(data)
    if gameStarted then 
        local src = source
        zoneData.players[src] = nil
        TriggerServerEvent('almez-zone:server:OnPlayerDeath')
    end
end)

--how long you want the thing to last for. in seconds.
announcestring = false
lastfor = 3
RegisterNetEvent('almez-zone:announce')
AddEventHandler('almez-zone:announce', function(msg)
	announcestring = msg
	PlaySoundFrontend(-1, "DELETE","HUD_DEATHMATCH_SOUNDSET", 1)
	Citizen.Wait(lastfor * 1000)
	announcestring = false
end)

function Initialize(scaleform)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
	PushScaleformMovieFunctionParameterString("~p~Battlezone")
    PushScaleformMovieFunctionParameterString(announcestring)
    PopScaleformMovieFunctionVoid()
    return scaleform
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if announcestring then
            scaleform = Initialize("mp_big_message_freemode")
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
        end
    end
end)