extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CrisisEdgeToy

## @identity
## name: Crisis Edge Toy — The Constitutive Edge
## concept: The crisis & the edge
## tier: small
## lineage: the foundations crisis read as a discovery, not a defeat — every formal system
##   F has an outside, and the boundary between the formalised inside and the unformalised
##   outside is where the living mathematics happens (Gödel's gap, the edge of chaos, the
##   queer irreducible).
## essence: a held marker of THE EDGE. One half is rigid crystal — order, the system F,
##   tidy and lattice-clean. The other half is open void — the outside, unformalised. A
##   single glowing seam runs between them: the constitutive edge, where the life is.
## truth: every system has an outside. The edge is not a flaw to be sealed — it is the
##   habitat. Draw the boundary and you create both the inside and the place worth standing.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent: Color = Color(0.40, 0.95, 0.80)    # the seam / edge glow
@export var spin_speed: float = 0.6

var _t: float = 0.0
var _seam: MeshInstance3D
var _seam_mat: StandardMaterial3D
var _void_cells: Array = []     # MeshInstance3D faint motes drifting in the outside
var _crystal_mats: Array = []   # ordered lattice glows


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("spin_speed"):
		spin_speed = float(config["spin_speed"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_void_cells = []
	_crystal_mats = []

	# held object — no base; centred near origin, ~0.4 m across
	# --- ORDER half: a rigid crystal lattice (x < 0) ---
	var lat_mat: StandardMaterial3D = _glow_mat(cool_white, 0.7)
	var frame_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.6)
	_crystal_mats.append(lat_mat)
	_crystal_mats.append(frame_mat)

	# a tidy 2x3x2 grid of little cubes = the formalised inside, F
	var nx: int = 2
	var ny: int = 3
	var nz: int = 2
	var d: float = 0.07
	var ix: int = 0
	while ix < nx:
		var iy: int = 0
		while iy < ny:
			var iz: int = 0
			while iz < nz:
				var p: Vector3 = Vector3(
					-0.06 - float(ix) * d,
					-0.07 + float(iy) * d,
					-float(nz - 1) * 0.5 * d + float(iz) * d
				)
				add_child(_box(p, Vector3(d * 0.72, d * 0.72, d * 0.72), lat_mat))
				iz += 1
			iy += 1
		ix += 1
	# lattice wire bounds around the crystal
	var cmin: Vector3 = Vector3(-0.06 - float(nx - 1) * d - d * 0.5, -0.07 - d * 0.5, -float(nz) * 0.5 * d)
	var cmax: Vector3 = Vector3(-0.06 + d * 0.5, -0.07 + float(ny - 1) * d + d * 0.5, float(nz) * 0.5 * d)
	_wire_box(cmin, cmax, 0.006, frame_mat)

	# --- THE SEAM: a glowing vertical plane at x = 0 (the constitutive edge) ---
	_seam_mat = _glow_mat(accent, 2.0)
	_seam = _box(Vector3(0.0, 0.0, 0.0), Vector3(0.012, 0.34, 0.26), _seam_mat)
	add_child(_seam)
	# edge filaments fanning along the seam
	var f: int = 0
	while f < 5:
		var yy: float = -0.14 + float(f) * 0.07
		add_child(_cylinder_between(Vector3(-0.02, yy, -0.12), Vector3(0.02, yy, 0.12), 0.004, _glow_mat(accent, 1.4)))
		f += 1

	# --- VOID half: open outside (x > 0) — a few drifting motes, mostly nothing ---
	var mote_mat: StandardMaterial3D = _glass_mat(wire_purple, 0.4)
	var m: int = 0
	while m < 7:
		var mp: Vector3 = Vector3(
			0.06 + _rng.randf() * 0.14,
			-0.12 + _rng.randf() * 0.24,
			-0.12 + _rng.randf() * 0.24
		)
		var mote: MeshInstance3D = _sphere(mp, 0.012 + _rng.randf() * 0.01, mote_mat)
		add_child(mote)
		_void_cells.append(mote)
		m += 1
	# a faint open wire frame on the void side (a boundary that does NOT close)
	add_child(_cylinder_between(Vector3(0.02, -0.16, -0.13), Vector3(0.20, -0.16, -0.13), 0.004, mote_mat))
	add_child(_cylinder_between(Vector3(0.02, 0.16, 0.13), Vector3(0.20, 0.16, 0.13), 0.004, mote_mat))

	# --- billboard title (small, above the toy) ---
	add_child(_billboard_label("THE EDGE", Vector3(0.0, 0.28, 0.0), 18, accent))
	add_child(_billboard_label("order | outside", Vector3(0.0, 0.21, 0.0), 11, wire_purple))


func _wire_box(mn: Vector3, mx: Vector3, r: float, mat: Material) -> void:
	var c: Array = [
		Vector3(mn.x, mn.y, mn.z), Vector3(mx.x, mn.y, mn.z), Vector3(mx.x, mn.y, mx.z), Vector3(mn.x, mn.y, mx.z),
		Vector3(mn.x, mx.y, mn.z), Vector3(mx.x, mx.y, mn.z), Vector3(mx.x, mx.y, mx.z), Vector3(mn.x, mx.y, mx.z)
	]
	var e: Array = [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]]
	var i: int = 0
	while i < e.size():
		add_child(_cylinder_between(c[e[i][0]], c[e[i][1]], r, mat))
		i += 1


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# gentle presentation spin
	rotation.y = _t * spin_speed

	# the seam pulses — the edge is where the life is
	if _seam_mat != null:
		_seam_mat.emission_energy_multiplier = (2.0 if emissive else 0.7) * (0.7 + 0.4 * sin(_t * 3.0))

	# void motes drift slowly (the unformalised outside is restless, undetermined)
	var i: int = 0
	while i < _void_cells.size():
		var mi: MeshInstance3D = _void_cells[i] as MeshInstance3D
		if is_instance_valid(mi):
			var base_y: float = mi.position.y
			mi.position.x += sin(_t * 0.8 + float(i)) * 0.0006
			mi.position.y = base_y + sin(_t * 1.1 + float(i) * 1.7) * 0.0008
		i += 1
