extends Node

## DialogManager: Centralized system for managing in-game dialogs and conversations

signal dialog_started(character_name)
signal dialog_message_shown(message_index, total_messages)
signal dialog_completed
signal dialog_choice_selected(choice_index)

# Current dialog state
var is_dialog_active = false
var current_character = ""
var current_messages = []
var current_message_index = 0
var current_choices = []
var dialog_ui_instance = null
var bottom_nav_bar = null

# Reference to the dialog UI scene
var dialog_ui_scene = preload("res://scenes/ui/dialog_ui.tscn")

func _find_bottom_nav_bar():
	# Look for the bottom nav bar in the navigation container
	var main_node = get_node_or_null("/root/Main")
	if main_node:
		bottom_nav_bar = main_node.get_node_or_null("UIRoot/MainContainer/NavigationContainer/BottomNavBar")
		if bottom_nav_bar:
			return true
	
	# Fallback: search in current scene tree (for backward compatibility)
	var current_scene = get_tree().current_scene
	bottom_nav_bar = current_scene.find_child("BottomNavBar", true, false)
	return bottom_nav_bar != null

# Sets up the dialog UI instance if needed
func _setup_dialog_ui(container: Control = null):
	print("DialogManager: Setting up dialog UI")
	
	# If we already have a dialog UI, just reuse it
	if dialog_ui_instance and is_instance_valid(dialog_ui_instance):
		print("DialogManager: Reusing existing dialog UI")
		return
	
	# Instantiate the dialog UI
	print("DialogManager: Instantiate the dialog UI")	
	dialog_ui_instance = dialog_ui_scene.instantiate()
	
	# If no container specified, try to add to UIManager or current scene
	if container:
		container.add_child(dialog_ui_instance)
		print("DialogManager: Added dialog UI to provided container")
	else:
		# Last resort: add to the root
		get_tree().root.add_child(dialog_ui_instance)
		print("DialogManager: Added dialog UI to root")
	
	# Initialize with fade-in
	dialog_ui_instance.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(dialog_ui_instance, "modulate:a", 1.0, 0.3)
	
	# fade bottom nav bar out if there	
	if _find_bottom_nav_bar():
		# Fade out bottom nav bar
		var nav_tween = create_tween()
		nav_tween.tween_property(bottom_nav_bar, "modulate:a", 0.0, 0.3)
	
	print("DialogManager: Dialog UI setup complete")

# Updates the dialog UI with current content
func _update_dialog_ui():
	if not dialog_ui_instance:
		print("DialogManager: No dialog UI instance found")
		return
	
	print("DialogManager: Updating dialog UI - Message ", current_message_index, " of ", current_messages.size())
	
	# Get references to the UI nodes with correct paths
	var character_name_label = dialog_ui_instance.get_node_or_null("DialogFrame/DialogContent/CharacterName")
	var dialog_text_label = dialog_ui_instance.get_node_or_null("DialogFrame/DialogContent/DialogText")
	
	if not character_name_label:
		print("DialogManager: ERROR - Could not find CharacterName label")
		return
		
	if not dialog_text_label:
		print("DialogManager: ERROR - Could not find DialogText label")
		return
	
	# Update character name
	character_name_label.text = "[b]" + current_character + "[/b]"
	print("DialogManager: Set character name to: ", current_character)
	
	# ADD THIS TEST:
	#await get_tree().process_frame
	#print("DialogManager: After frame delay, character name text is: ", character_name_label.text)

	
	
	# Update dialog text if we have messages - force refresh
	if current_message_index < current_messages.size():
		var message = current_messages[current_message_index]
		var styled_text = apply_fantasy_styling(message)
		dialog_text_label.text = styled_text
		print("DialogManager: Set dialog text to: ", styled_text)
		
		# ADD THIS TEST:
		#await get_tree().process_frame
		#print("DialogManager: After frame delay, dialog text is: ", dialog_text_label.text)
	else:
		print("DialogManager: ERROR - Message index out of range")
	
	# Hide choices container when showing regular dialog
	var choices_container = dialog_ui_instance.get_node_or_null("DialogFrame/DialogContent/ChoiceScrollContainer")
	if choices_container:
		choices_container.visible = false
		print("DialogManager: Hid choices container")

# Format text with fantasy styling
func apply_fantasy_styling(text: String) -> String:
	# Replace common terms with fantasy equivalents
	var styled_text = text
	styled_text = styled_text.replace("days", "sun cycles")
	styled_text = styled_text.replace("hours", "hourglasses")
	
	# Add rich text formatting for emphasis
	styled_text = styled_text.replace("*", "[i]").replace("*", "[/i]")
	
	return styled_text

