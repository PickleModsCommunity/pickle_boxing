local pending={}
local function decode64(data)
    local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local lookup={}
    for i=1,#alphabet do lookup[alphabet:sub(i,i)]=i-1 end
    local out={}; local buffer,bits=0,0
    for i=1,#data do
        local v=lookup[data:sub(i,i)]
        if v then
            buffer=(buffer<<6)|v; bits=bits+6
            if bits>=8 then bits=bits-8; out[#out+1]=string.char((buffer>>bits)&255); buffer=buffer&((1<<bits)-1) end
        end
    end
    return table.concat(out)
end
lib.callback.register('pickle_boxing:photo',function(src)
    if pending[src] or BoxingPhotoWebhook=='' or GetResourceState('screenshot-basic')~='started' then return false end
    local p=GetPlayerPed(src)
    if p==0 or #(GetEntityCoords(p)-Config.Photos.coords)>5 then return false end
    pending[src]=true
    local owner=BoxingIdentity(src); local result=promise.new(); local done=false
    local function finish(url) if not done then done=true; pending[src]=nil; result:resolve(url or false) end end
    SetTimeout(20000,function() finish(false) end)
    exports['screenshot-basic']:requestClientScreenshot(src,{encoding='jpg',quality=.8},function(err,data)
        if done or err or type(data)~='string' or #data>4000000 or BoxingIdentity(src)~=owner then finish(false); return end
        local encoded=data:match('^data:image/jpeg;base64,(.+)$')
        if not encoded then finish(false); return end
        local boundary='boxing'..math.random(1,1000000000)
        local body='--'..boundary..'\r\nContent-Disposition: form-data; name="files[0]"; filename="fighter.jpg"\r\nContent-Type: image/jpeg\r\n\r\n'..decode64(encoded)..'\r\n--'..boundary..'--\r\n'
        PerformHttpRequest(BoxingPhotoWebhook,function(status,response)
            local ok,parsed=pcall(json.decode,response or '')
            finish(status>=200 and status<300 and ok and parsed.attachments and parsed.attachments[1] and parsed.attachments[1].url)
        end,'POST',body,{['Content-Type']='multipart/form-data; boundary='..boundary})
    end)
    return Citizen.Await(result)
end)
