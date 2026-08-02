extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name QfepReactorBench

## @identity
## name: "The reactor — the whole formula"
## tier: medium
## lineage: A floor-standing bench reactor (~1m). Three dials — F, λ, φ — feed a
##   central glass chamber where a system flickers across its life as the dials
##   sweep: dead-ordered (a frozen lattice) → living-complex at the edge (a
##   loose, breathing swarm) → dead-random (a scattered cloud). A readout panel
##   shows QFE = F − λE + φΔE and a one-word verdict: FROZEN / ALIVE / NOISE.
## truth: "SET THE TERMS, WATCH IT FLICKER INTO LIFE."
## applications: the QFEP machine made operable — a bench you set and read; the
##   edge of chaos as an instrument reading; the whole formula, dialled.

@export var sweep_rate: float = 0.12
@export var particle_count: int = 14
@export var body_col: Color = Color(0.14, 0.16, 0.23)
@export var glass_col: Color = Color(0.46, 0.78, 0.98)
@export var frozen_col: Color = Color(0.40, 0.64, 1.0)
@export var alive_col: Color = Color(0.50, 0.99, 0.74)
@export var noise_col: Color = Color(0.78, 0.52, 0.98)
@export var dial_f_col: Color = Color(0.55, 0.92, 0.99)
@export var dial_l_col: Color = Color(0.62, 0.55, 0.98)
@export var dial_p_col: Color = Color(0.55, 0.99, 0.78)
@export var panel_col: Color = Color(0.07, 0.09, 0.13)
@export var readout_col: Color = Color(0.55, 0.98, 0.85)
@export var label_col: Color = Color(0.92, 0.96, 1.0)

## AXIS — COMPLEMENT: what this bench shows of the equation it does NOT run.
##
## The other three benches isolate a term; this one claims the whole formula, and its
## title says so. Read the formula again and find what is missing anyway:
##
##     QFE = F − λE(S) + φΔE(S,t)
##
## S. The system. It appears twice, it is what every term is a term OF, and there is
## no dial for it on this deck — three knobs for the weights and none for the thing
## being weighed. The chamber holds fourteen abstract particles standing in for any
## system whatsoever, which is the same move as having no system at all. Worse, the
## three needles are ganged: one hidden sweep drives all of them, so the bench shows a
## console you could set and is in fact a film you can only watch.
##
## So the complement here is not another term, it is the referent — and the axis is
## the same question the other three benches answer: how much does the bench admit is
## missing?
##
##   none       nothing — the legacy lineage, byte for byte. The whole formula, it says.
##   ghost      two dead mounts on the deck: capped stubs, blanked grey face plates,
##              unlit E and S tags. Provision was made for them and never fitted.
##   supply     two lit tributary conduits rise off the deck and plug into the chamber's
##              underside. The system is not in the glass; it is piped in from elsewhere.
##   redaction  a bone-white plate across the skirt carrying the whole formula with
##              (S) and (S,t) struck under black bars — the terms kept, their referent
##              blacked out — and the terms it does run underlined in accent.
##   quorum     two lit satellite dials, E and S, stand with the three and are linked
##              into the chamber. Five instruments, and the formula is finally whole.
##
## Shared word for word with [[f_order_bench]], [[lambda_dial_bench]] and
## [[phi_rate_bench]] — one equation, one vocabulary.
@export_enum("none", "ghost", "supply", "redaction", "quorum") var complement: String = "none"
const COMPLEMENTS: PackedStringArray = ["none", "ghost", "supply", "redaction", "quorum"]

## Seed for the particles' chaos homes. −1 keeps today's behaviour (randomize on every
## spawn); any value ≥ 0 makes the swarm reproducible, which is what a sweep needs —
## otherwise five variants of an axis are also five different swarms, and at the sweep's
## capture moment the swarm is most of the way to chaos, so that noise would be measured
## as the axis.
@export var chaos_seed: int = -1

# The two things this bench does not put a dial on — glyph, and the family's colour.
const COMP_A_GLYPH := "E"
const COMP_A_COLOR := Color(0.98, 0.78, 0.42)
const COMP_B_GLYPH := "S"
const COMP_B_COLOR := Color(0.98, 0.55, 0.62)
# Where the complement hardware stands: flank offset, deck height, forward offset.
# Deliberately inside the existing silhouette (body 0.95 wide, readout panel top y 1.33)
# so a variant is not also a different camera distance.
const COMP_X := 0.40
const COMP_Y := 0.615
const COMP_Z := 0.0

