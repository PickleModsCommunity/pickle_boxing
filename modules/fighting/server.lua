local DEFAULT_FIGHTER_DATA = { health = 100, hits = 0, contacts = 0 }

function GetRandomRange(tbl)
    return (tbl[1] < tbl[2] and math.random(tbl[1], tbl[2]) or tbl[1])
end

function AddFighterHealth(source, amount)
    local matchId, match, fighterId, fighter = GetPlayerMatch(source)
    if not matchId then return end
    SetFighterHealth(source, Matches[matchId].fighters[fighterId].health + amount)
end

function RemoveFighterHealth(source, amount)
    local matchId, match, fighterId, fighter = GetPlayerMatch(source)
    if not matchId then return end
    SetFighterHealth(source, Matches[matchId].fighters[fighterId].health - amount)
end

function SetFighterHealth(source, amount)
    local matchId, match, fighterId, fighter = GetPlayerMatch(source)
    if not matchId then return end
    local amount = amount
    if amount == nil or amount > 100 then
        amount = 100
    elseif amount < 0 then
        amount = 0
    end
    Matches[matchId].fighters[fighterId].health = amount
    TriggerClientEvent("pickle_boxing:updateHealth", source, Matches[matchId].fighters[fighterId].health)
end

function StartFighterKnockout(source)
    local matchId, match, fighterId, fighter = GetPlayerMatch(source)
    if not matchId or not match.game or match.game.currentStage~='in_round' or match.game.paused then return end
    local session=match.session
    fighter.knockoutAt=GetGameTimer()
    fighter.recoveryClicks=0
    Matches[matchId].fighters[fighterId].knockedOut = true
    PauseRound(matchId)
    TriggerClientEvent("pickle_boxing:knockoutStart", source)
    SetTimeout((Config.Fights.RecoverTime+2)*1000,function()
        if match.session==session and fighter.knockedOut and match.game then EndMatch(matchId) end
    end)
end

function IsFighterKnockedOut(source)
    local matchId, match, fighterId, fighter = GetPlayerMatch(source)
    if not matchId then return end
    return Matches[matchId].fighters[fighterId].knockedOut
end

local function processPunch(source,attacker)
    local matchId, match, fighterId, fighter = GetPlayerMatch(source)
    local attackerMatchId, attackerMatch, attackerFighterId, attackerFighter = GetPlayerMatch(attacker)
    if not matchId or not attackerMatchId or matchId ~= attackerMatchId or attacker==source
        or not match.game or match.game.currentStage~='in_round' or match.game.paused
        or not BoxingNear(source,match) or not BoxingNear(attacker,match)
        or #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(attacker)))>3
        or attackerFighter.knockedOut or attackerFighter.lastHit and GetGameTimer()-attackerFighter.lastHit<400 then return end
    attackerFighter.lastHit=GetGameTimer()
    if Matches[matchId].fighters[fighterId].knockedOut then return end
    RemoveFighterHealth(source, GetRandomRange(Config.Fights.AttackDamage))
    Matches[matchId].fighters[fighterId].contacts = Matches[matchId].fighters[fighterId].contacts + 1
    if Matches[matchId].fighters[fighterId].contacts % Config.Fights.KnockoutInterval == 0 or Matches[matchId].fighters[fighterId].health <= 0 then
        Matches[matchId].fighters[fighterId].knockedOut = (math.random(1, 100) <= (100 - Matches[matchId].fighters[fighterId].health))
    else 
        Matches[matchId].fighters[fighterId].knockedOut = false
    end
    if IsFighterKnockedOut(source) then 
        StartFighterKnockout(source)
    end
    Matches[matchId].fighters[attackerFighterId].hits = Matches[matchId].fighters[attackerFighterId].hits + 1
    BoxingSend(matchId,{action="playerPunched",values={}})
end

AddEventHandler('weaponDamageEvent',function(attacker,data)
    if type(data)~='table' or data.weaponType~=joaat('WEAPON_UNARMED') or not data.hitGlobalId then return end
    local target=NetworkGetEntityFromNetworkId(data.hitGlobalId)
    local id,match=GetPlayerMatch(tonumber(attacker))
    if not match then return end
    for _,f in ipairs(match.fighters) do
        if GetPlayerPed(f.source)==target then processPunch(f.source,tonumber(attacker)); break end
    end
end)
RegisterNetEvent('pickle_boxing:recoveryKey',function()
    local id,m,i,f=GetPlayerMatch(source)
    if f and f.knockedOut and f.knockoutAt and m.game and m.game.paused then f.recoveryClicks=(f.recoveryClicks or 0)+1 end
end)

RegisterNetEvent("pickle_boxing:knockoutResult", function(recovered)
    local matchId, match, fighterId, fighter = GetPlayerMatch(source)
    if not matchId or type(recovered)~='boolean' or not fighter.knockedOut or not fighter.knockoutAt
        or not match.game or not match.game.paused or match.game.currentStage~='in_round'
        or GetGameTimer()-fighter.knockoutAt<1000 or GetGameTimer()-fighter.knockoutAt>(Config.Fights.RecoverTime+1)*1000 then return end
    if recovered then
        local minimum=math.ceil(Config.Fights.RecoverClicks[2]+(Config.Fights.RecoverClicks[1]-Config.Fights.RecoverClicks[2])*(fighter.health/100))
        if (fighter.recoveryClicks or 0)<minimum then return end
    end
    fighter.knockoutAt=nil
    if recovered then
        Matches[matchId].fighters[fighterId].knockedOut = false
        AddFighterHealth(source, GetRandomRange(Config.Fights.RecoverHealth))
        ResumeRound(matchId)
    else
        EndMatch(matchId)
    end
end)