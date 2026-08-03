# ===========================================================================
# NOC Example 2.3: Gravity Scaled by Mass
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
#
# @identity
# essence: Gravity computed as a force scaled by each body's mass, revealing that all masses fall at the same acceleration
# desire: To enact Galileo's experiment — drop different masses, watch them stay together, see why F=mg cancels in the equation of motion
# critical_parameter: gravity_strength — the constant that proves itself constant by producing equal acceleration regardless of mass
# triggers: Default gravity reproduces Galileo's result; reducing gravity slows the fall but masses still descend together; reversing gravity inverts the demonstration
# emerges: The equivalence principle as visible event — heavy and light reach the floor together, the algebra confirmed by the eye
# needs: per-body mass [has], gravity force application [has], visible arrow comparison [has], VR sliders [has]
# relationships: NOC Ch.2 trilogy with example_2_1 and example_2_2. Anchor artifact in forces/Newton's_Laws map
# truth: Gravity treats mass as both source and target — and so cancels itself in motion, leaving acceleration alone to fall.
# ===========================================================================

extends Node3D

const DEFAULT_GRAVITY_STRENGTH := 0.9
const ARROW_LENGTH_SCALE := 0.8
const MIN_ARROW_LENGTH := 0.05
const MAX_ARROW_LENGTH := 1.0

## STAGE-2 DNA PROMOTION (2026-08-03).
##
## The slider turns the LAW (gravity). Nothing turned the DEMONSTRATION. Two things were
## hard-coded and both of them carry the whole argument:
##
##   mass_spread  the bodies dropped        ladder · uniform · extreme
##   evidence     what is offered as proof  result · trace · longhand · axiom
##
## `evidence` takes the value list the forces family already uses — koch_curve,
## fibonacci_sequences, sine_wave_controller, wave_interference_tank and
## example_2_8_two_body_attraction_vr all ask this same question in these same four words —
## rather than inventing a synonym for it. `mass_spread` takes example_2_5's list for the
## same reason: when a shared vocabulary is honest the siblings measure alike.
##
## This example argues the equivalence principle: F = mg cancels in F = ma, so every mass
## falls at the same acceleration. The shipped build draws the WEIGHT — the one quantity
## that does NOT cancel, whose arrow is three times longer on the heavy body than the light
## one. That is a real choice about what to show and it was never turnable.
##
##   result    the shipped build exactly: one orange weight arrow per body, its length
##             proportional to m·g. The forces, which differ.
##   trace     the arrows go and the FALL ITSELF is drawn — three dotted columns from each
##             release point to the floor, rungs across them at equal heights. Galileo's
##             claim laid down before the drop rather than watched during it.
##   longhand  the working instead of the answer. Each body keeps its weight arrow AND
##             gains a second arrow of IDENTICAL length beside it: the acceleration, after
##             the division. A flat ring under each body carries its mass as area. The
##             cancellation is on the geometry — one arrow scales, the other does not.
##   axiom     the instance gives way to the rule. No arrows; a slate behind the bodies
##             carries F = m g and a = F/m = g, the statement these three happen to be an
##             example of.
##
## mass_spread=ladder, evidence=result is the pre-promotion behaviour EXACTLY — same three
## masses at the same three release points, same orange weight arrows, nothing added — and
## it is the default, so the 5 existing placements are unchanged.
##
## Usage in map_data.json:
##   "example_2_3_gravity_scaled_by_mass_vr#evidence:longhand"
##   "example_2_3_gravity_scaled_by_mass_vr#mass_spread:extreme#evidence:trace"

## What this demo offers as proof that gravity is there. See the note above.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"
## The bodies dropped. ladder = 0.5/1.5/3.0, the shipped ramp; uniform = three identical
## bodies, the trivial case against which the ladder means something; extreme = 0.2 and 6.0
## with a middle, a thirtyfold mass ratio — the feather and the hammer.
@export_enum("ladder", "uniform", "extreme") var mass_spread: String = "ladder"
## SEED for the body colours, which spawn_movers() has always drawn from an unseeded
## rng.randomize(). -1 keeps that exactly: new colours every launch. Any other value fixes
## them, which is what a sweep needs if it is to measure an axis and not the paintwork.
@export var color_seed: int = -1

