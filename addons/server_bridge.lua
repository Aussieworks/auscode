-- Stormworks addon command bridge:
-- translates in-game chat commands into backend HTTP calls.

local ANNOUNCE_TAG = "Server Control"
local COMMAND_PREFIX = "?"
local HTTP_PORT = 8000
-- Backend server id this world controls (must match servers.json)
local BACKEND_SERVER_ID = 1
local API_PATH_START = "/server/" .. tostring(BACKEND_SERVER_ID) .. "/start"
local API_PATH_STOP = "/server/" .. tostring(BACKEND_SERVER_ID) .. "/stop"
local API_PATH_RESTART = "/server/" .. tostring(BACKEND_SERVER_ID) .. "/restart"
local QUERY_SOURCE = "stormworks_bridge"
local COOLDOWN_SECONDS = 5
local RESTART_DELAY_SECONDS = 10
local TICKS_PER_SECOND = 60

local REQUEST_METHOD_POST = "POST"
local REQUEST_METHOD_GET = "GET"
local ACTION_START = "start"
local ACTION_STOP = "stop"
local ACTION_RESTART = "restart"

local current_tick = 0
local request_counter = 0
local last_command_tick_by_peer = {}
local pending_requests = {}
local restart_in_progress = false
local scheduled_restart_tick = nil
local scheduled_restart_peer = nil

local function announce(message, peer_id)
    if peer_id ~= nil then
        server.announce(ANNOUNCE_TAG, message, peer_id)
        return
    end
    server.announce(ANNOUNCE_TAG, message)
end

local function seconds_to_ticks(seconds)
    return math.floor(seconds * TICKS_PER_SECOND)
end

local function normalize_command(raw_command)
    if type(raw_command) ~= "string" then
        return ""
    end
    local lowered = string.lower(raw_command)
    return string.gsub(lowered, "^" .. COMMAND_PREFIX, "")
end

local function is_in_cooldown(peer_id)
    local last_tick = last_command_tick_by_peer[peer_id]
    if not last_tick then
        return false
    end
    return (current_tick - last_tick) < seconds_to_ticks(COOLDOWN_SECONDS)
end

local function mark_command_usage(peer_id)
    last_command_tick_by_peer[peer_id] = current_tick
end

local function next_request_id()
    request_counter = request_counter + 1
    return request_counter
end

local function build_request_path(api_path, peer_id, request_id, method)
    return string.format(
        "%s?source=%s&peer_id=%d&request_id=%d&method=%s",
        api_path,
        QUERY_SOURCE,
        peer_id,
        request_id,
        method
    )
end

local function register_pending_request(request_path, action, peer_id)
    pending_requests[request_path] = {
        action = action,
        peer_id = peer_id
    }
end

local function send_http_request(api_path, action, peer_id)
    local request_id = next_request_id()
    local post_request_path = build_request_path(api_path, peer_id, request_id, REQUEST_METHOD_POST)

    if type(server.httpPost) == "function" then
        register_pending_request(post_request_path, action, peer_id)
        server.httpPost(HTTP_PORT, post_request_path, "")
        return true
    end

    local get_request_path = build_request_path(api_path, peer_id, request_id, REQUEST_METHOD_GET)
    register_pending_request(get_request_path, action, peer_id)
    server.httpGet(HTTP_PORT, get_request_path)
    return true
end

local function trigger_backend_action(action, peer_id)
    if action == ACTION_START then
        return send_http_request(API_PATH_START, action, peer_id)
    end
    if action == ACTION_STOP then
        return send_http_request(API_PATH_STOP, action, peer_id)
    end
    if action == ACTION_RESTART then
        return send_http_request(API_PATH_RESTART, action, peer_id)
    end
    return false
end

local function deny_if_not_admin(is_admin, peer_id)
    if is_admin then
        return false
    end
    announce("Only admins can use this command.", peer_id)
    return true
end

function onCreate(is_world_create)
    current_tick = 0
    request_counter = 0
    last_command_tick_by_peer = {}
    pending_requests = {}
    restart_in_progress = false
    scheduled_restart_tick = nil
    scheduled_restart_peer = nil
end

function onTick(game_ticks)
    current_tick = current_tick + game_ticks

    if scheduled_restart_tick and current_tick >= scheduled_restart_tick then
        local ok = trigger_backend_action(ACTION_RESTART, scheduled_restart_peer or -1)
        if not ok then
            announce("Failed to dispatch restart request.")
            restart_in_progress = false
        end
        scheduled_restart_tick = nil
        scheduled_restart_peer = nil
    end
end

function onCustomCommand(full_message, peer_id, is_admin, is_auth, command, ...)
    if peer_id == -1 then
        return
    end

    local normalized = normalize_command(command)
    if normalized ~= ACTION_START and normalized ~= ACTION_STOP and normalized ~= ACTION_RESTART then
        return
    end

    if deny_if_not_admin(is_admin, peer_id) then
        return
    end

    if is_in_cooldown(peer_id) then
        announce(string.format("Please wait %d seconds before reusing control commands.", COOLDOWN_SECONDS), peer_id)
        return
    end
    mark_command_usage(peer_id)

    if normalized == ACTION_RESTART then
        if restart_in_progress then
            announce("A restart is already in progress.", peer_id)
            return
        end

        restart_in_progress = true
        scheduled_restart_tick = current_tick + seconds_to_ticks(RESTART_DELAY_SECONDS)
        scheduled_restart_peer = peer_id
        announce(string.format("Server restarting in %d seconds.", RESTART_DELAY_SECONDS))
        return
    end

    local sent = trigger_backend_action(normalized, peer_id)
    if sent then
        announce(string.format("Requested server %s.", normalized))
    else
        announce("Failed to send command to backend.", peer_id)
    end
end

function httpReply(port, request, reply)
    if port ~= HTTP_PORT then
        return
    end

    local pending = pending_requests[request]
    if not pending then
        return
    end

    pending_requests[request] = nil

    local action = pending.action
    if action == ACTION_RESTART then
        restart_in_progress = false
    end

    announce(string.format("Backend acknowledged %s request.", action), pending.peer_id)
end
