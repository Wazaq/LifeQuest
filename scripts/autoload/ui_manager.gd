extends Node
## UIManager: Handles UI transitions and common interface elements

# Reference to main UI container
var main_container: Control = null

# Current active UI panel/screen
var current_screen: Control = null

# UI transition animations
var transition_in_time: float = 0.3
var transition_out_time: float = 0.2
var default_transition_type: int = Tween.TRANS_SINE

# Toast notification settings
var toast_duration: float = 3.0
var toast_container: Control = null
var active_toasts: Array[Control] = []

# UI sounds
var sound_button_click: AudioStream = null
var sound_popup_show: AudioStream = null
var sound_notification: AudioStream = null
var sound_success: AudioStream = null
var sound_failure: AudioStream = null

# Signals
signal screen_changed(old_screen, new_screen)
signal toast_displayed(message)
signal ui_initialized

func _ready():
	print("UIManager: Initializing UI system...")
	# Wait for the tree to be ready before attempting to find UI elements
	call_deferred("initialize_ui")

# Initialize UI elements and references
func initialize_ui():
	# Find main UI container (will be implemented when we have the actual UI scenes)
	# main_container = get_node("/root/Main/UIContainer")
	
	# Load UI sounds (commented out until we have actual sounds)
	# sound_button_click = load("res://assets/sounds/button_click.wav")
	# sound_popup_show = load("res://assets/sounds/popup_show.wav")
	# sound_notification = load("res://assets/sounds/notification.wav")
	# sound_success = load("res://assets/sounds/success.wav")
	# sound_failure = load("res://assets/sounds/failure.wav")
	
	print("UIManager: UI system initialized")
	emit_signal("ui_initialized")

# Change to a different UI screen with animation
func change_screen(new_screen_node: Control):
	if not is_instance_valid(new_screen_node):
		push_error("UIManager: Invalid screen node provided")
		return
	
	var old_screen = current_screen
	
	# Animate out the current screen if it exists
	if is_instance_valid(current_screen):
		animate_screen_out(current_screen)
		await get_tree().create_timer(transition_out_time).timeout
	
	# Hide all screens
	if main_container:
		for child in main_container.get_children():
			if child is Control:
				child.visible = false
	
	# Show and animate in the new screen
	current_screen = new_screen_node
	current_screen.visible = true
	animate_screen_in(current_screen)
	
	emit_signal("screen_changed", old_screen, current_screen)
	print("UIManager: Changed screen to %s" % current_screen.name)

# Open a screen by name with optional data
func open_screen(screen_name: String, data = null):
	print("UIManager: Attempting to open screen: %s" % screen_name)
	
	if not main_container:
		push_error("UIManager: Cannot open screen - main_container not set")
		return
	
	# Check if we're using the new navigation system
	var main_node = get_node_or_null("/root/Main")
	if main_node and main_node.has_method("_navigate_to"):
		# Use the navigation container's method
		match screen_name:
			"quest_board":
				main_node._navigate_to(main_node.ScreenState.QUEST_BOARD, data)
			"quest_details":
				main_node._navigate_to(main_node.ScreenState.QUEST_DETAILS, data)
			"quest_creation":
				main_node._navigate_to(main_node.ScreenState.QUEST_CREATION, data)
			"main_menu":
				main_node._navigate_to(main_node.ScreenState.MAIN_MENU, data)
			"character_creation":
				main_node._navigate_to(main_node.ScreenState.CHARACTER_CREATION, data)
			"character_profile":
				main_node._navigate_to(main_node.ScreenState.CHARACTER_PROFILE, data)
			"adventures":
				main_node._navigate_to(main_node.ScreenState.ADVENTURES, data)
			"more":
				main_node._navigate_to(main_node.ScreenState.MORE, data)
			_:
				push_error("UIManager: Unknown screen name: %s" % screen_name)
		return
		
	# Legacy method for backward compatibility
	var screen_path = ""
	
	# Map screen name to scene path
	match screen_name:
		"quest_board":
			screen_path = "res://scenes/quests/quest_board_new.tscn"
		"quest_details":
			screen_path = "res://scenes/quests/quest_details.tscn"
		"quest_creation":
			screen_path = "res://scenes/quests/quest_creation.tscn"
		"main_menu":
			screen_path = "res://scenes/main_menu/main_menu.tscn"
		"character_creation":
			screen_path = "res://scenes/character/character_creation.tscn"
		"character_profile":
			screen_path = "res://scenes/character/character_profile.tscn"
		_:
			push_error("UIManager: Unknown screen name: %s" % screen_name)
			return
	
	# Load and instantiate the screen
	var screen_scene = load(screen_path)
	if not screen_scene:
		push_error("UIManager: Failed to load screen scene: %s" % screen_path)
		return
		
	var screen_instance = screen_scene.instantiate()
	if not screen_instance:
		push_error("UIManager: Failed to instantiate screen: %s" % screen_path)
		return
	
	# Add to container
	main_container.add_child(screen_instance)
	
	# Initialize with data if needed
	if data != null and screen_instance.has_method("initialize"):
		screen_instance.initialize(data)
	
	# Change to the new screen
	change_screen(screen_instance)

