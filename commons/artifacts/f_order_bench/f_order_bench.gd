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

## AXIS — COMPLEMENT: what this bench shows of the equation it does NOT run.
##
## QFE = F − λE(S) + φΔE(S,t). This bench runs the first term and only the first
## term: it drives F down and a perfect crystal falls out. Its own truth line says
## what that costs — "minimize F alone and you get a perfect, frozen, dead thing".
## But the bench does not say it. It stands there titled F, cages one demonstration,
## prints one number, and the two terms it dropped leave no mark on the furniture.
##
## That silence is a position, not a neutral. An instrument that isolates a variable
## is making a claim about what can be held still while you look at something else,
## and the claim is invisible precisely because nothing on the bench records it. So
## the axis is the claim, made visible: how much of its own complement does this
## bench admit is missing?
##
##   none       nothing — the legacy lineage, byte for byte. F alone, unremarked.
##   ghost      two dead mounts on the deck: capped stubs, blanked grey face plates,
##              unlit λ and φ tags. Provision was made for them and never fitted.
##   supply     two lit tributary conduits rise from the deck and plug into the
##              crystal cage. The term is not self-standing; it is being fed.
##   redaction  a bone-white plate across the front carrying the whole formula,
##              with λE(S) and φΔE(S,t) struck under black bars and F boxed in
##              accent. The bench prints what it cut.
##   quorum     two lit satellite dials stand with the crystal, λ and φ present and
##              linked in. Three terms in session; one of them speaking.
##
## Shared word for word with [[lambda_dial_bench]], [[phi_rate_bench]] and
## [[qfep_reactor_bench]] — one equation, one vocabulary. It would be incoherent
## for the F bench and the λ bench to speak differently about the same formula.
@export_enum("none", "ghost", "supply", "redaction", "quorum") var complement: String = "none"
const COMPLEMENTS: PackedStringArray = ["none", "ghost", "supply", "redaction", "quorum"]

## Seed for the disordered scatter + jitter phases. −1 keeps today's behaviour
## (randomize on every spawn); any value ≥ 0 makes the scatter reproducible, which
## is what a sweep needs — otherwise five variants of an axis are also five
## different scatters, and the noise is measured as the axis.
@export var scatter_seed: int = -1

# The two terms this bench does not run — glyph, and the colour the family gives it.
const COMP_A_GLYPH := "λ"
const COMP_A_COLOR := Color(0.62, 0.55, 0.98)
const COMP_B_GLYPH := "φ"
const COMP_B_COLOR := Color(0.55, 0.99, 0.78)
# Where the complement hardware stands: flank offset, deck height, forward offset.
# Deliberately inside the existing silhouette (plinth r 0.46, cage top y 1.24) so a
# variant is not also a different camera distance.
const COMP_X := 0.40
const COMP_Y := 0.145
const COMP_Z := 0.10

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
	_read_dna_meta()
	if scatter_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = scatter_seed
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("complement"):
		var c_in: String = str(config["complement"]).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if config.has("scatter_seed"):
		scatter_seed = int(str(config["scatter_seed"]))
		if scatter_seed >= 0:
			_rng.seed = scatter_seed
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the
# first build; apply_grid_config (deferred) covers the rebuild path. Unknown words
# keep the default — an axis must never be able to blank an artifact by typo.
func _read_dna_meta() -> void:
	if has_meta("config_complement"):
		var c_in: String = str(get_meta("config_complement")).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if has_meta("config_scatter_seed"):
		scatter_seed = int(str(get_meta("config_scatter_seed")))


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

	# COMPLEMENT dressing, appended LAST so every child index and position above is
	# untouched on the legacy path. "none" falls through and adds nothing at all.
	match complement:
		"ghost":
			_comp_ghost()
		"supply":
			_comp_supply()
		"redaction":
			_comp_redaction()
		"quorum":
			_comp_quorum()
		_:
			pass                                  # "none" — the legacy lineage


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


