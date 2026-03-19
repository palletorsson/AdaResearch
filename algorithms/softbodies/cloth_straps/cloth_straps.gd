extends Node3D

# @identity
# essence: N parallel SoftBody3D strips pinned to a frame top bar — each strap is a foil-shader cloth that hangs under gravity and collides with player hands
# desire: to create a curtain you walk through with your body — each strap drapes, parts, and swings back, making soft body physics tactile and intimate
# critical_parameter: strap_count — more straps create a denser curtain with more inter-strap collision, fewer straps let each one swing freely
# triggers: player collision (layer 20) displaces individual straps; throwing a rigid ball (ui_accept) demonstrates mass-vs-compliance interaction
# emerges: overlapping straps tangle and bunch when disturbed simultaneously, creating knot-like configurations never coded into the system
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: follows jelly_cube and softmill as cloth-specific soft body; precedes flagdancer which adds bone-driven wind simulation
# truth: a curtain is not a surface — it is an array of constraints negotiating gravity, and parting it reveals that softness is a collective property

@export var strap_count: int = 8
@export var strap_width: float = 0.3
@export var strap_height: float = 3.5
@export var strap_overlap: float = 0.05

func _ready() -> void:
	setup_scene()
	setup_frame()
	setup_straps()

func setup_scene() -> void:
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 2, 6)
	cam.look_at(Vector3(0, 1.5, 0))
	add_child(cam)
	
	# Light
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)

func setup_frame() -> void:
	var frame_width = (strap_width - strap_overlap) * strap_count + strap_overlap + 0.4
	var frame_height = strap_height + 0.2
	var frame_thickness = 0.5
	
	var frame = StaticBody3D.new()
	# Frame bottom should be at y=0. Frame height is frame_height.
	# Center of frame is at frame_height/2.0.
	frame.position = Vector3(0, frame_height/2.0, 0)
	
	# Deep Red Material for Frame
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.5, 0.0, 0.1) # Deep Red
	
	# Top bar
	var top = MeshInstance3D.new()
	top.mesh = BoxMesh.new()
	(top.mesh as BoxMesh).size = Vector3(frame_width + 0.4, 0.2, frame_thickness)
	top.position = Vector3(0, frame_height/2.0, 0)
	top.material_override = frame_mat
	frame.add_child(top)
	
	var top_col = CollisionShape3D.new()
	top_col.shape = BoxShape3D.new()
	(top_col.shape as BoxShape3D).size = Vector3(frame_width + 0.4, 0.2, frame_thickness)
	top_col.position = top.position
	frame.add_child(top_col)
	
	# Side bars
	for x in [-frame_width/2.0 - 0.1, frame_width/2.0 + 0.1]:
		var side = MeshInstance3D.new()
		side.mesh = BoxMesh.new()
		(side.mesh as BoxMesh).size = Vector3(0.2, frame_height, frame_thickness)
		side.position = Vector3(x, 0, 0)
		side.material_override = frame_mat
		frame.add_child(side)
		
		var side_col = CollisionShape3D.new()
		side_col.shape = BoxShape3D.new()
		(side_col.shape as BoxShape3D).size = Vector3(0.2, frame_height, frame_thickness)
		side_col.position = side.position
		frame.add_child(side_col)
		
	add_child(frame)
	
	# Store frame reference for pinning if needed, though we can pin to world/static body
	# Actually, pinning to a NodePath is best.
	frame.name = "Frame"

func setup_straps() -> void:
	var template = $SoftBodyStrip
	if not template:
		print("SoftBodyStrip template not found!")
		return
		
	# Hide the template, we will use duplicates
	template.visible = false
	# Disable physics for template so it doesn't fall
	template.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Load Foil Shader
	var foil_shader = load("res://commons/resourses/shaders/foil_paper.gdshader")
	var foil_mat = ShaderMaterial.new()
	foil_mat.shader = foil_shader
	
	var total_width = (strap_width - strap_overlap) * strap_count
	var start_x = -total_width / 2.0 + strap_width / 2.0
	
	for i in range(strap_count):
		var x = start_x + i * (strap_width - strap_overlap)
		
		var new_strap = template.duplicate()
		new_strap.visible = true
		new_strap.process_mode = Node.PROCESS_MODE_INHERIT
		# Keep Y and Z from template, only change X
		new_strap.position.x = x
		
		# Apply Foil Shader
		new_strap.material_override = foil_mat
		
		# Enable collision with player (Layer 20) and environment (Layer 1)
		# Layer 20 is bit 19 (1 << 19 = 524288)
		new_strap.collision_layer = 1
		new_strap.collision_mask = 1 | 524288
		
		add_child(new_strap)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Throw a ball to test interaction
		var ball = RigidBody3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.3
		mesh.height = 0.6
		var mi = MeshInstance3D.new()
		mi.mesh = mesh
		ball.add_child(mi)
		var col = CollisionShape3D.new()
		col.shape = SphereShape3D.new()
		(col.shape as SphereShape3D).radius = 0.3
		ball.add_child(col)
		
		ball.position = Vector3(0, 1.5, 4)
		ball.mass = 5.0
		add_child(ball)
		ball.apply_central_impulse(Vector3(0, 0, -20))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
