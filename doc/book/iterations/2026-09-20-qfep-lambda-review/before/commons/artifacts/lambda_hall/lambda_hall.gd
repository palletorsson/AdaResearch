# lambda_hall.gd
# Walk-in architecture: the lambda edge as a hall. The west wall is a
# perfect frozen lattice (F: order), the east wall is the same lattice
# shattered and boiling (E: entropy), and between them six column rows
# interpolate by their x-position mapped to lambda 0..1. The only lit
# floor is a narrow walkway at lambda = 0.35 — the player literally
# walks the edge of chaos down the full length of the hall.
#
# QFE = F − λ·E(S) + φ·dE — qfeplaboratory, spine order 18.
#
# @identity
# essence: the complete QFEP formula embodied as a corridor — order to the
#   left, entropy to the right, life only on the narrow band between
# desire: a player pauses mid-hall, looks left at the crystal, right at the
#   fire, then down at the glowing line under their feet and understands λ
# critical_parameter: lambda_value — where the walkway sits between the walls
# triggers: apply_grid_config rebuilds the hall from DNA (length, width,
#   lambda, seed, colours)
# emerges: the spine's own phase structure (F_order → E_entropy → lambda_edge)
#   made walkable at body scale
# needs: nothing beyond the grid cell it occupies; open at both ends
# relationships: cellularautomata (λ is Langton's lambda — the same edge in
#   rule space); the spine's three-act phase structure; soft_stages ecology,
#   whose density curve climbs exactly this band
# truth: life is neither the crystal nor the fire — it is the corridor
#   between them, and it is narrow
#
# GDScript 4.6. Procedural only — everything built in _ready().

extends Node3D
class_name LambdaHall

# ── DNA ──────────────────────────────────────────────────────────────
@export var hall_length: float = 14.0      # Z extent
@export var hall_width: float = 7.0        # X extent (order wall ↔ chaos wall)
@export var hall_height: float = 4.0
@export var lambda_value: float = 0.35     # walkway position, 0=order 1=chaos
@export var rng_seed: int = 46
@export var order_color: Color = Color(0.62, 0.78, 0.94)   # pale ice-blue
@export var chaos_color: Color = Color(1.0, 0.18, 0.55)    # hot magenta
@export var chaos_color_b: Color = Color(1.0, 0.46, 0.10)  # hot orange
@export var edge_color: Color = Color(0.30, 1.0, 0.72)     # phosphor green-cyan

const CUBE_SIZE: float = 0.42
const WALL_STEP: float = 0.55
const WALK_WIDTH: float = 1.4
const DRIFTER_COUNT: int = 12
const ROW_FRACTIONS: Array[float] = [0.08, 0.21, 0.48, 0.62, 0.76, 0.90]

# ── runtime refs (guarded in _process) ───────────────────────────────
var _drifters: Array[Dictionary] = []      # {node, base, axis, spin, amp, phase}
var _pulse_mats: Array[Dictionary] = []    # {mat, base_energy, phase}
var _order_mat: StandardMaterial3D = null
var _order_base_energy: float = 0.7
var _walk_mat: StandardMaterial3D = null
var _walk_hsv: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _built: bool = false


func _ready() -> void:
	_build()


# ── grid config ──────────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("hall_length"):
		hall_length = float(config_data["hall_length"])
	if config_data.has("hall_width"):
		hall_width = float(config_data["hall_width"])
	if config_data.has("hall_height"):
		hall_height = float(config_data["hall_height"])
	if config_data.has("lambda_value"):
		lambda_value = clampf(float(config_data["lambda_value"]), 0.05, 0.95)
	elif config_data.has("lambda"):
		lambda_value = clampf(float(config_data["lambda"]), 0.05, 0.95)
	if config_data.has("rng_seed"):
		rng_seed = int(config_data["rng_seed"])
	elif config_data.has("seed"):
		rng_seed = int(config_data["seed"])
	order_color = _parse_color(config_data.get("order_color", order_color), order_color)
	chaos_color = _parse_color(config_data.get("chaos_color", chaos_color), chaos_color)
	chaos_color_b = _parse_color(config_data.get("chaos_color_b", chaos_color_b), chaos_color_b)
	edge_color = _parse_color(config_data.get("edge_color", edge_color), edge_color)
	if config_data.has("scale"):
		var s: float = maxf(0.1, float(config_data["scale"]))
		scale = Vector3(s, s, s)
	_build()


