extends "res://commons/scenes/mapobjects/rotation_cube.gd"
## Original quarter-turn bridge, synced to the same physics clock as the visitor.
@export var bridge_length: float = 3.0

func body_size() -> Vector3:
	return Vector3(bridge_length, .2, 1.0)

func _ready() -> void:
	profile="bridge"
	rotation_angle=90
	pause_duration=5
	super._ready()
	set_process(false)
	set_meta("source_utility","rc")

func _physics_process(delta: float) -> void:
	super._process(delta)
	static_body.force_update_transform()
