extends Node
## GameManager: Central coordinator for game state and core functionality

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
