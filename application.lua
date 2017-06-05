local LOG="[App] "

globals = {}

print(LOG.."Application starting...")

dofile("feeding.lua")
  
dofile("wifi.lua")

tmrApp = tmr.create()
tmrApp:register(60 * 1000, tmr.ALARM_AUTO, function(timer)
    print(LOG.."Application status:");
        
--    running, mode = tmrFeeding:state()
--    print(LOG.."Feed timer running: " .. tostring(running) .. ", mode: " .. mode) -- running: false, mode: 0

    -- print(LOG..(time_between_feeds - tmrFeeding_elapsed).." seconds left until next feed")
end)
tmrApp:start()


--file.close("application.lua")
