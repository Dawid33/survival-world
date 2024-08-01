---@diagnostic disable
local mod_gui = require('mod-gui')
local crash_site= require('crash-site')

global.main_elements = {}
global.current_settings = {
  biter_regen = false,
  pitch_black = false,
  shallow_water = false,
  robots = false,
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
    elements.vote_results.caption = string.format("Yes/No: %d/%d, Time Remaining: %s", global.vote_tally.yes_total, global.vote_tally.no_total, format_play_time(global.vote_tally.tick_to_finish_voting - game.tick))
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
        global.main_elements[player.index].vote_results.caption = string.format("Yes/No: %d/%d, Time Remaining: %s", global.vote_tally.yes_total, global.vote_tally.no_total, format_play_time(global.vote_tally.tick_to_finish_voting - game.tick))
    end
  end
end

local function end_vote(value, player_index)
    for _, p in pairs(game.connected_players) do
      global.main_elements[p.index].vote_frame.visible = false
      global.main_elements[p.index].reset_button.visible = true
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

function add_gui_to_player(player_index)
  player = game.get_player(player_index)
  local button_flow = mod_gui.get_button_flow(player)
  button_flow.add{type="sprite-button", name="interface_toggle", sprite="item/iron-gear-wheel"}

  -- Main in-game panel that shows stats, current settings and can be used to go back to the lobby.
  global.main_elements[player_index].main_dialog = player.gui.left.add{type="frame", visible=false, name="main_dialog", direction="vertical"}
  global.main_elements[player_index].main_dialog.caption = {"sw.main_dialog_caption"}
  global.main_elements[player_index].main_dialog_inner_frame = global.main_elements[player_index].main_dialog.add{type="frame", style="inside_shallow_frame_with_padding",name="game_info", direction="vertical"}
  local time_row = global.main_elements[player_index].main_dialog_inner_frame.add{type="flow"}
  time_row.add{type="label", caption={"sw.time"}, name="time_label"}
  global.main_elements[player_index].time_value = time_row.add{type="label", caption="", name="time_value"}

  local evo_row = global.main_elements[player_index].main_dialog_inner_frame.add{type="flow"}
  evo_row.style.horizontal_spacing = 78
  local evo_label = evo_row.add{type="label", caption={"sw.evo"}, name="evo"}
  global.main_elements[player_index].evo_value = evo_row.add{type="label", caption="", name="evo_value"}
  global.main_elements[player_index].reset_button = global.main_elements[player_index].main_dialog_inner_frame.add{type="button", caption={"sw.vote_reset"}, name="reset_button"}
  global.main_elements[player_index].reset_button.style.width = 0
  global.main_elements[player_index].reset_button.style.top_margin = 10
  global.main_elements[player_index].reset_button.style.horizontally_stretchable = "on"

  global.main_elements[player_index].vote_frame = global.main_elements[player_index].main_dialog.add{type="frame", direction="vertical", visible=false, style="inside_shallow_frame_with_padding"}
  global.main_elements[player_index].vote_frame.style.top_margin = 10
  global.main_elements[player_index].vote_label = global.main_elements[player_index].vote_frame.add{type="label", caption={"sw.vote_label"}}
  global.main_elements[player_index].vote_results = global.main_elements[player_index].vote_frame.add{type="label", caption=""}
  global.main_elements[player_index].vote_flow= global.main_elements[player_index].vote_frame.add{type="frame", style="invisible_frame"}
  global.main_elements[player_index].yes_button = global.main_elements[player_index].vote_flow.add{type="button", caption={"sw.yes_button"}, name="yes_button"}
  global.main_elements[player_index].abstain_button = global.main_elements[player_index].vote_flow.add{type="button", caption={"sw.abstain_button"}, name="abstain_button"}
  global.main_elements[player_index].no_button = global.main_elements[player_index].vote_flow.add{type="button", caption={"sw.no_button"}, name="no_button"}
  global.main_elements[player_index].yes_button.style.top_margin = 10
  global.main_elements[player_index].yes_button.style.horizontally_stretchable = "on"
  global.main_elements[player_index].abstain_button.style.top_margin = 10
  global.main_elements[player_index].abstain_button.style.horizontally_stretchable = "on"
  global.main_elements[player_index].no_button.style.top_margin = 10
  global.main_elements[player_index].no_button.style.horizontally_stretchable = "on"

  -- Lobby modal for setting map settings and starting the game.
  global.main_elements[player_index].lobby_modal = player.gui.screen.add{type="frame", visible=true, name="lobby_modal", caption={"sw.lobby"}, direction="vertical"}
  global.main_elements[player_index].lobby_modal.auto_center = true

  local inner_frame = global.main_elements[player_index].lobby_modal.add{type="frame", style="inside_deep_frame", name="game_info", direction="vertical"}

  local game_info_frame = inner_frame.add{type="frame", style="inner_frame"}
  local text_box = game_info_frame.add{type="text-box", text="Welcome to Deathworld Survival. Take a look at the settings and pick your poison. The game resets if biters settle on your spawn point. It also resets unconditionally if it hasn't been reset for 7 days. This scenario is WIP so expect some bugs.", style="map_generator_preset_description"}
  text_box.read_only = true
  text_box.word_wrap= true
  text_box.style.minimal_width = 380
  text_box.style.minimal_height = 110
  game_info_frame.style.horizontally_stretchable = true
  local tabbed_pane = inner_frame.add{type="tabbed-pane"}
  tabbed_pane.style.horizontally_stretchable = true

  local settings = tabbed_pane.add{type="tab", caption="Settings"}
  local settings_content = tabbed_pane.add{type="flow", direction="vertical"}
  settings_content.style.padding = 5;

  global.main_elements[player_index].biter_regen_checkbox = settings_content.add{type="checkbox", state=global.current_settings.biter_regen, caption="Biter Regen", name="biter_regen_checkbox"}
  global.main_elements[player_index].biter_regen_checkbox.tooltip = {"sw.biter_regen_tooltip"}
  global.main_elements[player_index].pitch_black_checkbox = settings_content.add{type="checkbox", state=global.current_settings.pitch_black, caption="Pitch Black Night", name="pitch_black_checkbox"}
  global.main_elements[player_index].pitch_black_checkbox.tooltip = {"sw.pitch_black_tooltip"}
  global.main_elements[player_index].shallow_water_checkbox = settings_content.add{type="checkbox", state=global.current_settings.shallow_water, caption="Shallow Water", name="shallow_water_checkbox"}
  global.main_elements[player_index].shallow_water_checkbox.tooltip = {"sw.shallow_water_tooltip"}
  global.main_elements[player_index].robots_checkbox = settings_content.add{type="checkbox", state=global.current_settings.robots, caption="Construction Robot Start", name="robots_checkbox"}
  global.main_elements[player_index].robots_checkbox .tooltip = {"sw.robots_tooltip"}

  local players = tabbed_pane.add{type="tab", caption="Players"}
  global.main_elements[player_index].players_content = tabbed_pane.add{type="flow", name="players_content", direction="vertical"}
  global.main_elements[player_index].players_content.style.padding = 5;

  tabbed_pane.add_tab(settings, settings_content)
  tabbed_pane.add_tab(players, global.main_elements[player_index].players_content)
  tabbed_pane.selected_tab_index = 1
  local bottom_buttons_flow = global.main_elements[player_index].lobby_modal.add{type="flow"}
  global.main_elements[player_index].preview_button = bottom_buttons_flow.add{type="button", caption={"sw.preview"}, name="preview_button"}
  global.main_elements[player_index].start_button = bottom_buttons_flow.add{type="button", caption={"sw.start_game"}, name="start_button"}
  global.main_elements[player_index].start_button.style.width = 0
  global.main_elements[player_index].start_button.style.top_margin = 5
  global.main_elements[player_index].start_button.style.horizontally_stretchable = "on"

  global.main_elements[player_index].preview_button.style.width = 0
  global.main_elements[player_index].preview_button.style.top_margin = 5
  global.main_elements[player_index].preview_button.style.horizontally_stretchable = "on"
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
  		global.charted_surface = false
      global.has_player_recieved_robots = {}
      set_normal_daytime(surface)

      local mgs = surface.map_gen_settings 
    	mgs.water = "1"
    	mgs.terrain_segmentation = "1"
    	mgs.starting_area = "big"
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

      if not global.has_seed_changed then
        local mgs = surface.map_gen_settings 
        mgs.seed = math.random(1111,999999999)
        mgs.width = 0
        mgs.height = 0
        surface.map_gen_settings = mgs
        global.has_seed_changed = true
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

    else 
      log("Failed to reset surface: bad game state")
    end
  end
)

