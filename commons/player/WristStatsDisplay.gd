extends Label3D
## Wrist-mounted stats display showing map name, XP, and health
## Attach to right hand in base.tscn

@export var show_map_name: bool = true
@export var show_xp: bool = true
@export var show_health: bool = true
@export var update_interval: float = 0.1  # Seconds between updates

var _time_since_update: float = 0.0

func _ready() -> void:
	# Set initial appearance
	pixel_size = 0.0008
	font_size = 48
	modulate = Color(1.0, 1.0, 1.0, 0.9)
	outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	outline_size = 4
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Connect to GameManager signals
	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.health_updated.connect(_on_health_updated)
		GameManager.current_map_changed.connect(_on_map_changed)
		
		# Initial update
		_update_display()

func _process(delta: float) -> void:
	_time_since_update += delta
	if _time_since_update >= update_interval:
		_time_since_update = 0.0
		_update_display()

func _update_display() -> void:
	if not GameManager:
		text = "No GameManager"
		return
	
	var lines: PackedStringArray = []
	
	if show_map_name:
		var map_name = GameManager.get_current_map()
		if map_name.is_empty():
			map_name = "---"
		# Clean up map name for display
		map_name = map_name.replace("_", " ").get_file()
		lines.append("📍 %s" % map_name)
	
	if show_xp:
		var xp = GameManager.get_score()
		lines.append("⭐ %d XP" % xp)
	
	if show_health:
		var health = GameManager.get_health()
		var max_health = GameManager.max_player_health
		var health_pct = (health / max_health) * 100.0 if max_health > 0 else 0.0
		var health_bar = _get_health_bar(health_pct)
		lines.append("❤️ %s %.0f%%" % [health_bar, health_pct])
	
	text = "\n".join(lines)

func _get_health_bar(percentage: float) -> String:
	var filled = int(percentage / 10.0)
	var empty = 10 - filled
	return "█".repeat(filled) + "░".repeat(empty)

func _on_score_updated(_new_score: int) -> void:
	_update_display()

func _on_health_updated(_new_health: float) -> void:
	_update_display()

func _on_map_changed(_map_name: String) -> void:
	_update_display()
