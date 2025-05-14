extends Control

func _ready():
	# Connect back button
	$ProfilePanel/BackButton.connect("pressed", Callable(self, "_on_back_button_pressed"))
	
	print("CharacterProfile V2: Ready")

func _on_back_button_pressed():
	# Go back to main menu
	if get_node_or_null("/root/UIManager"):
		UIManager.go_back()
		print("CharacterProfile V2: Going back")
	else:
		print("CharacterProfile V2: UIManager not found!")
		
		# Try direct approach
		var main_menu = load("res://scenes/main_menu/main_menu.tscn").instantiate()
		var parent = get_parent()
		if parent:
			parent.add_child(main_menu)
			queue_free()
