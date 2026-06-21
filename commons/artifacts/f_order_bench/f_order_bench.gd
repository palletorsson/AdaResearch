extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FOrderBench

## @identity
## name: F Order Bench
## concept: F (free energy & order) — the first term of QFE = F − λE(S) + φΔE(S,t)
## tier: medium
## truth: minimize F alone and you get a perfect, frozen, dead thing — order without becoming.
##
## A floor-standing QFEP instrument that stages free-energy minimization as a single
## visible event: ~64 scattered units, drifting and disordered, SNAP into a flawless
## cubic crystal lattice as F is driven down. A readout drops "F ↓" toward a floor value.
## The crystal that results is perfect, still, and lifeless — the lesson of F-alone.

@export var lattice_n: int = 4                      # crystal is n×n×n units
@export var lattice_pitch: float = 0.12             # spacing between lattice sites
@export var crystal_center: Vector3 = Vector3(0.0, 1.0, 0.0)
@export var anneal_period: float = 7.0              # seconds for one scatter→crystal→scatter cycle
@export var crystal_color: Color = Color(0.5, 0.8, 1.0)
@export var scatter_color: Color = Color(0.65, 0.6, 0.95)
@export var frame_color: Color = Color(0.55, 0.7, 0.95)

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _sites: PackedVector3Array = PackedVector3Array()      # ordered lattice targets
var _scatter: PackedVector3Array = PackedVector3Array()    # per-unit disordered home
var _phase: PackedFloat32Array = PackedFloat32Array()      # per-unit jitter phase
var _count: int = 0
var _title: Label3D
var _readout: Label3D
var _bar_fill: MeshInstance3D
var _bar_fill_mat: StandardMaterial3D
var _t: float = 0.0
var _order: float = 0.0    # 0 = scattered, 1 = perfect crystal


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
	_count = lattice_n * lattice_n * lattice_n

	# --- instrument plinth (y ~ 0) ---
	add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.46, 0.08, _steel_mat(Color(0.14, 0.18, 0.28))))
	add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.40, 0.06, _matte_mat(Color(0.18, 0.24, 0.38), 0.6, 0.3)))
	add_child(_cylinder(Vector3(0.0, 0.4, 0.0), 0.05, 0.6, _steel_mat(frame_color * 0.7)))

	# --- containment cage around the crystal (cool glass + glowing edges) ---
	var span: float = float(lattice_n - 1) * lattice_pitch + 0.12
	add_child(_box(crystal_center, Vector3(span, span, span), _glass_mat(crystal_color, 0.08)))
	_add_box_frame(crystal_center, Vector3(span, span, span), 0.008, _glow_mat(frame_color, 2.0))

	# --- title ---
	_title = _billboard_label("F  —  FREE ENERGY & ORDER", Vector3(0.0, 1.5, 0.0), 22, Color(0.88, 0.95, 1.0))
	add_child(_title)
	add_child(_billboard_label("minimize F  →  perfect crystal", Vector3(0.0, 1.36, 0.0), 14, Color(0.7, 0.78, 0.92)))

	# --- F readout (drops as order rises) ---
	_readout = _billboard_label("F ↓", Vector3(0.5, 1.18, 0.0), 20, crystal_color)
	add_child(_readout)

	# --- a vertical F-meter: rail + descending fill ---
	add_child(_box(Vector3(-0.5, 1.0, 0.0), Vector3(0.04, 0.5, 0.04), _matte_mat(Color(0.1, 0.13, 0.2))))
	_bar_fill_mat = _glow_mat(Color(0.95, 0.55, 0.35), 2.2)   # warm = high free energy
	_bar_fill = _box(Vector3(-0.5, 1.0, 0.0), Vector3(0.05, 0.5, 0.05), _bar_fill_mat)
	add_child(_bar_fill)
	add_child(_billboard_label("F", Vector3(-0.5, 1.3, 0.0), 16, Color(0.85, 0.9, 1.0)))

	# --- build ordered lattice sites + a disordered scatter home per unit ---
	_sites.resize(_count)
	_scatter.resize(_count)
	_phase.resize(_count)
	var i: int = 0
	var off: float = float(lattice_n - 1) * 0.5
	for ix in range(lattice_n):
		for iy in range(lattice_n):
			for iz in range(lattice_n):
				var site: Vector3 = crystal_center + Vector3(
					(float(ix) - off) * lattice_pitch,
					(float(iy) - off) * lattice_pitch,
					(float(iz) - off) * lattice_pitch)
				_sites[i] = site
				var rscatter: float = span * 0.55
				_scatter[i] = crystal_center + Vector3(
					_rng.randf_range(-rscatter, rscatter),
					_rng.randf_range(-rscatter, rscatter),
					_rng.randf_range(-rscatter, rscatter))
				_phase[i] = _rng.randf() * TAU
				i += 1

	# --- the units: ONE MultiMesh ---
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = _count
	var cube: BoxMesh = BoxMesh.new()
	cube.size = Vector3.ONE * (lattice_pitch * 0.42)
	_mm.mesh = cube
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "OrderUnits"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_mat(crystal_color, 1.8)
	add_child(_mm_inst)

	_apply_units(0.0)


func _apply_units(order: float) -> void:
	# order 0 → scattered + jittering; order 1 → exact lattice, frozen.
	for i in range(_count):
		var disordered: Vector3 = _scatter[i] + Vector3(
			sin(_t * 1.3 + _phase[i]),
			cos(_t * 1.1 + _phase[i] * 1.7),
			sin(_t * 0.9 + _phase[i] * 0.6)) * (lattice_pitch * 0.5 * (1.0 - order))
		var pos: Vector3 = disordered.lerp(_sites[i], order)
		var b: Basis = Basis()
		# residual tumble while disordered, snaps to axis-aligned when ordered
		var spin: float = (1.0 - order) * (_phase[i] + _t * 0.7)
		b = b.rotated(Vector3(0.3, 1.0, 0.2).normalized(), spin)
		_mm.set_instance_transform(i, Transform3D(b, pos))
		var col: Color = scatter_color.lerp(crystal_color, order)
		_mm.set_instance_color(i, col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# triangle wave: scatter → crystallize → hold → melt → scatter
	var phase: float = fmod(_t, anneal_period) / anneal_period   # 0..1
	if phase < 0.5:
		_order = smoothstep(0.0, 1.0, phase / 0.5)                # crystallizing
	else:
		_order = smoothstep(0.0, 1.0, (1.0 - phase) / 0.5)        # melting back
	_apply_units(_order)

	# F drops as order rises. Map order→F in [1.00 .. 0.05].
	var f_val: float = 1.0 - 0.95 * _order
	if _readout != null:
		_readout.text = "F ↓  %.2f" % f_val
		_readout.modulate = scatter_color.lerp(crystal_color, _order)
	# meter fill shrinks from the top as F falls
	if _bar_fill != null:
		var h: float = clampf(f_val, 0.02, 1.0) * 0.5
		var box_mesh: BoxMesh = _bar_fill.mesh as BoxMesh
		box_mesh.size = Vector3(0.05, h, 0.05)
		_bar_fill.position = Vector3(-0.5, 0.75 + h * 0.5, 0.0)
		_bar_fill_mat.emission = Color(0.95, 0.55, 0.35).lerp(crystal_color, _order)


# --- helper: glowing edge frame for a box ---
func _add_box_frame(center: Vector3, size: Vector3, r: float, mat: Material) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var corners: Array = [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz),
		Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	for e in edges:
		var a: Vector3 = center + corners[e[0]]
		var b: Vector3 = center + corners[e[1]]
		add_child(_cylinder_between(a, b, r, mat))
