@tool
extends EditorScript

func _run():
	# Get the current scene
	var scene = get_editor_interface().get_edited_scene_root()
	if not scene or scene.name != "QuestItem":
		print("Not editing QuestItem scene")
		return
		
	# Add StyleBoxFlat to the PanelContainer
	var panel_container = scene
	if not panel_container is PanelContainer:
		print("Root node is not a PanelContainer")
		return
		
	# Create StyleBoxFlat
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.196078, 0.196078, 0.196078, 0.784314)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.301961, 0.301961, 0.301961, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 10
	style.content_margin_top = 5
	style.content_margin_right = 10
	style.content_margin_bottom = 5
	
	# Apply the style
	panel_container.add_theme_stylebox_override("panel", style)
	
	# Configure HBoxContainer
	var hbox = panel_container.get_node("HBoxContainer")
	hbox.set("theme_override_constants/separation", 10)
	
	# Configure QuestIcon
	var icon = hbox.get_node("QuestIcon")
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_KEEP_ASPECT
	
	# Configure VBoxContainer
	var vbox = hbox.get_node("VBoxContainer")
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.set("theme_override_constants/separation", 5)
	
	# Configure QuestNameLabel
	var name_label = vbox.get_node("QuestNameLabel")
	name_label.text = "Quest Name"
	
	# Configure TimeLabel
	var time_label = vbox.get_node("TimeLabel")
	time_label.text = "Expires in 3 days"
	
	# Configure DetailButton
	var button = hbox.get_node("DetailButton") 
	button.text = ">"
	
	print("QuestItem styling completed!")
