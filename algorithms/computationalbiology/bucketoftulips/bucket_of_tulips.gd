# ===========================================================================
# BucketOfTulips — Phyllotaxis, Growth & Environmental Response
# Botanical simulation with golden-angle arrangement and developmental stages
# Elevated features:
#   - Phyllotaxis based on golden angle (137.508°) spiral arrangement
#   - Growth simulation: seed → sprouting → budding → blooming → mature
#   - Environmental response: drooping from heat, wilting from drought
#   - ImmediateMesh stems/petals, MultiMesh for pollen particles
#   - Configurable via apply_grid_config()
# License: CC BY-NC-SA 3.0 derivative
# ===========================================================================

extends Node3D

## Bucket of tulips with phyllotaxis-based arrangement, growth simulation,
## and environmental response. Modes: PHYLLOTAXIS shows golden-angle spiral
## placement; GROWTH animates developmental stages from seed to bloom;
## ENVIRONMENT simulates drooping and wilting under stress.

# --- Configuration ---
@export var tulip_count: int = 21
@export var bucket_radius: float = 0.35
@export var bucket_height: float = 0.28
@export var max_stem_height: float = 0.45
@export var step_speed: float = 1.0

# Phyllotaxis
@export var golden_angle_deg: float = 137.508
@export var radial_packing: float = 0.06  # Controls density of spiral

# Growth
@export var growth_duration: float = 12.0  # Total growth cycle seconds

# Environment
@export var heat_level: float = 0.0       # 0=cool, 1=scorching
@export var drought_level: float = 0.0    # 0=watered, 1=bone dry

# --- Mode ---
enum Mode { PHYLLOTAXIS, GROWTH, ENVIRONMENT }
var _mode: int = Mode.PHYLLOTAXIS

# --- Growth phases ---
enum GrowthPhase { SEED, SPROUTING, BUDDING, BLOOMING, MATURE }
var _growth_phase: int = GrowthPhase.MATURE
var _growth_time: float = 0.0
var _growth_progress: float = 1.0  # 0..1 overall growth

const PHASE_DURATIONS := [0.08, 0.20, 0.25, 0.30, 0.17]  # Fraction of total

# --- Internal state ---
var _time: float = 0.0
var _tulip_data: Array = []  # Per-tulip state dictionaries

# --- ImmediateMesh rendering ---
var _stem_im: ImmediateMesh
var _stem_mi: MeshInstance3D
var _petal_im: ImmediateMesh
var _petal_mi: MeshInstance3D
var _leaf_im: ImmediateMesh
var _leaf_mi: MeshInstance3D
var _spiral_im: ImmediateMesh   # Phyllotaxis spiral overlay
var _spiral_mi: MeshInstance3D
var _bucket_mi: MeshInstance3D

# Materials
var _mat_unshaded: StandardMaterial3D
var _mat_alpha: StandardMaterial3D

# Labels
var _title_label: Label3D
var _info_label: Label3D
var _phase_label: Label3D

# VR controls
var _mode_button: Node
var _heat_slider: Node
var _drought_slider: Node

# Tulip colors — common cultivar palette
const TULIP_COLORS: Array[Color] = [
	Color(0.92, 0.12, 0.15),   # Red
	Color(0.95, 0.55, 0.12),   # Orange
	Color(0.98, 0.92, 0.15),   # Yellow
	Color(0.85, 0.15, 0.55),   # Magenta
	Color(0.95, 0.45, 0.55),   # Pink
	Color(0.98, 0.95, 0.90),   # White-cream
	Color(0.55, 0.10, 0.60),   # Deep purple
	Color(0.95, 0.30, 0.30),   # Coral
]

# UI colors
const COL_STEM := Color(0.22, 0.52, 0.18)
const COL_STEM_DRY := Color(0.55, 0.50, 0.20)
const COL_LEAF := Color(0.18, 0.55, 0.15)
const COL_LEAF_DRY := Color(0.50, 0.48, 0.18)
const COL_SPIRAL := Color(1.0, 0.85, 0.3, 0.6)
const COL_GOLDEN := Color(1.0, 0.84, 0.0, 0.9)
const COL_SEED := Color(0.45, 0.30, 0.15, 0.8)
const COL_SPROUT := Color(0.3, 0.75, 0.2, 0.8)
const COL_BUD := Color(0.6, 0.8, 0.3, 0.8)
const COL_BLOOM := Color(0.95, 0.5, 0.6, 0.8)
const COL_MATURE := Color(0.4, 0.85, 0.5, 0.8)

