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

# Tutorial overlay references
@onready var tutorial_overlay: Control = $TutorialOverlay
@onready var tutorial_text: Label = $TutorialOverlay/TutorialText
@onready var highlight_container: Control = $TutorialOverlay/HighlightContainer

# Tutorial state
var current_tutorial_step: int = 0
var tutorial_steps = [
	{
		"text": "Welcome to your Character Profile! Here you can track your heroic progression and achievements.",
		"highlight_target": ""
	},
	{
		"text": "This shows your character name and current rank. As you complete quests, you'll advance from Peasant to Legend!",
		"highlight_target": "character_info"
	},
	{
		"text": "These are your character stats - Might, Intellect, Wisdom, Agility, Endurance, and Charm. They'll grow as you complete different types of quests.",
		"highlight_target": "stats_section"
	},
	{
		"text": "This progress section shows your quest completion count, your current streak, and total experience earned.",
		"highlight_target": "progress_section"
	},
	{
		"text": "These buttons will give you access to equipment and inventory management in future updates.",
		"highlight_target": "action_buttons"
	},
	{
		"text": "Congratulations! You're now ready to embark on your epic journey of personal growth and achievement. May fortune favor your quests, brave adventurer!",
		"highlight_target": ""
	}
]

func _ready():
	print("CharacterProfile: Ready")
	
	# Connect action button signals for future expansion
	equipment_button.pressed.connect(_on_equipment_button_pressed)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	
	# Update the character profile information
	update_character_info()
	
	# Check if we're in tutorial mode
	_check_tutorial_mode()

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
	if character is CharacterResource: # Tutorial Debugging Mode
	# Resource object path
		if character.avatar_path != "" and ResourceLoader.exists(character.avatar_path):
			character_portrait.texture = load(character.avatar_path)
	elif character is Dictionary: #Normal Game
	# Dictionary path
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

# Tutorial system integration
func _check_tutorial_mode():
	# Check if we're in tutorial mode and on the character profile step
	if TutorialManager and TutorialManager.is_tutorial_active():
		var current_step = TutorialManager.get_current_step()
		print("CharacterProfile: Tutorial active, current step: ", current_step)
		# Check if we're on the character profile tutorial step
		if current_step == TutorialManager.TutorialStep.CHARACTER_PROFILE_TUTORIAL:
			_start_tutorial_overlay()
	else:
		# Check if player has never completed tutorial
		var _character = ProfileManager.current_character
		if not TutorialManager.has_completed_tutorial():
			print("CharacterProfile: Tutorial not completed, starting from beginning")
			# Start tutorial from the beginning
			TutorialManager.start_tutorial()
			# This will navigate back to tavern hub to start tutorial flow

func _start_tutorial_overlay():
	print("CharacterProfile: Starting tutorial overlay")
	current_tutorial_step = 0
	tutorial_overlay.visible = true
	
	# Hide navigation bar during tutorial
	var main_node = get_node_or_null("/root/Main")
	if main_node:
		var nav_bar = main_node.get_node_or_null("UIRoot/MainContainer/NavigationContainer/BottomNavBar")
		if nav_bar:
			nav_bar.visible = false
	
	# Position tutorial text in center since nav bar is hidden
	tutorial_text.anchor_top = 0.6
	tutorial_text.anchor_bottom = 0.6
	tutorial_text.offset_top = 0
	tutorial_text.offset_bottom = 100
	
	# Set up proper mouse filtering for input detection
	var dim_background = tutorial_overlay.get_node_or_null("DimBackground")
	if dim_background:
		dim_background.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
		# Lighter overlay
		dim_background.color = Color(0, 0, 0, 0.4)
	
	# Add dark background to tutorial text for better readability
	if not tutorial_text.has_theme_stylebox_override("normal"):
		var text_bg = StyleBoxFlat.new()
		text_bg.bg_color = Color(0, 0, 0, 0.8)  # Dark background
		text_bg.corner_radius_top_left = 10
		text_bg.corner_radius_top_right = 10
		text_bg.corner_radius_bottom_left = 10
		text_bg.corner_radius_bottom_right = 10
		text_bg.content_margin_left = 15
		text_bg.content_margin_top = 15
		text_bg.content_margin_right = 15
		text_bg.content_margin_bottom = 15
		tutorial_text.add_theme_stylebox_override("normal", text_bg)
		tutorial_text.add_theme_color_override("font_color", Color.WHITE)
	
	# Make tutorial overlay cover full screen
	tutorial_overlay.anchor_bottom = 1.0  # Extend to bottom of screen
	
	# Make sure the overlay itself can receive input
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect gui_input signal for the tutorial overlay
	if not tutorial_overlay.gui_input.is_connected(_on_tutorial_overlay_clicked):
		tutorial_overlay.gui_input.connect(_on_tutorial_overlay_clicked)
	
	_show_tutorial_step(current_tutorial_step)

