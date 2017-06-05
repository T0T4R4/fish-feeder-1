local listener = {}

listener.handlers = {}
listener.svr = net.createServer(net.TCP)

listener.add = function(name, handler)
    listener.handlers[name] = handler   
end

listener.start = function(port)
    if listener.svr ~= nil then
        listener.svr:on('receive', function(socket, message, port, ip) 
            --message = network_message.decodeMessage(message)
            --if message ~= nil then
                for name, handler in pairs(listener.handlers) do   
                    handler(socket, message, port, ip)                    
                end
            --end      
        end)
    
        listener.svr:listen(port)
        print("server online")
    end
end

return listener