extends Control
## CharacterProfile: Displays character information, stats, and progression

# UI References - Updated for new scene structure
@onready var character_name_label = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/CharacterHeader/CharacterInfo/CharacterName
@onready var level_label = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/CharacterHeader/CharacterInfo/CharacterLevel
@onready var xp_label = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/CharacterHeader/CharacterInfo/CharacterXP
@onready var character_portrait = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/CharacterHeader/CharacterPortrait

# Stats Labels - Updated for new grid structure
@onready var might_value = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/StatsSection/StatsGrid/MightStat/MightValue
@onready var intellect_value = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/StatsSection/StatsGrid/IntellectStat/IntellectValue
@onready var wisdom_value = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/StatsSection/StatsGrid/WisdomStat/WisdomValue
@onready var agility_value = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/StatsSection/StatsGrid/AgilityStat/AgilityValue
@onready var endurance_value = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/StatsSection/StatsGrid/EnduranceStat/EnduranceValue
@onready var charm_value = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/StatsSection/StatsGrid/CharmStat/CharmValue

# Progress Labels - Updated for new structure
@onready var quests_completed_label = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/ProgressSection/QuestStatsContainer/QuestsCompleted
@onready var streak_label = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/ProgressSection/QuestStatsContainer/CurrentStreak
@onready var total_xp_label = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/ProgressSection/QuestStatsContainer/TotalXP

# Action Buttons - Updated for new structure
@onready var equipment_button = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/ActionsSection/ActionButtons/EquipmentButton
@onready var inventory_button = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/ActionsSection/ActionButtons/InventoryButton

func _ready():
	print("CharacterProfile: Ready")
	
	# Connect action button signals for future expansion
	equipment_button.pressed.connect(_on_equipment_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	
	# Update the character profile information
	update_character_info()

func update_character_info():
	if not get_node_or_null("/root/ProfileManager"):
		push_error("CharacterProfile: ProfileManager not found")
		return
	
	var character = ProfileManager.current_character
	
	# Update basic character info with fantasy-themed language
	character_name_label.text = character.name
	level_label.text = "Rank: %s" % _get_character_title(character.level)
	xp_label.text = "XP: %d" % character.xp
	
	# Update character stats with fantasy names and safe access
	might_value.text = str(get_safe_stat_value(character.stats, ProfileManager.CharacterStat.STRENGTH, 1))
	intellect_value.text = str(get_safe_stat_value(character.stats, ProfileManager.CharacterStat.INTELLIGENCE, 1))
	wisdom_value.text = str(get_safe_stat_value(character.stats, ProfileManager.CharacterStat.WISDOM, 1))
	agility_value.text = str(get_safe_stat_value(character.stats, ProfileManager.CharacterStat.DEXTERITY, 1))
	endurance_value.text = str(get_safe_stat_value(character.stats, ProfileManager.CharacterStat.CONSTITUTION, 1))
	charm_value.text = str(get_safe_stat_value(character.stats, ProfileManager.CharacterStat.CHARISMA, 1))
	
	# Update progress section with quest stats
	if get_node_or_null("/root/QuestManager"):
		var completed_count = QuestManager.completed_quests.size()
		quests_completed_label.text = "Quests Completed: %d" % completed_count
		
		# Update streak with fantasy-themed description
		var streak_days = character.streak
		var streak_text = _get_streak_description(streak_days)
		streak_label.text = "Current Streak: %s" % streak_text
		
		# Calculate total XP earned (character XP + completed quest XP)
		var total_earned_xp = character.xp
		# Add XP from level-ups (rough calculation)
		for level in range(2, character.level + 1):
			total_earned_xp += ProfileManager.calculate_xp_for_level(level)
		
		total_xp_label.text = "Total Experience Earned: %d XP" % total_earned_xp
	
	# Set character portrait if available
	if character.has("avatar") and character.avatar != "" and ResourceLoader.exists(character.avatar):
		character_portrait.texture = load(character.avatar)

# Helper function to safely get stat values from dictionary
func get_safe_stat_value(stats_dict, key, default_value = 1):
	if stats_dict.has(key):
		return stats_dict[key]
	return default_value

# Get character title based on level
func _get_character_title(level: int) -> String:
	match level:
		1, 2:
			return "Peasant"
		3, 4, 5:
			return "Squire"
		6, 7, 8, 9, 10:
			return "Knight"
		11, 12, 13, 14, 15:
			return "Noble"
		16, 17, 18, 19, 20:
			return "Hero"
		_:
			return "Legend"

# Get a fantasy-themed description for the streak count
func _get_streak_description(days: int) -> String:
	if days <= 0:
		return "0 sun cycles"
	elif days == 1:
		return "1 sun cycle"
	elif days <= 3:
		return "%d sun cycles" % days
	elif days <= 7:
		return "A week's journey (%d sun cycles)" % days
	elif days <= 14:
		return "A fortnight's tale (%d sun cycles)" % days
	elif days <= 30:
		return "A moon's cycle (%d sun cycles)" % days
	elif days <= 90:
		return "A season's saga (%d sun cycles)" % days
	elif days <= 180:
		return "Half a year's legend (%d sun cycles)" % days
	elif days <= 365:
		return "Almost a year's epic (%d sun cycles)" % days
	else:
		return "An epic of legends (%d sun cycles)" % days

# Handle Equipment button press (placeholder for future expansion)
func _on_equipment_button_pressed():
	print("CharacterProfile: Equipment button pressed")
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Equipment management coming soon!", "info")

# Handle Inventory button press (placeholder for future expansion)
func _on_inventory_button_pressed():
	print("CharacterProfile: Inventory button pressed")
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Inventory system coming soon!", "info")
