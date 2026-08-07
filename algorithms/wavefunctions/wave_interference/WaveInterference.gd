extends Node3D
class_name WaveInterference

# @identity
# essence: two wave sources whose ripples meet — the interference field between them is the truth of wave addition
# desire: to make the player walk through nodal lines and antinodes, feeling where waves cancel and where they double
# critical_parameter: evidence — how much of the interference arithmetic the field puts on the
#   table. The family ladder from [[wave_interference_tank]] and [[wave_interference_3d]]:
#   result < trace < sources < longhand. UNLIKE its two promoted siblings this artifact has
#   never shown the bare outcome: the shipped build already draws the two families of
#   expanding front rings, one colour per source, so ITS legacy rung is `sources`, and
#   `result` is the value that withholds the fronts rather than the default that lacks them.
# triggers: the field of grid points oscillating, each point summing both wave influences in real time;
#   _ready reads #evidence: and builds the chosen apparatus; apply_grid_config({evidence}).
# emerges: a checkerboard of constructive and destructive interference that no single wave could create
# needs: frequency1[has] frequency2[has] amplitude[has] grid_field[has] vr_source_drag[missing]
# relationships: pairs with wave_propagation_3d (one source) and coupled_oscillator_lattice (lattice
#   coupling). Carries the same `evidence` ladder as [[wave_interference_tank]] and
#   [[wave_interference_3d]] and parses a token through the tank's one reader.
# truth: when two waves meet they do not fight — they add, and the pattern they make holds more information than either alone

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-06). The word and its four rungs are taken character
# for character from wave_interference_tank and wave_interference_3d — this is the
# ancestor both of them credit ("builds on wave_interference, 2D ring version"), asking
# the same question of the same mathematics: wave1 and wave2 exist for one line each in
# animate_interference_field() before being summed and thrown away.
#
#   result    the summed field alone. The bare outcome — for THIS artifact a value that
#             builds LESS than the default, because the default already shows its fronts.
#   trace     the field read off: a chart plate standing beyond the sources carrying the
#             live profile along z = -3, the line through both sources.
#   sources   THE LEGACY LINEAGE, byte for byte — the shipped build already draws two
#             families of expanding front rings, one colour per source. The default.
#   longhand  both addends printed as flat colour plates above a lit rule, the field
#             beyond them as the sum. Long addition, in air.
#
# Deliberately NOT the axis: frequency1/frequency2/wave_speed/amplitude — every one is a
# per-second quantity a still cannot see, the exact trap the tank's promotion documents.
#
# CAPTURE NOTE: every visible legacy part of this artifact is CSG (CSGSphere3D,
# CSGBox3D, CSGCylinder3D) and the capture AABB counts MeshInstance3D ONLY, so the
# artifact used to measure as a 1 m box while spanning ~14 m. _create_aabb_anchor()
# adds one layers = 0 MeshInstance3D sized to the true extent (never rendered, in any
# variant, in game or on the bench) so all four rungs are photographed in one frame.
# ─────────────────────────────────────────────────────────────────────────────

## AXIS — how much of the interference arithmetic the field puts on the table.
## One ordered ladder, monotone in disclosure, shared with both promoted siblings:
##   result < trace < sources (legacy default) < longhand
## All four render the identical oscillating field; they differ in what is built around it.
@export_enum("result", "trace", "sources", "longhand") var evidence: String = "sources"
const EVIDENCES: PackedStringArray = ["result", "trace", "sources", "longhand"]

var time: float = 0.0
var wave_speed: float = 2.0
var frequency1: float = 1.0
var frequency2: float = 1.2
var amplitude: float = 1.0
var field_points: Array = []
var wave_rings1: Array = []
var wave_rings2: Array = []

# Apparatus built by the evidence axis. All null on the legacy default — `sources` IS
# the legacy build, so the Evidence host only ever exists on `trace` and `longhand`.
const TRACE_SAMPLES: int = 80      # profile resolution across the field's 8 m width
const ADDEND_RES: int = 20         # lattice of one addend plate (matches the 20-point field)
const PLATE_Z: float = -5.2        # chart/addend plane, beyond the sources at z = -3
var _evidence_root: Node3D
var _trace_im: ImmediateMesh
var _addend_ims: Array[ImmediateMesh] = []

