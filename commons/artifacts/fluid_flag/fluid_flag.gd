# FluidFlag.gd
# The Fluid Flag — a tall hanging cloth banner with vertical stripes in the
# genderfluid-pride palette (pink / soft-white / magenta / near-black / blue /
# light-blue), drawn on a subdivided plane with a sine ripple baked into the
# verts so it reads as soft fabric. A thin top crossbar holds it up; the cloth
# breathes with a cheap per-frame wave.
#
# @identity
# essence: A flag is a surface that admits motion. Six vertical bands of colour
#   hang from a bar and never sit still — the ripple is sine, the same wave that
#   teaches phase on every other bench, here let loose on cloth.
# desire: To make an identity-banner that is not a flat decal but a living mesh —
#   colour you can walk behind, fabric that catches a wind that isn't there.
# critical_parameter: ripple_amount (z displacement) × wave_speed. Set ripple to
#   zero and it is a painted board; raise it and the bands shimmer.
# truth: A boundary that can wave is not a wall. The stripes stay distinct while
#   the whole sheet moves as one.
extends Node3D
class_name FluidFlag

# ── Genderfluid-pride stripe palette, left → right across the width ───────────
const STRIPE_COLORS: Array[Color] = [
	Color(1.0, 0.45, 0.7),    # pink
	Color(1.0, 0.8, 0.9),     # soft white / light pink
	Color(0.7, 0.1, 0.85),    # bright purple / magenta
	Color(0.1, 0.1, 0.12),    # near-black
	Color(0.2, 0.35, 0.9),    # blue
	Color(0.45, 0.7, 1.0)     # light blue
]

# ── DNA knobs (overridable via apply_grid_config) ────────────────────────────
@export var flag_width: float = 0.9      # cloth width in metres (portrait, so < height)
@export var flag_height: float = 1.6     # cloth height in metres
@export var ripple_amount: float = 0.06  # peak z displacement of the cloth (metres)
@export var ripple_waves: float = 2.2    # how many sine periods span the width
@export var wave_speed: float = 1.1      # animation rate of the breathing wave
@export var animate: bool = true         # cheap per-frame wave in _process
@export var show_pole: bool = true       # thin top crossbar the cloth hangs from
@export var pole_height: float = 1.7     # top-edge height of the cloth (hang point)
@export var cols: int = 12               # quad columns (across width)
@export var rows: int = 20               # quad rows (down height)
@export var roughness_amt: float = 0.85  # matte fabric

# ── Runtime references ───────────────────────────────────────────────────────
var _cloth: MeshInstance3D = null
var _cloth_mesh: ArrayMesh = null
var _cloth_material: StandardMaterial3D = null
var _wave_phase: float = 0.0

# Cached base (un-animated) vertex positions so the wave can re-displace from a
# clean reference every frame instead of accumulating drift.
var _base_verts: PackedVector3Array = PackedVector3Array()
var _base_normals: PackedVector3Array = PackedVector3Array()
var _uvs: PackedVector2Array = PackedVector2Array()
var _colors: PackedColorArray = PackedColorArray()
var _indices: PackedInt32Array = PackedInt32Array()


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build()


func _build() -> void:
	# Clear any previous build (supports a rebuild from apply_grid_config).
	if _cloth != null and is_instance_valid(_cloth):
		_cloth.queue_free()
		_cloth = null

	_clamp_knobs()
	_build_material()
	_build_cloth()
	if show_pole:
		_build_pole()


## Keep the subdivision + sizes sane so an empty config never breaks the mesh.
func _clamp_knobs() -> void:
	cols = maxi(cols, 2)
	rows = maxi(rows, 2)
	flag_width = maxf(flag_width, 0.05)
	flag_height = maxf(flag_height, 0.05)
	pole_height = maxf(pole_height, flag_height)


# ═════════════════════════════════════════════════════════════════════════
# MATERIAL — matte, double-sided, vertex-coloured fabric
# ═════════════════════════════════════════════════════════════════════════

func _build_material() -> void:
	_cloth_material = StandardMaterial3D.new()
	_cloth_material.vertex_color_use_as_albedo = true
	_cloth_material.albedo_color = Color(1.0, 1.0, 1.0)
	_cloth_material.roughness = clampf(roughness_amt, 0.0, 1.0)
	_cloth_material.metallic = 0.0
	# Cloth is thin — render both faces so it reads from behind.
	_cloth_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# A faint self-glow keeps the dark stripe legible in dim lab light.
	_cloth_material.emission_enabled = true
	_cloth_material.emission = Color(0.06, 0.06, 0.08)
	_cloth_material.emission_energy_multiplier = 0.35


# ═════════════════════════════════════════════════════════════════════════
# CLOTH — subdivided vertical plane, sine ripple baked in, stripes by x
# Origin at the bottom-centre of the cloth; the sheet rises to pole_height.
# ═════════════════════════════════════════════════════════════════════════

