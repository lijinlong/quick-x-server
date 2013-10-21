
require("server.lib.init")
require("server.lib.errors")
require("shared.includes.functions")

local server = require "resty.websocket.server"
local wb, err = server:new({
    timeout = 2 * 1000, -- ping interval
    max_payload_len = 65535
})

if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end

-- create server app instance
local config = require("server.config")
local app = require("server.TestServerApp").new(config)

-- event loop
while true do
    local data, typ, err = wb:recv_frame()
    if wb.fatal then
        ngx.log(ngx.ERR, "failed to receive frame: ", err)
        return ngx.exit(444)
    end

    if not data then
        -- send ping
        -- local bytes, err = wb:send_ping()
        -- if not bytes then
        --     ngx.log(ngx.ERR, "failed to send ping: ", err)
        --     return ngx.exit(444)
        -- end
    elseif typ == "close" then
        break -- exit event loop
    elseif typ == "ping" then
        -- send pong
        local bytes, err = wb:send_pong()
        if not bytes then
            ngx.log(ngx.ERR, "failed to send pong: ", err)
            return ngx.exit(444)
        end
    elseif typ == "pong" then
        ngx.log(ngx.ERR, "client ponged")
    elseif typ == "text" then
        -- parsing request message
        local message = json.decode(data)
        if type(message) ~= "table" then
            ngx.log(ngx.ERR, string.format("invalid message = %s", tostring(data)))
        else
            local msgid = message._id_
            local actionName = app:normalizeActionName(message.action)
            local result = app:doRequest(actionName, message)
            if type(result) == "table" then
                if msgid then result._id_ = msgid end
            else
                result = {error = result}
            end

            local bytes, err = wb:send_text(json.encode(result))
            if not bytes then
                ngx.log(ngx.ERR, "failed to send text: ", err)
                return ngx.exit(444)
            end
        end
    elseif typ == "binary" then
        -- local bytes, err = wb:send_binary(string.reverse(data))
        -- if not bytes then
        --     ngx.log(ngx.ERR, "failed to send binary: ", err)
        --     return ngx.exit(444)
        -- end
    else
        ngx.log(ngx.ERR, string.format("unknwon typ = %s", tostring(typ)))
    end
end

wb:send_close()