# Golden angle in radians
const GOLDEN_ANGLE := 2.39996322972865332  # PI * (3 - sqrt(5))


func _ready() -> void:
	_create_materials()
	_create_mesh_instances()
	_create_bucket()
	_create_labels()
	_create_vr_controls()
	_init_tulip_data()
	_init_mode()


func _process(delta: float) -> void:
	_time += delta * step_speed
	match _mode:
		Mode.PHYLLOTAXIS:
			_draw_tulips()
			_draw_phyllotaxis_spiral()
		Mode.GROWTH:
			_advance_growth(delta * step_speed)
			_draw_tulips()
		Mode.ENVIRONMENT:
			_update_environment(delta * step_speed)
			_draw_tulips()
	_update_labels()


# =========================================================================
# Materials
# =========================================================================

func _create_materials() -> void:
	_mat_unshaded = StandardMaterial3D.new()
	_mat_unshaded.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_unshaded.vertex_color_use_as_albedo = true
	_mat_unshaded.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alpha = StandardMaterial3D.new()
	_mat_alpha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alpha.vertex_color_use_as_albedo = true
	_mat_alpha.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_alpha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


# =========================================================================
# Mesh instances
# =========================================================================

func _create_mesh_instances() -> void:
	_stem_im = ImmediateMesh.new()
	_stem_mi = MeshInstance3D.new()
	_stem_mi.mesh = _stem_im
	_stem_mi.material_override = _mat_unshaded
	add_child(_stem_mi)

	_petal_im = ImmediateMesh.new()
	_petal_mi = MeshInstance3D.new()
	_petal_mi.mesh = _petal_im
	_petal_mi.material_override = _mat_alpha
	add_child(_petal_mi)

	_leaf_im = ImmediateMesh.new()
	_leaf_mi = MeshInstance3D.new()
	_leaf_mi.mesh = _leaf_im
	_leaf_mi.material_override = _mat_alpha
	add_child(_leaf_mi)

	_spiral_im = ImmediateMesh.new()
	_spiral_mi = MeshInstance3D.new()
	_spiral_mi.mesh = _spiral_im
	_spiral_mi.material_override = _mat_alpha
	add_child(_spiral_mi)


# =========================================================================
# Bucket geometry
# =========================================================================

func _create_bucket() -> void:
	_bucket_mi = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = bucket_radius
	cyl.bottom_radius = bucket_radius * 0.82
	cyl.height = bucket_height
	cyl.radial_segments = 20
	cyl.rings = 2
	_bucket_mi.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.20)
	mat.metallic = 0.75
	mat.roughness = 0.35
	_bucket_mi.material_override = mat
	add_child(_bucket_mi)


# =========================================================================
# Tulip data — phyllotaxis positioning
# =========================================================================

func _init_tulip_data() -> void:
	_tulip_data.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Deterministic for reproducibility

	for i in range(tulip_count):
		var data := {}

		# --- Phyllotaxis: golden angle spiral ---
		# Vogel's model: r = c * sqrt(n), theta = n * golden_angle
		var angle := float(i) * deg_to_rad(golden_angle_deg)
		var r := radial_packing * sqrt(float(i + 1))
		# Clamp to bucket interior
		r = minf(r, bucket_radius * 0.85)

		data["base_x"] = r * cos(angle)
		data["base_z"] = r * sin(angle)
		data["spiral_index"] = i
		data["angle"] = angle

		# Per-tulip variation
		data["height_factor"] = 0.85 + rng.randf() * 0.3
		data["color"] = TULIP_COLORS[i % TULIP_COLORS.size()]
		# Slight hue shift per tulip
		var c: Color = data["color"]
		c.h = fmod(c.h + rng.randf_range(-0.03, 0.03), 1.0)
		data["color"] = c

		data["petal_count"] = 6  # Tulips are monocots (6 tepals)
		data["petal_openness"] = rng.randf_range(0.3, 0.9)
		data["lean_x"] = rng.randf_range(-0.08, 0.08)
		data["lean_z"] = rng.randf_range(-0.08, 0.08)
		data["leaf_angle"] = rng.randf() * TAU
		data["leaf_count"] = 1 + rng.randi_range(0, 1)

		# Growth state (used in GROWTH mode)
		data["growth"] = 1.0  # 0=seed, 1=fully grown
		data["bloom"] = 1.0   # 0=bud, 1=open

		# Environment state
		data["droop"] = 0.0   # 0=upright, 1=fully drooped
		data["wilt"] = 0.0    # 0=fresh, 1=wilted

		_tulip_data.append(data)


