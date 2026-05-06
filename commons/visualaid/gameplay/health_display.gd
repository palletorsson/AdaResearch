# @identity
# essence: A 3D label showing the player's current health, updated from GameManager.health_updated signal
# desire: To give the player a stable readout of fragility — a number that changes only when the world has acted on them
# critical_parameter: signal connection to GameManager — without it the display lies; with it, every change in health is mirrored instantly
# triggers: Damage events lower the number; healing raises it; map reload resets it; visibility ties health to context
# emerges: A small 3D readout becomes the player's contract with the game — what counts as harm is what changes this label
# needs: Label3D rendering [has], GameManager signal binding [has], reset on map enter [has]
# relationships: Companion to hits_reset_display in forces/Combat_Arena. Both are visual contracts between game state and player perception
# truth: A health display is not a stat — it is a promise that change has consequences and that the world keeps account.
extends Node3D

@onready var value_label: Label3D = $DisplayBody/ValueLabel

func _ready() -> void:
    # Connect to signal if available, or just poll
    if GameManager.has_signal("health_updated"):
        GameManager.health_updated.connect(_on_health_updated)

    # Initial set
    _update_display(GameManager.get_health())

func _on_health_updated(new_health: float) -> void:
    _update_display(new_health)

func _update_display(health: float) -> void:
    # Use ceil to show whole numbers if it's hit-based logic
    value_label.text = "%d" % ceil(health)
    
    # Change color based on health?
    if health <= 1.0:
        value_label.modulate = Color(1, 0, 0, 1) # Red
    elif health <= 2.0:
        value_label.modulate = Color(1, 1, 0, 1) # Yellow
    else:
        value_label.modulate = Color(0, 1, 0, 1) # Green
