extends Control
## MoreScreen: Screen for additional options and settings

@onready var reset_button = $MarginContainer/VBoxContainer/ResetButton
@onready var debug_section = $MarginContainer/VBoxContainer/DebugSection

func _ready():
	print("MoreScreen: Ready")
	
	# Show/hide debug section based on debug availability
	var debug_available = GameManager.is_debug_mode_available()
	
	if not debug_available:
		reset_button.visible = false
		if debug_section:
			debug_section.visible = false
	else:
		_setup_debug_buttons()
	
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

func _setup_debug_buttons():
	"""Setup debug buttons if debug section exists"""
	if not debug_section:
		print("MoreScreen: No debug section found in scene")
		return
	
	# Connect debug buttons
	var start_tutorial_btn = debug_section.get_node_or_null("StartTutorialButton")
	var quest_board_btn = debug_section.get_node_or_null("QuestBoardTutorialButton") 
	var character_profile_btn = debug_section.get_node_or_null("CharacterProfileTutorialButton")
	var reset_tutorial_btn = debug_section.get_node_or_null("ResetTutorialButton")
	var add_quests_btn = debug_section.get_node_or_null("AddTestQuestsButton")
	
	if start_tutorial_btn:
		start_tutorial_btn.connect("pressed", Callable(self, "_on_start_tutorial_directly"))
	if quest_board_btn:
		quest_board_btn.connect("pressed", Callable(self, "_on_jump_to_quest_board_tutorial"))
	if character_profile_btn:
		character_profile_btn.connect("pressed", Callable(self, "_on_jump_to_character_profile_tutorial"))
	if reset_tutorial_btn:
		reset_tutorial_btn.connect("pressed", Callable(self, "_on_reset_tutorial_only"))
	if add_quests_btn:
		add_quests_btn.connect("pressed", Callable(self, "_on_add_test_quests"))

# Debug button handlers
func _on_start_tutorial_directly():
	if GameManager.is_debug_mode_available():
		GameManager.get_debug_manager().start_tutorial_directly()

func _on_jump_to_quest_board_tutorial():
	if GameManager.is_debug_mode_available():
		GameManager.get_debug_manager().jump_to_quest_board_tutorial()

func _on_jump_to_character_profile_tutorial():
	if GameManager.is_debug_mode_available():
		GameManager.get_debug_manager().jump_to_character_profile_tutorial()

func _on_reset_tutorial_only():
	if GameManager.is_debug_mode_available():
		GameManager.get_debug_manager().reset_tutorial_only()

func _on_add_test_quests():
	if GameManager.is_debug_mode_available():
		GameManager.get_debug_manager().add_test_quests()

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
