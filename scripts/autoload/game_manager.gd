extends Node
## GameManager: Central coordinator for game state and core functionality

# Debug config
enum DebugCategory {
	QUEST_SYSTEM,
	GAME_STATE,
	UI_TESTING,
}
# Feature flag configurations
var enabled_features = {
	"quest_system": true,
	"character_profile": true,
	"notifications": true,
	"tutorials": true,
	"achievements": true,
	"adventures": false,    # For bottom nav visibility
	"social_features": false,  # Planned for future
	"daily_passes": false,     # Later MVP
	"user_auth": false         # Later MVP
}

# Game state
var is_initialized: bool = false
var current_scene: String = ""
var app_version: String = "0.1.0"

signal feature_enabled(feature_name)
signal feature_disabled(feature_name)
signal game_initialized
signal scene_changed(old_scene, new_scene)

func is_debug_enabled(_category: DebugCategory = DebugCategory.QUEST_SYSTEM) -> bool:
	# For now, single flag controls everything
	return true
	#return false
	
	# Future expansion could look like:
	# match category:
	#     DebugCategory.QUEST_SYSTEM: return quest_debug_enabled
	#     DebugCategory.GAME_STATE: return game_state_debug_enabled
	#     # etc.

func _ready():
	print("GameManager: Initializing game systems...")
	call_deferred("initialize_game")

func initialize_game():
	# Here we'll initialize all required subsystems
	# This will be expanded as we implement those systems
	is_initialized = true
	print("GameManager: Game initialized successfully")
	emit_signal("game_initialized")

func is_feature_enabled(feature_name: String) -> bool:
	if feature_name in enabled_features:
		return enabled_features[feature_name]
	return false

func enable_feature(feature_name: String):
	if feature_name in enabled_features and not enabled_features[feature_name]:
		enabled_features[feature_name] = true
		emit_signal("feature_enabled", feature_name)
		print("GameManager: Feature enabled - %s" % feature_name)

func disable_feature(feature_name: String):
	if feature_name in enabled_features and enabled_features[feature_name]:
		enabled_features[feature_name] = false
		emit_signal("feature_disabled", feature_name)
		print("GameManager: Feature disabled - %s" % feature_name)

func change_scene(scene_path: String):
	var old_scene = current_scene
	current_scene = scene_path
	get_tree().change_scene_to_file(scene_path)
	emit_signal("scene_changed", old_scene, current_scene)
	print("GameManager: Changed scene from %s to %s" % [old_scene, current_scene])
	
# Name collections
var male_names = [
	"Alaric", "Bram", "Cedric", "Darian", "Elric", "Finn", "Gareth", 
	"Hadrian", "Ivan", "Jasper", "Kell", "Leif", "Magnus", "Nolan",
	"Orion", "Percy", "Quentin", "Rowan", "Silas", "Thorne", "Ulric",
	"Vaughn", "Wren", "Xavier", "Yorath", "Zephyr"
]

var female_names = [
	"Aria", "Brielle", "Cora", "Dahlia", "Elara", "Freya", "Gwendolyn",
	"Harlow", "Iris", "Juniper", "Kira", "Luna", "Maeve", "Nova",
	"Ophelia", "Piper", "Quinn", "Rhiannon", "Sage", "Thea", "Uma",
	"Violet", "Willow", "Xanthe", "Yara", "Zora"
]

var neutral_names = [
	"Ash", "Avery", "Blair", "Cameron", "Dakota", "Eden", "Finley",
	"Gray", "Harper", "Jordan", "Kai", "Logan", "Morgan", "Nico",
	"Oak", "Parker", "Quinn", "Reese", "Sage", "Taylor", "Unity",
	"Val", "Winter", "Xen", "Yael", "Zen"
]

enum NameCategory {
	MALE,
	FEMALE,
	NEUTRAL,
	ANY  # For completely random selection across all categories
}

# Function to get a random name
func get_random_name(category: int = NameCategory.ANY) -> String:
	var chosen_list
	
	match category:
		NameCategory.MALE:
			chosen_list = male_names
		NameCategory.FEMALE:
			chosen_list = female_names
		NameCategory.NEUTRAL:
			chosen_list = neutral_names
		NameCategory.ANY:
			# Pick a random category first
			var all_lists = [male_names, female_names, neutral_names]
			chosen_list = all_lists[randi() % all_lists.size()]
	
	# Return a random name from the chosen list
	return chosen_list[randi() % chosen_list.size()]

# Function to get all names in a category (for custom selection UI if needed later)
func get_all_names(category: int) -> Array:
	match category:
		NameCategory.MALE:
			return male_names.duplicate()
		NameCategory.FEMALE:
			return female_names.duplicate()
		NameCategory.NEUTRAL:
			return neutral_names.duplicate()
		NameCategory.ANY:
			var all_names = []
			all_names.append_array(male_names)
			all_names.append_array(female_names)
			all_names.append_array(neutral_names)
			return all_names
	
	return []
