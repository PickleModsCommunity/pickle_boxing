Matches, MatchThreads, PlayerInfo = {}, {}, {}
local identities, joinLocks={},{}
function RegisterMatch(data)
    local id=tostring(#Config.Locations)..'_'..tostring(math.random(1,1000000000))
    Matches[id]={blip=data.blip,settings=data.defaultSettings,permissions=data.permissions,joinPermissions=data.joinPermissions,
        interact=data.interact,center=data.center,fighterPositions=data.fighterPositions,fighters={}}
    return Matches[id]
end
function GetPlayerMatch(src)
    for id,m in pairs(Matches) do for i,f in ipairs(m.fighters) do if f.source==src then return id,m,i,f end end end
end
function GetPlayerFighterInfo(src)
    local owner=BoxingIdentity(src)
    if not owner then return end
    if identities[src]==owner and PlayerInfo[src] then return PlayerInfo[src] end
    local rows=MySQL.query.await('SELECT * FROM pickle_boxing WHERE identifier=@id',{['@id']=owner})
    if owner~=BoxingIdentity(src) then return end
    local row=rows[1] or {}
    local ok,info=pcall(json.decode,row.info or '{}'); info=ok and type(info)=='table' and info or {}
    local p={source=src,name=info.name or GetPlayerName(src),image=info.image,
        record={wins=row.wins or 0,losses=row.losses or 0,ties=row.ties or 0}}
    for k,v in pairs(Config.DefaultFighterInfo) do p[k]=info[k] or v end
    local changed=MySQL.update.await('INSERT IGNORE INTO pickle_boxing (identifier,info,wins,losses,ties) VALUES (@id,@info,0,0,0)',{['@id']=owner,['@info']=json.encode(p)})
    if type(changed)~='number' or owner~=BoxingIdentity(src) then return end
    PlayerInfo[src]=p; identities[src]=owner
    return p
end
function UpdatePlayerFighterInfo(src,info)
    local clean=BoxingProfile(info)
    local owner=BoxingIdentity(src)
    if not clean or not owner then return false end
    local p=GetPlayerFighterInfo(src)
    if not p then return false end
    local rows=MySQL.update.await('UPDATE pickle_boxing SET info=@info WHERE identifier=@id',{['@info']=json.encode(clean),['@id']=owner})
    if type(rows)~='number' or owner~=BoxingIdentity(src) then return false end
    for k,v in pairs(clean) do p[k]=v end
    return true
end
function CanManageMatch(src,id)
    local m=Matches[id]
    if not m or not BoxingNear(src,m) then return false end
    if not m.permissions then return IsPlayerAceAllowed(src,'pickle_boxing.manage') end
    for _,permission in ipairs(m.permissions) do if CheckPermission(src,permission) then return true end end
    return false
end
function CanJoinMatch(src,id)
    local m=Matches[id]
    if not m or not BoxingNear(src,m) then return false end
    if not m.joinPermissions then return true end
    for _,permission in ipairs(m.joinPermissions) do if CheckPermission(src,permission) then return true end end
    return false
end
function StartMatch(id)
    local m=Matches[id]
    if not m or m.game or m.ending or #m.fighters~=2 then return end
    local session={id=id..':'..os.time()..':'..math.random(1,1000000000)}
    m.session=session
    local function alive() return m.session==session and m.game~=nil and #m.fighters==2 end
    m.game={currentStage='intro_ring'}
    BoxingSend(id,{action='startStage',values={}})
    CreateThread(function()
        Wait(8000); if not alive() then return end
        for i=1,2 do
            m.game={currentStage='intro_fighter'}
            BoxingSend(id,{action='startStage',values={i}})
            Wait(8000); if not alive() then return end
        end
        for round=1,m.settings.rounds do
            m.game={currentStage='in_round',stageId=session.id..':'..round,round=round,roundTime=60*m.settings.roundLength}
            if round>1 then for _,f in ipairs(m.fighters) do AddFighterHealth(f.source,GetRandomRange(Config.Fights.RecoverHealthRound)) end end
            BoxingSend(id,{action='startStage',values={round}})
            Wait(4000); if not alive() then return end
            while alive() and m.game.roundTime>0 do
                Wait(1000); if not alive() then return end
                if not m.game.paused then m.game.roundTime=math.max(0,m.game.roundTime-1) end
            end
        end
        if alive() then EndMatch(id) end
    end)
end
function EndMatch(id,force)
    local m=Matches[id]
    if not m or m.ending then return end
    m.ending=true
    local fighters=m.fighters; local session=m.session
    m.session=nil; m.game=nil -- invalidate every suspended stage before database work
    if not force and #fighters==2 and session then
        local a,b=fighters[1],fighters[2]
        local tie=(a.knockedOut and b.knockedOut) or (not a.knockedOut and not b.knockedOut and a.hits==b.hits)
        a.winner=not tie and (b.knockedOut or not a.knockedOut and a.hits>b.hits)
        b.winner=not tie and not a.winner
        local queries={{query='INSERT INTO pickle_boxing_results (id) VALUES (@id)',values={['@id']=session.id}}}
        for _,f in ipairs(fighters) do
            local column=tie and 'ties' or f.winner and 'wins' or 'losses'
            table.insert(queries,{query='UPDATE pickle_boxing SET '..column..'='..column..'+1 WHERE identifier=@owner',values={['@owner']=f.owner}})
        end
        SetResourceKvp('result:'..session.id,json.encode(queries))
        if MySQL.transaction.await(queries) then
            DeleteResourceKvp('result:'..session.id)
            for _,f in ipairs(fighters) do
                local p=PlayerInfo[f.source]
                if p and identities[f.source]==f.owner then
                    local column=tie and 'ties' or f.winner and 'wins' or 'losses'
                    p.record[column]=p.record[column]+1
                end
            end
        end
    end
    m.fighters={}
    BoxingSend(id,{action='endMatch',values={fighters,force}})
    for _,f in ipairs(fighters) do TriggerClientEvent('pickle_boxing:cleanupFighter',f.source) end
    m.ending=nil
end
function PauseRound(id)
    local m=Matches[id]; if not m or not m.game then return end
    m.game.paused=true; BoxingSend(id,{action='pauseRound',values={m.game.roundTime}})
end
function ResumeRound(id)
    local m=Matches[id]; if not m or not m.game then return end
    m.game.paused=false; BoxingSend(id,{action='resumeRound',values={m.game.roundTime}})
end
function PlayerLeaveMatch(src)
    local id,m,_,f=GetPlayerMatch(src)
    if not m then return true end
    if m.game and #m.fighters==2 then f.knockedOut=true; EndMatch(id); return true end
    for i,v in ipairs(m.fighters) do if v.source==src then table.remove(m.fighters,i); break end end
    BoxingSend(id,{action='leaveMatch',values={src}})
    TriggerClientEvent('pickle_boxing:cleanupFighter',src)
    return true
end
function PlayerJoinMatch(src,id,info)
    if joinLocks[src] or joinLocks[id] then return false end
    if not CanJoinMatch(src,id) or GetPlayerMatch(src) then return false end
    local m=Matches[id]
    if m.game or m.ending or #m.fighters>=2 then return false end
    joinLocks[src],joinLocks[id]=true,true
    local ok,result=pcall(function()
        if info and not UpdatePlayerFighterInfo(src,info) then return false end
        local p=GetPlayerFighterInfo(src)
        if not p or m.game or #m.fighters>=2 or not CanJoinMatch(src,id) then return false end
        local f={}
        for k,v in pairs(p) do f[k]=v end
        f.owner=BoxingIdentity(src); f.health=100; f.hits=0; f.contacts=0; f.ready=false
        table.insert(m.fighters,f)
        BoxingSend(id,{action='joinMatch',values={src}})
        return true
    end)
    joinLocks[src],joinLocks[id]=nil,nil
    return ok and result==true
end
lib.callback.register('pickle_boxing:attemptJoinMatch',function(src,id,info) return PlayerJoinMatch(src,id,info) end)
lib.callback.register('pickle_boxing:getFighterSettings',function(src) return GetPlayerFighterInfo(src) end)
local topCache,topTime={},0
lib.callback.register('pickle_boxing:getTopFighters',function()
    if GetGameTimer()-topTime<30000 then return topCache end
    local rows=MySQL.query.await('SELECT * FROM pickle_boxing ORDER BY wins DESC LIMIT 10')
    local result={}
    for _,row in ipairs(rows) do
        local ok,info=pcall(json.decode,row.info or '{}')
        if ok then info.record={wins=row.wins,losses=row.losses,ties=row.ties}; result[#result+1]=info end
    end
    topCache=result; topTime=GetGameTimer(); return result
end)
lib.callback.register('pickle_boxing:canManageMatch',CanManageMatch)
lib.callback.register('pickle_boxing:canJoinMatch',CanJoinMatch)
lib.callback.register('pickle_boxing:requestMatchData',function(src,id) if Matches[id] and BoxingNear(src,Matches[id]) then return BoxingPublic(Matches[id]) end end)
RegisterNetEvent('pickle_boxing:toggleReadyFight',function()
    local src=source; local id,m,i,f=GetPlayerMatch(src)
    if not m or m.game or not BoxingNear(src,m) then return end
    f.ready=not f.ready
    if #m.fighters==2 and m.fighters[1].ready and m.fighters[2].ready then StartMatch(id) end
    BoxingSend(id,{action='toggleReady',values={src,f.ready}})
end)
RegisterNetEvent('pickle_boxing:updateMatchSettings',function(id,s)
    if not CanManageMatch(source,id) or Matches[id].game or type(s)~='table' then return end
    if type(s.rounds)~='number' or s.rounds%1~=0 or s.rounds<1 or s.rounds>12
        or type(s.roundLength)~='number' or s.roundLength%1~=0 or s.roundLength<1 or s.roundLength>10
        or (s.fightType~='boxing' and s.fightType~='mma') or type(s.event)~='string' or #s.event>100 or s.event:find('[<>%c]') then return end
    Matches[id].settings={rounds=s.rounds,roundLength=s.roundLength,fightType=s.fightType,event=s.event}
    BoxingSend(id,{action='updateSettings',values={}})
end)
RegisterNetEvent('pickle_boxing:initializePlayer',function()
    local view={}
    for id,m in pairs(Matches) do
        view[id]=BoxingPublic(m)
        if not BoxingNear(source,m) then view[id].fighters={}; view[id].game=nil end
    end
    TriggerClientEvent('pickle_boxing:syncMatches',source,view)
end)
AddEventHandler('playerDropped',function() PlayerLeaveMatch(source); PlayerInfo[source]=nil; identities[source]=nil end)
CreateThread(function()
    for _,data in ipairs(Config.Locations) do RegisterMatch(data) end
    while true do
        Wait(1000)
        local remove={}
        for _,m in pairs(Matches) do for _,f in ipairs(m.fighters) do
            if f.owner~=BoxingIdentity(f.source) or not BoxingNear(f.source,m) then remove[#remove+1]=f.source end
        end end
        for _,src in ipairs(remove) do PlayerLeaveMatch(src) end
    end
end)
MySQL.ready(function()
    MySQL.update.await('CREATE TABLE IF NOT EXISTS pickle_boxing (identifier varchar(80) PRIMARY KEY, info longtext, wins int NOT NULL DEFAULT 0, losses int NOT NULL DEFAULT 0, ties int NOT NULL DEFAULT 0) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci')
    MySQL.update.await('CREATE TABLE IF NOT EXISTS pickle_boxing_results (id varchar(128) PRIMARY KEY) CHARACTER SET utf8mb4')
    local iterator=StartFindKvp('result:')
    while true do
        local key=FindKvp(iterator); if not key then break end
        local id=key:sub(8)
        local exists=MySQL.query.await('SELECT id FROM pickle_boxing_results WHERE id=@id',{['@id']=id})
        if exists[1] then DeleteResourceKvp(key) else
            local ok,queries=pcall(json.decode,GetResourceKvpString(key))
            if ok then for _,query in ipairs(queries) do query.values=query.values or query.parameters; query.parameters=nil end end
            if ok and MySQL.transaction.await(queries) then DeleteResourceKvp(key) end
        end
    end
    EndFindKvp(iterator)
    BoxingReady=true
    TriggerClientEvent('pickle_boxing:refresh',-1)
end)