func _parse_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var txt: String = value
		if Color.html_is_valid(txt):
			return Color.html(txt)
		return fallback
	if value is Array:
		var arr: Array = value
		if arr.size() >= 3:
			return Color(float(arr[0]), float(arr[1]), float(arr[2]))
	return fallback


# ── build ────────────────────────────────────────────────────────────

func _build() -> void:
	_clear_build()
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	var half_w: float = hall_width * 0.5
	var half_l: float = hall_length * 0.5
	var walk_x: float = -half_w + lambda_value * hall_width
	var walk_half: float = WALK_WIDTH * 0.5

	_build_floor(half_w, half_l, walk_x, walk_half)
	_build_order_wall(-half_w, half_l)
	_build_chaos_wall(half_w, half_l, rng)
	_build_lambda_rows(half_w, half_l, walk_x, walk_half, rng)
	_build_kerbs(half_w, half_l)
	_build_inscriptions(half_l, walk_x)
	_build_capture_camera(walk_x, half_l)
	_built = true


func _clear_build() -> void:
	_built = false
	_drifters.clear()
	_pulse_mats.clear()
	_order_mat = null
	_walk_mat = null
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _cube_mesh() -> BoxMesh:
	var box := BoxMesh.new()
	box.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
	return box


func _emissive_mat(albedo: Color, emit: Color, energy: float, use_vertex: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.emission_enabled = true
	m.emission = emit
	m.emission_energy_multiplier = energy
	m.roughness = 0.55
	m.metallic = 0.1
	if use_vertex:
		m.vertex_color_use_as_albedo = true
	return m


# ── floor + walkway ──────────────────────────────────────────────────

func _build_floor(half_w: float, half_l: float, walk_x: float, walk_half: float) -> void:
	# Dark floor slab — the unlit ground everywhere except the walkway.
	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorBody"
	add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "FloorMesh"
	var fbox := BoxMesh.new()
	fbox.size = Vector3(hall_width, 0.12, hall_length)
	floor_mesh.mesh = fbox
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.045, 0.05, 0.065)
	fmat.roughness = 0.95
	floor_mesh.material_override = fmat
	floor_mesh.position = Vector3(0.0, -0.04, 0.0)
	floor_body.add_child(floor_mesh)

	var fcol := CollisionShape3D.new()
	var fshape := BoxShape3D.new()
	fshape.size = Vector3(hall_width, 0.12, hall_length)
	fcol.shape = fshape
	fcol.position = Vector3(0.0, -0.04, 0.0)
	floor_body.add_child(fcol)

	# The walkway — the only lit floor, at the lambda line.
	var walk := MeshInstance3D.new()
	walk.name = "Walkway"
	var wbox := BoxMesh.new()
	wbox.size = Vector3(walk_half * 2.0, 0.06, hall_length)
	walk.mesh = wbox
	_walk_mat = _emissive_mat(edge_color.darkened(0.35), edge_color, 1.6, false)
	walk.material_override = _walk_mat
	walk.position = Vector3(walk_x, 0.03, 0.0)
	add_child(walk)
	_walk_hsv = Vector3(edge_color.h, edge_color.s, edge_color.v)

	# Faint guide strips at the walkway edges.
	for side in [-1.0, 1.0]:
		var strip := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(0.06, 0.08, hall_length)
		strip.mesh = sbox
		strip.material_override = _emissive_mat(edge_color, edge_color, 2.4, false)
		strip.position = Vector3(walk_x + float(side) * walk_half, 0.04, 0.0)
		add_child(strip)