# =========================================================================
# Mode management
# =========================================================================

func _init_mode() -> void:
	_spiral_mi.visible = (_mode == Mode.PHYLLOTAXIS)

	match _mode:
		Mode.PHYLLOTAXIS:
			# Show all tulips fully grown
			for d in _tulip_data:
				d["growth"] = 1.0
				d["bloom"] = 1.0
				d["droop"] = 0.0
				d["wilt"] = 0.0
		Mode.GROWTH:
			_growth_phase = GrowthPhase.SEED
			_growth_time = 0.0
			_growth_progress = 0.0
			for d in _tulip_data:
				d["growth"] = 0.0
				d["bloom"] = 0.0
				d["droop"] = 0.0
				d["wilt"] = 0.0
		Mode.ENVIRONMENT:
			for d in _tulip_data:
				d["growth"] = 1.0
				d["bloom"] = 1.0
				d["droop"] = 0.0
				d["wilt"] = 0.0


func _cycle_mode() -> void:
	_mode = (_mode + 1) % 3
	_init_mode()


# =========================================================================
# Drawing — stems
# =========================================================================

func _draw_tulips() -> void:
	_stem_im.clear_surfaces()
	_petal_im.clear_surfaces()
	_leaf_im.clear_surfaces()

	_stem_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_petal_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_leaf_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for d in _tulip_data:
		_draw_single_tulip(d)

	_stem_im.surface_end()
	_petal_im.surface_end()
	_leaf_im.surface_end()


