
local redis = require("resty.redis")

local RestyRedisAdapter = class("RestyRedisAdapter")

function RestyRedisAdapter:ctor(easy)
    self.easy = easy
    self.instance = redis:new()
end

function RestyRedisAdapter:connect()
    self.instance:set_timeout(self.easy.config.timeout)
    return self.instance:connect(self.easy.config.host, self.easy.config.port)
end

function RestyRedisAdapter:close()
    return self.instance:close()
end

function RestyRedisAdapter:command(command, ...)
    local method = self.instance[command]
    assert(type(method) == "function", string.format("RestyRedisAdapter:command() - invalid command %s", tostring(command)))
    return method(self.instance, ...)
end

function RestyRedisAdapter:readReply()
    local result, err = self.instance:read_reply()
    if result then
        return true, result
    end
    return false, err
end

function RestyRedisAdapter:initPipeline()
    self.instance:init_pipeline()
end

function RestyRedisAdapter:commitPipeline()
    return self.instance:commit_pipeline()
end

return RestyRedisAdapter