func _ready() -> void:
	# Initialize Wave Interference visualization
	_read_meta_overrides()
	print("Wave Interference Visualization initialized")
	create_interference_field()
	if evidence == "sources":
		create_wave_rings()            # the legacy build, in the legacy order
	setup_grid()
	_create_aabb_anchor()
	_build_evidence()

func _process(delta: float) -> void:
	time += delta

	animate_wave_sources(delta)
	animate_wave_rings(delta)
	animate_interference_field(delta)
	animate_interference_pattern(delta)
	_update_evidence()

func create_interference_field() -> void:
	# Create field points for interference visualization
	var field_points_node = $InterferenceField/FieldPoints
	var grid_size = 20
	var spacing = 0.4
	
	for i in range(grid_size):
		for j in range(grid_size):
			var point = CSGSphere3D.new()
			point.radius = 0.04
			point.material_override = StandardMaterial3D.new()
			point.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
			point.material_override.emission_enabled = true
			point.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
			
			# Position points in a grid
			var x = (i - grid_size/2) * spacing
			var z = (j - grid_size/2) * spacing
			point.position = Vector3(x, 0, z)
			
			field_points_node.add_child(point)
			field_points.append(point)

func create_wave_rings() -> void:
	# Create wave rings for both sources
	var rings1_node = $WaveRings1
	var rings2_node = $WaveRings2
	
	# Create rings for source 1
	for i in range(8):
		var ring = CSGCylinder3D.new()
		ring.radius = 0.5 + i * 0.5 + i * 0.5
		ring.height = 0.02
		ring.material_override = StandardMaterial3D.new()
		ring.material_override.albedo_color = Color(0.2, 0.8, 0.2, 0.3)
		ring.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override.emission_enabled = true
		ring.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.2
		
		rings1_node.add_child(ring)
		wave_rings1.append(ring)
	
	# Create rings for source 2
	for i in range(8):
		var ring = CSGCylinder3D.new()
		ring.radius = 0.5 + i * 0.5 + i * 0.5
		ring.height = 0.02
		ring.material_override = StandardMaterial3D.new()
		ring.material_override.albedo_color = Color(0.8, 0.2, 0.2, 0.3)
		ring.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override.emission_enabled = true
		ring.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.2
		
		rings2_node.add_child(ring)
		wave_rings2.append(ring)

func setup_grid() -> void:
	# Create reference grid
	var grid_lines = $Grid/GridLines
	
	# Create grid lines
	for i in range(-5, 6):
		# X-direction lines
		var x_line = CSGBox3D.new()
		x_line.size = Vector3(10, 0.01, 0.01)
		x_line.material_override = StandardMaterial3D.new()
		x_line.material_override.albedo_color = Color(0.3, 0.3, 0.3, 1)
		x_line.position = Vector3(0, -3, i)
		grid_lines.add_child(x_line)
		
		# Z-direction lines
		var z_line = CSGBox3D.new()
		z_line.size = Vector3(0.01, 0.01, 10)
		z_line.material_override = StandardMaterial3D.new()
		z_line.material_override.albedo_color = Color(0.3, 0.3, 0.3, 1)
		z_line.position = Vector3(i, -3, 0)
		grid_lines.add_child(z_line)

func animate_wave_sources(_delta) -> void:
	# Animate wave source cores
	var source1_core = $WaveSource1/SourceCore
	var source2_core = $WaveSource2/SourceCore
	
	if source1_core:
		# Pulse source 1
		var pulse1 = 1.0 + sin(time * frequency1 * PI * 2) * 0.3
		source1_core.scale = Vector3.ONE * pulse1
		
		# Change emission intensity
		var intensity1 = (sin(time * frequency1 * PI * 2) + 1.0) * 0.5
		source1_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity1
	
	if source2_core:
		# Pulse source 2
		var pulse2 = 1.0 + sin(time * frequency2 * PI * 2) * 0.3
		source2_core.scale = Vector3.ONE * pulse2
		
		# Change emission intensity
		var intensity2 = (sin(time * frequency2 * PI * 2) + 1.0) * 0.5
		source2_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity2

