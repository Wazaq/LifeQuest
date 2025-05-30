extends Control

# Header Elements
@onready var header_container: HBoxContainer = $MainContainer/VBoxContainer/HeaderSection/HBoxContainer
@onready var streak_label: Label = $MainContainer/VBoxContainer/HeaderSection/HBoxContainer/StreakLabel
@onready var daily_quest_label: Label = $MainContainer/VBoxContainer/HeaderSection/HBoxContainer/DailyQuestLabel

# Quest section
@onready var section_title: Label = $MainContainer/VBoxContainer/ActiveQuestSection/SectionTitle
@onready var quest_list: VBoxContainer = $MainContainer/VBoxContainer/ActiveQuestSection/QuestScrollArea/QuestList

# Action buttons
@onready var seek_adventure_button: Button = $MainContainer/VBoxContainer/ActionSection/SeekAdventureButton
@onready var reset_cooldown_button: Button = $MainContainer/VBoxContainer/ActionSection/ResetCooldownButton

# Quest item scene for creating quest cards
const quest_item_scene = preload("res://scenes/quests/quest_item_improved.tscn")

# track quest cards we've created
var active_quest_cards = {}

# Tutorial overlay references
@onready var tutorial_overlay: Control = $TutorialOverlay
@onready var tutorial_text: Label = $TutorialOverlay/TutorialText
@onready var continue_button: Button = $TutorialOverlay/ContinueButton
@onready var highlight_container: Control = $TutorialOverlay/HighlightContainer

