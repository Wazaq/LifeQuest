extends Control

# Node References
@onready var tavern_keeper: TextureRect = $TavernKeeperContainer/TavernKeeper

# Tutorial overlay references
@onready var tutorial_overlay: Control = $TutorialOverlay
@onready var tutorial_text: Label = $TutorialOverlay/TutorialText
@onready var continue_button: Button = $TutorialOverlay/ContinueButton
@onready var highlight_container: Control = $TutorialOverlay/HighlightContainer

# Tutorial state
var current_tutorial_step: int = 0
var tutorial_steps = [
	{
		"text": "Welcome to your tavern hub! This is your home base where your adventure begins and ends each day.",
		"highlight_target": ""
	},
	{
		"text": "This is the Tavern button - it brings you back to this cozy home base whenever you need it.",
		"highlight_target": "tavern_button"
	},
	{
		"text": "The Quests button is where you'll manage all your adventures and track your progress on epic tasks.",
		"highlight_target": "quests_button"
	},
	{
		"text": "Your Character button shows your stats, progression, and all the amazing growth you've achieved.",
		"highlight_target": "character_button"
	},
	{
		"text": "Finally, the Settings button gives you access to additional options and game preferences.",
		"highlight_target": "settings_button"
	}
]

func _ready() -> void:
	print("TavernHub: Ready")
	_setup_ui()
	_setup_tavern_keeper()
	_update_welcome_message()
	_check_tutorial_mode()
	pass

func _setup_ui():
	# Since we removed the welcome panel, we mainly need to ensure
	# the scene layout works well on mobile
	# Any additional UI setup can go here in the future
	pass

func _setup_tavern_keeper():
	# Connect tavern keeper interaction
	print("TavernHub: Setting up tavern keeper interaction")
	
	#Connect the Tavern Keeper signal for the Keeper clicks
	if tavern_keeper:
		tavern_keeper.gui_input.connect(_on_tavern_keeper_clicked)
		print("TavernHub: Connected to tavern keeper TextureRect")
		
		# Make sure the TextureRect can receive input
		#tavern_keeper.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		print("TavernHub: ERROR - Tavern keeper not found")

# Array of generic friendly responses from Dorin
var keeper_responses = [
	"Ah, %s! How goes your adventures today?",
	"Hello there, %s! Have you checked on your quests lately?",
	"%s, my friend! The tavern feels livelier with you here.",
	"Good to see you, %s! Any exciting tales from your recent quests?",
	"Welcome back, %s! The fire's warm and the quests are plenty.",
	"Hail and well met, %s! Ready for another day of adventure?",
	"%s! You're becoming quite the regular. I like that!",
	"Ah, the legendary %s returns! How may I assist you today?",
	"Greetings, brave %s! The quest board has been busy today."
]

func _on_tavern_keeper_clicked(event):
	# Only respond to left mouse button press
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("TavernHub: Tavern keeper clicked")
		_show_keeper_response()

func _show_keeper_response():
	# Get players name
	var player_name = ProfileManager.get_character_name()
	if player_name.is_empty():
		player_name = "adventurer"
	
	# Pick a random response and insert the players name
	var response = keeper_responses[randi() % keeper_responses.size()]
	var formatted_response = response % player_name
	
	# Show using Dialog manager
	DialogManager.show_dialog("Dorin", formatted_response)

func _update_welcome_message():
	# setting up time-based greetings for the tavern keeper
	print("TavernHub: Preparing time-based greetings")
	
	# We'll integrate this into the keeper responses
	_setup_time_based_keeper_greetings()

func _setup_time_based_keeper_greetings():
	# Get current time for time-based greeting
	var current_time = Time.get_datetime_dict_from_system()
	var hour = current_time.hour
	
	var time_greeting = ""
	if hour >= 5 and hour < 12:
		time_greeting = "Good morning"
	elif hour >= 12 and hour < 17:
		time_greeting = "Good afternoon"
	elif hour >= 17 and hour < 22:
		time_greeting = "Good evening"
	else:
		time_greeting = "Greetings, night owl"
	
	# Add time-based responses to the beginning of our keeper_responses array
	keeper_responses.insert(0, time_greeting + ", %s! Welcome back to the Seeking Quill.")
	keeper_responses.insert(1, time_greeting + ", brave %s! Ready for another day of adventure?")

# Tutorial system integration
func _check_tutorial_mode():
	# Check if we're in tutorial mode
	if TutorialManager and TutorialManager.is_tutorial_active():
		_start_tutorial_overlay()