func animate_wave_rings(_delta) -> void:
	# Animate wave rings expanding from sources
	for i in range(wave_rings1.size()):
		var ring = wave_rings1[i]
		if ring:
			# Expand rings from source 1
			var ring_time = time * wave_speed - i * 0.5
			var ring_radius = fmod(ring_time, 4.0)
			if ring_radius > 0:
				ring.radius = ring_radius
				
				# Fade out as ring expands
				var alpha = max(0, 1.0 - ring_radius / 4.0)
				ring.material_override.albedo_color = Color(0.2, 0.8, 0.2, alpha * 0.3)
				ring.material_override.emission = Color(0.2, 0.8, 0.2, 1) * alpha * 0.2
			else:
				ring.radius = 0.01
				
	
	for i in range(wave_rings2.size()):
		var ring = wave_rings2[i]
		if ring:
			# Expand rings from source 2
			var ring_time = time * wave_speed - i * 0.5
			var ring_radius = fmod(ring_time, 4.0)
			if ring_radius > 0:
				ring.radius = ring_radius
				
				# Fade out as ring expands
				var alpha = max(0, 1.0 - ring_radius / 4.0)
				ring.material_override.albedo_color = Color(0.8, 0.2, 0.2, alpha * 0.3)
				ring.material_override.emission = Color(0.8, 0.2, 0.2, 1) * alpha * 0.2
			else:
				ring.radius = 0.01
				

func animate_interference_field(_delta) -> void:
	# Animate field points based on wave interference
	var source1_pos = Vector3(-3, 0, -3)
	var source2_pos = Vector3(3, 0, -3)
	
	for i in range(field_points.size()):
		var point = field_points[i]
		if point:
			# Calculate distance to each source
			var dist1 = point.global_position.distance_to(source1_pos)
			var dist2 = point.global_position.distance_to(source2_pos)
			
			# Calculate wave values at this point
			var wave1 = sin(time * frequency1 * PI * 2 - dist1 * wave_speed) * amplitude
			var wave2 = sin(time * frequency2 * PI * 2 - dist2 * wave_speed) * amplitude
			
			# Calculate interference
			var interference = wave1 + wave2
			
			# Update point position and appearance
			point.position.y = interference * 0.5
			
			# Color based on interference pattern
			var intensity = (interference + 2.0) / 4.0  # Normalize to 0-1
			var color = Color.RED.lerp(Color.BLUE, intensity)
			point.material_override.albedo_color = color
			point.material_override.emission = color * 0.3
			
			# Scale based on interference magnitude
			var scale = 1.0 + abs(interference) * 0.3
			point.scale = Vector3.ONE * scale

func animate_interference_pattern(delta) -> void:
	# Animate the interference pattern visualization
	var pattern_core = $InterferencePattern/PatternCore
	if pattern_core:
		# Rotate pattern
		pattern_core.rotation.y += delta * 0.5
		
		# Pulse based on overall interference
		var pulse = 1.0 + sin(time * 2.0) * 0.1
		pattern_core.scale = Vector3.ONE * pulse
		
		# Change color based on time
		var color_shift = sin(time * 1.5) * 0.5 + 0.5
		var color = Color(0.2, 0.8, 0.2, 1).lerp(Color(0.8, 0.2, 0.2, 1), color_shift)
		pattern_core.material_override.emission = color * 0.3

func set_frequency1(freq: float) -> void:
	frequency1 = clamp(freq, 0.1, 5.0)

func set_frequency2(freq: float) -> void:
	frequency2 = clamp(freq, 0.1, 5.0)

func set_wave_speed(speed: float) -> void:
	wave_speed = clamp(speed, 0.5, 5.0)

func set_amplitude(amp: float) -> void:
	amplitude = clamp(amp, 0.1, 2.0)

