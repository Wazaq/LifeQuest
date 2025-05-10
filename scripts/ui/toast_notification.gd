extends PanelContainer
## ToastNotification: A temporary notification display

@onready var message_label: Label = $HBoxContainer/MessageLabel

# notification type styles
var style_colors = {
	"info": Color("6b98c2"),  # Blue for general info
	"success": Color("5cb85c"),  # Green for success
	"warning": Color("f0ad4e"),  # Orange for warnings
	"error": Color("d9534f")  # Red for errors
}

# Animation properties
var display_time: float = 3.0
var fade_in_time: float = 0.3
var fade_out_time: float = 0.5

func _ready():
	if message_label == null:
		push_error("Toast notification message label is null!")
		
	# Start invisible
	modulate.a = 0
	
	# Animate in
	animate_in()

# Setup the notification with message and type
func setup(message: String, type: String = "info", time: float = 3.0):
	# Use direct node access instead of relying on @onready var
	var label = get_node_or_null("HBoxContainer/MessageLabel")
	if label == null:
		push_error("Toast: Could not find MessageLabel node")
		return
		
	label.text = message
	display_time = time
	
	# Apply style based on type
	var style = get_theme_stylebox("panel", "PanelContainer").duplicate()
	if style is StyleBoxFlat and type in style_colors:
		style.border_color = style_colors[type]
		add_theme_stylebox_override("panel", style)

# Animate the notification coming in
func animate_in():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_time)
	
	# Wait display time then animate out
	await get_tree().create_timer(display_time).timeout
	animate_out()

# Animate the notification going out
func animate_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_out_time)
	
	# Remove from scene when done
	await tween.finished
	queue_free()

# Manually dismiss the notification
func dismiss():
	animate_out()
