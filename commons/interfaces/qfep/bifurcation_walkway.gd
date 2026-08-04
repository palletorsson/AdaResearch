# bifurcation_walkway.gd
# A corridor where your position = r parameter in the logistic map
# Walk through the phase transition: stable → period doubling → chaos → windows of order
# The bifurcation diagram made walkable — your body IS the parameter

extends Node3D

# Intentionally not global-named to avoid class-name collision with
# res://commons/artifacts/bifurcation_walkway/bifurcation_walkway.gd

signal r_changed(r_value: float)
signal regime_changed(regime: String)

## Walkway dimensions
@export var walkway_length: float = 12.0  # Long enough to walk through
@export var walkway_width: float = 2.0
@export var wall_height: float = 3.0

## R parameter range
@export var r_min: float = 2.5
@export var r_max: float = 4.0

# --- DNA (stage 2, promoted 2026-08-03) ------------------------------------
# This is bifurcation_diagram's mathematics built as architecture instead of as a chart,
# and it had exactly one of everything: one r window, and one place for the cloud to be.
#
# regime — WHICH CLAIM about the map the corridor is. Taken from bifurcation_diagram
# character for character, values and windows both, because it is the same question asked
# of the same equation: which qualitative behaviour class are you shown. "all" is absent
# from REGIME_WINDOWS on purpose - it means do not touch r_min/r_max. What differs from
# the chart is what a crop DOES here: a cropped chart is a chart of less, but a cropped
# corridor is twelve metres of one condition, a room rather than a transition. `stable`
# is a corridor you can walk end to end while nothing happens, which is a thing the
# walkway could never say and is the sharpest sentence in its vocabulary.
#
# occupancy — WHERE THE MATHEMATICS MEETS THE BODY. The artifact's thesis is that your
# position IS the parameter, and the shipped build made one silent architectural choice
# about that: the cloud hangs in the air at your own head height, so you walk through it
# and displace it. The alternatives are not mountings, they are different relations.
#   corridor  suspended in the air you walk through — the shipped build.
#   mural     flattened onto the two side walls, alternating; the air is clear and you
#             are a viewer again, walking past a chart. The corridor un-does itself.
#   inlay     laid into the floor, with the population value mapped ACROSS the corridor
#             instead of up it, so the cascade branches left and right under your feet
#             and you cannot see the part you are standing on.
#   vault     lifted overhead out of reach; you walk beneath the cascade.
@export_enum("all", "stable", "cascade", "chaos", "period3") var regime: String = "all"
@export_enum("corridor", "mural", "inlay", "vault") var occupancy: String = "corridor"

const REGIMES := ["all", "stable", "cascade", "chaos", "period3"]
const OCCUPANCIES := ["corridor", "mural", "inlay", "vault"]

## Resolution
@export var num_columns: int = 120  # Vertical columns along the walkway
@export var iterations_per_column: int = 80
@export var skip_transient: int = 40

## Visual
@export var dot_size: float = 0.04
@export var floor_glow: bool = true

# Colors
const COLOR_ORDER := Color(0.2, 0.4, 0.9)
const COLOR_EDGE := Color(0.2, 0.9, 0.4)
const COLOR_CHAOS := Color(0.9, 0.2, 0.2)
const COLOR_WINDOW := Color(1.0, 0.9, 0.3)

# Key r thresholds
const R_STABLE := 3.0
const R_PERIOD2 := 3.449
const R_PERIOD4 := 3.544
const R_CHAOS := 3.57
const R_WINDOW_START := 3.83
const R_WINDOW_END := 3.86

# The r window each regime crops to, identical to bifurcation_diagram's REGIME_WINDOWS.
# "all" is absent on purpose: it means "do not touch r_min/r_max", which is how the two
# maps that place this corridor keep their exact framing.
const REGIME_WINDOWS := {
	"stable": [2.5, R_STABLE],
	"cascade": [R_STABLE, R_CHAOS],
	"chaos": [R_CHAOS, 4.0],
	"period3": [3.82, 3.87],
}

