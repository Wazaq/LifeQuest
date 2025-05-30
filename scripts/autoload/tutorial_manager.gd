extends Node

# TutorialManager - Autoload for managing tutorial state and flow
# Coordinates guided learning experience across all game scenes

signal tutorial_started
signal tutorial_step_completed(current_step: int, total_steps: int)
signal tutorial_completed

enum TutorialStep {
	NONE = -1,
	TAVERN_HUB_TUTORIAL = 0,
	QUEST_BOARD_TUTORIAL = 1,
	CHARACTER_PROFILE_TUTORIAL = 2,
	TUTORIAL_COMPLETE = 3
}

# Tutorial state
var tutorial_active: bool = false
var current_tutorial_step: TutorialStep = TutorialStep.NONE
var tutorial_completion_status: Dictionary = {}
var player_tutorial_preferences: Dictionary = {}

# Tutorial step definitions
var tutorial_steps = {
	TutorialStep.TAVERN_HUB_TUTORIAL: {
		"title": "Welcome to Your Tavern Hub!",
		"description": "Learn about your home base and navigation",
		"scene": "tavern_hub"
	},
	TutorialStep.QUEST_BOARD_TUTORIAL: {
		"title": "Quest Management",
		"description": "Discover how to find and complete quests",
		"scene": "quest_board"
	},
	TutorialStep.CHARACTER_PROFILE_TUTORIAL: {
		"title": "Character Progress",
		"description": "Track your growth and achievements",
		"scene": "character_profile"
	}
}

func _ready():
	print("TutorialManager initialized")
	_load_tutorial_data()

# Tutorial control functions
func start_tutorial():
	print("Starting tutorial system")
	tutorial_active = true
	current_tutorial_step = TutorialStep.TAVERN_HUB_TUTORIAL
	tutorial_started.emit()

func complete_tutorial_step():
	print("Completing tutorial step: ", current_tutorial_step)
	advance_to_next_tutorial_step()

func advance_to_next_tutorial_step():
	print("Advancing to next tutorial step from: ", current_tutorial_step)
	current_tutorial_step = (current_tutorial_step + 1) as TutorialStep
	
	tutorial_step_completed.emit(current_tutorial_step, get_total_tutorial_steps())
	
	if current_tutorial_step >= TutorialStep.TUTORIAL_COMPLETE:
		complete_tutorial()

func complete_tutorial():
	print("Tutorial completed!")
	tutorial_active = false
	current_tutorial_step = TutorialStep.NONE
	_save_tutorial_completion()
	tutorial_completed.emit()

func skip_tutorial():
	print("Tutorial skipped by user")
	tutorial_active = false
	current_tutorial_step = TutorialStep.NONE
	_save_tutorial_completion()

# Tutorial state queries
func is_tutorial_active() -> bool:
	return tutorial_active

func get_current_step() -> TutorialStep:
	return current_tutorial_step

func get_current_step_info() -> Dictionary:
	if current_tutorial_step in tutorial_steps:
		return tutorial_steps[current_tutorial_step]
	return {}

func get_total_tutorial_steps() -> int:
	return tutorial_steps.size()

func should_show_tutorial_overlay(scene_name: String) -> bool:
	if not tutorial_active:
		return false
	
	var step_info = get_current_step_info()
	if step_info.has("scene"):
		return step_info["scene"] == scene_name
	return false

# Tutorial completion tracking
func has_completed_tutorial() -> bool:
	return tutorial_completion_status.get("completed", false)

func _save_tutorial_completion():
	tutorial_completion_status["completed"] = true
	tutorial_completion_status["completion_date"] = Time.get_datetime_string_from_system()
	# Save through DataManager
	if DataManager:
		DataManager.save_tutorial_data(tutorial_completion_status)

func _load_tutorial_data():
	if DataManager:
		tutorial_completion_status = DataManager.load_tutorial_data()
