extends Node3D
## The record becomes two standing bodies: source pose and the last pose kept by a visitor.
## No invented visitor pose on a direct start; the amber bay remains empty.
const Store = preload("res://algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd")
const DATA := "res://algorithms/computationalbiology/molecular_framework/assemblies.json"
const BLUE := Color(.44,.73,.88)
const AMBER := Color(.95,.57,.21)
var _revision := "unbuilt"
var _elapsed := 0.0
var bodies: Node3D
var status: Label3D
var record: Dictionary = {}

func _ready() -> void:
	var start_label := label("STARTING POSE",Vector3(-2.35,2.65,0),BLUE)
	add_child(start_label)
	add_child(label("LAST KEPT POSE",Vector3(2.35,2.65,0),AMBER))
	status = label("",Vector3(0,.65,.35),Color(.8,.85,.9))
	status.font_size = 24
	status.pixel_size = .0025
	add_child(status)
	bodies = Node3D.new()
	bodies.name = "RecordedBodies"
	add_child(bodies)
	refresh()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 1.0:
		_elapsed = 0.0
		refresh()

func refresh() -> void:
	record = Store.read(get_tree())
	var revision: String = str(record.get("revision","empty"))
	if revision == _revision: return
	_revision = revision
	for child in bodies.get_children():
		bodies.remove_child(child)
		child.queue_free()
	if record.is_empty():
		_draw_body(_starting_record(),"start",Vector3(-2.35,0,0),BLUE)
		status.text = "NO POSE KEPT YET\nLeave a joint elsewhere in the Assembly Laboratory."
		return
	_draw_body(record,"start",Vector3(-2.35,0,0),BLUE)
	_draw_body(record,"end",Vector3(2.35,0,0),AMBER)
	status.text = "%d joints moved · 13 joints / 12 connections\n%s · path of the hand not recorded" % [Store.changed(record),record.get("persistence","this session only")]

func _starting_record() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var result := {"nodes":[],"edges":data.assemblies.VRBody.bonds}
	for node in data.assemblies.VRBody.nodes:
		var p := Store.vector(node.pos)*float(data.assemblies.VRBody.scale)*1.12
		result.nodes.append({"id":node.id,"radius":float(data.catalog[node.part].radius)*1.12,"start":[p.x,p.y,p.z]})
	return result

func _draw_body(data: Dictionary, key: String, offset: Vector3, color: Color) -> void:
	var figure := Node3D.new()
	figure.name = "StartingPose" if key=="start" else "KeptPose"
	figure.position = offset
	bodies.add_child(figure)
	var points: Dictionary = {}
	for node in data.nodes:
		var p := Store.vector(node[key])
		points[node.id] = p
		var ball := SphereMesh.new()
		ball.radius = float(node.radius)
		ball.height = ball.radius*2
		ball.radial_segments = 20
		ball.rings = 10
		var mesh := MeshInstance3D.new()
		mesh.name = str(node.id)
		mesh.mesh = ball
		mesh.position = p
		mesh.material_override = material(color)
		figure.add_child(mesh)
	for edge in data.edges:
		var a: Vector3 = points[edge[0]]
		var b: Vector3 = points[edge[1]]
		var delta := b-a
		if delta.length()<.001: continue
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = .028
		cylinder.bottom_radius = .028
		cylinder.height = delta.length()
		cylinder.radial_segments = 12
		var mesh := MeshInstance3D.new()
		mesh.mesh = cylinder
		mesh.position = (a+b)*.5
		var up := Vector3.RIGHT if absf(delta.normalized().dot(Vector3.UP))>.99 else Vector3.UP
		mesh.basis = Basis.looking_at(delta.normalized(),up)*Basis(Vector3.RIGHT,PI/2)
		mesh.material_override = material(color.lightened(.15))
		figure.add_child(mesh)

func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = .45
	mat.roughness = .3
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = .15
	return mat

func label(text: String, pos: Vector3, color: Color) -> Label3D:
	var result := Label3D.new()
	result.text = text
	result.position = pos
	result.font_size = 34
	result.pixel_size = .003
	result.modulate = color
	result.outline_size = 4
	result.double_sided = true
	return result

func apply_grid_config(_config: Dictionary) -> void:
	pass