# Tutorial state
var current_tutorial_step: int = 0
var tutorial_steps = [
	{
		"text": "Welcome to your Quest Board! This is where you manage all your active adventures and seek out new challenges.",
		"highlight_target": ""
	},
	{
		"text": "Here you can see all your active quests with their difficulty colors, XP rewards, and time remaining.",
		"highlight_target": "quest_list"
	},
	{
		"text": "The lightning bolt buttons let you quickly complete quests when you've finished them in real life!",
		"highlight_target": "quick_complete"
	},
	{
		"text": "This button helps you seek out new adventures when you're ready for more challenges.",
		"highlight_target": "seek_adventure"
	},
	{
		"text": "Click on any quest card to see its full details, requirements, and completion options.",
		"highlight_target": "quest_card"
	},
	{
		"text": "Excellent! Now let's check your Character profile to see your progression and stats.",
		"highlight_target": ""
	}
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("QuestBoard: Initializing Quest Board")
	
	# Hide debug buttons based on category
	if not GameManager.is_debug_enabled(GameManager.DebugCategory.QUEST_SYSTEM):
		reset_cooldown_button.visible = false
	
	# Wait a frame for everything to be properly setup
	await get_tree().process_frame
	
	# Connect to QuestManager signals if available
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_completed.connect(_on_quest_completed)
	
	# Connect button signals
	seek_adventure_button.pressed.connect(_on_seek_adventure_pressed)
	reset_cooldown_button.pressed.connect(_on_reset_cooldown_pressed)
	
	# Load and display current quest data
	update_quest_display()

	# Check if we're in tutorial mode
	_check_tutorial_mode()

func _on_quest_started(quest_id):
	print("QuestBoard: Quest started signal received for: ", quest_id)
	update_quest_display()

@warning_ignore("unused_parameter")
func _on_quest_completed(quest_id, rewards):
	print("QuestBoard: Quest completed signal received for: ", quest_id)
	#update_quest_display()
	
func _on_seek_adventure_pressed():
	#print("Questboard: Seek Adventure button pressed")
	
	if not get_node_or_null("/root/QuestManager"):
		print("QuestBoard: QuestManager not found")
	
	# Check if we can take more quests
	var active_count = QuestManager.active_quests.size()
	var max_count = QuestManager.max_active_quests
	
	if active_count >= max_count:
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("Quest log is full! Complete some quests first.", "warning")
		return
		
	# Get a random quest
	var quest = QuestManager.get_random_quest()
	if quest:
		# Start the quest
		if QuestManager.start_quest(quest.id):
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("New adventure accepted: %s" % quest.title, "success")
			# Refresh the display
			update_quest_display()
		else:
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Failed to start quest", "error")
	else:
		if get_node_or_null("/root/UIManager"):
			UIManager.show_toast("No quests available right now", "info")
	
func _on_reset_cooldown_pressed():
	#print("QuestBoard: Reset cooldown button pressed")
	
	if not get_node_or_null("/root/QuestManager"):
		print("QuestBoard: QuestManager not found")
		return
	
	# Reset all cooldowns
	var count = QuestManager.reset_all_cooldowns()
	
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Reset cooldowns for %d quests" % count, "info")
		
	# Update the seek adventures avail number
	update_button_states()
	
func update_quest_display():
	print("QuestBoard: Updating quest display")
	
	# Update the header info
	update_header_info()
	
	# Update the active quests list
	update_active_quests()
	
	# Update buttons states
	update_button_states()
	
func update_header_info():
	# Update steak info (get from profile manager)
	var streakFire = preload("res://assets/icons/ui/streak.png")
	var streak: int = 0 # Default
	if get_node_or_null("/root/ProfileManger"):
		streak = ProfileManager.current_character.get("streak" , 0)	
	
	if not header_container.get_node_or_null("StreakIcon"):
		var fire_image = TextureRect.new()
		fire_image.texture = streakFire
		fire_image.name = "StreakIcon"
		fire_image.custom_minimum_size = Vector2(10,10)
		header_container.add_child(fire_image)
		header_container.move_child(fire_image, 0)
	# Current streak for the player	
	streak_label.text = " Streak: %d days" % streak	
	# TODO: Future feature, where the player can set their own dialy quest goal
	#daily_quest_label.text = "Today: 2/3 quests"
	
func update_active_quests():
	# Get active quests from QuestManager
	if not get_node_or_null("/root/QuestManager"):
		print("QuestBoard: QuestManager not found")
		return
	
	var active_quests = QuestManager.active_quests
	
	# During tutorial, limit display to first 2 quests to avoid text overlap
	var display_quests = active_quests
	if TutorialManager and TutorialManager.is_tutorial_active():
		var quest_ids = active_quests.keys()
		if quest_ids.size() > 2:
			display_quests = {}
			for i in range(2):
				var quest_id = quest_ids[i]
				display_quests[quest_id] = active_quests[quest_id]
	
	# Update section title
	var quest_count = active_quests.size()  # Show real count, not display count
	var max_quests = QuestManager.max_active_quests
	section_title.text = "Active Quests (%d/%d)" % [quest_count, max_quests]
	
	# Find which quests are actually new
	var current_quest_ids = display_quests.keys()
	var existing_card_ids = active_quest_cards.keys()
	
	# Remove cards for quests that are no longer active or not being displayed
	for card_id in existing_card_ids:
		if not card_id in current_quest_ids:
			if is_instance_valid(active_quest_cards[card_id]):
				active_quest_cards[card_id].queue_free()
			active_quest_cards.erase(card_id)
	
	# Create cards for new quests only
	for quest_id in current_quest_ids:
		if not quest_id in active_quest_cards:
			var quest = display_quests[quest_id]
			create_quest_card_with_unravel(quest)
		
func update_button_states():
	# Update "Seek New Adventure" button
	if get_node_or_null("/root/QuestManager"):
		var pool_count = QuestManager.get_available_quest_count()
		seek_adventure_button.text = "Seek New Adventure (%d available)" % pool_count
		
		# Disable if we're at max active quests
		var active_count = QuestManager.active_quests.size()
		var max_count = QuestManager.max_active_quests
		seek_adventure_button.disabled = (active_count >= max_count)

func create_quest_card(quest):
	#print("QuestBoard: Creating quest card for: ", quest.title)
	# Load Icons needed and prep
	var lightning_icon = load("res://assets/icons/ui/thunder_quick_quest_complete.png")
	var xp_icon = load("res://assets/icons/ui/xp.png")
	var timer_icon = load("res://assets/icons/ui/time.png")
	
	# Create a panel for the quest card (like your test cards)
	var quest_card = Panel.new()
	quest_card.custom_minimum_size = Vector2(300, 120)

	# Create the parchment-style background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.93, 0.87, 0.73, 1.0)  # Warm parchment color
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.65, 0.55, 0.35, 1.0)  # Darker brown border
	
	# Add difficulty color strip
	var difficulty_color = get_difficulty_color(quest.difficulty)
	style_box.border_width_left = 6  # Make left border thicker for difficulty strip
	style_box.border_color = difficulty_color
	
	quest_card.add_theme_stylebox_override("panel", style_box)
	
	# Create quick complete button (floating in top-right)
	var quick_complete_button = Button.new()
	quick_complete_button.text = ""
	# Load and set the lightning bolt icon
	if lightning_icon:
		quick_complete_button.icon = lightning_icon
		# Optional: Scale the icon if needed
		quick_complete_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		quick_complete_button.text = "QC"  # Fallback to emoji if icon fails to load
	quick_complete_button.custom_minimum_size = Vector2(40, 40)
	quick_complete_button.anchor_left = 1.0
	quick_complete_button.anchor_top = 0.0
	quick_complete_button.anchor_right = 1.0  
	quick_complete_button.anchor_bottom = 0.0
	quick_complete_button.offset_left = -50
	quick_complete_button.offset_top = 10
	quick_complete_button.offset_right = -10
	quick_complete_button.offset_bottom = 50

	# Style the quick complete button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.9, 0.7, 0.2, 0.9)  # Gold color
	button_style.corner_radius_top_left = 20
	button_style.corner_radius_top_right = 20
	button_style.corner_radius_bottom_left = 20
	button_style.corner_radius_bottom_right = 20
	quick_complete_button.add_theme_stylebox_override("normal", button_style)

	# Connect quick complete signal
	quick_complete_button.pressed.connect(_on_quick_complete_pressed.bind(quest))

	quest_card.add_child(quick_complete_button)
	
	# Add margin container
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 15)
	margin_container.add_theme_constant_override("margin_top", 15)
	margin_container.add_theme_constant_override("margin_right", 15)
	margin_container.add_theme_constant_override("margin_bottom", 15)
	quest_card.add_child(margin_container)
	
	# Add content container
	var content_container = VBoxContainer.new()
	margin_container.add_child(content_container)
	
	# Add quest title
	var title_label = Label.new()
	title_label.text = quest.title
	title_label.add_theme_font_size_override("font_size", 18)  # Bigger and bolder
	title_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1, 1.0))  # Dark brown text
	content_container.add_child(title_label)
	
	# Add quest reward info
	# Create a horizontal container for the reward info
	var reward_container = HBoxContainer.new()
	content_container.add_child(reward_container)

	# XP section
	if xp_icon:
		var xp_image = TextureRect.new()
		xp_image.texture = xp_icon
		xp_image.custom_minimum_size = Vector2(16, 16)  # Small icon size
		reward_container.add_child(xp_image)

	var xp_label = Label.new()
	xp_label.text = " %d XP • " % quest.xp_reward
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.2, 1.0))
	reward_container.add_child(xp_label)

	# Time section  
	if timer_icon:
		var time_image = TextureRect.new()
		time_image.texture = timer_icon
		time_image.custom_minimum_size = Vector2(16, 16)
		reward_container.add_child(time_image)

	var time_label = Label.new()
	time_label.text = " %s" % get_time_remaining_text(quest)
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.2, 1.0))
	reward_container.add_child(time_label)
	
	# Add the card to the quest list
	quest_list.add_child(quest_card)
	
	# ✨ CLICKABILITY SPELL ✨
	# Make the quest card clickable
	quest_card.gui_input.connect(_on_quest_card_clicked.bind(quest))
	quest_card.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Store reference to the card
	active_quest_cards[quest.id] = quest_card
	#print("QuestBoard: Quest card created and added to list")

