extends Control

# Header Elements
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("QuestBoard: Initializing Quest Board")
	
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

func _on_quest_started(quest_id):
	print("QuestBoard: Quest started signal received for: ", quest_id)
	update_quest_display()

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
	var streak: int = 0 # Default
	if get_node_or_null("/root/ProfileManger"):
		streak = ProfileManager.current_character.get("streak" , 0)
	
	streak_label.text = "🔥 Streak: %d days" % streak
	
	# Update daily quest info (placeholder for now)
	daily_quest_label.text = "Today: 2/3 quests"
	
func update_active_quests():
	# Get active quests from QuestManager
	if not get_node_or_null("/root/QuestManager"):
		print("QuestBoard: QuestManager not found")
		return
	
	var active_quests = QuestManager.active_quests
	
	# Update section title
	var quest_count = active_quests.size()
	var max_quests = QuestManager.max_active_quests
	section_title.text = "Active Quests (%d/%d)" % [quest_count, max_quests]
	
	# Find which quests are actually new
	var current_quest_ids = active_quests.keys()
	var existing_card_ids = active_quest_cards.keys()
	
	# Remove cards for quests that are no longer active
	for card_id in existing_card_ids:
		if not card_id in current_quest_ids:
			if is_instance_valid(active_quest_cards[card_id]):
				active_quest_cards[card_id].queue_free()
			active_quest_cards.erase(card_id)
	
	# Create cards for new quests only
	for quest_id in current_quest_ids:
		if not quest_id in active_quest_cards:
			var quest = active_quests[quest_id]
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
	quick_complete_button.text = "⚡"
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
	var reward_label = Label.new()
	reward_label.text = "⚡ %d XP • ⏳ %s" % [quest.xp_reward, get_time_remaining_text(quest)]
	reward_label.add_theme_font_size_override("font_size", 14)  # Slightly bigger
	reward_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.2, 1.0))  # Medium brown
	content_container.add_child(reward_label)
	
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
func _finish_completion(quest, rewards):
	if get_node_or_null("/root/UIManager"):
		UIManager.show_toast("Quest Completed! +%d XP!" % rewards.xp, "success")
	update_quest_display()
