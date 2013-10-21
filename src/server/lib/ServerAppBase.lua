
local ServerAppBase = class("ServerAppBase")

function ServerAppBase:ctor(config)
    if type(config) ~= "table" then config = {} end
    if type(config.appModuleName) ~= "string" then
        config.appModuleName = "app"
    end
    self.requestType = config.requestType or "http"
    self.config = clone(config)

    if self.requestType == "http" then
        self.requestMethod = ngx.req.get_method()
        self.requestParameters = ngx.req.get_uri_args()
        if self.requestMethod == "POST" then
            ngx.req.read_body()
            table.merge(self.requestParameters, ngx.req.get_post_args())
        end
    elseif self.requestType == "websockets" then
        self.requestParameters = nil
    else
        throw(ERR_SERVER_INVALID_CONFIG, "invalid request type", tostring(self.requestType))
    end

    if config.session then
        self.session = cc.server.Session.new(self)
    end
end

function ServerAppBase:doRequest(actionName, data)
    local actionModuleName, actionMethodName = self:normalizeActionName(actionName)
    actionModuleName = "actions." .. string.ucfirst(actionModuleName) .. "Action"
    actionMethodName = actionMethodName .. "Action"

    local actionModule = self:require(actionModuleName)
    local action = actionModule.new(self)
    local method = action[actionMethodName]
    if type(method) ~= "function" then
        throw(ERR_SERVER_INVALID_ACTION, "invalid action %s:%s", actionModuleName, actionMethodName)
    end
    action.GET, action.POST = self.GET, self.POST

    if not data then
        data = self.requestParameters
    else
        self.requestParameters = data
    end
    return method(action, data)
end

function ServerAppBase:require(moduleName)
    moduleName = self.config.appModuleName .. "." .. moduleName
    return require(moduleName)
end

function ServerAppBase:normalizeActionName(actionName)
    local actionName = actionName or (self.GET.action or "index.index")
    actionName = string.gsub(actionName, "[^%a.]", "")
    actionName = string.gsub(actionName, "^[.]+", "")
    actionName = string.gsub(actionName, "[.]+$", "")

    local parts = string.split(actionName, ".")
    if #parts == 1 then parts[2] = 'index' end
    return parts[1], parts[2]
end

function ServerAppBase:getRedisInstance(config)
    if not self.redisInstance then
        self.redisInstance = cc.server.RedisEasy.new(config)
        self.redisInstance:connect()
    end
    return self.redisInstance
end

function ServerAppBase:getMysqlInstance(config)
    if not self.mysqlInstance then
        self.mysqlInstance = cc.server.MysqlEasy.new(config)
    end
    return self.mysqlInstance
end

return ServerAppBase
