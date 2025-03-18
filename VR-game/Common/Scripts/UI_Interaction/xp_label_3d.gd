extends Label3D

class_name XpLabel3D

@export var prefix: String = "XP: "
@export var show_changes: bool = true
@export var change_duration: float = 1.5
@export var positive_color: Color = Color(0.2, 1.0, 0.2)
@export var negative_color: Color = Color(1.0, 0.2, 0.2)

var current_xp: int = 0
var change_label: Label3D
var tween: Tween

func _ready() -> void:
	# Set initial text
	current_xp = GameManager.get_xp()
	text = prefix + str(current_xp)
	
func _on_xp_updated(new_xp: int) -> void:
	var xp_change = new_xp - current_xp
	current_xp = new_xp
	
	# Update the main XP text
	text = prefix + str(current_xp)
	
	# Show XP change if enabled
	if show_changes and xp_change != 0:
		show_xp_change(xp_change)

func show_xp_change(amount: int) -> void:
	if not change_label:
		return
		
	# Cancel any existing tween
	if tween and tween.is_valid():
		tween.kill()
	
	# Set the change text
	change_label.text = ("+" if amount > 0 else "") + str(amount)
	
	# Set color based on positive/negative
	change_label.modulate = positive_color if amount > 0 else negative_color
	
	# Create animation tween
	tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in
	tween.tween_property(change_label, "modulate:a", 1.0, 0.3)
	
	# Move up
	var start_pos = change_label.position
	var end_pos = start_pos + Vector3(0, 0.2, 0)
	tween.tween_property(change_label, "position", end_pos, change_duration)
	
	# Fade out at the end
	tween.chain().tween_property(change_label, "modulate:a", 0.0, 0.3)
	
	# Reset position when done
	tween.chain().tween_property(change_label, "position", start_pos, 0.0)
