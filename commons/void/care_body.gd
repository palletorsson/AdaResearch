extends Node3D
## Quiet, inferred torso and legs. Hands and arm IK stay with the museum rig.
## This is a starting body, with no progression hooks or extra limb generation.
var camera: Camera3D
var feet: CharacterBody3D
var torso: Node3D
var legs: Array[Node3D] = []
var _yaw := 0.0

func configure(head: Camera3D, body: CharacterBody3D) -> void:
	camera = head
	feet = body
	torso = Node3D.new()
	torso.name = "PlainTorso"
	add_child(torso)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color("d8d4c5")
	cloth.roughness = 0.92
	var sole := StandardMaterial3D.new()
	sole.albedo_color = Color("454942")
	sole.roughness = 0.9
	var skin := StandardMaterial3D.new()
	var manager := get_node_or_null("/root/GameManager")
	skin.albedo_color = manager.get_hand_color() if manager != null else Color("c5ac93")
	skin.roughness = 0.85
	var neck := _capsule(torso,"Neck",Vector3(0,1.49,0),0.065,0.15,Vector3.ONE,skin)
	var head_mesh := _capsule(torso,"Head",Vector3(0,1.65,-0.02),0.105,0.25,Vector3(1,1,1.05),skin)
	# The first-person camera cannot see inside its own head. Other cameras
	# and shadows retain it; the existing hand geometry remains untouched.
	head_mesh.layers = 1<<19
	neck.layers = 1<<19
	camera.set_cull_mask_value(20,false)
	_capsule(torso,"Chest",Vector3(0,1.22,0),0.19,0.51,Vector3(1,1,0.65),cloth)
	_capsule(torso,"Hips",Vector3(0,0.92,0),0.17,0.29,Vector3(1,1,0.7),cloth)
	for side in [-1,1]:
		var leg := Node3D.new()
		leg.position.x = side*0.105
		leg.name = "LeftLeg" if side<0 else "RightLeg"
		torso.add_child(leg)
		legs.append(leg)
		_capsule(leg,"Trouser",Vector3(0,0.47,0),0.075,0.86,Vector3.ONE,cloth)
		_capsule(leg,"Shoe",Vector3(0,0.07,-0.06),0.07,0.22,Vector3(1,0.65,1),sole).rotation.x = PI/2

func _capsule(host: Node3D, title: String, at: Vector3, radius: float, height: float, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 16
	capsule.rings = 4
	mesh.mesh = capsule
	mesh.material_override = mat
	mesh.position = at
	mesh.scale = size
	host.add_child(mesh)
	return mesh

func _physics_process(delta: float) -> void:
	if camera == null or torso == null: return
	var back := Vector3(camera.global_basis.z.x,0,camera.global_basis.z.z)
	if back.length_squared()>0.001:
		_yaw = lerp_angle(_yaw,atan2(back.x,back.z),1-exp(-7*delta))
	torso.global_position = Vector3(camera.global_position.x,feet.global_position.y,camera.global_position.z)+back.normalized()*0.12
	torso.global_rotation = Vector3(0,_yaw,0)
	var height := clampf(camera.global_position.y-feet.global_position.y,1.15,2.0)
	torso.scale = Vector3(1,height/1.65,1)
