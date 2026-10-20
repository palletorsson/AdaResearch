extends Node3D
## Opt-in experiment in the existing museum. Surfaces are visual, never colliders.
signal experiment_updated(measurements: Dictionary)
const Sample = preload("res://commons/artifacts/geometry_noise/surface_sample.gd")
const Console = preload("res://commons/ui/control_console.gd")
const DEFAULT_STRENGTH := 0.18
const DEFAULT_SEED := 1847
const SPACING := 2.7
const SURFACE_Y := 1.35
var normalized_strength: float = DEFAULT_STRENGTH
var experiment_seed: int = DEFAULT_SEED
var sample = Sample.new()
var reference: MeshInstance3D
var perturbed: MeshInstance3D
var reference_edges: MeshInstance3D
var changed_edges: MeshInstance3D
var readout: Label3D
var console: Node3D
var slider: Node3D
var buttons: Dictionary = {}
var measurements: Dictionary = {}
var rebuild_count := 0
var last_rebuild_usec := 0
var wire_visible := true
var log_entries: Array[Dictionary] = []
var _built := false

func _ready() -> void:
	name = "GeometryNoiseTest"
	sample.resample(experiment_seed)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("eee8db")
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1, 1]:
		var body := MeshInstance3D.new()
		body.position = Vector3(side * SPACING * 0.5, SURFACE_Y, 0.0)
		body.material_override = material
		add_child(body)
		var edges := MeshInstance3D.new()
		body.add_child(edges)
		var ink := StandardMaterial3D.new()
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.albedo_color = Color("343b46")
		edges.material_override = ink
		edges.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if side == -1:
			reference = body; reference_edges = edges
		else:
			perturbed = body; changed_edges = edges
		plinth(Vector3(side * SPACING * 0.5, 0.15, 0.0))
		plate("REFERENCE / FIXED" if side == -1 else "SAME CONNECTIONS / MOVED POINTS",
			Vector3(side * SPACING * 0.5, 0.34, 1.08), Vector2(2.1,0.2), 27, 0.0018)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(side * SPACING * 0.5, 2.9, 0.8)
		lamp.light_energy = 1.1; lamp.omni_range = 4.0
		add_child(lamp)
	reference.mesh = sample.mesh_for(sample.base)
	reference_edges.mesh = edges_for(sample.base)
	plate("THE UNCERTAIN SURFACE", Vector3(0,2.65,-1.3),Vector2(3.8,.35),48,.0019)
	readout = plate("",Vector3(0,2.06,-1.3),Vector2(3.8,.76),42,.002)
	console = Console.new()
	console.name = "ExperimentControls"
	console.auto_demo = false
	console.face_to_origin = false
	console.body_height = 0.82
	console.board_width = 1.75
	console.position = Vector3(0,0,1.85)
	add_child(console)
	console.set_title("SAME SAMPLE / CHANGE ITS STRENGTH")
	slider = console.add_slider("STRENGTH", "strength")
	slider.set_normalized_value(normalized_strength)
	slider.slider_moved.connect(_slider_changed)
	for id in ["NEXT SEED", "ZERO", "RESET", "EDGES"]:
		var button = console.add_button(id)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
	_built = true
	_rebuild("initial")

func _slider_changed(_value: Variant) -> void:
	set_noise_strength(slider.get_normalized_value())

func set_noise_strength(value: float) -> void:
	if not is_finite(value): return
	var clean := clampf(value, 0.0, 1.0)
	if is_equal_approx(clean, normalized_strength): return
	normalized_strength = clean
	if _built:
		slider.set_normalized_value(clean)
		_rebuild("strength")

func set_experiment_seed(value: int) -> void:
	if value == experiment_seed: return
	experiment_seed = value
	sample.resample(value)
	if _built: _rebuild("seed")

func resample() -> void:
	set_experiment_seed(0 if experiment_seed == 9223372036854775807 else experiment_seed + 1)