function give_player_robots(player_index)
	  local p = game.get_player(player_index)
    p.character.insert{ name = "modular-armor", count = 1 }
    p.character.insert{ name = "construction-robot", count = 25 }
    local armor_inventory = p.character.get_inventory(defines.inventory.character_armor)
    local armor = armor_inventory.find_item_stack("modular-armor")
    local grid = armor.grid
    grid.put({
        name = "battery-mk2-equipment"
    })
    grid.put({
        name = "battery-mk2-equipment"
    })
    for i=1, 11 do
      grid.put({
          name = "solar-panel-equipment"
      })
    end
    grid.put({
        name = "personal-roboport-mk2-equipment"
    })
end

script.on_event(defines.events.on_player_respawned,
  function(event)
    	if global.current_settings.robots then
    	  if global.has_player_recieved_robots[event.player_index] == nil then
    	    give_player_robots(event.player_index)
    	    global.has_player_recieved_robots[event.player_index] = {}
    	  end
    	end
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

script.on_event(defines.events.on_gui_checked_state_changed, 
  function(event)
    if event.element.name == "biter_regen_checkbox" then
      global.current_settings.biter_regen =  event.element.state
      game.print(game.get_player(event.player_index).name .. " toggled biter regen.")

      for _, player in pairs(game.connected_players) do 
        global.main_elements[player.index].biter_regen_checkbox.state = event.element.state
      end
    elseif event.element.name == "pitch_black_checkbox" then
      global.current_settings.pitch_black =  event.element.state
      game.print(game.get_player(event.player_index).name .. " toggled pitch black.")

      for _, player in pairs(game.connected_players) do 
        global.main_elements[player.index].pitch_black_checkbox.state = event.element.state
      end
    elseif event.element.name == "robots_checkbox" then
      global.current_settings.robots = event.element.state
      game.print(game.get_player(event.player_index).name .. " toggled construction robot start.")

      for _, player in pairs(game.connected_players) do 
        global.main_elements[player.index].robots_checkbox.state = event.element.state
      end
    elseif event.element.name == "shallow_water_checkbox" then
      game.print(game.get_player(event.player_index).name .. " toggled shallow water.")
      global.current_settings.shallow_water = event.element.state

      for _, player in pairs(game.connected_players) do 
        global.main_elements[player.index].shallow_water_checkbox .state = event.element.state
      end
    end

  end
)

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
      end
    end
  end
)