var _t: float = 0.0
var _sweep: float = 0.5            # 0 = frozen, 0.5 = alive (edge), 1 = noise
var _chamber_c := Vector3(0.0, 0.78, 0.0)
var _chamber_r: float = 0.20
var _particles: Array[MeshInstance3D] = []
var _order_pos: Array[Vector3] = []
var _chaos_pos: Array[Vector3] = []
var _needle_f: MeshInstance3D = null
var _needle_l: MeshInstance3D = null
var _needle_p: MeshInstance3D = null
var _readout: Label3D = null
var _verdict: Label3D = null
var _dial_f_c := Vector3(-0.32, 0.62, 0.30)
var _dial_l_c := Vector3(0.0, 0.62, 0.34)
var _dial_p_c := Vector3(0.32, 0.62, 0.30)
var _dial_r: float = 0.085


func _ready() -> void:
	_read_dna_meta()
	if chaos_seed < 0:
		_rng.randomize()
	else:
		_rng.seed = chaos_seed
	_build()
	set_process(not Engine.is_editor_hint())


# The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the first
# build; apply_grid_config (deferred) covers the rebuild path. Unknown words keep the
# default — an axis must never be able to blank an artifact by typo.
func _read_dna_meta() -> void:
	if has_meta("config_complement"):
		var c_in: String = str(get_meta("config_complement")).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if has_meta("config_chaos_seed"):
		chaos_seed = int(str(get_meta("config_chaos_seed")))


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("complement"):
		var c_in: String = str(config["complement"]).strip_edges().to_lower()
		complement = c_in if COMPLEMENTS.has(c_in) else complement
	if config.has("chaos_seed"):
		chaos_seed = int(str(config["chaos_seed"]))
		if chaos_seed >= 0:
			_rng.seed = chaos_seed
	if config.has("sweep_rate"):
		sweep_rate = clampf(float(config["sweep_rate"]), 0.05, 0.4)
	if config.has("particle_count"):
		particle_count = int(clampf(float(config["particle_count"]), 6.0, 28.0))
	if config.has("alive_col"):
		alive_col = _parse_color(config["alive_col"], alive_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_particles.clear()
	_order_pos.clear()
	_chaos_pos.clear()
	_needle_f = null
	_needle_l = null
	_needle_p = null
	_readout = null
	_verdict = null
	_build()


func _build() -> void:
	# Bench body — a ~1m console with a sloped control deck.
	add_child(_box(Vector3(0.0, 0.30, 0.0), Vector3(0.95, 0.60, 0.55), _matte_mat(body_col, 0.85)))
	add_child(_box(Vector3(0.0, 0.605, 0.0), Vector3(0.97, 0.02, 0.57), _steel_mat(Color(0.32, 0.34, 0.40))))
	# Plinth feet hint.
	add_child(_box(Vector3(0.0, 0.01, 0.0), Vector3(1.0, 0.02, 0.60), _matte_mat(Color(0.08, 0.09, 0.12), 0.9)))

	# Three dials on the deck — the terms F, λ, φ.
	_needle_f = _add_dial(_dial_f_c, dial_f_col, "F")
	_needle_l = _add_dial(_dial_l_c, dial_l_col, "λ")
	_needle_p = _add_dial(_dial_p_c, dial_p_col, "φ")

	# Feed-lines from each dial up into the chamber base.
	add_child(_cylinder_between(_dial_f_c + Vector3(0, 0.02, 0), _chamber_c + Vector3(-0.12, -0.18, 0), 0.012, _glow_mat(dial_f_col, 0.7)))
	add_child(_cylinder_between(_dial_l_c + Vector3(0, 0.02, 0), _chamber_c + Vector3(0.0, -0.20, 0), 0.012, _glow_mat(dial_l_col, 0.7)))
	add_child(_cylinder_between(_dial_p_c + Vector3(0, 0.02, 0), _chamber_c + Vector3(0.12, -0.18, 0), 0.012, _glow_mat(dial_p_col, 0.7)))

	# Central chamber — glass sphere on a steel collar.
	add_child(_cylinder(_chamber_c + Vector3(0, -0.22, 0), 0.10, 0.10, _steel_mat(Color(0.28, 0.30, 0.36))))
	add_child(_sphere(_chamber_c, _chamber_r + 0.02, _glass_mat(glass_col, 0.13)))

	# Particles — order homes (lattice ring) + chaos homes (scatter).
	for i in range(particle_count):
		var ang: float = TAU * float(i) / float(particle_count)
		var ord_p: Vector3 = _chamber_c + Vector3(cos(ang), sin(ang * 2.3) * 0.5, sin(ang)) * (_chamber_r * 0.62)
		_order_pos.append(ord_p)
		var ch_p: Vector3 = _chamber_c + Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)).normalized() * (_chamber_r * _rng.randf_range(0.45, 0.92))
		_chaos_pos.append(ch_p)
		var p: MeshInstance3D = _sphere(ord_p, 0.016, _glow_mat(frozen_col, 1.0))
		_particles.append(p)
		add_child(p)

	# Readout panel — raised behind the chamber.
	add_child(_box(Vector3(0.0, 1.18, -0.12), Vector3(0.72, 0.30, 0.02), _matte_mat(panel_col, 0.4)))
	add_child(_box(Vector3(0.0, 1.18, -0.118), Vector3(0.70, 0.28, 0.005), _glow_mat(Color(0.12, 0.18, 0.24), 0.25)))
	_readout = _billboard_label(_readout_text(), Vector3(0.0, 1.22, -0.10), 15, readout_col)
	add_child(_readout)
	_verdict = _billboard_label(_verdict_text(), Vector3(0.0, 1.08, -0.10), 22, alive_col)
	add_child(_verdict)

	# Billboard title.
	add_child(_billboard_label("QFEP REACTOR BENCH — THE WHOLE FORMULA", Vector3(0.0, 1.5, 0.0), 18, label_col))

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


