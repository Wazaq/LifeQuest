extends Node
## DataManager: Handles saving and loading of game data

# Data file paths
const SAVE_DIR = "user://lifequest/"
const CHARACTER_SAVE_FILE = "character.json"
const ACTIVE_QUESTS_SAVE_FILE = "active_quests.json"
const COMPLETED_QUESTS_SAVE_FILE = "completed_quests.json"
const SETTINGS_SAVE_FILE = "settings.json"
const TUTORIAL_SAVE_FILE = "tutorial.json"

# Signals
signal data_saved(file_name)
signal data_loaded(file_name)
signal save_error(error_message)
signal load_error(error_message)

func _ready():
	print("DataManager: Initializing data management system...")
	# Ensure save directory exists
	ensure_save_directory()

# Make sure our save directory exists
func ensure_save_directory():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_DIR.trim_suffix("/")):
		dir.make_dir_recursive(SAVE_DIR.trim_suffix("/"))
		print("DataManager: Created save directory")

# Generic function to save any data to a JSON file
func save_data(file_name, data):
	var file_path = SAVE_DIR + file_name
	
	# Create a file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		push_error("DataManager: Failed to save data to %s, error: %s" % [file_path, error])
		emit_signal("save_error", "Failed to save %s: %s" % [file_name, error])
		return false
	
	# Convert to JSON and save
	var json_string = JSON.stringify(data, "  ")
	file.store_string(json_string)
	file.close()
	
	print("DataManager: Successfully saved %s" % file_name)
	emit_signal("data_saved", file_name)
	return true

# Generic function to load any data from a JSON file
func load_data(file_name):
	var file_path = SAVE_DIR + file_name
	
	# Check if file exists
	if not FileAccess.file_exists(file_path):
		print("DataManager: File does not exist: %s" % file_path)
		return null
	
	# Open file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var file_open_error = FileAccess.get_open_error()
		push_error("DataManager: Failed to open %s, error: %s" % [file_path, file_open_error])
		emit_signal("load_error", "Failed to load %s: %s" % [file_name, file_open_error])
		return null
	
	# Read file content
	var json_string = file.get_as_text()
	file.close()
	
	# Parse JSON
	var json = JSON.new()
	var pase_json_error = json.parse(json_string)
	if pase_json_error != OK:
		push_error("DataManager: JSON Parse Error: %s in %s at line %s" % [json.get_error_message(), file_name, json.get_error_line()])
		emit_signal("load_error", "Failed to parse %s: %s" % [file_name, json.get_error_message()])
		return null
	
	var data = json.get_data()
	print("DataManager: Successfully loaded %s" % file_name)
	emit_signal("data_loaded", file_name)
	return data

# Save character data
func save_character(character_data):
	var character_dict = {}
	
	# Convert from CharacterResource if needed
	if character_data is Resource:
		character_dict = character_data.to_dictionary()
	else:
		character_dict = character_data
	
	var result = save_data(CHARACTER_SAVE_FILE, character_dict)
	return result

# Load character data
func load_character():
	var character_dict = load_data(CHARACTER_SAVE_FILE)
	if not character_dict:
		print("DataManager: No character data found, creating new")
		return null
	
	var CharacterResourceClass = load("res://scripts/resources/character_resource.gd")
	var character = CharacterResourceClass.new(character_dict)
	return character

# Save active quests
func save_active_quests(quests_data):
	var quests_dict = {}
	
	# Convert dictionary of QuestResource objects to serializable form
	if quests_data is Dictionary:
		for key in quests_data:
			var quest = quests_data[key]
			if quest is Resource:
				quests_dict[key] = quest.to_dictionary()
			else:
				quests_dict[key] = quest
	else:
		quests_dict = quests_data
	
	var result = save_data(ACTIVE_QUESTS_SAVE_FILE, quests_dict)
	return result

# Load active quests
func load_active_quests():
	var quests_dict = load_data(ACTIVE_QUESTS_SAVE_FILE)
	if not quests_dict:
		print("DataManager: No active quests found")
		return {}
	
	# Convert serialized quests back to QuestResource objects
	var QuestResourceClass = load("res://scripts/resources/quest_resource.gd")
	var quests = {}
	for key in quests_dict:
		quests[key] = QuestResourceClass.new(quests_dict[key])
	
	return quests

# Save completed quests
func save_completed_quests(quests_data):
	var quests_array = []
	
	# Convert array of QuestResource objects to serializable form
	if quests_data is Array:
		for quest in quests_data:
			if quest is Resource:
				quests_array.append(quest.to_dictionary())
			else:
				quests_array.append(quest)
	else:
		quests_array = quests_data
	
	var result = save_data(COMPLETED_QUESTS_SAVE_FILE, quests_array)
	return result

# Load completed quests
func load_completed_quests():
	var quests_array = load_data(COMPLETED_QUESTS_SAVE_FILE)
	if not quests_array:
		print("DataManager: No completed quests found")
		return []
	
	# Convert serialized quests back to QuestResource objects
	var QuestResourceClass = load("res://scripts/resources/quest_resource.gd")
	var quests = []
	for quest_dict in quests_array:
		quests.append(QuestResourceClass.new(quest_dict))
	
	return quests

# Save app settings
func save_settings(settings_data):
	var result = save_data(SETTINGS_SAVE_FILE, settings_data)
	return result

# Load app settings
func load_settings():
	var settings = load_data(SETTINGS_SAVE_FILE)
	if not settings:
		print("DataManager: No settings found, using defaults")
		return {}
	
	return settings

# Delete save file
func delete_save_file(file_name):
	var file_path = SAVE_DIR + file_name
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			var err = dir.remove(file_name)
			if err != OK:
				push_error("DataManager: Failed to delete %s, error: %s" % [file_path, err])
				return false
			
			print("DataManager: Successfully deleted %s" % file_name)
			return true
	
	return false

# Check if save data exists for a character
func has_character_save():
	return FileAccess.file_exists(SAVE_DIR + CHARACTER_SAVE_FILE)

# Save tutorial completion data
func save_tutorial_data(tutorial_data):
	var result = save_data(TUTORIAL_SAVE_FILE, tutorial_data)
	return result

# Load tutorial completion data
func load_tutorial_data():
	var tutorial_data = load_data(TUTORIAL_SAVE_FILE)
	if not tutorial_data:
		print("DataManager: No tutorial data found")
		return {}
	
	return tutorial_data

# Save all game data at once
func save_all_game_data(character_data, active_quests, completed_quests, settings):
	var success = true
	
	success = success && save_character(character_data)
	success = success && save_active_quests(active_quests)
	success = success && save_completed_quests(completed_quests)
	success = success && save_settings(settings)
	
	return success
