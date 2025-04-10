QBCore = exports['qb-core']:GetCoreObject()

local DISCORD_WEBHOOK = "webhook"
local CHECK_INTERVAL = 5000

local playerMoney = {}

function sendToDiscord(name, oldMoney, newMoney, discordId)
    local message = {
        content = "<@" .. discordId .. "> **" .. name .. "** - Eski Para: $" .. oldMoney .. " | Yeni Para: $" .. newMoney .. " | Dupe Şüphesi!",
        username = "aref-checker",
        avatar_url = ""
    }
    
    PerformHttpRequest(DISCORD_WEBHOOK, function(err, text, headers) end, 'POST', 
        json.encode(message), { ['Content-Type'] = 'application/json' })
end

function checkPlayerMoney()
    local players = QBCore.Functions.GetPlayers()
    for _, playerId in ipairs(players) do
        local xPlayer = QBCore.Functions.GetPlayer(playerId)
        if xPlayer then
            local identifier = xPlayer.PlayerData.citizenid
            local charName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
            local cash = xPlayer.PlayerData.money['cash']
            local bank = xPlayer.PlayerData.money['bank']
            local currentMoney = cash + bank
            local discordId = "BILINMIYOR"

            for k, v in pairs(GetPlayerIdentifiers(playerId)) do
                if string.find(v, "discord:") then
                    discordId = string.sub(v, 9)
                    break
                end
            end

            if playerMoney[identifier] then
                local oldMoney = playerMoney[identifier]
                if currentMoney > oldMoney and currentMoney >= 50000 then
                    local difference = currentMoney - oldMoney
                    if difference >= 50000 then
                        sendToDiscord(charName, oldMoney, currentMoney, discordId)
                    end
                end
            end
            
            playerMoney[identifier] = currentMoney
        end
    end
end

Citizen.CreateThread(function()
    while true do
        checkPlayerMoney()
        Citizen.Wait(CHECK_INTERVAL)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if xPlayer then
        playerMoney[xPlayer.PlayerData.citizenid] = nil
    end
end)