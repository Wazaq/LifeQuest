extends Node
## QuestManager: Handles quest creation, tracking, and completion

# Quest difficulty levels
enum QuestDifficulty {
	EASY,
	INTERMEDIATE,
	HARD,
	EPIC,
	LEGENDARY,
	SPECIAL
}

# Quest categories
const CATEGORIES = [
	"physical",
	"mental",
	"creative",
	"social",
	"routine",
	"learning"
]

# Quest states
enum QuestState {
	AVAILABLE,
	ACTIVE,
	COMPLETED,
	FAILED,
	EXPIRED
}

# Quests dictionaries
var all_quests = {}  # All possible quests by ID
var active_quests = {}  # Currently active quests by ID
var available_quests = {}  # Quests available to take by ID
var completed_quests = {}  # Completed quests with timestamps by ID
var failed_quests = []  # Failed quests with timestamps

# Quest configuration
var max_active_quests = 3  # Maximum number of active quests allowed
var available_quest_count = 5  # Number of quests available at once
var last_refresh_time = 0  # Unix timestamp of last quest refresh

signal quest_created(quest)
signal quest_started(quest_id)
signal quest_progressed(quest_id, progress, max_steps)
signal quest_completed(quest_id, rewards)
signal quest_failed(quest_id)
signal quest_expired(quest_id)
signal available_quests_refreshed

func _ready():
	print("QuestManager: Initializing quest system...")
	
	# Load game data if available
	call_deferred("_load_game_data")
	
	# Set initial last refresh time
	last_refresh_time = Time.get_unix_time_from_system()
	
	# Set up a timer to check for quest expirations
	var timer = Timer.new()
	timer.wait_time = 3600  # Check every hour
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_check_quest_expirations"))
	add_child(timer)
	
	# Add example quests if there are no quests yet
	call_deferred("add_example_quests")

# Create a new quest
func create_quest(quest_data):
	var quest
	
	# Check if quest_data is already a QuestResource
	if quest_data is QuestResource:
		quest = quest_data
	else:
		# Create a new QuestResource if we were passed a dictionary
		quest = QuestResource.new(quest_data)
	
	# Ensure quest has a unique ID
	if quest.id.is_empty():
		quest.id = "quest_" + str(Time.get_unix_time_from_system())
	
	# Store in all_quests dictionary
	all_quests[quest.id] = quest
	
	# Save the updated quests data
	_save_game_data()
	
	emit_signal("quest_created", quest)
	print("QuestManager: Created quest - %s" % quest.title)
	
	# Make sure available quests is updated
	refresh_available_quests()
	
	return true

# Start a quest - move from available to active
func start_quest(quest_id):
	if quest_id in active_quests:
		print("QuestManager: Quest already active - %s" % quest_id)
		return false
	
	# Make sure quest exists in available quests
	if not quest_id in available_quests:
		print("QuestManager: Quest not available - %s" % quest_id)
		return false
	
	# Get the quest from available quests
	var quest = available_quests[quest_id]
	
	# Update quest state
	quest.state = QuestState.ACTIVE
	
	# Set deadline if applicable
	if quest.has_deadline and quest.deadline == 0:
		quest.set_deadline_hours(24)  # Default 24 hour deadline
	
	# Move to active quests
	active_quests[quest_id] = quest
	available_quests.erase(quest_id)
	
	_save_game_data()
	
	emit_signal("quest_started", quest_id)
	print("QuestManager: Started quest - %s" % quest.title)
	return true

# Update progress on a multi-step quest
func update_quest_progress(quest_id, progress):
	if not quest_id in active_quests:
		print("QuestManager: Cannot update progress on inactive quest - %s" % quest_id)
		return false
	
	var quest = active_quests[quest_id]
	
	# Check if quest is multi-step
	if not quest.is_multi_step:
		print("QuestManager: Cannot update progress on non-multi-step quest - %s" % quest_id)
		return false
	
	# Update progress
	var completed = quest.update_progress(progress)
	
	# Emit progress signal
	emit_signal("quest_progressed", quest_id, quest.current_progress, quest.total_steps)
	print("QuestManager: Updated quest progress - %s (%d/%d)" % [quest_id, quest.current_progress, quest.total_steps])
	
	# If completed by progress update, handle completion
	if completed:
		return complete_quest(quest_id)
	
	_save_game_data()
	return true

