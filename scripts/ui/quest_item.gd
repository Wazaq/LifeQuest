extends Control
## QuestItem: UI element representing a quest in a list

signal quest_selected(quest_id)

@onready var quest_name_label = $HBoxContainer/VBoxContainer/QuestNameLabel
@onready var quest_icon = $HBoxContainer/QuestIcon
@onready var quest_time_label = $HBoxContainer/VBoxContainer/TimeLabel
@onready var detail_button = $HBoxContainer/DetailButton

var quest_id = ""
var is_active = false

func _ready():
	# Connect signals
	detail_button.connect("pressed", Callable(self, "_on_detail_button_pressed"))
	connect("gui_input", Callable(self, "_on_gui_input"))

func initialize(quest, active):
	if not quest:
		push_error("QuestItem: Attempted to initialize with null quest")
		return
		
	quest_id = quest.id
	is_active = active
	
	# Set UI elements
	quest_name_label.text = quest.title
	
	# Set icon if available
	if quest.icon_path and ResourceLoader.exists(quest.icon_path):
		quest_icon.texture = load(quest.icon_path)
	
	# Set time label based on status
	if is_active:
		if quest.has_deadline:
			quest_time_label.text = quest.get_time_remaining()
		else:
			quest_time_label.text = QuestManager.get_difficulty_name(quest.difficulty)
	else:
		quest_time_label.text = QuestManager.get_difficulty_name(quest.difficulty)

func _on_detail_button_pressed():
	emit_signal("quest_selected", quest_id)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		emit_signal("quest_selected", quest_id)
