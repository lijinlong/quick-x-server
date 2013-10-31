
local redis = import(".redis_lua")

local RedisLuaAdapter = class("RedisLuaAdapter")

function RedisLuaAdapter:ctor(easy)
    self.easy = easy
end

function RedisLuaAdapter:connect()
    local ok, result = pcall(function()
        self.instance = redis.connect({
            host = self.easy.config.host,
            port = self.easy.config.port,
            timeout = self.easy.config.timeout
        })
    end)
    if ok then
        return true
    else
        return false, result
    end
end

function RedisLuaAdapter:close()
    return self.instance:quit()
end

function RedisLuaAdapter:command(command, ...)
    local method = self.instance[command]
    assert(type(method) == "function", string.format("RedisLuaAdapter:command() - invalid command %s", tostring(command)))
    local arg = {...}
    return pcall(function()
        return method(self.instance, unpack(arg))
    end)
end

function RedisLuaAdapter:pubsub(subscriptions)
    return pcall(function()
        return self.instance:pubsub(subscriptions)
    end)
end

function RedisLuaAdapter:commitPipeline(commands)
    return pcall(function()
        self.instance:pipeline(function()
            for _, arg in ipairs(commands) do
                local method = self.instance[command]
                assert(type(method) == "function", string.format("RedisLuaAdapter:commitPipeline() - invalid command %s", tostring(command)))
                method(self.instance, arg[1], unpack(arg[2]))
            end
        end)
    end)
end

return RedisLuaAdapter
