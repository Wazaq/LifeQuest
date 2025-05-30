extends Control
## HeaderBar: Top navigation header with character info and contextual content

# Character info elements
@onready var name_and_streak: Label = $MainContainer/HBoxContainer/LeftSection/NameAndStreak
@onready var xp_label: Label = $MainContainer/HBoxContainer/LeftSection/XPLabel
@onready var rank_label: Label = $MainContainer/HBoxContainer/LeftSection/RankLabel

# Quest info elements
@onready var urgent_quest_title: Label = $MainContainer/HBoxContainer/RightSection/UrgentQuestTitle
@onready var urgent_quest_name: Label = $MainContainer/HBoxContainer/RightSection/UrgentQuestName
@onready var urgent_quest_time: Label = $MainContainer/HBoxContainer/RightSection/UrgentQuestTime

func _ready():
	print("HeaderBar: Initializing")
	_update_character_info()
	_update_urgent_quest()

func _update_character_info():
	"""Update the left side character information"""
	if not ProfileManager or not ProfileManager.current_character:
		_show_no_character_info()
		return
	
	var character = ProfileManager.current_character
	
	# Name and streak with fire icon
	var streak_text = ""
	if character.streak > 0:
		streak_text = " ð¥ " + str(character.streak)
	name_and_streak.text = character.name + streak_text
	
	# XP display
	xp_label.text = "XP: " + str(character.xp)
	
	# Character rank/title
	var title = _get_character_title(character.level)
	rank_label.text = title

func _update_urgent_quest():
	"""Update the right side with most urgent active quest"""
	if not QuestManager or QuestManager.active_quests.is_empty():
		_show_no_urgent_quest()
		return
	
	# Find quest with shortest time remaining
	var most_urgent_quest = null
	var shortest_time = INF
	
	for quest_id in QuestManager.active_quests:
		var quest = QuestManager.active_quests[quest_id]
		if quest.has_deadline and quest.deadline > 0:
			var time_remaining = quest.deadline - Time.get_unix_time_from_system()
			if time_remaining > 0 and time_remaining < shortest_time:
				shortest_time = time_remaining
				most_urgent_quest = quest
	
	if most_urgent_quest:
		urgent_quest_title.text = "Urgent Quest"
		urgent_quest_name.text = most_urgent_quest.title
		
		# Format time remaining with fantasy theme
		var time_remaining = most_urgent_quest.deadline - Time.get_unix_time_from_system()
		urgent_quest_time.text = _format_time_remaining(time_remaining)
	else:
		_show_no_urgent_quest()

func _show_no_character_info():
	"""Show placeholder when no character is loaded"""
	name_and_streak.text = "No Character"
	xp_label.text = "XP: 0"
	rank_label.text = "Peasant"

func _show_no_urgent_quest():
	"""Show placeholder when no urgent quests"""
	urgent_quest_title.text = "No Urgent Quests"
	urgent_quest_name.text = ""
	urgent_quest_time.text = ""

func _get_character_title(level: int) -> String:
	"""Get fantasy title based on character level"""
	match level:
		1, 2:
			return "Peasant"
		3, 4, 5:
			return "Squire"
		6, 7, 8, 9, 10:
			return "Knight"
		11, 12, 13, 14, 15:
			return "Noble"
		16, 17, 18, 19, 20:
			return "Hero"
		_:
			return "Legend"

func _format_time_remaining(seconds: float) -> String:
	"""Format time remaining with fantasy theming"""
	if seconds <= 0:
		return "Expired"
	
	var total_seconds = int(seconds)
	@warning_ignore("integer_division")
	var hours = total_seconds / 3600
	@warning_ignore("integer_division")
	var minutes = (total_seconds % 3600) / 60
	
	if hours > 24:
		@warning_ignore("integer_division")
		var days = hours / 24
		return str(days) + " sun cycles remain"
	elif hours > 0:
		return str(hours) + " hourglasses remain"
	else:
		return str(minutes) + " minutes remain"

func refresh_display():
	"""Public function to refresh both character and quest info"""
	_update_character_info()
	_update_urgent_quest()
