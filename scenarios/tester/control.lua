---@diagnostic disable
local crash_site = require('crash-site')
global.main_elements = {}
global.current_settings = {
  biter_regen = false,
  pitch_black = false,
  shallow_water = false,
  robots = false,
	iron_size = 3,
	iron_frequency = 3,
	iron_richness = 3,
	copper_size = 3,
	copper_frequency = 3,
	copper_richness = 3,
	coal_size = 3,
	coal_frequency = 3,
	coal_richness = 3,
	stone_size = 3,
	stone_frequency = 3,
	stone_richness = 3,
	oil_size = 3,
	oil_frequency = 3,
	oil_richness = 3,
	uranium_size = 3,
	uranium_frequency = 3,
	uranium_richness = 3,
	trees_size = 1,
	trees_frequency = 1,
	trees_richness = 1,
	biter_size = 6,
	biter_frequency = 6,
}
global.has_player_recieved_robots = {}
global.game_state  = "in_lobby"
global.has_seed_changed = false
global.charted_surface = false
global.biter_regen_odds = 2
global.next_valid_vote_time = 0
global.vote_tally = {
  tick_to_finish_voting = nil,
  yes_total = 0,
  no_total = 0,
  yes = {},
  no = {},
}

local ui = require('ui')

local function refresh_player_gui(player_index) 
    global.main_elements[player_index].players_content.clear()
    for _, player in pairs(game.connected_players) do 
      global.main_elements[player_index].players_content.add{type="label", caption=player.name}
    end
end

local function start_vote()
  if global.next_valid_vote_time >= game.tick then
    game.print(string.format("Please wait 10 minutes before voting again. Cooldown remaining: %s", format_play_time(global.next_valid_vote_time - game.tick)))
    return
  end
    
  for _, elements in pairs(global.main_elements) do
    global.next_valid_vote_time = game.tick + 36000
    global.vote_tally.tick_to_finish_voting = game.tick + 3600
    elements.reset_button.visible = false
    elements.vote_frame.visible = true
    elements.main_dialog.visible = true
    elements.vote_frame.visible = true
    elements.vote_results.caption = string.format("Yes/No: %d/%d, Time Remaining: %s", global.vote_tally.yes_total, global.vote_tally.no_total, ui.format_play_time(global.vote_tally.tick_to_finish_voting - game.tick))
  end
end

local function vote(value, player_index)
  if value == true then
    if global.vote_tally.yes[player_index] == nil then
      global.vote_tally.yes[player_index] = game.get_player(player_index).name
      global.vote_tally.yes_total = global.vote_tally.yes_total + 1
    end
    if global.vote_tally.no[player_index] ~= nil then 
      global.vote_tally.no_total = global.vote_tally.no_total - 1
    end
    global.vote_tally.no[player_index] = nil
  elseif value == false then
    if global.vote_tally.no[player_index] == nil then
      global.vote_tally.no[player_index] = game.get_player(player_index).name
      global.vote_tally.no_total = global.vote_tally.no_total + 1
    end
    if global.vote_tally.yes[player_index] ~= nil then 
      global.vote_tally.yes_total = global.vote_tally.yes_total - 1
    end
    global.vote_tally.yes[player_index] = nil
  elseif value == nil then
    if global.vote_tally.yes[player_index] ~= nil then 
      global.vote_tally.yes_total = global.vote_tally.yes_total - 1
    end
    if global.vote_tally.no[player_index] ~= nil then 
      global.vote_tally.no_total = global.vote_tally.no_total - 1
    end
    global.vote_tally.yes[player_index] = nil
    global.vote_tally.no[player_index] = nil
  end

  if global.vote_tally.tick_to_finish_voting ~= nil and global.vote_tally.tick_to_finish_voting > game.tick then
    for _, player in pairs(game.connected_players) do 
        global.main_elements[player.index].vote_results.caption = string.format("Yes/No: %d/%d, Time Remaining: %s", global.vote_tally.yes_total, global.vote_tally.no_total, ui.format_play_time(global.vote_tally.tick_to_finish_voting - game.tick))
    end
  end
end

