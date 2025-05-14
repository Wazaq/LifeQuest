extends Control
## CharacterCreation: Allows the user to create their character

@onready var name_edit: LineEdit = $Panel/MarginContainer/VBoxContainer/NameEdit
@onready var create_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CreateButton

func _ready():
	print("CharacterCreation: Ready")
	
	# Connect signals
	create_button.connect("pressed", Callable(self, "_on_create_button_pressed"))

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

func _on_create_button_pressed():
	var character_name = name_edit.text.strip_edges()
	
	# Validate name
	if character_name.is_empty():
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Please enter a name for your character", "warning")
		return
	
	print("CharacterCreation: Creating character with name: %s" % character_name)
	
	# Create the character
	if get_node_or_null("/root/ProfileManager"):
		var character = ProfileManager.create_character(character_name)
		
		# Save the character data
		if get_node_or_null("/root/DataManager"):
			var success = DataManager.save_character(character)
			if success:
				if get_node_or_null("/root/UIManager"):
					UIManager.show_toast("Character created successfully!", "success")
				
				# Check if we're using the new navigation system
				var main_node = get_node_or_null("/root/Main")
				if main_node and main_node.has_method("_navigate_to"):
					# Use the "_on_character_created" callback to handle navigation
					if main_node.has_method("_on_character_created"):
						main_node._on_character_created()
					else:
						main_node._navigate_to(main_node.ScreenState.TAVERN_HUB)
					return
					
				# Legacy approach - navigate to the main menu
				print("CharacterCreation: Navigating to main_menu.tscn")
				
				# Load the main menu scene
				var main_menu = load("res://scenes/main_menu/main_menu.tscn").instantiate()
				
				# Find the screens container by going up the node tree from this node
				var screens_container = find_screens_container()
				
				if screens_container:
					# Change to the main menu screen
					screens_container.add_child(main_menu)
					
					if get_node_or_null("/root/UIManager"):
						UIManager.change_screen(main_menu)
				else:
					push_error("CharacterCreation: Could not find screens container")
					
				# Queue self for removal after a short delay to ensure animations complete
				await get_tree().create_timer(0.5).timeout
				queue_free()
			else:
				if get_node_or_null("/root/UIManager"):
					UIManager.show_toast("Failed to save character data.", "error")
	else:
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Failed to create character: ProfileManager not found.", "error")
