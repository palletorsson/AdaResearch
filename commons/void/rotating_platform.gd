extends "res://commons/scenes/mapobjects/rotation_cube.gd"
## The museum's rc law, with one rotating support and the tc rider convention.
## Origin is the deck top; the pivot and ceiling bearing never move.
const SteelShader = preload("res://commons/void/trials/transformation/rotation_steel.gdshader")
var deck_length := 8.0
var carried_player: CharacterBody3D

func body_size() -> Vector3:
	return Vector3(deck_length, .2, 1.6)

func _ready() -> void:
	process_physics_priority = 10 # After both player bodies; before Void's fall checks.
	profile = "bridge"
	super._ready()
	set_process(false)
	mesh_instance.position.y = -.1
	static_body.transform = mesh_instance.transform
	static_body.name = "RotatingSupport"
	var steel := ShaderMaterial.new()
	steel.shader = SteelShader
	mesh_instance.material_override = steel
	set_meta("source_utility", "rc")
	# One end is marked so a half-turn cannot pass for an unchanged rectangle.
	var mark := MeshInstance3D.new()
	mark.name = "EndMark"
	var strip := BoxMesh.new()
	strip.size = Vector3(.2,.006,1.56)
	mark.mesh = strip
	mark.position = Vector3(deck_length*.5-.22,.103,0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("e4bb64")
	mark.material_override = material
	mesh_instance.add_child(mark)
	var host: Node = get_parent()
	var ceiling := global_position.y+2.64
	while host != null:
		if host is Node3D and host.has_meta("void_content_floor"):
			ceiling = host.global_position.y+5.64
			break
		host = host.get_parent()
	var axle := StaticBody3D.new()
	axle.name = "FixedAxle"
	add_child(axle)
	var tube := CylinderMesh.new()
	tube.top_radius=.12; tube.bottom_radius=.12
	tube.height=maxf(.2,ceiling-global_position.y-.24)
	var mesh := MeshInstance3D.new()
	mesh.mesh=tube;mesh.position.y=tube.height*.5
	mesh.material_override=steel;axle.add_child(mesh)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius=.12;cylinder.height=tube.height
	shape.shape=cylinder;shape.position=mesh.position;axle.add_child(shape)
	# The hanger spans the open shaft and bears on the slab at both ends.
	var bearing := MeshInstance3D.new()
	bearing.name = "CeilingBearing"
	var beam := BoxMesh.new()
	beam.size = Vector3(7.4,.24,.28)
	bearing.mesh = beam
	bearing.position.y = ceiling-global_position.y-.12
	bearing.material_override=steel;axle.add_child(bearing)
	var bearing_shape := CollisionShape3D.new()
	var beam_shape := BoxShape3D.new()
	beam_shape.size=beam.size
	bearing_shape.shape=beam_shape;bearing_shape.position=bearing.position
	axle.add_child(bearing_shape)

func _supports(rider: CharacterBody3D) -> bool:
	if not rider.is_on_floor(): return false
	var velocity_up := rider.velocity.y
	if rider is XRToolsPlayerBody: velocity_up -= rider.ground_velocity.y
	var feet := static_body.to_local(rider.global_position)
	return velocity_up <= .25 and feet.y >= .04 and feet.y <= .24 \
		and absf(feet.x) <= deck_length*.5+.02 and absf(feet.z) <= .82

func _physics_process(delta: float) -> void:
	if not is_instance_valid(carried_player) or not _supports(carried_player):
		carried_player = null
		for candidate in get_tree().get_nodes_in_group("player_body"):
			if candidate is CharacterBody3D and _supports(candidate):
				carried_player = candidate
				break
	var before := static_body.global_transform
	super._process(delta)
	static_body.force_update_transform()
	if not is_instance_valid(carried_player): return
	var motion := static_body.global_transform * before.affine_inverse()
	if carried_player is XRToolsPlayerBody:
		# Move the whole rig, retaining the room-scale headset offset. Rebase
		# this support's ground estimate so XRTools does not apply the arc twice.
		carried_player.teleport(motion * carried_player.global_transform)
		var ground: Node3D = carried_player.get("_previous_ground_node")
		if is_instance_valid(ground) and is_ancestor_of(ground):
			carried_player.velocity -= carried_player.ground_velocity
			carried_player.ground_velocity = Vector3.ZERO
			carried_player.set("_previous_ground_global", ground.to_global(carried_player.get("_previous_ground_local")))
	else:
		carried_player.global_transform = motion * carried_player.global_transform

func prepare_editor_preview() -> void:
	set_physics_process(false)
	current_angle=0
	mesh_instance.rotation=Vector3.ZERO
	static_body.transform=mesh_instance.transform
