extends "res://commons/primitives/quad/quad.gd"
## Four corners, two source triangles, one shared edge — now a traversable plane.
## The tilted, independently editable assembly connects two existing storeys.
const BallTest := preload("res://commons/artifacts/surface_ball_test/surface_ball_test.tscn")
const GroundPhysics := preload("res://addons/godot-xr-tools/overrides/ground_physics.gd")
const GroundSettings := preload("res://addons/godot-xr-tools/overrides/ground_physics_settings.gd")
var support: StaticBody3D
var surface_shape: ConcavePolygonShape3D
var ball_test: Node3D
var armed := false
var tower: Node3D
var shared_diagonal: MeshInstance3D
var panel_edges: MeshInstance3D
var wood_finish: StandardMaterial3D

func _ready() -> void:
	vertex_positions = [Vector3(-2.2,0,3.6),Vector3(2.2,0,3.6),Vector3(2.2,0,-3.6),Vector3(-2.2,0,-3.6)]
	vertex_color = Color("090a0c")
	sphere_size_multiplier = .4
	super()
	wood_finish = StandardMaterial3D.new()
	wood_finish.albedo_texture = load("res://commons/void/textures/construction_wood.png")
	wood_finish.roughness = .88
	wood_finish.metallic = 0.0
	wood_finish.cull_mode = BaseMaterial3D.CULL_BACK
	for face in [triangle_mesh_a_front,triangle_mesh_b_front]:
		face.material_override = wood_finish
	var underside := wood_finish.duplicate() as StandardMaterial3D
	underside.cull_mode = BaseMaterial3D.CULL_FRONT
	for face in [triangle_mesh_a_back,triangle_mesh_b_back]:
		face.material_override = underside
	panel_edges = MeshInstance3D.new()
	panel_edges.name = "PanelThickness"
	panel_edges.material_override = wood_finish
	add_child(panel_edges)
	set_process_unhandled_input(false)
	support = StaticBody3D.new()
	support.name = "WalkableQuad"
	support.collision_layer = 1
	support.set_meta("void_slippery_surface",true)
	add_child(support)
	var collision := CollisionShape3D.new()
	surface_shape = ConcavePolygonShape3D.new()
	surface_shape.backface_collision = true
	collision.shape = surface_shape
	support.add_child(collision)
	# The XR body uses this actual surface's settings; its jump remains enabled.
	var ground := GroundPhysics.new()
	ground.name = "GroundPhysics"
	ground.physics = GroundSettings.new()
	ground.physics.flags = GroundSettings.GroundPhysicsFlags.MOVE_DRAG | GroundSettings.GroundPhysicsFlags.JUMP_VELOCITY
	ground.physics.stop_on_slope = false
	ground.physics.move_drag = 0.0
	ground.physics.move_traction = 30.0
	ground.physics.jump_velocity = preload("res://commons/void/player_rules.gd").JUMP
	support.add_child(ground)
	_update_meshes()
	# A visible shared diagonal, rather than a rectangular box pretending to be a quad.
	var diagonal := MeshInstance3D.new()
	diagonal.name = "SharedDiagonal"
	var rod := CylinderMesh.new()
	rod.top_radius = .008
	rod.bottom_radius = .008
	rod.height = vertex_positions[0].distance_to(vertex_positions[2])
	diagonal.mesh = rod
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("493e2e")
	mat.roughness = .9
	diagonal.material_override = mat
	add_child(diagonal)
	shared_diagonal = diagonal
	diagonal.position.y = .008
	diagonal.quaternion = Quaternion(Vector3.UP,(vertex_positions[2]-vertex_positions[0]).normalized())
	tower = get_tree().get_first_node_in_group("void_game")
	ball_test = BallTest.instantiate()
	ball_test.name = "SurfaceBallTest"
	add_child(ball_test)

func _update_meshes() -> void:
	super()
	_update_panel_edges()
	if surface_shape == null: return
	var faces := PackedVector3Array()
	for indices in [triangle_a_indices,triangle_b_indices]:
		for i in indices: faces.append(vertex_positions[i])
	surface_shape.set_faces(faces)
	if shared_diagonal != null:
		var a := vertex_positions[0]
		var b := vertex_positions[2]
		shared_diagonal.mesh.height = a.distance_to(b)
		shared_diagonal.position = (a+b)*.5+Vector3.UP*.008
		if a.distance_squared_to(b)>.000001:
			shared_diagonal.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func update_single_triangle_mesh(mesh_instance: MeshInstance3D, indices: Array[int]) -> void:
	# Both source triangles share physical board coordinates across their diagonal.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := vertex_positions[indices[0]]
	var b := vertex_positions[indices[1]]
	var c := vertex_positions[indices[2]]
	var normal := (b-a).cross(c-a).normalized()
	for side in [1,-1]:
		for i in ([0,1,2] if side==1 else [0,2,1]):
			var p := vertex_positions[indices[i]]
			st.set_normal(normal*side)
			st.set_uv(Vector2((p.x+2.2)/1.65,(p.z+3.6)/2.4))
			st.add_vertex(p)
	mesh_instance.mesh = st.commit()

func _update_panel_edges() -> void:
	if panel_edges == null: return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4:
		var a := vertex_positions[i]
		var b := vertex_positions[(i+1)%4]
		var points := [a,b,b-Vector3.UP*.045,a-Vector3.UP*.045]
		var normal := (b-a).cross(Vector3.DOWN).normalized()
		for j in [0,1,2,0,2,3]:
			st.set_normal(normal)
			st.set_uv(Vector2(points[j].distance_to(a),points[j].y-a.y)*5)
			st.add_vertex(points[j])
	panel_edges.mesh = st.commit()

func print_help() -> void:
	pass # This tower surface has no global keyboard shortcuts.

func _physics_process(delta: float) -> void:
	if tower == null or not tower.ready_for_play: return
	if tower.recovering:
		armed = false
		ball_test.clear()
	var feet: Vector3 = tower.body.global_position
	var p := to_local(feet)
	var near := absf(p.x)<3.0 and absf(p.z)<5.1 and p.y>-.5 and p.y<2.5
	var grounded: bool = tower.body.on_ground if tower.vr else tower.body.is_on_floor()
	if near and grounded: armed = true
	if armed and not grounded and absf(p.x)<2.5 and absf(p.z)<4.6 and p.y>-.8 and p.y<2.5:
		armed = false
		drop_test_points()

func drop_test_points() -> void:
	var points: Array[Vector3] = []
	for z in range(3):
		for x in range(5): points.append(Vector3((x-2)*.8,0,float(z)))
	ball_test.drop(self,points)

