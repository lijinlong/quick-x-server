
local RedisTransition = class("RedisTransition")

function RedisTransition:ctor(easy, ...)
    self.easy = easy
    self.started = false
    if #{...} > 0 then self:watch(...) end
end

function RedisTransition:watch(...)
    assert(self.started == false, "RedisTransition:watch() - WATCH inside MULTI is not allowed")
    return self.easy:command("watch", ...)
end

function RedisTransition:command(command, ...)
    if not self.started then
        self.easy:command("multi")
        self.started = true
    end
    return self.easy:command(command, ...)
end

function RedisTransition:commit()
    return self.easy:command("exec")
end

function RedisTransition:discard()
    return self.easy:command("discard")
end

return RedisTransition
