-- ==========================================================
-- Bothax Disconnect Webhook Notification Script
-- File: disconnect-notif.lua
-- ==========================================================

-- User Configuration
local WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL_HERE"
local DISCORD_USER_ID = "YOUR_DISCORD_USER_ID_HERE" -- Example: "123456789012345678"
local NOTIFY_INTERVAL = 30000 -- Interval in milliseconds (30000 ms = 30 seconds)

-- Cache & Connection State tracking
local last_bot_name = "Unknown"
local last_world_name = "UNKNOWN"
local is_disconnected = false
local disconnect_timestamp = 0

-- Check whether the bot is currently connected
local function isConnected()
    local local_player = GetLocal()
    local client = GetClient()
    local world = GetWorld()

    if not local_player or not client or not world then
        return false
    end

    if client.ping <= 0 or client.address == "" then
        return false
    end

    return true
end

-- Update cached player name and world name when connected
local function updateCache()
    local local_player = GetLocal()
    if local_player and local_player.name and local_player.name ~= "" then
        -- Remove Growtopia color formatting codes (e.g., `2, `w, `0)
        local clean_name = local_player.name:gsub("`%S", "")
        if clean_name ~= "" then
            last_bot_name = clean_name
        end
    end

    local world = GetWorld()
    if world and world.name and world.name ~= "" then
        last_world_name = world.name
    end
end

-- Helper to safely escape characters for JSON payload
local function escapeJSON(str)
    if not str then return "" end
    str = str:gsub('\\', '\\\\')
    str = str:gsub('"', '\\"')
    str = str:gsub('\n', '\\n')
    str = str:gsub('\r', '\\r')
    str = str:gsub('\t', '\\t')
    return str
end

-- Send Discord Webhook Notification
local function sendDiscordWebhook()
    if WEBHOOK_URL == "" or WEBHOOK_URL == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        LogToConsole("`4[Disconnect Notif]`1 Webhook URL is not configured!")
        return
    end

    local timestamp = disconnect_timestamp > 0 and disconnect_timestamp or os.time()
    local content_mention = (DISCORD_USER_ID ~= "" and DISCORD_USER_ID ~= "YOUR_DISCORD_USER_ID_HERE") and ("<@" .. DISCORD_USER_ID .. ">") or ""

    local bot_name_clean = escapeJSON(last_bot_name)
    local world_name_clean = escapeJSON(last_world_name)

    local payload = string.format([[
{
  "content": "%s",
  "embeds": [
    {
      "title": "⚠️ Bot Disconnected!",
      "color": 16711680,
      "fields": [
        {
          "name": "👤 Bot Name",
          "value": "%s",
          "inline": true
        },
        {
          "name": "🌐 World",
          "value": "%s",
          "inline": true
        },
        {
          "name": "⏰ Disconnected At",
          "value": "<t:%d:F> (<t:%d:R>)",
          "inline": false
        }
      ],
      "footer": {
        "text": "Bothax Disconnect Notifier"
      }
    }
  ]
}
]], escapeJSON(content_mention), bot_name_clean, world_name_clean, timestamp, timestamp)

    local headers = {
        ["Content-Type"] = "application/json"
    }

    local res = MakeRequest(WEBHOOK_URL, "POST", headers, payload)
    if res and res.status >= 200 and res.status < 300 then
        LogToConsole("`2[Disconnect Notif]`1 Webhook notification sent successfully.")
    else
        local errStatus = (res and res.status) or "Unknown error"
        LogToConsole("`4[Disconnect Notif]`1 Failed to send webhook. Status: " .. tostring(errStatus))
    end
end

-- Main Monitoring Loop
RunThread(function()
    LogToConsole("`2[Disconnect Notif]`1 Script loaded and running.")

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
