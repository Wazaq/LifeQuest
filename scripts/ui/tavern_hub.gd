extends Control

# Node References
@onready var tavern_keeper: TextureRect = $TavernKeeperContainer/TavernKeeper

func _ready() -> void:
	print("TavernHub: Ready")
	_setup_ui()
	_setup_tavern_keeper()
	_update_welcome_message()
	pass

func _setup_ui():
	# Since we removed the welcome panel, we mainly need to ensure
	# the scene layout works well on mobile
	# Any additional UI setup can go here in the future
	pass

func _setup_tavern_keeper():
	# Connect tavern keeper interaction
	print("TavernHub: Setting up tavern keeper interaction")
	
	#Connect the Tavern Keeper signal for the Keeper clicks
	if tavern_keeper:
		tavern_keeper.gui_input.connect(_on_tavern_keeper_clicked)
		print("TavernHub: Connected to tavern keeper TextureRect")
		
		# Make sure the TextureRect can receive input
		#tavern_keeper.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		print("TavernHub: ERROR - Tavern keeper not found")

# Array of generic friendly responses from Dorin
var keeper_responses = [
	"Ah, %s! How goes your adventures today?",
	"Hello there, %s! Have you checked on your quests lately?",
	"%s, my friend! The tavern feels livelier with you here.",
	"Good to see you, %s! Any exciting tales from your recent quests?",
	"Welcome back, %s! The fire's warm and the quests are plenty.",
	"Hail and well met, %s! Ready for another day of adventure?",
	"%s! You're becoming quite the regular. I like that!",
	"Ah, the legendary %s returns! How may I assist you today?",
	"Greetings, brave %s! The quest board has been busy today."
]

func _on_tavern_keeper_clicked(event):
	# Only respond to left mouse button press
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("TavernHub: Tavern keeper clicked")
		_show_keeper_response()

func _show_keeper_response():
	# Get players name
	var player_name = ProfileManager.get_character_name()
	if player_name.is_empty():
		player_name = "adventurer"
	
	# Pick a random response and insert the players name
	var response = keeper_responses[randi() % keeper_responses.size()]
	var formatted_response = response % player_name
	
	# Show using Dialog manager
	DialogManager.show_dialog("Dorin", formatted_response)

func _update_welcome_message():
	# setting up time-based greetings for the tavern keeper
	print("TavernHub: Preparing time-based greetings")
	
	# We'll integrate this into the keeper responses
	_setup_time_based_keeper_greetings()

func _setup_time_based_keeper_greetings():
	# Get current time for time-based greeting
	var current_time = Time.get_datetime_dict_from_system()
	var hour = current_time.hour
	
	var time_greeting = ""
	if hour >= 5 and hour < 12:
		time_greeting = "Good morning"
	elif hour >= 12 and hour < 17:
		time_greeting = "Good afternoon"
	elif hour >= 17 and hour < 22:
		time_greeting = "Good evening"
	else:
		time_greeting = "Greetings, night owl"
	
	# Add time-based responses to the beginning of our keeper_responses array
	keeper_responses.insert(0, time_greeting + ", %s! Welcome back to the Seeking Quill.")
	keeper_responses.insert(1, time_greeting + ", brave %s! Ready for another day of adventure?")
