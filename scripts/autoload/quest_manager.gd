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

# Active quests dictionary - quest_id: QuestResource
var active_quests = {}
# Completed quests array
var completed_quests = []
# Failed quests array
var failed_quests = []

signal quest_created(quest)
signal quest_started(quest_id)
signal quest_progressed(quest_id, progress, max_steps)
signal quest_completed(quest_id, rewards)
signal quest_failed(quest_id)
signal quest_expired(quest_id)

func _ready():
	print("QuestManager: Initializing quest system...")

# Create a new quest
func create_quest(quest_data):
	# We'll implement this when we have our QuestResource
	# This will instantiate a QuestResource from quest_data
	pass

# Start a quest
func start_quest(quest_id):
	if quest_id in active_quests:
		print("QuestManager: Quest already active - %s" % quest_id)
		return false
	
	# Here we'll load the quest from available quests
	# and move it to active_quests
	# For now, just a placeholder
	active_quests[quest_id] = null  # This will be a QuestResource
	emit_signal("quest_started", quest_id)
	print("QuestManager: Started quest - %s" % quest_id)
	return true

# Update progress on a multi-step quest
func update_quest_progress(quest_id, progress):
	if not quest_id in active_quests:
		print("QuestManager: Cannot update progress on inactive quest - %s" % quest_id)
		return false
	
	var quest = active_quests[quest_id]
	# We'll update the quest's progress here
	# For now, just emit the signal
	emit_signal("quest_progressed", quest_id, progress, 100) # Placeholder max_steps
	print("QuestManager: Updated quest progress - %s (%d)" % [quest_id, progress])
	return true

# Complete a quest
func complete_quest(quest_id):
	if not quest_id in active_quests:
		print("QuestManager: Cannot complete inactive quest - %s" % quest_id)
		return false
	
	var quest = active_quests[quest_id]
	# Calculate rewards
	var rewards = {
		"xp": 100,  # This will be calculated based on quest difficulty
		"items": []  # Future: quest rewards
	}
	
	completed_quests.append(quest)
	active_quests.erase(quest_id)
	
	emit_signal("quest_completed", quest_id, rewards)
	print("QuestManager: Completed quest - %s" % quest_id)
	return rewards

# Fail a quest
func fail_quest(quest_id):
	if not quest_id in active_quests:
		print("QuestManager: Cannot fail inactive quest - %s" % quest_id)
		return false
	
	var quest = active_quests[quest_id]
	failed_quests.append(quest)
	active_quests.erase(quest_id)
	
	emit_signal("quest_failed", quest_id)
	print("QuestManager: Failed quest - %s" % quest_id)
	return true

# Check if a quest is expired based on its deadline
func check_quest_expiration(quest_id):
	if not quest_id in active_quests:
		return false
	
	var quest = active_quests[quest_id]
	# We'll check if the quest's deadline has passed
	# For now, just a placeholder
	var is_expired = false
	
	if is_expired:
		active_quests.erase(quest_id)
		emit_signal("quest_expired", quest_id)
		print("QuestManager: Quest expired - %s" % quest_id)
		return true
	
	return false

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
