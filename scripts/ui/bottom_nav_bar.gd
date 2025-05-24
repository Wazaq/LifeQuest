extends Control
## BottomNavBar: Mobile-style navigation bar for the app

# Button references
@onready var tavern_button: Button = $PanelContainer/HBoxContainer/TavernButton
@onready var quests_button: Button = $PanelContainer/HBoxContainer/QuestsButton
@onready var character_button: Button = $PanelContainer/HBoxContainer/CharacterButton
@onready var adventures_button: Button = $PanelContainer/HBoxContainer/AdventuresButton
@onready var more_button: Button = $PanelContainer/HBoxContainer/MoreButton

# The currently active button
var active_button: Button = null

# Signals
signal nav_button_pressed(screen_name)

func _ready():
	print("BottomNavBar: Initializing")
	
	# Connect button signals
	tavern_button.pressed.connect(func(): _on_nav_button_pressed("tavern", tavern_button))
	quests_button.pressed.connect(func(): _on_nav_button_pressed("quest_board", quests_button))
	character_button.pressed.connect(func(): _on_nav_button_pressed("character_profile", character_button))
	adventures_button.pressed.connect(func(): _on_nav_button_pressed("adventures", adventures_button))
	more_button.pressed.connect(func(): _on_nav_button_pressed("more", more_button))
	
	# Set initial active button
	set_active_button("tavern")
	
	# Update available buttons based on feature flags (if GameManager exists)
	if get_node_or_null("/root/GameManager"):
		_update_feature_visibility()
		GameManager.feature_enabled.connect(_on_feature_flag_changed)
		GameManager.feature_disabled.connect(_on_feature_flag_changed)

# Set the active button by screen name
func set_active_button(screen_name: String):
	var button_to_activate = null
	
	match screen_name:
		"tavern", "main_menu":
			button_to_activate = tavern_button
		"quest_board":
			button_to_activate = quests_button
		"character_profile":
			button_to_activate = character_button
		"adventures":
			button_to_activate = adventures_button
		"more":
			button_to_activate = more_button
	
	if button_to_activate:
		_highlight_button(button_to_activate)

# Handle navigation button press
func _on_nav_button_pressed(screen_name: String, button: Button):
	print("BottomNavBar: Button pressed - " + screen_name)
	
	# Highlight the pressed button
	_highlight_button(button)
	
	# Emit signal for parent to handle navigation
	emit_signal("nav_button_pressed", screen_name)

# Highlight the active button and reset others
func _highlight_button(button: Button):
	# Return if this button is already active
	if active_button == button:
		return
		
	# Reset all buttons to default state
	for child in $PanelContainer/HBoxContainer.get_children():
		if child is Button:
			child.modulate = Color(0.6, 0.6, 0.65, 1.0)  # Dimmer for inactive
			child.scale = Vector2(1.0, 1.0)
	
	# Highlight the active button with animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animate to slightly larger scale and full brightness
	tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	
	# Store the current active button
	active_button = button

# Update button visibility based on feature flags
func _update_feature_visibility():
	if !get_node_or_null("/root/GameManager"):
		return
	
	# Show/hide Adventures button based on the feature flag
	if GameManager.is_feature_enabled("adventures"):
		adventures_button.visible = true
	else:
		adventures_button.visible = false

# Handle feature flag changes
func _on_feature_flag_changed(_feature_name: String):
	_update_feature_visibility()