func _show_tutorial_step(step_index: int):
	if step_index >= tutorial_steps.size():
		_complete_tutorial()
		return
	
	var step_data = tutorial_steps[step_index]
	tutorial_text.text = step_data["text"]
	tutorial_text.visible = true  # Make sure text is visible
	
	# For final message, move to center for better visibility
	if step_index == tutorial_steps.size() - 1:
		tutorial_text.anchor_top = 0.4
		tutorial_text.anchor_bottom = 0.4
	else:
		tutorial_text.anchor_top = 0.7
		tutorial_text.anchor_bottom = 0.7
	
	# Clear existing highlights
	_clear_highlights()
	
	# Add highlight for target element
	if step_data["highlight_target"] != "":
		_highlight_element(step_data["highlight_target"])

func _highlight_element(target: String):
	var target_node = null
	
	match target:
		"character_info":
			target_node = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/CharacterHeader/CharacterInfo
		"stats_section":
			target_node = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/StatsSection
		"progress_section":
			target_node = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/ProgressSection
		"action_buttons":
			target_node = $MarginContainer/CharacterCard/ContentContainer/ContentPadding/ProfileSections/ActionsSection
	
	if target_node:
		_create_highlight_border(target_node)

func _create_highlight_border(target_node: Node):
	if not target_node:
		return
	
	# Create a styled highlight panel
	var highlight_panel = Panel.new()
	highlight_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Position and size the highlight
	var global_rect = target_node.get_global_rect()
	var local_rect = get_global_rect()
	
	highlight_panel.position = global_rect.position - local_rect.position - Vector2(5, 5)
	highlight_panel.size = global_rect.size + Vector2(10, 10)
	
	# Style with bright border only (no center fill)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1.0, 1.0, 1.0, 0.0)  # Completely transparent center
	style_box.border_width_left = 5
	style_box.border_width_top = 5
	style_box.border_width_right = 5
	style_box.border_width_bottom = 5
	style_box.border_color = Color(1.0, 1.0, 0.0, 1.0)  # Bright yellow border
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	highlight_panel.add_theme_stylebox_override("panel", style_box)
	highlight_container.add_child(highlight_panel)
	
	# Add pulsing animation
	var tween = create_tween()
	tween.set_loops(-1)
	tween.tween_property(highlight_panel, "modulate:a", 0.5, 1.0)
	tween.tween_property(highlight_panel, "modulate:a", 1.0, 1.0)
	
	highlight_panel.set_meta("highlight_tween", tween)

func _clear_highlights():
	for child in highlight_container.get_children():
		if child.has_meta("highlight_tween"):
			var tween = child.get_meta("highlight_tween")
			if tween:
				tween.kill()
		child.queue_free()

func _on_tutorial_overlay_clicked(event):
	# Only process mouse button clicks, ignore mouse motion
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("CharacterProfile: Tutorial click detected, advancing to step ", current_tutorial_step + 1)
		current_tutorial_step += 1
		_show_tutorial_step(current_tutorial_step)

func _complete_tutorial():
	print("CharacterProfile: Tutorial completed, returning to tavern hub")
	tutorial_overlay.visible = false
	
	# Show navigation bar again
	var main_node = get_node_or_null("/root/Main")
	if main_node:
		var nav_bar = main_node.get_node_or_null("UIRoot/MainContainer/NavigationContainer/BottomNavBar")
		if nav_bar:
			nav_bar.visible = true
	
	# Disconnect gui_input signal to clean up
	if tutorial_overlay.gui_input.is_connected(_on_tutorial_overlay_clicked):
		tutorial_overlay.gui_input.disconnect(_on_tutorial_overlay_clicked)
	
	# Mark tutorial as completed in character data
	DataManager.save_character(ProfileManager.current_character)
	
	# Complete the tutorial in TutorialManager
	TutorialManager.complete_tutorial()
	
	# Navigate back to tavern hub for normal gameplay
	if get_node_or_null("/root/UIManager"):
		UIManager.open_screen("tavern_hub")