local function end_vote(value, player_index)
    for _, p in pairs(game.connected_players) do
      ui.reset_main_ui(p.index)
    end
    local result = ""
    local player_count = 0
    for p in pairs(game.connected_players) do
      player_count = player_count + 1
    end
    local half = math.ceil(0.5 * player_count)
    print("half: ", half)
    if global.vote_tally.yes_total > global.vote_tally.no_total and global.vote_tally.yes_total >= half then
      result = "Yes majority of all players. Reseting..."
      go_to_lobby()
      global.next_valid_vote_time = game.tick
    elseif global.vote_tally.yes_total == global.vote_tally.no_total then
      result = "Its a tie. Not reseting."
    else
      result = "No majority of all players. Not reseting."
    end
    game.print(string.format("Vote Results: %d/%d. %s", global.vote_tally.yes_total, global.vote_tally.no_total,  result))
    global.vote_tally.tick_to_finish_voting = nil
    global.vote_tally.yes = {}
    global.vote_tally.no = {}
    global.vote_tally.yes_total = 0
    global.vote_tally.no_total = 0
end

local function set_normal_daytime(surface)
      local surface = game.surfaces[1]
  		surface.brightness_visual_weights = { 0, 0, 0 }
  		surface.min_brightness = 0.15
  		surface.dawn = 0.80
  		surface.dusk = 0.20
  		surface.evening = 0.40
  		surface.morning = 0.60
  		surface.daytime = 0.75
  		surface.freeze_daytime = false
end

script.on_event(defines.events.on_gui_click, 
  function(event)
    if event.element.name == "interface_toggle" then
      if global.game_state == "in_game" then
        local main_dialog = global.main_elements[event.player_index].main_dialog
        if main_dialog.visible then
          main_dialog.visible = false
        else 
          main_dialog.visible = true
        end
      end
    elseif event.element.name == "preview_button" then
      game.print(game.get_player(event.player_index).name .. " changed the seed.")
      global.has_seed_changed = true
      global.game_state = "in_preview_lobby"
      game.surfaces[1].clear()
    elseif event.element.name == "no_button" then
      vote(false, event.player_index)
    elseif event.element.name == "abstain_button" then
      vote(nil, event.player_index)
    elseif event.element.name == "yes_button" then
      vote(true, event.player_index)
    elseif event.element.name == "reset_button" then
      start_vote()
    elseif event.element.name == "start_button" then
      game.print(game.get_player(event.player_index).name .. " started the game.")
      global.game_state  = "in_game"
      local surface = game.surfaces[1]

      surface.clear()
      for _, player in pairs(game.connected_players) do 
          global.main_elements[player.index].lobby_modal.visible = false
          player.gui.top.visible = true
      end
    end
  end
)

function go_to_lobby()
    global.has_seed_changed = false
    global.game_state = "in_lobby"
    game.surfaces[1].clear()
    for _, player in pairs(game.connected_players) do 
      if global.main_elements[player.index] ~= nil then
        player.gui.top.visible = false
        global.main_elements[player.index].main_dialog.visible = false
        global.main_elements[player.index].lobby_modal.visible = true
        end 
    end 
end

