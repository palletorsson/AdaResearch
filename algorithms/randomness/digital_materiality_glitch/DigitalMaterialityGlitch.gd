# @identity
# essence: error as aesthetic — corruption rendered as form
# desire: watch a clean digital grid degrade into datamosh, scan-lines, chromatic-shift, overflow
# critical_parameter: corruption_rate — how fast cells flip from intact to glitched
# triggers: glitch_timer cycles populate MultiMesh transforms each frame; error_cascade propagates through neighbors
# emerges: a visual ledger of digital pathologies — 64-cell data grid speckled with compression artifacts and pixel-sort streaks
# needs: corruption_rate slider [missing]; reset button [missing]; cascade speed control [missing]
# relationships: kin to noise visualizations but biased — distortion has direction; sibling to digital_archaeology that reads ruins
# truth: A glitch is not failure; it is the substrate making itself visible. Randomness with a wound becomes signature.

extends Node3D

# Digital Materiality & Glitch Visualization
# Demonstrates error as aesthetic and digital artifact generation
# Optimized: uses MultiMesh instead of per-frame CSG node creation

var time := 0.0
var glitch_timer := 0.0
var corruption_rate := 0.05

# Glitch parameters
var glitch_intensity := 0.3
var artifact_probability := 0.1
var error_propagation_speed := 2.0

# Digital structures
var data_grid := []
var corrupted_elements := []
var error_cascade := []

# === MultiMesh references (GlitchAesthetics) ===
var mm_datamosh: MultiMeshInstance3D       # 16 cylinders
var mm_pixel_sort: MultiMeshInstance3D     # 12 boxes
var mm_channel_shift: MultiMeshInstance3D  # 27 boxes
var mm_compression: MultiMeshInstance3D    # 16 boxes

# === MultiMesh references (DataCorruption) ===
var mm_data_grid: MultiMeshInstance3D      # 64 boxes

# === MultiMesh references (DigitalArtifacts) ===
var mm_scan_lines: MultiMeshInstance3D     # 20 boxes
var mm_chromatic: MultiMeshInstance3D      # 3 spheres
var mm_noise: MultiMeshInstance3D          # 50 boxes
var mm_overflow: MultiMeshInstance3D       # 10 boxes

# === MultiMesh references (ErrorPropagation) ===
var mm_error_waves: MultiMeshInstance3D    # 5 cylinders
var mm_error_cascade: MultiMeshInstance3D  # 50 spheres (capped)

# Instance counts
const DATAMOSH_COUNT := 16
const PIXEL_SORT_COUNT := 12
const CHANNEL_SHIFT_COUNT := 27  # 3 channels x 9
const COMPRESSION_COUNT := 16   # 4x4
const DATA_GRID_COUNT := 64     # 8x8
const SCAN_LINE_COUNT := 20
const CHROMATIC_COUNT := 3
const NOISE_COUNT := 50
const OVERFLOW_COUNT := 10
const ERROR_WAVE_COUNT := 5
const ERROR_CASCADE_MAX := 50

# Shared transparent material references (per-multimesh)
var mat_datamosh: StandardMaterial3D
var mat_pixel_sort: StandardMaterial3D
var mat_channel_shift: StandardMaterial3D
var mat_compression: StandardMaterial3D
var mat_data_grid: StandardMaterial3D
var mat_scan_lines: StandardMaterial3D
var mat_chromatic: StandardMaterial3D
var mat_noise: StandardMaterial3D
var mat_overflow: StandardMaterial3D
var mat_error_waves: StandardMaterial3D
var mat_error_cascade: StandardMaterial3D

# Pre-generated random values for stable noise (re-rolled periodically)
var _noise_randf := PackedFloat32Array()
var _noise_colors := PackedColorArray()
var _noise_positions := PackedVector3Array()
var _pixel_sort_randf := PackedFloat32Array()

# RNG for deterministic per-frame randomness where needed
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	initialize_digital_structures()
	_create_all_multimeshes()
	# Pre-roll stable noise
	_reroll_noise()
	_reroll_pixel_sort()

