
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
        local isRunning = self.isRunning

        local sub = self:newRedis()
        local ok, err = sub:command("subscribe", channel)
        if not ok then
            throw(ERR_SERVER_OPERATION_FAILED, "client %s subscribe channel [%s] failed, %s", self.sid, channel, err)
        end

        if self.config.debug then
            echoInfo("client %s subscribed channel [%s]", self.sid, channel)
        end

        while isRunning do
            local ok, result = sub:readReply()
            if not self.isRunning then
                -- main thread is dead
                isRunning = false
                break
            end

            if not ok then
                if result ~= "timeout" then
                    echoInfo("client %s get message from channel [%s] failed, %s", self.sid, channel, result)
                    break
                end
            else
                local message = tostring(result[3])
                if self.config.debug then
                    local msg = message
                    if string.len(msg) > 20 then
                        msg = string.sub(msg, 1, 20) .. " ..."
                    end
                    echoInfo("client %s get message [%s] from channel [%s]", self.sid, msg, channel)
                end

                if message == "quit" then
                    isRunning = false
                    break
                end

                -- forward message to client
                self.websockets:send_text(message)
            end
        end

        -- when error occured, connect will auto close, subscribe will remove too
        sub:close()
        sub = nil

        if self.config.debug then
            echoInfo("client %s unsubscribed from channel [%s]", self.sid, channel)
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
