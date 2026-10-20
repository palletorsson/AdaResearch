extends "res://commons/scenes/mapobjects/transport_cube.gd"
## Void dress for the original tc. Its tested XR-origin carry remains the driver.
const UnitCube = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")

func _ready() -> void:
	var support: StaticBody3D=get_node("CubeBaseStaticBody3D/CubeBaseStaticBody3D")
	var shape := BoxShape3D.new()
	shape.size=Vector3(2,1,2)
	support.get_node("CollisionShape3D").shape=shape
	get_node("CubeBaseStaticBody3D/DetectionArea/CollisionShape3D").shape=shape.duplicate()
	get_node("CubeBaseStaticBody3D/DetectionArea").position.y=.8
	get_node("CubeBaseStaticBody3D/CarryArea").monitoring=false
	for x in [-.5,.5]:
		for z in [-.5,.5]:
			var cube: Node3D=UnitCube.instantiate()
			cube.position=Vector3(x,-.5,z)
			support.add_child(cube)
			# One moving support body owns all four visual cubes.
			for collider in cube.find_children("*","CollisionShape3D",true,false): collider.free()
	super._ready()
	cube_mesh.hide()
	get_node("CubeBaseStaticBody3D/marker").hide()
	set_meta("source_utility","tc")

func _supports_body(rider: Node3D) -> bool:
	if rider is not CharacterBody3D: return false
	if rider is XRToolsPlayerBody: return _supports_xr_rider(rider)
	var feet: Vector3=_support_shape.to_local(rider.global_position)
	return rider.velocity.y<=.25 and feet.y>=.44 and feet.y<=.66 and absf(feet.x)<=1.04 and absf(feet.z)<=1.04

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _supports_body(body): super._on_detection_area_body_entered(body)

func _on_detection_area_body_exited(body: Node3D) -> void:
	super._on_detection_area_body_exited(body)
	# The museum tc cancels a boarding delay when its rider leaves. Void ferries
	# also run empty: restart that near-bank pause so a visitor cannot strand it.
	if auto_start and not is_queued_for_deletion(): start_transport()

func _physics_process(delta: float) -> void:
	if is_instance_valid(carried_player) and not _supports_body(carried_player):
		_on_detection_area_body_exited(carried_player)
	if not is_instance_valid(carried_player):
		for body in detection_area.get_overlapping_bodies():
			if _is_player(body) and _supports_body(body):
				_on_detection_area_body_entered(body)
				break
	super._physics_process(delta)

func reset_route(start: Vector3, end: Vector3) -> void:
	if is_instance_valid(carried_player): _on_detection_area_body_exited(carried_player)
	global_position=start
	static_body.force_update_transform()
	initial_position=start
	target_position=end
	move_distance=start.distance_to(end)
	move_direction=(end-start).normalized()
	is_moving=false
	is_returning=false
	return_timer=0
	waiting_to_start=false
	movement_sound.stop()
	if auto_start: start_transport()