func _start_tutorial_overlay():
	print("TavernHub: Starting tutorial overlay")
	current_tutorial_step = 0
	tutorial_overlay.visible = true
	_show_tutorial_step(current_tutorial_step)
	
	# Connect continue button
	if not continue_button.pressed.is_connected(_on_tutorial_continue):
		continue_button.pressed.connect(_on_tutorial_continue)

func _show_tutorial_step(step_index: int):
	print("TavernHub: Showing tutorial step ", step_index, " of ", tutorial_steps.size())
	
	if step_index >= tutorial_steps.size():
		print("TavernHub: Reached end of tutorial steps, completing")
		_complete_tutorial()
		return
	
	var step_data = tutorial_steps[step_index]
	tutorial_text.text = step_data["text"]
	print("TavernHub: Tutorial text set to: ", step_data["text"])
	
	# Clear existing highlights
	_clear_highlights()
	
	# Add highlight for target element
	if step_data["highlight_target"] != "":
		print("TavernHub: Creating highlight for: ", step_data["highlight_target"])
		_highlight_element(step_data["highlight_target"])
	
	# Update button text
	if step_index == tutorial_steps.size() - 1:
		continue_button.text = "Got it!"
	else:
		continue_button.text = "Continue"

func _highlight_element(target: String):
	# Find the target element and create a highlight around it
	var target_node = _find_nav_button(target)
	if target_node:
		_create_highlight_border(target_node)

func _find_nav_button(button_name: String) -> Node:
	# Find the nav button in the bottom navigation
	var main_node = get_node_or_null("/root/Main")
	if main_node:
		var nav_bar = main_node.get_node_or_null("UIRoot/MainContainer/NavigationContainer/BottomNavBar")
		if nav_bar:
			match button_name:
				"tavern_button":
					return nav_bar.get_node_or_null("PanelContainer/HBoxContainer/TavernButton")
				"quests_button":
					return nav_bar.get_node_or_null("PanelContainer/HBoxContainer/QuestsButton")
				"character_button":
					return nav_bar.get_node_or_null("PanelContainer/HBoxContainer/CharacterButton")
				"settings_button":
					return nav_bar.get_node_or_null("PanelContainer/HBoxContainer/MoreButton")
	return null

func _create_highlight_border(target_node: Node):
	if not target_node:
		return
	
	# Create a glowing border around the target
	var highlight_border = ColorRect.new()
	highlight_border.color = Color(1.0, 0.8, 0.0, 0.8)  # Golden glow
	highlight_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Position and size the highlight
	var global_rect = target_node.get_global_rect()
	var local_rect = get_global_rect()
	
	# Convert global position to local
	highlight_border.position = global_rect.position - local_rect.position - Vector2(5, 5)
	highlight_border.size = global_rect.size + Vector2(10, 10)
	
	# Add some visual flair with a border
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1.0, 0.8, 0.0, 0.0)  # Transparent center
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(1.0, 0.8, 0.0, 0.9)  # Golden border
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	# Create a panel for the styled border
	var highlight_panel = Panel.new()
	highlight_panel.add_theme_stylebox_override("panel", style_box)
	highlight_panel.position = highlight_border.position
	highlight_panel.size = highlight_border.size
	highlight_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	highlight_container.add_child(highlight_panel)
	
	# Add a pulsing animation (but store the tween to avoid cleanup issues)
	var tween = create_tween()
	tween.set_loops(-1)  # -1 for infinite loops
	tween.tween_property(highlight_panel, "modulate:a", 0.5, 1.0)
	tween.tween_property(highlight_panel, "modulate:a", 1.0, 1.0)
	
	# Store the tween reference so we can kill it when cleaning up
	highlight_panel.set_meta("highlight_tween", tween)

func _clear_highlights():
	# Remove all existing highlights and kill their tweens
	for child in highlight_container.get_children():
		# Kill the tween first to prevent errors
		if child.has_meta("highlight_tween"):
			var tween = child.get_meta("highlight_tween")
			if tween:
				tween.kill()
		child.queue_free()

func _on_tutorial_continue():
	current_tutorial_step += 1
	_show_tutorial_step(current_tutorial_step)

func _complete_tutorial():
	print("TavernHub: Tutorial completed")
	tutorial_overlay.visible = false
	TutorialManager.complete_tutorial()
	
	# Show completion message
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Tutorial completed! Ready for adventure!", "success")
