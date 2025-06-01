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
	
	# Navigation system not found - this should not happen in production
	push_error("SplashScreen: Navigation system not available!")
	
	# Queue self for removal after transition
	await get_tree().create_timer(0.5).timeout
	queue_free()

