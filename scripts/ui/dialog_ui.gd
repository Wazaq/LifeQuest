extends Control
## DialogUI: User interface for in-game dialogs

# Reference to the DialogManager singleton
@onready var dialog_manager = get_node("/root/DialogManager")

# Nodes in the UI
@onready var dialog_frame = $DialogFrame
@onready var character_name_label = $DialogFrame/DialogContent/CharacterName
@onready var dialog_text = $DialogFrame/DialogContent/DialogText
@onready var choice_container = $DialogFrame/DialogContent/ChoiceScrollContainer

func _ready():
	print("DialogUI: Ready")
	
	# Hide choice container because it shouldn't be visible at the start
	choice_container.visible = false
	
	
	# Set mouse filter to capture input
	mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect input events
	dialog_frame.gui_input.connect(_on_dialog_frame_gui_input)
	dialog_text.gui_input.connect(_on_dialog_frame_gui_input)

# Handle input on the dialog frame
func _on_dialog_frame_gui_input(event):
	# Only process left mouse button clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("DialogUI: Left click detected")
		
		# If choice container is visible, don't advance (let buttons handle input)
		if choice_container.visible:
			print("DialogUI: Choices visible, not advancing")
			return
			
		print("DialogUI: Advancing dialog")
		dialog_manager.advance_dialog()
