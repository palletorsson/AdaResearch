# CSG Compose Workbench — the `csg-compose` catalyst affordance
#
# A working surface holding three preset CSG compositions visible from a player's stance.
# Each preset shows the same two primitives (box + sphere) with one of the three
# operators applied: union, intersection, difference. A central glowing pillar above
# the workbench labels the active demonstration with the operator symbol.
#
# The workbench is the *introduction* artifact for the player's csg-compose affordance:
# stand at the bench, see all three operators side by side, pick one with the bracelet,
# replicate the operation by hand.
#
# @identity
# essence: A workbench holding all three CSG operators side by side — union, intersection, difference — applied to the same box+sphere pair, each labeled by symbol.
# desire: To let the player meet the whole composition algebra at once and pick an operator by hand with the catalyst bracelet.
# critical_parameter: preset_spacing — how far apart the three demonstrations sit. Too close and the operators blur together; too far and the comparison between them is lost.
# triggers: Stand at the bench; the csg-compose affordance lets the bracelet select an operator and replicate it. Presets rotate to stay legible.
# emerges: The realization that union, intersection, and difference are one family — three lawful ways to compose two solids.
# needs: Procedural presets [has], catalyst affordance [has]. Missing: a live player-built composition surface beside the three fixed presets.
# relationships: The introduction hub for csg_union_demo, csg_intersection_demo, and csg_difference_demo. Hands the player the operators that csg_architecture_cavity then puts to work.
# truth: Three operators, one algebra. Composition is a choice — keep all, keep the shared, or take away.
# @qfep_term: F — composition algebra.

extends Node3D
class_name CSGComposeWorkbench

# --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
# WHAT THIS ARTIFACT ARGUES that its siblings do not. fontana_puncture and
# csg_difference_demo are each ONE operation — an artwork and a demonstration of
# the same cube-minus-sphere. This one holds the whole bench, so its first
# question is not how deep the cut is or how much of the derivation is drawn. It
# is WHICH OPERATORS ARE ON THE BENCH: what the set of lawful compositions is
# taken to be. Its own truth line already says three, and says what they are —
# "keep all, keep the shared, or take away" — and it has never shipped any other
# claim. Seven placements, every one of them the same three.
#
# algebra — WHICH OPERATORS STAND ON THE BENCH. A new word: no axis in the corpus
#   asks what a closed operator set consists of, and the nearest neighbours are
#   about a single operation's depth (fontana's `breach`) or its exposition
#   (`workings`). The four values are four honest answers to "what is the algebra":
#     triad      SHIPPED. Godot's three CSG primitives and the three the bracelet
#                offers: A ∪ B, A ∩ B, A − B. The set as tooling defines it.
#     ordered    adds B − A beside A − B. Four benches, and the pair is the whole
#                proof that difference is the only non-commutative operator here —
#                which is precisely the demonstration csg_difference_demo declined
#                to swallow into its own `workings` and deferred to "a second
#                object beside this one". This is that object.
#     complete   adds the symmetric difference (A ∪ B) − (A ∩ B). Five benches.
#                XOR is derivable from the other four and is not a CSG primitive,
#                so this value is the difference between the operators a TOOL has
#                and the operators an ALGEBRA has.
#     atoms      not operators at all: the three disjoint regions A − B, A ∩ B and
#                B − A, which is the partition every one of the above is a union
#                of. Three benches again, and the same count is the point — the
#                bench looks like the shipped one and is arguing the opposite
#                thing: the operators are not primitive, the regions are.
#
# strike — WHERE B MEETS A. Reused CHARACTER FOR CHARACTER from fontana_puncture
#   and csg_difference_demo, same word, same four values, same question. What
#   differs, said plainly: the numbers are not theirs and cannot be. Fontana's
#   sphere is 1.36 half-extents and the demo's is 1.10; this bench's is 1.33
#   (r 0.3 against a 0.225 half-extent), so the same fraction of box_size cuts a
#   different topology in each. The three agree on the word and the value list and
#   each resolves it against its own geometry, which is what makes them comparable
#   rather than merely identical. Here it does something neither sibling can: ONE
#   offset drives every operator on the bench at once, so the axis is the bench's
#   own claim — that these are one family — put under load.
#     corner   SHIPPED, and a short-circuit: returns preset_offset untouched.
#     centred  the sphere concentric. Union is a ball with eight box corners
#              poking out (corner distance 0.39 > r 0.3), intersection is the ball
#              flattened on six faces, difference breaches all six faces at once
#              and the box survives as its twelve edges — three unmistakably
#              different pictures from one placement.
#     raised   0.30 of box_size up: the top engaged, the cut still meeting the sides.
#     grazing  0.48 up, the sphere centre all but on the top face — a cap, a scoop
#              and a bulge rather than anything internal.
#
# WHAT IS DECLINED. `workings` (outcome | trace | operands | expression), the
# twelve-artifact family word, genuinely FITS this artifact — the bench shows only
# outcomes and could ghost its operands like its sibling does. It is not shipped
# because the sibling already holds it: csg_difference_demo's promotion is exactly
# how much of ONE operation is drawn, and repeating it here over up to five presets
# would fill the frame with translucent boxes and say the family's existing thing
# five times. The hub's question is the set; the demo's question is the derivation.
# Kept apart, the two artifacts are comparable. Merged, one of them is redundant.
const ALGEBRAS: PackedStringArray = ["triad", "ordered", "complete", "atoms"]
const STRIKES: PackedStringArray = ["centred", "raised", "corner", "grazing"]