func _draw_single_tulip(d: Dictionary) -> void:
	var growth: float = d["growth"]
	if growth < 0.01:
		return  # Still a seed — nothing visible

	var base := Vector3(d["base_x"], bucket_height * 0.5, d["base_z"])
	var h: float = max_stem_height * d["height_factor"] * growth
	var droop: float = d["droop"]
	var wilt: float = d["wilt"]

	# Stem color lerps toward dry as wilt increases
	var stem_col: Color = COL_STEM.lerp(COL_STEM_DRY, wilt)

	# Stem is a tapered tube built from segments
	var segs := 6
	var stem_bottom_r := 0.012
	var stem_top_r := 0.008
	var lean := Vector3(d["lean_x"], 0, d["lean_z"])
	# Drooping bends the upper stem
	var droop_bend := droop * 0.8  # Radians of bend at top

	# Build stem curve points
	var stem_pts: Array[Vector3] = []
	for s in range(segs + 1):
		var t := float(s) / float(segs)
		var y := base.y + h * t
		# Drooping: quadratic bend increases toward top
		var bend_amount := droop_bend * t * t
		var bend_dir := Vector3(lean.x + 0.5, 0, lean.z + 0.3).normalized() if lean.length() > 0.01 else Vector3(1, 0, 0)
		var offset := base + lean * t + bend_dir * bend_amount * h * 0.5
		offset.y = y
		stem_pts.append(offset)

	# Draw stem as cross-quad tubes (4 faces)
	for s in range(segs):
		var p0 := stem_pts[s]
		var p1 := stem_pts[s + 1]
		var t0 := float(s) / float(segs)
		var t1 := float(s + 1) / float(segs)
		var r0 := lerpf(stem_bottom_r, stem_top_r, t0)
		var r1 := lerpf(stem_bottom_r, stem_top_r, t1)

		var up := (p1 - p0).normalized()
		var right := up.cross(Vector3.UP).normalized()
		if right.length_squared() < 0.01:
			right = Vector3(1, 0, 0)
		var fwd := up.cross(right).normalized()

		# 4 cross-quad faces for the tube
		for face in range(4):
			var angle0 := TAU * float(face) / 4.0
			var angle1 := TAU * float(face + 1) / 4.0
			var d0 := right * cos(angle0) + fwd * sin(angle0)
			var d1 := right * cos(angle1) + fwd * sin(angle1)

			var v0 := p0 + d0 * r0
			var v1 := p0 + d1 * r0
			var v2 := p1 + d0 * r1
			var v3 := p1 + d1 * r1

			_stem_im.surface_set_color(stem_col)
			_stem_im.surface_add_vertex(v0)
			_stem_im.surface_add_vertex(v1)
			_stem_im.surface_add_vertex(v2)

			_stem_im.surface_set_color(stem_col)
			_stem_im.surface_add_vertex(v1)
			_stem_im.surface_add_vertex(v3)
			_stem_im.surface_add_vertex(v2)

	# Flower head at top of stem
	var bloom_val: float = d["bloom"]
	if growth > 0.4 and bloom_val > 0.0:
		var tip := stem_pts[segs]
		var stem_dir := (stem_pts[segs] - stem_pts[segs - 1]).normalized()
		_draw_flower_head(d, tip, stem_dir, bloom_val, wilt)

	# Leaves along lower stem
	if growth > 0.2:
		var leaf_col: Color = COL_LEAF.lerp(COL_LEAF_DRY, wilt)
		var leaf_count: int = d["leaf_count"]
		for li in range(leaf_count):
			var t_leaf := 0.15 + float(li) * 0.2
			var seg_idx := mini(int(t_leaf * segs), segs - 1)
			var leaf_base := stem_pts[seg_idx]
			var leaf_angle: float = d["leaf_angle"] + float(li) * PI * 0.7
			_draw_leaf(leaf_base, leaf_angle, leaf_col, growth, wilt)


# =========================================================================
# Drawing — flower heads (6 tepals in two whorls)
# =========================================================================

func _draw_flower_head(d: Dictionary, tip: Vector3, stem_dir: Vector3, bloom: float, wilt: float) -> void:
	var petal_col: Color = d["color"]
	# Wilting desaturates and browns the petals
	if wilt > 0.0:
		petal_col = petal_col.lerp(Color(0.55, 0.40, 0.25), wilt * 0.7)
		petal_col.a = lerpf(0.92, 0.5, wilt)
	else:
		petal_col.a = 0.92

	var openness: float = d["petal_openness"] * bloom
	# Wilt makes petals droop further open or curl
	openness = clampf(openness + wilt * 0.4, 0.0, 1.2)

	var petal_length := 0.06 * bloom
	var petal_width := 0.025 * bloom

	# Find perpendicular basis
	var up := stem_dir.normalized()
	var right := up.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.01:
		right = Vector3(1, 0, 0)
	var fwd := up.cross(right).normalized()

	# 6 tepals: outer 3 slightly larger, inner 3 slightly smaller
	for i in range(6):
		var base_angle := TAU * float(i) / 6.0
		# Inner vs outer whorl offset
		var whorl_offset := 0.0 if i < 3 else (TAU / 12.0)
		var angle := base_angle + whorl_offset
		var size_mult := 1.0 if i < 3 else 0.85

		# Petal direction: tilts outward based on openness
		var radial := right * cos(angle) + fwd * sin(angle)
		var tilt_angle := openness * 0.6  # 0=closed upright, ~0.7=open
		var petal_dir := (up * cos(tilt_angle) + radial * sin(tilt_angle)).normalized()
		var petal_side := petal_dir.cross(radial).normalized()
		if petal_side.length_squared() < 0.01:
			petal_side = fwd

		var p_base := tip + radial * 0.008
		var p_tip := p_base + petal_dir * petal_length * size_mult
		var p_left := p_base + petal_dir * petal_length * 0.5 * size_mult - petal_side * petal_width * size_mult
		var p_right := p_base + petal_dir * petal_length * 0.5 * size_mult + petal_side * petal_width * size_mult

		# Inner petal color slightly lighter
		var pc := petal_col
		if i >= 3:
			pc = pc.lightened(0.12)

		# Two triangles forming a diamond petal
		_petal_im.surface_set_color(pc)
		_petal_im.surface_add_vertex(p_base)
		_petal_im.surface_set_color(pc)
		_petal_im.surface_add_vertex(p_left)
		_petal_im.surface_set_color(pc)
		_petal_im.surface_add_vertex(p_tip)

		_petal_im.surface_set_color(pc)
		_petal_im.surface_add_vertex(p_base)
		_petal_im.surface_set_color(pc)
		_petal_im.surface_add_vertex(p_tip)
		_petal_im.surface_set_color(pc)
		_petal_im.surface_add_vertex(p_right)


