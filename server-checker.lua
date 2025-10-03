local SEARCHING_WEAPONS = 
local CHECKED_SERVERS = 
-- tables here ^

local BASE_URL = "https://raw.githubusercontent.com/kissprojects/gun-searcher/refs/heads/main"
local lobbyHandlerCode = game:HttpGet(BASE_URL.."/lobby-handler.lua")
local injectTables = loadstring(game:HttpGet(BASE_URL.."/inject_tables.lua"))()

function queueLobbyHandler()
    queue_on_teleport(injectTables(lobbyHandlerCode, {[1] = SEARCHING_WEAPONS, [2] = SEARCHING_WEAPONS}))
end

function createInfoMessageBox(text)
    local MB_ICONINFO = 0x00000040
    local MB_OKCANCEL = 0x00000001
    
    local IDOK = 1
    local IDCANCEL = 2

    local input = messagebox(
        text,
        "FOUND WEAPONS!",
        bit32.bor(MB_ICONINFO, MB_OKCANCEL)
    )
    
    return input
end


function checkPlayersWeapons()
    local foundWeapons = {}
    
    local players = game:GetService("Players"):GetPlayers()
    
    for _, player in ipairs(players) do
        local inventory = player:FindFirstChild("GunInventory")
        if inventory then
            local playerWeapons = {}
            

            for _, slotInfo in ipairs(inventory:GetChildren()) do
                if slotInfo.Value and slotInfo.Value.Name ~= "Fists" then
                    local weaponName = slotInfo.Value.Name
                    
                    for _, searchWeapon in ipairs(SEARCHING_WEAPONS) do
                        if string.find(weaponName:upper(), searchWeapon:upper()) then
                            table.insert(playerWeapons, {
                                name = weaponName,
                                ammo = string.format("[%d/%d]", 
                                    slotInfo.BulletsInMagazine.Value, 
                                    slotInfo.BulletsInReserve.Value)
                            })
                            break
                        end
                    end
                end
            end
            
            -- Если у игрока найдены нужные оружия, добавляем в список
            if #playerWeapons > 0 then
                foundWeapons[player.Name] = playerWeapons
            end
        end
    end
    
    return foundWeapons
end

function createMessageText(foundWeapons)
    local message = "FOUND STUFF THAT YOU WANTED.\n\nFound:\n"
    
    local playerEntries = {}
    for playerName, weapons in pairs(foundWeapons) do
        local weaponTexts = {}
        for _, weapon in ipairs(weapons) do
            table.insert(weaponTexts, weapon.name .. weapon.ammo)
        end
        table.insert(playerEntries, playerName .. ": " .. table.concat(weaponTexts, ", "))
    end
    
    message = message .. table.concat(playerEntries, "\n")
    message = message .. "\n\nPress \"OK\" to continue or \"Cancel\" to skip to next server."
    
    return message
end

function startNotifying()
    local Sound = Instance.new("Sound", gethui())
    Sound.SoundId = "rbxassetid://3450794184"
    Sound:Play()
    Sound.Volume = 6

    Sound.Ended:Connect(function()
        if not isrbxactive() then
            Sound:Play()
        else
            Sound:Destroy()
        end
    end)
    
    return Sound
end


function leaveToLobby()
    pcall(function()
        for _, connection in ipairs(getconnections(game.Players.LocalPlayer.PlayerGui.GameUI.Menu.MainMenu.Message.Controls.LeaveGame.MouseButton1Click)) do
            connection:Fire()
        end
    end)
end


function searchWeapons()
    while true do
        local foundWeapons = checkPlayersWeapons()
        
        if next(foundWeapons) then 
         
            local messageText = createMessageText(foundWeapons)
            

            local sound = startNotifying()
            

            local input = createInfoMessageBox(messageText)
            

            if sound then
                sound:Stop()
                sound:Destroy()
            end
            

            local IDOK = 1
            local IDCANCEL = 2
            
            if input == IDOK then
                print("Continuing on current server")
                break
            elseif input == IDCANCEL then
                print("Leaving to lobby and searching next server")
                queueLobbyHandler()
                leaveToLobby()
                break
            end
        else

            print("No desired weapons found. Leaving to lobby.")
            queueLobbyHandler()
            leaveToLobby()
            break
        end
    end
end

-- Запускаем поиск
task.spawn(function()
    task.wait(2.5)
    searchWeapons()
end)
