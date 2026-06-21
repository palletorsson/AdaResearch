extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FOrderRoom

## @identity
## name: F Order Room
## concept: F (free energy & order) — the first term of QFE = F − λE(S) + φΔE(S,t)
## tier: large
## truth: pure order is perfect, frozen, and dead — a crystal palace you can walk into but nothing lives there.
##
## A room-scale staging of F-alone: a vast, flawless crystalline lattice fills the 7×7 floor —
## a regular grid of glass pillars capped with perfect octahedral crystals, every one identical,
## every one motionless. Cold cyan light, no drift, no growth. It is beautiful precisely because
## it is dead. Overhead: "PURE ORDER — PERFECT, FROZEN, DEAD".

@export var grid_n: int = 5                   # n×n lattice of pillars on the floor
@export var grid_pitch: float = 1.35          # spacing between pillars
@export var pillar_height: float = 2.4
@export var crystal_color: Color = Color(0.55, 0.85, 1.0)
@export var glass_color: Color = Color(0.45, 0.72, 0.98)
@export var floor_color: Color = Color(0.08, 0.12, 0.2)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# --- the 7×7 floor (large-tier convention, y = -0.05) ---
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(floor_color, 0.85, 0.1)))
	# a faint reflective inlay grid baked into the floor (cold, still)
	var inlay_mat: StandardMaterial3D = _glow_mat(crystal_color * 0.5, 0.6)
	var half: float = float(grid_n - 1) * 0.5
	for gx in range(grid_n):
		var x: float = (float(gx) - half) * grid_pitch
		add_child(_box(Vector3(x, 0.005, 0.0), Vector3(0.02, 0.01, 6.6), inlay_mat))
		add_child(_box(Vector3(0.0, 0.005, x), Vector3(6.6, 0.01, 0.02), inlay_mat))

	# --- the lattice of pillars: every site identical, perfectly placed ---
	var glass: StandardMaterial3D = _glass_mat(glass_color, 0.16)
	var crystal: StandardMaterial3D = _glow_mat(crystal_color, 2.0)
	var cap: StandardMaterial3D = _glow_mat(crystal_color, 2.6)
	for gx in range(grid_n):
		for gz in range(grid_n):
			var x: float = (float(gx) - half) * grid_pitch
			var z: float = (float(gz) - half) * grid_pitch
			_build_pillar(Vector3(x, 0.0, z), glass, crystal, cap)

	# --- cold ceiling lattice (mirror of the floor, sealing the palace) ---
	var ceil_mat: StandardMaterial3D = _glow_mat(crystal_color * 0.4, 0.5)
	for gx in range(grid_n):
		var x: float = (float(gx) - half) * grid_pitch
		add_child(_box(Vector3(x, pillar_height + 0.6, 0.0), Vector3(0.03, 0.02, 6.6), ceil_mat))
		add_child(_box(Vector3(0.0, pillar_height + 0.6, x), Vector3(6.6, 0.02, 0.03), ceil_mat))

	# --- overhead title (large-tier label y ~ 3.6) ---
	add_child(_billboard_label("PURE ORDER — PERFECT, FROZEN, DEAD", Vector3(0.0, 3.6, 0.0), 30, Color(0.85, 0.95, 1.0)))
	add_child(_billboard_label("minimize F alone  →  flawless, lifeless", Vector3(0.0, 3.3, 0.0), 18, Color(0.6, 0.72, 0.9)))
	add_child(_billboard_label("QFE = F", Vector3(0.0, 3.05, 0.0), 22, crystal_color))


func _build_pillar(base: Vector3, glass: Material, crystal: Material, cap: Material) -> void:
	# a perfect glass column with a crystalline lattice core and an octahedral crown.
	var cx: float = base.x
	var cz: float = base.z
	# glass shaft
	add_child(_box(Vector3(cx, pillar_height * 0.5, cz), Vector3(0.34, pillar_height, 0.34), glass))
	# inner crystal core (a thin bright bar, frozen)
	add_child(_box(Vector3(cx, pillar_height * 0.5, cz), Vector3(0.06, pillar_height * 0.94, 0.06), crystal))
	# stacked lattice cells along the shaft — the order made visible
	var cells: int = 6
	for k in range(cells):
		var y: float = (float(k) + 0.5) / float(cells) * pillar_height
		add_child(_box(Vector3(cx, y, cz), Vector3(0.2, 0.02, 0.2), crystal))
	# octahedral crown (two pyramids) — a perfect crystal cap
	add_child(_octahedron(Vector3(cx, pillar_height + 0.22, cz), 0.26, cap))
	# base plinth
	add_child(_box(Vector3(cx, 0.05, cz), Vector3(0.46, 0.1, 0.46), _steel_mat(glass_color * 0.5)))


func _octahedron(center: Vector3, r: float, mat: Material) -> Node3D:
	# upper + lower cone forming a perfect bipyramid (octahedron).
	var root: Node3D = Node3D.new()
	var up: CylinderMesh = CylinderMesh.new()
	up.top_radius = 0.0
	up.bottom_radius = r
	up.height = r
	up.radial_segments = 4
	var mi_up: MeshInstance3D = MeshInstance3D.new()
	mi_up.mesh = up
	mi_up.material_override = mat
	mi_up.position = center + Vector3(0.0, r * 0.5, 0.0)
	root.add_child(mi_up)
	var dn: CylinderMesh = CylinderMesh.new()
	dn.top_radius = r
	dn.bottom_radius = 0.0
	dn.height = r
	dn.radial_segments = 4
	var mi_dn: MeshInstance3D = MeshInstance3D.new()
	mi_dn.mesh = dn
	mi_dn.material_override = mat
	mi_dn.position = center + Vector3(0.0, -r * 0.5, 0.0)
	root.add_child(mi_dn)
	return root


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Nothing moves. The room is frozen by design — pure order, no becoming.
	# (No animation: the deadness IS the point of the F-alone term.)
	pass