script.on_event(defines.events.on_surface_cleared,
  function(event)
      local surface = game.surfaces[1]
  		global.charted_surface = false
      global.has_player_recieved_robots = {}
      set_normal_daytime(surface)

      local mgs = surface.map_gen_settings 
    	mgs.water = "1"
    	mgs.terrain_segmentation = "1"
    	mgs.starting_area = "big"
    	mgs.autoplace_controls["iron-ore"].size = global.current_settings.iron_size
    	mgs.autoplace_controls["iron-ore"].frequency = global.current_settings.iron_frequency
    	mgs.autoplace_controls["iron-ore"].richness = global.current_settings.iron_richness
    	mgs.autoplace_controls["copper-ore"].size = global.current_settings.copper_size
    	mgs.autoplace_controls["copper-ore"].frequency = global.current_settings.copper_frequency
    	mgs.autoplace_controls["copper-ore"].richness = global.current_settings.copper_richness
    	mgs.autoplace_controls["coal"].size = global.current_settings.coal_size
    	mgs.autoplace_controls["coal"].frequency = global.current_settings.coal_frequency
    	mgs.autoplace_controls["coal"].richness = global.current_settings.coal_richness
    	mgs.autoplace_controls["stone"].size = global.current_settings.stone_size
    	mgs.autoplace_controls["stone"].frequency = global.current_settings.stone_frequency
    	mgs.autoplace_controls["stone"].richness = global.current_settings.stone_richness
    	mgs.autoplace_controls["crude-oil"].size = global.current_settings.oil_size
    	mgs.autoplace_controls["crude-oil"].frequency = global.current_settings.oil_frequency
    	mgs.autoplace_controls["crude-oil"].richness = global.current_settings.oil_richness
    	mgs.autoplace_controls["uranium-ore"].size = global.current_settings.uranium_size
    	mgs.autoplace_controls["uranium-ore"].frequency = global.current_settings.uranium_frequency
    	mgs.autoplace_controls["uranium-ore"].richness = global.current_settings.uranium_richness
    	mgs.autoplace_controls["trees"].size = global.current_settings.trees_size
    	mgs.autoplace_controls["trees"].frequency = global.current_settings.trees_frequency
    	mgs.autoplace_controls["trees"].richness = global.current_settings.trees_richness
    	mgs.autoplace_controls["enemy-base"].size = global.current_settings.biter_size
    	mgs.autoplace_controls["enemy-base"].frequency = global.current_settings.biter_frequency
    	surface.map_gen_settings = mgs

    if global.game_state  == "in_lobby" then
        local mgs = surface.map_gen_settings 
        mgs.seed = math.random(1111,999999999)
        mgs.width = 1
        mgs.height = 1
        surface.map_gen_settings = mgs
        surface.set_tiles({{position={0,0}, name="out-of-map"}})
        -- Not setting the status makes normal world gen take over which overrides the out-of-map tile.
        surface.set_chunk_generated_status({0,0}, defines.chunk_generated_status.entities) 

      	for _, player in pairs(game.players) do
      		if player.connected and player.character ~= nil then
      			player.character.destroy()
      		end
      	end
    elseif global.game_state  == "in_preview_lobby" then
     	game.reset_time_played()
      local mgs = surface.map_gen_settings 
      mgs.seed = math.random(1111,999999999)
      mgs.width = 500
      mgs.height = 500
      surface.map_gen_settings = mgs
      surface.request_to_generate_chunks({0, 0}, 10)
      surface.force_generate_chunk_requests()
    elseif global.game_state  == "in_game" then
    	for _, player in pairs(game.players) do
    		  player.teleport({0,0}, 1)
      end

      local mgs = surface.map_gen_settings 
      if not global.has_seed_changed then
        mgs.seed = math.random(1111,999999999)
        global.has_seed_changed = false
      end
      mgs.width = 0
      mgs.height = 0
      surface.map_gen_settings = mgs

      -- We need to kill all players _before_ the surface is cleared, so that
    	-- their inventory, and crafting queue, end up on the old surface
    	for _, player in pairs(game.players) do
    		if player.connected and player.character ~= nil then
    			-- We call die() here because otherwise we will spawn a duplicate
    			-- character, wtimeho will carry over into the new surface
    			player.character.die()
    		end
    		-- Setting [ticks_to_respawn] to 1 seems to consistantly kill offline
    		-- players. Calling this for online players will cause them instead be
    		-- respawned the next tick, skipping the 10 respawn second timer.
    		player.ticks_to_respawn = 1
    	end

     	game.reset_time_played()
      surface.request_to_generate_chunks({0, 0}, 6)
      surface.force_generate_chunk_requests()
      game.reset_game_state()
    	game.forces["enemy"].reset()
    	game.forces["enemy"].reset_evolution()
    	game.pollution_statistics.clear()
    	game.forces["player"].research_queue_enabled = true
    	game.forces["player"].max_failed_attempts_per_tick_per_construction_queue = 2
    	game.forces["player"].max_successful_attempts_per_tick_per_construction_queue = 6
    	game.difficulty_settings.technology_price_multiplier = 1
    	game.difficulty_settings.recipe_difficulty = 0
    	surface.solar_power_multiplier = 1
    	local ship_items = 	{ ["firearm-magazine"] = 30, ["gun-turret"] = 2 }
    	local debris_items = { ["iron-plate"] = 8, ["burner-mining-drill"] = 15, ["stone-furnace"] = 15 }
    	crash_site.create_crash_site(surface, {-5,-6}, ship_items, debris_items, crash_site.default_ship_parts())

    	if global.current_settings.pitch_black then
    		surface.brightness_visual_weights = { 1, 1, 1 }
    		surface.min_brightness = 0
    		surface.dawn = 0.80
    		surface.dusk = 0.20
    		surface.evening = 0.40
    		surface.morning = 0.60
    		surface.daytime = 0.61
    		surface.freeze_daytime = false
    	else
        set_normal_daytime(surface)
    	end

    	if global.current_settings.robots == true then
    	  game.forces["player"].technologies["construction-robotics"].researched = true
    	  game.forces["player"].technologies["worker-robots-speed-1"].researched = true
    	  game.forces["player"].technologies["worker-robots-speed-2"].researched = true
    	  game.forces["player"].technologies["worker-robots-speed-3"].researched = true
    	  game.forces["player"].technologies["worker-robots-speed-4"].researched = true
    	end

    else 
      log("Failed to reset surface: bad game state")
    end
  end
)

