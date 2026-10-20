extends "res://commons/scenes/mapobjects/scale_cube.gd"
## Keep the museum's uniform scale law; advance its collider on the physics clock.
@export var crossing_size: float = 3.0

func _ready() -> void:
	center_offset=Vector3.ZERO
	min_scale=.5
	max_scale=crossing_size
	pause_at_max=5
	super._ready()
	set_process(false)
	set_meta("source_utility","sc")

func _physics_process(delta: float) -> void:
	super._process(delta)
	static_body.force_update_transform()