func _process(delta: float) -> void:
	time += delta
	glitch_timer += delta

	update_glitch_parameters()
	_update_glitch_aesthetics()
	_update_data_corruption(delta)
	_update_digital_artifacts()
	_update_error_propagation(delta)

# ─────────────────────────────────────────────
# Initialization helpers
# ─────────────────────────────────────────────

func initialize_digital_structures() -> void:
	data_grid.clear()
	for i in range(8):
		var row = []
		for j in range(8):
			row.append({"intact": true, "value": randi() % 256, "corruption_age": 0.0})
		data_grid.append(row)

func _create_multimesh_instance(parent: Node3D, mesh: Mesh, count: int, use_colors: bool, material: StandardMaterial3D) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = use_colors
	mm.mesh = mesh
	mm.instance_count = count
	# Initialize all instances hidden (zero-scale transform)
	var hidden_xform := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -9999, 0))
	for i in range(count):
		mm.set_instance_transform(i, hidden_xform)
		if use_colors:
			mm.set_instance_color(i, Color.WHITE)
	mmi.multimesh = mm
	mmi.material_override = material
	parent.add_child(mmi)
	return mmi

func _make_transparent_material(base_color: Color, emission_color: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0:
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_energy
	return mat

func _create_all_multimeshes() -> void:
	# ── Meshes ──
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1, 1, 1)  # unit; we scale per-instance

	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.top_radius = 1.0
	cylinder_mesh.bottom_radius = 1.0
	cylinder_mesh.height = 1.0

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0

	# ── Materials ──
	mat_datamosh = _make_transparent_material(Color(1.0, 0.2, 0.8, 0.7), Color(1.0, 0.2, 0.8), 0.5)
	mat_pixel_sort = _make_transparent_material(Color.WHITE, Color.WHITE, 0.3)
	mat_channel_shift = _make_transparent_material(Color.WHITE, Color.WHITE, 0.4)
	mat_compression = _make_transparent_material(Color.WHITE, Color(1.0, 0.0, 1.0), 0.6)
	mat_data_grid = _make_transparent_material(Color.WHITE, Color(1.0, 0.2, 0.2), 0.5)
	mat_scan_lines = _make_transparent_material(Color(0.0, 1.0, 0.0, 0.5), Color(0.0, 1.0, 0.0), 0.5)
	mat_chromatic = _make_transparent_material(Color.WHITE, Color.WHITE, 0.0)
	mat_noise = _make_transparent_material(Color.WHITE, Color.WHITE, 0.8)
	mat_overflow = _make_transparent_material(Color.WHITE, Color(1.0, 0.0, 0.0), 0.8)
	mat_error_waves = _make_transparent_material(Color(1.0, 0.5, 0.0, 0.6), Color(1.0, 0.5, 0.0), 0.5)
	mat_error_cascade = _make_transparent_material(Color(1.0, 0.0, 0.0, 1.0), Color(1.0, 0.0, 0.0), 0.8)

	# ── GlitchAesthetics ──
	var ga := $GlitchAesthetics
	mm_datamosh = _create_multimesh_instance(ga, cylinder_mesh, DATAMOSH_COUNT, true, mat_datamosh)
	mm_pixel_sort = _create_multimesh_instance(ga, box_mesh, PIXEL_SORT_COUNT, true, mat_pixel_sort)
	mm_channel_shift = _create_multimesh_instance(ga, box_mesh, CHANNEL_SHIFT_COUNT, true, mat_channel_shift)
	mm_compression = _create_multimesh_instance(ga, box_mesh, COMPRESSION_COUNT, true, mat_compression)

	# ── DataCorruption ──
	mm_data_grid = _create_multimesh_instance($DataCorruption, box_mesh, DATA_GRID_COUNT, true, mat_data_grid)

	# ── DigitalArtifacts ──
	var da := $DigitalArtifacts
	mm_scan_lines = _create_multimesh_instance(da, box_mesh, SCAN_LINE_COUNT, true, mat_scan_lines)
	mm_chromatic = _create_multimesh_instance(da, sphere_mesh, CHROMATIC_COUNT, true, mat_chromatic)
	mm_noise = _create_multimesh_instance(da, box_mesh, NOISE_COUNT, true, mat_noise)
	mm_overflow = _create_multimesh_instance(da, box_mesh, OVERFLOW_COUNT, true, mat_overflow)

	# ── ErrorPropagation ──
	var ep := $ErrorPropagation
	mm_error_waves = _create_multimesh_instance(ep, cylinder_mesh, ERROR_WAVE_COUNT, true, mat_error_waves)
	mm_error_cascade = _create_multimesh_instance(ep, sphere_mesh, ERROR_CASCADE_MAX, true, mat_error_cascade)

