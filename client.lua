-- Variables principales
local inArena = false
local currentArena = nil
local gunfightPed = nil
local hud = {kills = 0, deaths = 0}
local isDead = false
local spawnCoords = vector3(250.97, -777.16, 30.86) -- spawn normal
local arenaBlip = nil -- Blip de zone PvP

-- Nouvelle variable pour vMenu/noclip
local disableVMenu = false

-- Génère des coordonnées aléatoires dans le radius d'une arène
local function getRandomCoordsInArena(arena)
    local angle = math.rad(math.random(0, 360))
    local distance = math.random() * (arena.radius - 2.0)
    local offsetX = math.cos(angle) * distance
    local offsetY = math.sin(angle) * distance
    return vector3(arena.coord.x + offsetX, arena.coord.y + offsetY, arena.coord.z)
end

-- Crée le blip de zone
local function createArenaBlip(arena)
    if arenaBlip then RemoveBlip(arenaBlip) end
    arenaBlip = AddBlipForRadius(arena.coord.x, arena.coord.y, arena.coord.z, arena.radius)
    SetBlipColour(arenaBlip, 1) -- rouge
    SetBlipAlpha(arenaBlip, 80) -- transparence
end

-- Supprime le blip de zone
local function removeArenaBlip()
    if arenaBlip then
        RemoveBlip(arenaBlip)
        arenaBlip = nil
    end
end

-- Activer/Désactiver spawn auto
local function toggleAutoSpawn(state)
    exports.spawnmanager:setAutoSpawn(state)
    exports.spawnmanager:setAutoSpawnCallback(function() end)
end

-- Thread pour bloquer VMenu/Noclip quand inArena
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if disableVMenu then
            DisableControlAction(0, 289, true) -- F2 Noclip
            DisableControlAction(0, 170, true) -- F5 Menu
            DisableControlAction(0, 166, true) -- F5 alternative
            TriggerEvent('vMenu:disableMenu', true)
        else
            TriggerEvent('vMenu:disableMenu', false)
        end
    end
end)

-- Spawn PNJ entrée arène
Citizen.CreateThread(function()
    local model = GetHashKey(Config.PedModel)
    RequestModel(model)
    local t = GetGameTimer()
    while not HasModelLoaded(model) and (GetGameTimer() - t) < 5000 do Citizen.Wait(10) end
    gunfightPed = CreatePed(4, model, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z, Config.SpawnHeading, false, true)
    FreezeEntityPosition(gunfightPed, true)
    SetEntityInvincible(gunfightPed, true)
    SetBlockingOfNonTemporaryEvents(gunfightPed, true)

    while true do
        Citizen.Wait(0)
        local p = PlayerPedId()
        local pcoords = GetEntityCoords(p)
        local d = #(pcoords - Config.SpawnPoint)

        -- Interaction PNJ
        if d < 50.0 then
            DrawMarker(1, Config.SpawnPoint.x, Config.SpawnPoint.y, Config.SpawnPoint.z - 1.0, 0,0,0, 0,0,0, 1.0,1.0,0.2, 50,200,255, 100, false, true, 2, false, nil, nil, false)
            if d < Config.InteractDistance then
                SetTextComponentFormat('STRING')
                AddTextComponentString('Appuyez sur ~INPUT_CONTEXT~ pour rejoindre une arène PvP')
                DisplayHelpTextFromStringLabel(0,0,1,-1)
                if IsControlJustReleased(0, 38) then
                    TriggerEvent('pvp:openArenaMenu')
                end
            end
        end

        if inArena then
            -- HUD PvP moderne en haut d'écran
            -- Fond principal arrondi avec transparence
            DrawRect(0.5, 0.08, 0.35, 0.08, 0, 0, 0, 120)
            
            -- Bordure rouge subtile
            DrawRect(0.5, 0.04, 0.35, 0.002, 187, 0, 10, 200)
            DrawRect(0.5, 0.12, 0.35, 0.002, 187, 0, 10, 200)
            
            -- Titre PVP ARENA centré
            SetTextScale(0.45, 0.45)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextColour(187, 0, 10, 255)
            SetTextEntry("STRING")
            AddTextComponentString("PVP ARENA")
            SetTextCentre(true)
            DrawText(0.5, 0.045)
            
            -- Section Kills (gauche)
            SetTextScale(0.4, 0.4)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextColour(46, 204, 113, 255)
            SetTextEntry("STRING")
            AddTextComponentString("KILLS: " .. tostring(hud.kills))
            SetTextCentre(true)
            DrawText(0.4, 0.075)
            
            -- Section Deaths (droite)
            SetTextScale(0.4, 0.4)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextColour(231, 76, 60, 255)
            SetTextEntry("STRING")
            AddTextComponentString("DEATHS: " .. tostring(hud.deaths))
            SetTextCentre(true)
            DrawText(0.6, 0.075)
            
            -- Instructions de sortie en bas du HUD
            SetTextScale(0.32, 0.32)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextColour(255, 255, 255, 180)
            SetTextEntry("STRING")
            AddTextComponentString("Appuyez sur ~r~E~w~ pour quitter")
            SetTextCentre(true)
            DrawText(0.5, 0.095)

            -- Marqueur au sol + blocage sortie
            if currentArena and Config.Arenas and Config.Arenas[currentArena] then
                local a = Config.Arenas[currentArena]
                DrawMarker(1, a.coord.x, a.coord.y, a.coord.z - 1.0, 0,0,0, 0,0,0, a.radius * 2.0, a.radius * 2.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)

                if #(pcoords - a.coord) > a.radius then
                    SetEntityCoords(p, a.coord.x, a.coord.y, a.coord.z)
                    TriggerEvent('chat:addMessage', { args = {"PvP", "^1Vous ne pouvez pas sortir de la zone !"} })
                end
            end
            
            -- Permettre de quitter avec E
            if IsControlJustReleased(0, 38) then -- E key
                inArena = false
                currentArena = nil
                disableVMenu = false
                RemoveAllPedWeapons(PlayerPedId(), true)
                toggleAutoSpawn(true)
                SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z)
                removeArenaBlip()
                TriggerEvent('chat:addMessage', { args = {"PvP", "^2Vous avez quitté le PvP."} })
            end
        end
    end
