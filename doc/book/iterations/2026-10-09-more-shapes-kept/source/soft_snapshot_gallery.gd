extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Three controlled comparisons built from the existing frozen vessel.
const Vessel = preload("res://commons/artifacts/frozen_glass_vessel/frozen_glass_vessel.gd")
const Handle = preload("capture_point.gd")
@export_enum("time", "gravity", "skin") var study := "time"
var display: Node3D
var specimens: Array = []
var wires: Array[MultiMeshInstance3D] = []
var point: XRToolsPickable
var variant := 0
var pull := 2.0
var was_held := false
var builds := 0
var home := Vector3(0, 1.13, 1.72)
var sample_steps: Array[int] = []
var gravity_values: Array[float] = []
var ready_for_input := false
const TITLES := {"time":"FOUR MOMENTS / ONE RECIPE", "gravity":"THE SAME STOP / ANOTHER PULL", "skin":"ONE SURFACE / TWO READINGS"}

func _ready() -> void:
	study = str(get_meta("config_study", study))
	if study not in TITLES: study = "time"
	_small_controls()
	point = Handle.new(); point.position = home; add_child(point)
	point.action_pressed.connect(func(_source):
		if study != "gravity": act("CHANGE"))
	label(TITLES[study], Vector3(0,3.35,-0.1), 0.0027)
	box(Vector3(0,0.015,0.4), Vector3(9 if study=="time" else 7,0.025,3.2), material("dfc8d0"))
	_rebuild()
	ready_for_input = true
	refresh()

func _small_controls() -> void:
	box(Vector3(0,0.95,1.65),Vector3(1.8,0.12,0.5),material("26313a"),true)
	box(Vector3(0,0.45,1.65),Vector3(0.18,0.9,0.4),material("26313a"),true)
	for id in ["CHANGE","RESET"]:
		var button = PUSH.instantiate();button.position=Vector3(-0.55 if id=="CHANGE" else 0.55,1.045,1.72);add_child(button);buttons[id]=button
		button.pressed.connect(act.bind(id))
		var caption := label(id,button.position+Vector3(0,0.035,0.14),0.0011);caption.rotation_degrees.x=-55
	readout=label("",Vector3(0,1.43,1.42),0.0011)
	box(Vector3(0,1.43,1.38),Vector3(2.2,0.45,0.055),material("15232c"))

func apply_grid_config(config: Dictionary) -> void:
	if config.has("study") and str(config.study) in TITLES and study != str(config.study):
		study = str(config.study)
		if is_node_ready(): _rebuild(); refresh()

func _physics_process(_delta: float) -> void:
	if not ready_for_input: return
	var held: bool = point.held()
	if study == "gravity" and held:
		pull = snappedf(clampf(absf(to_local(point.global_position).x) * 4.0, 0.0, 4.0),0.1)
		readout.text = "PULL %.1f / release to reconstruct\nLeft and right copies receive opposite pulls" % pull
	if was_held and not held:
		if study == "gravity": _rebuild()
		point.global_position = to_global(home)
		refresh()
	was_held = held

func act(id: String) -> void:
	if not ready_for_input: return
	if id == "RESET":
		variant = 0; pull = 2.0
	else:
		if study == "gravity": pull = 4.0 if pull < 3.0 else 0.0
		elif study == "time": variant = 1 - variant
		else: variant = (variant + 1) % 3
	if study == "skin": _set_skin_view()
	else: _rebuild()
	if not point.held(): point.position = home
	refresh()

func refresh() -> void:
	match study:
		"time": readout.text = "Steps: %s\nPoint trigger / CHANGE stops" % str(sample_steps)
		"gravity": readout.text = "Step 200 / pulls: -%.1f, 0, +%.1f\nPull point sideways / release" % [pull,pull]
		"skin": readout.text = "Right: %s / same contact skin\nPoint trigger / CHANGE view" % ["skin + edges","skin only","edges only"][variant]
	buttons.CHANGE.set_selected(variant != 0 if study != "gravity" else not is_equal_approx(pull,2.0))

func _rebuild() -> void:
	if is_instance_valid(display): remove_child(display); display.queue_free()
	display = Node3D.new(); display.name = "Specimens"; add_child(display)
	specimens.clear(); wires.clear(); sample_steps.clear(); gravity_values.clear()
	var steps: Array = [0,10,40,200] if variant == 0 else [20,60,120,400]
	var count := 4 if study == "time" else (3 if study == "gravity" else 2)
	for i in count:
		var vessel = Vessel.new()
		vessel.show_label = false
		vessel.sim_steps = steps[i] if study == "time" else 200
		vessel.gravity_x = (i-1)*pull if study == "gravity" else 0.0
		vessel.vessel_color = Color("c98298" if study == "time" else ("b0c9c0" if study == "gravity" else "e6d9c5"))
		vessel.emission_boost = 0.15
		vessel.position = Vector3((i-(count-1)*0.5)*2.1,0.42,0)
		display.add_child(vessel); specimens.append(vessel)
		sample_steps.append(vessel.sim_steps); gravity_values.append(vessel.gravity_x)
		box(Vector3(vessel.position.x,0.2,0),Vector3(1.55,0.4,1.55),material("292632"),true,display)
		var caption := label("STEP %d" % vessel.sim_steps if study != "gravity" else "PULL %+.1f" % vessel.gravity_x,Vector3(vessel.position.x,0.28,0.8),0.00115)
		# These labels belong to the replaceable exhibit, not the permanent controls.
		caption.reparent(display, true)
		if study == "skin":
			var wire := _wire_mesh(vessel._mi.mesh)
			wire.position = vessel._mi.position
			vessel.add_child(wire); wires.append(wire)
	if study == "skin": _set_skin_view()
	builds += 1

func _set_skin_view() -> void:
	if specimens.size() != 2: return
	specimens[0]._mi.visible = true; wires[0].visible = false
	specimens[1]._mi.visible = variant != 2; wires[1].visible = variant != 1

func _wire_mesh(mesh: ArrayMesh) -> MultiMeshInstance3D:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var edges: Dictionary = {}
	for t in range(0, indices.size(),3):
		for pair in [[indices[t],indices[t+1]],[indices[t+1],indices[t+2]],[indices[t+2],indices[t]]]:
			var a: int = mini(pair[0],pair[1]); var b: int = maxi(pair[0],pair[1])
			if vertices[a].distance_to(vertices[b]) > 0.0001: edges[Vector2i(a,b)] = true
	var cylinder := CylinderMesh.new(); cylinder.top_radius=0.004; cylinder.bottom_radius=0.004; cylinder.height=1.0; cylinder.radial_segments=6
	var multi := MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.mesh=cylinder; multi.instance_count=edges.size()
	var at := 0
	for edge: Vector2i in edges:
		var a := vertices[edge.x]; var b := vertices[edge.y]; var d := b-a
		var turn := Basis(Quaternion(Vector3.UP,d.normalized()))
		var stretched := Basis(turn.x,turn.y*d.length(),turn.z)
		multi.set_instance_transform(at,Transform3D(stretched,(a+b)*0.5)); at+=1
	var node := MultiMeshInstance3D.new(); node.multimesh=multi; node.material_override=material("422736"); return node
