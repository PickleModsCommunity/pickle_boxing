local sceneCam
local generation=0
sceneActive=false
function StopScene(skipFadeIn)
    generation=generation+1
    sceneActive=false
    if sceneCam then SetCamActive(sceneCam,false); DestroyCam(sceneCam); sceneCam=nil end
    RenderScriptCams(false,false,0,true,true)
    if not skipFadeIn then DoScreenFadeIn(0) end
end
function StartRotateScene(pos,heading,distance,doneCb)
    StopScene(true)
    local token=generation
    local start=GetGameTimer()
    distance=distance or 7
    local point=pos+vector3(distance,distance,distance)
    local angle=GetHeadingFromVector_2d(pos.x-point.x,pos.y-point.y)
    sceneCam=CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',point.x,point.y,point.z,-5,0,angle,75,false,0)
    SetCamActive(sceneCam,true); RenderScriptCams(true,false,0,true,true); sceneActive=true
    CreateThread(function()
        while sceneActive and token==generation do
            local t=math.min(1,(GetGameTimer()-start)/8000)
            SetCamRot(sceneCam,-5-30*t,0,angle,2)
            if t==1 then break end
            Wait(0)
        end
        if doneCb and token==generation then doneCb(GetGameTimer()-start) end
    end)
end
function StartFighterScene(ped)
    StopScene(true)
    if not ped or not DoesEntityExist(ped) then return end
    local token=generation; local start=GetGameTimer()
    local pos=GetOffsetFromEntityInWorldCoords(ped,0,1.25,.5)
    local heading=GetEntityHeading(ped)+180
    sceneCam=CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',pos.x,pos.y,pos.z,-15,0,heading,70,false,0)
    SetCamActive(sceneCam,true); RenderScriptCams(true,false,0,true,true); sceneActive=true
    CreateThread(function()
        while sceneActive and token==generation do
            local t=math.min(1,(GetGameTimer()-start)/8000)
            SetCamFov(sceneCam,70+10*t); SetCamRot(sceneCam,-15+20*t,0,heading,2)
            SetCamCoord(sceneCam,pos.x,pos.y,pos.z-1+.75*t)
            if t==1 then break end
            Wait(0)
        end
    end)
end
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then StopScene(true) end end)
