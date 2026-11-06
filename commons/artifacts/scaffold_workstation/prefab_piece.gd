extends "res://commons/artifacts/primitive_encounters/piece.gd"
## Full-size solid: gravity remains active after a near-grid release.
var grid:Node3D
var grid_offset:=Vector3.ZERO
var unit_scale:=1.0
const SNAP:=.16

func _init()->void:
	floats=false;freeze=false;release_mode=ReleaseMode.UNFROZEN
	mass=18;linear_damp=.65;angular_damp=2.0
	physics_material_override=PhysicsMaterial.new();physics_material_override.friction=.9
	set_meta("desktop_preserve_orientation",true)

func _ready()->void:
	super._ready()
	dropped.connect(func(_piece):snap_release.call_deferred())

func snap_release()->void:
	if not is_instance_valid(grid) or held():return
	var local:Transform3D=grid.global_transform.affine_inverse()*global_transform
	var address:Vector3=(local.origin-grid_offset).snapped(Vector3.ONE*unit_scale)+grid_offset
	# Magnetism helps lateral alignment; gravity alone decides the support height.
	address.y=local.origin.y
	# No attraction across the room, and no suspension in midair after snapping.
	if local.origin.distance_to(address)>SNAP*unit_scale:return
	var euler:=local.basis.get_euler();var quarter:Vector3=euler.snapped(Vector3.ONE*PI*.5)
	var orientation:=Basis.from_euler(quarter)
	if local.basis.get_rotation_quaternion().angle_to(orientation.get_rotation_quaternion())>deg_to_rad(18):return
	var target:Transform3D=grid.global_transform*Transform3D(orientation,address)
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=$Collision.shape;query.transform=target
	query.collision_mask=7;query.exclude=[get_rid()];query.margin=.001
	if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return
	global_transform=target;linear_velocity=Vector3.ZERO;angular_velocity=Vector3.ZERO
	PhysicsServer3D.body_set_state(get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,target)
	freeze=false;sleeping=false