function give_player_robots(player)
    player.character.insert{ name = "modular-armor", count = 1 }
    player.character.insert{ name = "construction-robot", count = 10 }
    local armor_inventory = player.character.get_inventory(defines.inventory.character_armor)
    local armor = armor_inventory.find_item_stack("modular-armor")
    local grid = armor.grid
    grid.put({
        name = "personal-roboport-equipment"
    })
    for i=1, 19 do
      grid.put({
          name = "solar-panel-equipment"
      })
    end
end

function give_player_items(player_index)
	  local player = game.get_player(player_index)
  	if global.current_settings.robots and global.has_player_recieved_robots[player_index] == nil or global.has_player_recieved_robots[player_index] == false then
  	    give_player_robots(player)
  	    global.has_player_recieved_robots[player_index] = true
	  end
    player.character.insert{ name = "pistol", count = 1 }
    player.character.insert{ name = "firearm-magazine", count = 5 }
end

script.on_event(defines.events.on_player_respawned,
  function(event)
  give_player_items(event.player_index)
  end
)

script.set_event_filter(defines.events.on_entity_damaged, {{filter = "type", type = "unit"}, {filter = "final-health", comparison = "=", value = 0, mode = "and"}})
script.on_event(defines.events.on_entity_damaged,
function(event)
	if global.current_settings.biter_regen and event.final_health <= 0 and event.entity.name == "medium-biter" and math.random(1, global.biter_regen_odds) ~= global.biter_regen_odds then
		event.entity.health = 3000
	end
end
)


script.on_nth_tick(
  36000,
  function(event)
    if global.game_state == "in_game" then
    	if game.ticks_played > 36288000 then
    		game.print("Game has reached its maximum playtime of 7 days.")
    	  go_to_lobby()
    	end

    	if global.current_settings.biter_regen then 
    	  -- TODO: Test this scaling.
      	-- local red_sci = game.forces["player"].item_production_statistics.get_output_count "automation-science-pack" * 3
      	-- local green_sci = game.forces["player"].item_production_statistics.get_output_count "logistic-science-pack" * 7
      	-- local blue_sci = game.forces["player"].item_production_statistics.get_output_count "chemical-science-pack" * 60
      	-- local purple_sci = game.forces["player"].item_production_statistics.get_output_count "production-science-pack" * 155
      	-- local yellow_sci = game.forces["player"].item_production_statistics.get_output_count "utility-science-pack" * 195
      	-- local adjusted_sci = math.ceil(math.min((((red_sci + green_sci + blue_sci + purple_sci + yellow_sci) * 0.0001) + 1.5), 77))
      	-- global.biter_hp = math.max(adjusted_sci + math.ceil(math.max(((game.ticks_played - 1296000) * 0.00002777), 0)), 2)
    	end
  	end
  end
)

script.on_nth_tick(
  60,
  function(event)
  	if not global.charted_surface then
    	global.charted_surface = true
    	local surface = game.surfaces[1]
      game.forces["player"].chart(1, {{-250, -250},{250,250}})
      game.forces["player"].rechart()
      game.forces["player"].add_chart_tag(1, {position={25, -25}, icon={type="virtual", name="signal-green"}, text="Deathworld Survival Discord: https://discord.gg/6szRFxDntU"} )
  	end

    for _, player in pairs(game.connected_players) do 
      if global.vote_tally.tick_to_finish_voting ~= nil then
        if global.vote_tally.tick_to_finish_voting <= game.tick then
            end_vote()
        else
            global.main_elements[player.index].vote_results.caption = string.format("Yes/No: %d/%d, Time Remaining: %s", global.vote_tally.yes_total, global.vote_tally.no_total, ui.format_play_time(global.vote_tally.tick_to_finish_voting - game.tick))
        end
      end
      if global.main_elements[player.index] ~= nil then
        local percent_evo_factor = game.forces.enemy.evolution_factor * 100
        global.main_elements[player.index].evo_value.caption = string.format("%.1f%%", percent_evo_factor)
        global.main_elements[player.index].time_value.caption = ui.format_play_time(game.ticks_played) 
      end
    end
  end
)

