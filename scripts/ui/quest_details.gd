extends Control
## QuestDetails: Screen showing detailed information about a quest

# UI References
@onready var quest_name_label = $VBoxContainer/HeaderSection/QuestNameLabel
@onready var quest_icon = $VBoxContainer/HeaderSection/QuestIcon
@onready var time_label = $VBoxContainer/HeaderSection/TimeLabel
@onready var description_label = $VBoxContainer/DescriptionSection/DescriptionLabel
@onready var difficulty_label = $VBoxContainer/InfoSection/DifficultyRow/ValueLabel
@onready var xp_reward_label = $VBoxContainer/InfoSection/XPRow/ValueLabel
@onready var categories_label = $VBoxContainer/InfoSection/CategoriesRow/ValueLabel
@onready var action_button = $VBoxContainer/ActionButton
@onready var back_button = $VBoxContainer/BackButton

var current_quest_id = ""
var is_active = false
var current_quest = null
var abandon_confirmation_dialog = null

func _ready():
	# Connect signals
	action_button.connect("pressed", Callable(self, "_on_action_button_pressed"))
	back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))
	
	# Create abandon confirmation dialog
	_create_abandon_confirmation_dialog()

func _create_abandon_confirmation_dialog():
	abandon_confirmation_dialog = ConfirmationDialog.new()
	abandon_confirmation_dialog.title = "Abandon Quest?"
	abandon_confirmation_dialog.dialog_text = "Are you sure you wish to abandon this quest? Your progress will be lost."
	abandon_confirmation_dialog.ok_button_text = "Yes, Abandon"
	abandon_confirmation_dialog.cancel_button_text = "No, Continue"
	abandon_confirmation_dialog.min_size = Vector2(300, 150)
	
	# Connect confirm signal
	abandon_confirmation_dialog.confirmed.connect(_confirm_abandon_quest)
	
	# Add to the scene
	add_child(abandon_confirmation_dialog)

func initialize(data):
	if not data or not data.has("quest_id"):
		if get_node_or_null("/root/UIManager"):
			UIManager.go_back()
		return
		
	current_quest_id = data.quest_id
	
	# Determine if quest is active or available
	if QuestManager.active_quests.has(current_quest_id):
		is_active = true
		current_quest = QuestManager.active_quests[current_quest_id]
		_setup_active_quest()
	elif QuestManager.get_available_quests().has(current_quest_id):
		is_active = false
		current_quest = QuestManager.get_available_quests()[current_quest_id]
		_setup_available_quest()
	else:
		# Invalid quest ID
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Quest not found", "error")
			UIManager.go_back()

func _setup_active_quest():
	# Set UI elements for an active quest
	quest_name_label.text = current_quest.title
	
	if current_quest.has_deadline:
		time_label.text = _get_fantasy_time_remaining(current_quest)
	else:
		time_label.text = "No time limit inscribed"
		
	description_label.text = current_quest.description
	difficulty_label.text = QuestManager.get_difficulty_name(current_quest.difficulty)
	xp_reward_label.text = str(current_quest.xp_reward) + " Experience"
	categories_label.text = current_quest.category
	
	# Set icon if available
	if current_quest.icon_path and ResourceLoader.exists(current_quest.icon_path):
		quest_icon.texture = load(current_quest.icon_path)
	
	# Set action button
	action_button.text = "Complete Quest"
	
	# If we have multi-step quest, update button text accordingly
	if current_quest.is_multi_step:
		action_button.text = "Mark Progress (%d/%d)" % [current_quest.current_progress, current_quest.total_steps]
		if current_quest.current_progress >= current_quest.total_steps:
			action_button.text = "Complete Epic Task"
	
	# Add abandon quest button
	var parent = action_button.get_parent()
	if parent:
		# Check if we already have an abandon button
		var existing_abandon = parent.get_node_or_null("AbandonButton")
		if not existing_abandon:
			var abandon_button = Button.new()
			abandon_button.name = "AbandonButton"
			abandon_button.text = "Abandon Quest"
			abandon_button.custom_minimum_size = Vector2(action_button.custom_minimum_size.x, action_button.custom_minimum_size.y)
			abandon_button.connect("pressed", Callable(self, "_on_abandon_button_pressed"))
			
			# Add it before the back button
			var back_idx = parent.get_children().find(back_button)
			if back_idx >= 0:
				parent.add_child(abandon_button)
				parent.move_child(abandon_button, back_idx)
			else:
				parent.add_child(abandon_button)