func _build_cloth() -> void:
	_base_verts = PackedVector3Array()
	_base_normals = PackedVector3Array()
	_uvs = PackedVector2Array()
	_colors = PackedColorArray()
	_indices = PackedInt32Array()

	var verts_x: int = cols + 1
	var verts_y: int = rows + 1
	var half_w: float = flag_width * 0.5
	var bottom_y: float = pole_height - flag_height  # hang from the top crossbar

	var iy: int = 0
	while iy < verts_y:
		var v_norm: float = float(iy) / float(rows)          # 0 at bottom, 1 at top
		var py: float = bottom_y + v_norm * flag_height
		var ix: int = 0
		while ix < verts_x:
			var u_norm: float = float(ix) / float(cols)      # 0 left, 1 right
			var px: float = -half_w + u_norm * flag_width

			# Baked rest ripple: a horizontal sine across the width, slightly
			# stronger toward the free bottom edge so the top hem stays taut.
			var sag: float = 1.0 - v_norm                    # 1 at bottom, 0 at top
			var pz: float = sin(u_norm * ripple_waves * TAU) * ripple_amount * (0.35 + 0.65 * sag)

			_base_verts.push_back(Vector3(px, py, pz))
			_uvs.push_back(Vector2(u_norm, 1.0 - v_norm))
			_colors.push_back(_stripe_color(u_norm))
			ix += 1
		iy += 1

	_build_indices(verts_x, verts_y)
	_recompute_normals()
	_upload_mesh()

	_cloth = MeshInstance3D.new()
	_cloth.name = "Cloth"
	_cloth.mesh = _cloth_mesh
	_cloth.material_override = _cloth_material
	add_child(_cloth)


## Triangulate the grid (two triangles per quad), wound so the +z face is front.
func _build_indices(verts_x: int, verts_y: int) -> void:
	var iy: int = 0
	while iy < verts_y - 1:
		var ix: int = 0
		while ix < verts_x - 1:
			var i00: int = iy * verts_x + ix
			var i10: int = i00 + 1
			var i01: int = i00 + verts_x
			var i11: int = i01 + 1
			# Triangle A
			_indices.push_back(i00)
			_indices.push_back(i01)
			_indices.push_back(i11)
			# Triangle B
			_indices.push_back(i00)
			_indices.push_back(i11)
			_indices.push_back(i10)
			ix += 1
		iy += 1


## Map a normalised x (0..1) to a stripe colour, blended near each seam so the
## bands meet softly rather than aliasing.
func _stripe_color(u_norm: float) -> Color:
	var n: int = STRIPE_COLORS.size()
	var scaled: float = clampf(u_norm, 0.0, 0.99999) * float(n)
	var idx: int = int(floor(scaled))
	idx = clampi(idx, 0, n - 1)
	var frac: float = scaled - float(idx)
	# Blend zone width (fraction of a stripe) for the soft seam.
	var blend: float = 0.18
	if frac > 1.0 - blend and idx < n - 1:
		var t: float = (frac - (1.0 - blend)) / blend
		return STRIPE_COLORS[idx].lerp(STRIPE_COLORS[idx + 1], clampf(t, 0.0, 1.0) * 0.5)
	if frac < blend and idx > 0:
		var t2: float = (blend - frac) / blend
		return STRIPE_COLORS[idx].lerp(STRIPE_COLORS[idx - 1], clampf(t2, 0.0, 1.0) * 0.5)
	return STRIPE_COLORS[idx]


# ═════════════════════════════════════════════════════════════════════════
# NORMALS + UPLOAD
# ═════════════════════════════════════════════════════════════════════════

## Recompute smooth per-vertex normals from the current _base_verts + _indices.
func _recompute_normals() -> void:
	var count: int = _base_verts.size()
	_base_normals = PackedVector3Array()
	_base_normals.resize(count)
	var k: int = 0
	while k < count:
		_base_normals[k] = Vector3.ZERO
		k += 1

	var t: int = 0
	while t < _indices.size():
		var a: int = _indices[t]
		var b: int = _indices[t + 1]
		var c: int = _indices[t + 2]
		var va: Vector3 = _base_verts[a]
		var vb: Vector3 = _base_verts[b]
		var vc: Vector3 = _base_verts[c]
		var face_n: Vector3 = (vb - va).cross(vc - va)
		_base_normals[a] += face_n
		_base_normals[b] += face_n
		_base_normals[c] += face_n
		t += 3

	var m: int = 0
	while m < count:
		var nrm: Vector3 = _base_normals[m]
		if nrm.length() > 0.00001:
			_base_normals[m] = nrm.normalized()
		else:
			_base_normals[m] = Vector3(0.0, 0.0, 1.0)
		m += 1


