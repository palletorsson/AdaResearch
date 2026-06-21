extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MolecularRoom

## @identity
## name: Molecular Room — Post-Reductionist Making
## concept: Molecular design after crisis
## tier: large
## lineage: post-crisis design after the foundations crisis. At room scale, molecular design
##   becomes architecture: a designed material — a crystal, a protein scaffold, a metal-organic
##   framework — that you can stand inside. None of it was drawn as a master plan and then
##   forced into place. It was grown bond by bond from valence rules: each junction is the only
##   junction the slots permitted, and the whole lattice is the emergent consequence of those
##   local constraints repeated. Reductionism asked for one bottom rule that explains all;
##   post-reductionist making asks instead what the parts will let you build, and builds it.
## essence: a 7x7 room you stand within. A large 3D lattice (~3 m) of atom-nodes and bond-struts
##   fills the space — a crystalline / framework structure. It grows in waves: new bonds light
##   warm amber as junctions close outward from a seed, settling to cool purple/teal behind the
##   growth front. The form is regular because the valences are regular; it is alive because it
##   is still closing. You read the lattice from inside the material it designs.
## truth: molecular design as post-reductionist making — the structure is grown from valence,
##   not decreed from a blueprint. The whole is the lattice the local limits permit.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var grow_amber: Color = Color(0.98, 0.72, 0.32)     # warm "junction closing" accent
@export var bond_teal: Color = Color(0.35, 0.88, 0.80)
@export var room_size: float = 7.0
@export var lattice_n: int = 4                              # nodes per axis (n^3 atoms)
@export var lattice_span: float = 3.0                       # full width of the structure
@export var grow_period: float = 0.16                       # seconds between growth steps

var _t: float = 0.0
var _atoms: MultiMeshInstance3D       # atom-nodes (one MultiMesh)
var _node_pos: Array = []             # Vector3 per atom (room coords)
var _bonds: Array = []                # {mi:MeshInstance3D, mat:StandardMaterial3D, glow:float, born:float}
var _pending: Array = []              # bond candidates {a:int, b:int} not yet grown
var _accum: float = 0.0
var _origin := Vector3(0.0, 0.4, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("room_size"):
		room_size = float(config["room_size"])
	if config.has("lattice_n"):
		lattice_n = int(config["lattice_n"])
	if config.has("grow_period"):
		grow_period = float(config["grow_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _atom_field(count: int) -> MultiMeshInstance3D:
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
	mat.emission_energy_multiplier = 0.8 if emissive else 0.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mi.material_override = mat
	return mi


func _build() -> void:
	_node_pos = []
	_bonds = []
	_pending = []
	_accum = 0.0
	_t = 0.0

	var hs: float = room_size * 0.5
	var purple_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.5)

	# --- floor (large tier: thin slab at y = -0.05) ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.04, room_size), _matte_mat(slate, 0.9)))
	# faint wireframe perimeter
	add_child(_box(Vector3(0.0, 0.0, hs - 0.05), Vector3(room_size, 0.02, 0.04), purple_mat))
	add_child(_box(Vector3(0.0, 0.0, -hs + 0.05), Vector3(room_size, 0.02, 0.04), purple_mat))
	add_child(_box(Vector3(hs - 0.05, 0.0, 0.0), Vector3(0.04, 0.02, room_size), purple_mat))
	add_child(_box(Vector3(-hs + 0.05, 0.0, 0.0), Vector3(0.04, 0.02, room_size), purple_mat))

	# --- build the lattice node grid (room coords, centred, lifted to standing height) ---
	var n: int = maxi(2, lattice_n)
	var step: float = lattice_span / float(n - 1)
	var base: float = -lattice_span * 0.5
	var ix: int = 0
	while ix < n:
		var iy: int = 0
		while iy < n:
			var iz: int = 0
			while iz < n:
				var p: Vector3 = _origin + Vector3(base + float(ix) * step, 0.6 + float(iy) * step, base + float(iz) * step)
				# slight jitter so the crystal reads as designed-not-perfect
				p += Vector3(_rng.randf_range(-0.04, 0.04), _rng.randf_range(-0.04, 0.04), _rng.randf_range(-0.04, 0.04))
				_node_pos.append(p)
				iz += 1
			iy += 1
		ix += 1

	# atoms as one MultiMesh of spheres
	_atoms = _atom_field(_node_pos.size())
	add_child(_atoms)
	var mm: MultiMesh = _atoms.multimesh
	var k: int = 0
	while k < _node_pos.size():
		var s: float = 0.09
		mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(s, s, s)), _node_pos[k]))
		mm.set_instance_color(k, cool_white.lerp(bond_teal, _rng.randf() * 0.4))
		k += 1

	# --- pending bonds: each node to its axis-adjacent neighbours (the valence lattice) ---
	var a: int = 0
	while a < _node_pos.size():
		var b: int = a + 1
		while b < _node_pos.size():
			var d: float = (Vector3(_node_pos[a])).distance_to(Vector3(_node_pos[b]))
			if d <= step * 1.18:
				_pending.append({"a": a, "b": b})
			b += 1
		a += 1
	# shuffle so growth spreads in irregular waves from no single corner
	_pending.shuffle()

	# --- overhead title (large tier: y ~3.6) ---
	add_child(_billboard_label("MOLECULAR DESIGN", Vector3(0.0, 3.6, 0.0), 32, cool_white))
	add_child(_billboard_label("POST-REDUCTIONIST MAKING", Vector3(0.0, 3.3, 0.0), 30, grow_amber))
	add_child(_billboard_label("grown bond by bond from valence — not decreed", Vector3(0.0, 3.04, 0.0), 16, wire_purple))


