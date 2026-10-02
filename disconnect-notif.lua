local WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL_HERE"
local DISCORD_USER_ID = "YOUR_DISCORD_USER_ID_HERE"
local NOTIFY_INTERVAL = 30000

local last_bot_name = "Unknown"
local last_world_name = "UNKNOWN"
local is_disconnected = false
local disconnect_timestamp = 0

local function showTextOverlay(message)
    if SendVariantList then
        SendVariantList({ [0] = "OnTextOverlay", [1] = message }, -1, 0)
    end
end

local function isConnected()
    local local_player = GetLocal()
    local client = GetClient()
    local world = GetWorld()

    if not local_player or not client or not world then return false end
    if client.ping <= 0 or client.address == "" then return false end

    return true
end

local function updateCache()
    local local_player = GetLocal()
    if local_player and local_player.name and local_player.name ~= "" then
        local clean_name = local_player.name:gsub("`%S", "")
        if clean_name ~= "" then last_bot_name = clean_name end
    end

    local world = GetWorld()
    if world and world.name and world.name ~= "" then
        last_world_name = world.name
    end
end

local function escapeJSON(str)
    if not str then return "" end
    return str:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
end

local function sendDiscordWebhook()
    if WEBHOOK_URL == "" or WEBHOOK_URL == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        LogToConsole("`4[Disconnect Notif]`1 Webhook URL is not configured!")
        showTextOverlay("`4[Disconnect Notif]`1 Webhook URL belum diisi!")
        return
    end

    local timestamp = disconnect_timestamp > 0 and disconnect_timestamp or os.time()
    local content_mention = (DISCORD_USER_ID ~= "" and DISCORD_USER_ID ~= "YOUR_DISCORD_USER_ID_HERE") and ("<@" .. DISCORD_USER_ID .. ">") or ""

    local payload = string.format([[
{
  "content": "%s",
  "embeds": [
    {
      "title": "⚠️ Bot Disconnected!",
      "color": 16711680,
      "fields": [
        { "name": "👤 Bot Name", "value": "%s", "inline": true },
        { "name": "🌐 World", "value": "%s", "inline": true },
        { "name": "⏰ Disconnected At", "value": "<t:%d:F> (<t:%d:R>)", "inline": false }
      ],
      "footer": { "text": "Bothax Disconnect Notifier | Creator: !   iHannsy × MasPakan" }
    }
  ]
}
]], escapeJSON(content_mention), escapeJSON(last_bot_name), escapeJSON(last_world_name), timestamp, timestamp)

    local pcall_ok, res = pcall(MakeRequest, WEBHOOK_URL, "POST", { ["Content-Type"] = "application/json" }, payload)

    if not pcall_ok or not res or res.error then
        LogToConsole("`4[Disconnect Notif]`1 Aktifkan MakeRequest pada setting Bothax!")
        showTextOverlay("`4[Disconnect Notif]`1 Aktifkan MakeRequest pada setting Bothax!")
        return
    end

    if res.status >= 200 and res.status < 300 then
        LogToConsole("`2[Disconnect Notif]`1 Webhook notification sent successfully.")
    else
        LogToConsole("`4[Disconnect Notif]`1 Failed to send webhook. Status: " .. tostring(res.status))
        showTextOverlay("`4[Disconnect Notif]`1 Gagal mengirim webhook! Status: " .. tostring(res.status))
    end
end

RunThread(function()
    LogToConsole("`2[Disconnect Notif]`1 Script successfully loaded! Creator: `3!   iHannsy × MasPakan``")
    showTextOverlay("`2[Disconnect Notif]`1 Script Active! `3!   iHannsy × MasPakan``")

    while true do
        if isConnected() then
            updateCache()
            if is_disconnected then
                is_disconnected = false
                disconnect_timestamp = 0
                LogToConsole("`2[Disconnect Notif]`1 Bot reconnected! Resetting notification status.")
            end
            Sleep(1000)
        else
            if not is_disconnected then
                is_disconnected = true
                disconnect_timestamp = os.time()
                LogToConsole("`4[Disconnect Notif]`1 Bot disconnected! Sending webhook notification...")
            end

            sendDiscordWebhook()
            Sleep(NOTIFY_INTERVAL)
        end
    end
end)
