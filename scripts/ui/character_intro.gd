extends Control
## CharacterIntro: Narrative introduction for character creation

# Narrative states to control flow
enum NarrativeState {
	WORLD_INTRO,
	TAVERN_EXTERIOR,
	TAVERN_INTERIOR,
	CHARACTER_CREATION,
	WELCOME,
	TUTORIAL_OPTION # Player goes to Tutorial
}

# Background images for when they are needed
var tavern_ext = "res://assets/sprites/Tavern_external.png"
var tavern_int = "res://assets/sprites/Tavern_Interior.png"

# Current state in the narrative
var current_state = NarrativeState.WORLD_INTRO

# References to UI elements
@onready var background_image = $BackgroundContainer/BackgroundImage
@onready var dialog_box = $DialogContainer/DialogFrame
@onready var dialog_character_name: RichTextLabel = $DialogContainer/DialogFrame/DialogContent/CharacterName
@onready var dialog_text: RichTextLabel = $DialogContainer/DialogFrame/DialogContent/DialogText
@onready var name_input_container = $NameInputContainer
@onready var name_input = $NameInputContainer/Panel/MarginContainer/VBoxContainer/NameInput
@onready var confirm_name_button = $NameInputContainer/Panel/MarginContainer/VBoxContainer/ConfirmButton
@onready var tavern_keeper = $CharacterContainer/TavernKeeper

# References to the UI elements for the name selection
@onready var reroll_button = $NameInputContainer/Panel/MarginContainer/VBoxContainer/RerollButton 
@onready var male_button = $NameInputContainer/Panel/MarginContainer/VBoxContainer/GenderButtons/MaleButton
@onready var female_button = $NameInputContainer/Panel/MarginContainer/VBoxContainer/GenderButtons/FemaleButton
@onready var neutral_button = $NameInputContainer/Panel/MarginContainer/VBoxContainer/GenderButtons/NeutralButton

# Track the current name category selection
var current_name_category = GameManager.NameCategory.ANY

# Narrative text for each state
var narrative_text = {
	NarrativeState.WORLD_INTRO: "Welcome to the mystical realm of Questeria, a land where heroes forge their destinies through quests and adventures.",
	NarrativeState.TAVERN_EXTERIOR: "You find yourself at the entrance of the legendary 'Seeking Quill' tavern, known throughout the realm as a gathering place for adventurers and quest-seekers.",
	NarrativeState.TAVERN_INTERIOR: "",  # This will have multiple dialog entries with the tavern keeper
	NarrativeState.CHARACTER_CREATION: "",  # This will be handled differently with input field
	NarrativeState.WELCOME: "",  # This will be personalized based on character name
	NarrativeState.TUTORIAL_OPTION: "" # This sends the player to the Tutorial Scene
}

# Tavern keeper dialog for TAVERN_INTERIOR state
var tavern_keeper_dialog = [
	"Ah, a new face! Welcome to the Seeking Quill tavern, traveler.",
	"I'm Dorin, the keeper of this fine establishment and curator of adventures.",
	"This is where heroes like yourself can find quests to embark on and track their grand accomplishments.",
	"But first, I'll need to know what to call you. What name do you go by, adventurer?"
]

# Current dialog index for multi-part dialogs
var dialog_index = 0

func _ready():
	print("CharacterIntro: Ready")
	
	# Pre-load textures
	background_image.texture = load("res://assets/sprites/Tavern_external.png")
	tavern_keeper.texture = load("res://assets/sprites/Bartender_transparent.png")
	
	# Hide the name input initially
	name_input_container.visible = false
	
	# Hide the tavern keeper initially
	tavern_keeper.visible = false
	
	# Connect button signals
	confirm_name_button.pressed.connect(_on_confirm_name_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)
	male_button.pressed.connect(func(): _set_name_category(GameManager.NameCategory.MALE))
	female_button.pressed.connect(func(): _set_name_category(GameManager.NameCategory.FEMALE))
	neutral_button.pressed.connect(func(): _set_name_category(GameManager.NameCategory.NEUTRAL))
	
	# Generate initial random name
	_on_reroll_pressed()
	
	# Set initial background to world intro
	_update_state(NarrativeState.WORLD_INTRO)

func _update_state(new_state):
	#print("CharacterIntro: Updating state to ", new_state)
	current_state = new_state
	
	# Disconnect any existing signal connections to avoid duplicates
	_disconnect_all_dialog_signals()
	
	# Update background image based on state
	match current_state:
		NarrativeState.WORLD_INTRO:
			background_image.texture = load(tavern_ext)
			tavern_keeper.visible = false
			DialogManager.show_dialog("Narrator", narrative_text[current_state])
			# Connect to know when dialog is complete
			DialogManager.dialog_completed.connect(_on_intro_dialog_completed, CONNECT_ONE_SHOT)
			
		NarrativeState.TAVERN_EXTERIOR:
			background_image.texture = load(tavern_ext)
			tavern_keeper.visible = false
			DialogManager.show_dialog("Narrator", narrative_text[current_state])
			DialogManager.dialog_completed.connect(_on_exterior_dialog_completed, CONNECT_ONE_SHOT)
			
		NarrativeState.TAVERN_INTERIOR:
			background_image.texture = load(tavern_int)
			tavern_keeper.visible = true
			DialogManager.show_dialog_sequence("Dorin", tavern_keeper_dialog)
			DialogManager.dialog_completed.connect(_on_interior_dialog_completed, CONNECT_ONE_SHOT)
			
		NarrativeState.CHARACTER_CREATION:
			# Hide dialog and show name input
			_show_name_input()
			
		NarrativeState.WELCOME:
			# Personalized welcome message
			var character_name = ProfileManager.get_character_name()
			var welcome_message = "Well met, " + character_name + "! Welcome to the start of your heroic journey. Let's get you settled in and ready for adventure!"
			DialogManager.show_dialog("Dorin", welcome_message)
			DialogManager.dialog_completed.connect(_on_welcome_completed, CONNECT_ONE_SHOT)
		
		NarrativeState.TUTORIAL_OPTION:
			# Show choice dialog
			DialogManager.show_dialog_with_choices("Dorin",
			"Would you like me to show you around the tavern? I can give you a quick tour of how things work around here.",
			["Yes, that would be helpful", "No thanks, I'll figure it out"])
			DialogManager.dialog_choice_selected.connect(_on_tutorial_choice_selected, CONNECT_ONE_SHOT)