func _add_dial(center: Vector3, col: Color, text: String) -> MeshInstance3D:
	# Dial face, tilted up on the deck.
	add_child(_cylinder(center, _dial_r, 0.02, _matte_mat(Color(0.90, 0.92, 0.96), 0.4)))
	add_child(_torus(center + Vector3(0, 0.012, 0), _dial_r, 0.008, _glow_mat(col, 0.9)))
	# Tick marks at the sweep ends + midpoint.
	add_child(_box(center + Vector3(-_dial_r * 0.78, 0.018, 0.0), Vector3(0.008, 0.004, 0.016), _glow_mat(col, 0.8)))
	add_child(_box(center + Vector3(0.0, 0.018, _dial_r * 0.78), Vector3(0.016, 0.004, 0.008), _glow_mat(Color(1, 1, 1), 1.0)))
	add_child(_box(center + Vector3(_dial_r * 0.78, 0.018, 0.0), Vector3(0.008, 0.004, 0.016), _glow_mat(col, 0.8)))
	# Needle — a flat pointer pivoting at the dial center.
	var needle: MeshInstance3D = _box(center + Vector3(0.0, 0.02, _dial_r * 0.4), Vector3(0.010, 0.006, _dial_r * 0.8), _glow_mat(Color(0.10, 0.11, 0.14), 0.2))
	add_child(needle)
	add_child(_billboard_label(text, center + Vector3(0.0, 0.09, 0.0), 14, col))
	return needle


func _aliveness(s: float) -> float:
	# Bell curve peaking at the edge (s = 0.5), dead at both ends.
	return exp(-pow((s - 0.5) / 0.18, 2.0))


func _verdict_state() -> String:
	if _sweep < 0.28:
		return "FROZEN"
	if _sweep > 0.72:
		return "NOISE"
	return "ALIVE"


func _state_color() -> Color:
	if _sweep < 0.5:
		return frozen_col.lerp(alive_col, _sweep * 2.0)
	return alive_col.lerp(noise_col, (_sweep - 0.5) * 2.0)


func _readout_text() -> String:
	# F term high, E term penalised by λ, ΔE term the φ relational bonus.
	var f_term: float = 0.5 + (1.0 - _sweep) * 0.5
	var e_term: float = _sweep
	var de_term: float = _aliveness(_sweep)
	var qfe: float = f_term - 0.5 * e_term + 0.5 * de_term
	return "QFE = F - lambda*E + phi*dE\nF=%.2f  E=%.2f  dE=%.2f\nQFE = %.2f" % [f_term, e_term, de_term, qfe]


func _verdict_text() -> String:
	return _verdict_state()