script.on_event(defines.events.on_chunk_generated, 
  function(event)
    -- Convert all water to shallow water
    if global.current_settings.shallow_water then
    	local surface = game.surfaces[1]
    	local set_water_shallow = {}
    	local set_water_mud = {}
    	for k, tile in pairs (surface.find_tiles_filtered{name = "water", area = target_area}) do
    		set_water_shallow[#set_water_shallow + 1] = {name = "water-shallow", position = tile.position}
    	end
    	for k, tile in pairs (surface.find_tiles_filtered{name = "deepwater", area = target_area}) do
    		set_water_mud[#set_water_mud + 1] = {name = "water-mud", position = tile.position}
    	end
    	surface.set_tiles(set_water_shallow)
    	surface.set_tiles(set_water_mud)
  	end
  end
)

script.on_event(defines.events.on_biter_base_built, 
  function(event)
  	if (event.entity.position.x > -32 and event.entity.position.x< 32 and event.entity.position.y > -32 and event.entity.position.y < 32) then
  		game.print("Uh oh... The biters have overtaken your spawn!")
  		go_to_lobby()
  	end
  end
)

local function refresh_all_players_list(event)
    for _, p in pairs(game.connected_players) do
      refresh_player_gui(p.index)
    end
end

script.on_event(defines.events.on_player_left_game, refresh_all_players_list)
script.on_event(defines.events.on_player_joined_game, 
  function(event)
    player = game.get_player(event.player_index)
    if global.game_state == "in_game" then
       global.main_elements[event.player_index].lobby_modal.visible = false 
      if tick_to_finish_voting == nil then 
        global.main_elements[event.player_index].main_dialog.visible = false
        ui.reset_main_ui(event.player_index)
      else
        global.main_elements[player.index].main_dialog.visible = true
      end
      player.gui.top.visible = true
    end 
    if global.game_state == "in_lobby" or global.game_state == "in_preview_lobby" then
        player.gui.top.visible = false
        global.main_elements[event.player_index].main_dialog.visible = false
    end
    refresh_all_players_list(event)
  end
)

script.on_event(defines.events.on_unit_group_finished_gathering, 
  function(event)
  end
)

script.on_event(defines.events.on_player_created,
  function(event)
    global.main_elements[event.player_index] = {}
    ui.add_gui_to_player(event.player_index)
    refresh_player_gui(event.player_index)
    if global.game_state == "in_game" then
  	  give_player_items(event.player_index)
	  end
	  player = game.get_player(event.player_index)
  end
)

script.on_load(function()
    log("Loading Scenario (on_load)")
end)

script.on_init(function()
    log("Initialising Scenario for the first time (on_init)")
  	game.map_settings.enemy_evolution.destroy_factor = 0
  	game.map_settings.enemy_evolution.pollution_factor = 0
  	game.map_settings.enemy_evolution.time_factor = 0.00004
  	game.map_settings.enemy_expansion.enabled = true
  	game.map_settings.enemy_expansion.max_expansion_cooldown  = 4000
  	game.map_settings.enemy_expansion.min_expansion_cooldown  = 3000
  	game.map_settings.enemy_expansion.settler_group_max_size  = 10
  	game.map_settings.enemy_expansion.settler_group_min_size = 8
  	game.map_settings.path_finder.general_entity_collision_penalty = 1
  	game.map_settings.path_finder.general_entity_subsequent_collision_penalty = 1
  	game.map_settings.path_finder.ignore_moving_enemy_collision_distance = 0
  	game.map_settings.max_failed_behavior_count = 1
  	game.map_settings.pollution.ageing = 0.5
  	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 3
  	game.map_settings.unit_group.max_gathering_unit_groups = 30
  	game.map_settings.unit_group.max_unit_group_size = 150
    local surface = game.surfaces[1]
    surface.clear()
end)

