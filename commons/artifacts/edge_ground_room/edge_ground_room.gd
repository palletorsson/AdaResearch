extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EdgeGroundRoom

## @identity
## name: Edge-Ground Room — The Limit Is the Foundation
## concept: The edge is the ground
## tier: large
## lineage: post-crisis synthesis, at the scale of a place you inhabit. The room makes the
##   reversal literal: the FLOOR you stand on is the edge itself. One half of the room is the
##   ordered crystal (frozen, regular, sterile); the other half is the open chaos (restless,
##   formless). You stand on the SEAM between them — the lambda-edge, the ~0.4 band where
##   structure and possibility are balanced — and it holds your weight. And it is the only
##   band where anything lives: a small world (flora, motes, growth) springs up ALONG the seam,
##   not in the frozen order and not in the formless chaos, but exactly on the limit. The edge
##   is not the failure of the floor; the edge is the floor, and it is the only fertile ground.
## essence: a 7x7 room. The floor is split: cool crystalline lattice on one side, dark churning
##   void on the other, and a bright living seam-band down the centre (~0.4 of the width) where
##   you stand. Along the seam, small structures and plant-forms grow and glow warm; motes lift
##   from the chaos and settle into order at the edge. Overhead the thesis.
## truth: the edge is the ground — the limit is the foundation. Stand on the seam between order
##   and chaos and it holds; only there does a world grow.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var life_amber: Color = Color(0.98, 0.72, 0.32)     # warm "the edge is alive" accent
@export var ground_teal: Color = Color(0.35, 0.88, 0.80)
@export var room_size: float = 7.0
@export var seam_band: float = 0.4                          # fraction of width that is the edge
@export var sprout_count: int = 14
@export var mote_count: int = 26

