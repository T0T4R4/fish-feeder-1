local LOG="[Feed] "

local pin_servo1 = 7 -- pin marked D7 on board
local freq_servo1 = 50 -- Hz


local pos_0 = 71
local pos_90 = 123
local pos_m90 = 27

local half_turn = pos_90 - pos_m90
local quarter_turn = pos_90 - pos_0

local pos_start = pos_m90 -- 27
local pos_full = pos_90 -- 123
pos_current = 0 -- variable, current position 
globals.tmrFeeding_elapsed = 0

print(LOG.."Feeding interval set to "..config.time_between_feeds.." seconds")

function moveTo(pos, spd) -- spd: millisec the highest the slowest
    pwm.setduty(pin_servo1, pos)
    pwm.start(pin_servo1)
    tmr.delay(spd * 1000) -- microSec
    pwm.stop(pin_servo1)
    pos_current=pos
end

function agitate(times, amplitude, speed) 
    local i = 0
    while( i < times) do
        moveTo(pos_current - amplitude, speed)
        moveTo(pos_current + amplitude, speed)
        i = i + 1
    end
end

function feed() 
    -- initial position
    pwm.setup(pin_servo1, freq_servo1, pos_start) 
    
    print(LOG.."Dispatching food...")

    local j = 0
    while( j < config.feed_times) do
        moveTo(pos_full, config.spd_posmove) -- go to end position ~ move 180deg
    
        -- either we agitate or we just wait for food to drop
        agitate(config.agitate_times, config.agitate_amplitude, config.agitate_speed)
        --agitate(config.agitate_times, half_turn, config.agitate_speed)
        
        --bring back to original position and clean hole
        moveTo(pos_start + 20, config.spd_posmove) -- slightly move by an amplitude of 10 to be able to agitate for cleaning hole
        agitate(3, 20, 50) -- clean hole by agitating 5 times
        moveTo(pos_start, config.spd_posmove) -- back to start position ~ mode 180 deg 
        
        j = j + 1
    end
end

function initFeedingAlarm()
    print("Initializing feeding alarm")
    
    if (tmrFeeding) then tmrFeeding:unregister() end -- in case of
    
    tmrFeeding = tmr.create()
    
    tmrFeeding:register( config.tmrFeedingCheckInterval * 1000, tmr.ALARM_AUTO, function(timer)
        print("Is it feeding time ?")
        -- check if it is the time to feed
        globals.tmrFeeding_elapsed = globals.tmrFeeding_elapsed + config.tmrFeedingCheckInterval
        if (globals.tmrFeeding_elapsed >= config.time_between_feeds) then
            print(LOG.."Time to feed little fishies !")
            
            feed()
            
            print(LOG.."Now eat, you little bastards !")
            globals.tmrFeeding_elapsed = 0
        end
    end)

    tmrFeeding:start()
end

-- Entrypoint

initFeedingAlarm()


