extends "res://commons/artifacts/force_capability_lab/loose_point.gd"
## The hand moves this small proxy. Forces move the constrained body;
## a pickup never reparents or teleports a joint's actual rigid body.
var target: RigidBody3D
var offset := Vector3.ZERO

func _ready() -> void:
	super()
	sphere.radius=0.085; sphere.height=0.17; get_child(1).shape.radius=0.085
	collision_mask=0; gravity_scale=0
	var mat=StandardMaterial3D.new();mat.albedo_color=Color("ed96bb")
	get_child(0).material_override=mat

func held() -> bool:
	return is_picked_up() or has_meta("capability_desktop_held")

func _physics_process(_dt: float) -> void:
	if not is_instance_valid(target):return
	var anchor=target.to_global(offset)
	if held():
		target.freeze=false; target.sleeping=false
		var force=((global_position-anchor)*100.0-target.linear_velocity*5.0).limit_length(130.0)
		target.apply_force(force,anchor-target.global_position)
	else:
		freeze=true;global_position=anchor;linear_velocity=Vector3.ZERO