# Internal
var _current_r: float = 2.5
var _current_regime: String = "STABLE"
var _floor_segments: Array[MeshInstance3D] = []
var _marker_nodes: Array[Node3D] = []
var _dots_instance: MultiMeshInstance3D
# Reached only at occupancy == "vault". See _build_frame_anchor().
var _frame_anchor: MeshInstance3D
var _regime_label: Label3D
var _r_label: Label3D
var _title_label: Label3D
var _player_in_walkway: bool = false
var _built: bool = false
# The z scatter was an unseeded randf(), so no two launches of the same corridor were the
# same cloud. Same range, same look, now reproducible — a variant sweep can only compare
# frames that are comparable.
var _rng := RandomNumberGenerator.new()

# Keyboard fallback
var _keyboard_pos: float = 0.0

func _ready() -> void:
	_apply_regime()
	_build_walkway_structure()
	_generate_bifurcation_columns()
	_build_floor_gradient()
	_build_regime_markers()
	_build_labels()
	_build_player_detection()

	add_to_group("qfep_reactive")
	_built = true
	print("BifurcationWalkway: Walk through the phase transition")


## Grid system integration.
##
## Guarded three ways: the key has to be present, the value has to be one the code can
## actually build, and it has to differ from the current one — so a map token carrying
## unrelated layout keys rebuilds nothing. _built stays false until _ready has run once,
## which keeps a config applied early from freeing meshes that do not exist yet; the
## exports alone are enough then, and _ready will build with them.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("regime"):
		var want_regime: String = str(config_data["regime"]).strip_edges().to_lower()
		if want_regime != regime and REGIMES.has(want_regime):
			regime = want_regime
			changed = true

	if config_data.has("occupancy"):
		var want_occ: String = str(config_data["occupancy"]).strip_edges().to_lower()
		if want_occ != occupancy and OCCUPANCIES.has(want_occ):
			occupancy = want_occ
			changed = true

	if not changed or not _built:
		return

	_apply_regime()
	_rebuild_data()


## Crop the r axis onto one behaviour class. "all" and any unknown value leave the
## exported r_min/r_max untouched, which is the whole of the default guarantee.
func _apply_regime() -> void:
	if regime == "all" or not REGIME_WINDOWS.has(regime):
		return
	var span_r: Array = REGIME_WINDOWS[regime]
	r_min = float(span_r[0])
	r_max = float(span_r[1])
	_current_r = clampf(_current_r, r_min, r_max)


## Only ever reached from apply_grid_config after a value actually moved. The walkway
## shell, the walls, the labels and the player Area3D are untouched: they are the
## architecture, and neither axis is about them.
func _rebuild_data() -> void:
	if _dots_instance != null and is_instance_valid(_dots_instance):
		remove_child(_dots_instance)
		_dots_instance.queue_free()
	_dots_instance = null

	if _frame_anchor != null and is_instance_valid(_frame_anchor):
		remove_child(_frame_anchor)
		_frame_anchor.queue_free()
	_frame_anchor = null

	for seg in _floor_segments:
		if is_instance_valid(seg):
			remove_child(seg)
			seg.queue_free()
	_floor_segments.clear()

	for node in _marker_nodes:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_marker_nodes.clear()

	_generate_bifurcation_columns()
	_build_floor_gradient()
	_build_regime_markers()
	_update_display()

# ---------------------------------------------------------------------------
# Walkway structure — floor, walls, ceiling frame
# ---------------------------------------------------------------------------

func _build_walkway_structure() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.05, 0.05, 0.08)
	floor_mat.metallic = 0.2
	floor_mat.roughness = 0.8

	# Floor
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(walkway_length, 0.05, walkway_width)
	floor_mesh.mesh = floor_box
	floor_mesh.position = Vector3(walkway_length / 2.0, -0.025, 0)
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)

	# Floor collision
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(walkway_length / 2.0, -0.025, 0)
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(walkway_length, 0.05, walkway_width)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	add_child(floor_body)

	# Side walls (transparent, faint glow)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.1, 0.15, 0.25, 0.15)
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mat.emission_enabled = true
	wall_mat.emission = Color(0.1, 0.2, 0.4)
	wall_mat.emission_energy_multiplier = 0.3

	for side in [-1.0, 1.0]:
		var wall := MeshInstance3D.new()
		var wall_box := BoxMesh.new()
		wall_box.size = Vector3(walkway_length, wall_height, 0.02)
		wall.mesh = wall_box
		wall.position = Vector3(walkway_length / 2.0, wall_height / 2.0, side * walkway_width / 2.0)
		wall.material_override = wall_mat
		add_child(wall)