# Complete a quest
func complete_quest(quest_id):
	if not quest_id in active_quests:
		print("QuestManager: Cannot complete inactive quest - %s" % quest_id)
		return false
	
	var quest = active_quests[quest_id]
	
	# Update quest state
	quest.state = QuestState.COMPLETED
	
	# Calculate rewards
	var rewards = {
		"xp": quest.xp_reward,
		"stats": quest.stat_rewards,
		"items": quest.item_rewards
	}
	
	# Record completion time for cooldown
	var completion_data = quest.to_dictionary()
	completion_data["completion_time"] = Time.get_unix_time_from_system()
	
	# Store in completed_quests dictionary
	completed_quests[quest_id] = completion_data
	
	# Remove from active quests
	active_quests.erase(quest_id)
	
	_save_game_data()
	
	emit_signal("quest_completed", quest_id, rewards)
	print("QuestManager: Completed quest - %s" % quest.title)
	return rewards

# Fail a quest
func fail_quest(quest_id):
	if not quest_id in active_quests:
		print("QuestManager: Cannot fail inactive quest - %s" % quest_id)
		return false
	
	var quest = active_quests[quest_id]
	
	# Update quest state
	quest.state = QuestState.FAILED
	
	# Store in failed_quests with timestamp
	var failed_data = quest.to_dictionary()
	failed_data["failure_time"] = Time.get_unix_time_from_system()
	failed_quests.append(failed_data)
	
	# Remove from active quests
	active_quests.erase(quest_id)
	
	_save_game_data()
	
	emit_signal("quest_failed", quest_id)
	print("QuestManager: Failed quest - %s" % quest.title)
	return true

# Check for expired quests
func _check_quest_expirations():
	var current_time = Time.get_unix_time_from_system()
	var expired_quests = []
	
	# Check all active quests for expiration
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		if quest.has_deadline and quest.deadline > 0 and current_time > quest.deadline:
			expired_quests.append(quest_id)
	
	# Process expired quests
	for quest_id in expired_quests:
		expire_quest(quest_id)
		
	return expired_quests.size() > 0

# Expire a quest
func expire_quest(quest_id):
	if not quest_id in active_quests:
		return false
		
	var quest = active_quests[quest_id]
	
	# Update quest state
	quest.state = QuestState.EXPIRED
	
	# Remove from active quests
	active_quests.erase(quest_id)
	
	_save_game_data()
	
	emit_signal("quest_expired", quest_id)
	print("QuestManager: Expired quest - %s" % quest.title)
	return true

# Get a difficulty name from the enum value
func get_difficulty_name(difficulty: int) -> String:
	match difficulty:
		QuestDifficulty.EASY:
			return "Easy"
		QuestDifficulty.INTERMEDIATE:
			return "Intermediate"
		QuestDifficulty.HARD:
			return "Hard"
		QuestDifficulty.EPIC:
			return "Epic"
		QuestDifficulty.LEGENDARY:
			return "Legendary"
		QuestDifficulty.SPECIAL:
			return "Special"
		_:
			return "Unknown"

# Get a random quest from the available quests
func get_random_quest():
	# If no available quests, return null
	if available_quests.is_empty():
		print("QuestManager: No available quests to select from")
		return null
	
	# Get random quest ID from available quests
	var available_ids = available_quests.keys()
	available_ids.shuffle()
	var random_id = available_ids[0]
	
	print("QuestManager: Selected random quest - %s" % available_quests[random_id].title)
	return available_quests[random_id]

# Get the available quests dictionary
func get_available_quests() -> Dictionary:
	return available_quests

# Get number of available quests (for UI display)
func get_available_quest_count() -> int:
	var eligible_count = 0
	
	# Count all quests not active or on cooldown
	for quest_id in all_quests:
		# Skip active quests
		if active_quests.has(quest_id):
			continue
		
		# Check cooldown for completed quests
		if completed_quests.has(quest_id):
			var completed_data = completed_quests[quest_id]
			var completion_time = completed_data.get("completion_time", 0)
			var cooldown_hours = completed_data.get("cooldown_hours", 0)
			
			# Skip if still on cooldown
			if not _is_cooldown_complete(completion_time, cooldown_hours):
				continue
		
		# Quest is eligible
		eligible_count += 1
	
	return eligible_count

