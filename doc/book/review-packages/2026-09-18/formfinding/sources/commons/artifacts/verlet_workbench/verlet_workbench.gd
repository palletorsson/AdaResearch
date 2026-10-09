extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VerletWorkbench

## @identity
## name: "Verlet & the soft-body sim"
## tier: applied
## lineage: Loup Verlet (1967) — integrate position straight from position; velocity is implied
##   by where you just were. Constraints are not solved, only nudged, pass after pass.
## essence: A workbench running the actual integrator. A cloth hangs and relaxes; a dial sets
##   the number of constraint passes per frame and a readout reports it. Crank the passes up
##   and the cloth stiffens; drop them and it sags — yet no linear system is ever solved.
##   The springs hold because we keep correcting, never because we computed an answer.
## truth: "INTEGRATE POSITION FROM POSITION — THE CONSTRAINTS HOLD WITHOUT BEING SOLVED"
## applications: every game cloth, rope, and ragdoll — Verlet is the cheap, stable workhorse.

## --- DNA (stage 2, promoted 2026-08-12) --------------------------------------------------
## AXIS `relaxation` — HOW INSISTENTLY IS A DISTANCE CONSTRAINT ENFORCED.
##
## This artifact already WAS this axis; what it lacked was a word. The dial and the readout
## were built on day one (see _build), `constraint_passes` was already a clamped config key,
## and @identity states the claim outright: "crank the passes up and the cloth stiffens; drop
## them and it sags — yet no linear system is ever solved." The word exists because
## apply_dna_block refuses a numeric axis by design — sample points on a continuum are a
## design choice, not a fact about the code — so the choice is named here and derived there:
##
##   nudged = 1     worked = 4 (the shipped literal)     pressed = 8     held = 12
##
## Shared with cloth_simulation in this wave, character for character: same question, same
## four values, two independent solvers. Their bite numbers should ORDER the same way.
##
## IT IS A RESTING SHAPE, NOT A RATE — and that is measured, not argued. soft_body_sim.step()
## was replicated in Python and each value run to its fixed point. The cloth's hanging height
## is 0.6406 / 0.6071 / 0.6009 / 0.5988 m for nudged / worked / pressed / held, and its mean
## SIGNED spring stretch over all 392 springs 0.701 / 0.168 / 0.080 / 0.051 % (the unsigned mean
## is about twice that throughout, so quote the sign) — a clean 1/passes law (4.17x, 2.10x, 1.57x
## against a predicted 4, 2, 1.5). Four different EQUILIBRIA, so a longer settle cannot
## collapse them into one another.
##
## ONE CORRECTION TO THE APPROVED DESIGN, which claimed a longer pre-settle would make the
## values MORE different. It makes them LESS different: nudged-vs-worked is 48.8 mm of max
## vertex displacement after the shipped 60-step pre-settle and 34.5 mm at equilibrium — a
## 29% shrink, because at 60 steps nudged is still in transient overshoot (moving 1.27 mm per
## step). The ladder, its ordering and its ratios all survive; the mechanism claimed for them
## did not, so it is written down here rather than quietly kept.
##
## PREDICTED CLOSEST PAIR: pressed vs held. Measured 2.154 mm max / 1.792 mm mean vertex
## displacement, against nudged-vs-worked's 34.458 / 28.736 — a ratio of 16.0:1, where the
## residual-stretch arithmetic predicted 18:1. At dna.framing 0.65 the frame is ~2.5 m wide
## over 760 px, so pressed-vs-held is about 0.7 px and WILL read faint; nudged-vs-worked is
## about 10 px across a cloth holding ~8% of frame.
##
## DECLINED. `damping` (0.99): four values, one drape, reached at different speeds — the
## purest rate axis in the sequence and invisible to a still by construction. The gust
## amplitudes (0.6 lateral on line ~247, 0.3 in Z) move the cloth more than the axis does and
## are still wrong, because they are a DRIVE — `sin(_t * 0.8)` never stops, so photographing
## them is photographing the clock; the fixture's whole job is to switch them off. Cloth
## resolution (cloth_cols / cloth_rows / cell) is a real and interesting claim — the
## discretization IS the material — but `grain` is already the corpus's word for how a body
## is subdivided, across six artifacts with a different value set, and a seventh synonym
## serving ONE placement is worse than one axis that is exactly right. The pin mode
## (`top_corners`, six values already in soft_body_shapes._cloth_is_pin) is flagdancer's
## `heading` in this same wave.
##
## DETERMINISM: see `still` and `settle_steps` below. As shipped this artifact could not be
## measured at all; with the fixture two runs of a value are the same picture.
## -----------------------------------------------------------------------------------------

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

## The axis. Sets how many constraint-relaxation passes the solver runs per step — which is
## the number the dial has always turned and the readout has always printed.
@export_enum("nudged", "worked", "pressed", "held") var relaxation: String = "worked"

## The word's arithmetic, kept next to it so apply_dna_block reads the values off the export
## and this table can never drift from them silently.
const RELAXATION_PASSES := {
	"nudged": 1,
	"worked": 4,
	"pressed": 8,
	"held": 12,
}