# ---------------------------------------------------------------------------
# Bifurcation data as floating dots along the corridor
# ---------------------------------------------------------------------------

## Where one dot sits, given how far along the corridor it is and what the orbit value is.
##
## The `_:` branch is `corridor`, and it is the shipped expression unchanged: the height
## mapping and the +/- 0.6 * width scatter are what every existing placement has drawn.
## Only the source of the scatter moved, from a global randf() to a seeded generator.
func _dot_position(x_pos: float, x_val: float, j: int) -> Vector3:
	# Which wall a mural dot lands on. Computed before the match so no local declaration
	# sits in a pattern block, where `var` also means a binding pattern.
	var side: float = -1.0
	if (j % 2) == 0:
		side = 1.0

	match occupancy:
		"mural":
			# Flattened onto both side walls, alternating, just inside the glass.
			return Vector3(x_pos, x_val * (wall_height - 0.5) + 0.25,
					side * (walkway_width / 2.0 - 0.04))
		"inlay":
			# The population value branches ACROSS the corridor instead of up it, and the
			# whole diagram lies in the floor you are standing on.
			return Vector3(x_pos, 0.02 + _rng.randf() * 0.012,
					(x_val - 0.5) * walkway_width * 0.9)
		"vault":
			# Lifted out of reach: you walk beneath the cascade.
			return Vector3(x_pos, wall_height + 0.35 + x_val * 1.2,
					(_rng.randf() - 0.5) * walkway_width * 0.6)
		_:
			return Vector3(x_pos, x_val * (wall_height - 0.5) + 0.25,
					(_rng.randf() - 0.5) * walkway_width * 0.6)


func _generate_bifurcation_columns() -> void:
	var all_positions: Array[Vector3] = []
	var all_colors: Array[Color] = []
	_rng.seed = 20260803

	for i in range(num_columns):
		var t: float = float(i) / float(num_columns - 1)
		var r: float = r_min + t * (r_max - r_min)
		var x_pos: float = t * walkway_length
		var x: float = 0.5

		for j in range(iterations_per_column):
			x = r * x * (1.0 - x)
			if j >= skip_transient:
				all_positions.append(_dot_position(x_pos, x, j))
				all_colors.append(_get_color_for_r(r))

	# Build MultiMesh
	var mm_instance := MultiMeshInstance3D.new()
	mm_instance.name = "BifurcationDots"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = all_positions.size()

	var sphere := SphereMesh.new()
	sphere.radius = dot_size
	sphere.height = dot_size * 2.0
	sphere.radial_segments = 6
	sphere.rings = 3
	mm.mesh = sphere

	for i in range(all_positions.size()):
		mm.set_instance_transform(i, Transform3D(Basis(), all_positions[i]))
		mm.set_instance_color(i, all_colors[i])

	mm_instance.multimesh = mm

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.6
	mm_instance.material_override = mat

	add_child(mm_instance)
	_dots_instance = mm_instance
	_build_frame_anchor()
	print("BifurcationWalkway: %d bifurcation dots" % all_positions.size())


