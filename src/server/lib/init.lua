
if type(DEBUG) ~= "number" then DEBUG = 1 end
local CURRENT_MODULE_NAME = ...

-- init shared framework modules
cc = cc or {}
cc.VERSION = "2.0.0"
cc.FRAMEWORK_NAME = "quick-x server"

require("framework.debug")
require("framework.functions")
json = require("framework.json")

require(cc.PACKAGE_NAME .. ".errors")

cc.server = {}
cc.server.ServerAppBase = require(CURRENT_MODULE_NAME .. ".ServerAppBase")
cc.server.ActionBase    = require(CURRENT_MODULE_NAME .. ".ActionBase")
cc.server.Session       = require(CURRENT_MODULE_NAME .. ".Session")
cc.server.MysqlEasy     = require(CURRENT_MODULE_NAME .. ".MysqlEasy")
cc.server.RedisEasy     = require(CURRENT_MODULE_NAME .. ".RedisEasy")

-- init base classes
cc.Registry   = require("framework.cc.Registry")
cc.GameObject = require("framework.cc.GameObject")

-- init components
local components = {
    "components.behavior.StateMachine",
    "components.behavior.EventProtocol",
}
for _, packageName in ipairs(components) do
    cc.Registry.add(require("framework.cc." .. packageName), packageName)
end

-- init MVC
cc.mvc = {}
cc.mvc.ModelBase = require("framework.cc.mvc.ModelBase")