# Go back to previous screen
func go_back():
	# Check if we're using the new navigation system
	var main_node = get_node_or_null("/root/Main")
	if main_node and main_node.has_method("_navigate_to") and main_node.previous_screen_states.size() > 0:
		# Navigate to the previous screen
		var previous_state = main_node.previous_screen_states.pop_back()
		main_node._navigate_to(previous_state)
		return
	
	# Legacy method for backward compatibility
	# Find the previous screen in the container
	if not main_container or not current_screen:
		return
		
	# Get children and find current screen index
	var children = main_container.get_children()
	var current_index = children.find(current_screen)
	
	if current_index <= 0 or current_index >= children.size():
		# No previous screen, try to go to main menu
		open_screen("main_menu")
		return
		
	# Get previous screen
	var previous_screen = children[current_index - 1]
	
	# Change to previous screen
	change_screen(previous_screen)
	
	# Queue free the current screen
	current_screen.queue_free()

# Animate a screen coming into view
func animate_screen_in(screen: Control):
	if not is_instance_valid(screen):
		return
	
	# Reset properties
	screen.modulate.a = 0
	screen.scale = Vector2(0.95, 0.95)
	
	# Create tween for animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(default_transition_type)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animate properties
	tween.tween_property(screen, "modulate:a", 1.0, transition_in_time)
	tween.tween_property(screen, "scale", Vector2(1, 1), transition_in_time)
	
	# Play sound if available
	# if sound_popup_show:
	#     AudioManager.play_sfx(sound_popup_show)

# Animate a screen going out of view
func animate_screen_out(screen: Control):
	if not is_instance_valid(screen):
		return
	
	# Create tween for animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(default_transition_type)
	tween.set_ease(Tween.EASE_IN)
	
	# Animate properties
	tween.tween_property(screen, "modulate:a", 0.0, transition_out_time)
	tween.tween_property(screen, "scale", Vector2(1.05, 1.05), transition_out_time)
	
	# Queue hiding the screen when animation is complete
	await tween.finished
	
	# Check if the screen is still valid before trying to hide it
	if is_instance_valid(screen):
		screen.visible = false

# Show a popup window
func show_popup(popup: Control):
	if not is_instance_valid(popup):
		return
	
	# Reset properties
	popup.modulate.a = 0
	popup.scale = Vector2(0.9, 0.9)
	popup.visible = true
	
	# Create tween for animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(default_transition_type)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animate properties
	tween.tween_property(popup, "modulate:a", 1.0, transition_in_time)
	tween.tween_property(popup, "scale", Vector2(1, 1), transition_in_time)
	
	# Play sound if available
	# if sound_popup_show:
	#     AudioManager.play_sfx(sound_popup_show)

# Hide a popup window
func hide_popup(popup: Control):
	if not is_instance_valid(popup):
		return
	
	# Create tween for animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(default_transition_type)
	tween.set_ease(Tween.EASE_IN)
	
	# Animate properties
	tween.tween_property(popup, "modulate:a", 0.0, transition_out_time)
	tween.tween_property(popup, "scale", Vector2(0.9, 0.9), transition_out_time)
	
	# Queue hiding the popup when animation is complete
	await tween.finished
	
	# Check if the popup is still valid before trying to hide it
	if is_instance_valid(popup):
		popup.visible = false

# Show a toast notification
func show_toast(message: String, type: String = "info", duration: float = -1):
	print("UIManager: Attempting to show toast with message: " + message)
	
	if toast_container == null:
		push_error("UIManager: Cannot show toast - toast_container not set")
		return
	
	print("UIManager: Toast container exists, loading scene...")
	var toast_scene = load("res://scenes/ui/toast_notification.tscn")
	if toast_scene == null:
		push_error("UIManager: Failed to load toast notification scene")
		return
		
	print("UIManager: Scene loaded, instantiating...")
	var toast = toast_scene.instantiate()
	if toast == null:
		push_error("UIManager: Failed to instantiate toast")
		return
	
	print("UIManager: Toast instantiated, setting up...")
	
	# Set toast duration
	var toast_time = duration if duration > 0 else toast_duration
	
	# Configure and add the toast
	toast.setup(message, type, toast_time)
	
	# Make sure the toast is added with the correct anchors
	toast_container.add_child(toast)
	
	# Ensure the toast is positioned correctly at the top center
	toast.anchor_left = 0.5
	toast.anchor_top = 0.0 
	toast.anchor_right = 0.5
	toast.anchor_bottom = 0.0
	toast.offset_left = -200
	toast.offset_top = 20
	toast.offset_right = 200
	toast.offset_bottom = 80
	
	active_toasts.append(toast)
	
	# Play sound based on type (to be implemented when we have sounds)
	# if type == "success" and sound_success:
	#     AudioManager.play_sfx(sound_success)
	# elif type == "error" and sound_failure:
	#     AudioManager.play_sfx(sound_failure)
	# elif sound_notification:
	#     AudioManager.play_sfx(sound_notification)
	
	emit_signal("toast_displayed", message)
	print("UIManager: Toast notification displayed - %s" % message)

# Remove a specific toast notification
func remove_toast(toast: Control):
	if not is_instance_valid(toast):
		return
	
	if toast in active_toasts:
		active_toasts.erase(toast)
	
	# Animate out the toast
	var tween = create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	
	# Remove the toast from the scene if it's still valid
	if is_instance_valid(toast):
		if toast.is_inside_tree():
			toast.queue_free()

# Clear all active toast notifications
func clear_all_toasts():
	for toast in active_toasts:
		if is_instance_valid(toast):
			remove_toast(toast)
	
	active_toasts.clear()

# Play a button click sound
func play_button_sound():
	# Will be implemented when we have sounds
	# if sound_button_click:
	#     AudioManager.play_sfx(sound_button_click)
	pass

# Set the main UI container
func set_main_container(container: Control):
	main_container = container
	print("UIManager: Set main container to %s" % container.name)

# Set the toast container
func set_toast_container(container: Control):
	toast_container = container
	print("UIManager: Set toast container to %s" % container.name)