# ─────────────────────────────────────────────
# Stable random values (re-rolled periodically to avoid stale look)
# ─────────────────────────────────────────────

var _noise_reroll_timer := 0.0
var _pixel_sort_reroll_timer := 0.0

func _reroll_noise() -> void:
	_noise_randf.resize(NOISE_COUNT)
	_noise_colors.resize(NOISE_COUNT)
	_noise_positions.resize(NOISE_COUNT)
	for i in range(NOISE_COUNT):
		_noise_randf[i] = _rng.randf()
		_noise_colors[i] = Color(_rng.randf(), _rng.randf(), _rng.randf(), _rng.randf_range(0.5, 1.0))
		_noise_positions[i] = Vector3(
			_rng.randf_range(-4, 4),
			_rng.randf_range(-2, 2),
			_rng.randf_range(-1, 1)
		)

func _reroll_pixel_sort() -> void:
	_pixel_sort_randf.resize(PIXEL_SORT_COUNT)
	for i in range(PIXEL_SORT_COUNT):
		_pixel_sort_randf[i] = _rng.randf()

# ─────────────────────────────────────────────
# Parameter update
# ─────────────────────────────────────────────

func update_glitch_parameters() -> void:
	glitch_intensity = 0.2 + sin(time * 0.4) * 0.3
	artifact_probability = 0.05 + cos(time * 0.6) * 0.04
	error_propagation_speed = 1.5 + sin(time * 0.8) * 1.0

# ─────────────────────────────────────────────
# GlitchAesthetics
# ─────────────────────────────────────────────

func _update_glitch_aesthetics() -> void:
	_update_datamosh()
	_update_pixel_sort()
	_update_channel_shift()
	_update_compression()

func _update_datamosh() -> void:
	var mm := mm_datamosh.multimesh
	var base_pos := Vector3(0 * 3.0 - 6.0, 0, 0)  # index 0 → "datamosh"

	for i in range(DATAMOSH_COUNT):
		var original_pos := base_pos + Vector3(
			(i % 4) * 0.4 - 0.6,
			3,
			(i / 4) * 0.4 - 0.6
		)
		var glitch_offset := Vector3(
			sin(time * 3 + i) * glitch_intensity,
			cos(time * 2 + i) * glitch_intensity,
			sin(time * 4 + i) * glitch_intensity * 0.5
		)

		# Random-looking but deterministic rotation based on time + index
		var rx := sin(time * 1.7 + i * 0.93) * PI
		var ry := cos(time * 1.3 + i * 1.27) * PI
		var rz := sin(time * 2.1 + i * 0.71) * PI

		# Cylinder: default height=1, radius=1 → scale to radius=0.05, height=variable
		var h := 0.5 + fmod(abs(sin(time * 0.5 + i * 2.3)) * 1.5, 1.5)
		var s := Vector3(0.05, h, 0.05)

		var basis := Basis.from_euler(Vector3(rx, ry, rz)).scaled(s)
		var xform := Transform3D(basis, original_pos + glitch_offset)
		mm.set_instance_transform(i, xform)
		mm.set_instance_color(i, Color(1.0, 0.2, 0.8, 0.7))