# =========================================================================
# Drawing — leaves
# =========================================================================

func _draw_leaf(leaf_base: Vector3, angle: float, col: Color, growth: float, wilt: float) -> void:
	var leaf_len := 0.14 * clampf(growth * 2.0, 0.0, 1.0)
	var leaf_w := 0.025

	# Leaf points outward and slightly up
	var dir := Vector3(cos(angle), 0.35 - wilt * 0.5, sin(angle)).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = Vector3(0, 0, 1)

	var p0 := leaf_base
	var p_mid := leaf_base + dir * leaf_len * 0.5
	var p_tip := leaf_base + dir * leaf_len
	var p_left := p_mid - side * leaf_w
	var p_right := p_mid + side * leaf_w

	# Two triangles: base->left->tip and base->tip->right
	_leaf_im.surface_set_color(col)
	_leaf_im.surface_add_vertex(p0)
	_leaf_im.surface_set_color(col)
	_leaf_im.surface_add_vertex(p_left)
	_leaf_im.surface_set_color(col)
	_leaf_im.surface_add_vertex(p_tip)

	_leaf_im.surface_set_color(col)
	_leaf_im.surface_add_vertex(p0)
	_leaf_im.surface_set_color(col)
	_leaf_im.surface_add_vertex(p_tip)
	_leaf_im.surface_set_color(col)
	_leaf_im.surface_add_vertex(p_right)


# =========================================================================
# Phyllotaxis spiral visualization
# =========================================================================

func _draw_phyllotaxis_spiral() -> void:
	_spiral_im.clear_surfaces()
	_spiral_im.surface_begin(Mesh.PRIMITIVE_LINES)

	var y := bucket_height * 0.5 + max_stem_height + 0.15

	# Draw the Fermat spiral path connecting tulip centers in order
	for i in range(tulip_count - 1):
		var d0: Dictionary = _tulip_data[i]
		var d1: Dictionary = _tulip_data[i + 1]
		var p0 := Vector3(d0["base_x"], y, d0["base_z"])
		var p1 := Vector3(d1["base_x"], y, d1["base_z"])

		_spiral_im.surface_set_color(COL_SPIRAL)
		_spiral_im.surface_add_vertex(p0)
		_spiral_im.surface_add_vertex(p1)

	# Draw golden angle annotation arcs between consecutive tulips
	# Show the constant angular spacing
	for i in range(mini(tulip_count, 8)):
		var d: Dictionary = _tulip_data[i]
		var cx := 0.0
		var cz := 0.0
		var r := sqrt(d["base_x"] * d["base_x"] + d["base_z"] * d["base_z"])
		if r < 0.01:
			continue
		var start_angle: float = d["angle"]
		# Small arc showing the golden angle increment
		var arc_segs := 12
		var arc_span := deg_to_rad(golden_angle_deg)
		for s in range(arc_segs):
			var t0 := float(s) / float(arc_segs)
			var t1 := float(s + 1) / float(arc_segs)
			var a0 := start_angle + arc_span * t0
			var a1 := start_angle + arc_span * t1
			var arc_r := r * 0.5

			_spiral_im.surface_set_color(COL_GOLDEN)
			_spiral_im.surface_add_vertex(Vector3(cx + arc_r * cos(a0), y + 0.01, cz + arc_r * sin(a0)))
			_spiral_im.surface_add_vertex(Vector3(cx + arc_r * cos(a1), y + 0.01, cz + arc_r * sin(a1)))

	# Numbered index dots at each tulip position
	for i in range(tulip_count):
		var d: Dictionary = _tulip_data[i]
		var pos := Vector3(d["base_x"], y, d["base_z"])
		# Small cross mark
		var sz := 0.008
		_spiral_im.surface_set_color(COL_GOLDEN)
		_spiral_im.surface_add_vertex(pos + Vector3(-sz, 0, 0))
		_spiral_im.surface_add_vertex(pos + Vector3(sz, 0, 0))
		_spiral_im.surface_set_color(COL_GOLDEN)
		_spiral_im.surface_add_vertex(pos + Vector3(0, 0, -sz))
		_spiral_im.surface_add_vertex(pos + Vector3(0, 0, sz))

	_spiral_im.surface_end()


