extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LambdaDialBench

## @identity
## name: Lambda Dial Bench
## concept: lambda (the order-chaos dial) — λ in QFE = F − λE(S) + φΔE(S,t)
## tier: medium
## truth: life sits at λ ≈ 0.3–0.5 — turn the dial too low and it freezes, too high and it dissolves.
##
## A floor-standing QFEP instrument with one big λ dial you watch sweep 0 → 1. A field of
## ~49 units reads the dial: at λ=0 they lock into a frozen crystal grid, at λ=1 they
## explode into pure noise, and in the gold band λ≈0.3–0.5 they organize into a living,
## breathing, complex pattern. The dial oscillates on its own; the field morphs to match.
## Readout: "λ = 0.40  LIFE".

@export var field_n: int = 7                  # field is n×n units
@export var field_pitch: float = 0.13
@export var field_center: Vector3 = Vector3(0.0, 1.05, 0.0)
@export var sweep_period: float = 12.0        # seconds for one full λ sweep cycle
@export var crystal_color: Color = Color(0.45, 0.75, 1.0)
@export var life_color: Color = Color(0.5, 1.0, 0.65)
@export var noise_color: Color = Color(0.95, 0.5, 0.85)

## AXIS — COMPLEMENT: what this bench shows of the equation it does NOT run.
##
## QFE = F − λE(S) + φΔE(S,t). This bench owns the middle term and nothing else. It
## sweeps λ from 0 to 1 and lets a field of 49 units answer — frozen, alive, noise —
## and the reading it prints ("λ = 0.40 LIFE") is stated as if λ were a quantity you
## could read off the world. It is not. λ is a WEIGHT: how much this system is willing
## to pay in order for the disorder it buys. A weight with no F to trade against and
## no φ to spend it over is a dial with nothing on the other end.
##
## The bench does not say that either. So the axis is the saying: how much of its own
## complement does this bench admit is missing?
##
##   none       nothing — the legacy lineage, byte for byte. λ alone, unremarked.
##   ghost      two dead mounts on the deck: capped stubs, blanked grey face plates,
##              unlit F and φ tags. Provision was made for them and never fitted.
##   supply     two lit tributary conduits rise from the deck and plug in under the
##              field. The dial is not self-standing; it is being fed.
##   redaction  a bone-white plate across the front carrying the whole formula, with
##              F and φΔE(S,t) struck under black bars and λE boxed in accent. The
##              bench prints what it cut.
##   quorum     two lit satellite dials stand with the big one, F and φ present and
##              linked in. Three terms in session; one of them speaking.
##
## Shared word for word with [[f_order_bench]], [[phi_rate_bench]] and
## [[qfep_reactor_bench]] — one equation, one vocabulary. It would be incoherent for
## the λ bench and the F bench to speak differently about the same formula.
@export_enum("none", "ghost", "supply", "redaction", "quorum") var complement: String = "none"
const COMPLEMENTS: PackedStringArray = ["none", "ghost", "supply", "redaction", "quorum"]

## Seed for the per-unit noise vectors + wave phases. −1 keeps today's behaviour
## (randomize on every spawn); any value ≥ 0 makes the field reproducible, which is
## what a sweep needs — otherwise five variants of an axis are also five different
## fields, and the noise is measured as the axis.
@export var field_seed: int = -1

# The two terms this bench does not run — glyph, and the colour the family gives it.
const COMP_A_GLYPH := "F"
const COMP_A_COLOR := Color(0.55, 0.92, 0.99)
const COMP_B_GLYPH := "φ"
const COMP_B_COLOR := Color(0.55, 0.99, 0.78)
# Where the complement hardware stands: flank offset, deck height, forward offset.
# Deliberately inside the existing silhouette (the dial already reaches x −0.81, the
# field y 1.05) so a variant is not also a different camera distance.
const COMP_X := 0.40
const COMP_Y := 0.145
const COMP_Z := 0.10

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _count: int = 0
var _grid: PackedVector3Array = PackedVector3Array()    # ordered crystal sites
var _seed_off: PackedVector3Array = PackedVector3Array() # per-unit random vector for noise
var _phase: PackedFloat32Array = PackedFloat32Array()
var _title: Label3D
var _readout: Label3D
var _needle: MeshInstance3D
var _needle_mat: StandardMaterial3D
var _gold_arc: MeshInstance3D
var _lambda: float = 0.0
var _t: float = 0.0
const GOLD_LO: float = 0.3
const GOLD_HI: float = 0.5


func _ready() -> void:
	_read_dna_meta()
	if field_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = field_seed
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("complement"):
		var c_in: String = str(config["complement"]).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if config.has("field_seed"):
		field_seed = int(str(config["field_seed"]))
		if field_seed >= 0:
			_rng.seed = field_seed
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


# The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the first
# build; apply_grid_config (deferred) covers the rebuild path. Unknown words keep the
# default — an axis must never be able to blank an artifact by typo.
func _read_dna_meta() -> void:
	if has_meta("config_complement"):
		var c_in: String = str(get_meta("config_complement")).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if has_meta("config_field_seed"):
		field_seed = int(str(get_meta("config_field_seed")))