func _update_pixel_sort() -> void:
	var mm := mm_pixel_sort.multimesh
	var base_pos := Vector3(1 * 3.0 - 6.0, 0, 0)  # index 1 → "pixel_sort"

	# Re-roll pixel sort heights periodically for variation
	_pixel_sort_reroll_timer += get_process_delta_time()
	if _pixel_sort_reroll_timer > 0.08:
		_pixel_sort_reroll_timer = 0.0
		_reroll_pixel_sort()

	# Copy and optionally partial-sort
	var pixel_heights := Array(_pixel_sort_randf)
	if _rng.randf() < glitch_intensity:
		var start_idx := _rng.randi() % maxi(1, pixel_heights.size() - 3)
		var end_idx := start_idx + 3
		var segment = pixel_heights.slice(start_idx, end_idx)
		segment.sort()
		for si in range(segment.size()):
			pixel_heights[start_idx + si] = segment[si]

	for i in range(PIXEL_SORT_COUNT):
		var h: float = pixel_heights[i] if i < pixel_heights.size() else 0.5
		var sy := h * 2.0  # box height
		var pos := base_pos + Vector3(
			i * 0.25 - 1.5,
			h,
			0
		)
		var s := Vector3(0.2, maxf(sy, 0.01), 0.2)
		var xform := Transform3D(Basis.IDENTITY.scaled(s), pos)
		mm.set_instance_transform(i, xform)

		var sorted_color := h
		mm.set_instance_color(i, Color(sorted_color, 1.0 - sorted_color, 0.5))

func _update_channel_shift() -> void:
	var mm := mm_channel_shift.multimesh
	var base_pos := Vector3(2 * 3.0 - 6.0, 0, 0)  # index 2 → "channel_shift"

	var offsets := [
		Vector3(0.1, 0, 0) * glitch_intensity,
		Vector3(0, 0, 0),
		Vector3(-0.1, 0, 0) * glitch_intensity
	]
	var channel_colors := [
		Color(1.0, 0.0, 0.0, 0.8),
		Color(0.0, 1.0, 0.0, 0.8),
		Color(0.0, 0.0, 1.0, 0.8)
	]

	var idx := 0
	for channel_idx in range(3):
		for i in range(9):
			var pos: Vector3 = base_pos + Vector3(
				(i % 3) * 0.3 - 0.3,
				(i / 3) * 0.3 - 0.3,
				channel_idx * 0.1 - 0.1
			) + offsets[channel_idx]

			var s := Vector3(0.15, 0.15, 0.15)
			var xform := Transform3D(Basis.IDENTITY.scaled(s), pos)
			mm.set_instance_transform(idx, xform)
			mm.set_instance_color(idx, channel_colors[channel_idx])
			idx += 1

func _update_compression() -> void:
	var mm := mm_compression.multimesh
	var base_pos := Vector3(3 * 3.0 - 6.0, 0, 0)  # index 3 → "compression"

	var idx := 0
	for i in range(4):
		for j in range(4):
			var pos := base_pos + Vector3(
				i * 0.5 - 0.75,
				0,
				j * 0.5 - 0.75
			)

			var artifact_intensity := 0.0
			# Use deterministic "random" per cell per frame
			var noise_val := fmod(abs(sin(time * 3.7 + i * 7.1 + j * 13.3)), 1.0)
			var scale_factor := 1.0
			if noise_val < artifact_probability:
				artifact_intensity = 1.0
				scale_factor = 1.0 + glitch_intensity

			var s := Vector3(0.4, 0.4, 0.4) * scale_factor
			var xform := Transform3D(Basis.IDENTITY.scaled(s), pos)
			mm.set_instance_transform(idx, xform)

			var c := Color(
				0.5 + artifact_intensity * 0.5,
				0.5,
				0.5 + artifact_intensity * 0.5
			)
			if artifact_intensity > 0:
				# Brighter to simulate emission being more visible
				c = Color(1.0, 0.5, 1.0, 1.0)
			mm.set_instance_color(idx, c)
			idx += 1

