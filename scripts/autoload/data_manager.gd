extends Node
## DataManager: Handles saving and loading of game data

# Data file paths
const SAVE_DIR = "user://lifequest/"
const PLAYER_GAME_DATA_FILE = "player_game_data.json"
const PLAYER_QUEST_DATA_FILE = "player_quest_data.json"
const PLAYER_TUTORIAL_DATA_FILE = "player_tutorial_data.json"
const SETTINGS_SAVE_FILE = "settings.json"

# Legacy file names (for migration/cleanup)
const LEGACY_CHARACTER_FILE = "character.json"
const LEGACY_QUESTS_FILE = "quests.json"
const LEGACY_TUTORIAL_FILE = "tutorial_state.json"

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
	
	var result = save_data(PLAYER_GAME_DATA_FILE, character_dict)
	return result

# Load character data
func load_character():
	var character_dict = load_data(PLAYER_GAME_DATA_FILE)
	if not character_dict:
		print("DataManager: No character data found, creating new")
		return null
	
	var CharacterResourceClass = load("res://scripts/resources/character_resource.gd")
	var character = CharacterResourceClass.new(character_dict)
	return character

# Save player quest data (active, completed, failed, unlocked categories, completion counts)
func save_player_quest_data(quest_data):
	var result = save_data(PLAYER_QUEST_DATA_FILE, quest_data)
	return result

# Load player quest data
func load_player_quest_data():
	var quest_data = load_data(PLAYER_QUEST_DATA_FILE)
	if not quest_data:
		print("DataManager: No player quest data found, creating new structure")
		# Return default structure
		return {
			"unlocked_categories": ["physiological", "tutorial"],
			"completion_counts": {},
			"total_completions": 0,
			"last_refresh_time": 0,
			"active_quests": {},
			"completed_quests": {},
			"failed_quests": {}
		}
	
	return quest_data

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
	return FileAccess.file_exists(SAVE_DIR + PLAYER_GAME_DATA_FILE)

# Save tutorial completion data
func save_tutorial_data(tutorial_data):
	var result = save_data(PLAYER_TUTORIAL_DATA_FILE, tutorial_data)
	return result

# Load tutorial completion data
func load_tutorial_data():
	var tutorial_data = load_data(PLAYER_TUTORIAL_DATA_FILE)
	if not tutorial_data:
		print("DataManager: No tutorial data found")
		return {}
	
	return tutorial_data

# Save all game data at once
func save_all_game_data(character_data, quest_data, tutorial_data, settings):
	var success = true
	
	success = success && save_character(character_data)
	success = success && save_player_quest_data(quest_data)
	success = success && save_tutorial_data(tutorial_data)
	success = success && save_settings(settings)
	
	return success
