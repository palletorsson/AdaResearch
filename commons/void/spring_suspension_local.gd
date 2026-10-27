extends "res://algorithms/joint/05_spring_suspension/SpringSuspension.gd"
## The original trace samples world positions; do not transform it twice on a floor.
func _ready() -> void:
	super._ready()
	_trail_mesh.top_level=true
	_trail_mesh.global_transform=Transform3D.IDENTITY
	_wheel_rest_y=to_global(Vector3(0,1.6,0)).y

func _process(delta: float) -> void:
	super._process(delta)
	_info_label.global_position=wheel.global_position+global_basis*Vector3(1.2,0,0)
