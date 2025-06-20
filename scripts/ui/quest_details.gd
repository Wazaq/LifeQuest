extends Control
## QuestDetails: Screen showing detailed information about a quest

# UI References
@onready var quest_name_label = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/QuestHeader/QuestTitle
@onready var time_label = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/QuestDetails/TimeInfo
@onready var description_label = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/QuestDetails/QuestDescription
@onready var difficulty_label = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/QuestDetails/DifficultyInfo
@onready var xp_reward_label = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/QuestDetails/RewardInfo
@onready var categories_label = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/QuestDetails/CategoryInfo
@onready var action_button = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/ActionButtons/CompleteButton
@onready var back_button = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/ActionButtons/BackButton
@onready var abandon_button: Button = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/ActionButtons/AbandonButton
@onready var abandon_confirmation_dialog: ConfirmationDialog = $MarginContainer/QuestCardBackground/ContentContainer/ContentPadding/QuestSections/ActionButtons/AbandonButton/ConfirmationDialog

var current_quest_id = ""
var is_active = false
var current_quest = null

func _ready():
	# Connect signals
	action_button.connect("pressed", Callable(self, "_on_action_button_pressed"))
	back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))
	abandon_button.connect("pressed", Callable(self, "_on_abandon_button_pressed"))
	
	# Confirm Dialog signal
	abandon_confirmation_dialog.confirmed.connect(_confirm_abandon_quest)
	abandon_confirmation_dialog.canceled.connect(abandon_cancelled)


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
		
	# Set action button
	action_button.text = "Complete Quest"
	
	# If we have multi-step quest, update button text accordingly
	if current_quest.is_multi_step:
		action_button.text = "Mark Progress (%d/%d)" % [current_quest.current_progress, current_quest.total_steps]
		if current_quest.current_progress >= current_quest.total_steps:
			action_button.text = "Complete Epic Task"

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
	@warning_ignore("integer_division")
	var minutes = seconds / 60
	@warning_ignore("integer_division")
	var hours = minutes / 60
	@warning_ignore("integer_division")
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
	@warning_ignore("integer_division")
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
	abandon_confirmation_dialog.visible = true	

# Cancelling and closing the dialog box	
func abandon_cancelled(): abandon_confirmation_dialog.visible = false


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