## Allow-lists. An unknown word in a map token falls back to the shipped lineage rather
## than stranding a placement with a blank exhibit.
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]
const SPREADS: PackedStringArray = ["ladder", "uniform", "extreme"]

# The three populations. SAME THREE RELEASE POINTS in every case, so the only thing that
# differs between them is what the bodies weigh — which is the point of having a control.
const MASS_LADDER: Array = [0.5, 1.5, 3.0]
const MASS_UNIFORM: Array = [1.5, 1.5, 1.5]
const MASS_EXTREME: Array = [0.2, 1.0, 6.0]
const SPAWN_X: Array = [-0.25, 0.0, 0.25]
const SPAWN_Y := 0.35
const FLOOR_Y := -0.5

const TRACE_INK := Color(0.72, 0.86, 0.98)
const ACC_INK := Color(0.35, 0.86, 0.85)
const MASS_RING := Color(0.85, 0.80, 0.55)
const SLATE := Color(0.12, 0.13, 0.16)
const CHALK := Color(0.93, 0.93, 0.88)

## Nodes built by trace / longhand / axiom. Freed before any restage; empty on the shipped
## path, where not one of them is ever constructed.
var _evidence_parts: Array[Node3D] = []
var _built: bool = false

var movers: Array[Mover] = []
var mover_labels: Dictionary = {}
var force_visuals: Dictionary = {}
var mover_initial_positions: Dictionary = {}

var gravity_strength: float = DEFAULT_GRAVITY_STRENGTH
var show_force_vectors: bool = true

# UI — Ada rack panel
var _panel: ForcesRackPanel
var _gravity_slider: Node3D
var auto_reset_timer: Timer

func _ready() -> void:
	_read_grid_config_meta()

	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_create_panel()
	spawn_movers()
	setup_auto_reset()
	_built = true
	print("Example 2.3: Gravity scaled by mass")

func setup_auto_reset() -> void:
	auto_reset_timer = Timer.new()
	auto_reset_timer.wait_time = 20.0
	auto_reset_timer.autostart = true
	auto_reset_timer.timeout.connect(reset_scene)
	add_child(auto_reset_timer)

func _process(_delta: float) -> void:
	pass  # Slider labels auto-update

func _physics_process(_delta: float) -> void:
	for mover in movers:
		if not is_instance_valid(mover):
			continue

		var gravity_force: Vector3 = Vector3(0, -gravity_strength * mover.mass, 0)
		mover.apply_force(gravity_force)
		update_force_visual(mover, gravity_force)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_scene()
			KEY_F:
				toggle_force_vectors()

func _create_panel() -> void:
	_panel = ForcesRackPanel.new()
	_panel.setup("2.3  Gravity Scaled by Mass", 1, 3)
	_panel.set_instructions("[F] Weight arrows  [R] Reset")

	_gravity_slider = _panel.add_slider("Gravity", 0.1, 2.5, gravity_strength, 0.05)
	_gravity_slider.slider_moved.connect(_on_gravity_slider_moved)

	# Position panel to the left, at chest height, angled toward viewer
	_panel.position = Vector3(-0.45, 0.35, 0.15)
	_panel.rotation_degrees = Vector3(0, 25, 0)
	add_child(_panel)

func spawn_movers() -> void:
	clear_existing_movers()

	var configs: Array = _mover_configs()

	var rng := RandomNumberGenerator.new()
	if color_seed < 0:
		rng.randomize()
	else:
		rng.seed = color_seed

	for config in configs:
		var mover := Mover.new()
		mover.mass = float(config["mass"])
		mover.position_v = config["position"]
		mover.velocity = Vector3.ZERO
		mover.acceleration = Vector3.ZERO
		mover.bounce_damping = 0.6
		add_child(mover)
		mover.set_size(0.03 + mover.mass * 0.01)

		var random_color := Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.4, 0.7),
			rng.randf_range(0.8, 1.0)
		)
		mover.set_color(random_color)

		movers.append(mover)
		mover_initial_positions[mover] = config["position"]

		var arrow := create_force_arrow()
		mover.add_child(arrow)
		force_visuals[mover] = arrow

	# The exhibit hangs off the bodies, so it is raised after they exist and again after
	# any respawn. On the shipped path this builds nothing at all.
	_apply_evidence()

