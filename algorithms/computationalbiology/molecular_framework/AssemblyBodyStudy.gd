extends Node3D
## Opt-in, body-size editing beside MolecularDesigner's authored cycle.
## Moving gold joints changes geometry; the turquoise collar reroutes one edge.
const JointScript = preload("res://algorithms/computationalbiology/molecular_framework/AssemblyJoint.gd")
const BondScript = preload("res://algorithms/computationalbiology/molecular_framework/AssemblyBondEnd.gd")
const Store = preload("res://algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd")
const DATA := "res://algorithms/computationalbiology/molecular_framework/assemblies.json"
const BODY_SCALE := 1.12
const REACH := Vector3(1.9, 2.35, 1.9)
var joints: Array[XRToolsPickable] = []
var targets: Array[Vector3] = []
var original: Array[Vector3] = []
var pairs: Array[Vector2i] = []
var original_pairs: Array[Vector2i] = []
var rods: Array[MeshInstance3D] = []
var active: Dictionary = {}
var names: Array[String] = []
var edit_count := 0
var caption: Label3D
var radii: Array[float] = []
var last_keep_error: Error = OK
var bond_handle: XRToolsPickable
var bond_preview: MeshInstance3D
var bond_start_handle: XRToolsPickable
var bond_start_preview: MeshInstance3D
var held_ends: Dictionary = {}
var bond_index := -1
var bond_held := false
const SNAP_DISTANCE := .28
const COLLAR_OFFSET := Vector3(-.23,0,.1)

func build(catalog: Dictionary, assembly: Dictionary) -> void:
	# The study is positioned after map configuration. Its dimensions stay in metres.
	var index: Dictionary = {}
	for node in assembly.nodes:
		var i := joints.size()
		var handle := JointScript.new()
		handle.name = "Joint_" + str(node.id)
		handle.study = self
		handle.joint_index = i
		var mesh := MeshInstance3D.new()
		mesh.name = "Mesh"
		var ball := SphereMesh.new()
		ball.radius = float(catalog[node.part].get("radius", .08)) * BODY_SCALE
		ball.height = ball.radius * 2
		radii.append(ball.radius)
		ball.radial_segments = 20
		ball.rings = 10
		mesh.mesh = ball
		mesh.material_override = material(Color(.95,.57,.21), .25)
		handle.add_child(mesh)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = maxf(ball.radius,.095)
		collision.shape = shape
		handle.add_child(collision)
		add_child(handle)
		var v: Array = node.pos
		var point := Vector3(v[0],v[1],v[2]) * float(assembly.get("scale",1.0)) * BODY_SCALE
		handle.position = point
		joints.append(handle)
		targets.append(point)
		original.append(point)
		names.append(str(node.id))
		index[node.id] = i
	for bond in assembly.bonds:
		pairs.append(Vector2i(index[bond[0]],index[bond[1]]))
		if bond[0]=="l_elb" and bond[1]=="l_hand": bond_index = pairs.size()-1
		var rod := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = .028
		cylinder.bottom_radius = .028
		cylinder.radial_segments = 12
		rod.mesh = cylinder
		rod.material_override = material(Color(.85,.77,.57), .08)
		add_child(rod)
		rods.append(rod)
	original_pairs.assign(pairs)
	# A flush floor inlay names the available working area without erecting a barrier.
	for side in [-1.0,1.0]:
		for axis in [0,2]:
			var edge := MeshInstance3D.new()
			var strip := BoxMesh.new()
			strip.size = Vector3(.012,.008,REACH.z*2) if axis==0 else Vector3(REACH.x*2,.008,.012)
			edge.mesh = strip
			edge.position[axis] = side * REACH[axis]
			edge.position.y = .012
			edge.material_override = material(Color(.74,.47,.19), .12)
			add_child(edge)
	caption = Label3D.new()
	caption.text = "LEAVE A BODY DIFFERENT\nTake a joint. Or move a connection."
	caption.font_size = 34
	caption.pixel_size = .003
	caption.position = Vector3(0,2.65,-1.3)
	caption.modulate = Color(.94,.8,.58)
	caption.outline_size = 4
	caption.double_sided = true
	add_child(caption)
	_restore_pose()
	_build_connection()
	_update_rods()
	_update_connection()

