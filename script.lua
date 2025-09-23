--- Called when the script is initialized (whenever creating or loading a world.)
---@param is_world_create boolean Only returns true when the world is first created.
function onCreate(is_world_create)
	debug.log("Loaded")
end

--- Called every game tick
---@param game_ticks number the number of ticks since the last onTick call (normally 1, while sleeping 400.)
function onTick(game_ticks)
end

--- Called when the world is exited.
function onDestroy()
end