# ── COMPLEMENT ───────────────────────────────────────────────────────────────
# Five values, four builders, appended after everything else. The gestures are
# identical across the four QFEP benches — only the anchors and the two absent
# glyphs change — so a room of them reads as one instrument family taking one
# position on its own isolation.

# Where the missing terms would plug in: the collar under the crystal cage.
func _comp_hub() -> Vector3:
	return crystal_center + Vector3(0.0, -0.26, 0.0)


## Engraved text: NOT _billboard_label. Depth-tested and non-billboard so the black
## redaction bars can actually cover it, and so LabelFramer leaves it alone (it frames
## hanging billboards, and this text lies on a body already).
func _comp_ink(text: String, pos: Vector3, font: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.modulate = col
	l.outline_size = 0
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.no_depth_test = false
	l.position = pos
	return l


## GHOST — provision, unfitted. A capped stub on the deck carrying a blanked face
## plate with the term's tag on it, all unlit. Grey and not black on purpose: the
## capture stage is near-black, and a black value is an invisible one.
func _comp_ghost_one(sx: float, glyph: String) -> void:
	var post_mat: StandardMaterial3D = _matte_mat(Color(0.34, 0.36, 0.42), 0.85, 0.3)
	var face_mat: StandardMaterial3D = _matte_mat(Color(0.21, 0.22, 0.27), 0.95, 0.1)
	add_child(_cylinder(Vector3(sx, COMP_Y + 0.15, COMP_Z), 0.05, 0.30, post_mat))
	add_child(_torus(Vector3(sx, COMP_Y + 0.30, COMP_Z), 0.075, 0.016, post_mat))
	add_child(_box(Vector3(sx, COMP_Y + 0.42, COMP_Z), Vector3(0.23, 0.27, 0.02), post_mat))
	add_child(_box(Vector3(sx, COMP_Y + 0.42, COMP_Z + 0.016), Vector3(0.20, 0.24, 0.02), face_mat))
	add_child(_comp_ink(glyph, Vector3(sx, COMP_Y + 0.42, COMP_Z + 0.035), 26, Color(0.52, 0.54, 0.60)))


func _comp_ghost() -> void:
	_comp_ghost_one(-COMP_X, COMP_A_GLYPH)
	_comp_ghost_one(COMP_X, COMP_B_GLYPH)


## SUPPLY — the term is fed. A lit conduit rises off the deck and elbows into the
## containment collar, in the colour the family gives that term, tagged at the base.
func _comp_supply_one(sx: float, glyph: String, col: Color) -> void:
	var lit: StandardMaterial3D = _glow_mat(col, 1.6)
	add_child(_torus(Vector3(sx, COMP_Y + 0.02, COMP_Z), 0.07, 0.018, _steel_mat(col.darkened(0.45))))
	add_child(_cylinder(Vector3(sx, COMP_Y + 0.16, COMP_Z), 0.028, 0.28, lit))
	add_child(_cylinder_between(Vector3(sx, COMP_Y + 0.28, COMP_Z), _comp_hub(), 0.026, lit))
	add_child(_box(Vector3(sx, COMP_Y + 0.34, COMP_Z + 0.055), Vector3(0.13, 0.11, 0.015),
		_matte_mat(Color(0.87, 0.86, 0.82), 0.55)))
	add_child(_comp_ink(glyph, Vector3(sx, COMP_Y + 0.34, COMP_Z + 0.07), 20, Color(0.10, 0.11, 0.15)))


func _comp_supply() -> void:
	_comp_supply_one(-COMP_X, COMP_A_GLYPH, COMP_A_COLOR)
	_comp_supply_one(COMP_X, COMP_B_GLYPH, COMP_B_COLOR)
	add_child(_torus(_comp_hub(), 0.09, 0.02, _steel_mat(Color(0.55, 0.60, 0.72))))


## REDACTION — the bench prints what it cut. A bone plate across the front carries the
## whole formula; the term this bench runs is boxed in accent, the other two are struck
## under matte-black bars. `keep` is the slot that survives: 0 = F, 1 = λE, 2 = φΔE.
func _comp_formula_plate(keep: int) -> void:
	var py: float = 0.60
	var pz: float = 0.155
	var bone: StandardMaterial3D = _matte_mat(Color(0.87, 0.86, 0.82), 0.55)
	var steel: StandardMaterial3D = _steel_mat(Color(0.42, 0.45, 0.52))
	var bar: StandardMaterial3D = _matte_mat(Color(0.05, 0.05, 0.07), 0.98)
	add_child(_cylinder_between(Vector3(0.0, py, 0.03), Vector3(0.0, py, pz - 0.012), 0.02, steel))
	add_child(_box(Vector3(0.0, py, pz - 0.012), Vector3(0.78, 0.26, 0.02), steel))
	add_child(_box(Vector3(0.0, py, pz), Vector3(0.74, 0.22, 0.02), bone))
	add_child(_comp_ink("QFE =", Vector3(-0.20, py, pz + 0.02), 13, Color(0.10, 0.11, 0.15)))
	var slot_x: PackedFloat32Array = PackedFloat32Array([-0.065, 0.055, 0.225])
	var slot_w: PackedFloat32Array = PackedFloat32Array([0.075, 0.135, 0.175])
	var slot_t: PackedStringArray = PackedStringArray(["F", "- λE", "+ φΔE"])
	for i in range(3):
		if i == keep:
			add_child(_box(Vector3(slot_x[i], py, pz + 0.011),
				Vector3(slot_w[i] + 0.03, 0.15, 0.006), _glow_mat(crystal_color, 1.4)))
			add_child(_comp_ink(slot_t[i], Vector3(slot_x[i], py, pz + 0.025), 13,
				Color(0.06, 0.07, 0.10)))
		else:
			add_child(_box(Vector3(slot_x[i], py, pz + 0.015),
				Vector3(slot_w[i] + 0.02, 0.135, 0.012), bar))


func _comp_redaction() -> void:
	_comp_formula_plate(0)


## QUORUM — three terms in session. Two lit satellite dials stand with the crystal,
## each tied back into the containment: the bench admits it cannot mean anything alone.
func _comp_quorum_one(sx: float, glyph: String, col: Color) -> void:
	var steel: StandardMaterial3D = _steel_mat(Color(0.55, 0.60, 0.72))
	add_child(_cylinder(Vector3(sx, COMP_Y + 0.24, COMP_Z), 0.035, 0.48, steel))
	add_child(_box(Vector3(sx, COMP_Y + 0.50, COMP_Z), Vector3(0.20, 0.20, 0.015),
		_matte_mat(Color(0.88, 0.90, 0.94), 0.4)))
	var ring: MeshInstance3D = _torus(Vector3(sx, COMP_Y + 0.50, COMP_Z + 0.012), 0.115, 0.014,
		_glow_mat(col, 2.0))
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(ring)
	var needle: MeshInstance3D = _box(Vector3(sx, COMP_Y + 0.548, COMP_Z + 0.03),
		Vector3(0.014, 0.085, 0.012), _glow_mat(Color(1.0, 0.85, 0.40), 2.2))
	needle.rotation_degrees = Vector3(0.0, 0.0, 22.0)
	add_child(needle)
	add_child(_comp_ink(glyph, Vector3(sx, COMP_Y + 0.455, COMP_Z + 0.03), 20, Color(0.10, 0.11, 0.15)))
	add_child(_cylinder_between(Vector3(sx, COMP_Y + 0.50, COMP_Z),
		_comp_hub() + Vector3(0.0, -0.02, 0.0), 0.014, _glow_mat(col, 1.2)))


func _comp_quorum() -> void:
	_comp_quorum_one(-COMP_X, COMP_A_GLYPH, COMP_A_COLOR)
	_comp_quorum_one(COMP_X, COMP_B_GLYPH, COMP_B_COLOR)


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
