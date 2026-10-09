extends Node3D
## Opt-in, body-size editing beside MolecularDesigner's authored cycle.
## Same VRBody nodes and edges; moving a joint changes geometry, not adjacency.
const JointScript = preload("res://algorithms/computationalbiology/molecular_framework/AssemblyJoint.gd")
const BODY_SCALE := 1.12
const REACH := Vector3(1.9, 2.35, 1.9)
var joints: Array[XRToolsPickable] = []
var targets: Array[Vector3] = []
var original: Array[Vector3] = []
var pairs: Array[Vector2i] = []
var rods: Array[MeshInstance3D] = []
var active: Dictionary = {}
var names: Array[String] = []
var edit_count := 0
var caption: Label3D

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
		var rod := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = .028
		cylinder.bottom_radius = .028
		cylinder.radial_segments = 12
		rod.mesh = cylinder
		rod.material_override = material(Color(.85,.77,.57), .08)
		add_child(rod)
		rods.append(rod)
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
	caption.text = "LEAVE A BODY DIFFERENT\nTake a joint. Let it stay."
	caption.font_size = 34
	caption.pixel_size = .003
	caption.position = Vector3(0,2.65,-1.3)
	caption.modulate = Color(.94,.8,.58)
	caption.outline_size = 4
	caption.double_sided = true
	add_child(caption)
	_update_rods()

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
	if active.has(index) and targets[index].distance_to(active[index]) > .01:
		edit_count += 1
	active.erase(index)

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
	_update_rods()

func _update_rods() -> void:
	for i in range(pairs.size()):
		var a := targets[pairs[i].x]
		var b := targets[pairs[i].y]
		var direction := b - a
		rods[i].visible = direction.length() > .001
		if not rods[i].visible: continue
		rods[i].position = (a+b)*.5
		var up := Vector3.RIGHT if absf(direction.normalized().dot(Vector3.UP)) > .99 else Vector3.UP
		rods[i].basis = Basis.looking_at(direction.normalized(),up) * Basis(Vector3.RIGHT,PI/2)
		(rods[i].mesh as CylinderMesh).height = direction.length()

func reset_pose() -> void:
	# Exposed for authoring/tests. Do not interrupt a visitor who is holding a joint.
	if not active.is_empty(): return
	for i in range(joints.size()):
		joints[i].position = original[i]
		targets[i] = original[i]
	_update_rods()

func export_pose() -> Dictionary:
	var positions: Dictionary = {}
	for i in range(names.size()):
		var p := targets[i]
		positions[names[i]] = [p.x,p.y,p.z]
	return {"assembly":"VRBody", "positions":positions,"completed_edits":edit_count,
		"scope":"Current hall visit; adjacency and catalogue unchanged."}
