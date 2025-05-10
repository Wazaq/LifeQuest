extends Control
## CharacterCreation: Allows the user to create their character

@onready var name_edit: LineEdit = $Panel/MarginContainer/VBoxContainer/NameEdit
@onready var create_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CreateButton

func _ready():
	print("CharacterCreation: Ready")
	
	# Connect signals
	create_button.connect("pressed", Callable(self, "_on_create_button_pressed"))

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
				
				# Navigate to the main menu
				print("CharacterCreation: Navigating to main_menu.tscn")
				
				# Load the main menu scene
				var main_menu = load("res://scenes/main_menu/main_menu.tscn").instantiate()
				
				# Add it to the screens container
				var main = get_tree().get_root().get_node("Main")
				var screens_container = main.get_node("UIRoot/MainContainer/ScreensContainer")
				
				# Change to the main menu screen
				screens_container.add_child(main_menu)
				
				if get_node_or_null("/root/UIManager"):
					UIManager.change_screen(main_menu)
					
				# Queue self for removal
				queue_free()
			else:
				if get_node_or_null("/root/UIManager"):
					UIManager.show_toast("Failed to save character data.", "error")
	else:
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Failed to create character: ProfileManager not found.", "error")