func clear_existing_movers() -> void:
	for mover in movers:
		if is_instance_valid(mover):
			mover.queue_free()
	movers.clear()
	mover_labels.clear()
	force_visuals.clear()
	mover_initial_positions.clear()


func create_force_arrow() -> Node3D:
	var arrow_root := Node3D.new()
	arrow_root.name = "WeightArrow"
	arrow_root.visible = show_force_vectors

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = 1.0
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, -0.5)
	shaft.rotation_degrees = Vector3(90, 0, 0)
	shaft.material_override = _create_gravity_arrow_material()
	arrow_root.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh: CylinderMesh = CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.02
	head_mesh.height = 0.08
	head.mesh = head_mesh
	head.position = Vector3(0, 0, -1.0)
	head.rotation_degrees = Vector3(90, 0, 0)
	head.material_override = _create_gravity_arrow_material()
	arrow_root.add_child(head)

	return arrow_root

func _create_gravity_arrow_material() -> StandardMaterial3D:
	# Use Ada accent_orange for gravity arrows
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.45, 0.15, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.45, 0.15)
	mat.emission_energy_multiplier = 0.4
	return mat

func update_force_visual(mover: Mover, gravity_force: Vector3) -> void:
	var arrow: Node3D = force_visuals.get(mover, null)
	if not arrow or not is_instance_valid(arrow):
		return

	var magnitude: float = gravity_force.length()
	if not show_force_vectors or magnitude < 0.01:
		arrow.visible = false
		return

	arrow.visible = true
	var length: float = clamp(magnitude * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)

	var shaft: Node = arrow.get_node("Shaft") if arrow.has_node("Shaft") else null
	var head: Node = arrow.get_node("Head") if arrow.has_node("Head") else null

	if shaft and shaft is MeshInstance3D:
		shaft.scale = Vector3(1, 1, length)
		shaft.position = Vector3(0, 0, length * 0.5)

	if head and head is MeshInstance3D:
		head.position = Vector3(0, 0, length)
		head.scale = Vector3(1, 1, clamp(length * 0.4, 0.3, 0.9))

	var basis := Basis().looking_at(Vector3.DOWN, Vector3.FORWARD)
	arrow.transform = Transform3D(basis, Vector3.ZERO)

func reset_scene() -> void:
	gravity_strength = DEFAULT_GRAVITY_STRENGTH
	if _panel:
		_panel.set_slider_value(0, gravity_strength)
	restore_initial_positions()

func restore_initial_positions() -> void:
	for mover in movers:
		if not is_instance_valid(mover):
			continue
		var start: Vector3 = mover_initial_positions.get(mover, mover.position_v)
		mover.position_v = start
		mover.velocity = Vector3.ZERO
		mover.acceleration = Vector3.ZERO

func toggle_force_vectors() -> void:
	show_force_vectors = !show_force_vectors
	for arrow in force_visuals.values():
		if is_instance_valid(arrow):
			arrow.visible = show_force_vectors

func _on_gravity_slider_moved(_position) -> void:
	gravity_strength = _panel.get_slider_value(0)
	for mover in movers:
		if is_instance_valid(mover):
			mover.acceleration = Vector3.ZERO

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `evidence` and `mass_spread`
# EVERYTHING BELOW THIS LINE IS APPENDED. Nothing above it moved except three
# lines: the config read at the top of _ready(), the masses coming from
# _mover_configs(), and the seeded colour rng.
# ═══════════════════════════════════════════════════════════════════════════

## THE PATH THAT REACHES THIS SCRIPT FROM A MAP.
##
## This scene's root is an UNSCRIPTED Node3D — the whole NOC forces family is shaped
## root -> FishTank -> Demo, and this script sits on the grandchild. The grid calls
## apply_grid_config() on the ROOT, which has no such method, so that call never arrives
## here. What the grid DOES do unconditionally is write every #key:value token onto the
## root as `config_<key>` metadata, and it does so BEFORE the scene enters the tree
## (GridInteractablesComponent sets the metadata at line 1608 and only adds the child at
## 1220 of the following placement pass) — so it is already in place when this _ready()
## runs. Walk up and read it.
##
## The sweep harness reaches the exports directly: capture_config_sweep._holder_of()
## searches descendants for the property before setting it, so an unscripted root costs
## nothing there.
##
## Costs nothing when no token is present: the exports keep their defaults and not a
## single existing placement changes.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_evidence"):
			evidence = str(node.get_meta("config_evidence"))
		if node.has_meta("config_mass_spread"):
			mass_spread = str(node.get_meta("config_mass_spread"))
		if node.has_meta("config_color_seed"):
			color_seed = int(str(node.get_meta("config_color_seed")))
		node = node.get_parent()


