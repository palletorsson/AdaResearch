# Keep the connections; move the positions

**Companion experiment — Random_Noise_Types / Noise opening**

Learning elements:

- A saved original and a changed copy
- Independent Gaussian displacement in three dimensions
- Seed and generator call order
- Fixed-sample amplitude comparison
- Indexed connectivity versus geometric position
- RMS, maximum displacement and centroid drift

Walk to the two pale surfaces. The reference stays level. Move the nearby slider. The other surface changes without drawing new offsets. ZERO returns it to the reference; RESET returns to the opening variation. NEXT SEED supplies a different set of offsets.

Bring the position and face arrays from Primitives and the local seeded generator from Randomness. This optional study adds one operation: `changed[i] = original[i] + saved_noise[i] * sigma`. The two arrays must remain separate. We always calculate from the original, so dragging a control back returns to the same shape instead of accumulating a random walk.

The unit vectors are three independent Gaussian samples per vertex. At strength 0.18, `sigma = 0.18 * 0.25` metres. Sigma describes the distribution per axis, not a maximum or a chance of failure. Do not clip the draws or remove their finite-sample average without declaring another experiment.

The reported RMS is `sqrt(sum(displacement.length_squared()) / vertex_count)`. The maximum is a separate observation. Centroid drift measures the mean displacement vector's length. `sqrt(3) * sigma` is the population RMS; it is displayed separately from the measurement of 289 points.

## Complete files

Use the existing Ada project and its prepared museum environment. Create these three files at `res://commons/artifacts/geometry_noise/`. The root scene builds its two meshes, labels and plinths in code. `ControlConsole` and its XR Tools slider/buttons are supplied museum infrastructure; they are not missing learner mesh construction. A bare project without these controls is not the stated host.

`surface_sample.gd` owns the record and calculation. `GeometryNoiseTest.gd` supplies the encounter. `ArrayMesh` keeps one indexed entry for each of the 289 vertices; normals are recomputed by accumulating face contributions. The edge overlay is a separate drawing, not additional topology. [Godot 4.6: ArrayMesh](https://docs.godotengine.org/en/4.6/classes/class_arraymesh.html)

### surface_sample.gd

```gdscript
extends RefCounted
## One saved Gaussian vector per logical vertex. No scene/global RNG mutation.
const SEGMENTS := 16
const SIZE_M := 2.0
const MAX_SIGMA_M := 0.25
var base := PackedVector3Array()
var indices := PackedInt32Array()
var unit_noise := PackedVector3Array()
var sample_seed: int = 1847

func _init() -> void:
	for z in range(SEGMENTS + 1):
		for x in range(SEGMENTS + 1):
			base.append(Vector3(float(x) / SEGMENTS - 0.5, 0.0, float(z) / SEGMENTS - 0.5) * SIZE_M)
	for z in range(SEGMENTS):
		for x in range(SEGMENTS):
			var a := z * (SEGMENTS + 1) + x
			var b := a + 1
			var c := a + SEGMENTS + 1
			var d := c + 1
			# Clockwise from above: Godot's front face convention.
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	resample(sample_seed)

func resample(value: int) -> void:
	sample_seed = value
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	unit_noise.clear()
	for i in base.size():
		unit_noise.append(Vector3(rng.randfn(), rng.randfn(), rng.randfn()))

func evaluate(strength: float) -> Dictionary:
	var amount := clampf(strength, 0.0, 1.0) if is_finite(strength) else 0.0
	var sigma := amount * MAX_SIGMA_M
	var positions := PackedVector3Array()
	var sum_squared := 0.0
	var maximum := 0.0
	var centroid := Vector3.ZERO
	for i in base.size():
		var displacement: Vector3 = unit_noise[i] * sigma
		positions.append(base[i] + displacement)
		# Measure the stored coordinates, including their float32 rounding.
		var measured: Vector3 = positions[i] - base[i]
		sum_squared += measured.length_squared()
		maximum = maxf(maximum, measured.length())
		centroid += measured
	centroid /= float(base.size())
	return {"positions":positions, "seed":sample_seed, "strength":amount,
		"sigma_m":sigma, "population_rms_m":sqrt(3.0)*sigma,
		"rms_m":sqrt(sum_squared / base.size()), "maximum_m":maximum,
		"centroid_drift_m":centroid.length(), "centroid_vector":centroid,
		"vertices":base.size(), "triangles":indices.size()/3}

func mesh_for(positions: PackedVector3Array) -> ArrayMesh:
	assert(positions.size() == base.size())
	var normals := PackedVector3Array()
	normals.resize(base.size())
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i+1]
		var c := indices[i+2]
		var normal := (positions[c]-positions[a]).cross(positions[b]-positions[a])
		normals[a] += normal
		normals[b] += normal
		normals[c] += normal
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 1e-18 else Vector3.UP
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices.duplicate()
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
```

### GeometryNoiseTest.gd

```gdscript
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
```

### GeometryNoiseTest.tscn

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://commons/artifacts/geometry_noise/GeometryNoiseTest.gd" id="1"]

[node name="GeometryNoiseTest" type="Node3D"]
script = ExtResource("1")
```

## Check what travelled

1. Keep seed 1847. Predict the RMS at strength 0.09 from the opening measurement, then test it. The fixed sample makes the scaling prediction possible.
2. Return to 0.18. Check that the coordinates return, not just the silhouette.
3. Change seed. Can you still predict the exact maximum from the previous shape? Explain why the shared distribution does not supply that number.
4. Hide the edge overlay. Has the mesh's index array changed, or only its visible aid?

The ordinary case is a 289-vertex, 512-triangle indexed surface. A nonintersecting geometric shape is a separate property: fixed connectivity does not guarantee it. No failure threshold is asserted in this lesson.

The local test command is `python -X utf8 tools/test_geometry_noise.py`. It checks actual mesh arrays, normals, metric calculations, seed replay, proportional scaling, isolated RNG, reset, controls and idle behaviour. The museum probe separately exercises pointer buttons, held XR Tools slider poses and approach clearance. These are runtime checks, not a claim that a human student or a physical headset has completed the lesson.

The next Noise halls can return to this distinction: a source supplies values; an operation gives them colour, displacement or occupancy. Here the offsets are independent. A correlated spatial field introduces another relationship.
