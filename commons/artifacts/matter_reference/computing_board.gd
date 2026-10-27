extends "res://commons/artifacts/matter_reference/marble_boards.gd"
## Source computing boards share actual planks and dynamic sphere/crate templates.
var prefabs: Dictionary = {}
var generated: Array[Node3D] = []
var serial := 0
var suspended: Dictionary = {}
func _init() -> void:board_graph_path = "res://commons/artifacts/matter_reference/computing-boards.json"
func _ready() -> void:
	prefabs = preload("res://commons/artifacts/matter_reference/source_cache.gd").read_json("res://commons/artifacts/matter_reference/prefabs.json").prefabs
	super._ready()
	for rec in graph.bodies:
		if not bodies.has(rec.id):continue
		var b: PhysicsBody3D = bodies[rec.id]
		b.physics_material_override.friction = 0 if rec.material=="slide" else .05
func mat(look: String) -> Material:
	var key := look
	if look in ["tubeGlass","catch-glass"]:key = "glass"
	if look in ["tubeBack","queueBack"]:key = "back"
	if look in ["tube","queueFloor","queueBack","leg"]:key = "stop"
	if look in ["flap","trap"]:key = "rocker"
	if look in ["return","exit","before","after"]:key = "tray"
	return super.mat(key)
func prefab(kind_name: String) -> Node3D:
	var host := Node3D.new()
	for p in prefabs[kind_name]:
		var arrays := [];arrays.resize(Mesh.ARRAY_MAX);var verts := PackedVector3Array();var normals := PackedVector3Array();var uv := PackedVector2Array()
		for i in range(0,p.vertices.size(),3):verts.append(Vector3(p.vertices[i],p.vertices[i+1],p.vertices[i+2]));normals.append(Vector3(p.normals[i],p.normals[i+1],p.normals[i+2]))
		for i in range(0,p.uv.size(),2):uv.append(Vector2(p.uv[i],p.uv[i+1]))
		# Three.js and Godot use opposite triangle winding.
		var indices := PackedInt32Array()
		for i in range(0,verts.size(),3):indices.append_array(PackedInt32Array([i,i+2,i+1]))
		arrays[Mesh.ARRAY_VERTEX] = verts;arrays[Mesh.ARRAY_NORMAL] = normals;arrays[Mesh.ARRAY_TEX_UV] = uv;arrays[Mesh.ARRAY_INDEX] = indices
		var m := StandardMaterial3D.new();m.albedo_color = Color(p.color);m.roughness = p.roughness;m.metallic = p.metallic
		if p.emission!="000000":m.emission_enabled = true;m.emission = Color(p.emission);m.emission_energy_multiplier = p.emission_energy
		if p.unshaded:m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var mesh := MeshInstance3D.new();mesh.mesh = ArrayMesh.new();mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh.material_override = m;host.add_child(mesh)
	return host
func make_dynamic(template: String) -> RigidBody3D:
	var rec: Dictionary = graph.templates[template];var body := RigidBody3D.new();body.name = "Generated"+str(serial);serial+=1;body.mass = rec.mass;body.can_sleep = false;body.continuous_cd = true;body.position = v(rec.position);body.quaternion = q(rec.quaternion);body.gravity_scale = 9.82/9.8;body.collision_layer = 1;body.collision_mask = 1
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.linear_damp = -log(1.0-rec.linear_damping);body.angular_damp = -log(1.0-rec.angular_damping)
	var pm := PhysicsMaterial.new();pm.friction = .15 if rec.look=="crate" else .05;pm.bounce = 0 if rec.look=="crate" else .08;body.physics_material_override = pm;add_child(body)
	for sh in rec.shapes:
		var col := CollisionShape3D.new();col.position = v(sh.at);col.quaternion = q(sh.quaternion)
		if sh.type=="box":col.shape = BoxShape3D.new();col.shape.size = v(sh.size);col.shape.margin = .001
		else:col.shape = SphereShape3D.new();col.shape.radius = sh.radius
		body.add_child(col)
		if sh.type=="sphere":
			var mesh := MeshInstance3D.new();mesh.mesh = SphereMesh.new();mesh.mesh.radius = sh.radius;mesh.mesh.height = sh.radius*2;mesh.material_override = mat("marble");body.add_child(mesh)
	generated.append(body);return body
func clear_generated() -> void:
	suspended.clear()
	for node in generated:
		if is_instance_valid(node):node.queue_free()
	generated.clear()

func suspend_generated() -> void:
	suspended.clear()
	for node in generated:
		if is_instance_valid(node) and node is RigidBody3D:
			suspended[node.get_instance_id()] = {"body":node,"freeze":node.freeze,"linear":node.linear_velocity,"angular":node.angular_velocity};node.freeze = true

func resume_generated() -> void:
	for saved in suspended.values():
		if not is_instance_valid(saved.body):continue
		var body: RigidBody3D = saved.body;body.freeze = saved.freeze;body.linear_velocity = saved.linear;body.angular_velocity = saved.angular
	suspended.clear()
func pose(id: String,key: String) -> void:
	var p: Dictionary = graph.poses[key];var b: PhysicsBody3D = bodies[id];b.position = v(p.position);b.quaternion = q(p.quaternion);PhysicsServer3D.body_set_state(b.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,b.global_transform)
func console(names: Array,callback: Callable) -> void:
	var base := 0.0
	for rec in graph.bodies:
		if rec.look in ["floor","table"]:base = rec.position[1]+rec.shapes[0].size[1]/2
	var host := Node3D.new();host.name = "Controls";host.position = Vector3(0,base+.8,.9);add_child(host);box_mesh(host,Vector3(0,-.4,0),Vector3(maxf(1.1,names.size()*.28),.8,.18),"dark")
	host.position += v(pending.get("control_offset",[0,0,0]))
	for i in names.size():
		var button := ButtonScene.instantiate();button.name = names[i];button.label = names[i];button.position = Vector3((i-(names.size()-1)*.5)*.28,.06,.14);button.cap_color = Color("e45391");host.add_child(button);buttons[names[i]] = button;button.pressed.connect(callback.bind(names[i]))
	status = Label3D.new();status.position = Vector3(0,.32,.14);status.font_size = 28;status.pixel_size = .0009;host.add_child(status);finish_control_labels(host);remember(host,"Reachable source program controls")
