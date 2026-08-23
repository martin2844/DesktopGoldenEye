-- This package is discovered and validated by the current milestone, but Lua
-- execution remains intentionally disabled until the sandbox and hook API land.
return {
    on_load = function(api)
        api.log("Hello from example.hello-agent")
    end,
}
