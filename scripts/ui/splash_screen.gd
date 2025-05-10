extends Control
## SplashScreen: Initial screen shown when the app launches

@onready var start_button = $VBoxContainer/StartButton

func _ready():
	print("SplashScreen: Ready")
	
	# Debug output
	print("SplashScreen: StartButton exists: ", start_button != null)
	
	# We'll use a different method to get the button - directly from the scene
	var direct_button = get_node_or_null("VBoxContainer/StartButton")
	print("SplashScreen: Direct button reference exists: ", direct_button != null)
	
	# Connect signals using shorter syntax
	if direct_button:
		# Clear any existing connections first
		if direct_button.is_connected("pressed", Callable(self, "_on_start_button_pressed")):
			direct_button.disconnect("pressed", Callable(self, "_on_start_button_pressed"))
		
		# Connect with shorter syntax
		direct_button.pressed.connect(_on_start_button_pressed)
		print("SplashScreen: Button connected with shorter syntax")
		
		# Add a direct callback for testing
		direct_button.pressed.connect(func(): print("DIRECT CALLBACK TRIGGERED"))
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
	
	if has_character:
		# Actually navigate to the main menu scene
		print("SplashScreen: Navigating to main_menu.tscn")
		
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
				
			# Queue self for removal after a short delay
			await get_tree().create_timer(0.5).timeout
			queue_free()
		else:
			push_error("SplashScreen: Could not find screens container")
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Error: Could not find screens container", "error")
	else:
		# Navigate to character creation scene
		print("SplashScreen: Navigating to character_creation.tscn")
		
		# Load the character creation scene
		var character_creation = load("res://scenes/character/character_creation.tscn").instantiate()
		
		# Find the screens container by going up the node tree from this node
		var screens_container = find_screens_container()
		
		if screens_container:
			# Change to the character creation screen
			screens_container.add_child(character_creation)
			
			if get_node_or_null("/root/UIManager"):
				UIManager.change_screen(character_creation)
		else:
			push_error("SplashScreen: Could not find screens container")
			
		# Queue self for removal after a short delay to ensure animations complete
		await get_tree().create_timer(0.5).timeout
		queue_free()