func get_time_remaining_text(quest) -> String:
	# Simple time remaining text for now
	if quest.has_deadline and quest.deadline > 0:
		var current_time = Time.get_unix_time_from_system()
		var time_left = quest.deadline - current_time
		
		if time_left <= 0:
			return "Expired!"
		
		var hours = int(time_left / 3600)
		@warning_ignore("integer_division")
		var days = int(hours / 24)
		
		if days > 0:
			return "%d sun cycles remain" % days
		elif hours > 0:
			return "%d hourglasses remain" % hours
		else:
			return "Soon!"
	else:
		return "No time limit"
		
func get_difficulty_color(difficulty: int) -> Color:
	match difficulty:
		0:  # Easy
			return Color(0.4, 0.8, 0.4, 1.0)    # Green
		1:  # Intermediate  
			return Color(0.9, 0.7, 0.2, 1.0)    # Yellow/Gold
		2:  # Hard
			return Color(0.9, 0.4, 0.2, 1.0)    # Orange
		3:  # Epic
			return Color(0.8, 0.2, 0.8, 1.0)    # Purple
		4:  # Legendary
			return Color(0.9, 0.1, 0.1, 1.0)    # Red
		_:  # Special/Unknown
			return Color(0.2, 0.6, 0.9, 1.0)    # Blue