## Config from map_data.json tokens: #evidence:trace · #mass_spread:extreme#color_seed:7
##
## GUARDED ON CHANGE, deliberately. A placement carrying any OTHER token arrives here with
## no key of ours at all, and the grid can reach a placement twice. An unguarded respawn
## would tear down and re-drop three bodies mid-fall for nothing.
func apply_grid_config(config: Dictionary) -> void:
	var respawn: bool = false
	var restage: bool = false

	if config.has("mass_spread"):
		var want_spread: String = str(config["mass_spread"])
		if want_spread != mass_spread:
			mass_spread = want_spread
			respawn = true
	if config.has("color_seed"):
		var want_seed: int = int(str(config["color_seed"]))
		if want_seed != color_seed:
			color_seed = want_seed
			respawn = true
	if config.has("evidence"):
		var want_evidence: String = str(config["evidence"])
		if want_evidence != evidence:
			evidence = want_evidence
			restage = true

	# Before _ready() the bodies do not exist and _ready() will do all of this itself.
	if not _built:
		return
	if respawn:
		spawn_movers()          # rebuilds the bodies AND re-raises the exhibit
	elif restage:
		_apply_evidence()


## The three bodies this placement drops. Same release points in every population.
func _mover_configs() -> Array:
	var masses: Array = _masses()
	var out: Array = []
	for i in range(min(masses.size(), SPAWN_X.size())):
		out.append({
			"mass": float(masses[i]),
			"position": Vector3(float(SPAWN_X[i]), SPAWN_Y, 0.0),
		})
	return out


func _masses() -> Array:
	var want: String = String(mass_spread).strip_edges().to_lower()
	if not SPREADS.has(want):
		want = "ladder"                     # an unknown word keeps the shipped ramp
	mass_spread = want
	match mass_spread:
		"uniform":
			return MASS_UNIFORM
		"extreme":
			return MASS_EXTREME
		_:
			return MASS_LADDER


# ── The exhibits ──────────────────────────────────────────────────────────

func _apply_evidence() -> void:
	var want: String = String(evidence).strip_edges().to_lower()
	if not EVIDENCES.has(want):
		want = "result"                     # an unknown word keeps the shipped arrows
	evidence = want

	for part in _evidence_parts:
		if is_instance_valid(part):
			part.queue_free()
	_evidence_parts.clear()

	# result keeps the weight arrows; longhand sets a second arrow BESIDE them, so it
	# needs them too. trace and axiom put the answer away and show something else.
	var wants_arrows: bool = (want == "result" or want == "longhand")
	show_force_vectors = wants_arrows
	for arrow in force_visuals.values():
		if is_instance_valid(arrow):
			arrow.visible = wants_arrows

	match want:
		"trace":
			_build_trace()
		"longhand":
			_build_longhand()
		"axiom":
			_build_axiom()
		_:
			pass                            # result — the legacy lineage, nothing added


## TRACE — the fall drawn instead of watched. Three dotted columns, one from each release
## point down to the tank floor, and rungs across them at equal heights. The rungs are the
## claim: at every moment of the descent the three bodies are on the same line, whatever
## they weigh. Drawn before the drop, because for this system the outcome is not in doubt.
func _build_trace() -> void:
	var root := Node3D.new()
	root.name = "Evidence_trace"
	add_child(root)
	_evidence_parts.append(root)

	# One material and one mesh resource for the whole column, shared by every dot: 66
	# StandardMaterial3Ds for a dotted line would be a real cost for no visible difference.
	var ink: StandardMaterial3D = _flat_material(TRACE_INK)
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.006
	dot_mesh.height = 0.012
	dot_mesh.radial_segments = 6
	dot_mesh.rings = 3
	var rung_mesh := BoxMesh.new()
	rung_mesh.size = Vector3(float(SPAWN_X[SPAWN_X.size() - 1]) - float(SPAWN_X[0]), 0.003, 0.003)

	var step: float = 0.04
	var y: float = SPAWN_Y
	var rung: int = 0
	while y > FLOOR_Y:
		for sx in SPAWN_X:
			var dot := MeshInstance3D.new()
			dot.mesh = dot_mesh
			dot.material_override = ink
			dot.position = Vector3(float(sx), y, 0.0)
			root.add_child(dot)
		if rung % 3 == 0:
			var bar := MeshInstance3D.new()
			bar.mesh = rung_mesh
			bar.material_override = ink
			bar.position = Vector3(0.0, y, 0.0)
			root.add_child(bar)
		rung += 1
		y -= step