## An invisible box that tells a capture where the cloud actually is.
##
## Every dot lives in a MultiMeshInstance3D, and the capture AABB counts MeshInstance3D
## only — so the measured extent of this artifact comes from the floor slab and the two
## wall planes, i.e. the corridor SHELL. At corridor, mural and inlay the cloud sits
## inside that shell and the framing is honest. At vault it is lifted to wall_height +
## 1.55, well above it, and a capture would frame the empty corridor and photograph the
## axis as "the dots were deleted" instead of "the dots were lifted".
##
## So the anchor exists ONLY at vault. layers = 0 keeps it out of every render (and,
## unlike visible = false, does not propagate to children or touch materials) while the
## mesh still counts toward the AABB. Building it unconditionally would inflate the
## framing of the three values that do not need it, which is the same fault reversed.
func _build_frame_anchor() -> void:
	if occupancy != "vault":
		return
	var anchor := MeshInstance3D.new()
	anchor.name = "FrameAnchor"
	var box := BoxMesh.new()
	var top: float = wall_height + 1.75
	box.size = Vector3(walkway_length, top, walkway_width)
	anchor.mesh = box
	anchor.position = Vector3(walkway_length / 2.0, top / 2.0, 0)
	anchor.layers = 0
	add_child(anchor)
	_frame_anchor = anchor

# ---------------------------------------------------------------------------
# Floor gradient — glows the color of the current regime
# ---------------------------------------------------------------------------

func _build_floor_gradient() -> void:
	if not floor_glow:
		return

	var segment_count := 24
	var seg_length: float = walkway_length / float(segment_count)

	for i in range(segment_count):
		var t: float = float(i) / float(segment_count - 1)
		var r: float = r_min + t * (r_max - r_min)
		var color := _get_color_for_r(r)

		var seg := MeshInstance3D.new()
		var seg_mesh := BoxMesh.new()
		seg_mesh.size = Vector3(seg_length * 0.95, 0.005, walkway_width * 0.9)
		seg.mesh = seg_mesh
		seg.position = Vector3(seg_length * (float(i) + 0.5), 0.003, 0)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(color.r, color.g, color.b, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.4
		seg.material_override = mat

		add_child(seg)
		_floor_segments.append(seg)

# ---------------------------------------------------------------------------
# Regime markers — vertical lines at key r values
# ---------------------------------------------------------------------------

func _build_regime_markers() -> void:
	var markers := {
		R_STABLE: ["Period Doubling →", COLOR_ORDER],
		R_CHAOS: ["← CHAOS", COLOR_CHAOS],
		R_WINDOW_START: ["Window of Order", COLOR_WINDOW],
	}

	for r_val: float in markers:
		# A cropped regime puts some thresholds outside the corridor entirely; drawing
		# them anyway would hang a label in the air past the far end. At regime == "all"
		# all three are inside 2.5..4.0 and nothing is skipped.
		if r_val < r_min or r_val > r_max:
			continue
		var info: Array = markers[r_val]
		var label_text: String = info[0]
		var color: Color = info[1]
		var x_pos: float = (r_val - r_min) / (r_max - r_min) * walkway_length

		# Vertical glowing line
		var line := MeshInstance3D.new()
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(0.02, wall_height, 0.02)
		line.mesh = line_mesh
		line.position = Vector3(x_pos, wall_height / 2.0, walkway_width / 2.0 - 0.05)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.0
		line.material_override = mat
		add_child(line)
		_marker_nodes.append(line)

		# Marker label
		var lbl := Label3D.new()
		lbl.text = label_text
		lbl.font_size = 20
		lbl.position = Vector3(x_pos, wall_height + 0.2, walkway_width / 2.0 - 0.1)
		lbl.modulate = color
		lbl.outline_size = 4
		lbl.outline_modulate = Color.BLACK
		add_child(lbl)
		_marker_nodes.append(lbl)

# ---------------------------------------------------------------------------
# Labels — current r, regime name, title
# ---------------------------------------------------------------------------

func _build_labels() -> void:
	# Title at entrance
	_title_label = Label3D.new()
	_title_label.text = "BIFURCATION WALKWAY\nWalk through the phase transition"
	_title_label.font_size = 32
	_title_label.position = Vector3(0.5, wall_height * 0.7, 0)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.modulate = Color.WHITE
	_title_label.outline_size = 5
	_title_label.outline_modulate = Color.BLACK
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)

	# Current r value (follows player)
	_r_label = Label3D.new()
	_r_label.text = "r = %.3f" % r_min
	_r_label.font_size = 28
	_r_label.position = Vector3(walkway_length / 2.0, wall_height + 0.5, 0)
	_r_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_r_label.outline_size = 4
	_r_label.outline_modulate = Color.BLACK
	add_child(_r_label)

	# Regime label
	_regime_label = Label3D.new()
	_regime_label.text = "STABLE"
	_regime_label.font_size = 24
	_regime_label.position = Vector3(walkway_length / 2.0, wall_height + 0.8, 0)
	_regime_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_regime_label.outline_size = 4
	_regime_label.outline_modulate = Color.BLACK
	add_child(_regime_label)