func _build() -> void:
	_count = field_n * field_n

	# --- plinth + post ---
	add_child(_cylinder(Vector3(0.0, 0.04, 0.0), 0.46, 0.08, _steel_mat(Color(0.14, 0.18, 0.28))))
	add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.40, 0.06, _matte_mat(Color(0.18, 0.24, 0.38), 0.6, 0.3)))
	add_child(_cylinder(Vector3(0.0, 0.42, 0.0), 0.05, 0.6, _steel_mat(Color(0.4, 0.5, 0.7))))

	# --- the big λ dial face (left side, tilted toward viewer) ---
	var dial_center: Vector3 = Vector3(-0.55, 1.05, 0.0)
	add_child(_cylinder(dial_center + Vector3(0.0, 0.0, -0.03), 0.26, 0.04, _matte_mat(Color(0.1, 0.13, 0.2))))
	add_child(_torus(dial_center, 0.26, 0.02, _steel_mat(Color(0.6, 0.66, 0.8))))
	# tick marks 0 → 1 across a 270° arc
	for ti in range(11):
		var frac: float = float(ti) / 10.0
		var a: float = lerp(2.356, -2.356, frac)   # 135° → -135°
		var tip: Vector3 = dial_center + Vector3(cos(a), sin(a), 0.0) * 0.24
		var inn: Vector3 = dial_center + Vector3(cos(a), sin(a), 0.0) * 0.20
		add_child(_cylinder_between(inn, tip, 0.006, _glow_mat(Color(0.7, 0.8, 1.0), 1.4)))
	# gold zone arc (λ 0.3–0.5) — a bright band on the dial
	_gold_arc = _make_arc(dial_center, 0.215, GOLD_LO, GOLD_HI, _glow_mat(Color(1.0, 0.85, 0.3), 2.6))
	add_child(_gold_arc)
	add_child(_billboard_label("0", dial_center + Vector3(-0.18, -0.2, 0.01), 13, Color(0.7, 0.78, 0.9)))
	add_child(_billboard_label("1", dial_center + Vector3(0.18, -0.2, 0.01), 13, Color(0.7, 0.78, 0.9)))
	add_child(_billboard_label("λ", dial_center + Vector3(0.0, 0.33, 0.01), 22, Color(0.9, 0.95, 1.0)))
	# the needle (rotates with λ)
	_needle_mat = _glow_mat(Color(1.0, 0.4, 0.4), 2.4)
	_needle = _cylinder(dial_center, 0.008, 0.22, _needle_mat)
	add_child(_needle)
	add_child(_sphere(dial_center, 0.03, _steel_mat(Color(0.8, 0.85, 0.95))))

	# --- title + readout ---
	_title = _billboard_label("λ  —  THE ORDER-CHAOS DIAL", Vector3(0.0, 1.5, 0.0), 22, Color(0.88, 0.95, 1.0))
	add_child(_title)
	add_child(_billboard_label("0 = crystal · 0.4 = LIFE · 1 = noise", Vector3(0.0, 1.36, 0.0), 14, Color(0.7, 0.78, 0.92)))
	_readout = _billboard_label("λ = 0.00", Vector3(0.42, 1.22, 0.0), 22, life_color)
	add_child(_readout)

	# --- the field that reads the dial ---
	_grid.resize(_count)
	_seed_off.resize(_count)
	_phase.resize(_count)
	var i: int = 0
	var off: float = float(field_n - 1) * 0.5
	for ix in range(field_n):
		for iz in range(field_n):
			_grid[i] = field_center + Vector3((float(ix) - off) * field_pitch, 0.0, (float(iz) - off) * field_pitch)
			_seed_off[i] = Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
			_phase[i] = _rng.randf() * TAU
			i += 1

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = _count
	var cube: BoxMesh = BoxMesh.new()
	cube.size = Vector3.ONE * (field_pitch * 0.46)
	_mm.mesh = cube
	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "LambdaField"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_mat(Color(1, 1, 1), 1.8)
	add_child(_mm_inst)

	_apply_field()

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


func _life_strength(lam: float) -> float:
	# peaks at the center of the gold band, falls off either side.
	var mid: float = (GOLD_LO + GOLD_HI) * 0.5
	var d: float = absf(lam - mid) / 0.28
	return clampf(1.0 - d * d, 0.0, 1.0)


