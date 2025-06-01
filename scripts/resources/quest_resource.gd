extends Resource
class_name QuestResource

# Basic quest properties
@export var id: String
@export var title: String
@export var description: String
@export var difficulty: int  # Using QuestManager.QuestDifficulty enum
@export var category: String
@export var tags: Array[String] = []
@export var icon_path: String = ""

# Quest progression tracking
@export var is_multi_step: bool = false
@export var total_steps: int = 1
@export var current_progress: int = 0
@export var state: int = 0  # Using QuestManager.QuestState enum
@export var times_completed: int = 0
@export var repeatable: bool = true # default to true special quests would be false

# Time constraints
@export var has_deadline: bool = false
@export var creation_time: int = 0  # Unix timestamp
@export var deadline: int = 0  # Unix timestamp
@export var cooldown_hours: int = 0  # Hours before this quest can appear again

# Rewards
@export var xp_reward: int = 10
@export var stat_rewards: Dictionary = {}  # Stat: amount
@export var item_rewards: Array = []

func _init(data = null):
	if data:
		# Initialize from data dictionary if provided
		from_dictionary(data)
	else:
		# Set default creation time
		creation_time = Time.get_unix_time_from_system() as int

# Convert the quest to a dictionary for saving
func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"difficulty": difficulty,
		"category": category,
		"tags": tags,
		"icon_path": icon_path,
		"is_multi_step": is_multi_step,
		"total_steps": total_steps,
		"current_progress": current_progress,
		"state": state,
		"has_deadline": has_deadline,
		"creation_time": creation_time,
		"deadline": deadline,
		"cooldown_hours": cooldown_hours,
		"xp_reward": xp_reward,
		"stat_rewards": stat_rewards,
		"item_rewards": item_rewards,
		"times_completed": times_completed,
		"repeatable": repeatable
	}

# Initialize the quest from a dictionary
func from_dictionary(data: Dictionary):
	id = data.get("id", "")
	title = data.get("title", "")
	description = data.get("description", "")
	difficulty = data.get("difficulty", 0)
	category = data.get("category", "")
	var tag_array = data.get("tags", [])
	tags.clear() # Clear the existing array
	for tag in tag_array:
		tags.append(tag as String) # Append each element as string
	icon_path = data.get("icon_path", "")
	is_multi_step = data.get("is_multi_step", false)
	total_steps = data.get("total_steps", 1)
	current_progress = data.get("current_progress", 0)
	state = data.get("state", 0)
	has_deadline = data.get("has_deadline", false)
	creation_time = data.get("creation_time", Time.get_unix_time_from_system())
	deadline = data.get("deadline", 0)
	cooldown_hours = data.get("cooldown_hours", 0)
	xp_reward = data.get("xp_reward", 10)
	stat_rewards = data.get("stat_rewards", {})
	item_rewards = data.get("item_rewards", [])
	times_completed = data.get("times_completed", 0)
	repeatable = data.get("repeatable", true)

# Calculate XP reward based on difficulty and steps
func calculate_xp_reward() -> int:
	var base_xp = 10
	
	# Multiply by difficulty factor
	var difficulty_multiplier = 1.0
	match difficulty:
		0:  # Easy
			difficulty_multiplier = 1.0
		1:  # Intermediate
			difficulty_multiplier = 1.5
		2:  # Hard
			difficulty_multiplier = 2.0
		3:  # Epic
			difficulty_multiplier = 3.0
		4:  # Legendary
			difficulty_multiplier = 5.0
		5:  # Special
			difficulty_multiplier = 2.5
	
	# Account for multi-step quests
	var step_multiplier = 1.0
	if is_multi_step and total_steps > 1:
		step_multiplier = sqrt(total_steps)  # Square root for balance
	
	return int(base_xp * difficulty_multiplier * step_multiplier)

# Update quest progress
func update_progress(progress: int) -> bool:
	if not is_multi_step:
		return false
	
	current_progress = clamp(progress, 0, total_steps)
	
	# Auto-complete if reached max steps
	if current_progress >= total_steps:
		state = 2  # QuestManager.QuestState.COMPLETED
		return true
	
	return false

# Check if quest is expired
func is_expired() -> bool:
	if not has_deadline:
		return false
	
	var current_time = Time.get_unix_time_from_system()
	return current_time > deadline

# Create a deadline based on hours from now
func set_deadline_hours(hours: int):
	if hours <= 0:
		has_deadline = false
		deadline = 0
		return
	
	has_deadline = true
	var current_time = Time.get_unix_time_from_system()
	deadline = floor(current_time + (hours * 3600)) as int  # Convert hours to seconds

# Get formatted time remaining string
func get_time_remaining() -> String:
	if not has_deadline:
		return "No deadline"
	
	var current_time = Time.get_unix_time_from_system()
	var time_left = deadline - current_time
	
	if time_left <= 0:
		return "Expired"
	
	var hours = int(time_left / 3600)
	var minutes = int((time_left % 3600) / 60)
	
	if hours > 0:
		return "%d hours, %d minutes" % [hours, minutes]
	else:
		return "%d minutes" % minutes
