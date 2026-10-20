extends "res://commons/artifacts/whiteboard/whiteboard_pen.gd"
## One marker can write on the whiteboard or any sticky note on its wall.
var wall: Node3D

func _process(delta: float) -> void:
	if is_instance_valid(wall) and (is_picked_up() or desktop_held):
		var target: Node3D=null
		for surface in wall.writing_surfaces():
			if surface.sample_uv($WritingTip.global_position).x>=0:target=surface;break
		if target!=board:_previous=Vector2(-1,-1)
		board=target
	super(delta)

func _physics_process(delta: float) -> void:
	# The inherited recovery guard needs an owner even while the nib is in air.
	if not is_picked_up() and not desktop_held and is_instance_valid(wall):board=wall
	super(delta)
