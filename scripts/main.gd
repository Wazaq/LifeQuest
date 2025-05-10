extends Node
## Main: Root node for the LifeQuest application

# References to UI containers
@onready var ui_root: Control = $UIRoot
@onready var screens_container: Control = $UIRoot/MainContainer/ScreensContainer
@onready var notification_layer: Control = $UIRoot/NotificationLayer
@onready var popup_layer: Control = $UIRoot/PopupLayer

func _ready():
	print("Main: Initializing LifeQuest application...")
	
	# Wait for all autoloads to be ready
	await get_tree().process_frame
	
	# Set up UI references in the UIManager
	if get_node_or_null("/root/UIManager"):
		UIManager.set_main_container(screens_container)
		UIManager.set_toast_container(notification_layer)
	
	# Initialize game state
	if get_node_or_null("/root/GameManager"):
		GameManager.connect("game_initialized", Callable(self, "_on_game_initialized"))
	
	load_initial_screen()

func load_initial_screen():
	# Check if the user has a saved character
	var has_character = false
	if get_node_or_null("/root/DataManager"):
		has_character = DataManager.has_character_save()
		
		if has_character:
			# Load the character data
			var character_data = DataManager.load_character()
			if character_data and get_node_or_null("/root/ProfileManager"):
				# Update the ProfileManager with the loaded character data
				ProfileManager.update_character(character_data.to_dictionary())
	
	# For now, always load the splash screen first
	print("Main: Loading splash screen")
	var splash_screen = load("res://scenes/main_menu/splash_screen.tscn").instantiate()
	screens_container.add_child(splash_screen)
	
	# We'll transition to character creation or main menu based on user action
	# in the splash screen

func _on_game_initialized():
	print("Main: Game systems initialized")
