
local RedisTransaction = class("RedisTransaction")

function RedisTransaction:ctor(easy, ...)
    self.easy = easy
    self.started = false
    if #{...} > 0 then self:watch(...) end
end

function RedisTransaction:watch(...)
    assert(self.started == false, "RedisTransaction:watch() - WATCH inside MULTI is not allowed")
    return self.easy:command("watch", ...)
end

function RedisTransaction:command(command, ...)
    if not self.started then
        self.easy:command("multi")
        self.started = true
    end
    return self.easy:command(command, ...)
end

function RedisTransaction:commit()
    return self.easy:command("exec")
end

function RedisTransaction:discard()
    return self.easy:command("discard")
end

return RedisTransaction
