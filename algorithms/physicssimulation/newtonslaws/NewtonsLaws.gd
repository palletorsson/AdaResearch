## Newton's Laws — rigid bodies under a named law
## Uses Godot's built-in RigidBody3D physics. No manual gravity or collision.
##
## @identity
## essence: Rigid bodies arranged to enact one named law at a time — no net force, one force across three masses, or two bodies exchanging an equal and opposite pair
## desire: To make Newton's three laws visible at once: inertia, F=ma, equal-and-opposite reactions arriving as visible motion
## critical_parameter: law — which of the three the apparatus is currently standing up; applied_force_strength only decides how loudly it says it
## triggers: Low force shows all three balls behaving similarly under gravity; high force separates inertial from forced behavior visibly
## emerges: Watching three balls together reveals laws as relations, not isolated rules — the third ball moves only because the others do not
## needs: RigidBody3D physics [has], force/velocity arrows [has, and the force arrows are finally drawn], grid config for force tuning [has]
## relationships: Anchor artifact for forces/Newton's_Laws map. Companion to bouncingball, friction_ramp, and the example_2_* NOC ports. Shares `law` with force_field_visualizer and distribution_sampler, and `evidence` with 38 siblings
## truth: A law is not a rule about one body — it is a constraint on what relations between bodies are allowed.
extends Node3D

## ── the law axis ──────────────────────────────────────────────────────────────────────
## WHICH OF THE THREE THE APPARATUS IS ENACTING. Family word, taken character for character
## from force_field_visualizer (gravity | point_charge | dipole | vortex) and
## distribution_sampler (uniform | gaussian | poisson | exponential): in both, `law` names
## the rule currently in force and the values are the named laws themselves. Same question
## here, and unlike those two the answers were already written on the artifact's front —
## they were just not reachable from anything.
##
## THE FINDING THAT MADE THIS AXIS NECESSARY. This artifact is called Newton's Laws and its
## @identity promised "equal-and-opposite reactions arriving as visible motion". What it
## built was three balls under three different FORCE HISTORIES — gravity only, a constant
## push, an oscillating push. That is one law, F = ma, demonstrated three times over. The
## third law needs a PAIR of bodies exchanging force, and there was no pair: every force in
## the file came from outside the scene and nothing pushed back. `reaction` builds the pair.
##   all           three bodies, three force histories — THE SHIPPED ARRANGEMENT, kept
##                 because 11 maps are standing on it and because the comparison it draws
##                 is a real one, just not the one its name claims.
##   inertia       the same three bodies and nothing applied to any of them. The first law
##                 is the one you photograph by removing something: they fall, they land,
##                 they stay, and every velocity arrow goes out.
##   acceleration  the same force on all three, so only the mass is left to explain why
##                 they end up in three different places. F = ma read off the floor as three
##                 different distances.
##   reaction      two bodies of unequal mass, driven at each other by forces of equal
##                 magnitude and opposite sign. They meet off-centre, because equal and
##                 opposite is a statement about FORCE and the masses were never equal.
##
## ── the evidence axis ─────────────────────────────────────────────────────────────────
## WHAT STANDS BESIDE THE BODIES. Family word and the canonical four-value ladder, shared
## with 22 siblings including bouncing_ball next door in this same registry file.
##   result    only the yellow velocity arrows the artifact already draws when a body is
##             moving — THE SHIPPED BUILD. Nothing is constructed.
##   trace     the applied forces drawn. A SECOND FINDING: _create_arrow has always built a
##             coloured force arrow per ball and set it invisible, and nothing in the file
##             ever turned one on. The mesh for this rung has been in the scene, unlit, the
##             whole time.
##   longhand  the arithmetic beside each body: its mass, the force on it, and the quotient.
##   axiom     the specimens' annotations withdrawn for the rule — the three laws on a
##             slate, with no arrows under them.

@export var applied_force_strength: float = 5.0
@export var oscillation_speed: float = 2.0
## Stage-2 DNA axis — which of the three laws the apparatus is standing up.
@export_enum("all", "inertia", "acceleration", "reaction") var law: String = "all"
## Stage-2 DNA axis — how much of the working stands beside the bodies.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

const LAWS: PackedStringArray = ["all", "inertia", "acceleration", "reaction"]
const EVIDENCE: PackedStringArray = ["result", "trace", "longhand", "axiom"]

var balls: Array[RigidBody3D] = []
var time: float = 0.0

# Visualization
var force_arrows: Array[MeshInstance3D] = []
var velocity_arrows: Array[MeshInstance3D] = []
var _readouts: Array[Label3D] = []
var _slate: Label3D
## Per-ball force mode, filled from the law spec. One of free / constant / oscillate /
## push_right / push_left. At `all` this is exactly ["free", "constant", "oscillate"], which
## is the shipped _physics_process written as a list instead of as three if-blocks.
var _modes: Array[String] = []

var ball_colors := [
	Color(1.0, 0.3, 0.3),  # Red — gravity only
	Color(0.3, 1.0, 0.3),  # Green — constant applied force
	Color(0.3, 0.5, 1.0),  # Blue — oscillating force
]

