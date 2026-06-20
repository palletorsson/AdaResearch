extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalAntenna

## @identity
## name: "Fractal antennas & structures"
## tier: applied
## lineage: a working multi-band radiator — the Koch monopole that put fractals in every phone.
## essence: A real device. A self-similar Koch conductor on a ground plane, fed at
##   the base, with a frequency-response readout lit across several bands at once.
##   One folded wire, many resonances: the recursion gives the metal an electrical
##   length for each band, so the bars all light without a tuner.
## truth: "fold the wire and one antenna covers many bands"
## applications: infinite edge in finite room — the fractal's repeated detail is
##   why a fingernail of conductor speaks Wi-Fi, GPS and cellular together.

@export var depth: int = 3
@export var arm_len: float = 0.42
@export var wire_radius: float = 0.008
@export var conductor_col: Color = Color(0.88, 0.78, 0.46)
@export var ground_col: Color = Color(0.40, 0.43, 0.48)
@export var body_col: Color = Color(0.16, 0.18, 0.22)
@export var band_lit_col: Color = Color(0.40, 0.95, 0.55)
@export var band_dim_col: Color = Color(0.18, 0.26, 0.20)
@export var band_count: int = 5

var _t: float = 0.0
var _bands: Array[MeshInstance3D] = []
var _band_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("arm_len"):
		arm_len = float(config["arm_len"])
	if config.has("band_count"):
		band_count = clampi(int(config["band_count"]), 3, 8)
	if config.has("conductor_col"):
		conductor_col = _parse_color(config["conductor_col"], conductor_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_bands.clear()
	_band_mats.clear()
	_build()


func _build() -> void:
	# ~1m device — a body box with a ground plane and the radiator standing up.
	var body_mat: StandardMaterial3D = _matte_mat(body_col, 0.5, 0.35)
	add_child(_box(Vector3(0.0, 0.18, 0.0), Vector3(0.6, 0.36, 0.45), body_mat))
	# ground plane (the counterpoise the monopole works against)
	var ground_mat: StandardMaterial3D = _steel_mat(ground_col)
	add_child(_box(Vector3(0.0, 0.37, 0.0), Vector3(0.5, 0.02, 0.4), ground_mat))

	var wire_mat: StandardMaterial3D = _steel_mat(conductor_col)
	# feed point at the base of the radiator
	add_child(_sphere(Vector3(0.0, 0.39, 0.0), wire_radius * 1.8, _glow_mat(Color(0.95, 0.5, 0.3), 2.2)))

	# the Koch monopole rises straight up from the feed
	var base := Vector3(0.0, 0.39, 0.0)
	var tip := base + Vector3(0.0, arm_len, 0.0)
	_koch(self, base, tip, depth, wire_mat)

	# --- frequency-response readout (several bands lit) ---------------------
	var panel_mat: StandardMaterial3D = _matte_mat(Color(0.07, 0.09, 0.10), 0.4)
	add_child(_box(Vector3(0.22, 0.22, 0.235), Vector3(0.34, 0.22, 0.02), panel_mat))
	var n: int = max(band_count, 3)
	for i in range(n):
		var bx: float = lerpf(0.10, 0.34, float(i) / float(n - 1))
		var bh: float = 0.05 + 0.12 * (0.5 + 0.5 * sin(float(i) * 1.7))
		var lit: bool = (i % 2 == 0)
		var col: Color = band_lit_col if lit else band_dim_col
		var mat: StandardMaterial3D = _glow_mat(col, 2.0 if lit else 0.4)
		var bar := _box(Vector3(bx - 0.0, 0.155 + bh * 0.5, 0.247), Vector3(0.028, bh, 0.012), mat)
		add_child(bar)
		_bands.append(bar)
		_band_mats.append(mat)

	add_child(_billboard_label("MULTI-BAND ANTENNA", Vector3(0.0, arm_len + 0.62, 0.0), 22, conductor_col))
	add_child(_billboard_label("Fractal antennas & structures", Vector3(0.0, arm_len + 0.78, 0.0), 16, Color(0.85, 0.90, 0.95)))


func _koch(parent: Node3D, a: Vector3, b: Vector3, d: int, mat: Material) -> void:
	if d <= 1:
		parent.add_child(_cylinder_between(a, b, wire_radius, mat))
		return
	# Split the segment into the classic Koch four parts with a bump out the side.
	var ab: Vector3 = b - a
	var p1: Vector3 = a + ab / 3.0
	var p2: Vector3 = a + ab * (2.0 / 3.0)
	# bump perpendicular to the segment, in the X/Y plane (radiator faces +Z)
	var dir: Vector3 = ab.normalized()
	var side_axis: Vector3 = Vector3(0.0, 0.0, 1.0)
	if absf(dir.dot(side_axis)) > 0.9:
		side_axis = Vector3(1.0, 0.0, 0.0)
	var perp: Vector3 = dir.cross(side_axis).normalized()
	var bump: float = ab.length() / 3.0 * 0.82
	var apex: Vector3 = (p1 + p2) * 0.5 + perp * bump
	_koch(parent, a, p1, d - 1, mat)
	_koch(parent, p1, apex, d - 1, mat)
	_koch(parent, apex, p2, d - 1, mat)
	_koch(parent, p2, b, d - 1, mat)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Gently pulse the lit bands so the readout reads as "live".
	for i in range(_band_mats.size()):
		var mat: StandardMaterial3D = _band_mats[i]
		var lit: bool = (i % 2 == 0)
		if not lit:
			continue
		var e: float = 1.6 + 0.8 * (0.5 + 0.5 * sin(_t * 2.2 + float(i) * 0.9))
		mat.emission_energy_multiplier = e if emissive else e * 0.3