## LONGHAND — the working instead of the answer. Each body keeps its weight arrow, whose
## length is m·g and therefore differs, and gains a second arrow of the SAME length on every
## body: the acceleration, after the division by m. The flat ring under each body carries
## its mass as area. Three quantities on the geometry, and the cancellation between them
## visible without running the sum.
func _build_longhand() -> void:
	var acc_length: float = clamp(gravity_strength * ARROW_LENGTH_SCALE, MIN_ARROW_LENGTH, MAX_ARROW_LENGTH)
	for mover in movers:
		if not is_instance_valid(mover):
			continue

		var ring := MeshInstance3D.new()
		ring.name = "MassRing"
		var torus := TorusMesh.new()
		var outer: float = 0.03 + sqrt(float(mover.mass)) * 0.028
		torus.outer_radius = outer
		torus.inner_radius = maxf(0.004, outer - 0.007)
		ring.mesh = torus
		ring.material_override = _flat_material(MASS_RING)
		ring.position = Vector3(0.0, -0.06, 0.0)
		mover.add_child(ring)
		_evidence_parts.append(ring)

		var acc: Node3D = _fixed_arrow(ACC_INK, acc_length)
		acc.position = Vector3(0.055, 0.0, 0.0)
		mover.add_child(acc)
		_evidence_parts.append(acc)


## AXIOM — the instance gives way to the rule. No arrows and no bodies to compare: a slate
## behind the drop carrying the two lines that make the comparison unnecessary.
func _build_axiom() -> void:
	var root := Node3D.new()
	root.name = "Evidence_axiom"
	add_child(root)
	_evidence_parts.append(root)

	var plate := MeshInstance3D.new()
	plate.name = "Slate"
	var box := BoxMesh.new()
	box.size = Vector3(0.74, 0.34, 0.012)
	plate.mesh = box
	plate.material_override = _matte_material(SLATE)
	plate.position = Vector3(0.0, 0.16, -0.4)
	root.add_child(plate)

	# ASCII only. A glyph the fallback font has no page for renders as a tofu box, which is
	# worse evidence than a plain letter.
	var law := Label3D.new()
	law.name = "Law"
	law.text = "F = m g\na = F / m = g"
	law.font_size = 44
	law.pixel_size = 0.0016
	law.modulate = CHALK
	law.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	law.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	law.position = Vector3(0.0, 0.16, -0.392)
	root.add_child(law)


## An arrow of FIXED length pointing down the world's y. Deliberately not built through
## create_force_arrow(): that one is driven per frame by update_force_visual() from the
## force magnitude, and the whole point of this one is that it does not move when the mass
## does. Cylinders are Y-axis in Godot, so the cone is flipped 180 about X to point down.
func _fixed_arrow(tint: Color, length: float) -> Node3D:
	var root := Node3D.new()
	root.name = "AccelerationArrow"
	var mat: StandardMaterial3D = _flat_material(tint)

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.005
	shaft_mesh.bottom_radius = 0.005
	shaft_mesh.height = length
	shaft.mesh = shaft_mesh
	shaft.material_override = mat
	shaft.position = Vector3(0.0, -length * 0.5, 0.0)
	root.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.018
	head_mesh.height = 0.05
	head.mesh = head_mesh
	head.material_override = mat
	head.position = Vector3(0.0, -length - 0.025, 0.0)
	head.rotation_degrees = Vector3(180.0, 0.0, 0.0)
	root.add_child(head)

	return root


func _flat_material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.8
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 0.35
	return mat


func _matte_material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.9
	mat.metallic = 0.0
	return mat
