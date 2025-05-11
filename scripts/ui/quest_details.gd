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

func _ready():
	# Connect signals
	action_button.connect("pressed", Callable(self, "_on_action_button_pressed"))
	back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))

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
		time_label.text = current_quest.get_time_remaining()
	else:
		time_label.text = "No deadline"
		
	description_label.text = current_quest.description
	difficulty_label.text = QuestManager.get_difficulty_name(current_quest.difficulty)
	xp_reward_label.text = str(current_quest.xp_reward) + " XP"
	categories_label.text = current_quest.category
	
	# Set icon if available
	if current_quest.icon_path and ResourceLoader.exists(current_quest.icon_path):
		quest_icon.texture = load(current_quest.icon_path)
	
	# Set action button
	action_button.text = "Complete Quest"

func _setup_available_quest():
	# Set UI elements for an available quest
	quest_name_label.text = current_quest.title
	
	if current_quest.has_deadline:
		time_label.text = "Duration: " + str(current_quest.deadline - current_quest.creation_time) + " seconds"
	else:
		time_label.text = "No deadline"
		
	description_label.text = current_quest.description
	difficulty_label.text = QuestManager.get_difficulty_name(current_quest.difficulty)
	xp_reward_label.text = str(current_quest.xp_reward) + " XP"
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
