local captured_urls = {}

local function check_and_log(str)
    if type(str) == "string" and str:find("server_data%.php") then
        local url = str:match("(https?://%S+server_data%.php%S*)") or str:match("(https?://%S+)") or str
        if not captured_urls[url] then
            captured_urls[url] = true
            LogToConsole("`2[Server Data URL]`w " .. url)
        end
    end
end

AddHook("OnSendPacket", "DebugServerDataSend", function(type, packet)
    check_and_log(packet)
end)

AddHook("OnVariant", "DebugServerDataVar", function(var)
    for i = 0, #var do
        if type(var[i]) == "string" then
            check_and_log(var[i])
        end
    end
end)

LogToConsole("`2[Debug Server Data]`w Script loaded.")