func _grow_one_bond() -> void:
	if _pending.size() == 0:
		# lattice complete: restart the growth front so the room keeps breathing
		var b: int = 0
		while b < _bonds.size():
			(_bonds[b] as Dictionary)["born"] = _t - _rng.randf_range(0.0, 2.0)
			b += 1
		# rebuild pending from existing bond pairs is unnecessary; just let glows recycle
		return
	var cand: Dictionary = _pending.pop_back()
	var pa: Vector3 = Vector3(_node_pos[int(cand["a"])])
	var pb: Vector3 = Vector3(_node_pos[int(cand["b"])])
	var bmat: StandardMaterial3D = _glow_mat(grow_amber, 2.4)
	var mi: MeshInstance3D = _cylinder_between(pa, pb, 0.018, bmat)
	add_child(mi)
	_bonds.append({"mi": mi, "mat": bmat, "glow": 1.0, "born": _t})


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# slow overall drift of the lattice so it reads as a living structure
	if is_instance_valid(_atoms):
		_atoms.rotation.y = sin(_t * 0.12) * 0.04

	# --- grow the structure outward, a few bonds per tick ---
	_accum += delta
	if _accum >= grow_period:
		_accum = 0.0
		var burst: int = 2
		var i: int = 0
		while i < burst:
			_grow_one_bond()
			i += 1

	# --- fresh bonds glow warm amber at the growth front, cool to teal/purple behind ---
	var e: int = 0
	while e < _bonds.size():
		var ed: Dictionary = _bonds[e]
		var age: float = _t - float(ed["born"])
		var heat: float = clampf(1.0 - age * 0.5, 0.0, 1.0)   # 1 at birth -> 0 after ~2 s
		var bm: StandardMaterial3D = ed["mat"]
		var cool: Color = wire_purple.lerp(bond_teal, 0.4)
		bm.albedo_color = cool.lerp(grow_amber, heat)
		bm.emission = cool.lerp(grow_amber, heat)
		bm.emission_energy_multiplier = (0.6 + 2.2 * heat) if emissive else 0.2
		e += 1

	# --- atom shimmer via per-instance colour pulse ---
	if is_instance_valid(_atoms):
		var mm: MultiMesh = _atoms.multimesh
		var k: int = 0
		while k < mm.instance_count:
			var ph: float = sin(_t * 1.4 + float(k) * 0.5) * 0.5 + 0.5
			mm.set_instance_color(k, cool_white.lerp(bond_teal, 0.25 + 0.35 * ph))
			k += 1