# ─────────────────────────────────────────────
# DataCorruption
# ─────────────────────────────────────────────

func _update_data_corruption(_delta: float) -> void:
	# Corruption propagation at intervals
	if glitch_timer > 0.1:
		glitch_timer = 0.0
		propagate_corruption()

	var mm := mm_data_grid.multimesh
	var idx := 0
	for i in range(data_grid.size()):
		for j in range(data_grid[i].size()):
			var cell_data: Dictionary = data_grid[i][j]
			var pos := Vector3(
				i * 0.5 - data_grid.size() * 0.25,
				0,
				j * 0.5 - data_grid[i].size() * 0.25
			)

			var s := Vector3(0.4, 0.4, 0.4)
			var rot := Vector3.ZERO

			var color: Color
			if cell_data.intact:
				var value_ratio: float = float(cell_data.value) / 255.0
				color = Color(0.2, value_ratio, 0.8)
			else:
				var corruption_age: float = cell_data.corruption_age
				color = Color(1.0, 0.2, 0.2, maxf(1.0 - corruption_age * 0.1, 0.2))
				# Glitch scale
				s *= 1.0 + sin(time * 10 + i + j) * 0.2
				rot = Vector3(
					sin(time * 5 + i) * 0.5,
					cos(time * 7 + j) * 0.5,
					sin(time * 3 + i + j) * 0.3
				)

			var basis := Basis.from_euler(rot).scaled(s)
			var xform := Transform3D(basis, pos)
			mm.set_instance_transform(idx, xform)
			mm.set_instance_color(idx, color)
			idx += 1

func propagate_corruption() -> void:
	for i in range(data_grid.size()):
		for j in range(data_grid[i].size()):
			var cell: Dictionary = data_grid[i][j]
			if cell.intact and randf() < corruption_rate * glitch_intensity:
				cell.intact = false
				cell.corruption_age = 0.0
				corrupted_elements.append(Vector2(i, j))
			if not cell.intact:
				cell.corruption_age += 0.1

# ─────────────────────────────────────────────
# DigitalArtifacts
# ─────────────────────────────────────────────

func _update_digital_artifacts() -> void:
	_update_scan_lines()
	_update_chromatic_aberration()
	_update_digital_noise()
	_update_buffer_overflow()

func _update_scan_lines() -> void:
	var mm := mm_scan_lines.multimesh
	for i in range(SCAN_LINE_COUNT):
		var pos := Vector3(0, i * 0.2 - 2.0, -2.0)
		var s := Vector3(8.0, 0.05, 0.1)
		var xform := Transform3D(Basis.IDENTITY.scaled(s), pos)
		mm.set_instance_transform(i, xform)

		var alpha := 0.3 + sin(time * 10 + i) * 0.2
		mm.set_instance_color(i, Color(0.0, 1.0, 0.0, alpha))

func _update_chromatic_aberration() -> void:
	var mm := mm_chromatic.multimesh
	var aberration_strength := glitch_intensity * 0.5
	var channel_colors := [
		Color(1.0, 0.0, 0.0, 0.4),
		Color(0.0, 1.0, 0.0, 0.4),
		Color(0.0, 0.0, 1.0, 0.4)
	]

	for color_idx in range(CHROMATIC_COUNT):
		var offset := Vector3((color_idx - 1) * aberration_strength, 0, 0)
		var pos := Vector3(0, 0, 2) + offset
		# Sphere mesh: radius=1, height=2 → scale to radius=1.0 means scale=1
		var xform := Transform3D(Basis.IDENTITY, pos)
		mm.set_instance_transform(color_idx, xform)
		mm.set_instance_color(color_idx, channel_colors[color_idx])

