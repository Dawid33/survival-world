---@diagnostic disable
local mod_gui = require('mod-gui')
local crash_site= require('crash-site')

local main_elements = {}

local current_settings = {}
local game_state  = "in_lobby"
local has_seed_changed = false
local respawn_items = { ["pistol"] = 1, ["firearm-magazine"] = 5 }

local function format_play_time(ticks)
    local seconds = math.floor(ticks / 60)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local days = math.floor(hours / 24)

    hours = hours % 24
    result =  string.format("%d:%02d:%02d", hours, minutes % 60, seconds % 60)
    return result
end

local function refresh_player_gui() 
  for _, element in pairs(main_elements) do 
    if element ~= nil and element.players_content ~= nil then
      element.players_content.clear()
      for _, p in pairs(game.players) do 
        element.players_content.add{type="label", caption=p.name}
      end
    end
  end
end

function add_gui_to_player(player_index)
  player = game.get_player(player_index)
  local button_flow = mod_gui.get_button_flow(player)
  button_flow.add{type="sprite-button", name="interface_toggle", sprite="item/iron-gear-wheel"}

  -- Main in-game panel that shows stats, current settings and can be used to go back to the lobby.
  main_elements[player_index].main_dialog = player.gui.left.add{type="frame", visible=false, name="main_dialog"}
  main_elements[player_index].main_dialog.caption = "Survival World"
  local inner_frame = main_elements[player_index].main_dialog.add{type="frame", style="inside_shallow_frame_with_padding",name="game_info", direction="vertical"}
  inner_frame.add{type="label", caption={"sw.welcome"}}
  inner_frame.add{type="line"}

  local time_row = inner_frame.add{type="flow"}
  time_row.add{type="label", caption={"sw.time"}, name="time_label"}
  main_elements[player_index].time_value = time_row.add{type="label", caption="", name="time_value"}

  local evo_row = inner_frame.add{type="flow"}
  evo_row.style.horizontal_spacing = 78
  local evo_label = evo_row.add{type="label", caption={"sw.evo"}, name="evo"}
  main_elements[player_index].evo_value = evo_row.add{type="label", caption="", name="evo_value"}
  main_elements[player_index].reset_button = inner_frame.add{type="button", caption="Reset", name="reset_button"}
  main_elements[player_index].reset_button.style.width = 0
  main_elements[player_index].reset_button.style.top_margin = 5
  main_elements[player_index].reset_button.style.horizontally_stretchable = "on"

  -- Lobby modal for setting map settings and starting the game.
  main_elements[player_index].lobby_modal = player.gui.screen.add{type="frame", visible=true, name="lobby_modal", caption={"sw.lobby"}, direction="vertical"}
  main_elements[player_index].lobby_modal.auto_center = true

  local inner_frame = main_elements[player_index].lobby_modal.add{type="frame", style="inside_deep_frame", name="game_info", direction="vertical"}

  local game_info_frame = inner_frame.add{type="frame", style="inner_frame"}
  local text_box = game_info_frame.add{type="text-box", text="Welcome to Survival World. In this lobby you can vote on changing the game settings. When you're read, press start to start the game.", style="map_generator_preset_description"}
  text_box.read_only = true
  text_box.word_wrap= true
  text_box.style.minimal_width = 300
  text_box.style.minimal_height = 80
  game_info_frame.style.horizontally_stretchable = true
  local tabbed_pane = inner_frame.add{type="tabbed-pane"}
  tabbed_pane.style.horizontally_stretchable = true

  local settings = tabbed_pane.add{type="tab", caption="Settings"}
  local settings_content = tabbed_pane.add{type="flow", direction="vertical"}
  settings_content.style.padding = 5;

  main_elements[player_index].biter_regen_checkbox = settings_content.add{type="checkbox", state=false, caption="Biter Regen", name="biter_regen_checkbox"}
  main_elements[player_index].pitch_black_checkbox = settings_content.add{type="checkbox", state=false, caption="Pitch Black Night", name="pitch_black_checkbox"}

  local players = tabbed_pane.add{type="tab", caption="Players"}
  main_elements[player_index].players_content = tabbed_pane.add{type="flow", name="players_content", direction="vertical"}
  main_elements[player_index].players_content.style.padding = 5;

  tabbed_pane.add_tab(settings, settings_content)
  tabbed_pane.add_tab(players, main_elements[player_index].players_content)
  tabbed_pane.selected_tab_index = 1
  local bottom_buttons_flow = main_elements[player_index].lobby_modal.add{type="flow"}
  main_elements[player_index].preview_button = bottom_buttons_flow.add{type="button", caption={"sw.preview"}, name="preview_button"}
  main_elements[player_index].start_button = bottom_buttons_flow.add{type="button", caption={"sw.start_game"}, name="start_button"}
  main_elements[player_index].start_button.style.width = 0
  main_elements[player_index].start_button.style.top_margin = 5
  main_elements[player_index].start_button.style.horizontally_stretchable = "on"

  main_elements[player_index].preview_button.style.width = 0
  main_elements[player_index].preview_button.style.top_margin = 5
  main_elements[player_index].preview_button.style.horizontally_stretchable = "on"
  refresh_player_gui()
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

