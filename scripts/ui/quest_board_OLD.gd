extends Control
## QuestBoard: Main screen for managing quests

# References to UI containers
@onready var active_quests_container: VBoxContainer = $MarginContainer/VBoxContainer/ActiveQuestSectionBG/ActiveQuestsSection/ActiveQuestsScrollContainer/ActiveQuestsContainerNew
@onready var active_count_label: Label = $MarginContainer/VBoxContainer/ActiveQuestSectionBG/ActiveQuestsSection/HeaderRow/CountLabel
@onready var get_new_quest_button: Button = $MarginContainer/VBoxContainer/GetNewQuestButton
@onready var reset_cooldown_button: Button = $MarginContainer/VBoxContainer/ResetCooldownButton

# Track loaded quest items
var active_quest_items = {}

# Load the quest item scene
var quest_item_scene = preload("res://scenes/quests/quest_item_improved.tscn")

func _ready():
	print("QuestBoard: Initializing quest board")
	
	# Wait for the scene to be fully ready
	await get_tree().process_frame
	
	# Configure containers to expand
	active_quests_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Set minimum height for section containers
	$MarginContainer/VBoxContainer/ActiveQuestSectionBG.custom_minimum_size.y = 200
	$MarginContainer/VBoxContainer/AvailQuestSectionBG.custom_minimum_size.y = 200
	
	# Ensure ScrollContainer takes space
	$MarginContainer/VBoxContainer/ActiveQuestSectionBG/ActiveQuestsSection/ActiveQuestsScrollContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$MarginContainer/VBoxContainer/AvailQuestSectionBG/AvailableQuestsSection/AvailableQuestsScrollContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Ensure parent MarginContainer has proper size
	$MarginContainer.custom_minimum_size = Vector2(400, 600)
	$MarginContainer.anchor_right = 1.0
	$MarginContainer.anchor_bottom = 1.0
	
	# Add bottom margin to prevent overlap with bottom nav bar
	var bottom_margin = 90  # Height of bottom nav bar + some padding
	$MarginContainer.add_theme_constant_override("margin_bottom", bottom_margin)
	$MarginContainer.add_theme_constant_override("margin_left", 10)
	$MarginContainer.add_theme_constant_override("margin_right", 10)
	$MarginContainer.add_theme_constant_override("margin_top", 10)
	
	# Connect signals
	if get_node_or_null("/root/QuestManager"):
		QuestManager.quest_started.connect(_on_quest_started)
		QuestManager.quest_completed.connect(_on_quest_completed)
		QuestManager.quest_failed.connect(_on_quest_failed)
		QuestManager.quest_expired.connect(_on_quest_expired)
	
	# Connect UI button signals
	if get_new_quest_button:
		get_new_quest_button.pressed.connect(_on_get_new_quest_pressed)
	else:
		push_error("QuestBoard: get_new_quest_button not found")
		
	if reset_cooldown_button:
		reset_cooldown_button.pressed.connect(_on_reset_cooldown_pressed)
	else:
		push_error("QuestBoard: reset_cooldown_button not found")
	
	# Initial UI update
	print("QuestBoard: Updating quest display")
	update_quest_display()

func update_quest_display():
	update_active_quests()
	update_button_visibility()

func update_active_quests():
	# Clear existing items first
	for item in active_quest_items.values():
		if is_instance_valid(item):
			item.queue_free()
	
	active_quest_items.clear()
	
	# Get active quests from QuestManager
	var active_quests = QuestManager.active_quests
	
	# Debug output for active quests
	print("QuestBoard: Active quests count: ", active_quests.size())
	for quest_id in active_quests:
		print("QuestBoard: Active quest - ", active_quests[quest_id].title)
	
	# Update count label with fantasy-themed format
	var active_count = active_quests.size()
	var max_count = QuestManager.max_active_quests
	
	# Choose a message based on how many quest slots are filled
	if active_count == 0:
		active_count_label.text = "Quest Log Empty"
	elif active_count < max_count:
		active_count_label.text = "%d/%d Adventures Underway" % [active_count, max_count]
	else:
		active_count_label.text = "Quest Log Full!"
	
	# Create quest items for each active quest
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		print("QuestBoard: Adding active quest to UI - ", quest.title)
		add_quest_item(quest, active_quests_container, true)
		
	# Debug output after adding
	await get_tree().process_frame
	print("QuestBoard: Active container children after adding: ", active_quests_container.get_child_count())

func add_quest_item(quest, container, is_active):
	# Create a new quest item instance
	var quest_item = quest_item_scene.instantiate()
	
	# Set proper size flags before adding to container
	quest_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add to container
	container.add_child(quest_item)
	
	# Initialize the quest item
	quest_item.initialize(quest, is_active)
	quest_item.connect("quest_selected", Callable(self, "_on_quest_selected"))
	
	# Force the quest item to be visible
	quest_item.visible = true
	
	# Print position and visibility info
	print("QuestBoard: Added " + ("active" if is_active else "available") + " quest item for: " + quest.title)
	print("QuestBoard: Quest item visible: " + str(quest_item.visible))
	print("QuestBoard: Quest item global position: " + str(quest_item.global_position))
	print("QuestBoard: Quest item size: " + str(quest_item.size))
	
	# Store reference for active quests onlye
	active_quest_items[quest.id] = quest_item

func _on_quest_selected(quest_id):
	# Open the quest details screen for the selected quest
	if get_node_or_null("/root/UIManager"):
		UIManager.open_screen("quest_details", {"quest_id": quest_id})
	else:
		print("QuestBoard: UIManager not found, can't open quest details")

func _on_get_new_quest_pressed():
	# In the full implementation, this would request a new quest
	if get_node_or_null("/root/QuestManager"):
		# Check if we've reached the maximum number of active quests
		if QuestManager.active_quests.size() >= QuestManager.max_active_quests:
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Maximum number of active quests reached (%d)" % QuestManager.max_active_quests, "warning")
			return
		
		var quest = QuestManager.get_random_quest()
		if quest:
			# Start the quest
			QuestManager.start_quest(quest.id)
			update_quest_display()
			
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("New quest accepted: %s" % quest.title, "success")
		else:
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("No new quests available at this time", "info")
	
	# Update the button visibility based on active quest count
	update_button_visibility()

func _on_reset_cooldown_pressed():
	print("QuestBoard: Reset cooldown button pressed")
	
	if get_node_or_null("/root/QuestManager"):
		var count = QuestManager.reset_all_cooldowns()
		update_quest_display()
		
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Reset cooldowns for %d quests" % count, "info")
	else:
		print("QuestBoard: QuestManager not found, can't reset cooldowns")

func _on_quest_started(_quest_id):
	update_quest_display()

func _on_quest_completed(_quest_id, _rewards):
	update_quest_display()

func _on_quest_failed(_quest_id):
	update_quest_display()

func _on_quest_expired(_quest_id):
	update_quest_display()

func update_button_visibility():
	# Update Get New Quest button with quest pool count
	if get_node_or_null("/root/QuestManager"):
		var active_count = QuestManager.active_quests.size()
		var max_count = QuestManager.max_active_quests
		var pool_count = QuestManager.get_available_quest_count()
		
		if get_new_quest_button:
			# Update button text to include pool count
			get_new_quest_button.text = "Get New Quest (%d in pool)" % pool_count
			
			# Hide the button if we've reached the max active quests
			get_new_quest_button.visible = active_count < max_count
		
		if reset_cooldown_button:
			reset_cooldown_button.visible = true # TODO: Add feature flag here later
