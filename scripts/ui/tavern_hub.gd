extends Control
## TavernHub: Main hub for the application

#@onready var header_label = $MarginContainer/VBoxContainer/HeaderLabel
#
#func _ready():
	#print("TavernHub: Ready")
	#
	## Add margin to container
	#var margin_container = $MarginContainer
	#margin_container.add_theme_constant_override("margin_left", 20)
	#margin_container.add_theme_constant_override("margin_right", 20)
	#margin_container.add_theme_constant_override("margin_top", 20)
	#margin_container.add_theme_constant_override("margin_bottom", 90) # Extra bottom margin for nav bar
	#
	## Make header label bigger
	#header_label.add_theme_font_size_override("font_size", 28)
	#
	## Get subheader label
	#var subheader_label = $MarginContainer/VBoxContainer/SubheaderLabel
	#if subheader_label:
		#subheader_label.add_theme_font_size_override("font_size", 18)
	#
	## Update welcome message with character name
	#if get_node_or_null("/root/ProfileManager"):
		#var character_name = "Hero"
		#
		## Check if ProfileManager has a character
		#if ProfileManager.current_character and ProfileManager.current_character.has("name") and ProfileManager.current_character.name != "":
			#character_name = ProfileManager.current_character.name
		#
		#header_label.text = "Welcome to the Tavern, %s!" % character_name
