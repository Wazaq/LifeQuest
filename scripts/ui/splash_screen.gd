extends Control
## SplashScreen: Initial screen shown when the app launches

@onready var start_button = $VBoxContainer/StartButton

func _ready():
	print("SplashScreen: Ready")
	
	# Debug output
	print("SplashScreen: StartButton exists: ", start_button != null)
	
	# We'll use a different method to get the button - directly from the scene
	var direct_button = get_node_or_null("VBoxContainer/StartButton")
	
	# Connect signals using shorter syntax
	if direct_button:
		# Clear any existing connections first
		if direct_button.is_connected("pressed", Callable(self, "_on_start_button_pressed")):
			direct_button.disconnect("pressed", Callable(self, "_on_start_button_pressed"))
		
		# Connect with shorter syntax
		direct_button.pressed.connect(_on_start_button_pressed)
	else:
		push_error("SplashScreen: StartButton not found!")

# Helper function to find the screens container by traversing up from this node
func find_screens_container() -> Control:
	# First try getting it from UIManager
	if get_node_or_null("/root/UIManager") and UIManager.main_container:
		return UIManager.main_container
	
	# If not found, try finding it in the scene tree
	var current_node = self
	var max_iterations = 10  # Avoid infinite loops
	var iteration = 0
	
	while current_node and iteration < max_iterations:
		# If this is the screens container itself
		if current_node.name == "ScreensContainer":
			return current_node
		
		# Look for a ScreensContainer child
		var screens = current_node.get_node_or_null("ScreensContainer")
		if screens:
			return screens
		
		# Look for deeper paths
		screens = current_node.get_node_or_null("UIRoot/MainContainer/ScreensContainer")
		if screens:
			return screens
		
		screens = current_node.get_node_or_null("MainContainer/ScreensContainer")
		if screens:
			return screens
		
		# Go up to parent
		current_node = current_node.get_parent()
		iteration += 1
	
	# Last resort: try to find it directly from the root
	var root = get_tree().get_root()
	var node = root.get_node_or_null("Main/UIRoot/MainContainer/ScreensContainer")
	if node:
		return node
	
	# Could not find it
	return null

func _on_start_button_pressed():
	print("SplashScreen: Start button pressed")
	
	# Check if user has existing character
	var has_character = false
	if get_node_or_null("/root/DataManager"):
		has_character = DataManager.has_character_save()
	
	# First try using the navigation system (preferred approach)
	var main_node = get_node_or_null("/root/Main")
	if main_node and main_node.has_method("_navigate_to"):
		if has_character:
			# Character exists, go to tavern hub
			main_node._navigate_to(main_node.ScreenState.TAVERN_HUB)
		else:
			# No character, go to character intro
			main_node._navigate_to(main_node.ScreenState.CHARACTER_INTRO)
		return  # Important! Return here to avoid running legacy code
	
	# Legacy approach (fallback) - only runs if navigation system not found
	#TODO: This section may be OBE 88 - 122
	print("SplashScreen: Using legacy navigation (fallback)")
	
	if has_character:
		# Load the main menu scene
		var main_menu = load("res://scenes/main_menu/main_menu.tscn").instantiate()
		
		# Find the screens container
		var screens_container = find_screens_container()
		
		if screens_container:
			# Add the main menu to the container
			screens_container.add_child(main_menu)
			
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Navigating to Main Menu", "info")
				UIManager.change_screen(main_menu)
		else:
			push_error("SplashScreen: Could not find screens container")
	else:
		# Load the character creation scene
		var character_creation = load("res://scenes/character/character_creation.tscn").instantiate()
		
		# Find the screens container
		var screens_container = find_screens_container()
		
		if screens_container:
			# Change to the character creation screen
			screens_container.add_child(character_creation)
			
			if get_node_or_null("/root/UIManager"):
				UIManager.change_screen(character_creation)
		else:
			push_error("SplashScreen: Could not find screens container")
	
	# Queue self for removal after transition
	await get_tree().create_timer(0.5).timeout
	queue_free()