func _setup_available_quest():
	# Set UI elements for an available quest
	quest_name_label.text = current_quest.title
	
	if current_quest.has_deadline:
		var duration_secs = current_quest.deadline - current_quest.creation_time
		time_label.text = "Duration: " + _format_fantasy_duration(duration_secs)
	else:
		time_label.text = "No time limit inscribed"
		
	description_label.text = current_quest.description
	difficulty_label.text = QuestManager.get_difficulty_name(current_quest.difficulty)
	xp_reward_label.text = str(current_quest.xp_reward) + " Experience"
	categories_label.text = current_quest.category
	
	# Set icon if available
	if current_quest.icon_path and ResourceLoader.exists(current_quest.icon_path):
		quest_icon.texture = load(current_quest.icon_path)
	
	# Set action button
	action_button.text = "Accept Quest"

func _on_action_button_pressed():
	if is_active:
		# Complete quest
		if QuestManager.complete_quest(current_quest_id):
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Quest completed! Earned " + 
					str(current_quest.xp_reward) + " XP!", "success")
				UIManager.go_back()
		else:
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Failed to complete quest", "error")
	else:
		# Accept quest
		if QuestManager.start_quest(current_quest_id):
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Quest accepted: " + current_quest.title, "success")
				UIManager.go_back()
		else:
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Failed to accept quest", "error")

func _on_back_button_pressed():
	if get_node_or_null("/root/UIManager"):
		UIManager.go_back()

# Convert seconds to a fantasy-themed time description
func _format_fantasy_duration(seconds: int) -> String:
	var minutes = seconds / 60
	var hours = minutes / 60
	var days = hours / 24
	
	if days > 0:
		if days == 1:
			return "a full sun's cycle"
		elif days <= 7:
			return "%d sun cycles" % days
		elif days <= 30:
			return "%.1f moon cycles" % (float(days) / 7.0)
		else:
			return "many moons"
	elif hours > 0:
		if hours == 1:
			return "a single hourglass"
		elif hours <= 6:
			return "%d hourglasses" % hours
		else:
			return "less than a sun cycle"
	else:
		if minutes <= 5:
			return "a mere moment"
		elif minutes <= 30:
			return "a short while"
		else:
			return "less than an hourglass"

# Get fantasy-themed time remaining text
func _get_fantasy_time_remaining(quest) -> String:
	var current_time = Time.get_unix_time_from_system()
	var time_left = quest.deadline - current_time
	
	if time_left <= 0:
		return "The sands have run out!"
	
	var hours = int(time_left / 3600)
	var days = int(hours / 24)
	
	if days > 0:
		if days == 1:
			return "One sun cycle remains"
		elif days <= 7:
			return "%d sun cycles remain" % days
		else:
			return "%.1f moon cycles remain" % (float(days) / 7.0)
	elif hours > 0:
		if hours == 1:
			return "A single hourglass remains"
		else:
			return "%d hourglasses remain" % hours
	else:
		var minutes = int((time_left % 3600) / 60)
		if minutes <= 5:
			return "Mere moments remain!"
		else:
			return "%d sand grains remain" % minutes

# Handle abandon button press
func _on_abandon_button_pressed():
	# Show confirmation dialog
	if abandon_confirmation_dialog:
		abandon_confirmation_dialog.popup_centered()

# Execute quest abandonment after confirmation
func _confirm_abandon_quest():
	if QuestManager.active_quests.has(current_quest_id):
		# We'll fail the quest rather than just removing it
		if QuestManager.fail_quest(current_quest_id):
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Quest abandoned. May courage find you again.", "info")
				UIManager.go_back()
		else:
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Failed to abandon quest", "error")
	else:
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Invalid quest state", "error")
			UIManager.go_back()
