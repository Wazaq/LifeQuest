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
	"physiological",
	"safety", 
	"security",
	"love",
	"belonging",
	"esteem",
	"self_actualization"
]

# Quest states
enum QuestState {
	AVAILABLE,
	ACTIVE,
	COMPLETED,
	FAILED,
	EXPIRED
}

# Quest JSON Files
var quest_files = [
		"res://data/quests/physiological_quests.json",
		"res://data/quests/tutorial_quests.json"
	]

# Quest data - separated from quest library
var master_quest_list = {}  # All possible quests loaded from JSON files (library)
var player_quest_data = {}  # Player's quest state (active, completed, failed, etc.)

# Easy access to player quest sections
var active_quests = {}  # Reference to player_quest_data.active_quests
var completed_quests = {}  # Reference to player_quest_data.completed_quests
var failed_quests = {}  # Reference to player_quest_data.failed_quests
var available_quests = {}  # Dynamically calculated from library minus player state

# Tier unlocking system
var tier_unlock_requirements = {
	"physiological": {},  # Always unlocked
	"safety": {"physiological": 10},
	"security": {"physiological": 5, "safety": 10},
	"love": {"physiological": 5, "safety": 5, "security": 10},
	"belonging": {"physiological": 5, "safety": 5, "security": 5, "love": 10},
	"esteem": {"physiological": 5, "safety": 5, "security": 5, "love": 5, "belonging": 10},
	"self_actualization": {"physiological": 5, "safety": 5, "security": 5, "love": 5, "belonging": 5, "esteem": 10}
}

# Quest configuration
var max_active_quests = 10  # Maximum number of active quests allowed
var available_quest_count = 20  # Number of quests available at once
var last_refresh_time = 0  # Unix timestamp of last quest refresh

signal quest_created(quest)
signal quest_started(quest_id)
signal quest_progressed(quest_id, progress, max_steps)
signal quest_completed(quest_id, rewards)
signal quest_failed(quest_id)
signal quest_expired(quest_id)
signal available_quests_refreshed

func debug_reset_dictionaries():
	active_quests.clear()
	available_quests.clear()
	completed_quests.clear()
	failed_quests.clear()
	

func _ready():	
	print("QuestManager: Initializing quest system...")
	
	# Load quest library from JSON files (quest definitions)
	call_deferred("load_quest_library")
	
	# Load player quest data (active, completed, failed states)
	call_deferred("load_player_quest_data")
	
	# Set up a timer to check for quest expirations
	var timer = Timer.new()
	timer.wait_time = 3600  # Check every hour
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_check_quest_expirations"))
	add_child(timer)

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
	
	# Store in master_quest_list dictionary
	master_quest_list[quest.id] = quest
	
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
	var category = quest.category
	var completion_counts = player_quest_data.get("completion_counts", {})
	completion_counts[category] = completion_counts.get(category, 0) + 1
	player_quest_data["completion_counts"] = completion_counts
	
	# Check if new tiers should unlock
	check_tier_unlocks()
	
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

# Check if new tiers should unlock based on completion counts
func check_tier_unlocks():
	var completion_counts = player_quest_data.get("completion_counts", {})
	var unlocked_categories = player_quest_data.get("unlocked_categories", ["physiological", "tutorial"])
	var newly_unlocked = []
	
	# Check each tier to see if it should be unlocked
	for tier in tier_unlock_requirements:
		# Skip if already unlocked
		if tier in unlocked_categories:
			continue
		
		var requirements = tier_unlock_requirements[tier]
		var tier_unlocked = true
		
		# Check if all requirements are met
		for required_category in requirements:
			var required_count = requirements[required_category]
			var current_count = completion_counts.get(required_category, 0)
			
			if current_count < required_count:
				tier_unlocked = false
				break
		
		# If all requirements met, unlock this tier
		if tier_unlocked:
			unlocked_categories.append(tier)
			newly_unlocked.append(tier)
			print("QuestManager: Unlocked new tier - %s!" % tier)
	
	# Update player data if any new tiers were unlocked
	if newly_unlocked.size() > 0:
		player_quest_data["unlocked_categories"] = unlocked_categories
		print("QuestManager: Total unlocked categories: %s" % str(unlocked_categories))
		
		# Refresh available quests to include new tier quests
		call_deferred("merge_new_quests_and_refresh")
	
	return newly_unlocked

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
	failed_quests[quest_id] = failed_data
	
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

