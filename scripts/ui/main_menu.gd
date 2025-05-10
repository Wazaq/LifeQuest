extends Control
## MainMenu: Main navigation hub for the application

@onready var welcome_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderContainer/WelcomeLabel
@onready var quests_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/QuestsButton
@onready var character_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/CharacterButton

func _ready():
	print("MainMenu: Ready")
	
	# Update welcome message with character name
	if get_node_or_null("/root/ProfileManager"):
		var character_name = ProfileManager.current_character.name
		welcome_label.text = "Welcome, %s!" % character_name
	
	# Connect signals
	quests_button.connect("pressed", Callable(self, "_on_quests_button_pressed"))
	character_button.connect("pressed", Callable(self, "_on_character_button_pressed"))

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
