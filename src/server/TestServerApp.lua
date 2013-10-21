
local TestServerApp = class("TestServerApp", cc.server.ServerAppBase)

function TestServerApp:doRequest(actionName, data)
    local function go()
        return TestServerApp.super.doRequest(self, actionName, data)
    end

    if self.config.debug then
        local ok, result = pcall(function() return go() end)
        if not ok then
            return self:onRequestError(actionName, data, ok)
        end
        return result
    else
        return go()
    end
end

return TestServerApp