func get_interference_at_point(pos: Vector3) -> float:
	var source1_pos = Vector3(-3, 0, -3)
	var source2_pos = Vector3(3, 0, -3)
	
	var dist1 = pos.distance_to(source1_pos)
	var dist2 = pos.distance_to(source2_pos)
	
	var wave1 = sin(time * frequency1 * PI * 2 - dist1 * wave_speed) * amplitude
	var wave2 = sin(time * frequency2 * PI * 2 - dist2 * wave_speed) * amplitude
	
	return wave1 + wave2

func reset_simulation() -> void:
	time = 0.0

func _exit_tree() -> void:
	# Drop the evidence meshes first so a torn-down field cannot be redrawn into.
	_evidence_root = null
	_trace_im = null
	_addend_ims.clear()
	for child in get_children():
		if not child.owner:
			child.queue_free()


## LATENT BUG, FIXED HERE. This method existed as `pass`: the artifact advertised a
## configuration hook and silently discarded every key handed to it. It now stores the
## config as metadata in the family's shape and re-reads. A scan of all map_data.json
## files finds zero placements carrying any config on this token, so the change is off
## the default path either way.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was: String = evidence
	_read_meta_overrides()
	# Config can arrive either side of _ready — GridInteractablesComponent defers this
	# call, the sweep sets the export before add_child. Rebuild ONLY when the word
	# actually changed AND _ready has already built once, so a shipped placement
	# carrying no #evidence: token is never touched.
	if is_node_ready() and evidence != was:
		_teardown_evidence()
		_build_evidence()


func _read_meta_overrides() -> void:
	if has_meta("config_evidence"):
		# The family's one reader — see wave_interference_tank.gd. Aliases such as
		# `pattern`, `fronts` and `terms` resolve to the same rungs in all three
		# bodies because there is exactly one table, and it is not in this file.
		evidence = WaveInterferenceTank.evidence_name(str(get_meta("config_evidence")))


# ── evidence: the ladder of disclosure ───────────────────────────────────────
#
#   result  <  trace  <  sources  <  longhand
#
# _build_evidence() makes the apparatus once; _update_evidence() refills it from the
# frame's own numbers. Unlike the two promoted siblings, `sources` is not an added
# overlay here — it IS the legacy ring build, so its branch re-creates the rings the
# _ready gate builds on the default path, and `result` is the value that withholds
# them. An unrecognised word is the bare outcome, exactly as in the twins.

func _build_evidence() -> void:
	match evidence:
		"sources":
			if wave_rings1.is_empty():
				create_wave_rings()    # already built on the default _ready path
		"trace":
			_build_trace()
		"longhand":
			_build_addends()
		_:
			pass                       # "result" and unknown words: the summed field alone


## Drop every rung's geometry so a changed token can build a different one. Only
## reachable through apply_grid_config; on the default path this never runs.
func _teardown_evidence() -> void:
	for ring in wave_rings1:
		if is_instance_valid(ring):
			ring.queue_free()
	for ring in wave_rings2:
		if is_instance_valid(ring):
			ring.queue_free()
	wave_rings1.clear()
	wave_rings2.clear()
	if is_instance_valid(_evidence_root):
		_evidence_root.queue_free()
	_evidence_root = null
	_trace_im = null
	_addend_ims.clear()


## Everything trace/longhand builds hangs off the Evidence node, never off the field —
## teardown is one line and a rebuild cannot take the field with it. Created lazily, so
## `sources` and `result` add no node at all.
func _ev_add(n: Node) -> void:
	if _evidence_root == null:
		_evidence_root = Node3D.new()
		_evidence_root.name = "Evidence"
		add_child(_evidence_root)
	_evidence_root.add_child(n)


func _update_evidence() -> void:
	match evidence:
		"trace":
			_draw_trace()
		"longhand":
			_draw_addends()
		_:
			pass


