
local RedisPipeline = class("RedisPipeline")

function RedisPipeline:ctor(easy)
    self.easy = easy
    self.commands = {}
end

function RedisPipeline:command(command, ...)
    self.commands[#self.commands + 1] = {command, {...}}
end

function RedisPipeline:commit()
    self.easy.adapter:initPipeline()
    for _, arg in ipairs(self.commands) do
        self.easy:command(arg[1], unpack(arg[2]))
    end
    return self.easy.adapter:commitPipeline()
end

return RedisPipeline
