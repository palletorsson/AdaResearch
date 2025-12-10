extends Node3D

@onready var value_label: Label3D = $DisplayBody/ValueLabel

func _ready() -> void:
	if GameManager.has_signal("health_updated"):
		GameManager.health_updated.connect(_on_health_updated)
	
	_update_display(GameManager.get_health())

func _on_health_updated(new_health: float) -> void:
	_update_display(new_health)

func _update_display(health: float) -> void:
	# "Hits To Reset" implies countdown. 
	# But we already have a Health display (3 -> 0).
	# Let's make this one show how many hits we have TAKEN (0 -> 3) to show progress towards failure.
	var hits_taken = max(0, GameManager.max_player_health - health)
	value_label.text = "%d / %d" % [ceil(hits_taken), int(GameManager.max_player_health)]
	
	if hits_taken >= 2:
		value_label.modulate = Color(1, 0, 0, 1) # Red danger
	elif hits_taken >= 1:
		value_label.modulate = Color(1, 1, 0, 1) # Warning
	else:
		value_label.modulate = Color(1, 0.6, 0, 1) # Normal orange