# ---------------------------------------------------------------------------
# Player detection — Area3D along the walkway
# ---------------------------------------------------------------------------

func _build_player_detection() -> void:
	var area := Area3D.new()
	area.name = "WalkwayArea"
	area.position = Vector3(walkway_length / 2.0, wall_height / 2.0, 0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(walkway_length, wall_height, walkway_width)
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_body"):
		_player_in_walkway = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("player_body"):
		_player_in_walkway = false

func _process(delta: float) -> void:
	var x_pos: float = 0.0

	if _player_in_walkway:
		var xr_origin := get_tree().get_first_node_in_group("xr_origin")
		if xr_origin:
			# Convert player world X to walkway local X
			var local_pos: Vector3 = to_local(xr_origin.global_position)
			x_pos = clampf(local_pos.x, 0.0, walkway_length)
	else:
		# Keyboard fallback — arrow keys
		if Input.is_key_pressed(KEY_RIGHT):
			_keyboard_pos += 2.0 * delta
		if Input.is_key_pressed(KEY_LEFT):
			_keyboard_pos -= 2.0 * delta
		_keyboard_pos = clampf(_keyboard_pos, 0.0, walkway_length)
		x_pos = _keyboard_pos

	# Map position to r value
	var t: float = x_pos / walkway_length
	var new_r: float = r_min + t * (r_max - r_min)

	if absf(new_r - _current_r) > 0.001:
		_current_r = new_r
		_update_display()
		r_changed.emit(_current_r)

func _update_display() -> void:
	var color := _get_color_for_r(_current_r)
	var regime := _get_regime_name(_current_r)

	if _r_label:
		var x_pos: float = (_current_r - r_min) / (r_max - r_min) * walkway_length
		_r_label.text = "r = %.3f  (λ ≈ %.2f)" % [_current_r, (_current_r - r_min) / (r_max - r_min)]
		_r_label.position.x = x_pos
		_r_label.modulate = color

	if _regime_label:
		_regime_label.text = regime
		_regime_label.position.x = (_current_r - r_min) / (r_max - r_min) * walkway_length
		_regime_label.modulate = color

	if regime != _current_regime:
		_current_regime = regime
		regime_changed.emit(_current_regime)

func _get_color_for_r(r: float) -> Color:
	if r < R_STABLE:
		return COLOR_ORDER
	elif r < R_CHAOS:
		var t_val: float = (r - R_STABLE) / (R_CHAOS - R_STABLE)
		return COLOR_ORDER.lerp(COLOR_EDGE, t_val)
	elif r >= R_WINDOW_START and r <= R_WINDOW_END:
		return COLOR_WINDOW
	else:
		var t_val: float = clampf((r - R_CHAOS) / (r_max - R_CHAOS), 0.0, 1.0)
		return COLOR_EDGE.lerp(COLOR_CHAOS, t_val)

func _get_regime_name(r: float) -> String:
	if r < R_STABLE:
		return "STABLE (single attractor)"
	elif r < R_PERIOD2:
		return "PERIOD-2 (first bifurcation)"
	elif r < R_PERIOD4:
		return "PERIOD-4"
	elif r < R_CHAOS:
		return "PERIOD-DOUBLING CASCADE"
	elif r >= R_WINDOW_START and r <= R_WINDOW_END:
		return "WINDOW OF ORDER (period-3)"
	else:
		return "CHAOS"

# Public API
func get_current_r() -> float:
	return _current_r

func get_regime() -> String:
	return _current_regime
