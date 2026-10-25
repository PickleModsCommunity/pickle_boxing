BoxingReady=false
function BoxingIdentity(src)
    if not GetPlayerName(src) then return end
    local ok,id=pcall(GetIdentifier,src)
    return ok and id or nil
end
function BoxingNear(src,match)
    local ped=GetPlayerPed(src)
    return match and ped~=0 and GetEntityHealth(ped)>0 and GetPlayerRoutingBucket(src)==(match.bucket or 0)
        and #(GetEntityCoords(ped)-match.center.coords)<=match.center.radius+10
end
function BoxingProfile(info)
    if type(info)~='table' then return end
    local clean={}
    for _,key in ipairs({'name','height','emoteIntro','emoteWin','emoteLoss'}) do
        local value=info[key]
        if type(value)~='string' or #value>80 or value:find('[<>%c]') then return end
        if key:find('emote') and not value:match('^[%w_%-]+$') then return end
        clean[key]=value
    end
    for _,key in ipairs({'age','weight'}) do
        local n=info[key]
        if type(n)~='number' or n%1~=0 or n<1 or n>(key=='age' and 120 or 700) then return end
        clean[key]=n
    end
    if info.image and (type(info.image)~='string' or #info.image>2048 or not info.image:match('^https://[%w%.%-%/_?=&%%]+$')) then return end
    clean.image=info.image
    return clean
end
function BoxingPublic(match)
    local result={}
    for k,v in pairs(match) do if k~='permissions' and k~='joinPermissions' and k~='ending' then result[k]=v end end
    result.fighters={}
    for i,f in ipairs(match.fighters) do
        local clean={}
        for k,v in pairs(f) do if k~='owner' and k~='knockoutAt' and k~='recoveryClicks' then clean[k]=v end end
        result.fighters[i]=clean
    end
    return result
end
function BoxingSend(id,operation)
    local match=Matches[id]
    for _,player in ipairs(GetPlayers()) do
        local src=tonumber(player)
        if BoxingNear(src,match) or GetPlayerMatch(src)==id then
            TriggerClientEvent('pickle_boxing:updateMatch',src,id,BoxingPublic(match),operation)
        end
    end
end
local rate={}
local register=RegisterNetEvent
RegisterNetEvent=function(name,fn)
    register(name,function(...)
        local src=source; local key=src..':'..name; local now=GetGameTimer()
        if not BoxingReady or not BoxingIdentity(src) or rate[key] and now-rate[key]<(name=="pickle_boxing:recoveryKey" and 50 or 200) then return end
        rate[key]=now; fn(...)
    end)
end
local callback=lib.callback.register
lib.callback.register=function(name,fn)
    callback(name,function(src,...)
        local key=src..':'..name; local now=GetGameTimer()
        if not BoxingReady or not BoxingIdentity(src) or rate[key] and now-rate[key]<750 then return false end
        rate[key]=now; return fn(src,...)
    end)
end
AddEventHandler('playerDropped',function()
    local prefix=source..':'
    for key in pairs(rate) do if key:sub(1,#prefix)==prefix then rate[key]=nil end end
end)
