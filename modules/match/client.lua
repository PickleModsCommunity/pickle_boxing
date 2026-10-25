Matches = {}
LocalMatches = {}

local refPed = nil
local currentMatchArea

function OpenFighterSettings(index, cb)
    lib.callback("pickle_boxing:getFighterSettings", "", function(result)
        local options = {
            {type = 'input', label = _L("fighter_settings_name"), default = result.name},
            {type = 'number', label = _L("fighter_settings_age"), default = result.age},
            {type = 'number', label = _L("fighter_settings_weight"), default = result.weight},
            {type = 'input', label = _L("fighter_settings_height"), default = result.height},
            {type = 'input', label = _L("fighter_settings_emote_intro"), default = result.emoteIntro},
            {type = 'input', label = _L("fighter_settings_emote_win"), default = result.emoteWin},
            {type = 'input', label = _L("fighter_settings_emote_loss"), default = result.emoteLoss},
        }
        if result.image then
            options[#options + 1] = {type = 'checkbox', label = _L("fighter_settings_retake_photo"), default = false}
        end
        local input
        input = lib.inputDialog(_L("fighter_settings_title"), options)
        if not input then cb(nil); return end
        local info = {
            name = input[1] or result.name,
            image = result.image,
            age = input[2] or result.age,
            weight = input[3] or result.weight,
            height = input[4] or result.height,
            emoteIntro = input[5] or result.emoteIntro,
            emoteWin = input[6] or result.emoteWin,
            emoteLoss = input[7] or result.emoteLoss,
        }
        if input[8] or not info.image then
            StartPhoto({ coords = GetEntityCoords(PlayerPedId()), heading = GetEntityHeading(PlayerPedId()) }, function(url)
                info.image = url or info.image
                cb(info)
            end)
        else
            cb(info)
        end
    end, index)
end

function AttemptJoinMatch(index)
    lib.callback("pickle_boxing:canJoinMatch", "", function(result)
        if not result then
            ShowNotification(_L("no_perm_join"))
            return 
        end
        OpenFighterSettings(index, function(info)
            if not info then return end
            lib.callback("pickle_boxing:attemptJoinMatch", "", function(result, notification)
                if notification then
                    ShowNotification(notification)
                end
            end, index, info)
        end)
    end, index)
end

function ToggleReadyFight()
    TriggerServerEvent("pickle_boxing:toggleReadyFight")
end

function OpenViewFight(index, recursive)
    LocalMatches[index].viewingFight = true
    local match = Matches[index]
    if not match then return end
    if match.game and not recursive then 
        ShowNotification(_L("match_active"))
        SetTimeout(250, function()
            OpenMatchInteraction(index)
        end)
        return
    end
    local options = {
        {
            title = _L("fighters") .. ":",
        },
    }
    local serverId = GetPlayerServerId(PlayerId())
    local isFighter = false
    for i=1, #match.fighterPositions do 
        if match.fighters[i] then
            local readyText = (match.fighters[i].ready and (match.fighters[i].source == serverId and _L("ready_interact") or _L("ready")) or ( match.fighters[i].source == serverId and _L("not_ready_interact") or _L("not_ready")))
            local onSelect = nil
            if  match.fighters[i].source == serverId then
                onSelect = ToggleReadyFight
                isFighter = true
            end
            options[#options + 1] = {
                title = match.fighters[i].name .. " - " .. readyText,
                description = _L("record", match.fighters[i].record.wins, match.fighters[i].record.losses, match.fighters[i].record.ties),
                onSelect = onSelect
            }
        else
            local title = _L("fighter_join_slot")
            local onSelect = function() AttemptJoinMatch(index) end
            if isFighter then
                title = _L("fighter_empty_slot")
                onSelect = nil
            end
            options[#options + 1] = {
                title = title,
                onSelect = onSelect
            }
        end
    end
    lib.registerContext({
        id = 'view_fight',
        title = _L("match_view_fight"),
        options = options,
        onExit = function() 
            LocalMatches[index].viewingFight = nil
            SetTimeout(250, function()
                OpenMatchInteraction(index)
            end)
        end
    })
    lib.showContext('view_fight')
end

function OpenStatistics(index)
    local match = Matches[index]
    if not match then return end
    lib.callback("pickle_boxing:getTopFighters", "", function(fighters)
        local options = {}
        for i=1, #fighters do 
            options[#options + 1] = {
                title = fighters[i].name,
                description = _L("record", fighters[i].record.wins, fighters[i].record.losses, fighters[i].record.ties)
            }
        end
        lib.registerContext({
            id = 'match_statistics',
            title = _L("match_statistics"),
            options = options,
            onExit = function() 
                SetTimeout(250, function()
                    OpenMatchInteraction(index)
                end)
            end
        })
        lib.showContext('match_statistics')
    end)
end

function OpenSettings(index)
    local match = Matches[index]
    if not match then return end
    lib.callback("pickle_boxing:canManageMatch", "", function(result)
        if not result then 
            ShowNotification(_L("no_match_management")) 
            SetTimeout(250, function()
                OpenMatchInteraction(index)
            end)
            return
        end
        local settings = match.settings
        local options = {
            {type = 'number', label = _L("match_settings_rounds"), default = settings.rounds},
            {type = 'number', label = _L("match_settings_round_length"), default = settings.roundLength},
            {type = 'select', label = _L("match_settings_fight_type"), options = { {label = _L("boxing"), value = "boxing"}, {label = _L("mma"), value = "mma"} }, default = settings.fightType},
            {type = 'input', label = _L("match_settings_event_name"), default = settings.event},
        }
        local input = lib.inputDialog(_L("fighter_settings_title"), options)
        if not input then return end
        TriggerServerEvent("pickle_boxing:updateMatchSettings", index, {
            rounds = tonumber(input[1]),
            roundLength = tonumber(input[2]),
            fightType = input[3],
            event = input[4],
        })
        SetTimeout(250, function()
            OpenMatchInteraction(index)
        end)
    end, index)
end

function OpenMatchInteraction(index)
    local match = Matches[index]
    if not match then return end
    lib.registerContext({
        id = 'match_interact',
        title = _L("match_interaction"),
        options = {
            {
                title = _L("match_view_fight"),
                description = _L("match_view_fight_desc"),
                onSelect = function()
                    SetTimeout(250, function()
                        OpenViewFight(index)
                    end)
                end
            },
            {
                title = _L("match_statistics"),
                description = _L("match_statistics_desc"),
                onSelect = function()
                    SetTimeout(250, function()
                        OpenStatistics(index)
                    end)
                end
            },
            {
                title = _L("match_settings"),
                description = _L("match_settings_desc"),
                onSelect = function()
                    SetTimeout(250, function()
                        OpenSettings(index)
                    end)
                end
            },
        },
    })
     
    lib.showContext('match_interact')
end

function StartIntroRingStage(matchId)
    local match = Matches[matchId]
    if not match then return end
    local serverId = GetPlayerServerId(PlayerId())
    local ped = PlayerPedId()
    for i=1, #match.fighters do 
        if match.fighters[i].source == serverId then
            local coords = match.fighterPositions[i].coords
            local heading = match.fighterPositions[i].heading
            FreezeEntityPosition(ped, true)
            SetEntityCoords(ped, coords.x, coords.y, coords.z)
            SetEntityHeading(ped, heading)
            break
        end
    end
    StartRotateScene(match.center.coords, match.center.heading, match.center.distance or 7.0)
    SetTimeout(2000, function()
        SendNUIMessage({
            type = "showStats",
            data = {
                fighters = match.fighters,
                event = match.settings.event or "Main Event"
            }
        })
    end)
    SetTimeout(7500, function()
        SendNUIMessage({
            type = "hideStats"
        })
        Wait(500)
        FreezeEntityPosition(ped, false)
    end)
end

function StartEndMatchStage(matchId, fighters, force)
    local participant=false
    for _,f in ipairs(fighters or {}) do if f.source==GetPlayerServerId(PlayerId()) then participant=true end end
    if not participant then return end
    if force then
        StopScene()
        StopFightThread()
        RemoveBoxingGlove()
        ClearPedTasksImmediately(PlayerPedId())
        FreezeEntityPosition(PlayerPedId(), false)
        if refPed then
            DeleteEntity(refPed)
            refPed = nil
        end
    else
        local match = Matches[matchId]
        if not match then return end
        local serverId = GetPlayerServerId(PlayerId())
        local ped = PlayerPedId()
        local model = {
            hash = `U_M_M_SpyActor`,
            components = {
                {0, 0}, -- "HEAD"
                {0, 0}, -- "BEARD"
                {0, 0}, -- "HAIR"
                {0, 0}, -- "UPPER"
                {0, 0}, -- "LOWER"
                {0, 0}, -- "HAND"
                {0, 0}, -- "FEET"
                {0, 0}, -- "TEETH"
                {0, 0}, -- "ACCESSORIES"
                {0, 0}, -- "TASK"
                {0, 0}, -- "DECL"
                {0, 0}, -- "JBIB"
            }
        }
        local coords = match.center.coords
        local heading = match.center.heading
        refPed = CreateNPC(model.hash, coords.x, coords.y, coords.z, heading, false, true)
        if not refPed then return end
        if model.components then
            for i=1, #model.components do 
                SetPedComponentVariation(refPed, i - 1, model.components[i][1] or 0, model.components[i][2] or 0, model.components[i][3] or 0)
            end
        end

        for i=1, #fighters do 
            if fighters[i].source == serverId then
                local coords = GetOffsetFromEntityInWorldCoords(refPed, (i == 1 and 1.0 or -1.0), 0.0, -2.0)
                local heading = match.center.heading
                FreezeEntityPosition(ped, true)
                SetEntityCoords(ped, coords.x, coords.y, coords.z)
                SetEntityHeading(ped, heading)
                SetTimeout(5000, function()
                    ExecuteCommand(Config.EmoteCommandPrefix .. " " .. (fighters[i].winner and fighters[i].emoteWin or fighters[i].emoteLoss))
                end)
            end
        end
        StartFighterScene(refPed)
        SetTimeout(10000, function()
            StopScene()
            StopFightThread()
            RemoveBoxingGlove()
            ClearPedTasksImmediately(PlayerPedId())
            FreezeEntityPosition(PlayerPedId(), false)
            DeleteEntity(refPed)
            refPed = nil
        end)
    end
end

function StartIntroFighterStage(matchId, fighterId)
    local match = Matches[matchId]
    if not match then return end
    local serverId = GetPlayerServerId(PlayerId())
    local ped = PlayerPedId()
    for i=1, #match.fighters do 
        if match.fighters[i].source == serverId then
            local coords = match.fighterPositions[i].coords
            local heading = match.fighterPositions[i].heading
            FreezeEntityPosition(ped, true)
            SetEntityCoords(ped, coords.x, coords.y, coords.z)
            SetEntityHeading(ped, heading)
        end
        if fighterId == i then
            if serverId == match.fighters[fighterId].source then 
                SetTimeout(2600, function()
                    ExecuteCommand(Config.EmoteCommandPrefix .. " " .. match.fighters[fighterId].emoteIntro)
                end)
            end
            StartFighterScene(GetPlayerPed(GetPlayerFromServerId(match.fighters[i].source)), match.fighters[i].emoteIntro)
        end
    end
    SetTimeout(2000, function()
        SendNUIMessage({
            type = "showFighterStats",
            data = match.fighters[fighterId]
        })
    end)
    SetTimeout(7000, function()
        SendNUIMessage({
            type = "hideFighterStats"
        })
        Wait(500)
    end)
end

function StartFightRoundStage(matchId, roundId)
    local match = Matches[matchId]
    if not match then return end
    if sceneActive then
        StopScene()
    end
    local serverId = GetPlayerServerId(PlayerId())
    local ped = PlayerPedId()
    for i=1, #match.fighters do 
        if match.fighters[i].source == serverId then
            local coords = match.fighterPositions[i].coords
            local heading = match.fighterPositions[i].heading
            FreezeEntityPosition(ped, true)
            SetTimeout(2000, function()
                FreezeEntityPosition(ped, false)
            end)
            SetEntityCoords(ped, coords.x, coords.y, coords.z)
            SetEntityHeading(ped, heading)
            CreateFightThread()
            if match.settings.fightType == "boxing" then
                AttachBoxingGlove()
            end
        end
    end
    LocalMatches[matchId].stopRound = true
    SetTimeout(4000, function()
        if not Matches[matchId] or not Matches[matchId].game or Matches[matchId].game.stageId~=match.game.stageId then return end
        LocalMatches[matchId].stopRound = false
        local timeLeft = match.game.roundTime
        SendNUIMessage({
            type = "showScoreboard",
            data = match
        })
        CreateThread(function()
            while Matches[matchId].game and timeLeft > 0 and not LocalMatches[matchId].stopRound do
                if not Matches[matchId].game.paused then
                    timeLeft = timeLeft - 1
                elseif timeLeft ~= Matches[matchId].game.roundTime then
                    timeLeft = Matches[matchId].game.roundTime
                end                
                Wait(1000)
            end
            LocalMatches[matchId].stopRound = false
            SendNUIMessage({
                type = "hideScoreboard",
            })
        end)
    end)
end

function EnterMatchArea(matchId)
    if not matchId then return end
    lib.callback("pickle_boxing:requestMatchData", "", function(match)
        if not match then return end
        Matches[matchId] = match
        if match.game and match.game.currentStage == "in_round" then
            match.game.roundTime = math.max(0,match.game.roundTime)
            LocalMatches[matchId].stopRound = true
            Wait(1100)
            LocalMatches[matchId].stopRound = false
            StartFightRoundStage(matchId, match.game.round)
        end
    end, matchId)
end

function LeaveMatchArea(matchId)
    if matchId then
        LocalMatches[matchId].stopRound = true
        SendNUIMessage({
            type = "hideScoreboard",
        })
    end
end

RegisterNetEvent("pickle_boxing:syncMatches", function(matches)
    Matches = matches
    for k,v in pairs(LocalMatches) do 
        DeleteInteraction(v.interact)
        if v.blip then RemoveBlip(v.blip) end
        LocalMatches[k] = nil
    end
    for k,v in pairs(Matches) do 
        if debugFirst then
            DebugFirstMatch(k)
            debugFirst = false 
        end
        LocalMatches[k] = {}
        LocalMatches[k].interact = CreateInteraction({
            label = _L("match_interaction"),
            model = {
                hash = `U_M_M_SpyActor`,
                components = {
                    {0, 0}, -- "HEAD"
                    {0, 0}, -- "BEARD"
                    {0, 0}, -- "HAIR"
                    {0, 0}, -- "UPPER"
                    {0, 0}, -- "LOWER"
                    {0, 0}, -- "HAND"
                    {0, 0}, -- "FEET"
                    {0, 0}, -- "TEETH"
                    {0, 0}, -- "ACCESSORIES"
                    {0, 0}, -- "TASK"
                    {0, 0}, -- "DECL"
                    {0, 0}, -- "JBIB"
                }
            },
            coords = v.interact.coords,
            heading = v.interact.heading
        }, function(selected)
            OpenMatchInteraction(k)
        end)
        if v.blip and v.blip.enabled then
            LocalMatches[k].blip = CreateBlip({
                coords = v.center.coords,
                id = v.blip.id,
                display = v.blip.display,
                scale = v.blip.scale,
                color = v.blip.color,
                label = v.blip.label
            })
        end
    end
end)

RegisterNetEvent("pickle_boxing:updateMatch", function(matchId, match, operation) 
    Matches[matchId] = match
    if operation and currentMatchArea == matchId and LocalMatches[matchId] and LocalMatches[matchId].viewingFight and (operation.action == "joinMatch" or operation.action == "leaveMatch" or operation.action == "toggleReady") then
        SetTimeout(250, function()
            OpenViewFight(matchId, true)
        end)
    end
    if operation.action == "joinMatch" then
    elseif operation.action == "leaveMatch" then
    elseif operation.action == "endMatch" then
        StopScene(true)
        if currentMatchArea == matchId then
            StartEndMatchStage(matchId, operation.values[1], operation.values[2])
        end
    elseif operation.action == "toggleReady" then
    elseif operation.action == "startStage" then
        if currentMatchArea == matchId then
            lib.hideContext()
            SetTimeout(300, function()
                lib.hideContext()
            end)
            if match.game.currentStage == "intro_ring" then
                StartIntroRingStage(matchId)
            elseif match.game.currentStage == "intro_fighter" then
                StartIntroFighterStage(matchId, operation.values[1])
            elseif match.game.currentStage == "in_round" then
                StartFightRoundStage(matchId, operation.values[1])
            end
        end
    elseif operation.action == "resumeRound" then
        if currentMatchArea == matchId then
            SendNUIMessage({
                type = "resumeScoreboard",
                data = operation.values[1]
            })
        end
    elseif operation.action == "pauseRound" then
        if currentMatchArea == matchId then
            SendNUIMessage({
                type = "pauseScoreboard",
                data = operation.values[1]
            })
        end
    elseif operation.action == "playerPunched" then
        if currentMatchArea == matchId then
            SendNUIMessage({
                type = "updateScoreboard",
                data = Matches[matchId]
            })
        end
    end
end)

AddEventHandler("onResourceStop", function(name)
    if name ~= GetCurrentResourceName() then return end 
    if refPed then 
        DeleteEntity(refPed)
        refPed = nil
    end
end)

AddEventHandler("onResourceStart", function(name)
    if name ~= GetCurrentResourceName() then return end
    TriggerServerEvent("pickle_boxing:initializePlayer")
end)

CreateThread(function()
    Wait(1000)
    while true do 
        local coords = GetEntityCoords(PlayerPedId())
        local insideArea = k
        for k,v in pairs(Matches) do 
            local dist = #(v.center.coords - coords)
            if dist < v.center.radius then 
                insideArea = k
                break
            end
        end
        if insideArea then
            if insideArea ~= currentMatchArea then
                LeaveMatchArea(currentMatchArea)
                currentMatchArea = insideArea
                EnterMatchArea(currentMatchArea)
            end
        elseif currentMatchArea then
            LeaveMatchArea(currentMatchArea)
            currentMatchArea = nil
        end
        Wait(1000)
    end
end)
RegisterNetEvent('pickle_boxing:refresh',function() TriggerServerEvent('pickle_boxing:initializePlayer') end)
