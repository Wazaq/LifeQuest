extends Control
## SplashScreen: Initial screen shown when the app launches

@onready var start_button = $VBoxContainer/StartButton

func _ready():
	print("SplashScreen: Ready")
	
	# Connect signals
	start_button.connect("pressed", Callable(self, "_on_start_button_pressed"))

func _on_start_button_pressed():
	print("SplashScreen: Start button pressed")
	
	# Check if user has existing character
	var has_character = false
	if get_node_or_null("/root/DataManager"):
		has_character = DataManager.has_character_save()
	
	if has_character:
		# Eventually navigate to the main menu scene
		print("SplashScreen: Would navigate to main_menu.tscn")
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Character found! Would navigate to Main Menu.", "info")
	else:
		# Navigate to character creation scene
		print("SplashScreen: Navigating to character_creation.tscn")
		
		# Load the character creation scene
		var character_creation = load("res://scenes/character/character_creation.tscn").instantiate()
		
		# Add it to the screens container
		var main = get_tree().get_root().get_node("Main")
		var screens_container = main.get_node("UIRoot/MainContainer/ScreensContainer")
		
		# Change to the character creation screen
		screens_container.add_child(character_creation)
		
		if get_node_or_null("/root/UIManager"):
			UIManager.change_screen(character_creation)
			
		# Queue self for removal
		queue_free()
