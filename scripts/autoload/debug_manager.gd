extends Node
## DebugManager: Centralized debug functionality for development
## Contains all debug-only features to keep production code clean

signal debug_action_completed(action_name: String)

# Debug shortcuts for efficient testing
func start_tutorial_directly():
	"""Skip character creation and jump straight to tutorial"""
	print("DebugManager: Starting tutorial directly")
	
	# Create a test character
	var test_character = CharacterResource.new()
	test_character.name = "Debug Hero"
	test_character.level = 1
	test_character.xp = 0
	test_character.streak = 0
	
	# Save the character
	ProfileManager.current_character = test_character
	if DataManager:
		DataManager.save_character(test_character)
	
	# Start tutorial
	if TutorialManager:
		TutorialManager.start_tutorial()
	
	# Navigate to tavern hub with tutorial active
	if UIManager:
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.has_method("_navigate_to"):
			main_node._navigate_to(main_node.ScreenState.TAVERN_HUB)
	
	debug_action_completed.emit("start_tutorial_directly")

func jump_to_quest_board_tutorial():
	"""Jump directly to quest board tutorial step"""
	print("DebugManager: Jumping to quest board tutorial")
	
	# Ensure we have a character
	_ensure_test_character()
	
	# Set tutorial to quest board step
	if TutorialManager:
		TutorialManager.tutorial_active = true
		TutorialManager.current_tutorial_step = TutorialManager.TutorialStep.QUEST_BOARD_TUTORIAL
	
	# Navigate to quest board
	if UIManager:
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.has_method("_navigate_to"):
			main_node._navigate_to(main_node.ScreenState.QUEST_BOARD)
	
	debug_action_completed.emit("jump_to_quest_board_tutorial")

func jump_to_character_profile_tutorial():
	"""Jump directly to character profile tutorial step"""
	print("DebugManager: Jumping to character profile tutorial")
	
	# Ensure we have a character
	_ensure_test_character()
	
	# Set tutorial to character profile step
	if TutorialManager:
		TutorialManager.tutorial_active = true
		TutorialManager.current_tutorial_step = TutorialManager.TutorialStep.CHARACTER_PROFILE_TUTORIAL
	
	# Navigate to character profile
	if UIManager:
		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.has_method("_navigate_to"):
			main_node._navigate_to(main_node.ScreenState.CHARACTER_PROFILE)
	
	debug_action_completed.emit("jump_to_character_profile_tutorial")

func reset_tutorial_only():
	"""Reset just tutorial completion without wiping character/quest data"""
	print("DebugManager: Resetting tutorial state only")
	
	if TutorialManager:
		TutorialManager.tutorial_active = false
		TutorialManager.current_tutorial_step = TutorialManager.TutorialStep.NONE
		TutorialManager.tutorial_completion_status.clear()
	
	# Remove tutorial data file
	if DataManager:
		var tutorial_file = "user://tutorial_data.save"
		if FileAccess.file_exists(tutorial_file):
			var dir = DirAccess.open("user://")
			if dir:
				dir.remove("tutorial_data.save")
	
	if UIManager:
		UIManager.show_toast("Tutorial state reset!", "success")
	
	debug_action_completed.emit("reset_tutorial_only")

func add_test_quests():
	"""Add some test quests for debugging quest system"""
	print("DebugManager: Adding test quests")
	
	# Ensure we have a character
	_ensure_test_character()
	
	if QuestManager:
		# Clear existing quests first
		QuestManager.active_quests.clear()
		
		# Add a variety of test quests
		var test_quests = [
			{
				"title": "Debug Quest: Easy Task",
				"description": "A simple test quest for debugging",
				"difficulty": QuestManager.QuestDifficulty.EASY,
				"xp_reward": 50,
				"category": "Testing"
			},
			{
				"title": "Debug Quest: Medium Challenge", 
				"description": "A medium difficulty test quest",
				"difficulty": QuestManager.QuestDifficulty.INTERMEDIATE,
				"xp_reward": 100,
				"category": "Testing"
			}
		]
		
		for quest_data in test_quests:
			var quest = QuestResource.new()
			quest.id = "debug_" + str(randi())
			quest.title = quest_data.title
			quest.description = quest_data.description
			quest.difficulty = quest_data.difficulty
			quest.xp_reward = quest_data.xp_reward
			quest.category = quest_data.category
			quest.deadline = Time.get_unix_time_from_system() + (24 * 60 * 60) # 24 hours
			
			QuestManager.active_quests[quest.id] = quest
		
		# Save the quests
		if DataManager:
			DataManager.save_active_quests(QuestManager.active_quests)
	
	if UIManager:
		UIManager.show_toast("Test quests added!", "success")
	
	debug_action_completed.emit("add_test_quests")

func clear_quest_data():
	"""Clear all saved quest data to force fresh JSON loading"""
	print("DebugManager: Clearing all quest data")
	
	if QuestManager:
		# Clear all quest dictionaries
		#QuestManager.all_quests.clear()
		QuestManager.active_quests.clear()
		QuestManager.available_quests.clear()
		QuestManager.completed_quests.clear()
		QuestManager.failed_quests.clear()
		
		# Remove the saved quests file
		if DataManager:
			var quest_file = "user://quests.json"
			if FileAccess.file_exists(quest_file):
				var dir = DirAccess.open("user://")
				if dir:
					dir.remove("quests.json")
					print("DebugManager: Deleted saved quest data file")
		
		# Force reload of JSON quests
		QuestManager.load_quest_files()
	
	if UIManager:
		UIManager.show_toast("Quest data cleared - JSON quests loaded!", "success")
	
	debug_action_completed.emit("clear_quest_data")

func show_debug_options():
	"""Show debug options dialog or panel"""
	print("DebugManager: Showing debug options")
	
	# For now, we'll just show a simple confirmation for each action
	# Later this could be expanded to a proper debug panel UI
	if UIManager:
		UIManager.show_toast("Debug Manager Active - Check More screen for options", "info")

# Helper functions
func _ensure_test_character():
	"""Make sure we have a character for testing"""
	if not ProfileManager.current_character:
		var test_character = CharacterResource.new()
		test_character.name = "Debug Hero"
		test_character.level = 1
		test_character.experience = 0
		test_character.streak = 0
		
		ProfileManager.current_character = test_character
		if DataManager:
			DataManager.save_character(test_character)

func get_debug_info() -> Dictionary:
	"""Return current debug state information"""
	var info = {}
	
	if TutorialManager:
		info["tutorial_active"] = TutorialManager.tutorial_active
		info["tutorial_step"] = TutorialManager.current_tutorial_step
		info["tutorial_completed"] = TutorialManager.has_completed_tutorial()
	
	if ProfileManager and ProfileManager.current_character:
		info["has_character"] = true
		info["character_name"] = ProfileManager.current_character.name
	else:
		info["has_character"] = false
	
	if QuestManager:
		info["active_quests"] = QuestManager.active_quests.size()
	
	return info

func _ready():
	print("DebugManager: Debug tools loaded")
