extends Control
## CharacterProfile: Displays character information, stats, and progression

# UI References
@onready var character_name_label = $ProfilePanel/MarginContainer/MainVBox/HeaderSection/CharacterInfo/DetailsVBox/CharacterNameLabel
@onready var level_label = $ProfilePanel/MarginContainer/MainVBox/HeaderSection/CharacterInfo/DetailsVBox/LevelLabel
@onready var xp_progress_label = $ProfilePanel/MarginContainer/MainVBox/HeaderSection/CharacterInfo/DetailsVBox/XPProgressLabel
@onready var xp_bar = $ProfilePanel/MarginContainer/MainVBox/HeaderSection/CharacterInfo/DetailsVBox/XPBar
@onready var avatar_rect = $ProfilePanel/MarginContainer/MainVBox/HeaderSection/CharacterInfo/AvatarRect

# Stats Labels
@onready var strength_label = $ProfilePanel/MarginContainer/MainVBox/StatsSection/StatsGrid/StrengthLabel
@onready var intelligence_label = $ProfilePanel/MarginContainer/MainVBox/StatsSection/StatsGrid/IntelligenceLabel
@onready var wisdom_label = $ProfilePanel/MarginContainer/MainVBox/StatsSection/StatsGrid/WisdomLabel
@onready var dexterity_label = $ProfilePanel/MarginContainer/MainVBox/StatsSection/StatsGrid/DexterityLabel
@onready var constitution_label = $ProfilePanel/MarginContainer/MainVBox/StatsSection/StatsGrid/ConstitutionLabel
@onready var charisma_label = $ProfilePanel/MarginContainer/MainVBox/StatsSection/StatsGrid/CharismaLabel

# Quest Stats Labels
@onready var quests_completed_label = $ProfilePanel/MarginContainer/MainVBox/QuestStatsSection/QuestStatsGrid/QuestsCompletedLabel
@onready var streak_label = $ProfilePanel/MarginContainer/MainVBox/QuestStatsSection/QuestStatsGrid/StreakLabel

# Buttons
@onready var back_button = $ProfilePanel/MarginContainer/MainVBox/ButtonsSection/BackButton

func _ready():
	print("CharacterProfile: Ready")
	
	# Connect button signals
	back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))
	
	# Update the character profile information
	update_character_info()

func update_character_info():
	if not get_node_or_null("/root/ProfileManager"):
		push_error("CharacterProfile: ProfileManager not found")
		return
	
	var character = ProfileManager.current_character
	
	# Debug output for character data structure
	print("CharacterProfile: Character stats structure:")
	print("CharacterProfile: Stats type: ", typeof(character.stats))
	print("CharacterProfile: Stats keys: ", character.stats.keys())
	
	# Update basic character info
	character_name_label.text = character.name
	level_label.text = "Adventurer Rank: %d" % character.level
	xp_progress_label.text = "Experience: %d/%d" % [character.xp, character.xp_to_next_level]
	
	# Calculate XP progress percentage
	var xp_percent = (float(character.xp) / float(character.xp_to_next_level)) * 100.0
	xp_bar.value = xp_percent
	
	# Update character stats with safe access
	strength_label.text = "Might: %d" % get_safe_stat_value(character.stats, 0, 1)
	intelligence_label.text = "Intellect: %d" % get_safe_stat_value(character.stats, 1, 1)
	wisdom_label.text = "Wisdom: %d" % get_safe_stat_value(character.stats, 2, 1)
	dexterity_label.text = "Agility: %d" % get_safe_stat_value(character.stats, 3, 1)
	constitution_label.text = "Endurance: %d" % get_safe_stat_value(character.stats, 4, 1)
	charisma_label.text = "Charm: %d" % get_safe_stat_value(character.stats, 5, 1)
	
	# Update quest stats
	if get_node_or_null("/root/QuestManager"):
		var completed_count = 0
		if QuestManager.completed_quests:
			completed_count = QuestManager.completed_quests.size()
		
		quests_completed_label.text = str(completed_count)
		
		# Update streak with a fantasy-themed description
		var streak_days = character.streak
		var streak_text = _get_streak_description(streak_days)
		streak_label.text = streak_text
	
	# Set avatar if available
	if character.avatar and character.avatar != "" and ResourceLoader.exists(character.avatar):
		avatar_rect.texture = load(character.avatar)

# Helper function to safely get stat values from dictionary
func get_safe_stat_value(stats_dict, key, default_value = 1):
	if stats_dict.has(key):
		return stats_dict[key]
	return default_value

# Get a fantasy-themed description for the streak count
func _get_streak_description(days: int) -> String:
	if days <= 0:
		return "Awaiting your first quest"
	elif days == 1:
		return "A single scroll marked"
	elif days <= 3:
		return "A few scrolls marked"
	elif days <= 7:
		return "A week's journey"
	elif days <= 14:
		return "A fortnight's tale"
	elif days <= 30:
		return "A moon's cycle"
	elif days <= 90:
		return "A season's saga"
	elif days <= 180:
		return "Half a year's legend"
	elif days <= 365:
		return "Almost a year's epic"
	else:
		return "An epic of legends"

func _on_back_button_pressed():
	if get_node_or_null("/root/UIManager"):
		UIManager.go_back()