# Adds choice buttons to the dialog UI
func _add_choices_to_ui(choices: Array):
	if not dialog_ui_instance:
		return
	
	var choice_scroll = dialog_ui_instance.get_node_or_null("DialogFrame/DialogContent/ChoiceScrollContainer")
	var choice_container = dialog_ui_instance.get_node_or_null("DialogFrame/DialogContent/ChoiceScrollContainer/ChoiceContainer")
	
	if not choice_scroll or not choice_container:
		push_error("DialogManager: Choice containers not found in dialog UI")
		return
	
	# Make sure it's visible
	choice_scroll.visible = true
	
	# Clear any existing choices
	for child in choice_container.get_children():
		child.queue_free()
	
	# Add buttons for each choice
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i]
		button.custom_minimum_size = Vector2(0, 50)  # Taller for better touch area
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL  # Ensure it can be focused
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND  # Show hand cursor
		
		# Add some styling
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.6)
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color(0.7, 0.7, 0.7, 0.8)
		normal_style.corner_radius_top_left = 4
		normal_style.corner_radius_top_right = 4
		normal_style.corner_radius_bottom_left = 4
		normal_style.corner_radius_bottom_right = 4
		button.add_theme_stylebox_override("normal", normal_style)
		
		choice_container.add_child(button)
		
		# Connect button signals - use capture for correct index
		button.pressed.connect(func(): _on_choice_selected(i))
	
	# Set the Dialog text mouse filter to pass through so buttons can be pressed
	var dialog_text = dialog_ui_instance.get_node_or_null("DialogFrame/DialogContent/DialogText")
	if dialog_text:
		dialog_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Ensure the container has appropriate size
	choice_container.custom_minimum_size = Vector2(300, choices.size() * 60)
	choice_scroll.custom_minimum_size = Vector2(300, min(choices.size() * 60, 180))

# Handle choice selection
func _on_choice_selected(choice_index: int):
	print("DialogManager: Choice selected: ", choice_index)
	emit_signal("dialog_choice_selected", choice_index)
	
	# By default, complete dialog after choice
	_complete_dialog()

# Show a simple single message dialog
func show_dialog(character_name: String, message: String, container: Control = null):
	print("DialogManager: Showing single dialog - ", character_name, ": ", message)
	_setup_dialog_ui(container)
	is_dialog_active = true
	current_character = character_name
	current_messages = [message]
	current_message_index = 0
	
	_update_dialog_ui()
	
	emit_signal("dialog_started", character_name)
	emit_signal("dialog_message_shown", 0, 1)

# Show a multi-message dialog sequence
func show_dialog_sequence(character_name: String, messages: Array, container: Control = null):
	print("DialogManager: Showing dialog sequence - ", character_name, " with ", messages.size(), " messages")
	_setup_dialog_ui(container)
	is_dialog_active = true
	current_character = character_name
	current_messages = messages
	current_message_index = 0
	
	_update_dialog_ui()
	
	emit_signal("dialog_started", character_name)
	emit_signal("dialog_message_shown", 0, messages.size())

# Show a dialog with choices
func show_dialog_with_choices(character_name: String, message: String, choices: Array, container: Control = null):
	print("DialogManager: Showing dialog with choices - ", character_name)
	print("DialogManager: Choices array: ", choices)
	_setup_dialog_ui(container)
	is_dialog_active = true
	current_character = character_name
	current_messages = [message]
	current_message_index = 0
	current_choices = choices
	
	_update_dialog_ui()
	_add_choices_to_ui(choices)
	print("DialogManager: Finished adding choices to UI")
	
	emit_signal("dialog_started", character_name)

# Advance to the next message in a sequence
func advance_dialog():
	print("DialogManager: Advancing dialog - current index: ", current_message_index, " of ", current_messages.size())
	
	if !is_dialog_active:
		print("DialogManager: No dialog active, cannot advance")
		return
		
	if current_message_index >= current_messages.size() - 1:
		print("DialogManager: Reached end of dialog, completing")
		_complete_dialog()
		return
	
	current_message_index += 1
	print("DialogManager: Advanced to message ", current_message_index)
	_update_dialog_ui()
	print("DialogManager: Update 'done'")
	emit_signal("dialog_message_shown", current_message_index, current_messages.size())

# Hide the dialog (for when transitioning to other UI elements)
func hide_dialog():
	print("DialogManager: Hiding dialog")
	if dialog_ui_instance:
		dialog_ui_instance.visible = false

# Show the dialog again
func show_dialog_ui():
	print("DialogManager: Showing dialog")
	if dialog_ui_instance:
		dialog_ui_instance.visible = true

# Complete and clear the current dialog
func _complete_dialog():
	print("DialogManager: Completing dialog")
	is_dialog_active = false
	
	# fade bottom nav bar in  if there
	if bottom_nav_bar and is_instance_valid(bottom_nav_bar):
   	 # Fade nav bar back in
		var nav_tween = create_tween()
		nav_tween.tween_property(bottom_nav_bar, "modulate:a", 1.0, 0.3)
	
	# Animate dialog closing
	if dialog_ui_instance:
		var tween = create_tween()
		tween.tween_property(dialog_ui_instance, "modulate:a", 0.0, 0.3)
		await tween.finished
		
		dialog_ui_instance.queue_free()
		dialog_ui_instance = null
	
	emit_signal("dialog_completed")