@export var cloth_cols: int = 10
@export var cloth_rows: int = 8
@export var cell: float = 0.085
@export var constraint_passes: int = 4
@export var stiffness: float = 0.75
@export var cloth_col: Color = Color(0.85, 0.40, 0.78)
@export var panel_col: Color = Color(0.10, 0.11, 0.14)
@export var readout_col: Color = Color(0.55, 0.95, 0.70)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

## --- capture fixture: both are exact no-ops at their defaults ------------------------------
## `still` zeroes the four things this bench drives off the wall clock — the lateral gust
## (0.6), the Z gust (0.3), the bench sway (0.06) and the dial spin (0.6) — so gravity stays
## the constant (0, -3, 0) the pre-settle already used and the two rotating nodes hold 0. At
## 1.45 s the gust alone is sin(1.16) * 0.6 = +0.55 against -3.0 vertical: a 10.4-degree tilt
## that swings the free bottom edge roughly 108 mm, three times the whole axis's separation.
@export var still: bool = false
## `settle_steps` is the literal count the pre-settle loop has always run. Raised by the
## fixture to 420 so every value reaches ITS OWN fixed point before frame 1. Measured: at 420
## the pose is 0.05 mm from the 2400-step pose for nudged and bit-identical for the other
## three, and 132 further rendered frames move nudged by at most 0.066 mm — 3% of the closest
## pair's separation. At the shipped 60, the same 66-vs-87 frame difference moves nudged by
## up to 21 mm, ten times that separation. The frame clock is why this export exists.
@export var settle_steps: int = 60

var _t: float = 0.0
var _sway: Node3D = null
var _sim = null
var _cloth_mi: MeshInstance3D = null
var _cloth_mat: StandardMaterial3D = null
var _readout: Label3D = null
var _dial: Node3D = null

## Only the nodes THIS script added to itself. The old teardown freed every child, including
## anything the grid had attached (highlights, colliders, the pickup plumbing).
var _owned: Array[Node] = []
## Signature of every value _build reads, so a config that changes nothing rebuilds nothing.
var _sig: String = ""
## True once a config has handed us an explicit numeric pass count. The pre-existing numeric
## contract then wins over the word — it is strictly more expressive, and it is what any map
## written before this promotion would carry.
var _passes_pinned: bool = false


func _ready() -> void:
	_build()
	_sig = _build_signature()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cloth_cols"):
		cloth_cols = clampi(int(config["cloth_cols"]), 4, 16)
	if config.has("cloth_rows"):
		cloth_rows = clampi(int(config["cloth_rows"]), 4, 14)
	if config.has("relaxation"):
		var word: String = str(config["relaxation"]).strip_edges().to_lower()
		if RELAXATION_PASSES.has(word):
			relaxation = word
	if config.has("constraint_passes"):
		constraint_passes = clampi(int(config["constraint_passes"]), 1, 12)
		_passes_pinned = true
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.2, 0.95)
	if config.has("cloth_col"):
		cloth_col = _parse_color(config["cloth_col"], cloth_col)
	if config.has("still"):
		still = bool(config["still"])
	if config.has("settle_steps"):
		settle_steps = clampi(int(config["settle_steps"]), 0, 4000)

	var sig: String = _build_signature()
	if sig == _sig and not _owned.is_empty():
		return
	_teardown()
	_build()
	_sig = sig


## Every value _build reads, in one string. Two configs with the same signature build the
## same bench, so the second one is not built at all.
func _build_signature() -> String:
	return "%s|%d|%d|%d|%.6f|%d|%.6f|%s|%s|%s|%s|%d|%d" % [
		relaxation, _effective_passes(), cloth_cols, cloth_rows, cell,
		int(emissive), stiffness,
		cloth_col.to_html(true), panel_col.to_html(true),
		readout_col.to_html(true), label_col.to_html(true),
		int(still), settle_steps,
	]


## The pass count the solver actually runs. At the shipped default this returns the literal 4
## that `@export var constraint_passes: int = 4` has always declared.
func _effective_passes() -> int:
	if _passes_pinned:
		return clampi(constraint_passes, 1, 12)
	if RELAXATION_PASSES.has(relaxation):
		return int(RELAXATION_PASSES[relaxation])
	return clampi(constraint_passes, 1, 12)


func _teardown() -> void:
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_sway = null
	_sim = null
	_cloth_mi = null
	_cloth_mat = null
	_readout = null
	_dial = null


## add_child + remember it, so _teardown frees only what this script made.
func _own(n: Node) -> Node:
	add_child(n)
	_owned.append(n)
	return n


func _make_sim() -> void:
	# A cloth pinned at its two TOP CORNERS only — "top_corners" pins (r == 0 and c in {0, cols-1}),
	# two particles, not the whole top row. The deep catenary between them is the drape the axis
	# reshapes. Hung in front of the bench (XY plane, +Z out).
	var sim = SBShapes.make_cloth(cloth_cols, cloth_rows, cell, "top_corners", stiffness)
	sim.constraint_passes = _effective_passes()
	sim.gravity = Vector3(0.0, -3.0, 0.0)
	sim.damping = 0.99
	sim.floor_y = -10.0
	_sim = sim
	# Pre-settle so the very first frame shows a relaxed drape, not a flat sheet. Synchronous,
	# fixed dt (soft_body_sim.step defaults to 1/60 and nobody passes another), so the pose
	# here is a function of settle_steps and the pass count alone — not of the frame rate.
	for _i in settle_steps:
		_sim.step()