@export_category("Workbench Settings")
@export_enum("triad", "ordered", "complete", "atoms") var algebra: String = "triad"
@export_enum("centred", "raised", "corner", "grazing") var strike: String = "corner"
@export var bench_color: Color = Color(0.32, 0.36, 0.42, 1.0)
@export var preset_spacing: float = 1.1
@export var rotation_speed: float = 0.25
## The operand pair every preset shares. Both were literals inside _build_presets.
@export var box_size: Vector3 = Vector3(0.45, 0.45, 0.45)
@export var sphere_radius: float = 0.3
## The shipped placement of B. A map token that names this directly still WINS over
## strike — the named axis is a vocabulary laid over the raw vector, never a
## replacement for it.
@export var preset_offset: Vector3 = Vector3(0.2, 0.1, 0.1)

const UNION_COLOR: Color = Color(0.55, 0.85, 1.0, 1.0)
const INTER_COLOR: Color = Color(1.0, 0.55, 0.4, 1.0)
const DIFF_COLOR: Color = Color(0.7, 0.6, 0.95, 1.0)
const REVERSE_COLOR: Color = Color(0.55, 0.95, 0.6, 1.0)
const XOR_COLOR: Color = Color(1.0, 0.8, 0.35, 1.0)

var _preset_roots: Array = []
var _t: float = 0.0
var _built: bool = false
var _offset_explicit: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build_all()


## Guarded. The old body assigned preset_spacing and had no rebuild behind it — a
## knob that worked only because config always arrives before _ready. It now
## rebuilds when, and only when, a value the build actually reads has changed. All
## seven placements pass no config keys at all, so none of them is touched.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _config_signature() == before:
		return
	for c in get_children():
		c.queue_free()
	_preset_roots.clear()
	_built = false
	_build_all()


func _config_signature() -> String:
	return "%s|%s|%.4f|%.4f|%s|%s|%s" % [
		algebra, strike, preset_spacing, sphere_radius,
		str(box_size), str(_cut_offset()), str(bench_color)]


func _read_metadata_overrides() -> void:
	if has_meta("config_algebra"):
		var a: String = str(get_meta("config_algebra")).strip_edges().to_lower()
		if ALGEBRAS.has(a):
			algebra = a
	if has_meta("config_strike"):
		var s: String = str(get_meta("config_strike")).strip_edges().to_lower()
		if STRIKES.has(s):
			strike = s
	if has_meta("config_preset_spacing"):
		preset_spacing = float(str(get_meta("config_preset_spacing")))
	if has_meta("config_rotation_speed"):
		rotation_speed = float(str(get_meta("config_rotation_speed")))
	if has_meta("config_sphere_radius"):
		sphere_radius = float(str(get_meta("config_sphere_radius")))
	if has_meta("config_preset_offset"):
		var o = get_meta("config_preset_offset")
		if o is Vector3:
			preset_offset = o
		else:
			var parts: PackedStringArray = str(o).split(",")
			if parts.size() >= 3:
				preset_offset = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
		_offset_explicit = true
	if has_meta("config_bench_color"):
		var c = get_meta("config_bench_color")
		if c is Color:
			bench_color = c
		else:
			bench_color = _parse_color(str(c), bench_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts: PackedStringArray = raw.split(",")
	if parts.size() >= 3:
		var a: float = 1.0
		if parts.size() > 3:
			a = float(parts[3])
		return Color(float(parts[0]), float(parts[1]), float(parts[2]), a)
	return fallback


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	for r in _preset_roots:
		if is_instance_valid(r):
			r.rotation.y = _t


# ── The shared placement of B ─────────────────────────────────────────

## strike resolved to the vector the bench has always used. "corner" returns
## preset_offset UNTOUCHED rather than recomputing a fraction of box_size: at the
## shipped box_size the two are identical anyway, but a placement that overrode
## box_size alone would silently have its offset rescaled by the ratio path, and
## the guarantee should not depend on nobody doing that.
func _cut_offset() -> Vector3:
	if _offset_explicit or strike == "corner" or not STRIKES.has(strike):
		return preset_offset
	return _strike_fraction(strike) * box_size


## Fractions of box_size, so B tracks the solid it engages. The same fractions
## fontana_puncture and csg_difference_demo use, against this bench's own box.
func _strike_fraction(which: String) -> Vector3:
	match which:
		"raised":
			return Vector3(0.0, 0.30, 0.0)
		"grazing":
			return Vector3(0.0, 0.48, 0.0)
		_:
			return Vector3.ZERO


# ── Build ─────────────────────────────────────────────────────────────

func _build_all() -> void:
	_built = true
	var presets: Array = _recipe(algebra)
	_build_bench(presets.size())
	_build_presets(presets)
	_build_overall_label()


## The bench's operator set. `triad` returns exactly the three literals
## _build_presets used to hold, in the same order, with the same colours and the
## same labels.
func _recipe(which: String) -> Array:
	var u: Dictionary = {"kind": "union", "color": UNION_COLOR, "label": "A ∪ B"}
	var n: Dictionary = {"kind": "intersection", "color": INTER_COLOR, "label": "A ∩ B"}
	var d: Dictionary = {"kind": "difference", "color": DIFF_COLOR, "label": "A − B"}
	var r: Dictionary = {"kind": "reverse", "color": REVERSE_COLOR, "label": "B − A"}
	# Written out rather than as ⊕ on purpose: the label IS the argument that XOR
	# is derived from the other operators and is not a primitive of its own. It
	# also keeps every glyph on the bench to the three the artifact already ships.
	var x: Dictionary = {"kind": "xor", "color": XOR_COLOR, "label": "(A ∪ B) − (A ∩ B)"}
	match which:
		"ordered":
			return [u, n, d, r]
		"complete":
			return [u, n, d, r, x]
		"atoms":
			return [d, n, r]
		_:
			return [u, n, d]


func _build_bench(count: int) -> void:
	var bench := MeshInstance3D.new()
	bench.name = "Bench"
	var box := BoxMesh.new()
	# count = 3 gives preset_spacing * 3.2 — the width the bench has always had.
	box.size = Vector3(preset_spacing * (float(count) + 0.2), 0.12, 1.2)
	bench.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = bench_color
	mat.roughness = 0.7
	bench.material_override = mat
	bench.position.y = 0.5
	add_child(bench)


func _build_presets(presets: Array) -> void:
	var count: int = presets.size()
	for i in count:
		var preset: Dictionary = presets[i]
		var root: CSGCombiner3D = _make_solid(str(preset["kind"]))
		# count = 3 gives (i - 1) * preset_spacing, the shipped layout.
		var x_off: float = (float(i) - float(count - 1) * 0.5) * preset_spacing
		root.position = Vector3(x_off, 1.1, 0.0)
		var col: Color = preset["color"]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.metallic = 0.3
		mat.roughness = 0.4
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.3
		root.material_override = mat
		add_child(root)
		_preset_roots.append(root)
		# Per-preset label.
		var label := Label3D.new()
		label.text = str(preset["label"])
		label.font_size = 30
		label.outline_size = 6
		label.modulate = col
		label.position = Vector3(x_off, 0.45, 0.65)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)


