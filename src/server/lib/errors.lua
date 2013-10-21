
ERR_SERVER_INVALID_CONFIG     = "ERR_SERVER_INVALID_CONFIG"
ERR_SERVER_INVALID_RESULT     = "ERR_SERVER_INVALID_RESULT"
ERR_SERVER_INVALID_PARAMETERS = "ERR_SERVER_INVALID_PARAMETERS"
ERR_SERVER_INVALID_ACTION     = "ERR_SERVER_INVALID_ACTION"
ERR_SERVER_INVALID_SESSION_ID = "ERR_SERVER_INVALID_SESSION_ID"
ERR_SERVER_UNKNOWN_ERROR      = "ERR_SERVER_UNKNOWN_ERROR"

function throw(errorType, fmt, ...)
    fmt = tostring(fmt)
    local args = {...}
    local ok, msg = pcall(function()
        return string.format(fmt, unpack(args))
    end)
    if not ok then msg = fmt end
    error(string.format("<<%s>> - %s", tostring(errorType), msg), 2)
end