# Check the Quests cooldown
func check_quest_cooldown(quest_id: String) -> bool:
	# Check completed quests (full cooldown)
	if completed_quests.has(quest_id):
		var data = completed_quests[quest_id]
		return _is_cooldown_complete(data.get("completion_time", 0), data.get("cooldown_hours", 0))
	
	# Check failed quests (half cooldown)
	if failed_quests.has(quest_id):
		var data = failed_quests[quest_id]
		return _is_cooldown_complete(data.get("failure_time", 0), data.get("cooldown_hours", 0) / 2)
	
	return true # Avaialable
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

func get_available_quest_count() -> int:
	var eligible_count = 0
	var unlocked_categories = player_quest_data.get("unlocked_categories", ["physiological", "tutorial"])
	
	# Count all quests not active or on cooldown
	for quest_id in master_quest_list:
		var quest = master_quest_list[quest_id]
		
		# Skip if quest category not unlocked yet
		if not quest.category in unlocked_categories:
			continue
		
		# Skip active quests
		if active_quests.has(quest_id):
			continue
			
		# Skip failed quests on cooldown
		if failed_quests.has(quest_id):
			var failure_data = failed_quests[quest_id]
			var completion_time = failure_data.get("failure_time", 0)
			var cooldown_hours = failure_data.get("cooldown_hours", 0)
			
			# Skip if still on cooldown
			if not _is_cooldown_complete(completion_time, cooldown_hours):
				continue
		
		# Check cooldown for completed quests
		if completed_quests.has(quest_id):
			var completed_data = completed_quests[quest_id]
			var completion_time = completed_data.get("completion_time", 0)
			var cooldown_hours = completed_data.get("cooldown_hours", 0)
			
			# Skip if still on cooldown
			if not _is_cooldown_complete(completion_time, cooldown_hours):
				continue
			
			# Skip if non-repeatable and already completed
			if not quest.repeatable:
				continue
		
		# Quest is eligible
		eligible_count += 1
	
	return eligible_count

# Refresh the list of available quests
func refresh_available_quests():
	print("QuestManager: Refresh Available quests")
	available_quests.clear()
	
	# Get unlocked categories
	var unlocked_categories = player_quest_data.get("unlocked_categories", ["physiological", "tutorial"])
	
	# Get all quests not active or on cooldown
	var eligible_quests = {}
	
	for quest_id in master_quest_list:
		var quest = master_quest_list[quest_id]
		
		# Skip if quest category not unlocked yet
		if not quest.category in unlocked_categories:
			continue
		
		# Skip active quests
		if active_quests.has(quest_id):
			continue
			
		if failed_quests.has(quest_id):
			var failure_data = failed_quests[quest_id]
			var completion_time = failure_data.get("failure_time", 0)
			var cooldown_hours = failure_data.get("cooldown_hours", 0)
			
			# Skip if still on cooldown
			if not _is_cooldown_complete(completion_time, cooldown_hours):
				continue
		
		# Check cooldown for completed quests
		if completed_quests.has(quest_id):
			var completed_data = completed_quests[quest_id]
			var completion_time = completed_data.get("completion_time", 0)
			var cooldown_hours = completed_data.get("cooldown_hours", 0)
			
			# Skip if still on cooldown
			if not _is_cooldown_complete(completion_time, cooldown_hours):
				continue
			
			# Skip if non-repeatable and already completed
			if not quest.repeatable:
				continue
		
		# Quest is eligible
		eligible_quests[quest_id] = quest
	
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

# Load quest library from JSON files (quest definitions only)
func load_quest_library():
	print("QuestManager: Loading quest library from JSON files")
	
	# Clear and reload quest library (but don't touch player state)
	master_quest_list.clear()
	
	var total_loaded = 0
	
	# Load each quest file, This is set up top in the header area
	for file_path in quest_files:
		var loaded_count = _load_quest_file(file_path)
		total_loaded += loaded_count
	
	print("QuestManager: Loaded %d total quest definitions from %d files" % [total_loaded, quest_files.size()])