func _on_quest_card_clicked(event, quest):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("QuestBoard: Quest card clicked - ", quest.title)
		# Navigate to quest details
		if get_node_or_null("/root/UIManager"):
			UIManager.open_screen("quest_details", {"quest_id": quest.id})

func _on_quick_complete_pressed(quest):
	print("QuestBoard: Quick complete pressed for - ", quest.title)
	# We'll add the confirmation dialog next!
	show_completion_confirmation(quest)

func show_completion_confirmation(quest):
	print("QuestBoard: Showing completion confirmation for - ", quest.title)
	
	# Create confirmation dialog
	var confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.title = "Complete Quest?"
	confirmation_dialog.dialog_text = "You will receive:\n%d XP!" % [quest.xp_reward]
	confirmation_dialog.ok_button_text = "Complete Quest"
	confirmation_dialog.cancel_button_text = "Not Yet"
	
	# Add to scene temporarily
	add_child(confirmation_dialog)
	
	# Connect the confirmation signal
	confirmation_dialog.confirmed.connect(_on_quest_completion_confirmed.bind(quest))
	confirmation_dialog.canceled.connect(func(): confirmation_dialog.queue_free())
	
	# Show the dialog
	confirmation_dialog.popup_centered()

func _on_quest_completion_confirmed(quest):
	print("QuestBoard: Quest completion confirmed for - ", quest.title)
	
	# Complete the quest through QuestManager
	if get_node_or_null("/root/QuestManager"):
		var rewards = QuestManager.complete_quest(quest.id)
		if rewards:
			# Success! Show celebration
			show_quest_completion_celebration(quest, rewards)
		else:
			# Failed to complete
			if get_node_or_null("/root/UIManager"):
				UIManager.show_toast("Failed to complete quest", "error")

func show_quest_completion_celebration(quest, rewards):
	print("QuestBoard: QUEST COMPLETED! ", quest.title, " - Rewards: ", rewards)
	
	# Find the quest card to animate
	if quest.id in active_quest_cards:
		var quest_card = active_quest_cards[quest.id]
		# ROLL THE DICE OF CELEBRATION! 🎲
		var animation_type = randi() % 4
		match animation_type:
			0:
				_animate_sparkle_and_fade(quest_card, quest, rewards)
			1:
				_animate_victory_flash(quest_card, quest, rewards)
			2:
				_animate_scroll_effect(quest_card, quest, rewards)
			3:
				_animate_celebration_burst(quest_card, quest, rewards)
	else:
		# Fallback if card not found
		_show_completion_toast(quest, rewards)

@warning_ignore("unused_parameter")
func _show_completion_toast(quest, rewards):
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Quest Completed! +%d XP!" % rewards.xp, "success")
	update_quest_display()
	
func create_quest_card_with_unravel(quest):
	# Create the quest card normally
	create_quest_card(quest)
	
	# Get the newly created card
	var quest_card = active_quest_cards[quest.id]
	
	# Move it to the top of the list
	quest_list.move_child(quest_card, 0)
	
	# Start with "rolled up" appearance
	quest_card.scale = Vector2(0.0, 1.0)  # Horizontally collapsed
	quest_card.modulate.a = 0.8
	
	# Unravel animation!
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(quest_card, "scale:x", 1.0, 0.8)
	tween.tween_property(quest_card, "modulate:a", 1.0, 0.8)
	
	print("📜 NEW QUEST UNRAVELED: ", quest.title)

