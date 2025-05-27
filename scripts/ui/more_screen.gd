extends Control
## MoreScreen: Screen for additional options and settings

@onready var reset_button = $MarginContainer/VBoxContainer/ResetButton

func _ready():
	print("MoreScreen: Ready")
	
	if not GameManager.is_debug_enabled(GameManager.DebugCategory.GAME_STATE):
		reset_button.visible = false
	
	# Add margin to container
	var margin_container = $MarginContainer
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_bottom", 90) # Extra bottom margin for nav bar
	
	# Make header label bigger
	var header_label = $MarginContainer/VBoxContainer/HeaderLabel
	header_label.add_theme_font_size_override("font_size", 24)
	
	# Style the reset button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.7, 0.3, 0.3, 1.0) # Red for danger
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	reset_button.add_theme_stylebox_override("normal", style)
	
	# Connect reset button
	reset_button.connect("pressed", Callable(self, "_on_reset_button_pressed"))

func _on_reset_button_pressed():
	print("MoreScreen: Reset button pressed")
	
	# Delete save files
	if get_node_or_null("/root/DataManager"):
		DataManager.delete_save_file(DataManager.CHARACTER_SAVE_FILE)
		DataManager.delete_save_file(DataManager.ACTIVE_QUESTS_SAVE_FILE)
		DataManager.delete_save_file(DataManager.COMPLETED_QUESTS_SAVE_FILE)
		DataManager.delete_save_file(DataManager.SETTINGS_SAVE_FILE)
		
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Game data reset successfully!", "success")
		
		# Return to splash screen
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.has_method("_navigate_to"):
			main_node._navigate_to(main_node.ScreenState.SPLASH)
		else:
			print("MoreScreen: Legacy navigation fallback")