func _rebuild_cloth_mesh() -> ArrayMesh:
	# Build the cloth surface from the current particle positions.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in _sim.positions.size():
		verts.append(_sim.positions[i])
		normals.append(Vector3.UP)
	for r in cloth_rows - 1:
		for c in cloth_cols - 1:
			var i0: int = r * cloth_cols + c
			var i1: int = r * cloth_cols + c + 1
			var i2: int = (r + 1) * cloth_cols + c + 1
			var i3: int = (r + 1) * cloth_cols + c
			indices.append_array([i0, i1, i2, i0, i2, i3])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


func _build() -> void:
	# Bench
	_own(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.2, 0.2, 0.7), _matte_mat(Color(0.16, 0.17, 0.20), 0.85)))
	_own(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.5, _steel_mat(Color(0.34, 0.36, 0.40))))
	# A frame the cloth hangs from
	_own(_box(Vector3(0.0, 1.32, -0.05), Vector3(cloth_cols * cell + 0.12, 0.04, 0.06), _matte_mat(Color(0.30, 0.32, 0.36), 0.6)))
	_own(_cylinder_between(Vector3(-(cloth_cols * cell) * 0.5, 0.86, -0.05), Vector3(-(cloth_cols * cell) * 0.5, 1.32, -0.05), 0.02, _matte_mat(Color(0.30, 0.32, 0.36), 0.6)))
	_own(_cylinder_between(Vector3((cloth_cols * cell) * 0.5, 0.86, -0.05), Vector3((cloth_cols * cell) * 0.5, 1.32, -0.05), 0.02, _matte_mat(Color(0.30, 0.32, 0.36), 0.6)))

	var sway := Node3D.new()
	sway.name = "ClothSway"
	_own(sway)
	_sway = sway

	_make_sim()
	# Cloth sits at the top of the frame, draping forward and down.
	var cloth_holder := Node3D.new()
	cloth_holder.position = Vector3(0.0, 1.3, 0.06)
	sway.add_child(cloth_holder)

	_cloth_mat = StandardMaterial3D.new()
	_cloth_mat.albedo_color = cloth_col
	_cloth_mat.roughness = 0.5
	_cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cloth_mat.emission_enabled = true
	_cloth_mat.emission = cloth_col
	_cloth_mat.emission_energy_multiplier = 0.35 if emissive else 0.0

	_cloth_mi = MeshInstance3D.new()
	_cloth_mi.mesh = _rebuild_cloth_mesh()
	_cloth_mi.material_override = _cloth_mat
	cloth_holder.add_child(_cloth_mi)

	# Constraint-pass dial + readout panel (the applied control surface)
	var dial := Node3D.new()
	dial.position = Vector3(0.62, 0.95, 0.28)
	_own(dial)
	_dial = dial
	dial.add_child(_cylinder(Vector3.ZERO, 0.07, 0.04, _steel_mat(Color(0.4, 0.42, 0.46))))
	# A pointer notch on the dial so its rotation is legible.
	dial.add_child(_box(Vector3(0.0, 0.03, 0.045), Vector3(0.012, 0.012, 0.05), _glow_mat(readout_col, 1.6)))

	_own(_box(Vector3(0.55, 1.18, 0.25), Vector3(0.34, 0.18, 0.02), _matte_mat(panel_col, 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.55, 1.18, 0.27), 16, readout_col)
	_own(_readout)

	_own(_billboard_label("INTEGRATE POSITION FROM POSITION", Vector3(0.0, 1.62, 0.0), 22, label_col))


func _readout_text() -> String:
	return "VERLET\npasses: %d\nstiffness: %.2f\n(constraints held, never solved)" % [_sim.constraint_passes, stiffness]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Live cloth: re-run the integrator and rebuild only the surface positions.
	if _sim != null:
		if still:
			# Pose pinned. Constant gravity — the same vector _make_sim pre-settled under —
			# so the cloth holds the drape ITS pass count converged to and a further step is
			# a no-op. Two captures of one value are the same picture.
			_sim.gravity = Vector3(0.0, -3.0, 0.0)
		else:
			# A faint breeze so the drape keeps moving (and the relaxation stays visible).
			var gust: float = sin(_t * 0.8) * 0.6
			_sim.gravity = Vector3(gust, -3.0, 0.3 * sin(_t * 0.5))
		_sim.step()
		if _cloth_mi != null:
			_cloth_mi.mesh = _rebuild_cloth_mesh()
	if _dial != null:
		_dial.rotation.y = 0.0 if still else sin(_t * 0.3) * 0.6
	if _sway != null:
		_sway.rotation.y = 0.0 if still else sin(_t * 0.25) * 0.06
