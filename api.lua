local LOG="[Api] "
local PORT=80

print(LOG.."Init")

sv = net.createServer(net.TCP, 30)

--
-- HTTP parser ( https://github.com/nodemcu/nodemcu-firmware/issues/105 )
--

local buf = ""
local method, url
local cnt_len = 0
local body_len = 0

local HTTP_100 = "HTTP/1.1 100 Continue\r\n"
local HTTP_200 = "HTTP/1.1 200 OK\r\n\r\n"
local HTTP_400 = "HTTP/1.1 400 Not Found\r\n\r\n"
local REGEXP1 = "^([A-Z]+) (.-) HTTP/1.1$"
local REGEXP2 = "^([%w-]+):%s*(.+)"
local CRLF = "\r\n"

body = ""
buf = nil
abortRequest = false

local function jsonDecode(str) 
    t = sjson.decode(str)
    -- for k,v in pairs(t) do print(k,v) end
    return t
end

local ondisconnect = function(conn)
    print("disconnected!")
end

local onheader = function(conn, k, v)
    -- TODO: look for Content-Type: header
    -- to help parse body
    --print("H", k, v)
    -- parse content length to know body length
    if k == "content-length" then
        cnt_len = tonumber(v)
    end
    if k == "expect" and v == "100-continue" then
        conn:send(HTTP_100)
    end
end


local onReceiveChunk = function(conn, c)
    -- NB: once length of seen chunks equals Content-Length:
    --   onend(conn) is called
    body_len = body_len + #c
    --print("B", #c, body_len, cnt_len, node.heap())
    body = body .. c:gsub('\r?\n?', '') -- removes crlf

    if body_len >= cnt_len then
        conn:send(HTTP_200)

        print (body)

        -- decode data
        local json = jsonDecode(body)

        if ( url == "/globals") then
            if (json.config) then
                config = json.config
                for k,v in pairs(config) do print(k,v) end
                print("Config overwritten successfully !")

                -- reset feeding alarm
                initFeedingAlarm()
            end
    
            if (json.globals) then
                globals = json.globals
                print("Globals overwritten successfully !")
            end

            
        end
    end
    
end

local onrequest = function(conn, method, url)
    print("R", method, url)

    if (method == "GET") then
        if ( url == "/status") then
            local o = {}
            o.config = config
            o.globals = globals
            o.node = {}
            -- majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
            --o.node.chipid = chipid
            o.node.heap = node.heap()
            --local ip, nm, gw = wifi.sta.getip()
            --o.wifi = {}
            --o.wifi.ip = ip
            --o.wifi.nm = nm
            --o.wifi.gw = gw
            conn:send("HTTP/1.0 200 OK\r\nContent-Type: application/json\r\n\r\n"..sjson.encode(o))
        elseif (url == "/feednow" ) then
            feed() 
            conn:send(HTTP_200)
        else
            conn:send(HTTP_400)
        end

        abortBodyParsing = true
    end
end

    
local onreceive = function(conn, chunk)
    --print("IN", #chunk, chunk)
    -- merge chunks in buffer
    if not buf then
        print("New request !")
        body = ""
        body_len = 0
        buf = ""
        method = nil
        url = nil
        abortRequest = false
    end

    buf = buf .. chunk
    
    -- consume buffer line by line
    while #buf > 0 do
        -- extract line
        local e = buf:find(CRLF, 1, true)
        if not e then break end
        local line = buf:sub(1, e - 1)
        buf = buf:sub(e + 2)
        -- method, url?
        if not method then
      
            local i
            -- NB: just version 1.1 assumed
            _, i, method, url = line:find(REGEXP1)
            
        -- header line?
        elseif #line > 0 then
            -- parse header
            local _, _, k, v = line:find(REGEXP2)
            -- header seems ok?
            if k then
                k = k:lower()
                onheader(conn, k, v)
            end
        -- headers end
        else
            -- request callback
            abortBodyParsing = false
            
            onrequest(conn, method, url)
        
            if (abortBodyParsing == true) then 
                print("No need to parse Budy")
                buf = nil
            else
                -- NB: we feed the rest of the buffer as starting chunk of body
                onReceiveChunk(conn, buf)
            
                -- buffer no longer needed
                buf = nil
                -- NB: we explicitly reassign receive handler so that
                --   next received chunks go directly to body handler
                conn:on("receive", onReceiveChunk)
                -- parser done
            
            end
            
            break
        end
    end
end

if sv then
    sv:listen(80, function(conn)
        conn:on("receive", onreceive)
        conn:on("sent", function(sck) sck:close() end)
        conn:on("disconnection", ondisconnect)
    end)
end