# ── order wall: F ────────────────────────────────────────────────────

func _build_order_wall(wall_x: float, half_l: float) -> void:
	var z_count: int = int(floor(hall_length / WALL_STEP))
	var y_count: int = int(floor((hall_height - 0.3) / WALL_STEP))
	var total: int = z_count * y_count

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _cube_mesh()
	mm.instance_count = total

	var idx: int = 0
	for zi in range(z_count):
		for yi in range(y_count):
			var pos := Vector3(
				wall_x,
				0.35 + float(yi) * WALL_STEP,
				-half_l + WALL_STEP * 0.5 + float(zi) * WALL_STEP)
			mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, pos))
			idx += 1

	var inst := MultiMeshInstance3D.new()
	inst.name = "OrderWall"
	inst.multimesh = mm
	_order_mat = _emissive_mat(order_color, order_color, _order_base_energy, false)
	_order_mat.roughness = 0.25
	_order_mat.metallic = 0.4
	inst.material_override = _order_mat
	add_child(inst)


# ── chaos wall: E ────────────────────────────────────────────────────

func _build_chaos_wall(wall_x: float, half_l: float, rng: RandomNumberGenerator) -> void:
	var z_count: int = int(floor(hall_length / WALL_STEP))
	var y_count: int = int(floor((hall_height - 0.3) / WALL_STEP))
	var total: int = z_count * y_count

	# Reserve DRIFTER_COUNT slots as free-floating animated cubes.
	var drifter_slots: Dictionary = {}
	var guard: int = 0
	while drifter_slots.size() < DRIFTER_COUNT and guard < 200:
		drifter_slots[rng.randi_range(0, total - 1)] = true
		guard += 1

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true          # must be set before instance_count
	mm.mesh = _cube_mesh()
	mm.instance_count = total - drifter_slots.size()

	var drift_mat: StandardMaterial3D = _emissive_mat(Color.WHITE, chaos_color, 2.6, true)
	var slot: int = 0
	var write: int = 0
	for zi in range(z_count):
		for yi in range(y_count):
			var base := Vector3(
				wall_x,
				0.35 + float(yi) * WALL_STEP,
				-half_l + WALL_STEP * 0.5 + float(zi) * WALL_STEP)
			var jitter := Vector3(
				-rng.randf_range(0.0, 1.1),   # only inward — off the wall
				rng.randf_range(-0.4, 0.5),
				rng.randf_range(-0.45, 0.45))
			var pos: Vector3 = base + jitter
			var mix: float = rng.randf()
			var col: Color = chaos_color.lerp(chaos_color_b, mix)
			if drifter_slots.has(slot):
				_spawn_drifter(pos, col, drift_mat, rng)
			else:
				var cube_basis := Basis(Vector3(rng.randf_range(-1.0, 1.0),
					rng.randf_range(-1.0, 1.0),
					rng.randf_range(-1.0, 1.0)).normalized(),
					rng.randf_range(0.0, TAU))
				var s: float = rng.randf_range(0.45, 1.5)
				cube_basis = cube_basis.scaled(Vector3(s, s, s))
				mm.set_instance_transform(write, Transform3D(cube_basis, pos))
				mm.set_instance_color(write, col)
				write += 1
			slot += 1

	var inst := MultiMeshInstance3D.new()
	inst.name = "ChaosWall"
	inst.multimesh = mm
	inst.material_override = _emissive_mat(Color.WHITE, chaos_color.lerp(chaos_color_b, 0.4), 2.2, true)
	add_child(inst)