# Disconnect all dialog manager signals to prevent duplicates
func _disconnect_all_dialog_signals():
	if DialogManager.dialog_completed.is_connected(_on_intro_dialog_completed):
		DialogManager.dialog_completed.disconnect(_on_intro_dialog_completed)
	if DialogManager.dialog_completed.is_connected(_on_exterior_dialog_completed):
		DialogManager.dialog_completed.disconnect(_on_exterior_dialog_completed)
	if DialogManager.dialog_completed.is_connected(_on_interior_dialog_completed):
		DialogManager.dialog_completed.disconnect(_on_interior_dialog_completed)
	if DialogManager.dialog_completed.is_connected(_on_welcome_completed):
		DialogManager.dialog_completed.disconnect(_on_welcome_completed)
	if DialogManager.dialog_choice_selected.is_connected(_on_tutorial_choice_selected):
		DialogManager.dialog_choice_selected.disconnect(_on_tutorial_choice_selected)

func _on_intro_dialog_completed():
	#print("CharacterIntro: Intro dialog completed")
	_update_state(NarrativeState.TAVERN_EXTERIOR)

func _on_exterior_dialog_completed():
	#print("CharacterIntro: Exterior dialog completed")
	_update_state(NarrativeState.TAVERN_INTERIOR)

func _on_interior_dialog_completed():
	#print("CharacterIntro: Interior dialog completed")
	_update_state(NarrativeState.CHARACTER_CREATION)
	
func _on_welcome_completed():
	#print("CharacterIntro: Welcome dialog completed")
	_update_state(NarrativeState.TUTORIAL_OPTION)
	
func _on_tutorial_choice_selected(choice_index: int):
	#print("CharacterIntro: Tutorial choice selected: ", choice_index)
	
	if choice_index == 0:
		# Yes - Start tutorial and go to tavern hub in tutorial mode
		DialogManager.show_dialog("Dorin", "Excellent! Let me show you around. Follow my guidance and you'll be questing like a seasoned adventurer in no time!")
		DialogManager.dialog_completed.connect(func():
			# Start tutorial system
			TutorialManager.start_tutorial()
			# Navigate directly to tavern hub (now in tutorial mode)
			_complete_character_creation()
		, CONNECT_ONE_SHOT)
	else:
		# No - Go to tavern hub in normal mode
		DialogManager.show_dialog("Dorin", "As you wish! Feel free to explore. See you around.")
		DialogManager.dialog_completed.connect(func():
			# Skip tutorial and go to normal tavern hub
			TutorialManager.skip_tutorial()
			_complete_character_creation()
		, CONNECT_ONE_SHOT)

func _show_name_input():
	print("CharacterIntro: Showing name input")
	
	# Hide the dialog UI completely
	DialogManager.hide_dialog()
	
	# Show the name input container
	name_input_container.visible = true
	
	# Generate an initial random name
	_on_reroll_pressed()

func _on_confirm_name_pressed():
	var character_name = name_input.text.strip_edges()
	
	# Validate name
	if character_name.is_empty():
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Please enter a name for your character", "warning")
		return
	
	print("CharacterIntro: Creating character with name: %s" % character_name)
	
	# Hide name input
	name_input_container.visible = false
	
	# Create the character
	if get_node_or_null("/root/ProfileManager"):
		var character = ProfileManager.create_character(character_name)
		
		# Save the character data
		if get_node_or_null("/root/DataManager"):
			var success = DataManager.save_character(character)
			if success:
				# Move to the welcome state
				_update_state(NarrativeState.WELCOME)
			else:
				if get_node_or_null("/root/UIManager"):
					UIManager.show_toast("Failed to save character data.", "error")
	else:
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Failed to create character: ProfileManager not found.", "error")

func _set_name_category(category):
	current_name_category = category
	_on_reroll_pressed()
	
	# Visual feedback for selected category
	male_button.disabled = (category == GameManager.NameCategory.MALE)
	female_button.disabled = (category == GameManager.NameCategory.FEMALE)
	neutral_button.disabled = (category == GameManager.NameCategory.NEUTRAL)

func _on_reroll_pressed():
	# Get a random name based on the selected category
	name_input.text = GameManager.get_random_name(current_name_category)

func _complete_character_creation():
	print("CharacterIntro: Completing character creation")
	# Navigate to the tavern hub using the navigation system
	var main_node = get_node_or_null("/root/Main")
	if main_node and main_node.has_method("_navigate_to"):
		# Use the "_on_character_created" callback to handle navigation
		if main_node.has_method("_on_character_created"):
			main_node._on_character_created()
		else:
			main_node._navigate_to(main_node.ScreenState.TAVERN_HUB)
	else:
		print("CharacterIntro: Could not find Main node or navigate method")
