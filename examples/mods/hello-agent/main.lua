return {
    on_load = function(api)
        api.log("Hello from example.hello-agent")
        api.game.unlock_all_levels(true)
        api.log("All solo missions are unlocked for this session")
    end,
}