func _spawn_drifter(pos: Vector3, col: Color, mat: StandardMaterial3D, rng: RandomNumberGenerator) -> void:
	var cube := MeshInstance3D.new()
	cube.mesh = _cube_mesh()
	var own_mat: StandardMaterial3D = mat.duplicate() as StandardMaterial3D
	own_mat.albedo_color = col
	own_mat.emission = col
	cube.material_override = own_mat
	cube.position = pos
	var s: float = rng.randf_range(0.4, 0.9)
	cube.scale = Vector3(s, s, s)
	add_child(cube)
	_drifters.append({
		"node": cube,
		"base": pos,
		"axis": Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0),
			rng.randf_range(-1.0, 1.0)).normalized(),
		"spin": rng.randf_range(0.4, 1.3),
		"amp": rng.randf_range(0.10, 0.30),
		"phase": rng.randf_range(0.0, TAU),
	})


# ── interpolation rows: walking lambda ───────────────────────────────

func _build_lambda_rows(half_w: float, half_l: float, walk_x: float, walk_half: float,
		rng: RandomNumberGenerator) -> void:
	var clearance: float = walk_half + 0.45
	var z_step: float = 1.65
	var z_count: int = int(floor(hall_length / z_step))
	var y_levels: Array[float] = [0.5, 1.4, 2.3, 3.2]

	for frac in ROW_FRACTIONS:
		var row_x: float = -half_w + frac * hall_width
		# Keep rows off the walkway.
		if absf(row_x - walk_x) < clearance:
			if row_x < walk_x:
				row_x = walk_x - clearance
			else:
				row_x = walk_x + clearance
		var lam: float = clampf((row_x + half_w) / hall_width, 0.0, 1.0)
		# Band weight: 1 at the living edge, 0 far from it.
		var w: float = clampf(1.0 - absf(lam - lambda_value) / 0.40, 0.0, 1.0)

		var hot: Color = chaos_color.lerp(chaos_color_b, 0.5)
		var base_col: Color = order_color.lerp(hot, lam)
		var row_col: Color = base_col.lerp(edge_color, w * 0.85)
		var energy: float = lerpf(0.5, 2.3, lam) + w * 1.6

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true      # before instance_count
		mm.mesh = _cube_mesh()
		mm.instance_count = z_count * y_levels.size()

		var idx: int = 0
		for zi in range(z_count):
			var z: float = -half_l + z_step * 0.5 + float(zi) * z_step
			for y in y_levels:
				var p := Vector3(row_x, y, z)
				p.x += rng.randf_range(-1.0, 1.0) * lam * 0.40
				p.y += rng.randf_range(-1.0, 1.0) * lam * 0.30
				p.z += rng.randf_range(-1.0, 1.0) * lam * 0.40
				var cube_basis := Basis(Vector3(rng.randf_range(-1.0, 1.0),
					rng.randf_range(-1.0, 1.0),
					rng.randf_range(-1.0, 1.0)).normalized(),
					rng.randf_range(0.0, TAU) * lam)
				var s: float = 1.0 + rng.randf_range(-1.0, 1.0) * lam * 0.4
				cube_basis = cube_basis.scaled(Vector3(s, s, s))
				mm.set_instance_transform(idx, Transform3D(cube_basis, p))
				var tint: Color = row_col.lerp(row_col.lightened(0.25), rng.randf())
				mm.set_instance_color(idx, tint)
				idx += 1

		var inst := MultiMeshInstance3D.new()
		inst.name = "LambdaRow_%02d" % int(frac * 100.0)
		inst.multimesh = mm
		var mat: StandardMaterial3D = _emissive_mat(Color.WHITE, row_col, energy, true)
		inst.material_override = mat
		add_child(inst)

		# The living band breathes.
		if w > 0.35:
			_pulse_mats.append({
				"mat": mat,
				"base_energy": energy,
				"phase": frac * TAU,
			})


# ── kerbs: gentle containment ────────────────────────────────────────