func _ready() -> void:
	law = _pick(law, LAWS, "all")
	evidence = _pick(evidence, EVIDENCE, "result")
	scale = Vector3(0.8, 0.8, 0.8)
	_create_balls()
	_create_containment()
	_build_evidence()

# ── the law family ────────────────────────────────────────────────────────────────────
# One spec per value. `all` returns the four literal lists _create_balls used to hold
# inline — the same three positions, the same three masses, the same 0.2 / 0.5 / 0.9
# frictions, and the same three force modes — so the shipped arrangement is not
# re-derived from anything, it is the same numbers moved four lines up.

func _law_spec() -> Dictionary:
	match law:
		"inertia":
			return {
				"positions": [Vector3(-2, 3, 0), Vector3(0, 3, 0), Vector3(2, 3, 0)],
				"masses": [1.0, 1.5, 2.0],
				"frictions": [0.2, 0.5, 0.9],
				"modes": ["free", "free", "free"],
			}
		"acceleration":
			return {
				"positions": [Vector3(-2, 3, 0), Vector3(0, 3, 0), Vector3(2, 3, 0)],
				"masses": [1.0, 1.5, 2.0],
				"frictions": [0.2, 0.2, 0.2],
				"modes": ["constant", "constant", "constant"],
			}
		"reaction":
			return {
				"positions": [Vector3(-1.6, 3, 0), Vector3(1.6, 3, 0)],
				"masses": [1.0, 2.0],
				"frictions": [0.2, 0.2],
				"modes": ["push_right", "push_left"],
			}
		_:
			return {
				"positions": [Vector3(-2, 3, 0), Vector3(0, 3, 0), Vector3(2, 3, 0)],
				"masses": [1.0, 1.5, 2.0],
				"frictions": [0.2, 0.5, 0.9],
				"modes": ["free", "constant", "oscillate"],
			}


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	if allowed.has(value):
		return value
	return fallback


func _create_balls() -> void:
	var spec: Dictionary = _law_spec()
	var positions: Array = spec["positions"]
	var masses: Array = spec["masses"]
	var frictions: Array = spec["frictions"]
	_modes = []
	for m in spec["modes"]:
		_modes.append(str(m))

	for i in range(positions.size()):
		var rb := RigidBody3D.new()
		rb.mass = float(masses[i])
		rb.name = "Ball_%d" % i

		# Collision shape
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.3
		col.shape = shape
		rb.add_child(col)

		# Visual
		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ball_colors[i]
		mat.emission_enabled = true
		mat.emission = ball_colors[i] * 0.5
		mat.emission_energy_multiplier = 1.5
		mesh_inst.material_override = mat
		rb.add_child(mesh_inst)

		# Physics material — friction comes from the law spec; at `all` it is the same
		# 0.2 / 0.5 / 0.9 ladder the three if-branches used to spell out.
		var phys_mat := PhysicsMaterial.new()
		phys_mat.bounce = 0.6
		phys_mat.friction = float(frictions[i])
		rb.physics_material_override = phys_mat

		rb.position = positions[i]
		add_child(rb)
		balls.append(rb)

		# Force arrow visualization
		var arrow := _create_arrow(ball_colors[i])
		add_child(arrow)
		force_arrows.append(arrow)

		# Velocity arrow
		var vel_arrow := _create_arrow(Color.YELLOW)
		add_child(vel_arrow)
		velocity_arrows.append(vel_arrow)

func _create_containment() -> void:
	# Floor
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(10, 0.2, 10)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)

	# Walls
	for wall_data in [
		[Vector3(5, 2, 0), Vector3(0.2, 4, 10)],
		[Vector3(-5, 2, 0), Vector3(0.2, 4, 10)],
		[Vector3(0, 2, 5), Vector3(10, 4, 0.2)],
		[Vector3(0, 2, -5), Vector3(10, 4, 0.2)],
	]:
		var wall := StaticBody3D.new()
		var wcol := CollisionShape3D.new()
		var wshape := BoxShape3D.new()
		wshape.size = wall_data[1]
		wcol.shape = wshape
		wall.add_child(wcol)
		wall.position = wall_data[0]
		add_child(wall)

func _physics_process(delta: float) -> void:
	time += delta

	for i in range(balls.size()):
		if i >= _modes.size():
			continue
		var mode: String = _modes[i]
		if mode == "constant":
			balls[i].apply_central_force(Vector3(applied_force_strength, 0, 0))
		elif mode == "oscillate":
			var osc_force := Vector3(
				sin(time * oscillation_speed) * applied_force_strength * 1.5,
				0,
				cos(time * oscillation_speed * 0.75) * applied_force_strength
			)
			balls[i].apply_central_force(osc_force)
		elif mode == "push_right":
			balls[i].apply_central_force(Vector3(applied_force_strength, 0, 0))
		elif mode == "push_left":
			balls[i].apply_central_force(Vector3(-applied_force_strength, 0, 0))

	_update_arrows()