# A vertex-coloured, unshaded, double-sided surface — these are readouts, not objects
# in the room's light, and the capture orbits so a one-sided chart is an inert axis
# from two of the four angles. Same choices as the tank's readout material.
func _readout_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _flat_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _glow_material(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _ev_box(center: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	_ev_add(mi)


## The same two addends animate_interference_field() computes and throws away, read at
## an arbitrary LOCAL point. Local on purpose: the field animation reads
## point.global_position against local source constants (the latent placement bug noted
## in the promotion report), and the apparatus should show the local-frame truth.
func _wave_terms(pos: Vector3) -> Vector2:
	var d1: float = pos.distance_to(Vector3(-3, 0, -3))
	var d2: float = pos.distance_to(Vector3(3, 0, -3))
	var w1: float = sin(time * frequency1 * PI * 2 - d1 * wave_speed) * amplitude
	var w2: float = sin(time * frequency2 * PI * 2 - d2 * wave_speed) * amplitude
	return Vector2(w1, w2)


# RUNG — TRACE. A chart plate standing beyond the sources carrying the live profile
# along z = -3, the line that runs through both of them and therefore through every
# fringe. Lit lobes under the curve so the rung bites from map distance, a zero line so
# the crossings read as the nodes.
func _build_trace() -> void:
	_ev_box(Vector3(0, 2.5, PLATE_Z), Vector3(8.4, 2.2, 0.06), _flat_material(Color(0.035, 0.045, 0.065)))
	_ev_box(Vector3(0, 2.5, PLATE_Z + 0.05), Vector3(8.0, 0.03, 0.02), _glow_material(Color(0.42, 0.50, 0.60), 0.5))
	var mi := MeshInstance3D.new()
	mi.name = "TraceCurve"
	_trace_im = ImmediateMesh.new()
	mi.mesh = _trace_im
	mi.position = Vector3(0, 2.5, PLATE_Z + 0.07)
	mi.material_override = _readout_material()
	_ev_add(mi)


func _draw_trace() -> void:
	if _trace_im == null:
		return
	var n: int = TRACE_SAMPLES
	var gain: float = 0.85 / maxf(amplitude * 2.0, 0.0001)
	var xs: PackedFloat32Array = PackedFloat32Array()
	var ys: PackedFloat32Array = PackedFloat32Array()
	for i in range(n):
		var x: float = lerpf(-4.0, 4.0, float(i) / float(n - 1))
		var t: Vector2 = _wave_terms(Vector3(x, 0, -3))
		xs.append(x)
		ys.append(clampf((t.x + t.y) * gain, -1.0, 1.0))

	_trace_im.clear_surfaces()
	_trace_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# Lit lobes under the curve — what makes the rung readable at three metres.
	var fill := Color(0.25, 0.55, 1.0, 0.40)
	for i in range(n - 1):
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(xs[i], 0.0, 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(xs[i + 1], 0.0, 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(xs[i + 1], ys[i + 1], 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(xs[i], 0.0, 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(xs[i + 1], ys[i + 1], 0.0))
		_trace_im.surface_set_color(fill)
		_trace_im.surface_add_vertex(Vector3(xs[i], ys[i], 0.0))
	# The curve itself, a ribbon offset along the segment normal.
	var lw: float = 0.05
	var line := Color(0.62, 0.92, 1.0, 1.0)
	for i in range(n - 1):
		var a := Vector2(xs[i], ys[i])
		var b := Vector2(xs[i + 1], ys[i + 1])
		var d := b - a
		if d.length() < 0.000001:
			continue
		var nrm: Vector2 = Vector2(-d.y, d.x).normalized() * (lw * 0.5)
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(a.x - nrm.x, a.y - nrm.y, 0.01))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(a.x + nrm.x, a.y + nrm.y, 0.01))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(b.x + nrm.x, b.y + nrm.y, 0.01))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(a.x - nrm.x, a.y - nrm.y, 0.01))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(b.x + nrm.x, b.y + nrm.y, 0.01))
		_trace_im.surface_set_color(line)
		_trace_im.surface_add_vertex(Vector3(b.x - nrm.x, b.y - nrm.y, 0.01))
	_trace_im.surface_end()


