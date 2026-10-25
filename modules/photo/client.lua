local photoCam,photoReturn,photoActive
local function finishPhoto()
    photoActive=false
    local ped=PlayerPedId()
    if photoReturn then
        SetEntityCoords(ped,photoReturn.coords.x,photoReturn.coords.y,photoReturn.coords.z)
        SetEntityHeading(ped,photoReturn.heading); photoReturn=nil
    end
    FreezeEntityPosition(ped,false)
    ClearPedTasks(ped)
    if photoCam then SetCamActive(photoCam,false); DestroyCam(photoCam); photoCam=nil end
    RenderScriptCams(false,false,0,true,true); DoScreenFadeIn(0)
end
function StartPhoto(returnSettings,cb)
    if photoActive then cb(nil); return end
    photoActive=true; photoReturn=returnSettings
    local ped=PlayerPedId(); local pos=Config.Photos.coords
    SetEntityCoords(ped,pos.x,pos.y,pos.z-.55); SetEntityHeading(ped,Config.Photos.heading)
    FreezeEntityPosition(ped,true)
    local cameraPos=GetOffsetFromEntityInWorldCoords(ped,0,1.75,.35)
    photoCam=CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',cameraPos.x,cameraPos.y,cameraPos.z,0,0,GetEntityHeading(ped)-180,45,false,0)
    SetCamActive(photoCam,true); RenderScriptCams(true,false,0,true,true)
    CreateThread(function()
        local deadline=GetGameTimer()+60000
        while photoActive and GetGameTimer()<deadline do
            if IsControlJustPressed(1,200) or IsControlJustPressed(1,177) then break end
            ShowInteractText(_L('take_photo')..' / ESC')
            if IsControlJustPressed(1,51) then
                lib.callback('pickle_boxing:photo',false,function(url)
                    finishPhoto(); cb(type(url)=='string' and url or nil)
                end)
                return
            end
            Wait(0)
        end
        finishPhoto(); cb(nil)
    end)
end
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then finishPhoto() end end)