func _build_kerbs(half_w: float, half_l: float) -> void:
	for side in [-1.0, 1.0]:
		var kerb_x: float = float(side) * (half_w - 0.45)
		var body := StaticBody3D.new()
		body.name = "Kerb_East" if side > 0.0 else "Kerb_West"
		add_child(body)

		var mesh_inst := MeshInstance3D.new()
		var kbox := BoxMesh.new()
		kbox.size = Vector3(0.18, 0.28, hall_length)
		mesh_inst.mesh = kbox
		var kmat := StandardMaterial3D.new()
		kmat.albedo_color = Color(0.10, 0.11, 0.14)
		kmat.roughness = 0.9
		mesh_inst.material_override = kmat
		mesh_inst.position = Vector3(kerb_x, 0.14, 0.0)
		body.add_child(mesh_inst)

		# Collider taller than the visible kerb — keeps the player in
		# the hall without a visual wall.
		var col := CollisionShape3D.new()
		var cshape := BoxShape3D.new()
		cshape.size = Vector3(0.18, 1.1, hall_length)
		col.shape = cshape
		col.position = Vector3(kerb_x, 0.55, 0.0)
		body.add_child(col)


# ── inscriptions ─────────────────────────────────────────────────────

func _build_inscriptions(half_l: float, walk_x: float) -> void:
	var lam_text: String = "λ = %.2f — life walks here" % lambda_value
	# One at each open end, oriented for whoever walks in.
	_floor_label(lam_text, Vector3(walk_x, 0.075, -half_l + 1.4), 180.0)
	_floor_label(lam_text, Vector3(walk_x, 0.075, half_l - 1.4), 0.0)
	_floor_label("QFE = F − λ·E(S) + φ·dE", Vector3(walk_x, 0.075, 0.0), 0.0)


func _floor_label(text: String, pos: Vector3, yaw_deg: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.004
	label.modulate = edge_color.lightened(0.2)
	label.outline_size = 10
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	# Lie flat on the floor, facing up. yaw 0 reads for a walker heading −Z
	# (top of the text points away from them); yaw 180 for a walker heading +Z.
	label.rotation_degrees = Vector3(-90.0, yaw_deg, 0.0)
	label.position = pos
	add_child(label)


# ── capture camera ───────────────────────────────────────────────────

func _build_capture_camera(walk_x: float, half_l: float) -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 70.0
	# Standing on the walkway at the +Z end, eye height, looking down the
	# hall (−Z): order wall left, chaos wall right, glowing edge ahead.
	cam.position = Vector3(walk_x, 1.6, half_l - 0.4)
	cam.rotation_degrees = Vector3(-4.0, 0.0, 0.0)
	add_child(cam)


# ── living edge ──────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _built:
		return
	_time += delta

	# Chaos wall boils: the drifters tumble and drift.
	for d in _drifters:
		var node: MeshInstance3D = d["node"]
		if not is_instance_valid(node):
			continue
		var axis: Vector3 = d["axis"]
		node.rotate(axis, float(d["spin"]) * delta)
		var base: Vector3 = d["base"]
		var phase: float = d["phase"]
		var amp: float = d["amp"]
		node.position = base + Vector3(
			sin(_time * 0.6 + phase) * amp,
			sin(_time * 0.9 + phase * 1.7) * amp * 0.8,
			cos(_time * 0.5 + phase) * amp)

	# The living band breathes.
	for p in _pulse_mats:
		var mat: StandardMaterial3D = p["mat"]
		if mat == null:
			continue
		var base_e: float = p["base_energy"]
		mat.emission_energy_multiplier = base_e * (1.0 + 0.28 * sin(_time * 2.1 + float(p["phase"])))

	# Order wall: one slow cold shimmer, almost static.
	if _order_mat != null:
		_order_mat.emission_energy_multiplier = _order_base_energy * (1.0 + 0.07 * sin(_time * 0.45))

	# Soft hue drift along the walkway.
	if _walk_mat != null:
		var h: float = fposmod(_walk_hsv.x + 0.025 * sin(_time * 0.3), 1.0)
		_walk_mat.emission = Color.from_hsv(h, _walk_hsv.y, _walk_hsv.z)
