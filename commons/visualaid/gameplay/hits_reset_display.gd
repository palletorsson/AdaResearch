# @identity
# essence: A 3D readout that mirrors player health and reflects the reset state — companion display to health_display
# desire: To name the moment of reset as visible — to show that being hit and being whole are tracked, not assumed
# critical_parameter: GameManager signal binding — the display is only honest while connected
# triggers: Damage updates the value; restart restores baseline; visibility tracks active map context
# emerges: A readout that pairs with health_display to make state legible — together they read as a small instrument panel
# needs: Label3D [has], GameManager signal [has], reset behavior [has]
# relationships: Twin of health_display in forces/Combat_Arena. Same pattern, different role
# truth: A reset is not a return to nothing — it is the act of restoring an expected state, and the readout is the witness.
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