func _build_connection() -> void:
	if bond_index < 0: return
	bond_handle = _make_collar(1)
	bond_start_handle = _make_collar(0)
	bond_preview = _make_preview()
	bond_start_preview = _make_preview()
	var hint := Label3D.new()
	hint.text = "GOLD: move a joint\nTURQUOISE: change either end\nRelease a ring at another joint."
	hint.position = Vector3(-1.25,1.45,.6)
	hint.font_size = 23
	hint.pixel_size = .0024
	hint.modulate = Color(.45,.94,.88)
	hint.outline_size = 4
	hint.double_sided = true
	add_child(hint)

func _make_collar(endpoint: int) -> XRToolsPickable:
	var handle := BondScript.new()
	handle.name = "ConnectionEnd" if endpoint==1 else "ConnectionStart"
	handle.study = self
	handle.endpoint = endpoint
	var ring := TorusMesh.new()
	ring.inner_radius = .052
	ring.outer_radius = .095
	ring.rings = 20
	ring.ring_segments = 12
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = ring
	mesh.rotation.x = PI/2
	mesh.material_override = material(Color(.12,.85,.8),.35)
	handle.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = .10
	collision.shape = shape
	handle.add_child(collision)
	add_child(handle)
	return handle

func _make_preview() -> MeshInstance3D:
	var preview := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = .12
	ring.outer_radius = .14
	ring.rings = 20
	ring.ring_segments = 12
	preview.mesh = ring
	preview.rotation.x = PI/2
	preview.material_override = material(Color(.2,1,.65),.6)
	preview.visible = false
	add_child(preview)
	return preview

func connection_handle(endpoint: int) -> XRToolsPickable:
	return bond_handle if endpoint==1 else bond_start_handle

func begin_connection(endpoint: int = 1) -> void:
	held_ends[endpoint] = true
	bond_held = true
	caption.text = "THE CONNECTION IS LOOSE\nBring its end to a gold joint."

func connection_candidate(endpoint: int = 1) -> int:
	var handle := connection_handle(endpoint)
	if not is_instance_valid(handle): return -1
	var point := to_local(handle.global_position)
	var nearest := -1
	var distance := SNAP_DISTANCE
	for i in range(targets.size()):
		var d := point.distance_to(targets[i])
		if d < distance:
			distance = d
			nearest = i
	# Compare with the other end's last released joint, not its unfinished drag.
	var other: int = pairs[bond_index][1-endpoint]
	if nearest < 0 or nearest == other: return -1
	for i in range(pairs.size()):
		if i == bond_index: continue
		var edge := pairs[i]
		if (edge.x==other and edge.y==nearest) or (edge.y==other and edge.x==nearest): return -1
	return nearest

func finish_connection(endpoint: int = 1) -> void:
	if not held_ends.has(endpoint): return
	var candidate := connection_candidate(endpoint)
	held_ends.erase(endpoint)
	bond_held = not held_ends.is_empty()
	if candidate >= 0 and candidate != pairs[bond_index][endpoint]:
		if endpoint==1:
			pairs[bond_index].y = candidate
		else:
			pairs[bond_index].x = candidate
		edit_count += 1
		last_keep_error = Store.keep(get_tree(),_record())
		caption.text = "SAME POINTS. ANOTHER RELATION.\n" + ("Connection kept for the final hall." if last_keep_error==OK else "Connection kept for this session only.")
	else:
		caption.text = "THE CONNECTION RETURNS\nRelease at another joint to change it."
	_update_connection()
	_update_rods()

func _update_connection() -> void:
	if not is_instance_valid(bond_handle): return
	for endpoint in [0,1]:
		var handle := connection_handle(endpoint)
		var preview := bond_preview if endpoint==1 else bond_start_preview
		if not held_ends.has(endpoint):
			var offset := COLLAR_OFFSET
			if endpoint==0: offset.x = -offset.x
			handle.global_position = to_global(targets[pairs[bond_index][endpoint]]+offset)
			preview.visible = false
			continue
		var point := to_local(handle.global_position).clamp(Vector3(-REACH.x,.12,-REACH.z),REACH)
		handle.global_position = to_global(point)
		var candidate := connection_candidate(endpoint)
		preview.visible = candidate >= 0
		if candidate >= 0: preview.position = targets[candidate]

