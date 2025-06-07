extends Control
## MoreScreen: Screen for additional options and settings

# Admin / Debug stuff
@onready var reset_button = $MarginContainer/VBoxContainer/DebugSection/ResetButton
@onready var debug_section = $MarginContainer/VBoxContainer/DebugSection

# Player Settings
@onready var player_settings: VBoxContainer = $MarginContainer/VBoxContainer/PlayerSettings
@onready var reset_tutorial_button: Button = $MarginContainer/VBoxContainer/PlayerSettings/ResetTutorialButton
@onready var player_reset: Button = $MarginContainer/VBoxContainer/PlayerSettings/PlayerReset
@onready var confirm_reset_dialog: ConfirmationDialog = $MarginContainer/VBoxContainer/PlayerSettings/PlayerReset/ConfirmReset
@onready var double_confirm_reset_dialog: ConfirmationDialog = $MarginContainer/VBoxContainer/PlayerSettings/PlayerReset/DoubleConfirmReset
@onready var version_label: Label = $MarginContainer/VBoxContainer/VersionLabel


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
	
	# Prepping the Player Settings
	if player_settings:
		_setup_player_settings_buttons()
	
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

func _setup_player_settings_buttons():
	var reset_tutorial_btn = player_settings.get_node_or_null("ResetTutorialButton")
	
	# Connect player reset button
	player_reset.connect("pressed", Callable(self, "_on_player_reset_pressed"))
	
	# Player Confirm delete Dialog Signals
	confirm_reset_dialog.confirmed.connect(_player_dbl_reset_confirmed)
	confirm_reset_dialog.canceled.connect(_player_reset_cancelled)
	double_confirm_reset_dialog.confirmed.connect(_on_reset_button_pressed)
	double_confirm_reset_dialog.canceled.connect(_player_reset_cancelled)
	
	if reset_tutorial_btn:
		reset_tutorial_btn.connect("pressed", Callable(self, "_on_reset_tutorial"))
	
	# Populate the version label
	version_label.text = "Version: " + ProjectSettings.get_setting("application/config/version", "0.0.0-Beta")

func _setup_debug_buttons():
	"""Setup debug buttons if debug section exists"""
	if not debug_section:
		print("MoreScreen: No debug section found in scene")
		return
	
	# Connect debug buttons
	var start_tutorial_btn = debug_section.get_node_or_null("StartTutorialButton")
	var quest_board_btn = debug_section.get_node_or_null("QuestBoardTutorialButton") 
	var character_profile_btn = debug_section.get_node_or_null("CharacterProfileTutorialButton")
	var add_quests_btn = debug_section.get_node_or_null("AddTestQuestsButton")
	var clear_quest_data_btn = debug_section.get_node_or_null("ClearQuestDataButton")
	
	
	if start_tutorial_btn:
		start_tutorial_btn.connect("pressed", Callable(self, "_on_start_tutorial_directly"))
	if quest_board_btn:
		quest_board_btn.connect("pressed", Callable(self, "_on_jump_to_quest_board_tutorial"))
	if character_profile_btn:
		character_profile_btn.connect("pressed", Callable(self, "_on_jump_to_character_profile_tutorial"))
	if add_quests_btn:
		add_quests_btn.connect("pressed", Callable(self, "_on_add_test_quests"))
	if clear_quest_data_btn:
		clear_quest_data_btn.connect("pressed", Callable(self, "_on_clear_quest_data"))

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

func _on_reset_tutorial():
	# This was moved to the Player Settings but will use current setup
	#GameManager.get_debug_manager().reset_tutorial_only()
	DebugManager.reset_tutorial_only()
	UIManager.show_toast("Tutorial Restarted", "info")
	
	# Return to splash screen
	var main_node = get_node_or_null("/root/Main")
	if main_node and main_node.has_method("_navigate_to"):
		main_node._navigate_to(main_node.ScreenState.TAVERN_HUB)

func _on_add_test_quests():
	if GameManager.is_debug_mode_available():
		GameManager.get_debug_manager().add_test_quests()

func _on_clear_quest_data():
	if GameManager.is_debug_mode_available():
		GameManager.get_debug_manager().clear_quest_data()

func _on_reset_button_pressed():
	print("MoreScreen: Reset button pressed")
	
	# Delete save files
	if get_node_or_null("/root/DataManager"):
		DataManager.delete_save_file(DataManager.PLAYER_GAME_DATA_FILE)
		DataManager.delete_save_file(DataManager.PLAYER_QUEST_DATA_FILE)
		DataManager.delete_save_file(DataManager.PLAYER_TUTORIAL_DATA_FILE)
		DataManager.delete_save_file(DataManager.SETTINGS_SAVE_FILE)
		
		# Also clean up legacy files if they exist
		DataManager.delete_save_file(DataManager.LEGACY_CHARACTER_FILE)
		DataManager.delete_save_file(DataManager.LEGACY_QUESTS_FILE)
		DataManager.delete_save_file(DataManager.LEGACY_TUTORIAL_FILE)
		
		if get_node_or_null("/root/QuestManager"):
			# Blow out the quest data
			DebugManager.clear_quest_data()
			
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Game data reset successfully!", "success")
		
		# Return to splash screen
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.has_method("_navigate_to"):
			main_node._navigate_to(main_node.ScreenState.SPLASH)
		else:
			print("MoreScreen: Legacy navigation fallback")

func _on_player_reset_pressed():
	confirm_reset_dialog.visible = true

func _player_dbl_reset_confirmed():
	double_confirm_reset_dialog.visible = true
	
func _player_reset_cancelled():
	confirm_reset_dialog.visible = false
	double_confirm_reset_dialog.visible = false
