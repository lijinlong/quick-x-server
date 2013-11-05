
local TestServerApp = class("TestServerApp", cc.server.WebSocketsServerBase)

function TestServerApp:ctor(config)
    TestServerApp.super.ctor(self, config)
    self:addEventListener(TestServerApp.WEBSOCKETS_READY_EVENT, self.onWebSocketsReady, self)
    self:addEventListener(TestServerApp.WEBSOCKETS_CLOSE_EVENT, self.onWebSocketsClose, self)
    self:addEventListener(TestServerApp.CLIENT_ABORT_EVENT, self.onClientAbort, self)

    -- self:getComponent("components.behavior.EventProtocol"):setEventProtocolDebugEnabled(true)

    self.shm = ngx.shared[self.config.sharedMemoryDictName]
    local ok, err = self.shm:add("next_session_id", 0)
    if not ok then
        if err ~= "exists" then
            throw(ERR_SERVER_OPERATION_FAILED, "cannot set shared memory key \"next_session_id\"")
        end
    end

    local sid, err = self.shm:incr("next_session_id", 1)
    if not sid then
        throw(ERR_SERVER_OPERATION_FAILED, "cannot update shared memory key \"next_session_id\"")
    end
    self.sid = sid

    -- subscribe
    self.pushMessageChannel = string.format(self.config.pushMessageChannelPattern, self.sid)
end

function TestServerApp:doRequest(actionName, data)
    local _, result = xpcall(function()
        return TestServerApp.super.doRequest(self, actionName, data)
    end, function(msg) return {error = msg} end)
    return result
end


---- events callback

function TestServerApp:onWebSocketsReady(event)
    self:subscribePushMessageChannel()
end

function TestServerApp:onWebSocketsClose(event)
    self:unsubscribePushMessageChannel()
end

function TestServerApp:onClientAbort(event)
    self:unsubscribePushMessageChannel()
end


---- internal methods

function TestServerApp:subscribePushMessageChannel()
    local function subscribe()
        local channel = self.pushMessageChannel
        local isRunning = true

        local redis = self:newRedis()
        local ok, loop = redis:pubsub({subscribe = channel})
        if not ok then
            throw(ERR_SERVER_OPERATION_FAILED, "subscribe channel [%s] failed, %s", channel, loop)
        end

        for msg, abort in loop do
            if msg.kind == "subscribe" then
                if self.config.debug then
                    echoInfo("subscribed channel [%s]", msg.channel)
                end
            elseif msg.kind == "message" then
                if self.config.debug then
                    local msg_ = msg.payload
                    if string.len(msg_) > 20 then
                        msg_ = string.sub(msg_, 1, 20) .. " ..."
                    end
                    echoInfo("get message [%s] from channel [%s]", msg_, channel)
                end

                if msg.payload == "quit" then
                    isRunning = false
                    abort()
                    break
                end

                -- forward message to client
                self.websockets:send_text(msg.payload)
            end
        end

        -- when error occured, connect will auto close, subscribe will remove too
        redis:close()
        redis = nil

        if self.config.debug then
            echoInfo("unsubscribed from channel [%s]", channel)
        end

        if isRunning then
            self:subscribePushMessageChannel()
        end
    end

    ngx.thread.spawn(subscribe)
end

function TestServerApp:unsubscribePushMessageChannel()
    self:getRedis():command("publish", self.pushMessageChannel, "quit")
end

return TestServerApp
