local mod_gui = require('mod-gui')

ui = {}

ui.format_play_time = function (ticks)
    local seconds = math.floor(ticks / 60)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    local days = math.floor(hours / 24)

    hours = hours % 24
    result =  string.format("%d:%02d:%02d", hours, minutes % 60, seconds % 60)
    return result
end

ui.reset_main_ui = function(player_index)
    global.main_elements[player_index].vote_frame.visible = false
    global.main_elements[player_index].reset_button.visible = true
end

ui.add_gui_to_player = function(player_index)
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
  global.main_elements[player_index].reset_button.style.vertically_stretchable = "on"

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
  local text_box = game_info_frame.add{type="text-box", text="Welcome to Deathworld Survival. Take a look at the settings and pick your poison. The game resets if biters settle on your spawn point. It also resets unconditionally if it hasn't been reset for 7 days. Control over the settings below is shared between all players. This scenario is WIP so expect some bugs.", style="map_generator_preset_description"}
  text_box.read_only = true
  text_box.word_wrap= true
  text_box.style.minimal_width = 340
  text_box.style.minimal_height = 120
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

  local map_settings = tabbed_pane.add{type="tab", caption="Map Generation"}
  local map_settings_content = tabbed_pane.add{type="table", column_count=4, draw_horizontal_line_after_headers=true, vertical_centering=true}
  map_settings_content.style.padding = 5;
  map_settings_content.style.horizontal_align = "center";
  map_settings_content.add{type="label", caption="Resource"}
  map_settings_content.add{type="label", caption="Size"}
  map_settings_content.add{type="label", caption="Frequency"}
  map_settings_content.add{type="label", caption="Richness"}

  map_settings_content.add{type="label", caption="Iron", name="iron_label"}
  global.main_elements[player_index].iron_size_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.iron_size}
  global.main_elements[player_index].iron_frequency_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.iron_frequency}
  global.main_elements[player_index].iron_richness_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.iron_richness}

  map_settings_content.add{type="label", caption="Copper", name="copper_label"}
  global.main_elements[player_index].copper_size_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.copper_size}
  global.main_elements[player_index].copper_frequency_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.copper_frequency}
  global.main_elements[player_index].copper_richness_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.copper_richness}

  map_settings_content.add{type="label", caption="Coal", name="coal_label"}
  global.main_elements[player_index].coal_size_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.coal_size}
  global.main_elements[player_index].coal_frequency_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.coal_frequency}
  global.main_elements[player_index].coal_richness_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.coal_richness}

  map_settings_content.add{type="label", caption="Stone", name="stone_label"}
  global.main_elements[player_index].stone_size_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.stone_size}
  global.main_elements[player_index].stone_frequency_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.stone_frequency}
  global.main_elements[player_index].stone_richness_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.stone_richness}

  map_settings_content.add{type="label", caption="Oil", name="oil_label"}
  global.main_elements[player_index].oil_size_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.oil_size}
  global.main_elements[player_index].oil_frequency_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.oil_frequency}
  global.main_elements[player_index].oil_richness_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.oil_richness}

  map_settings_content.add{type="label", caption="Uranium", name="uranium_label"}
  global.main_elements[player_index].uranium_size_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.uranium_size}
  global.main_elements[player_index].uranium_frequency_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.uranium_frequency}
  global.main_elements[player_index].uranium_richness_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.uranium_richness}

  map_settings_content.add{type="label", caption="Trees", name="trees_label"}
  global.main_elements[player_index].trees_size_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.trees_size}
  global.main_elements[player_index].trees_frequency_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.trees_frequency}
  global.main_elements[player_index].trees_richness_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.trees_richness}

  map_settings_content.add{type="label", caption="Biters", name="biter_label"}
  global.main_elements[player_index].biter_size_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.biter_size}
  global.main_elements[player_index].biter_frequency_slider = map_settings_content.add{type="textfield", numeric=true, allow_decimal=true, text=global.current_settings.biter_frequency}

  for i, c in pairs(map_settings_content.children) do 
    if c.type ~= "label" then
      c.style.top_margin = 4
      c.style.right_margin = 2
      c.style.width = 60
    else
      c.style.bottom_margin = 4
    end
  end

  local presets = tabbed_pane.add{type="tab", caption="Presets"}
  local presets_content = tabbed_pane.add{type="flow", direction="vertical"}
  presets_content.style.padding = 5;

  local players = tabbed_pane.add{type="tab", caption="Players"}
  global.main_elements[player_index].players_content = tabbed_pane.add{type="flow", name="players_content", direction="vertical"}
  global.main_elements[player_index].players_content.style.padding = 5;

  tabbed_pane.add_tab(settings, settings_content)
  tabbed_pane.add_tab(map_settings, map_settings_content)
  tabbed_pane.add_tab(presets, presets_content)
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

  if global.game_state == "in_game" then
   global.main_elements[player_index].lobby_modal.visible = false 
  end
end

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

