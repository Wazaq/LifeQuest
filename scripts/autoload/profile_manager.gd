extends Node
## ProfileManager: Handles user profile and character management

# Character stats (will be expanded in future)
enum CharacterStat {
	STRENGTH,
	INTELLIGENCE,
	WISDOM,
	DEXTERITY,
	CONSTITUTION,
	CHARISMA
}

# Character data
var current_character = {
	"name": "",
	"level": 1,
	"xp": 0,
	"xp_to_next_level": 100,
	"stats": {
		CharacterStat.STRENGTH: 1,
		CharacterStat.INTELLIGENCE: 1,
		CharacterStat.WISDOM: 1,
		CharacterStat.DEXTERITY: 1,
		CharacterStat.CONSTITUTION: 1,
		CharacterStat.CHARISMA: 1
	},
	"avatar": "",
	"streak": 0,
	"last_activity": 0,  # Unix timestamp
	"creation_date": 0   # Unix timestamp
}

signal character_created(character_data)
signal character_updated(character_data)
signal level_increased(new_level, rewards) # Changed from level_up to avoid conflict
signal xp_gained(amount, new_total)
signal streak_updated(new_streak)
signal stat_increased(stat, new_value)

func _ready():
	print("ProfileManager: Initializing profile system...")
	# Connect to the QuestManager's signals to update XP
	if get_node_or_null("/root/QuestManager"):
		get_node("/root/QuestManager").connect("quest_completed", Callable(self, "_on_quest_completed"))

func create_character(player_name: String, avatar: String = ""):
	current_character.name = player_name
	current_character.avatar = avatar
	current_character.creation_date = Time.get_unix_time_from_system()
	current_character.last_activity = Time.get_unix_time_from_system()
	
	emit_signal("character_created", current_character)
	print("ProfileManager: Created character - %s" % player_name)
	return current_character

func update_character(data: Dictionary):
	for key in data:
		if key in current_character:
			current_character[key] = data[key]
	
	emit_signal("character_updated", current_character)
	print("ProfileManager: Updated character data")
	return current_character
	
func get_character_name() -> String:
	return current_character.name

func add_xp(amount: int):
	if amount <= 0:
		return
	
	current_character.xp += amount
	
	# Check for level up
	while current_character.xp >= current_character.xp_to_next_level:
		level_up()
	
	emit_signal("xp_gained", amount, current_character.xp)
	print("ProfileManager: Added %d XP, total now %d" % [amount, current_character.xp])
	return current_character.xp

func level_up():
	current_character.level += 1
	current_character.xp -= current_character.xp_to_next_level
	
	# Calculate new XP threshold (simple progression)
	current_character.xp_to_next_level = calculate_xp_for_level(current_character.level + 1)
	
	# Level up rewards would go here
	var rewards = {}
	
	emit_signal("level_increased", current_character.level, rewards)
	print("ProfileManager: Leveled up to %d" % current_character.level)
	return current_character.level

func calculate_xp_for_level(level: int) -> int:
	# Simple formula: 100 * level^1.5
	return int(100 * pow(level, 1.5))

func update_streak():
	var current_time = Time.get_unix_time_from_system()
	var last_day = Time.get_datetime_dict_from_unix_time(current_character.last_activity).day
	var current_day = Time.get_datetime_dict_from_unix_time(current_time).day
	
	if current_day != last_day:
		current_character.streak += 1
		current_character.last_activity = current_time
		emit_signal("streak_updated", current_character.streak)
		print("ProfileManager: Updated streak to %d" % current_character.streak)
	
	return current_character.streak

func increase_stat(stat: int, amount: int = 1):
	if stat in current_character.stats:
		current_character.stats[stat] += amount
		emit_signal("stat_increased", stat, current_character.stats[stat])
		print("ProfileManager: Increased stat %d to %d" % [stat, current_character.stats[stat]])
		return current_character.stats[stat]
	return 0

func get_stat_name(stat: int) -> String:
	match stat:
		CharacterStat.STRENGTH:
			return "Strength"
		CharacterStat.INTELLIGENCE:
			return "Intelligence"
		CharacterStat.WISDOM:
			return "Wisdom"
		CharacterStat.DEXTERITY:
			return "Dexterity"
		CharacterStat.CONSTITUTION:
			return "Constitution"
		CharacterStat.CHARISMA:
			return "Charisma"
		_:
			return "Unknown"

func _on_quest_completed(_quest_id, rewards):
	if "xp" in rewards:
		add_xp(rewards.xp)
	
	# Update streak when a quest is completed
	update_streak()
