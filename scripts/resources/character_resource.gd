extends Resource
class_name CharacterResource

# Basic character information
@export var name: String = ""
@export var avatar_path: String = ""
@export var creation_date: int = 0  # Unix timestamp

# Progression
@export var level: int = 1
@export var xp: int = 0
@export var xp_to_next_level: int = 100

# Stats
@export var stats: Dictionary = {
	0: 1,  # STRENGTH
	1: 1,  # INTELLIGENCE
	2: 1,  # WISDOM
	3: 1,  # DEXTERITY
	4: 1,  # CONSTITUTION
	5: 1   # CHARISMA
}

# Activity tracking
@export var streak: int = 0
@export var last_activity: int = 0  # Unix timestamp
@export var completed_quests: Array = []
@export var failed_quests: Array = []

# Achievements and unlocks
@export var achievements: Array = []
@export var unlocked_features: Array = []

func _init(data = null):
	if data:
		# Initialize from data dictionary if provided
		from_dictionary(data)
	else:
		# Set default timestamps
		creation_date = Time.get_unix_time_from_system() as int
		last_activity = Time.get_unix_time_from_system() as int

# Convert the character to a dictionary for saving
func to_dictionary() -> Dictionary:
	return {
		"name": name,
		"avatar_path": avatar_path,
		"creation_date": creation_date,
		"level": level,
		"xp": xp,
		"xp_to_next_level": xp_to_next_level,
		"stats": stats,
		"streak": streak,
		"last_activity": last_activity,
		"completed_quests": completed_quests,
		"failed_quests": failed_quests,
		"achievements": achievements,
		"unlocked_features": unlocked_features
	}

# Initialize the character from a dictionary
func from_dictionary(data: Dictionary):
	name = data.get("name", "")
	avatar_path = data.get("avatar_path", "")
	creation_date = data.get("creation_date", Time.get_unix_time_from_system())
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	xp_to_next_level = data.get("xp_to_next_level", 100)
	stats = data.get("stats", {
		0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1
	})
	streak = data.get("streak", 0)
	last_activity = data.get("last_activity", Time.get_unix_time_from_system())
	completed_quests = data.get("completed_quests", [])
	failed_quests = data.get("failed_quests", [])
	achievements = data.get("achievements", [])
	unlocked_features = data.get("unlocked_features", [])

# Add XP and handle level-ups
func add_xp(amount: int) -> bool:
	if amount <= 0:
		return false
	
	xp += amount
	var leveled_up = false
	
	# Check for level-ups
	while xp >= xp_to_next_level:
		level_up()
		leveled_up = true
	
	return leveled_up

# Handle level up
func level_up() -> void:
	level += 1
	xp -= xp_to_next_level
	xp_to_next_level = calculate_xp_for_level(level + 1)

# Calculate required XP for a given level
func calculate_xp_for_level(target_level: int) -> int:
	# Simple formula: 100 * level^1.5
	return int(100 * pow(target_level, 1.5))

# Update streak based on daily activity
func update_streak() -> int:
	var current_time = Time.get_unix_time_from_system()
	var last_day = Time.get_datetime_dict_from_unix_time(last_activity).day
	var current_day = Time.get_datetime_dict_from_unix_time(current_time).day
	
	if current_day != last_day:
		streak += 1
		last_activity = floor(current_time) as int
	
	return streak

# Break streak if inactive for more than a day
func check_streak_break() -> bool:
	var current_time = Time.get_unix_time_from_system()
	var seconds_since_last_activity = current_time - last_activity
	
	# If more than 48 hours (2 days) have passed, break the streak
	if seconds_since_last_activity > (48 * 3600):
		streak = 0
		last_activity = floor(current_time) as int
		return true
	
	return false

# Get the stat name from its ID
func get_stat_name(stat_id: int) -> String:
	match stat_id:
		0: return "Strength"
		1: return "Intelligence"
		2: return "Wisdom"
		3: return "Dexterity"
		4: return "Constitution"
		5: return "Charisma"
		_: return "Unknown"

# Increase a stat by the specified amount
func increase_stat(stat_id: int, amount: int = 1) -> int:
	if not stats.has(stat_id):
		stats[stat_id] = 0
	
	stats[stat_id] += amount
	return stats[stat_id]

# Calculate days since character creation
func days_since_creation() -> int:
	var current_time = Time.get_unix_time_from_system()
	var seconds_since_creation = current_time - creation_date
	return int(seconds_since_creation / (24 * 3600))  # Convert seconds to days

# Get character's play time statistics
func get_stats_summary() -> Dictionary:
	return {
		"days_active": days_since_creation(),
		"longest_streak": streak, # In the future, track historical max streak
		"quests_completed": completed_quests.size(),
		"quests_failed": failed_quests.size(),
		"completion_rate": calculate_completion_rate()
	}

# Calculate quest completion rate
func calculate_completion_rate() -> float:
	var total_quests = completed_quests.size() + failed_quests.size()
	if total_quests == 0:
		return 0.0
	
	return float(completed_quests.size()) / float(total_quests) * 100.0