end)

-- Menu choix arène (texte)
RegisterNetEvent('pvp:openArenaMenu')
AddEventHandler('pvp:openArenaMenu', function()
    print("Opening arena menu...")
    -- Ouvrir l'interface NUI moderne
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openArenaMenu",
        arenas = Config.Arenas
    })
    print("NUI message sent")
end)

-- Callbacks NUI
RegisterNUICallback("selectArena", function(data, cb)
    print("selectArena callback received with data:", json.encode(data))
    local arenaIndex = tonumber(data.index)
    print("Arena selected: " .. tostring(arenaIndex)) -- Debug
    if arenaIndex and Config.Arenas[arenaIndex] then
        print("Valid arena found, joining arena " .. arenaIndex)
        TriggerServerEvent("pvp:joinArena", arenaIndex)
        SetNuiFocus(false, false)
        cb("ok")
    else
        print("Invalid arena index: " .. tostring(arenaIndex))
        cb("error")
    end
end)

RegisterNUICallback("closeMenu", function(_, cb)
    print("closeMenu callback received")
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Entrée arène
RegisterNetEvent('pvp:forceJoinClient')
AddEventHandler('pvp:forceJoinClient', function(arenaIndex, arenaData)
    local a = arenaData
    inArena = true
    currentArena = arenaIndex
    hud.kills = 0
    hud.deaths = 0
    toggleAutoSpawn(false)
    disableVMenu = true

    DoScreenFadeOut(200)
    Citizen.Wait(250)

    local spawnPos = getRandomCoordsInArena(a)
    SetEntityCoords(PlayerPedId(), spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), a.heading or 0.0)

    Citizen.Wait(200)
    DoScreenFadeIn(200)

    GiveWeaponToPed(PlayerPedId(), GetHashKey(Config.GunWeapon), 250, false, true)
    SetPedAmmo(PlayerPedId(), GetHashKey(Config.GunWeapon), 250)

    createArenaBlip(a)

    TriggerServerEvent('pvp:playerEnteredArena', arenaIndex)
    TriggerEvent('chat:addMessage', { args = {"PvP", "^2Vous avez rejoint l'arène " .. a.name .. " !"} })
end)

-- Quitter PvP
RegisterCommand("quitpvp", function()
    if inArena then
        inArena = false
        currentArena = nil
        disableVMenu = false
        RemoveAllPedWeapons(PlayerPedId(), true)
        toggleAutoSpawn(true)
        SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z)
        removeArenaBlip()
        TriggerEvent('chat:addMessage', { args = {"PvP", "^2Vous avez quitté le PvP."} })
    else
        TriggerEvent('chat:addMessage', { args = {"PvP", "^1Vous n'êtes pas en PvP."} })
    end
end)

-- Gestion morts
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)
        local ped = PlayerPedId()
        if not isDead and IsEntityDead(ped) then
            isDead = true
            local killer = GetPedSourceOfDeath(ped)
            local killerServerId = nil
            if killer and killer ~= 0 then
                local killerPlayer = NetworkGetPlayerIndexFromPed(killer)
                if killerPlayer and killerPlayer ~= -1 then
                    killerServerId = GetPlayerServerId(killerPlayer)
                end
            end
            TriggerServerEvent('pvp:playerDied', killerServerId, currentArena)
        elseif isDead and not IsEntityDead(ped) then
            isDead = false
        end
    end
end)

-- Respawn en arène
RegisterNetEvent('pvp:respawnInArenaClient')
AddEventHandler('pvp:respawnInArenaClient', function(arenaIndex, arenaData)
    local a = arenaData
    Citizen.Wait(Config.RespawnDelay)
    local ped = PlayerPedId()
    isDead = false

    local spawnPos = getRandomCoordsInArena(a)
    SetEntityCoords(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
    SetEntityHeading(ped, a.heading or 0.0)

    NetworkResurrectLocalPlayer(spawnPos.x, spawnPos.y, spawnPos.z, a.heading or 0.0, true, false)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastDamageBone(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))

    GiveWeaponToPed(ped, GetHashKey(Config.GunWeapon), 250, false, true)
    SetPedAmmo(ped, GetHashKey(Config.GunWeapon), 250)
end)

-- Mise à jour HUD
RegisterNetEvent('pvp:updateHud')
AddEventHandler('pvp:updateHud', function(kills, deaths)
    hud.kills = kills
    hud.deaths = deaths
end)

-- Bloque commande noclip pendant arène
RegisterCommand("noclip", function()
    if disableVMenu then
        TriggerEvent('chat:addMessage', { args = {"PvP", "^1Le noclip est désactivé en arène !"} })
        return
    end
end, false)