# RUNG — LONGHAND. The sum written out: plate A, a "+", plate B, a lit rule, and the
# field beyond them as the answer. Flat colour plates rather than little reliefs, for
# the reason both siblings document: a relief reads differently from every angle, and a
# rung only legible from the front is a rung the loop photographs three times as nothing.
func _build_addends() -> void:
	var back := _flat_material(Color(0.045, 0.05, 0.07))
	var chalk := _glow_material(Color(0.96, 0.94, 0.86), 1.6)
	_addend_ims.clear()
	for s in range(2):
		var hx: float = -2.1
		if s == 1:
			hx = 2.1
		_ev_box(Vector3(hx, 2.6, PLATE_Z - 0.03), Vector3(3.5, 3.5, 0.06), back)
		var mi := MeshInstance3D.new()
		mi.name = "Addend%d" % s
		var im := ImmediateMesh.new()
		mi.mesh = im
		mi.position = Vector3(hx, 2.6, PLATE_Z + 0.02)
		mi.material_override = _readout_material()
		_ev_add(mi)
		_addend_ims.append(im)
	# The "+" between the plates, and the rule you draw before writing the answer.
	_ev_box(Vector3(0, 2.6, PLATE_Z), Vector3(0.5, 0.09, 0.05), chalk)
	_ev_box(Vector3(0, 2.6, PLATE_Z), Vector3(0.09, 0.5, 0.05), chalk)
	_ev_box(Vector3(0, 0.75, PLATE_Z), Vector3(8.2, 0.09, 0.05), chalk)


func _draw_addends() -> void:
	if _addend_ims.size() < 2:
		return
	var tile: float = 3.2
	var n: int = ADDEND_RES
	var step: float = tile / float(n)
	var half_t: float = tile * 0.5
	for s in range(2):
		var im: ImmediateMesh = _addend_ims[s]
		if im == null:
			continue
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in range(n):
			for i in range(n):
				# Plate coordinates map back onto the SAME 8 x 8 m footprint the field
				# covers, so a cell of plate A sits over the same ground as the sphere
				# whose height it is one half of. Top-down: +u is +x, +v (up the plate)
				# is -z, so the sources' side (z = -3) is the upper band of each plate.
				var u: float = (float(i) + 0.5) / float(n) - 0.5
				var v: float = (float(j) + 0.5) / float(n) - 0.5
				var terms: Vector2 = _wave_terms(Vector3(u * 8.0, 0, -v * 8.0))
				var w: float = terms.x
				if s == 1:
					w = terms.y
				# Each addend normalised to its own full range, as in both siblings —
				# and through the field's own RED->BLUE ramp, so plate and field speak
				# one colour language.
				var col: Color = Color.RED.lerp(Color.BLUE, clampf((w / maxf(amplitude, 0.0001) + 1.0) * 0.5, 0.0, 1.0))
				var x0: float = -half_t + float(i) * step
				var x1: float = x0 + step
				var y0: float = -half_t + float(j) * step
				var y1: float = y0 + step
				im.surface_set_color(col)
				im.surface_add_vertex(Vector3(x0, y0, 0))
				im.surface_set_color(col)
				im.surface_add_vertex(Vector3(x1, y0, 0))
				im.surface_set_color(col)
				im.surface_add_vertex(Vector3(x1, y1, 0))
				im.surface_set_color(col)
				im.surface_add_vertex(Vector3(x0, y0, 0))
				im.surface_set_color(col)
				im.surface_add_vertex(Vector3(x1, y1, 0))
				im.surface_set_color(col)
				im.surface_add_vertex(Vector3(x0, y1, 0))
		im.surface_end()


## Every visible legacy part of this artifact is CSG, and the capture AABB counts
## MeshInstance3D ONLY — without this the 14 m artifact measures as a 1 m box and every
## variant is photographed from inside it. One never-rendered box (layers = 0 renders on
## no camera, in game or on the bench) spanning the true extent: grid floor at y = -3.05,
## field label at y = +5.15, front rings sweeping to x = +-7, z in [-7, 5]. Sized to the
## real extent and no further — an overshoot is the same fault in the other direction.
func _create_aabb_anchor() -> void:
	var anchor := MeshInstance3D.new()
	anchor.name = "AabbAnchor"
	var box := BoxMesh.new()
	box.size = Vector3(14.0, 8.2, 12.0)
	anchor.mesh = box
	anchor.position = Vector3(0.0, 1.05, -1.0)
	anchor.layers = 0
	add_child(anchor)
