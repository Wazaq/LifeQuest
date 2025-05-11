extends Control
## QuestCreation: Admin-only screen for creating new quests

# UI References
@onready var title_input = $VBoxContainer/TitleSection/TitleInput
@onready var description_input = $VBoxContainer/DescriptionSection/DescriptionInput
@onready var difficulty_dropdown = $VBoxContainer/ParametersSection/DifficultyRow/DifficultyDropdown
@onready var category_dropdown = $VBoxContainer/ParametersSection/CategoryRow/CategoryDropdown
@onready var tags_input = $VBoxContainer/ParametersSection/TagsRow/TagsInput
@onready var xp_input = $VBoxContainer/ParametersSection/XPRow/XPInput
@onready var cooldown_input = $VBoxContainer/ParametersSection/CooldownRow/CooldownInput
@onready var deadline_checkbox = $VBoxContainer/ParametersSection/DeadlineRow/DeadlineCheckbox
@onready var deadline_input = $VBoxContainer/ParametersSection/DeadlineRow/DeadlineInput
@onready var icon_button = $VBoxContainer/IconSection/SelectIconButton
@onready var selected_icon_display = $VBoxContainer/IconSection/SelectedIconDisplay
@onready var save_button = $VBoxContainer/ButtonsSection/SaveButton
@onready var cancel_button = $VBoxContainer/ButtonsSection/CancelButton

var selected_icon_path = ""

func _ready():
	# Set up difficulty dropdown
	difficulty_dropdown.clear()
	difficulty_dropdown.add_item("Easy", QuestManager.QuestDifficulty.EASY)
	difficulty_dropdown.add_item("Intermediate", QuestManager.QuestDifficulty.INTERMEDIATE)
	difficulty_dropdown.add_item("Hard", QuestManager.QuestDifficulty.HARD)
	difficulty_dropdown.add_item("Epic", QuestManager.QuestDifficulty.EPIC)
	difficulty_dropdown.add_item("Legendary", QuestManager.QuestDifficulty.LEGENDARY)
	difficulty_dropdown.add_item("Special", QuestManager.QuestDifficulty.SPECIAL)
	
	# Set up category dropdown
	category_dropdown.clear()
	for category in QuestManager.CATEGORIES:
		category_dropdown.add_item(category.capitalize())
	
	# Connect signals
	save_button.connect("pressed", Callable(self, "_on_save_pressed"))
	cancel_button.connect("pressed", Callable(self, "_on_cancel_pressed"))
	icon_button.connect("pressed", Callable(self, "_on_select_icon_pressed"))
	deadline_checkbox.connect("toggled", Callable(self, "_on_deadline_toggled"))
	
	# Initial state
	deadline_input.editable = deadline_checkbox.button_pressed

func _on_save_pressed():
	# Validate inputs
	if title_input.text.strip_edges().is_empty():
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Quest title cannot be empty", "error")
		return
	
	if description_input.text.strip_edges().is_empty():
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Quest description cannot be empty", "error")
		return
	
	# Create new quest resource
	var quest = QuestResource.new()
	quest.id = _generate_id_from_title(title_input.text)
	quest.title = title_input.text
	quest.description = description_input.text
	quest.difficulty = difficulty_dropdown.get_selected_id()
	quest.category = QuestManager.CATEGORIES[category_dropdown.selected]
	
	# Parse tags
	var tags_text = tags_input.text.strip_edges()
	if not tags_text.is_empty():
		quest.tags = tags_text.split(",", false)
		# Trim whitespace from each tag
		for i in range(quest.tags.size()):
			quest.tags[i] = quest.tags[i].strip_edges()
	
	# Set XP reward
	if not xp_input.text.is_empty() and xp_input.text.is_valid_int():
		quest.xp_reward = int(xp_input.text)
	else:
		quest.xp_reward = quest.calculate_xp_reward()
	
	# Set cooldown
	if not cooldown_input.text.is_empty() and cooldown_input.text.is_valid_int():
		quest.cooldown_hours = int(cooldown_input.text)
	
	# Set deadline if enabled
	if deadline_checkbox.button_pressed and not deadline_input.text.is_empty() and deadline_input.text.is_valid_int():
		quest.set_deadline_hours(int(deadline_input.text))
	
	# Set icon path
	quest.icon_path = selected_icon_path
	
	# Add quest to the quest manager
	if QuestManager.create_quest(quest):
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Quest created: " + quest.title, "success")
			UIManager.go_back()
	else:
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Failed to create quest", "error")

func _on_cancel_pressed():
	if get_node_or_null("/root/UIManager"):
		UIManager.go_back()

func _on_select_icon_pressed():
	# In a real implementation, this would open a file dialog
	# For now, we'll just set a placeholder path
	selected_icon_path = "res://assets/icons/quests/placeholder.png"
	
	# If the icon exists, load and display it
	if ResourceLoader.exists(selected_icon_path):
		selected_icon_display.texture = load(selected_icon_path)
	
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Selected placeholder icon (no file dialog yet)", "info")

func _on_deadline_toggled(toggled):
	deadline_input.editable = toggled

func _generate_id_from_title(title):
	# Create a snake_case id from the quest title
	var id = title.to_lower().replace(" ", "_")
	
	# Remove special characters
	var regex = RegEx.new()
	regex.compile("[^a-z0-9_]")
	id = regex.sub(id, "", true)
	
	# Add timestamp to ensure uniqueness
	id += "_" + str(Time.get_unix_time_from_system())
	
	return id
