extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GodelSentenceMachine

## @identity
## name: Godel Sentence Machine
## lineage: Godel's first incompleteness theorem, staged as a machine. The
##   sentence G says of itself "G IS NOT PROVABLE" — a fixed point of the
##   provability predicate built by the diagonal lemma.
## essence: a panel displays G with a self-reference arrow looping G back onto
##   itself. A prover arm reaches in to PROVE G, jams (flares red), retracts —
##   then the verdict resolves to a gold "TRUE — BUT UNPROVABLE". Forever:
##   attempt -> jam -> conclude.
## truth: if G were provable it would be false (it asserts its own
##   unprovability); a sound system proves no falsehoods, so G is not provable —
##   and therefore G is true. True, and out of reach of proof.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var panel_blue: Color = Color(0.40, 0.62, 0.95)
@export var jam_red: Color = Color(0.902, 0.224, 0.275)
@export var true_gold: Color = Color(1.0, 0.78, 0.30)
@export var cycle_period: float = 6.0

var _t: float = 0.0
var _arm: Node3D
var _arm_pivot: Vector3 = Vector3(0.62, 0.92, 0.0)
var _g_panel: MeshInstance3D
var _g_panel_mat: StandardMaterial3D
var _loop_mi: MeshInstance3D
var _loop_mat: StandardMaterial3D
var _verdict: Label3D
var _jam_spark: Label3D
var _spark_pos: Vector3 = Vector3(-0.30, 0.92, 0.07)


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
	_t = 0.0
	# --- chalk ring on the floor (no bench) ---
	var ring_mat := _glow_mat(wire_purple, 0.5)
	add_child(_torus(Vector3(0.0, 0.02, 0.0), 0.66, 0.012, ring_mat))

	# --- the machine panel: a standing slab the sentence is printed on ---
	var frame_mat := _steel_mat(Color(0.34, 0.36, 0.42))
	var pw: float = 0.78
	var ph: float = 0.50
	var py: float = 0.92
	# back slab (the panel face, faint glow)
	_g_panel_mat = _glow_mat(panel_blue, 0.35)
	_g_panel = _box(Vector3(0.0, py, 0.0), Vector3(pw, ph, 0.02), _g_panel_mat)
	add_child(_g_panel)
	# panel frame edges
	add_child(_box(Vector3(0.0, py + ph * 0.5, 0.0), Vector3(pw, 0.02, 0.04), frame_mat))
	add_child(_box(Vector3(0.0, py - ph * 0.5, 0.0), Vector3(pw, 0.02, 0.04), frame_mat))
	add_child(_box(Vector3(-pw * 0.5, py, 0.0), Vector3(0.02, ph, 0.04), frame_mat))
	add_child(_box(Vector3(pw * 0.5, py, 0.0), Vector3(0.02, ph, 0.04), frame_mat))
	# two legs to the floor
	add_child(_cylinder(Vector3(-pw * 0.34, py * 0.5 - 0.12, 0.0), 0.018, py - 0.24, frame_mat))
	add_child(_cylinder(Vector3(pw * 0.34, py * 0.5 - 0.12, 0.0), 0.018, py - 0.24, frame_mat))

	# --- the sentence G, printed on the panel ---
	add_child(_billboard_label("G:", Vector3(-0.30, py + 0.12, 0.05), 26, cool_white))
	add_child(_billboard_label("\"G IS NOT PROVABLE\"", Vector3(0.04, py + 0.12, 0.05), 22, cool_white))
	# the named token of G the loop arrow points at
	var g_dot_mat := _glow_mat(true_gold, 1.0)
	add_child(_sphere(Vector3(-0.30, py - 0.04, 0.06), 0.028, g_dot_mat))
	add_child(_billboard_label("this sentence", Vector3(-0.04, py - 0.06, 0.05), 13, wire_purple))

	# --- the self-reference loop: G points back at itself ---
	# A torus tilted to read as an arrow looping out of G and back onto G.
	_loop_mat = _glow_mat(wire_purple, 1.1)
	_loop_mi = _torus(Vector3(-0.30, py + 0.04, 0.16), 0.11, 0.010, _loop_mat)
	_loop_mi.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	add_child(_loop_mi)
	# little arrowhead biting back into the G dot — the self-reference closing
	add_child(_arrow(Vector3(-0.30, py + 0.13, 0.20), Vector3(-0.30, py + 0.02, 0.09), 0.010, _loop_mat))
	add_child(_billboard_label("refers to itself", Vector3(-0.30, py + 0.20, 0.16), 12, wire_purple))

	# --- the prover arm: reaches from the right edge toward G to PROVE it ---
	_arm = Node3D.new()
	add_child(_arm)
	var arm_mat := _steel_mat(Color(0.78, 0.82, 0.90))
	# upper arm segment, pivoting at _arm_pivot
	_arm.add_child(_cylinder_between(Vector3.ZERO, Vector3(-0.34, 0.0, 0.08), 0.018, arm_mat))
	# the "PROVE" clamp at the reaching end
	var clamp_mat := _glow_mat(panel_blue, 0.9)
	var clamp := Node3D.new()
	clamp.position = Vector3(-0.34, 0.0, 0.08)
	clamp.add_child(_box(Vector3(0.0, 0.04, 0.0), Vector3(0.10, 0.012, 0.05), clamp_mat))
	clamp.add_child(_box(Vector3(0.0, -0.04, 0.0), Vector3(0.10, 0.012, 0.05), clamp_mat))
	_arm.add_child(clamp)
	_arm.position = _arm_pivot
	add_child(_billboard_label("PROVE", Vector3(0.40, 1.10, 0.0), 14, panel_blue))

	# --- the jam spark (red flare when the prover seizes), hidden between attempts ---
	_jam_spark = _billboard_label("JAM", _spark_pos + Vector3(0.0, 0.10, 0.0), 26, jam_red)
	_jam_spark.modulate = Color(jam_red.r, jam_red.g, jam_red.b, 0.0)
	add_child(_jam_spark)

	# --- the verdict that finally resolves: TRUE BUT UNPROVABLE (gold) ---
	_verdict = _billboard_label("TRUE — BUT UNPROVABLE", Vector3(0.0, 1.30, 0.0), 24, true_gold)
	_verdict.modulate = Color(true_gold.r, true_gold.g, true_gold.b, 0.0)
	add_child(_verdict)

	# --- title ---
	add_child(_billboard_label("GODEL SENTENCE MACHINE", Vector3(0.0, 1.5, 0.0), 30, cool_white))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var phase: float = fmod(_t, cycle_period) / cycle_period  # 0..1

	# The cycle: attempt (reach in) -> jam (seize, red) -> conclude (gold verdict).
	# phase 0.00..0.40  attempt: arm swings in toward G
	# phase 0.40..0.55  jam: arm shudders, red spark flares
	# phase 0.55..1.00  conclude: arm retracts, gold verdict glows then fades
	var reach: float = 0.0
	var jam: float = 0.0
	var conclude: float = 0.0
	if phase < 0.40:
		reach = _smooth(phase / 0.40)
	elif phase < 0.55:
		reach = 1.0
		jam = (phase - 0.40) / 0.15
	else:
		conclude = (phase - 0.55) / 0.45
		reach = 1.0 - _smooth(conclude)

	# arm swings from parked (out) to reaching (in toward G)
	if is_instance_valid(_arm):
		var parked: float = -0.55
		var reaching: float = -1.30
		_arm.rotation.z = lerpf(parked, reaching, reach)
		# shudder while jammed
		if jam > 0.0:
			_arm.rotation.z += sin(_t * 60.0) * 0.05 * (1.0 - absf(jam * 2.0 - 1.0) * 0.0)

	# self-reference loop always spins — G chasing its own tail
	if is_instance_valid(_loop_mi):
		_loop_mi.rotation.y = _t * 1.4
	if _loop_mat != null:
		_loop_mat.emission_energy_multiplier = (0.9 + 0.4 * sin(_t * 3.0)) if emissive else 0.0

	# jam spark: red flare during the jam window
	if is_instance_valid(_jam_spark):
		var a: float = 0.0
		if jam > 0.0:
			a = sin(jam * PI)  # 0..1..0 across the jam window
		_jam_spark.modulate = Color(jam_red.r, jam_red.g, jam_red.b, a)
		_jam_spark.scale = Vector3.ONE * (1.0 + a * 0.5 + 0.1 * sin(_t * 50.0) * a)
	# panel flushes red at the jam, cools otherwise
	if _g_panel_mat != null:
		var heat: float = 0.0
		if jam > 0.0:
			heat = sin(jam * PI)
		_g_panel_mat.emission = panel_blue.lerp(jam_red, heat)
		_g_panel_mat.emission_energy_multiplier = (0.35 + heat * 0.9) if emissive else 0.0

	# verdict: gold conclusion, eased in over the conclude window, breathing
	if is_instance_valid(_verdict):
		var va: float = _smooth(clampf(conclude * 2.0, 0.0, 1.0))
		_verdict.modulate = Color(true_gold.r, true_gold.g, true_gold.b, va)
		_verdict.scale = Vector3.ONE * (1.0 + 0.06 * sin(_t * 2.5) * va)


func _smooth(x: float) -> float:
	var c: float = clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)