## The force a body is under right now, in newtons. Used both to drive the arrows and to
## print the arithmetic, so the picture and the numbers cannot disagree.
func _force_on(i: int) -> Vector3:
	if i >= _modes.size():
		return Vector3.ZERO
	var mode: String = _modes[i]
	if mode == "constant" or mode == "push_right":
		return Vector3(applied_force_strength, 0, 0)
	if mode == "push_left":
		return Vector3(-applied_force_strength, 0, 0)
	if mode == "oscillate":
		return Vector3(
			sin(time * oscillation_speed) * applied_force_strength * 1.5,
			0,
			cos(time * oscillation_speed * 0.75) * applied_force_strength
		)
	return Vector3.ZERO


func _show_force_arrows() -> bool:
	return evidence == "trace" or evidence == "longhand"


func _update_arrows() -> void:
	for i in range(balls.size()):
		var rb := balls[i]
		var vel := rb.linear_velocity

		# Velocity arrow
		if vel.length() > 0.2 and i < velocity_arrows.size():
			var arrow := velocity_arrows[i]
			arrow.visible = true
			arrow.position = rb.position + Vector3(0, 0.4, 0)
			var target := arrow.position + vel.normalized()
			if arrow.position.distance_to(target) > 0.01:
				arrow.look_at(target, Vector3.UP)
			arrow.scale.y = clamp(vel.length() / 5.0, 0.2, 2.0)
		elif i < velocity_arrows.size():
			velocity_arrows[i].visible = false

		# Force arrow — untouched unless the evidence axis asks for it, so at the shipped
		# default these stay exactly as _create_arrow left them: built, and invisible.
		if _show_force_arrows() and i < force_arrows.size():
			var f: Vector3 = _force_on(i)
			var farrow := force_arrows[i]
			if f.length() > 0.01:
				farrow.visible = true
				farrow.position = rb.position + Vector3(0, -0.05, 0)
				var ftarget := farrow.position + f.normalized()
				if farrow.position.distance_to(ftarget) > 0.01:
					farrow.look_at(ftarget, Vector3.UP)
				farrow.scale.y = clamp(f.length() / 5.0, 0.3, 2.5)
			else:
				farrow.visible = false

		# The arithmetic, refreshed where the force is time-varying.
		if evidence == "longhand" and i < _readouts.size():
			var lab := _readouts[i]
			lab.position = rb.position + Vector3(0, 0.95, 0)
			var mag: float = _force_on(i).length()
			lab.text = "m = %.1f kg\nF = %.1f N\na = F/m = %.1f" % [rb.mass, mag, mag / rb.mass]

func _create_arrow(color: Color) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.015
	cyl.height = 1.0
	arrow.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.5
	arrow.material_override = mat
	arrow.visible = false
	return arrow

# ── evidence ──────────────────────────────────────────────────────────────────────────
# Nothing below runs at the shipped default: `result` returns before a node is constructed
# and before a single force arrow is switched on.

func _build_evidence() -> void:
	if evidence == "result" or evidence == "trace":
		return
	if evidence == "axiom":
		_slate = Label3D.new()
		_slate.text = "1.  ΣF = 0   ⇒   Δv = 0\n2.  F = m a\n3.  F₁₂ = − F₂₁"
		_slate.font_size = 44
		_slate.outline_size = 10
		_slate.modulate = Color(0.95, 0.9, 0.75, 1.0)
		_slate.position = Vector3(0, 2.4, 0)
		_slate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_slate)
		return
	# longhand — one readout per body, positioned and filled by _update_arrows.
	for i in range(balls.size()):
		var lab := Label3D.new()
		lab.font_size = 26
		lab.outline_size = 6
		lab.modulate = ball_colors[i]
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.text = ""
		add_child(lab)
		_readouts.append(lab)

func reset() -> void:
	var positions: Array = _law_spec()["positions"]
	for i in range(balls.size()):
		balls[i].linear_velocity = Vector3.ZERO
		balls[i].angular_velocity = Vector3.ZERO
		if i < positions.size():
			balls[i].position = positions[i]
	time = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Was `pass`. Both axis words rebuild — but only when the word is in the allow-list, only
## when it differs from the word already held, and only once _ready has built the scene a
## first time. No placement passes any key to this token today: all 11 maps carry a bare
## `newtons_laws` / `newtons_laws:0:1`, and the `#with_wall`-style flags that appear beside
## it in two of them belong to the curation_station wrapping it, not to this artifact.
func apply_grid_config(config: Dictionary) -> void:
	var dirty: bool = false
	if config.has("applied_force_strength"):
		applied_force_strength = float(config["applied_force_strength"])
	if config.has("oscillation_speed"):
		oscillation_speed = float(config["oscillation_speed"])
	if config.has("law"):
		var l: String = _pick(str(config["law"]), LAWS, law)
		if l != law:
			law = l
			dirty = true
	if config.has("evidence"):
		var e: String = _pick(str(config["evidence"]), EVIDENCE, evidence)
		if e != evidence:
			evidence = e
			dirty = true
	if dirty and is_node_ready():
		_rebuild()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	balls.clear()
	force_arrows.clear()
	velocity_arrows.clear()
	_readouts.clear()
	_modes.clear()
	_slate = null
	time = 0.0
	_create_balls()
	_create_containment()
	_build_evidence()