## One preset. Every kind is the SAME operand pair — that is the bench's claim —
## so A and B are built from the shared box_size / sphere_radius / _cut_offset().
func _make_solid(kind: String) -> CSGCombiner3D:
	var root := CSGCombiner3D.new()
	root.name = "Preset_%s" % kind
	match kind:
		"intersection":
			root.add_child(_csg_box(CSGShape3D.OPERATION_UNION))
			root.add_child(_csg_sphere(CSGShape3D.OPERATION_INTERSECTION))
		"difference":
			root.add_child(_csg_box(CSGShape3D.OPERATION_UNION))
			root.add_child(_csg_sphere(CSGShape3D.OPERATION_SUBTRACTION))
		"reverse":
			# B − A. The non-commutative twin: the sphere keeps what the box did not.
			root.add_child(_csg_sphere(CSGShape3D.OPERATION_UNION))
			root.add_child(_csg_box(CSGShape3D.OPERATION_SUBTRACTION))
		"xor":
			# (A ∪ B) − (A ∩ B). A CSGCombiner3D nested in a combiner is a SHAPE,
			# not a container — which is exactly what is wanted here: each inner
			# combiner resolves first and then takes part with its own operation.
			var both := CSGCombiner3D.new()
			both.name = "Either"
			both.operation = CSGShape3D.OPERATION_UNION
			both.add_child(_csg_box(CSGShape3D.OPERATION_UNION))
			both.add_child(_csg_sphere(CSGShape3D.OPERATION_UNION))
			root.add_child(both)
			var shared := CSGCombiner3D.new()
			shared.name = "Shared"
			shared.operation = CSGShape3D.OPERATION_SUBTRACTION
			shared.add_child(_csg_box(CSGShape3D.OPERATION_UNION))
			shared.add_child(_csg_sphere(CSGShape3D.OPERATION_INTERSECTION))
			root.add_child(shared)
		_:
			root.add_child(_csg_box(CSGShape3D.OPERATION_UNION))
			root.add_child(_csg_sphere(CSGShape3D.OPERATION_UNION))
	return root


func _csg_box(op: int) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = box_size
	b.operation = op
	return b


func _csg_sphere(op: int) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = sphere_radius
	s.position = _cut_offset()
	s.operation = op
	return s


func _build_overall_label() -> void:
	var label := Label3D.new()
	label.text = "Compose"
	label.font_size = 42
	label.outline_size = 8
	label.modulate = Color(0.95, 0.85, 0.45, 1.0)
	label.position = Vector3(0.0, 1.95, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