func reset_experiment() -> void:
	normalized_strength = DEFAULT_STRENGTH
	experiment_seed = DEFAULT_SEED
	sample.resample(experiment_seed)
	if _built:
		slider.set_normalized_value(normalized_strength)
		wire_visible = true
		reference_edges.visible = true; changed_edges.visible = true
		_rebuild("reset")

func show_baseline() -> void:
	set_noise_strength(0.0)

func act(id: String) -> void:
	match id:
		"NEXT SEED": resample()
		"ZERO": show_baseline()
		"RESET": reset_experiment()
		"EDGES":
			wire_visible = not wire_visible
			reference_edges.visible = wire_visible; changed_edges.visible = wire_visible

func _rebuild(reason: String) -> void:
	var start := Time.get_ticks_usec()
	measurements = sample.evaluate(normalized_strength)
	perturbed.mesh = sample.mesh_for(measurements.positions)
	changed_edges.mesh = edges_for(measurements.positions)
	rebuild_count += 1
	last_rebuild_usec = Time.get_ticks_usec() - start
	readout.text = ("Seed %d   /   strength %.2f   /   sigma %.2f cm per axis\n"
		+ "Measured RMS %.2f cm   /   largest move %.2f cm\n"
		+ "Centroid drift %.2f cm   /   population RMS %.2f cm\n"
		+ "289 vertices / 512 triangles   -   surface collision OFF") % [
			experiment_seed,normalized_strength,measurements.sigma_m*100,
			measurements.rms_m*100,measurements.maximum_m*100,
			measurements.centroid_drift_m*100,measurements.population_rms_m*100]
	log_entries.append({"event":reason,"seed":experiment_seed,"strength":normalized_strength,
		"sigma_m":measurements.sigma_m,"rms_m":measurements.rms_m,"maximum_m":measurements.maximum_m,
		"centroid_drift_m":measurements.centroid_drift_m,"engine":Engine.get_version_info().string,
		"rebuild_usec":last_rebuild_usec})
	if log_entries.size() > 64: log_entries.pop_front()
	experiment_updated.emit(measurements.duplicate(true))

func edges_for(positions: PackedVector3Array) -> ArrayMesh:
	var lines := PackedVector3Array()
	var seen: Dictionary = {}
	for i in range(0,sample.indices.size(),3):
		for j in 3:
			var a: int = sample.indices[i+j]
			var b: int = sample.indices[i+(j+1)%3]
			var pair := Vector2i(mini(a,b),maxi(a,b))
			if seen.has(pair): continue
			seen[pair] = true
			lines.append(positions[a]+Vector3.UP*.002)
			lines.append(positions[b]+Vector3.UP*.002)
	var arrays: Array = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = lines
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES,arrays)
	return mesh

func plinth(at: Vector3) -> void:
	var body := StaticBody3D.new(); body.position = at
	body.collision_layer = 1; body.collision_mask = 0
	add_child(body)
	var box := BoxMesh.new(); box.size = Vector3(2.18,.3,2.18)
	var visual := MeshInstance3D.new(); visual.mesh = box
	var material := StandardMaterial3D.new(); material.albedo_color = Color("d8d3ca")
	visual.material_override = material; body.add_child(visual)
	var shape := CollisionShape3D.new(); var collision := BoxShape3D.new()
	collision.size = box.size; shape.shape = collision; body.add_child(shape)

func plate(text: String, at: Vector3, size: Vector2, font: int, pixels: float) -> Label3D:
	var backing := MeshInstance3D.new()
	var box := BoxMesh.new(); box.size = Vector3(size.x,size.y,.045)
	backing.mesh = box; backing.position = at
	var material := StandardMaterial3D.new(); material.albedo_color = Color("202932")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backing.material_override = material; add_child(backing)
	var label := Label3D.new(); label.text = text
	label.font_size = font; label.pixel_size = pixels
	label.position.z = .026; label.outline_size = 0
	label.modulate = Color("fff2da"); label.no_depth_test = false
	backing.add_child(label)
	return label