var _t: float = 0.0
var _seam_mat: StandardMaterial3D
var _sprouts: Array = []         # {mi:MeshInstance3D, mat:StandardMaterial3D, base_h:float, phase:float}
var _motes: MultiMeshInstance3D
var _mote_base: Array = []       # Vector3 per mote
var _crystal_mats: Array = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("room_size"):
		room_size = float(config["room_size"])
	if config.has("seam_band"):
		seam_band = float(config["seam_band"])
	if config.has("sprout_count"):
		sprout_count = int(config["sprout_count"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _mote_field(count: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = SphereMesh.new()
	mm.instance_count = count
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.9 if emissive else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mi.material_override = mat
	return mi


func _build() -> void:
	_sprouts = []
	_mote_base = []
	_crystal_mats = []
	_t = 0.0

	var hs: float = room_size * 0.5
	var band: float = room_size * clampf(seam_band, 0.15, 0.6) * 0.5   # half-width of the seam in metres

	# --- base floor slab (large tier: thin slab at y = -0.05) ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.04, room_size), _matte_mat(slate, 0.95)))

	# --- ORDER HALF (x < -band): cool crystalline floor lattice ---
	var cx: int = 0
	while cx < 7:
		var cz: int = 0
		while cz < 9:
			var px: float = -hs + 0.5 + float(cx) * ((hs - band - 0.5) / 6.0)
			if px > -band - 0.1:
				cz += 1
				continue
			var pz: float = -hs + 0.5 + float(cz) * ((room_size - 1.0) / 8.0)
			var cmat: StandardMaterial3D = _glow_mat(wire_purple, 0.5)
			add_child(_box(Vector3(px, 0.0, pz), Vector3(0.5, 0.06, 0.5), cmat))
			_crystal_mats.append(cmat)
			cz += 1
		cx += 1

	# --- CHAOS HALF (x > band): dark churning void floor (low, restless boxes) ---
	var vx: int = 0
	while vx < 7:
		var vz: int = 0
		while vz < 9:
			var px2: float = band + 0.3 + float(vx) * ((hs - band - 0.3) / 6.0)
			if px2 > hs - 0.2:
				vz += 1
				continue
			var pz2: float = -hs + 0.5 + float(vz) * ((room_size - 1.0) / 8.0)
			var h: float = _rng.randf_range(0.02, 0.14)
			add_child(_box(Vector3(px2, h * 0.5 - 0.05, pz2), Vector3(0.45, h, 0.45), _matte_mat(Color(0.10, 0.10, 0.14), 0.95)))
			vz += 1
		vx += 1

	# --- THE SEAM-BAND (the edge you stand on): bright teal load-bearing floor down x ~ 0 ---
	_seam_mat = _glow_mat(ground_teal, 1.2)
	add_child(_box(Vector3(0.0, 0.005, 0.0), Vector3(band * 2.0, 0.05, room_size), _seam_mat))
	# edge lines marking the two boundaries of the band (lambda ~0.4 made visible)
	add_child(_box(Vector3(-band, 0.03, 0.0), Vector3(0.04, 0.04, room_size), _glow_mat(cool_white, 1.4)))
	add_child(_box(Vector3(band, 0.03, 0.0), Vector3(0.04, 0.04, room_size), _glow_mat(cool_white, 1.4)))

	# --- a living world grows ALONG the seam only (not in order, not in chaos) ---
	var s: int = 0
	while s < sprout_count:
		var sx: float = _rng.randf_range(-band * 0.8, band * 0.8)
		var sz: float = _rng.randf_range(-hs + 0.6, hs - 0.6)
		var base_h: float = _rng.randf_range(0.3, 0.9)
		var smat: StandardMaterial3D = _glow_mat(life_amber, 1.6)
		# a little stalk with a glowing head — a plant-form rooted in the edge
		var stalk: MeshInstance3D = _cylinder(Vector3(sx, base_h * 0.5 + 0.03, sz), 0.025, base_h, smat)
		add_child(stalk)
		add_child(_sphere(Vector3(sx, base_h + 0.05, sz), 0.07, _glow_mat(ground_teal, 1.8)))
		_sprouts.append({"mi": stalk, "mat": smat, "base_h": base_h, "phase": _rng.randf_range(0.0, TAU), "x": sx, "z": sz})
		s += 1

	# --- motes lifting from the chaos and settling toward the seam (one MultiMesh) ---
	_motes = _mote_field(mote_count)
	add_child(_motes)
	var mm: MultiMesh = _motes.multimesh
	var k: int = 0
	while k < mote_count:
		var startx: float = _rng.randf_range(band, hs - 0.5)   # born in the chaos
		var p: Vector3 = Vector3(startx, _rng.randf_range(0.1, 1.6), _rng.randf_range(-hs + 0.5, hs - 0.5))
		_mote_base.append(p)
		var sc: float = 0.05
		mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(sc, sc, sc)), p))
		mm.set_instance_color(k, cool_white)
		k += 1

	# --- overhead title (large tier: y ~3.6) ---
	add_child(_billboard_label("THE EDGE IS THE GROUND", Vector3(0.0, 3.6, 0.0), 32, cool_white))
	add_child(_billboard_label("THE LIMIT IS THE FOUNDATION", Vector3(0.0, 3.3, 0.0), 30, life_amber))
	add_child(_billboard_label("order one side, chaos the other — only the seam holds, and only there does a world grow", Vector3(0.0, 3.04, 0.0), 14, wire_purple))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# the load-bearing seam pulses to show it carries weight
	if _seam_mat != null:
		var pulse: float = 0.5 + 0.5 * sin(_t * 1.6)
		_seam_mat.emission_energy_multiplier = (1.0 + 0.8 * pulse) if emissive else 0.3

	# the crystal half is frozen — only the faintest cold shimmer
	var c: int = 0
	while c < _crystal_mats.size():
		var cm: StandardMaterial3D = _crystal_mats[c]
		cm.emission_energy_multiplier = (0.5 + 0.1 * sin(_t * 0.6 + float(c))) if emissive else 0.2
		c += 1

	# the living seam-world sways and breathes (it is alive — the edge is fertile)
	var s: int = 0
	while s < _sprouts.size():
		var sd: Dictionary = _sprouts[s]
		var mi: MeshInstance3D = sd["mi"]
		var ph: float = float(sd["phase"])
		if is_instance_valid(mi):
			mi.rotation.z = sin(_t * 1.3 + ph) * 0.12
		var sm: StandardMaterial3D = sd["mat"]
		sm.emission_energy_multiplier = (1.4 + 0.5 * sin(_t * 2.0 + ph)) if emissive else 0.3
		s += 1

	# motes rise from the chaos and drift toward the seam, then recycle (chaos feeds the edge)
	if is_instance_valid(_motes):
		var mm: MultiMesh = _motes.multimesh
		var k: int = 0
		while k < mm.instance_count:
			var b: Vector3 = Vector3(_mote_base[k])
			# drift toward x=0 (the seam) and rise, looping
			var prog: float = fmod(_t * 0.25 + float(k) * 0.13, 1.0)
			var x: float = lerpf(b.x, 0.0, prog)
			var y: float = b.y + prog * 1.2
			var z: float = b.z + sin(_t * 0.5 + float(k)) * 0.2
			var sc: float = lerpf(0.05, 0.02, prog)
			mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(sc, sc, sc)), Vector3(x, y, z)))
			# colour shifts cool->teal as it nears the fertile edge
			mm.set_instance_color(k, cool_white.lerp(ground_teal, prog))
			k += 1