script.on_event(defines.events.on_gui_text_changed, 
  function(event)
    if event.element.index == global.main_elements[event.player_index].iron_size_slider.index then
      global.current_settings.iron_size = global.main_elements[event.player_index].iron_size_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].iron_size_slider.text = global.current_settings.iron_size 
      end
  	elseif event.element.index == global.main_elements[event.player_index].iron_frequency_slider.index then
    	global.current_settings.iron_frequency = global.main_elements[event.player_index].iron_frequency_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].iron_frequency_slider.text = global.current_settings.iron_frequency 
      end
  	elseif event.element.index == global.main_elements[event.player_index].iron_richness_slider.index then
    	global.current_settings.iron_richness = global.main_elements[event.player_index].iron_richness_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].iron_richness_slider.text = global.current_settings.iron_richness 
      end
  	elseif event.element.index == global.main_elements[event.player_index].copper_size_slider.index then
    	global.current_settings.copper_size = global.main_elements[event.player_index].copper_size_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].copper_size_slider.text = global.current_settings.copper_size 
      end
  	elseif event.element.index == global.main_elements[event.player_index].copper_frequency_slider.index then
      	global.current_settings.copper_frequency = global.main_elements[event.player_index].copper_frequency_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].copper_frequency_slider.text = global.current_settings.copper_frequency 
      end
  	elseif event.element.index == global.main_elements[event.player_index].copper_richness_slider.index then
      	global.current_settings.copper_richness = global.main_elements[event.player_index].copper_richness_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].copper_richness_slider.text = global.current_settings.copper_richness 
      end
  	elseif event.element.index == global.main_elements[event.player_index].coal_size_slider.index then
      	global.current_settings.coal_size = global.main_elements[event.player_index].coal_size_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].coal_size_slider.text = global.current_settings.coal_size 
      end
  	elseif event.element.index == global.main_elements[event.player_index].coal_frequency_slider.index then
      global.current_settings.coal_frequency = global.main_elements[event.player_index].coal_frequency_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].coal_frequency_slider.text = global.current_settings.coal_frequency 
      end
  	elseif event.element.index == global.main_elements[event.player_index].coal_richness_slider.index then
      	global.current_settings.coal_richness = global.main_elements[event.player_index].coal_richness_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].coal_richness_slider.text = global.current_settings.coal_richness 
      end
  	elseif event.element.index == global.main_elements[event.player_index].stone_size_slider.index then
      	global.current_settings.stone_size = global.main_elements[event.player_index].stone_size_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].stone_size_slider.text = global.current_settings.stone_size 
      end
  	elseif event.element.index == global.main_elements[event.player_index].stone_frequency_slider.index then
      	global.current_settings.stone_frequency = global.main_elements[event.player_index].stone_frequency_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].stone_frequency_slider.text = global.current_settings.stone_frequency 
      end
  	elseif event.element.index == global.main_elements[event.player_index].stone_richness_slider.index then
      	global.current_settings.stone_richness = global.main_elements[event.player_index].stone_richness_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].stone_richness_slider.text = global.current_settings.stone_richness 
      end
  	elseif event.element.index == global.main_elements[event.player_index].oil_size_slider.index then
      	global.current_settings.oil_size = global.main_elements[event.player_index].oil_size_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].oil_size_slider.text = global.current_settings.oil_size 
      end
  	elseif event.element.index == global.main_elements[event.player_index].oil_frequency_slider.index then
      	global.current_settings.oil_frequency = global.main_elements[event.player_index].oil_frequency_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].oil_frequency_slider.text = global.current_settings.oil_frequency 
      end
  	elseif event.element.index == global.main_elements[event.player_index].oil_richness_slider.index then
      	global.current_settings.oil_richness = global.main_elements[event.player_index].oil_richness_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].oil_richness_slider.text = global.current_settings.oil_richness 
      end
  	elseif event.element.index == global.main_elements[event.player_index].uranium_size_slider.index then
      	global.current_settings.uranium_size = global.main_elements[event.player_index].uranium_size_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].uranium_size_slider.text = global.current_settings.uranium_size 
      end
  	elseif event.element.index == global.main_elements[event.player_index].uranium_frequency_slider.index then
      	global.current_settings.uranium_frequency = global.main_elements[event.player_index].uranium_frequency_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].uranium_frequency_slider.text = global.current_settings.uranium_frequency 
      end
  	elseif event.element.index == global.main_elements[event.player_index].uranium_richness_slider.index then
      	global.current_settings.uranium_richness = global.main_elements[event.player_index].uranium_richness_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].uranium_richness_slider.text = global.current_settings.uranium_richness 
      end
  	elseif event.element.index == global.main_elements[event.player_index].trees_size_slider.index then
      	global.current_settings.trees_size = global.main_elements[event.player_index].trees_size_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].trees_size_slider.text = global.current_settings.trees_size 
      end
  	elseif event.element.index == global.main_elements[event.player_index].trees_frequency_slider.index then
      	global.current_settings.trees_frequency = global.main_elements[event.player_index].trees_frequency_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].trees_frequency_slider.text = global.current_settings.trees_frequency 
      end
  	elseif event.element.index == global.main_elements[event.player_index].trees_richness_slider.index then
      	global.current_settings.trees_richness = global.main_elements[event.player_index].trees_richness_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].trees_richness_slider.text = global.current_settings.trees_richness 
      end
  	elseif event.element.index == global.main_elements[event.player_index].biter_size_slider.index then
      	global.current_settings.biter_size = global.main_elements[event.player_index].biter_size_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].biter_size_slider.text = global.current_settings.biter_size 
      end
  	elseif event.element.index == global.main_elements[event.player_index].biter_frequency_slider.index then
      	global.current_settings.biter_frequency = global.main_elements[event.player_index].biter_frequency_slider.text
      for _, player in pairs(game.connected_players) do 
      	global.main_elements[player.index].biter_frequency_slider.text = global.current_settings.biter_frequency 
  	  end
  	end
  end
)

return ui