# Load player quest data (states, not definitions)
func load_player_quest_data():
	print("QuestManager: Loading player quest data")
	
	# Load player quest data from DataManager
	player_quest_data = DataManager.load_player_quest_data()
	
	# Set up references for easy access
	active_quests = player_quest_data.get("active_quests", {})
	completed_quests = player_quest_data.get("completed_quests", {})
	failed_quests = player_quest_data.get("failed_quests", {})
	
	# Convert dictionary data back to QuestResource objects for active quests
	for quest_id in active_quests:
		if typeof(active_quests[quest_id]) == TYPE_DICTIONARY:
			var quest = QuestResource.new()
			quest.from_dictionary(active_quests[quest_id])
			active_quests[quest_id] = quest
	
	print("QuestManager: Loaded player quest data - Active: %d, Completed: %d, Failed: %d" % 
		[active_quests.size(), completed_quests.size(), failed_quests.size()])
	
	# After both library and player data are loaded, merge new quests and refresh available
	call_deferred("merge_new_quests_and_refresh")

# Merge new quests from library into player's available pool
func merge_new_quests_and_refresh():
	print("QuestManager: Merging new quests from library")
	
	var new_quests_added = 0
	var unlocked_categories = player_quest_data.get("unlocked_categories", ["physiological", "tutorial"])
	
	# Find quests in library that player doesn't have yet
	for quest_id in master_quest_list:
		var quest = master_quest_list[quest_id]
		
		# Skip if quest category not unlocked yet
		if not quest.category in unlocked_categories:
			continue
		
		# Skip if player already has this quest in any state
		if quest_id in active_quests or quest_id in completed_quests or quest_id in failed_quests:
			continue
		
		# This is a new quest for the player - add to their data
		# Note: We don't add it directly to available_quests since that's calculated dynamically
		new_quests_added += 1
		print("QuestManager: Found new quest available for player - %s" % quest.title)
	
	print("QuestManager: %d new quests available for player" % new_quests_added)
	
	# Refresh available quests based on current state
	refresh_available_quests()

# Load a single quest file
func _load_quest_file(file_path: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("QuestManager: Could not open %s" % file_path)
		return 0
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("QuestManager: Failed to parse %s" % file_path)
		return 0
	
	var quest_data = json.data
	var loaded_count = 0
	
	# Create quest resources from JSON data
	for quest_id in quest_data:
		var quest_info = quest_data[quest_id]
		
		# Check if quest is non-repeatable and already completed
		var is_repeatable = quest_info.get("repeatable", true)
		if not is_repeatable and completed_quests.has(quest_id):
			print("QuestManager: Skipping non-repeatable completed quest - %s" % quest_info.get("title", quest_id))
			continue
		
		# Create quest resource using from_dictionary method
		var quest = QuestResource.new()
		quest.from_dictionary(quest_info)
		
		# Set deadline based on duration_hours if specified
		if quest_info.has("duration_hours") and quest_info.get("duration_hours", 0) > 0:
			var duration_hours = quest_info.get("duration_hours", 24)
			quest.set_deadline_hours(duration_hours)
		
		# Add to master quest list
		master_quest_list[quest.id] = quest
		loaded_count += 1
		#print("QuestManager: Loaded quest - %s" % quest.title)
	
	print("QuestManager: Loaded %d quests from %s" % [loaded_count, file_path])
	return loaded_count



# Save player quest data using new structure
func _save_game_data():
	print("QuestManager: Saving player quest data")
	if not get_node_or_null("/root/DataManager"):
		push_error("QuestManager: DataManager not found, can't save quest data")
		return false
	
	# Serialize active quests to dictionary form
	var serialized_active_quests = {}
	for quest_id in active_quests:
		serialized_active_quests[quest_id] = active_quests[quest_id].to_dictionary()
	
	# Update player quest data structure
	player_quest_data["last_refresh_time"] = last_refresh_time
	player_quest_data["active_quests"] = serialized_active_quests
	player_quest_data["completed_quests"] = completed_quests
	player_quest_data["failed_quests"] = failed_quests
	# Note: available_quests is calculated dynamically, not saved
	
	# Save using DataManager
	var save_result = DataManager.save_player_quest_data(player_quest_data)
	
	if save_result:
		print("QuestManager: Player quest data saved successfully")
	else:
		push_error("QuestManager: Failed to save player quest data")
	
	return save_result