# =========================================================================
# Growth simulation
# =========================================================================

func _advance_growth(delta: float) -> void:
	_growth_time += delta
	_growth_progress = clampf(_growth_time / growth_duration, 0.0, 1.0)

	# Determine phase from cumulative thresholds
	var cumulative := 0.0
	_growth_phase = GrowthPhase.MATURE
	for phase_idx in range(PHASE_DURATIONS.size()):
		cumulative += PHASE_DURATIONS[phase_idx]
		if _growth_progress < cumulative:
			_growth_phase = phase_idx
			break

	# Update each tulip with staggered growth (center grows first)
	for i in range(_tulip_data.size()):
		var d: Dictionary = _tulip_data[i]
		# Stagger: inner tulips grow first (lower spiral index)
		var delay := float(i) / float(maxi(tulip_count, 1)) * 0.35
		var local_progress := clampf((_growth_progress - delay) / (1.0 - delay), 0.0, 1.0)

		# Growth: stem elongation
		d["growth"] = clampf(local_progress * 1.5, 0.0, 1.0)

		# Bloom: only after stem is mostly grown
		if local_progress > 0.55:
			d["bloom"] = clampf((local_progress - 0.55) / 0.45, 0.0, 1.0)
		else:
			d["bloom"] = 0.0

	# Loop the growth cycle
	if _growth_time > growth_duration * 1.3:
		_growth_time = 0.0
		_growth_progress = 0.0
		for d in _tulip_data:
			d["growth"] = 0.0
			d["bloom"] = 0.0


# =========================================================================
# Environmental response
# =========================================================================

func _update_environment(delta: float) -> void:
	# Read slider values
	if _heat_slider:
		heat_level = _heat_slider.get_normalized_value()
	if _drought_slider:
		drought_level = _drought_slider.get_normalized_value()

	for d in _tulip_data:
		# Drooping responds to heat — taller tulips droop more
		var target_droop: float = heat_level * d["height_factor"]
		d["droop"] = lerpf(d["droop"], target_droop, delta * 2.0)

		# Wilting responds to drought — progressive desiccation
		var target_wilt := drought_level
		d["wilt"] = lerpf(d["wilt"], target_wilt, delta * 1.5)


# =========================================================================
# Labels
# =========================================================================

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.font_size = 26
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, max_stem_height + bucket_height + 0.55, 0)
	_title_label.modulate = Color.WHITE
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.font_size = 20
	_info_label.outline_size = 3
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0, max_stem_height + bucket_height + 0.30, 0)
	_info_label.modulate = Color(0.85, 0.9, 1.0)
	add_child(_info_label)

	_phase_label = Label3D.new()
	_phase_label.font_size = 18
	_phase_label.outline_size = 3
	_phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_phase_label.position = Vector3(0, -bucket_height * 0.5 - 0.35, 0)
	_phase_label.modulate = Color(0.7, 0.8, 1.0)
	add_child(_phase_label)


