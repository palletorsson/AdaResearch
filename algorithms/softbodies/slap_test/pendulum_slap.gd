extends Node3D

# Configuration
@export var pendulum_height: float = 8.0
@export var arm_length: float = 3.5
@export var soft_body_pressure: float = 2.5
@export var slap_force: float = 20.0

var lower_arm: RigidBody3D

func _ready() -> void:
	# setup_scene()
	setup_pendulum()
	# setup_soft_body()
	call_deferred("apply_initial_impulse")

func apply_initial_impulse() -> void:
	if lower_arm:
		# Swing it back first so it hits forward
		lower_arm.apply_central_impulse(Vector3(0, 0, 50.0))


func setup_pendulum() -> void:
	# Anchor
	var anchor = StaticBody3D.new()
	anchor.position = Vector3(0, pendulum_height, 0)
	add_child(anchor)
	
	# Upper Arm
	var upper_arm = create_link(Vector3(0, pendulum_height - arm_length/2.0, 0), Color.RED)
	add_child(upper_arm)
	
	# Joint 1
	var joint1 = PinJoint3D.new()
	joint1.node_a = anchor.get_path()
	joint1.node_b = upper_arm.get_path()
	joint1.position = anchor.position
	# Allow swinging in Z axis (slapping forward/back)
	# PinJoint3D aligns with Z axis by default? No, it pins A and B. 
	# We want it to swing like a pendulum.
	add_child(joint1)
	
	# Lower Arm (The Slapper)
	lower_arm = create_link(Vector3(0, pendulum_height - arm_length - arm_length/2.0, 0), Color.BLUE)
	# Make it heavier to slap hard
	lower_arm.mass = 10.0 
	add_child(lower_arm)
	
	# Joint 2
	var joint2 = PinJoint3D.new()
	joint2.node_a = upper_arm.get_path()
	joint2.node_b = lower_arm.get_path()
	joint2.position = Vector3(0, pendulum_height - arm_length, 0)
	add_child(joint2)
	
	# Add a "Hand" or "Paddle" to the end of lower arm
	var paddle = MeshInstance3D.new()
	paddle.mesh = BoxMesh.new()
	(paddle.mesh as BoxMesh).size = Vector3(1.5, 1.5, 0.5)
	paddle.position = Vector3(0, -arm_length/2.0, 0)
	lower_arm.add_child(paddle)
	
	var paddle_col = CollisionShape3D.new()
	paddle_col.shape = BoxShape3D.new()
	(paddle_col.shape as BoxShape3D).size = Vector3(1.5, 1.5, 0.5)
	paddle_col.position = Vector3(0, -arm_length/2.0, 0)
	lower_arm.add_child(paddle_col)

func create_link(pos: Vector3, color: Color) -> RigidBody3D:
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = 2.0
	
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.3
	mesh.height = arm_length
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	
	var shape = CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	(shape.shape as CapsuleShape3D).radius = 0.3
	(shape.shape as CapsuleShape3D).height = arm_length
	body.add_child(shape)
	
	return body


func _physics_process(_delta):
	# Add some periodic force to keep the pendulum swinging if needed
	# Or just let it swing from gravity if we start it offset
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if lower_arm:
			# Slap!
			lower_arm.apply_central_impulse(Vector3(0, 0, -slap_force))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
