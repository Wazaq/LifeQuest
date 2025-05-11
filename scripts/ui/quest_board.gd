extends Control
## QuestBoard: Main screen for managing quests

# References to UI containers
@onready var active_quests_container = $VBoxContainer/ActiveQuestsSection/QuestsContainer
@onready var available_quests_container = $VBoxContainer/AvailableQuestsSection/QuestsContainer
@onready var active_count_label = $VBoxContainer/ActiveQuestsSection/HeaderRow/CountLabel
@onready var refresh_button = $VBoxContainer/AvailableQuestsSection/RefreshButton
@onready var get_new_quest_button = $VBoxContainer/GetNewQuestButton

# Track loaded quest items
var active_quest_items = {}
var available_quest_items = {}

# Load the quest item scene
var quest_item_scene = preload("res://scenes/quests/quest_item.tscn")

func _ready():
	print("QuestBoard: Initializing quest board")
	
	# Connect signals
	if get_node_or_null("/root/QuestManager"):
		QuestManager.connect("quest_started", Callable(self, "_on_quest_started"))
		QuestManager.connect("quest_completed", Callable(self, "_on_quest_completed"))
		QuestManager.connect("quest_failed", Callable(self, "_on_quest_failed"))
		QuestManager.connect("quest_expired", Callable(self, "_on_quest_expired"))
	
	# Connect UI button signals
	refresh_button.connect("pressed", Callable(self, "_on_refresh_pressed"))
	get_new_quest_button.connect("pressed", Callable(self, "_on_get_new_quest_pressed"))
	
	# Initial UI update
	update_quest_display()

func update_quest_display():
	update_active_quests()
	update_available_quests()

func update_active_quests():
	# Clear existing items first
	for item in active_quest_items.values():
		if is_instance_valid(item):
			item.queue_free()
	
	active_quest_items.clear()
	
	# Get active quests from QuestManager
	var active_quests = QuestManager.active_quests
	
	# Update count label
	active_count_label.text = "%d active" % active_quests.size()
	
	# Create quest items for each active quest
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		add_quest_item(quest, active_quests_container, true)

func update_available_quests():
	# Clear existing items first
	for item in available_quest_items.values():
		if is_instance_valid(item):
			item.queue_free()
	
	available_quest_items.clear()
	
	# Create quest items for each available quest
	# This would come from QuestManager's available quests
	# For now, we'll just use a placeholder
	var available_quests = QuestManager.get_available_quests()
	
	for quest_id in available_quests:
		var quest = available_quests[quest_id]
		add_quest_item(quest, available_quests_container, false)

func add_quest_item(quest, container, is_active):
	# Create a new quest item instance
	var quest_item = quest_item_scene.instantiate()
	container.add_child(quest_item)
	
	# Initialize the quest item
	quest_item.initialize(quest, is_active)
	quest_item.connect("quest_selected", Callable(self, "_on_quest_selected"))
	
	# Store reference
	if is_active:
		active_quest_items[quest.id] = quest_item
	else:
		available_quest_items[quest.id] = quest_item

func _on_quest_selected(quest_id):
	# Open the quest details screen for the selected quest
	if get_node_or_null("/root/UIManager"):
		UIManager.open_screen("quest_details", {"quest_id": quest_id})
	else:
		print("QuestBoard: UIManager not found, can't open quest details")

func _on_refresh_pressed():
	# In the full implementation, this would show an ad and refresh quests
	if get_node_or_null("/root/QuestManager"):
		QuestManager.refresh_available_quests()
		update_available_quests()
		
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Refreshed available quests", "info")

func _on_get_new_quest_pressed():
	# In the full implementation, this would request a new quest
	if get_node_or_null("/root/QuestManager"):
		var quest = QuestManager.get_random_quest()
		if quest:
			update_quest_display()
			
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("New quest available!", "success")
		else:
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("No new quests available at this time", "info")

func _on_quest_started(_quest_id):
	update_quest_display()

func _on_quest_completed(_quest_id, _rewards):
	update_quest_display()

func _on_quest_failed(_quest_id):
	update_quest_display()

func _on_quest_expired(_quest_id):
	update_quest_display()
