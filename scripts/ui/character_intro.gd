extends Control
## CharacterIntro: Narrative introduction for character creation

# Narrative states to control flow
enum NarrativeState {
	WORLD_INTRO,
	TAVERN_EXTERIOR,
	TAVERN_INTERIOR,
	CHARACTER_CREATION,
	WELCOME
}

# Current state in the narrative
var current_state = NarrativeState.WORLD_INTRO

# References to UI elements
@onready var background_image = $BackgroundContainer/BackgroundImage
@onready var dialog_box = $DialogContainer/DialogFrame
@onready var dialog_character_name: RichTextLabel = $DialogContainer/DialogFrame/DialogContent/CharacterName
@onready var dialog_text: RichTextLabel = $DialogContainer/DialogFrame/DialogContent/DialogText
#@onready var next_button: Button = $DialogContainer/NextButton
@onready var name_input_container = $NameInputContainer
@onready var name_input = $NameInputContainer/Panel/MarginContainer/VBoxContainer/NameInput
@onready var confirm_name_button = $NameInputContainer/Panel/MarginContainer/VBoxContainer/ConfirmButton
@onready var tavern_keeper = $CharacterContainer/TavernKeeper

# Narrative text for each state
var narrative_text = {
	NarrativeState.WORLD_INTRO: "Welcome to the mystical realm of Questeria, a land where heroes forge their destinies through quests and adventures.",
	NarrativeState.TAVERN_EXTERIOR: "You find yourself at the entrance of the legendary 'Seeking Quill' tavern, known throughout the realm as a gathering place for adventurers and quest-seekers.",
	NarrativeState.TAVERN_INTERIOR: "",  # This will have multiple dialog entries with the tavern keeper
	NarrativeState.CHARACTER_CREATION: "",  # This will be handled differently with input field
	NarrativeState.WELCOME: ""  # This will be personalized based on character name
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
	dialog_box.texture = load("res://assets/ui/frames/dialog_frame_transparent.png")
	
	# Set dialog box visible
	dialog_box.visible = true
	
	# Hide the name input initially
	name_input_container.visible = false
	
	# Hide the tavern keeper initially
	tavern_keeper.visible = false
	
	# Connect button signals
	dialog_box.gui_input.connect(_on_dialog_box_gui_input)
	#next_button.pressed.connect(_on_next_button_pressed) #TODO: Possible removal
	confirm_name_button.pressed.connect(_on_confirm_name_pressed)
	dialog_text.gui_input.connect(_on_dialog_box_gui_input)
	
	# Set initial background to world intro
	_update_state(NarrativeState.WORLD_INTRO)

func _update_state(new_state):
	current_state = new_state
	
	# Update background image based on state
	match current_state:
		NarrativeState.WORLD_INTRO:
			# We'll use the tavern exterior as a placeholder for world intro for now
			background_image.texture = load("res://assets/sprites/Tavern_external.png")
			tavern_keeper.visible = false
			_show_simple_dialog("Narrator", narrative_text[current_state])
			
		NarrativeState.TAVERN_EXTERIOR:
			background_image.texture = load("res://assets/sprites/Tavern_external.png")
			tavern_keeper.visible = false
			_show_simple_dialog("Narrator", narrative_text[current_state])
			
		NarrativeState.TAVERN_INTERIOR:
			background_image.texture = load("res://assets/sprites/Tavern_Interior.png")
			tavern_keeper.visible = true
			tavern_keeper.position = Vector2(200, 400)  # Center of the room in front of bar
			dialog_index = 0
			_show_tavern_keeper_dialog()
			
		NarrativeState.CHARACTER_CREATION:
			# Show name input when we reach this state
			_show_name_input()
			
		NarrativeState.WELCOME:
			# Personalized welcome message
			var character_name = ProfileManager.get_character_name()
			_show_simple_dialog("Dorin", "Well met, " + character_name + "! Welcome to the start of your heroic journey. Let's get you settled in and ready for adventure!")

func _show_simple_dialog(character_name: String, text: String):
	# Hide the name input container
	name_input_container.visible = false
	
	# Show the dialog box
	dialog_box.visible = true
	
	# Set the text
	dialog_character_name.text = character_name
	dialog_text.text = text
	
	# Show the next button
	#next_button.visible = true #TODO: Possible removal

func _show_tavern_keeper_dialog():
	# Show the current part of the tavern keeper's dialog
	if dialog_index < tavern_keeper_dialog.size():
		_show_simple_dialog("Dorin", tavern_keeper_dialog[dialog_index])
	else:
		# Move to the next state when we've shown all dialog parts
		_update_state(NarrativeState.CHARACTER_CREATION)

func _show_name_input():
	# Hide the dialog box
	dialog_box.visible = false
	
	# Show the name input container
	name_input_container.visible = true
	
	# Focus the name input
	name_input.grab_focus()
	
func _on_dialog_box_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#_create_tap_feedback(event.position) #TODO: Possibly remove, including func
		_on_next_button_pressed() # Move the dialog forward
		
	#var tween = create_tween()
	#tween.tween_property(dialog_box, "modulate", Color(0.9, 0.9, 0.9), 0.1)
	#tween.tween_property(dialog_box, "modulate", Color(1, 1, 1), 0.1)
	pass
	
func _create_tap_feedback(pos: Vector2):
	# Create a simple circular feedback at tap position
	var feedback = ColorRect.new()
	feedback.color = Color(1, 1, 1, 0.3)
	feedback.size = Vector2(20, 20)
	feedback.position = pos - Vector2(10, 10)  # Center at tap position
	feedback.pivot_offset = Vector2(10, 10)
	dialog_box.add_child(feedback)
	
	# Animate and remove
	var tween = create_tween()
	tween.tween_property(feedback, "scale", Vector2(3, 3), 0.3)
	tween.parallel().tween_property(feedback, "modulate:a", 0.0, 0.3)
	await tween.finished
	feedback.queue_free()

func _on_next_button_pressed():
	match current_state:
		NarrativeState.WORLD_INTRO:
			_update_state(NarrativeState.TAVERN_EXTERIOR)
			
		NarrativeState.TAVERN_EXTERIOR:
			_update_state(NarrativeState.TAVERN_INTERIOR)
			
		NarrativeState.TAVERN_INTERIOR:
			# Increment dialog index for multi-part dialogs
			dialog_index += 1
			_show_tavern_keeper_dialog()
			
		NarrativeState.WELCOME:
			# Complete the introduction and navigate to the tavern hub
			_complete_character_creation()

func _on_confirm_name_pressed():
	var character_name = name_input.text.strip_edges()
	
	# Validate name
	if character_name.is_empty():
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Please enter a name for your character", "warning")
		return
	
	print("CharacterIntro: Creating character with name: %s" % character_name)
	
	# Create the character
	if get_node_or_null("/root/ProfileManager"):
		var character = ProfileManager.create_character(character_name)
		
		# Save the character data
		if get_node_or_null("/root/DataManager"):
			var success = DataManager.save_character(character)
			if success:
				if get_node_or_null("/root/UIManager"):
					UIManager.show_toast("Character created successfully!", "success")
				
				# Move to the welcome state
				_update_state(NarrativeState.WELCOME)
			else:
				if get_node_or_null("/root/UIManager"):
					UIManager.show_toast("Failed to save character data.", "error")
	else:
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Failed to create character: ProfileManager not found.", "error")

func _complete_character_creation():
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
