extends Node
## NavigationContainer: Manages navigation and screen transitions with a bottom nav bar

# Screen states
enum ScreenState {
	SPLASH,
	CHARACTER_CREATION,
	MAIN_MENU,
	TAVERN_HUB,
	QUEST_BOARD,
	CHARACTER_PROFILE,
	QUEST_DETAILS,
	ADVENTURES,
	MORE
}

# Reference to screens container and bottom nav bar
@onready var screens_container = $UIRoot/MainContainer/ScreensContainer
@onready var bottom_nav_bar = $UIRoot/BottomNavBar
@onready var notification_layer = $UIRoot/NotificationLayer
@onready var popup_layer = $UIRoot/PopupLayer

# Current screen state
var current_screen_state = ScreenState.SPLASH
var previous_screen_states = []

# Screen history for back navigation
var screen_history = []

# Store references to screen instances
var screen_instances = {}

func _ready():
	print("NavigationContainer: Initializing")
	
	# Wait for all autoloads to be ready
	await get_tree().process_frame
	
	# Set up UI references in the UIManager
	if get_node_or_null("/root/UIManager"):
		UIManager.set_main_container(screens_container)
		UIManager.set_toast_container(notification_layer)
	
	# Connect bottom nav bar signals
	if bottom_nav_bar:
		bottom_nav_bar.nav_button_pressed.connect(_on_nav_button_pressed)
	
	# Hide bottom nav on startup (only show after character creation)
	if bottom_nav_bar:
		bottom_nav_bar.visible = false
	
	# Initialize game state
	if get_node_or_null("/root/GameManager"):
		GameManager.connect("game_initialized", Callable(self, "_on_game_initialized"))
	
	_load_initial_screen()

# Load the initial screen based on save state
func _load_initial_screen():
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
	print("NavigationContainer: Loading splash screen")
	_navigate_to(ScreenState.SPLASH)

# Handle nav button press from bottom bar
func _on_nav_button_pressed(screen_name: String):
	print("NavigationContainer: Nav button pressed - " + screen_name)
	
	match screen_name:
		"tavern":
			_navigate_to(ScreenState.TAVERN_HUB)
		"quest_board":
			_navigate_to(ScreenState.QUEST_BOARD)
		"character_profile":
			_navigate_to(ScreenState.CHARACTER_PROFILE)
		"adventures":
			_navigate_to(ScreenState.ADVENTURES)
		"more":
			_navigate_to(ScreenState.MORE)
		_:
			print("NavigationContainer: Unknown screen name - " + screen_name)

# Navigate to a specific screen
func _navigate_to(screen_state, data = null):
	previous_screen_states.push_back(current_screen_state)
	current_screen_state = screen_state
	
	# Clear existing screens if needed
	if screens_container.get_child_count() > 0:
		for child in screens_container.get_children():
			# Don't remove screens we want to keep in memory
			if _should_keep_screen_loaded(child):
				child.visible = false
			else:
				child.queue_free()
	
	# Determine which scene to load
	var scene_path = ""
	var need_bottom_nav = true
	
	match screen_state:
		ScreenState.SPLASH:
			scene_path = "res://scenes/main_menu/splash_screen.tscn"
			need_bottom_nav = false
		ScreenState.CHARACTER_CREATION:
			scene_path = "res://scenes/character/character_creation.tscn"
			need_bottom_nav = false
		ScreenState.MAIN_MENU:
			scene_path = "res://scenes/main_menu/main_menu.tscn"
		ScreenState.TAVERN_HUB:
			scene_path = "res://scenes/main_menu/tavern_hub.tscn"
		ScreenState.QUEST_BOARD:
			scene_path = "res://scenes/quests/quest_board_new.tscn"
		ScreenState.CHARACTER_PROFILE:
			scene_path = "res://scenes/character/character_profile.tscn"
		ScreenState.QUEST_DETAILS:
			scene_path = "res://scenes/quests/quest_details.tscn"
			# Pass data to quest details if needed
		ScreenState.ADVENTURES:
			# Adventures screen not yet implemented
			scene_path = ""
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Adventures feature coming soon!", "info")
			return
		ScreenState.MORE:
			scene_path = "res://scenes/main_menu/more_screen.tscn"
	
	# Show/hide bottom navigation
	if bottom_nav_bar:
		bottom_nav_bar.visible = need_bottom_nav
	
	# Update bottom nav active button
	if bottom_nav_bar and need_bottom_nav:
		match screen_state:
			ScreenState.MAIN_MENU, ScreenState.TAVERN_HUB:
				bottom_nav_bar.set_active_button("tavern")
			ScreenState.QUEST_BOARD:
				bottom_nav_bar.set_active_button("quest_board")
			ScreenState.CHARACTER_PROFILE:
				bottom_nav_bar.set_active_button("character_profile")
			ScreenState.MORE:
				bottom_nav_bar.set_active_button("more")
			ScreenState.ADVENTURES:
				bottom_nav_bar.set_active_button("adventures")
	
	# Load and instantiate the scene if path is valid
	if scene_path != "":
		var screen_scene = load(scene_path)
		if screen_scene:
			var screen_instance = screen_scene.instantiate()
			screens_container.add_child(screen_instance)
			
			# Initialize with data if needed
			if data != null and screen_instance.has_method("initialize"):
				screen_instance.initialize(data)
		else:
			print("NavigationContainer: Failed to load scene - " + scene_path)

# Determines if a screen should be kept loaded (not freed)
func _should_keep_screen_loaded(_screen_node: Node) -> bool:
	# For now, we don't keep any screens in memory
	# In the future, we might want to cache certain screens
	return false

# Handle callback from character creation
func _on_character_created():
	# Navigate to tavern hub
	_navigate_to(ScreenState.TAVERN_HUB)
	
	# Show bottom nav
	if bottom_nav_bar:
		bottom_nav_bar.visible = true

func _on_game_initialized():
	print("NavigationContainer: Game systems initialized")
