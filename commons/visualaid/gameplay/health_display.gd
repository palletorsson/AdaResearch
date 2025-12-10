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
