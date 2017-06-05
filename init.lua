local LOG="[init] "
-- load credentials, 'SSID' and 'PASSWORD' declared and initialize in there
dofile("credentials.lua")
dofile("config.lua")

function startup()
    if file.open("init.lua") == nil then
        print(LOG.."init.lua deleted or renamed")
    else
        print(LOG.."Running")
        
        -- the actual application is stored in 'application.lua'
        dofile("application.lua")

        file.close("init.lua")
    end
end


startup()