# Refresh the list of available quests
func refresh_available_quests():
	print("QuestManager: Refresh Available quests")
	available_quests.clear()
	
	# Get all quests not active or on cooldown
	var eligible_quests = {}
	
	for quest_id in all_quests:
		# Skip active quests
		if active_quests.has(quest_id):
			continue
		
		# Check cooldown for completed quests
		if completed_quests.has(quest_id):
			var completed_data = completed_quests[quest_id]
			var completion_time = completed_data.get("completion_time", 0)
			var cooldown_hours = completed_data.get("cooldown_hours", 0)
			
			# Skip if still on cooldown
			if not _is_cooldown_complete(completion_time, cooldown_hours):
				continue
		
		# Quest is eligible
		eligible_quests[quest_id] = all_quests[quest_id]
	
	# If we have fewer eligible quests than our desired count, use all of them
	if eligible_quests.size() <= available_quest_count:
		available_quests = eligible_quests.duplicate()
	else:
		# Randomly select quests up to our desired count
		var eligible_ids = eligible_quests.keys()
		eligible_ids.shuffle()
		
		for i in range(available_quest_count):
			if i >= eligible_ids.size():
				break
			var quest_id = eligible_ids[i]
			available_quests[quest_id] = eligible_quests[quest_id]
	
	# Update refresh timestamp
	last_refresh_time = Time.get_unix_time_from_system()
	
	emit_signal("available_quests_refreshed")
	print("QuestManager: Refreshed available quests (%d/%d eligible)" % [available_quests.size(), eligible_quests.size()])
	
	_save_game_data()
	return available_quests.size()

# Check if a quest's cooldown period has completed
func _is_cooldown_complete(completion_time: int, cooldown_hours: int) -> bool:
	if cooldown_hours <= 0:
		return true
		
	var current_time = Time.get_unix_time_from_system()
	var cooldown_seconds = cooldown_hours * 3600
	
	return (current_time - completion_time) >= cooldown_seconds

# Reset cooldowns for all completed quests
func reset_all_cooldowns():
	# Remove all cooldowns from completed quests
	for quest_id in completed_quests.keys():
		# Just update the completion time to way in the past
		completed_quests[quest_id]["completion_time"] = 0
	
	print("QuestManager: Reset all quest cooldowns")
	
	# Refresh the available quests
	refresh_available_quests()
	
	return completed_quests.size()

# Add example quests for development
func add_example_quests():
	# Only add if we don't have any quests yet
	if not all_quests.is_empty():
		return
		
	print("QuestManager: Adding example quests")
	
	# Example 1: The Wardrobe's Whisper
	var quest1 = QuestResource.new()
	quest1.id = "wardrobe_whisper"
	quest1.title = "The Wardrobe's Whisper"
	quest1.description = "Tackle the task of sorting and organizing clothes."
	quest1.difficulty = QuestDifficulty.INTERMEDIATE
	quest1.category = "routine"
	quest1.xp_reward = 3
	quest1.cooldown_hours = 72  # 3 days
	quest1.icon_path = "res://assets/icons/quests/wardrobe.png"  # Will need to create this
	create_quest(quest1)
	
	# Example 2: The Spare Room Saga
	var quest2 = QuestResource.new()
	quest2.id = "spare_room_saga"
	quest2.title = "The Spare Room Saga"
	quest2.description = "Clean and organize your spare room or storage area."
	quest2.difficulty = QuestDifficulty.HARD
	quest2.category = "routine"
	quest2.xp_reward = 5
	quest2.cooldown_hours = 168  # 7 days
	quest2.icon_path = "res://assets/icons/quests/room.png"  # Will need to create this
	create_quest(quest2)
	
	# Example 3: Scholar's Journey
	var quest3 = QuestResource.new()
	quest3.id = "scholars_journey"
	quest3.title = "Scholar's Journey"
	quest3.description = "Spend 30 minutes learning something new."
	quest3.difficulty = QuestDifficulty.EASY
	quest3.category = "learning"
	quest3.xp_reward = 2
	quest3.cooldown_hours = 24  # 1 day
	quest3.icon_path = "res://assets/icons/quests/book.png"  # Will need to create this
	create_quest(quest3)
	
	# Example 4: Morning Expedition
	var quest4 = QuestResource.new()
	quest4.id = "morning_expedition"
	quest4.title = "Morning Expedition"
	quest4.description = "Take a 20-minute walk in the morning."
	quest4.difficulty = QuestDifficulty.EASY
	quest4.category = "physical"
	quest4.xp_reward = 2
	quest4.cooldown_hours = 24  # 1 day
	quest4.icon_path = "res://assets/icons/quests/walk.png"  # Will need to create this
	create_quest(quest4)
	
	# Example 5: Social Diplomat
	var quest5 = QuestResource.new()
	quest5.id = "social_diplomat"
	quest5.title = "Social Diplomat"
	quest5.description = "Reach out to a friend or family member you haven't spoken to in a while."
	quest5.difficulty = QuestDifficulty.INTERMEDIATE
	quest5.category = "social"
	quest5.xp_reward = 3
	quest5.cooldown_hours = 48  # 2 days
	quest5.icon_path = "res://assets/icons/quests/social.png"  # Will need to create this
	create_quest(quest5)
	
	# Make sure available quests are refreshed
	refresh_available_quests()

