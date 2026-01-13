extends Node3D

@onready var manager = $SnapConnectionManager
@onready var logic_display = $CategoryLogicDisplay

func _ready() -> void:
	if manager:
		manager.connection_created.connect(_on_connection_created)
		manager.connection_broken.connect(_on_connection_broken)

func _on_connection_created(_point_a, _point_b, _line) -> void:
	# Hide instruction display when a connection is made
	if logic_display:
		logic_display.visible = false

func _on_connection_broken(_point_a, _point_b) -> void:
	# Show instruction display again if connection is broken
	if logic_display:
		logic_display.visible = true
