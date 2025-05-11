extends Control
## MainMenu: Main navigation hub for the application

@onready var welcome_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderContainer/WelcomeLabel
@onready var quests_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/QuestsButton
@onready var character_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/CharacterButton
var reset_button: Button  # Will be created dynamically

func _ready():
	print("MainMenu: Ready")
	
	# Debug info
	print("MainMenu: Checking UI elements")
	
	if welcome_label:
		print("MainMenu: Welcome label found")
	else:
		print("MainMenu: Welcome label NOT found")
		
	if quests_button:
		print("MainMenu: Quests button found")
	else:
		print("MainMenu: Quests button NOT found")
		
	if character_button:
		print("MainMenu: Character button found")
	else:
		print("MainMenu: Character button NOT found")
	
	# Update welcome message with character name
	if get_node_or_null("/root/ProfileManager") and welcome_label:
		var character_name = "Hero"
		
		# Check if ProfileManager has a character
		if ProfileManager.current_character and ProfileManager.current_character.has("name") and ProfileManager.current_character.name != "":
			character_name = ProfileManager.current_character.name
		
		welcome_label.text = "Welcome, %s!" % character_name
	
	# Connect signals for existing buttons
	quests_button.connect("pressed", Callable(self, "_on_quests_button_pressed"))
	character_button.connect("pressed", Callable(self, "_on_character_button_pressed"))
	
	# Create reset button dynamically
	var buttons_container = get_node("Panel/MarginContainer/VBoxContainer/ButtonsContainer")
	if buttons_container:
		# Create the reset button
		reset_button = Button.new()
		reset_button.text = "Reset Game (Testing)"
		reset_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		reset_button.custom_minimum_size = Vector2(200, 0)
		
		# Connect its signal
		reset_button.connect("pressed", Callable(self, "_on_reset_button_pressed"))
		
		# Add to the container
		buttons_container.add_child(reset_button)
		print("MainMenu: Reset button created")
	else:
		print("MainMenu: Could not find buttons container")

func _on_quests_button_pressed():
	print("MainMenu: Quests button pressed")
	
	# Show a message since we don't have the quests screen yet
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Quests screen would open here", "info")

func _on_character_button_pressed():
	print("MainMenu: Character button pressed")
	
	# Show a message since we don't have the character profile screen yet
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Character profile would open here", "info")

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

func _on_reset_button_pressed():
	print("MainMenu: Reset button pressed")
	
	# Delete save files
	if get_node_or_null("/root/DataManager"):
		DataManager.delete_save_file(DataManager.CHARACTER_SAVE_FILE)
		DataManager.delete_save_file(DataManager.ACTIVE_QUESTS_SAVE_FILE)
		DataManager.delete_save_file(DataManager.COMPLETED_QUESTS_SAVE_FILE)
		DataManager.delete_save_file(DataManager.SETTINGS_SAVE_FILE)
		
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Game data reset successfully!", "success")
			
		# Return to splash screen
		print("MainMenu: Navigating back to splash screen")
		
		# Load the splash screen scene
		var splash_screen = load("res://scenes/main_menu/splash_screen.tscn").instantiate()
		
		# Find the screens container by going up the node tree from this node
		var screens_container = find_screens_container()
		
		if screens_container:
			# Change to the splash screen
			screens_container.add_child(splash_screen)
			
			if get_node_or_null("/root/UIManager"):
				UIManager.change_screen(splash_screen)
		else:
			push_error("MainMenu: Could not find screens container")
			
		# Queue self for removal
		queue_free()
