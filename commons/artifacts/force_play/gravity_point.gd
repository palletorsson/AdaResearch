extends "res://commons/artifacts/force_capability_lab/force_point.gd"
## The familiar point becomes a local gravity gun. Trigger pulls; release lets go.
## It applies a bounded spring force, never freezes or teleports the target.
var candidates: Array = []
var caught: RigidBody3D
var beam: Node3D

func _ready() -> void:
	super()
	remove_from_group("ada_thrust_points")
	beam=load("res://commons/artifacts/force_halls/vector_arrow.gd").new();add_child(beam)
	var m=StandardMaterial3D.new();m.albedo_color=Color("96dfcf");m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.build(m,0.009,false)

func aim_frame() -> Node3D:
	var aim: Node3D=get_picked_up_by_controller()
	if aim==null and is_instance_valid(desktop_pointer):aim=desktop_pointer.get("_camera")
	return aim if aim!=null else self

func acquire() -> RigidBody3D:
	var aim=aim_frame();var direction=-aim.global_basis.z
	var best=0.91;var selected: RigidBody3D
	for body in candidates:
		if not is_instance_valid(body) or body==self:continue
		var to_body=body.global_position-aim.global_position
		if to_body.length()>9.0 or to_body.length()<0.15:continue
		var alignment=direction.dot(to_body.normalized())
		if alignment>best:
			var ray=PhysicsRayQueryParameters3D.create(aim.global_position,body.global_position,1|4)
			ray.exclude=[get_rid()]
			var hit=get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty() or hit.get("collider")==body:best=alignment;selected=body
	return selected

func _physics_process(_dt: float) -> void:
	if not firing or not held():caught=null;beam.visible=false;return
	if not is_instance_valid(caught):caught=acquire()
	if not is_instance_valid(caught):beam.visible=false;return
	var aim=aim_frame();var goal=aim.global_position-aim.global_basis.z*1.8
	if caught.global_position.distance_to(goal)>10.0:caught=null;beam.visible=false;return
	if caught.is_picked_up() or caught.has_meta("capability_desktop_held"):caught=null;return
	caught.freeze=false;caught.sleeping=false
	caught.apply_central_force(((goal-caught.global_position)*32.0-caught.linear_velocity*8.0).limit_length(95.0))
	beam.set_ends(Vector3.ZERO,to_local(caught.global_position))

func _process(_dt: float) -> void:
	jet.visible=false