func _update_digital_noise() -> void:
	var mm := mm_noise.multimesh

	# Re-roll noise periodically for flickering effect
	_noise_reroll_timer += get_process_delta_time()
	if _noise_reroll_timer > 0.06:
		_noise_reroll_timer = 0.0
		_reroll_noise()

	var hidden_xform := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -9999, 0))
	for i in range(NOISE_COUNT):
		if _noise_randf[i] < artifact_probability:
			var pos: Vector3 = _noise_positions[i]
			var s := Vector3(0.1, 0.1, 0.1)
			var xform := Transform3D(Basis.IDENTITY.scaled(s), pos)
			mm.set_instance_transform(i, xform)
			mm.set_instance_color(i, _noise_colors[i])
		else:
			mm.set_instance_transform(i, hidden_xform)

func _update_buffer_overflow() -> void:
	var mm := mm_overflow.multimesh
	var overflow_height := 3.0 + glitch_intensity * 2.0

	for i in range(OVERFLOW_COUNT):
		# Deterministic per-instance random height using sin
		var h := overflow_height * fmod(abs(sin(time * 0.4 + i * 3.7)), 1.0)
		var pos := Vector3(
			i * 0.4 - 2.0,
			h * 0.5,
			3.0
		)
		var s := Vector3(0.3, maxf(h, 0.01), 0.3)
		var xform := Transform3D(Basis.IDENTITY.scaled(s), pos)
		mm.set_instance_transform(i, xform)

		var color: Color
		if h > 2.0:
			color = Color(1.0, 0.0, 0.0)
		else:
			color = Color(0.2, 0.8, 0.2)
		mm.set_instance_color(i, color)

# ─────────────────────────────────────────────
# ErrorPropagation
# ─────────────────────────────────────────────

func _update_error_propagation(_delta: float) -> void:
	_update_error_cascade()
	_update_error_waves()

func _update_error_waves() -> void:
	var mm := mm_error_waves.multimesh
	for i in range(ERROR_WAVE_COUNT):
		var wave_radius := fmod(time * error_propagation_speed + i * 0.5, 4.0)
		var r := wave_radius + 0.2
		# Cylinder mesh: radius=1, height=1 → scale x/z = r, y = 0.1
		var s := Vector3(r, 0.1, r)
		var pos := Vector3(0, 7, 0)
		var xform := Transform3D(Basis.IDENTITY.scaled(s), pos)
		mm.set_instance_transform(i, xform)

		var alpha := 1.0 - (wave_radius / 4.0)
		mm.set_instance_color(i, Color(1.0, 0.5, 0.0, alpha * 0.6))

func _update_error_cascade() -> void:
	# Propagate errors
	var new_errors := []
	for error in error_cascade:
		error.age += get_process_delta_time()
		error.intensity *= 0.998  # slower decay per frame (was 0.95 per 0.1s)

		if error.age < 2.0 and _rng.randf() < 0.005:
			new_errors.append({
				"pos": error.pos + Vector3(
					_rng.randf_range(-1, 1),
					_rng.randf_range(-1, 1),
					_rng.randf_range(-1, 1)
				),
				"age": 0.0,
				"intensity": error.intensity * 0.8
			})

	error_cascade.append_array(new_errors)

	# Seed initial error if empty
	if error_cascade.is_empty():
		error_cascade.append({"pos": Vector3.ZERO, "age": 0.0, "intensity": 1.0})

	# Remove old errors
	error_cascade = error_cascade.filter(func(e): return e.age < 3.0)

	# Cap the cascade
	if error_cascade.size() > ERROR_CASCADE_MAX:
		error_cascade.resize(ERROR_CASCADE_MAX)

	# Update multimesh
	var mm := mm_error_cascade.multimesh
	var hidden_xform := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -9999, 0))
	for i in range(ERROR_CASCADE_MAX):
		if i < error_cascade.size():
			var error: Dictionary = error_cascade[i]
			var r: float = 0.2 * error.intensity
			var s := Vector3(r, r, r)
			var xform := Transform3D(Basis.IDENTITY.scaled(s), error.pos)
			mm.set_instance_transform(i, xform)
			mm.set_instance_color(i, Color(1.0, 0.0, 0.0, error.intensity))
		else:
			mm.set_instance_transform(i, hidden_xform)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