func material(color: Color, glow: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = .45
	mat.roughness = .3
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = glow
	return mat

func begin_edit(index: int) -> void:
	active[index] = targets[index]

func finish_edit(index: int) -> void:
	store_joint(index)
	var changed: bool = active.has(index) and targets[index].distance_to(active[index]) > .01
	active.erase(index)
	if changed:
		edit_count += 1
		last_keep_error = Store.keep(get_tree(),_record())
		caption.text = "LEAVE A BODY DIFFERENT\n" + ("Pose kept for the final hall." if last_keep_error==OK else "Pose kept for this session only.")

func _record() -> Dictionary:
	var nodes: Array = []
	var edges: Array = []
	var start_edges: Array = []
	for i in range(names.size()):
		var a := original[i]
		# A second held hand is not yet a released decision.
		var b: Vector3 = active.get(i, targets[i])
		nodes.append({"id":names[i],"radius":radii[i],"start":[a.x,a.y,a.z],"end":[b.x,b.y,b.z]})
	for pair in pairs: edges.append([names[pair.x],names[pair.y]])
	for pair in original_pairs: start_edges.append([names[pair.x],names[pair.y]])
	return {"schema":2,"source_map":"AdvancedLaboratory_Lab_Equipment_Simulation",
		"assembly":"VRBody","source_hash":FileAccess.get_sha256(DATA),"nodes":nodes,
		"edges":edges,"start_edges":start_edges,"completed_edits":edit_count}

func _restore_pose() -> void:
	var record := Store.read(get_tree())
	if record.is_empty() or record.source_hash != FileAccess.get_sha256(DATA): return
	var saved: Dictionary = {}
	for node in record.nodes: saved[node.id] = node.end
	# A matching source hash is necessary; verify names too before changing anything.
	for id in names:
		if not saved.has(id): return
	# This workshop currently opens one edge. Keep its authored index stable on reload.
	var restored_pairs: Array[Vector2i] = []
	for edge in record.edges:
		if not names.has(edge[0]) or not names.has(edge[1]): return
		restored_pairs.append(Vector2i(names.find(edge[0]),names.find(edge[1])))
	for i in range(pairs.size()):
		if i!=bond_index and restored_pairs[i]!=original_pairs[i]: return
	pairs.assign(restored_pairs)
	for i in range(names.size()):
		joints[i].position = Store.vector(saved[names[i]])
		store_joint(i)
	edit_count = int(record.get("completed_edits",0))
	caption.text = "LEAVE A BODY DIFFERENT\nLast kept pose restored. Take a joint."

func store_joint(index: int) -> void:
	var handle := joints[index]
	var point := to_local(handle.global_position)
	# This is a finite workspace, not an anatomy constraint. No limb length is enforced.
	point = point.clamp(Vector3(-REACH.x,.12,-REACH.z), REACH)
	handle.global_position = to_global(point)
	targets[index] = to_local(handle.global_position)

func _process(_delta: float) -> void:
	# Poll position as well as using hooks: the desktop pointer moves a frozen body.
	for i in range(joints.size()):
		store_joint(i)
	_update_connection()
	_update_rods()

func _update_rods() -> void:
	for i in range(pairs.size()):
		var a := targets[pairs[i].x]
		var b := targets[pairs[i].y]
		if i==bond_index:
			if held_ends.has(0): a = to_local(bond_start_handle.global_position)
			if held_ends.has(1): b = to_local(bond_handle.global_position)
		var direction := b - a
		rods[i].visible = direction.length() > .001
		if not rods[i].visible: continue
		rods[i].position = (a+b)*.5
		var up := Vector3.RIGHT if absf(direction.normalized().dot(Vector3.UP)) > .99 else Vector3.UP
		rods[i].basis = Basis.looking_at(direction.normalized(),up) * Basis(Vector3.RIGHT,PI/2)
		(rods[i].mesh as CylinderMesh).height = direction.length()
		if i==bond_index:
			var mat := rods[i].material_override as StandardMaterial3D
			var reversed := Vector2i(original_pairs[i].y,original_pairs[i].x)
			mat.albedo_color = Color(.12,.85,.8) if bond_held or (pairs[i]!=original_pairs[i] and pairs[i]!=reversed) else Color(.85,.77,.57)

func reset_pose() -> void:
	# Exposed for authoring/tests. Do not interrupt a visitor who is holding a joint.
	if not active.is_empty() or bond_held: return
	for i in range(joints.size()):
		joints[i].position = original[i]
		targets[i] = original[i]
	pairs.assign(original_pairs)
	_update_connection()
	_update_rods()
	caption.text = "LEAVE A BODY DIFFERENT\nTake a joint. Or move a connection."

func export_pose() -> Dictionary:
	var positions: Dictionary = {}
	for i in range(names.size()):
		var p: Vector3 = active.get(i,targets[i])
		positions[names[i]] = [p.x,p.y,p.z]
	return {"assembly":"VRBody", "positions":positions,"completed_edits":edit_count,
		"edges":_record().edges,"scope":"Latest released coordinates and both ends of one reroutable connection; thirteen joints retained."}
