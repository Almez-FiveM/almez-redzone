ESX = exports['es_extended']:getSharedObject()
Queues = {}
QueBucket = 12
started = false
gameStarted = false
lastWinned = false 
Citizen.CreateThread(function()
    TriggerEvent('almez-zone:server:RegisterQueue', 'zone', {
        name = 'zone',
        maxPlayers = 64,
        players = {},
    })
    while true do 
        Citizen.Wait(60 * 1000 * 50 --[[ 50 minutes ]])
        if started then
            started = false
            if not lastWinned then 
                TriggerClientEvent('almez-zone:client:QueueBool', -1, false)
                print("Game Ended WITH TIMER")
                TriggerClientEvent('almez-zone:announce', -1, "Battle Zone is finished by timer! No one won the game!")
                gameStarted = false
                Queues = {}
                TriggerClientEvent('almez-zone:client:ResetZone', -1)
                TriggerEvent('almez-zone:server:RegisterQueue', 'zone', {
                    name = 'zone',
                    maxPlayers = 64,
                    players = {},
                })
            end
        else
            started = true
            TriggerClientEvent('almez-zone:client:QueueBool', -1, true)
            print("Queue Started WITH TIMER")
            TriggerClientEvent('almez-zone:announce', -1, "STARTING IN 5 MINUTE GO TO 201 POSTAL TO QUE UP!")
            Citizen.Wait(60 * 1000 * 5 --[[ 5 minutes ]])
            print("Game Started WITH TIMER")
            for k, v in pairs(Queues["zone"].players) do
                if v then
                    TriggerClientEvent('cS.Countdown', k, 255, 255, 255, 45, true)
                    SetPlayerRoutingBucket(k, QueBucket)
                    gameStarted = true
                    GameData = {
                        zoneRadius = ZoneConfig.zoneRadius,
                        zoneCoords = ZoneConfig.zoneCoords[math.random(1, #ZoneConfig.zoneCoords)],
                        players = Queues["zone"].players,
                    }
                    TriggerClientEvent('almez-zone:client:TeleportPlayers', k, GameData)
                end
            end
            Queues["zone"] = nil
        end
    end
end)

RegisterCommand('battlezone', function(source, args, raw)
    started = true
    TriggerClientEvent('almez-zone:client:QueueBool', -1, true)
    print("Queue Started WITH TIMER")
    TriggerClientEvent('almez-zone:announce', -1, "STARTING IN 5 MIN GO TO 201 POSTAL TO QUE UP!")

    Wait(60 * 1000 * 5 --[[ 5 minutes ]])
    print("Game Started WITH TIMER")
    local coords = math.random(1, #ZoneConfig.zoneCoords)
    for k, v in pairs(Queues["zone"].players) do
        if v then
            TriggerClientEvent('cS.Countdown', k, 255, 255, 255, 45, true)
            SetPlayerRoutingBucket(k, QueBucket)
            gameStarted = true
            GameData = {
                zoneRadius = ZoneConfig.zoneRadius,
                zoneCoords = ZoneConfig.zoneCoords[coords],
                players = Queues["zone"].players,
            }
            TriggerClientEvent('almez-zone:client:TeleportPlayers', k, GameData)
        end
    end
    Queues["zone"] = nil
end, true)

RegisterServerEvent('almez-zone:server:FixBucket')
AddEventHandler('almez-zone:server:FixBucket', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

RegisterServerEvent('almez-zone:server:RegisterQueue')
AddEventHandler('almez-zone:server:RegisterQueue', function(name, data)
    if Queues[name] == nil then
        Queues[name] = data
        print(name .. ' has been registered. (' .. json.encode(data) .. ')')
    end
end)

RegisterServerEvent('almez-zone:server:UnregisterQueue')
AddEventHandler('almez-zone:server:UnregisterQueue', function(name)
    if Queues[name] ~= nil then
        Queues[name] = nil
    end
end)

RegisterServerEvent('almez-zone:server:UpdateQueue')
AddEventHandler('almez-zone:server:UpdateQueue', function(name, data)
    if Queues[name] ~= nil then
        Queues[name] = data
    end
end)

RegisterServerEvent('almez-zone:server:JoinQueue')
AddEventHandler('almez-zone:server:JoinQueue', function(data)
    local src = source
    if gameStarted then return end
    if Queues[data.name] ~= nil then
        Queues[data.name].players[src] = true
        TriggerClientEvent('almez-zone:client:JoinQueue', src, Queues[data.name])
        if Queues[data.name].players ~= nil then
            print(json.encode(Queues))
            local players = 0
            for k, v in pairs(Queues[data.name].players) do
                if v then
                    players = players + 1
                end
            end
            print(players .. ' / ' .. Queues[data.name].maxPlayers)
            if players >= Queues[data.name].maxPlayers then
                local coords = math.random(1, #ZoneConfig.zoneCoords)
                for k, v in pairs(Queues[data.name].players) do
                    if v then 
                        TriggerClientEvent('cS.Countdown', k, 255, 255, 255, 45, true)
                        SetPlayerRoutingBucket(k, QueBucket)
                        gameStarted = true
                        GameData = {
                            zoneRadius = ZoneConfig.zoneRadius,
                            zoneCoords = ZoneConfig.zoneCoords[coords],
                            players = Queues[data.name].players,
                        }
                        TriggerClientEvent('almez-zone:client:TeleportPlayers', k, GameData)
                    end
                end
                Queues[data.name] = nil
            end
        end
    end
end)

RegisterCommand('bucketcheck', function (source)
    local src = source
    local bucket = GetPlayerRoutingBucket(src)
    print(bucket, "bucket checked")    
end)

RegisterServerEvent('almez:server:LeaveQueue')
AddEventHandler('almez:server:LeaveQueue', function(data)
    local src = source
    if Queues[data.name] ~= nil then
        Queues[data.name].players[src] = nil
        TriggerClientEvent('almez:client:LeaveQueue', src)
    end
end)

RegisterServerEvent('almez-zone:server:OnPlayerDeath')
AddEventHandler('almez-zone:server:OnPlayerDeath', function()
    local src = source
    local players = 0
    if gameStarted then
        if GameData.players[src] == nil then return end
        GameData.players[src] = nil
        TriggerClientEvent('almez-zone:client:sendToHub', src)
        print("Somebody died in zone!")
    
        for k, v in pairs(GameData.players) do
            if v then
                players = players + 1
            end
        end
        print(players.." player still in ga")
        if players < 2 then
            print("Game Ended WITH LAST PLAYER WIN")
            lastWinned = true
            gameStarted = false
            Queues = {}
            TriggerClientEvent('almez-zone:client:ResetZone', -1)
            TriggerEvent('almez-zone:server:RegisterQueue', 'zone', {
                name = 'zone',
                maxPlayers = 64,
                players = {},
            })
            local lastPlayer = 0
            for k, v in pairs(GameData.players) do
                if v then
                    lastPlayer = k
                end
            end
            TriggerClientEvent('almez-zone:announce', -1, "(ID: "..lastPlayer..") " .. GetPlayerName(lastPlayer) .. " won the game!")
            if ZoneConfig.rewards["items"] then 
                for k, v in pairs(GameData.players) do
                    if v then
                        local xPlayer = ESX.GetPlayerFromId(k)
                        for i = 1, #ZoneConfig.rewards["items"] do
                            xPlayer.addInventoryItem(ZoneConfig.rewards["items"][i].item, ZoneConfig.rewards["items"][i].amount)
                        end
                    end
                end
            end
            if ZoneConfig.rewards["money"] then
                for k, v in pairs(GameData.players) do
                    if v then
                        local xPlayer = ESX.GetPlayerFromId(k)
                        xPlayer.addMoney(ZoneConfig.rewards["money"])
                    end
                end
            end
        -- else
        --     local crewWithPlayers = {}
        --     for k, v in pairs(GameData.players) do
        --         if v then
        --             local crew = exports['esx_gangs']:getPlayerGang(k)
        --             if crew ~= nil then
        --                 if crewWithPlayers[crew] == nil then
        --                     crewWithPlayers[crew] = {
        --                         crew = crew,
        --                         players = 1,
        --                     }
        --                 else
        --                     crewWithPlayers[crew].players = crewWithPlayers[crew].players + 1
        --                 end
        --             end
        --         end
        --     end

        --     if #crewWithPlayers < 2 then
        --         print("Game Ended WITH LAST CREW WIN")
        --         TriggerClientEvent('almez-zone:announce', -1, string.upper(crewWithPlayers[1].crew).. " GANG HAS WON BATTLE ZONE")
        --         if ZoneConfig.rewards["items"] then 
        --             for k, v in pairs(ZoneConfig.rewards["items"]) do
        --                 exports['esx_gangs']:addGangItem(v.item, v.amount, crewWithPlayers[1].crew)
        --             end
        --         end
        --         if ZoneConfig.rewards["money"] > 0 then 
        --             exports['esx_gangs']:addGangMoney(ZoneConfig.rewards["money"], crewWithPlayers[1].crew)
        --         end

        --         lastWinned = true
        --         gameStarted = false
        --         Queues = {}
        --         TriggerClientEvent('almez-zone:client:ResetZone', -1)
        --         TriggerEvent('almez-zone:server:RegisterQueue', 'zone', {
        --             name = 'zone',
        --             maxPlayers = 64,
        --             players = {},
        --         })
        --     end
        end
    end
end)

GameData = {}

Citizen.CreateThread(function()
    while true do
        local sleep = 500
        if gameStarted then 
            if GameData.zoneRadius > 15.0 then
                GameData.zoneRadius = GameData.zoneRadius - 0.17
                TriggerClientEvent('almez-zone:client:UpdateZone', -1, GameData.zoneRadius)
            end
        end
        Citizen.Wait(sleep)
    end
end)

ESX.RegisterServerCallback('almez-zone:CheckGang', function(source, cb)
    local src = source
    local gang = exports['esx_gangs']:getPlayerGang(src)
    if gang ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

RegisterCommand('specbucket', function(source)
    local src = source
    print(src)
    SetPlayerRoutingBucket(src, QueBucket)
end, true)

RegisterCommand('specdefault', function(source)
    local src = source
    SetPlayerRoutingBucket(src, 0)
end, true)