# ✨ ANIMATION 1: SPARKLE AND FADE ✨
func _animate_sparkle_and_fade(quest_card, quest, rewards):
	print("🌟 SPARKLE AND FADE ANIMATION!")
	
	# Create sparkle particles (simulated with multiple small panels)
	for i in range(8):
		var sparkle = Panel.new()
		sparkle.size = Vector2(6, 6)
		sparkle.position = quest_card.global_position + Vector2(randf() * 300, randf() * 120)
		
		var sparkle_style = StyleBoxFlat.new()
		sparkle_style.bg_color = Color(1.0, 0.8, 0.0, 1.0)  # Golden sparkles
		sparkle_style.corner_radius_top_left = 3
		sparkle_style.corner_radius_top_right = 3
		sparkle_style.corner_radius_bottom_left = 3
		sparkle_style.corner_radius_bottom_right = 3
		sparkle.add_theme_stylebox_override("panel", sparkle_style)
		
		quest_list.add_child(sparkle)
		
		# Animate sparkles
		var sparkle_tween = create_tween()
		sparkle_tween.set_parallel(true)
		sparkle_tween.tween_property(sparkle, "modulate:a", 0.0, 1.5)
		sparkle_tween.tween_property(sparkle, "position:y", sparkle.position.y - 50, 1.5)
		sparkle_tween.finished.connect(func(): sparkle.queue_free())
	
	# Fade out the quest card
	var tween = create_tween()
	tween.tween_property(quest_card, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): _finish_completion(quest, rewards))