function go_to_lobby()
    global.has_seed_changed = false
    global.game_state  = "in_lobby"
    global.current_settings = {}
    game.surfaces[1].clear()
    for _, player in pairs(game.connected_players) do 
      if global.main_elements[player.index] ~= nil then
        global.main_elements[player.index].main_dialog.visible = false
        global.main_elements[player.index].lobby_modal.visible = true
      end 
    end 
end

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
      game.forces["player"].add_chart_tag(1, {position={50, -50}, icon={type="virtual", name="signal-green"}, text="Deathworld Survival Discord https://discord.gg/xYGNBaWEuC"} )
  	end

    for _, player in pairs(game.connected_players) do 
      if global.vote_tally.tick_to_finish_voting ~= nil then
        if global.vote_tally.tick_to_finish_voting <= game.tick then
            end_vote()
        else
            global.main_elements[player.index].vote_results.caption = string.format("Yes/No: %d/%d, Time Remaining: %s", global.vote_tally.yes_total, global.vote_tally.no_total, format_play_time(global.vote_tally.tick_to_finish_voting - game.tick))
        end
      end
      if global.main_elements[player.index] ~= nil then
        local percent_evo_factor = game.forces.enemy.evolution_factor * 100
        global.main_elements[player.index].evo_value.caption = string.format("%.1f%%", percent_evo_factor)
        global.main_elements[player.index].time_value.caption = format_play_time(game.ticks_played) 
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
    if global.game_state == "in_game" then
       global.main_elements[event.player_index].lobby_modal.visible = false 
    end
    refresh_all_players_list(event)
  end
)

script.on_event(defines.events.on_unit_group_finished_gathering, 
  function(event)
    print("finished gathering")
  end
)

script.on_event(defines.events.on_player_created,
  function(event)
    global.main_elements[event.player_index] = {}
    add_gui_to_player(event.player_index)
    if global.game_state == "in_game" then
     global.main_elements[event.player_index].lobby_modal.visible = false 
    end
    refresh_player_gui(event.player_index)
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