## Build (or rebuild) the ArrayMesh surface from the current base buffers.
func _upload_mesh() -> void:
	if _cloth_mesh == null:
		_cloth_mesh = ArrayMesh.new()
	_cloth_mesh.clear_surfaces()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _base_verts
	arrays[Mesh.ARRAY_NORMAL] = _base_normals
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	_cloth_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


# ═════════════════════════════════════════════════════════════════════════
# POLE — thin top crossbar the cloth hangs from + two stubby end caps
# ═════════════════════════════════════════════════════════════════════════

func _build_pole() -> void:
	var bar_mat: StandardMaterial3D = StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.22, 0.22, 0.26)
	bar_mat.metallic = 0.6
	bar_mat.roughness = 0.4

	# Horizontal crossbar along x at the top of the cloth.
	var bar: MeshInstance3D = MeshInstance3D.new()
	bar.name = "Crossbar"
	var bar_cyl: CylinderMesh = CylinderMesh.new()
	bar_cyl.top_radius = 0.018
	bar_cyl.bottom_radius = 0.018
	bar_cyl.height = flag_width + 0.16
	bar.mesh = bar_cyl
	bar.material_override = bar_mat
	# CylinderMesh is +y by default; rotate to lie along x.
	bar.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	bar.position = Vector3(0.0, pole_height + 0.02, 0.0)
	add_child(bar)

	# Two end knobs.
	var half_span: float = (flag_width + 0.16) * 0.5
	var side: int = 0
	while side < 2:
		var sign_x: float = -1.0 if side == 0 else 1.0
		var knob: MeshInstance3D = MeshInstance3D.new()
		knob.name = "Knob%d" % side
		var ball: SphereMesh = SphereMesh.new()
		ball.radius = 0.03
		ball.height = 0.06
		ball.radial_segments = 12
		ball.rings = 8
		knob.mesh = ball
		knob.material_override = bar_mat
		knob.position = Vector3(sign_x * half_span, pole_height + 0.02, 0.0)
		add_child(knob)
		side += 1


# ═════════════════════════════════════════════════════════════════════════
# ANIMATION — cheap travelling wave re-displacing z from the baked rest pose
# ═════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not animate:
		return
	if _cloth_mesh == null or _base_verts.is_empty():
		return

	_wave_phase += delta * wave_speed

	var verts_x: int = cols + 1
	var verts_y: int = rows + 1
	var animated: PackedVector3Array = PackedVector3Array()
	animated.resize(_base_verts.size())

	var iy: int = 0
	while iy < verts_y:
		var v_norm: float = float(iy) / float(rows)
		var sag: float = 1.0 - v_norm           # bottom edge moves most
		var ix: int = 0
		while ix < verts_x:
			var k: int = iy * verts_x + ix
			var base_v: Vector3 = _base_verts[k]
			var u_norm: float = float(ix) / float(cols)
			# Travelling wave: phase shifts across width and a little down height.
			var arg: float = u_norm * ripple_waves * TAU - _wave_phase + v_norm * 1.4
			var extra_z: float = sin(arg) * ripple_amount * 0.45 * (0.3 + 0.7 * sag)
			animated[k] = Vector3(base_v.x, base_v.y, base_v.z + extra_z)
			ix += 1
		iy += 1

	# Re-upload only the vertex buffer's worth; keep cached normals (cheap — the
	# lighting wobble from a soft cloth wave is imperceptible at this amplitude).
	_cloth_mesh.clear_surfaces()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = animated
	arrays[Mesh.ARRAY_NORMAL] = _base_normals
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	_cloth_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG — DNA knobs from map_data.json, then rebuild if already built
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null:
		return
	if config_data.has("flag_width"):
		flag_width = float(config_data["flag_width"])
	if config_data.has("flag_height"):
		flag_height = float(config_data["flag_height"])
	if config_data.has("ripple_amount"):
		ripple_amount = float(config_data["ripple_amount"])
	if config_data.has("ripple_waves"):
		ripple_waves = float(config_data["ripple_waves"])
	if config_data.has("wave_speed"):
		wave_speed = float(config_data["wave_speed"])
	if config_data.has("animate"):
		animate = bool(config_data["animate"])
	if config_data.has("show_pole"):
		show_pole = bool(config_data["show_pole"])
	if config_data.has("pole_height"):
		pole_height = float(config_data["pole_height"])
	if config_data.has("cols"):
		cols = int(config_data["cols"])
	if config_data.has("rows"):
		rows = int(config_data["rows"])
	if config_data.has("roughness_amt"):
		roughness_amt = float(config_data["roughness_amt"])

	# Rebuild only if we've already built once (node is inside the tree).
	if is_inside_tree():
		_build()