# ⚡ ANIMATION 2: VICTORY FLASH ⚡
func _animate_victory_flash(quest_card, quest, rewards):
	print("⚡ VICTORY FLASH ANIMATION!")
	
	# Create bright flash overlay
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 0.5, 0.0)  # Bright yellow
	flash.size = quest_card.size
	flash.position = Vector2.ZERO
	quest_card.add_child(flash)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Flash sequence
	tween.tween_property(flash, "color:a", 0.8, 0.2)
	tween.tween_property(flash, "color:a", 0.0, 0.3).set_delay(0.2)
	
	# Scale pulse
	tween.tween_property(quest_card, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(quest_card, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
	
	# Slide away
	tween.tween_property(quest_card, "position:x", quest_card.position.x + 400, 0.5).set_delay(0.6)
	tween.tween_property(quest_card, "modulate:a", 0.0, 0.5).set_delay(0.6)
	
	tween.finished.connect(func(): _finish_completion(quest, rewards))

# 📜 ANIMATION 3: SCROLL EFFECT 📜
func _animate_scroll_effect(quest_card, quest, rewards):
	print("📜 SCROLL EFFECT ANIMATION!")
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Roll up from both sides
	tween.tween_property(quest_card, "scale:x", 0.0, 1.2)
	tween.tween_property(quest_card, "rotation", PI * 2, 1.2)  # Full spin
	
	# Slight bounce up as it "rolls"
	tween.tween_property(quest_card, "position:y", quest_card.position.y - 20, 0.6)
	tween.tween_property(quest_card, "position:y", quest_card.position.y, 0.6).set_delay(0.6)
	
	tween.finished.connect(func(): _finish_completion(quest, rewards))

# 🎊 ANIMATION 4: CELEBRATION BURST 🎊
func _animate_celebration_burst(quest_card, quest, rewards):
	print("🎊 CELEBRATION BURST ANIMATION!")
	
	# Create confetti explosion
	for i in range(12):
		var confetti = Panel.new()
		confetti.size = Vector2(8, 8)
		confetti.position = quest_card.global_position + quest_card.size / 2
		
		var confetti_style = StyleBoxFlat.new()
		var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.MAGENTA, Color.CYAN]
		confetti_style.bg_color = colors[randi() % colors.size()]
		confetti.add_theme_stylebox_override("panel", confetti_style)
		
		quest_list.add_child(confetti)
		
		# Random explosion directions
		var direction = Vector2(randf_range(-200, 200), randf_range(-100, -200))
		
		var confetti_tween = create_tween()
		confetti_tween.set_parallel(true)
		confetti_tween.tween_property(confetti, "position", confetti.position + direction, 1.0)
		confetti_tween.tween_property(confetti, "rotation", randf() * PI * 4, 1.0)  # Spin wildly
		confetti_tween.tween_property(confetti, "modulate:a", 0.0, 1.0)
		confetti_tween.finished.connect(func(): confetti.queue_free())
	
	# Make quest card explode outward then disappear
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(quest_card, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(quest_card, "modulate:a", 0.0, 0.5).set_delay(0.3)
	
	tween.finished.connect(func(): _finish_completion(quest, rewards))

# Helper function to finish the completion process
@warning_ignore("unused_parameter")
func _finish_completion(quest, rewards):
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Quest Completed! +%d XP!" % rewards.xp, "success")
	update_quest_display()

# Tutorial system integration
func _check_tutorial_mode():
	# Check if we're in tutorial mode and on the quest board step
	if TutorialManager and TutorialManager.is_tutorial_active():
		var current_step = TutorialManager.get_current_step()
		print("QuestBoard: Tutorial active, current step: ", current_step)
		# Check if we're on the quest board tutorial step
		if current_step == TutorialManager.TutorialStep.QUEST_BOARD_TUTORIAL:
			_start_tutorial_overlay()

func _start_tutorial_overlay():
	print("QuestBoard: Starting tutorial overlay")
	current_tutorial_step = 0
	tutorial_overlay.visible = true
	
	# Position tutorial text in bottom third of screen
	#tutorial_text.anchor_top = 0.7
	#tutorial_text.anchor_bottom = 0.7
	#tutorial_text.offset_top = 0
	#tutorial_text.offset_bottom = 100
	
	# Set up proper mouse filtering for input detection
	var dim_background = tutorial_overlay.get_node_or_null("DimBackground")
	if dim_background:
		dim_background.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
		# Lighten the overlay - less dark, more transparent
		dim_background.color = Color(0, 0, 0, 0.4)  # Lighter overlay
	
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
	
	# Make tutorial overlay cover nav bar area to block navigation during tutorial
	tutorial_overlay.anchor_bottom = 1.0  # Extend to bottom of screen
	
	# Make sure the overlay itself can receive input
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Connect gui_input signal for the tutorial overlay
	if not tutorial_overlay.gui_input.is_connected(_on_tutorial_overlay_clicked):
		tutorial_overlay.gui_input.connect(_on_tutorial_overlay_clicked)
	
	_show_tutorial_step(current_tutorial_step)

func _show_tutorial_step(step_index: int):
	if step_index >= tutorial_steps.size():
		print("QuestBoard: Tutorial completed, advancing to character screen")
		_complete_tutorial()
		return
	
	var step_data = tutorial_steps[step_index]
	tutorial_text.text = step_data["text"]
	tutorial_text.visible = true  # Make sure text is visible
	
	# Clear existing highlights
	_clear_highlights()
	
	# Add highlight for target element
	if step_data["highlight_target"] != "":
		_highlight_element(step_data["highlight_target"])
	
	# Update button text
	if step_index == tutorial_steps.size() - 1:
		continue_button.text = "Continue to Character Screen"
	else:
		continue_button.text = "Continue"

func _highlight_element(target: String):
	var target_node = null
	
	match target:
		"quest_list":
			target_node = quest_list
		"seek_adventure":
			target_node = seek_adventure_button
		"quest_card":
			# Find first active quest card
			if quest_list.get_child_count() > 0:
				target_node = quest_list.get_child(0)
		"quick_complete":
			# Find first quick complete button in a quest card
			if quest_list.get_child_count() > 0:
				var first_card = quest_list.get_child(0)
				for child in first_card.get_children():
					if child is Button and child.icon != null:
						target_node = child
						break
	
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

func _on_tutorial_continue():
	current_tutorial_step += 1
	_show_tutorial_step(current_tutorial_step)

func _on_tutorial_overlay_clicked(event):
	# Only process mouse button clicks, ignore mouse motion
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("QuestBoard: Tutorial click detected, advancing to step ", current_tutorial_step + 1)
		current_tutorial_step += 1
		_show_tutorial_step(current_tutorial_step)

func _complete_tutorial():
	print("QuestBoard: Tutorial step completed, advancing to character screen")
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
	
	# Tell TutorialManager to advance to character screen tutorial
	TutorialManager.advance_to_next_tutorial_step()
	
	# Navigate to character screen
	if get_node_or_null("/root/UIManager"):
		UIManager.open_screen("character_profile")