func _apply_field() -> void:
	var life: float = _life_strength(_lambda)
	# crystal weight high when λ low; noise weight high when λ high.
	var noise_w: float = clampf((_lambda - GOLD_HI) / (1.0 - GOLD_HI), 0.0, 1.0)
	var spread: float = field_pitch * (field_n) * 0.5
	for i in range(_count):
		var site: Vector3 = _grid[i]
		# noise displacement (grows with λ past the gold band)
		var noise: Vector3 = _seed_off[i] * spread * noise_w
		noise += Vector3(
			sin(_t * 3.0 + _phase[i]),
			cos(_t * 2.6 + _phase[i] * 1.4),
			sin(_t * 2.2 + _phase[i] * 0.7)) * (field_pitch * 1.6 * noise_w)
		# life displacement: a coherent travelling wave — only in the gold band
		var wave: float = sin((site.x + site.z) * 6.0 - _t * 3.0 + _phase[i] * 0.2)
		var living: Vector3 = Vector3(0.0, wave * field_pitch * 0.9 * life, 0.0)
		var pos: Vector3 = site + noise + living
		var b: Basis = Basis()
		var spin: float = noise_w * (_phase[i] + _t * 1.5)
		b = b.rotated(Vector3(0.4, 1.0, 0.2).normalized(), spin)
		_mm.set_instance_transform(i, Transform3D(b, pos))
		# color: crystal → life → noise
		var col: Color = crystal_color
		if _lambda <= GOLD_HI:
			col = crystal_color.lerp(life_color, life)
		else:
			col = life_color.lerp(noise_color, noise_w)
		_mm.set_instance_color(i, col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# λ oscillates 0 → 1 → 0 slowly, lingering a touch in the gold band.
	var raw: float = 0.5 - 0.5 * cos(_t * TAU / sweep_period)
	_lambda = clampf(raw, 0.0, 1.0)
	_apply_field()

	# rotate the needle to match λ (135° → -135°)
	if _needle != null:
		var a: float = lerp(2.356, -2.356, _lambda)
		var dial_center: Vector3 = Vector3(-0.55, 1.05, 0.0)
		var dir: Vector3 = Vector3(cos(a), sin(a), 0.0)
		_needle.transform = Transform3D(_basis_y_to(dir), dial_center + dir * 0.11)
		# needle warms toward red as it leaves the gold band
		var life: float = _life_strength(_lambda)
		_needle_mat.emission = Color(1.0, 0.4, 0.4).lerp(Color(1.0, 0.85, 0.3), life)

	# readout text + a verdict word
	if _readout != null:
		var verdict: String = "NOISE"
		var col: Color = noise_color
		if _lambda < GOLD_LO:
			verdict = "FROZEN"
			col = crystal_color
		elif _lambda <= GOLD_HI:
			verdict = "LIFE"
			col = life_color
		_readout.text = "λ = %.2f  %s" % [_lambda, verdict]
		_readout.modulate = col


# ── COMPLEMENT ───────────────────────────────────────────────────────────────
# Five values, four builders, appended after everything else. The gestures are
# identical across the four QFEP benches — only the anchors and the two absent
# glyphs change — so a room of them reads as one instrument family taking one
# position on its own isolation.

# Where the missing terms would plug in: just under the field the dial drives.
func _comp_hub() -> Vector3:
	return field_center + Vector3(0.0, -0.10, 0.0)


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
## field's underside, in the colour the family gives that term, tagged at the base.
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
	var py: float = 0.62
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
				Vector3(slot_w[i] + 0.03, 0.15, 0.006), _glow_mat(life_color, 1.4)))
			add_child(_comp_ink(slot_t[i], Vector3(slot_x[i], py, pz + 0.025), 13,
				Color(0.06, 0.07, 0.10)))
		else:
			add_child(_box(Vector3(slot_x[i], py, pz + 0.015),
				Vector3(slot_w[i] + 0.02, 0.135, 0.012), bar))


func _comp_redaction() -> void:
	_comp_formula_plate(1)


## QUORUM — three terms in session. Two lit satellite dials stand with the big one,
## each tied back into the field: the bench admits it cannot mean anything alone.
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


# --- a thin filled arc band on the dial face (immediate-mesh ring sector) ---
func _make_arc(center: Vector3, radius: float, frac_lo: float, frac_hi: float, mat: Material) -> MeshInstance3D:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	var inner: float = radius - 0.03
	var outer: float = radius + 0.03
	var segs: int = 16
	var a_lo: float = lerp(2.356, -2.356, frac_lo)
	var a_hi: float = lerp(2.356, -2.356, frac_hi)
	for s in range(segs):
		var t0: float = float(s) / float(segs)
		var t1: float = float(s + 1) / float(segs)
		var aa: float = lerp(a_lo, a_hi, t0)
		var ab: float = lerp(a_lo, a_hi, t1)
		var i0: Vector3 = Vector3(cos(aa) * inner, sin(aa) * inner, 0.0)
		var o0: Vector3 = Vector3(cos(aa) * outer, sin(aa) * outer, 0.0)
		var i1: Vector3 = Vector3(cos(ab) * inner, sin(ab) * inner, 0.0)
		var o1: Vector3 = Vector3(cos(ab) * outer, sin(ab) * outer, 0.0)
		im.surface_add_vertex(i0)
		im.surface_add_vertex(o0)
		im.surface_add_vertex(o1)
		im.surface_add_vertex(i0)
		im.surface_add_vertex(o1)
		im.surface_add_vertex(i1)
	im.surface_end()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = im
	mi.position = center + Vector3(0.0, 0.0, 0.01)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