func _set_needle(needle: MeshInstance3D, center: Vector3, frac: float) -> void:
	if needle == null:
		return
	# Sweep needle from -70deg (left tick) to +70deg (right tick) about Y.
	var ang: float = lerpf(deg_to_rad(70.0), deg_to_rad(-70.0), frac)
	var b := Basis(Vector3.UP, ang)
	needle.transform = Transform3D(b, center + Vector3(0.0, 0.02, 0.0)).translated_local(Vector3(0.0, 0.0, _dial_r * 0.4))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Slow sweep across the system's whole life.
	_sweep = sin(_t * TAU * sweep_rate) * 0.5 + 0.5
	var alive: float = _aliveness(_sweep)
	var col: Color = _state_color()

	# Dials track the terms: F falls as the system disorders; λ-load (E) rises;
	# φ-bonus (ΔE) peaks at the edge.
	_set_needle(_needle_f, _dial_f_c, 1.0 - _sweep)
	_set_needle(_needle_l, _dial_l_c, _sweep)
	_set_needle(_needle_p, _dial_p_c, alive)

	# Particles: lattice when frozen, breathing swarm at the edge, cloud as noise.
	for i in range(_particles.size()):
		var p: MeshInstance3D = _particles[i]
		var home: Vector3 = _order_pos[i].lerp(_chaos_pos[i], _sweep)
		# Edge-of-chaos breathing: motion peaks in the alive middle.
		var breath := Vector3(
			sin(_t * 4.0 + float(i) * 1.3),
			cos(_t * 3.4 + float(i) * 0.8),
			sin(_t * 4.7 + float(i))) * (0.02 * alive)
		# Hard chaos jitter that only grows toward noise.
		var jit := Vector3(
			sin(_t * 11.0 + float(i)),
			cos(_t * 9.7 + float(i) * 2.1),
			sin(_t * 13.0 + float(i) * 0.7)) * (0.012 * clampf((_sweep - 0.5) * 2.0, 0.0, 1.0))
		p.position = home + breath + jit
		p.material_override = _glow_mat(col, 0.9 + alive * 0.6)

	if _readout != null:
		_readout.text = _readout_text()
	if _verdict != null:
		_verdict.text = _verdict_text()
		_verdict.modulate = col


# ── COMPLEMENT ───────────────────────────────────────────────────────────────
# Five values, four builders, appended after everything else. The gestures are
# identical across the four QFEP benches — only the anchors and the two absent
# glyphs change — so a room of them reads as one instrument family taking one
# position on its own isolation.

# Where the missing referent would plug in: the underside of the glass chamber.
func _comp_hub() -> Vector3:
	return _chamber_c + Vector3(0.0, -0.10, 0.0)


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
## plate with the tag on it, all unlit. Grey and not black on purpose: the capture
## stage is near-black, and a black value is an invisible one.
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


## SUPPLY — the referent is piped in. A lit conduit rises off the deck and elbows into
## the chamber collar, in the colour the family gives it, tagged at the base.
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
	# The intake collar rings the glass at the point of entry (r > the sphere's
	# section there), rather than sitting inside it as a hidden disc.
	add_child(_torus(_comp_hub(), 0.26, 0.022, _steel_mat(Color(0.55, 0.60, 0.72))))


## REDACTION — the bench prints what it cut. A bone plate across the front skirt carries
## the whole formula; the terms it runs are underlined in accent, and the two places
## where the SYSTEM is named — (S) and (S,t) — go under matte-black bars.
func _comp_formula_plate() -> void:
	var py: float = 0.34
	var pz: float = 0.29
	var bone: StandardMaterial3D = _matte_mat(Color(0.87, 0.86, 0.82), 0.55)
	var steel: StandardMaterial3D = _steel_mat(Color(0.42, 0.45, 0.52))
	var bar: StandardMaterial3D = _matte_mat(Color(0.05, 0.05, 0.07), 0.98)
	var ink: Color = Color(0.10, 0.11, 0.15)
	add_child(_box(Vector3(0.0, py, pz - 0.012), Vector3(0.92, 0.28, 0.02), steel))
	add_child(_box(Vector3(0.0, py, pz), Vector3(0.88, 0.24, 0.02), bone))
	add_child(_comp_ink("QFE = F - λE", Vector3(-0.20, py, pz + 0.02), 13, ink))
	add_child(_comp_ink("+ φΔE", Vector3(0.185, py, pz + 0.02), 13, ink))
	# The terms it does run, underlined — the family's accent-box gesture.
	var lit: StandardMaterial3D = _glow_mat(readout_col, 1.4)
	add_child(_box(Vector3(-0.20, py - 0.075, pz + 0.011), Vector3(0.40, 0.012, 0.006), lit))
	add_child(_box(Vector3(0.185, py - 0.075, pz + 0.011), Vector3(0.17, 0.012, 0.006), lit))
	# The referent, struck out in both places it is named.
	add_child(_box(Vector3(0.05, py, pz + 0.015), Vector3(0.12, 0.15, 0.012), bar))
	add_child(_box(Vector3(0.355, py, pz + 0.015), Vector3(0.19, 0.15, 0.012), bar))


func _comp_redaction() -> void:
	_comp_formula_plate()


## QUORUM — five instruments. Lit satellite dials for E and S stand with the three and
## are linked into the chamber: the bench admits what its console left off.
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