# Save all quest data
func _save_game_data():
	if not get_node_or_null("/root/DataManager"):
		push_error("QuestManager: DataManager not found, can't save quest data")
		return false
	
	# Save all quests
	var serialized_all_quests = {}
	for quest_id in all_quests:
		serialized_all_quests[quest_id] = all_quests[quest_id].to_dictionary()
	
	# Save active quests
	var serialized_active_quests = {}
	for quest_id in active_quests:
		serialized_active_quests[quest_id] = active_quests[quest_id].to_dictionary()
	
	# Save available quests
	var serialized_available_quests = {}
	for quest_id in available_quests:
		serialized_available_quests[quest_id] = available_quests[quest_id].to_dictionary()
	
	# Create save data structure
	var quest_save_data = {
		"all_quests": serialized_all_quests,
		"active_quests": serialized_active_quests,
		"available_quests": serialized_available_quests,
		"completed_quests": completed_quests,  # Already in dictionary form
		"failed_quests": failed_quests,  # Already in array form
		"last_refresh_time": last_refresh_time
	}
	
	# Save using DataManager
	var save_result = DataManager.save_data("quests.json", quest_save_data)
	
	if save_result:
		print("QuestManager: Quest data saved successfully")
	else:
		push_error("QuestManager: Failed to save quest data")
	
	return save_result

# Load all quest data
func _load_game_data():
	if not get_node_or_null("/root/DataManager"):
		push_error("QuestManager: DataManager not found, can't load quest data")
		return false
	
	# Load data using DataManager
	var quest_data = DataManager.load_data("quests.json")
	
	if not quest_data:
		print("QuestManager: No quest data found or failed to load")
		return false
	
	# Load all quests
	if quest_data.has("all_quests"):
		all_quests.clear()
		for quest_id in quest_data.all_quests:
			var quest = QuestResource.new(quest_data.all_quests[quest_id])
			all_quests[quest_id] = quest
	
	# Load active quests
	if quest_data.has("active_quests"):
		active_quests.clear()
		for quest_id in quest_data.active_quests:
			var quest = QuestResource.new(quest_data.active_quests[quest_id])
			active_quests[quest_id] = quest
	
	# Load available quests
	if quest_data.has("available_quests"):
		available_quests.clear()
		for quest_id in quest_data.available_quests:
			var quest = QuestResource.new(quest_data.available_quests[quest_id])
			available_quests[quest_id] = quest
	
	# Load completed quests (already in dictionary form)
	if quest_data.has("completed_quests"):
		completed_quests = quest_data.completed_quests
	
	# Load failed quests (already in array form)
	if quest_data.has("failed_quests"):
		failed_quests = quest_data.failed_quests
	
	# Load last refresh time
	if quest_data.has("last_refresh_time"):
		last_refresh_time = quest_data.last_refresh_time
	
	print("QuestManager: Quest data loaded successfully")
	print("QuestManager: All quests: %d, Active: %d, Available: %d, Completed: %d" % 
		[all_quests.size(), active_quests.size(), available_quests.size(), completed_quests.size()])
	
	return true