script.on_event(defines.events.on_surface_cleared,
  function(event)
      local surface = game.surfaces[1]
      set_normal_daytime(surface)

      -- make sure its daytime

    if game_state  == "in_lobby" then
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
    elseif game_state  == "in_preview_lobby" then
      local mgs = surface.map_gen_settings 
      mgs.seed = math.random(1111,999999999)
      mgs.width = 500
      mgs.height = 500
    	mgs.water = "1"
    	mgs.terrain_segmentation = "1"
    	mgs.autoplace_controls["iron-ore"].size = "10"
    	mgs.autoplace_controls["iron-ore"].frequency = "1"
    	mgs.autoplace_controls["iron-ore"].richness = "1"
    	mgs.autoplace_controls["copper-ore"].size = "10"
    	mgs.autoplace_controls["copper-ore"].frequency = "1"
    	mgs.autoplace_controls["copper-ore"].richness = "1"
    	mgs.autoplace_controls["coal"].size = "10"
    	mgs.autoplace_controls["coal"].frequency = "1"
    	mgs.autoplace_controls["coal"].richness = "1"
    	mgs.autoplace_controls["stone"].size = "10"
    	mgs.autoplace_controls["stone"].frequency = "1"
    	mgs.autoplace_controls["stone"].richness = "1"
    	mgs.autoplace_controls["crude-oil"].size = "10"
    	mgs.autoplace_controls["crude-oil"].frequency = "10"
    	mgs.autoplace_controls["crude-oil"].richness = "0.05"
    	mgs.autoplace_controls["uranium-ore"].size = "4"
    	mgs.autoplace_controls["uranium-ore"].frequency = "0.1"
    	mgs.autoplace_controls["uranium-ore"].richness = "1"
    	mgs.autoplace_controls["enemy-base"].size = "6"
    	mgs.autoplace_controls["enemy-base"].frequency = "1"
    	surface.map_gen_settings = mgs
      surface.map_gen_settings = mgs
      surface.request_to_generate_chunks({0, 0}, 10)
      surface.force_generate_chunk_requests()
    elseif game_state  == "in_game" then
    	for _, player in pairs(game.players) do
    		  player.teleport({0,0}, 1)
      end

      if not has_seed_changed then
        local mgs = surface.map_gen_settings 
        mgs.seed = math.random(1111,999999999)
        mgs.width = 0
        mgs.height = 0
        surface.map_gen_settings = mgs
        has_seed_changed = true
      end

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

    	if current_settings.pitch_black then
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

    else 
      log("Failed to reset surface: bad game state")
    end
  end
)

script.on_event(defines.events.on_gui_click, 
  function(event)
    local player = game.get_player(event.player_index)

    if event.element.name == "interface_toggle" then
      if game_state == "in_game" then
        local main_dialog = main_elements[event.player_index].main_dialog
        if main_dialog.visible then
          main_dialog.visible = false
        else 
          main_dialog.visible = true
        end
      end
    elseif event.element.name == "preview_button" then
      has_seed_changed = true
      game_state = "in_preview_lobby"
      game.surfaces[1].clear()
      game.forces["player"].rechart()
    elseif event.element.name == "reset_button" then
      has_seed_changed = false
      game_state  = "in_lobby"
      current_settings = {}
      game.surfaces[1].clear()
      main_elements[event.player_index].main_dialog.visible = false
      main_elements[event.player_index].lobby_modal.visible = true
    elseif event.element.name == "start_button" then
      game_state  = "in_game"
      local surface = game.surfaces[1]

      -- Get settings off of the players gui
      if main_elements[event.player_index].biter_regen_checkbox.state then
        current_settings.biter_regen = true
      end

      if main_elements[event.player_index].pitch_black_checkbox.state then
        current_settings.pitch_black = true
      end

      surface.clear()
      main_elements[event.player_index].lobby_modal.visible = false
    end
  end
)

script.on_nth_tick(
  60,
  function(event)
    if game_state == "in_preview_lobby" then
      game.forces["player"].chart(1, {{-250, -250},{250,250}})
      game.forces["player"].chart_all()
      game.forces["player"].rechart()
    end
    local percent_evo_factor = game.forces.enemy.evolution_factor * 100
    for _, elements in pairs(main_elements) do 
      elements.evo_value.caption = string.format("%.1f%%", percent_evo_factor)
      elements.time_value.caption = format_play_time(game.ticks_played) 
    end
  end
)

script.on_event(defines.events.on_player_left_game,
function(event)
  refresh_player_gui()
end)
script.on_event(defines.events.on_player_created,
  function(event)
    main_elements[event.player_index] = {}
    add_gui_to_player(event.player_index)
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

