if GetResourceState('qb-core') ~= 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()

function ShowNotification(target, text)
	TriggerClientEvent(GetCurrentResourceName()..":showNotification", target, text)
end

function GetIdentifier(source)
    local player=QBCore.Functions.GetPlayer(source)
    local xPlayer=player and player.PlayerData
    return xPlayer and xPlayer.citizenid
end

function CheckPermission(source, permission)
    if type(permission)~="table" then return false end
    if permission.type == "ace" then
        return IsPlayerAceAllowed(source, permission.name)
    elseif permission.type == "job" then
        local player=QBCore.Functions.GetPlayer(source)
    local xPlayer=player and player.PlayerData
        if not xPlayer or not xPlayer.job then return false end
        local name = xPlayer.job.name
        local rank = xPlayer.job.grade.level
        return (permission.name == name and permission.rank <= rank)
    elseif permission.type == "group" then
        return QBCore.Functions.HasPermission(source, permission.name)
    end
end