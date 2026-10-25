local knockoutGeneration=0
local fightThread = nil
local responseCooldown = false
local responseCooldownBlock = false
local fightControls = {22, 24, 45, 47, 140, 141, 142, 143, 257, 263, 264}
local fighterHealth = 100
local fighterGloveProps = nil
local fighterKnockedOut = false

function IsFightControlPressed()
    for i=1, #fightControls do 
        if IsControlPressed(0, fightControls[i]) then
            return true, (fightControls[i] == 22 or fightControls[i] == 143)
        end
    end
    return false
end

function DisableFightControls()
    for i=1, #fightControls do 
        DisableControlAction(0, fightControls[i], true)
    end
end

function FightResponseCooldown(ms, isBlock)
    if responseCooldown then return end
    responseCooldown = true
    CreateThread(function()
        Wait(1000)
        CreateThread(function()
            while responseCooldown do
                DisableFightControls()
                Wait(0)
            end
        end)
        Wait(ms or 1000)
        responseCooldown = false
    end)
end

function StartFightKnockout()
    if fighterKnockedOut then return end
    knockoutGeneration=knockoutGeneration+1
    local generation=knockoutGeneration
    fighterKnockedOut = true
    local ped = PlayerPedId()
    SetCamEffect(1)
    CreateThread(function()
        local secondsLeft = Config.Fights.RecoverTime + 1
        local recoverRequired = math.ceil(lerp(Config.Fights.RecoverClicks[2], Config.Fights.RecoverClicks[1], (fighterHealth / 100)))
        TransitionToBlurred(500)
        SendNUIMessage({
            type = "knockoutStart",
            seconds = secondsLeft - 1,
            recover = recoverRequired
        })
        CreateThread(function() 
            while fighterKnockedOut and generation==knockoutGeneration do
                secondsLeft = secondsLeft - 1
                if secondsLeft <= 0 then
                    RecoverFightKnockout(true)
                    break
                end
                Wait(1000)
            end
        end)
        while fighterKnockedOut and generation==knockoutGeneration do
            SetPedToRagdoll(ped, 1000, 1000)
            if IsControlJustPressed(1, 51) then
                TriggerServerEvent("pickle_boxing:recoveryKey")
                SendNUIMessage({
                    type = "knockoutKeypress"
                })
                recoverRequired = recoverRequired - 1
                if recoverRequired <= 0 then
                    RecoverFightKnockout()
                    break
                end
            end
            Wait(0) 
        end
    end)
end

function RecoverFightKnockout(fail)
    fighterKnockedOut = false
    SendNUIMessage({
        type = "knockoutStop",
    })
    SetCamEffect(0)
    TransitionFromBlurred(4000)
    TriggerServerEvent("pickle_boxing:knockoutResult", not fail)
end

function StopFightThread()
    knockoutGeneration=knockoutGeneration+1
    fightThread=false
    fighterKnockedOut=false
    responseCooldown=false
    SendNUIMessage({type='knockoutStop'})
    SetCamEffect(0)
    TransitionFromBlurred(0)
    SetEntityInvincible(PlayerPedId(),false)
    FreezeEntityPosition(PlayerPedId(),false)
end

function CreateFightThread()
    if fightThread then return end
    fightThread = true
    fighterHealth = 200
    CreateThread(function()
        local playerId = PlayerId()
        while fightThread do
            local ped = PlayerPedId()
            local _, weaponHash = GetCurrentPedWeapon(ped)
            if not IsControlPressed(0, 25) then
                DisableFightControls()
            elseif not responseCooldown then
                local pressed, isBlock = IsFightControlPressed()
                if pressed then
                    FightResponseCooldown(1000, isBlock)
                end
            end
            if weaponHash ~= `WEAPON_UNARMED` then
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            end
            DisableControlAction(0, 21, true)
            SetEntityHealth(ped, 200)
            SetPlayerLockon(playerId, true)
            Wait(0)
        end
    end)
end

function AttachBoxingGlove()
    RemoveBoxingGlove()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local boneId = GetPedBoneIndex(ped, 18905)
    local off, rot = vector3(-0.05, 0.0, 0.04), vector3(-90.0, 90.0, 0.0)
    local leftGlove = CreateProp(Config.Fights.BoxingGloveProp or `prop_boxing_glove_01`, coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(leftGlove, ped, boneId, off.x, off.y, off.z, rot.x, rot.y, rot.z, false, false, false, true, 2, true)
    
    boneId = GetPedBoneIndex(ped, 57005)
    off, rot = vector3(-0.05, 0.0, -0.04), vector3(90.0, 90.0, 0.0)
    local rightGlove = CreateProp(Config.Fights.BoxingGloveProp or `prop_boxing_glove_01`, coords.x, coords.y, coords.z, true, true, false)
    AttachEntityToEntity(rightGlove, ped, boneId, off.x, off.y, off.z, rot.x, rot.y, rot.z, false, false, false, true, 2, true)
    
    fighterGloveProps = {leftGlove, rightGlove}
end

function RemoveBoxingGlove()
    if fighterGloveProps then
        for i=1, #fighterGloveProps do 
            if DoesEntityExist(fighterGloveProps[i]) then
                DeleteEntity(fighterGloveProps[i])
            end
        end 
    end
end

RegisterNetEvent("pickle_boxing:knockoutStart", function()
    if not fighterKnockedOut then
        StartFightKnockout()
    end
end)

RegisterNetEvent("pickle_boxing:updateHealth", function(health, knockedOut)
    fighterHealth = health
end)

AddEventHandler('gameEventTriggered', function(event, args)
    if not fightThread then return end
    if event ~= "CEventNetworkEntityDamage" or GetEntityType(args[1]) ~= 1 or args[7] ~= `WEAPON_UNARMED` then return end
    local attacker = GetPlayerServerId(NetworkGetPlayerIndexFromPed(args[2]))
    if attacker == GetPlayerServerId(PlayerId()) or args[12] ~= 1 then return end
    TriggerServerEvent("pickle_boxing:playerPunched", attacker)
end)

AddEventHandler("onResourceStop", function(name)
    if name ~= GetCurrentResourceName() then return end
    RemoveBoxingGlove()
end)
local function cleanup()
    StopFightThread(); RemoveBoxingGlove()
    if StopScene then StopScene(true) end
    ClearPedTasks(PlayerPedId())
    SetNuiFocus(false,false)
    for _,t in ipairs({'hideStats','hideScoreboard','hideFighterStats','knockoutStop'}) do SendNUIMessage({type=t}) end
end
RegisterNetEvent('pickle_boxing:cleanupFighter',cleanup)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then cleanup() end end)
