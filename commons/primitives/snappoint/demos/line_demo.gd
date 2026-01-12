extends Node3D

@onready var manager = $SnapConnectionManager
@onready var label = $InstructionLabel

func _ready() -> void:
	if manager:
		manager.connection_created.connect(_on_connection_created)
		manager.connection_broken.connect(_on_connection_broken)

func _on_connection_created(_point_a, _point_b, _line) -> void:
	# Hide instruction text when a connection is made
	if label:
		label.visible = false

func _on_connection_broken(_point_a, _point_b) -> void:
	# Show instruction text again if connection is broken
	if label:
		label.visible = true