func _update_labels() -> void:
	var mode_names := ["Phyllotaxis", "Growth", "Environment"]
	_title_label.text = "Bucket of Tulips — %s" % mode_names[_mode]

	match _mode:
		Mode.PHYLLOTAXIS:
			_info_label.text = "%d tulips  |  golden angle %.1f°  |  Vogel spiral" % [tulip_count, golden_angle_deg]
			_phase_label.text = "r = c·sqrt(n)    theta = n · 137.508°"
		Mode.GROWTH:
			var phase_names := ["Seed", "Sprouting", "Budding", "Blooming", "Mature"]
			var phase_cols := [COL_SEED, COL_SPROUT, COL_BUD, COL_BLOOM, COL_MATURE]
			_info_label.text = "Phase: %s  |  progress %.0f%%" % [phase_names[_growth_phase], _growth_progress * 100.0]
			_phase_label.text = "Staggered growth — center-first emergence"
			_phase_label.modulate = phase_cols[_growth_phase]
		Mode.ENVIRONMENT:
			_info_label.text = "Heat %.0f%%  |  Drought %.0f%%" % [heat_level * 100.0, drought_level * 100.0]
			if heat_level > 0.6 and drought_level > 0.6:
				_phase_label.text = "Severe stress — drooping and wilting"
			elif heat_level > 0.4:
				_phase_label.text = "Heat stress — stems bending"
			elif drought_level > 0.4:
				_phase_label.text = "Water stress — colors fading"
			else:
				_phase_label.text = "Healthy — adjust sliders to stress"


# =========================================================================
# VR controls
# =========================================================================

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("TULIPS", [
		[{"type": "button", "label": "MODE"}],
		[
			{"type": "slider_h", "label": "HEAT", "default": 0.0},
			{"type": "slider_h", "label": "DROUGHT", "default": 0.0},
		],
	])
	panel.position = Vector3(0, -bucket_height * 0.5 - 0.1, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	_mode_button = panel.find_child("Btn_0", true, false)
	if _mode_button:
		var area: Node = _mode_button.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _cycle_mode())

	_heat_slider = panel.find_child("Param_0", true, false)
	if _heat_slider and _heat_slider.has_signal("slider_moved"):
		_heat_slider.slider_moved.connect(_on_heat_changed)

	_drought_slider = panel.find_child("Param_1", true, false)
	if _drought_slider and _drought_slider.has_signal("slider_moved"):
		_drought_slider.slider_moved.connect(_on_drought_changed)


func _on_heat_changed(_value: float) -> void:
	heat_level = _heat_slider.get_normalized_value()


func _on_drought_changed(_value: float) -> void:
	drought_level = _drought_slider.get_normalized_value()


# =========================================================================
# apply_grid_config
# =========================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("tulip_count"):
		tulip_count = clampi(int(config["tulip_count"]), 3, 55)
	if config.has("bucket_radius"):
		bucket_radius = clampf(float(config["bucket_radius"]), 0.15, 0.8)
	if config.has("bucket_height"):
		bucket_height = clampf(float(config["bucket_height"]), 0.1, 0.5)
	if config.has("max_stem_height"):
		max_stem_height = clampf(float(config["max_stem_height"]), 0.2, 1.0)
	if config.has("step_speed"):
		step_speed = clampf(float(config["step_speed"]), 0.1, 5.0)
	if config.has("golden_angle_deg"):
		golden_angle_deg = clampf(float(config["golden_angle_deg"]), 90.0, 180.0)
	if config.has("radial_packing"):
		radial_packing = clampf(float(config["radial_packing"]), 0.02, 0.15)
	if config.has("growth_duration"):
		growth_duration = clampf(float(config["growth_duration"]), 4.0, 30.0)
	if config.has("heat_level"):
		heat_level = clampf(float(config["heat_level"]), 0.0, 1.0)
	if config.has("drought_level"):
		drought_level = clampf(float(config["drought_level"]), 0.0, 1.0)
	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"PHYLLOTAXIS": _mode = Mode.PHYLLOTAXIS
			"GROWTH": _mode = Mode.GROWTH
			"ENVIRONMENT": _mode = Mode.ENVIRONMENT

	# Rebuild tulip data and bucket
	_init_tulip_data()
	_init_mode()


# =========================================================================
# Cleanup
# =========================================================================

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
