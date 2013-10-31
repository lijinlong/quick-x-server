
local RedisPipeline = class("RedisPipeline")

function RedisPipeline:ctor(easy)
    self.easy = easy
    self.commands = {}
end

function RedisPipeline:command(command, ...)
    self.commands[#self.commands + 1] = {command, {...}}
end

function RedisPipeline:commit()
    return self.easy.adapter:commitPipeline(self.commands)
end

return RedisPipeline
