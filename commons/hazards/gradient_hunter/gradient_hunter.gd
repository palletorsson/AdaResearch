# @identity
# essence: x_next = x - lr * grad(loss(x)) -- gradient descent as locomotion, loss as distance-to-player
# desire: a sleek predator sampling 6 points, moving toward lowest loss, stuck in local minima
# critical_parameter: _sample_positions / _gradient_dir -- 6-point gradient estimate determines movement
# triggers: continuous gradient sampling; steepest descent movement; local minima -> random annealing jump
# emerges: machine learning as hunting -- the loss function IS the space between predator and prey
# needs: HazardCreatureBase [has]; gradient sampling [has]; minima detection [has]; annealing [has]; VR interaction [missing]
# relationships: embodies machinelearning sequence; pairs with grammar_markov (optimization vs stochastic)
# truth: gradient descent finds A minimum but not THE minimum -- the hunter gets stuck because optimization does.

extends HazardCreatureBase
class_name GradientHunter
## Sleek predator that uses gradient descent to find the player.
## Instead of direct pathfinding, samples 6 positions around itself,
## evaluates distance-to-player at each, and moves toward the lowest.
## Gets stuck behind walls (local minimum) — if stuck for >3 seconds,
## "anneals" by jumping to a random offset position.

@export_group("Gradient Descent")
@export var learning_rate: float = 3.0
@export var sample_radius: float = 0.8
@export var anneal_timeout: float = 3.0
@export var anneal_jump_radius: float = 2.5
@export var sample_count: int = 6

@export_group("Visual")
@export var body_inner_radius: float = 0.08
@export var body_outer_radius: float = 0.22
@export var sample_sphere_radius: float = 0.04
@export var leg_length: float = 0.25
@export var leg_radius: float = 0.02


# ── DNA (stage 2) ────────────────────────────────────────────────────────
@export_group("DNA")

## AXIS — WHAT SHAPE IS THE ESTIMATOR? This creature's own critical_parameter is
## "_sample_positions / _gradient_dir — 6-point gradient estimate determines movement", and
## that estimate was six points on a horizontal circle, hard-coded in three separate places
## (the mesh builder, the orbit animation and _compute_gradient) with the same inlined
## `angle = i/sample_count * TAU` formula. A gradient is never measured; it is INFERRED from
## a finite set of probes, and which probes you take is the whole of what the optimiser can
## possibly know. The ring was never a fact about gradient descent. It was one stencil.
##
##   ring     six points evenly around a circle of sample_radius — the shipped hunter, byte
##            for byte, and the only value whose points also ORBIT (see _process_visual)
##   pair     two points, +X and -X. A single central difference: the cheapest honest
##            estimator there is, and one that can only ever see along one line
##   axial    four points, +/-X and +/-Z. The textbook coordinate-wise partials — the
##            gradient as dL/dx and dL/dz and nothing in between
##   shell    twelve points on a SPHERE, not a circle. Every other value samples a plane and
##            then throws the y component away in _process_chase; this one admits the third
##            dimension the creature has always had and never used
##   swarm    nine points on a deterministic golden-angle spiral at mixed radii — not a
##            stencil at all but a population, the estimator of a search that has given up
##            on differences and is just looking around
##
## Deterministic by construction: no randf anywhere in here, so five variants are five
## pictures of the same creature rather than five different creatures.
@export_enum("ring", "pair", "axial", "shell", "swarm") var stencil: String = "ring"

## AXIS — WHAT DOES IT PUT IN FRAME AS PROOF A LAW IS MOVING IT? Taken character for
## character from [[gradient_descent_visualization]] (promoted the same day) and from the
## motion family behind it — koch_curve, box_counting_dimension, three_body_problem,
## the NOC examples. Same four rungs, same question, and here the apparatus is a PREDATOR
## rather than a diagram: the loss function is the space between it and you.
##
##   result    the body and its four legs. A hunter, and no account of how it decides
##   trace     + the sample points: where it looked. The probe ring is the widest thing on
##             this creature, so this is the rung that changes the picture most
##   longhand  + the gradient arrow and the live loss / learning-rate readout. THE SHIPPED
##             creature. In a still with no player in the world the arrow collapses to the
##             body centre and the numbers read loss=0.00 — this rung is carried by the
##             label, and that is worth knowing before reading a verdict on it
##   axiom     + the stencil drawn as geometry: a spoke from the centre to every probe and a
##             chord between neighbours, with the label carrying the update rule instead of
##             this instant's numbers. What is in frame stops being the estimate and becomes
##             the ESTIMATOR — the part that is true before any hunt begins
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "longhand"

## Allow-lists. An unrecognised token falls back to the value already held.
const STENCILS: PackedStringArray = ["ring", "pair", "axial", "shell", "swarm"]
const EVIDENCES: PackedStringArray = ["result", "trace", "longhand", "axiom"]

# ── Gradient state ───────────────────────────────────────────────────────

var _sample_positions: Array[Vector3] = []   # World-space sample offsets
var _sample_losses: Array[float] = []        # Distance values at each sample
var _gradient_dir: Vector3 = Vector3.ZERO    # Computed gradient direction
var _best_sample_idx: int = 0
var _worst_sample_idx: int = 0
var _current_loss: float = 0.0
var _stuck_timer: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _stuck_threshold: float = 0.15           # Distance moved threshold for "stuck"

# ── Visual refs ──────────────────────────────────────────────────────────

var _body_mesh: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _sample_meshes: Array[MeshInstance3D] = []
var _sample_materials: Array[StandardMaterial3D] = []
var _arrow_mesh: MeshInstance3D = null
var _arrow_mat: StandardMaterial3D = null
var _axiom_mat: StandardMaterial3D = null
var _axiom_meshes: Array[MeshInstance3D] = []
var _label: Label3D = null
## The probe offsets, in creature-local space. ONE source of truth for the mesh builder, the
## orbit animation and _compute_gradient, which each used to inline the same ring formula.
var _offsets: Array[Vector3] = []
var _leg_roots: Array[Node3D] = []
var _leg_meshes: Array[MeshInstance3D] = []
var _walk_phase: float = 0.0

# Colors
var _best_color: Color = Color(0.1, 0.95, 0.2)    # green
var _worst_color: Color = Color(0.95, 0.1, 0.1)   # red
var _neutral_color: Color = Color(0.8, 0.8, 0.2)  # yellow


## HazardCreatureBase's own default patrol speed, and this creature's. The write below is
## guarded against the first: exports are set on the instance BEFORE add_child (by the DNA
## sweep, and by anything else that configures a scene pre-tree), so an unconditional
## `patrol_speed = 1.2` here silently discards a supplied value. Nothing in the repo supplies
## one today, so every existing placement takes the branch and gets 1.2 exactly as before.
const BASE_PATROL_SPEED := 1.8
const OWN_PATROL_SPEED := 1.2


func _on_ready() -> void:
	max_health = 75.0
	_health = max_health
	chase_speed = 0.0  # We handle movement via gradient
	if is_equal_approx(patrol_speed, BASE_PATROL_SPEED):
		patrol_speed = OWN_PATROL_SPEED
	contact_damage = 18.0
	_last_position = global_position

	# Initialize sample arrays. sample_count is whatever the stencil resolved to in
	# _create_materials (6 under the default ring), so these stay in step with _offsets.
	_sample_positions.resize(sample_count)
	_sample_losses.resize(sample_count)
	for i in range(sample_count):
		_sample_positions[i] = Vector3.ZERO
		_sample_losses[i] = 0.0


func _create_materials() -> void:
	# EARLIEST subclass hook the base calls (before _build_collision and _build_mesh), so the
	# stencil is resolved here — everything downstream reads sample_count and _offsets.
	_refresh_stencil()
	_body_mat = _make_material(Color(0.15, 0.15, 0.2), Color(0.05, 0.05, 0.15))
	_arrow_mat = _make_material(Color(0.9, 0.9, 0.1), Color(0.9, 0.9, 0.1))
	_axiom_mat = _make_material(Color(0.45, 0.7, 1.0), Color(0.3, 0.55, 0.95))
	_sample_materials.clear()
	for i in range(sample_count):
		var mat := _make_material(_neutral_color, _neutral_color * 0.5)
		_sample_materials.append(mat)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	col.shape = shape
	col.position.y = leg_length + body_outer_radius
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = leg_length + body_outer_radius

	# Elongated torus body (tube creature)
	var torus := TorusMesh.new()
	torus.inner_radius = body_inner_radius
	torus.outer_radius = body_outer_radius
	_body_mesh = _add_mesh(torus, _body_mat)

	# Sample point spheres floating around the body. Under stencil=ring these are the six
	# points of the shipped creature, at the same positions the inlined formula produced.
	for i in range(sample_count):
		var sphere := SphereMesh.new()
		sphere.radius = sample_sphere_radius
		sphere.height = sample_sphere_radius * 2.0
		var mi := _add_mesh(sphere, _sample_materials[i], _offsets[i])
		mi.name = "Sample_%d" % i
		_sample_meshes.append(mi)

	# Arrow mesh pointing in gradient direction (thin cylinder)
	var arrow_cyl := CylinderMesh.new()
	arrow_cyl.height = 0.3
	arrow_cyl.top_radius = 0.005
	arrow_cyl.bottom_radius = 0.02
	_arrow_mesh = _add_mesh(arrow_cyl, _arrow_mat, Vector3(0, 0, 0))
	_arrow_mesh.name = "GradientArrow"

	# 4 legs
	for i in range(4):
		_build_leg(i)

	# Info label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 40
	_label.pixel_size = 0.003
	_label.position = Vector3(0, body_outer_radius + 0.2, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)

	# Under evidence=longhand (the default) this shows everything just built and adds
	# nothing, so a shipped placement sees no difference at all.
	_apply_evidence()


# ── DNA implementation ───────────────────────────────────────────────────
# The stencil and the evidence rung, and nothing else, live below here.


## The probe offsets this stencil puts around the body, in creature-local space.
## Wholly deterministic — no randf — so five variants are five pictures of one creature.
func _stencil_offsets() -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var r: float = sample_radius
	match stencil:
		"pair":
			pts.append(Vector3(r, 0.0, 0.0))
			pts.append(Vector3(-r, 0.0, 0.0))
		"axial":
			pts.append(Vector3(r, 0.0, 0.0))
			pts.append(Vector3(-r, 0.0, 0.0))
			pts.append(Vector3(0.0, 0.0, r))
			pts.append(Vector3(0.0, 0.0, -r))
		"shell":
			# The twelve icosahedron vertices, normalised onto the sample sphere. The only
			# value that samples the Y the creature has always had and never used.
			var phi: float = (1.0 + sqrt(5.0)) * 0.5
			var raw: Array[Vector3] = [
				Vector3(0.0, 1.0, phi), Vector3(0.0, 1.0, -phi),
				Vector3(0.0, -1.0, phi), Vector3(0.0, -1.0, -phi),
				Vector3(1.0, phi, 0.0), Vector3(1.0, -phi, 0.0),
				Vector3(-1.0, phi, 0.0), Vector3(-1.0, -phi, 0.0),
				Vector3(phi, 0.0, 1.0), Vector3(-phi, 0.0, 1.0),
				Vector3(phi, 0.0, -1.0), Vector3(-phi, 0.0, -1.0),
			]
			for j in range(raw.size()):
				var v: Vector3 = raw[j]
				pts.append(v.normalized() * r)
		"swarm":
			# Nine points on a golden-angle spiral at mixed radii: a population rather than
			# a stencil, the estimator of a search that has stopped taking differences.
			var golden: float = PI * (3.0 - sqrt(5.0))
			for i in range(9):
				var t: float = float(i) / 8.0
				var a: float = golden * float(i)
				var rad: float = r * (0.35 + 0.65 * t)
				pts.append(Vector3(cos(a) * rad, (t - 0.5) * r * 0.5, sin(a) * rad))
		_:
			# "ring" — the shipped hunter. Same formula the mesh builder used to inline, and
			# it still reads sample_count, so a placement that set that export keeps it.
			var n: int = maxi(2, sample_count)
			for i in range(n):
				var ang: float = (float(i) / float(n)) * TAU
				pts.append(Vector3(cos(ang) * r, 0.0, sin(ang) * r))
	return pts


## Resolve the stencil into _offsets and keep everything indexed by probe in step with it.
## Called from _create_materials — the earliest hook the base hands a subclass, before
## _build_collision and _build_mesh — so sample_count is already correct by the time the
## spheres, the materials and _on_ready's arrays are sized.
func _refresh_stencil() -> void:
	_offsets = _stencil_offsets()
	sample_count = _offsets.size()
	_sample_positions.resize(sample_count)
	_sample_losses.resize(sample_count)
	for i in range(sample_count):
		_sample_positions[i] = Vector3.ZERO
		_sample_losses[i] = 0.0


## What is in frame as proof a law is moving this thing. `longhand` is the shipped creature
## and reaches here as a pure no-op: everything was just built visible and nothing is added.
func _apply_evidence() -> void:
	var show_probes: bool = evidence != "result"
	var show_arrow: bool = evidence == "longhand" or evidence == "axiom"
	for i in range(_sample_meshes.size()):
		if is_instance_valid(_sample_meshes[i]):
			_sample_meshes[i].visible = show_probes
	if is_instance_valid(_arrow_mesh):
		_arrow_mesh.visible = show_arrow
	if is_instance_valid(_label):
		_label.visible = show_arrow
	_clear_axiom()
	if evidence == "axiom":
		_build_axiom()


func _clear_axiom() -> void:
	for i in range(_axiom_meshes.size()):
		if is_instance_valid(_axiom_meshes[i]):
			_axiom_meshes[i].queue_free()
	_axiom_meshes.clear()


## AXIOM — the estimator drawn instead of the estimate. A spoke from the body to every probe,
## and a chord from each probe to its nearest neighbour: the stencil's own shape, which is
## true before any hunt starts and stays true when there is no player in the world at all.
func _build_axiom() -> void:
	for i in range(_offsets.size()):
		_axiom_bar(Vector3.ZERO, _offsets[i], 0.006)
	# Nearest-neighbour chords, each unordered pair drawn once. Defined this way because it
	# is the one rule that reads correctly for a circle, a cross, a line and a sphere alike.
	for i in range(_offsets.size()):
		var best: int = -1
		var best_d: float = INF
		for j in range(_offsets.size()):
			if j == i:
				continue
			var d: float = _offsets[i].distance_to(_offsets[j])
			if d < best_d:
				best_d = d
				best = j
		if best > i:
			_axiom_bar(_offsets[i], _offsets[best], 0.004)


func _axiom_bar(a: Vector3, b: Vector3, thick: float) -> void:
	var seg: Vector3 = b - a
	var seg_len: float = seg.length()
	if seg_len < 0.001:
		return
	var cyl := CylinderMesh.new()
	cyl.height = seg_len
	cyl.top_radius = thick
	cyl.bottom_radius = thick
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, _axiom_mat)
	# CylinderMesh runs along local +Y, so build a basis whose Y is the segment.
	var up: Vector3 = seg / seg_len
	var ref: Vector3 = Vector3.FORWARD
	if absf(up.dot(ref)) > 0.95:
		ref = Vector3.RIGHT
	var right: Vector3 = ref.cross(up).normalized()
	var fwd: Vector3 = up.cross(right).normalized()
	mi.transform = Transform3D(Basis(right, up, fwd), (a + b) * 0.5)
	_mesh_root.add_child(mi)
	_axiom_meshes.append(mi)


## Reachable configuration. The base forwards health / speed / damage and knew nothing about
## either axis, so a map token could not reach one. Both branches are CHANGE-GUARDED and
## BUILD-GUARDED: a word outside the allow-list, a word the creature already holds, or a call
## that arrives before _ready has built the body tears nothing down. Arriving early is fine
## on its own — the export is simply assigned and _ready builds with it.
func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	if config.has("stencil"):
		var s: String = str(config["stencil"]).strip_edges().to_lower()
		if STENCILS.has(s) and s != stencil:
			stencil = s
			if _mesh_root != null:
				_rebuild_probes()
	if config.has("evidence"):
		var ev: String = str(config["evidence"]).strip_edges().to_lower()
		if EVIDENCES.has(ev) and ev != evidence:
			evidence = ev
			if _mesh_root != null:
				_apply_evidence()


## Re-seat the probe spheres on a new stencil. Only the spheres are touched — the body, the
## legs, the arrow and the label are the same nodes throughout.
func _rebuild_probes() -> void:
	for i in range(_sample_meshes.size()):
		if is_instance_valid(_sample_meshes[i]):
			_sample_meshes[i].queue_free()
	_sample_meshes.clear()
	_sample_materials.clear()
	_refresh_stencil()
	for i in range(sample_count):
		var mat: StandardMaterial3D = _make_material(_neutral_color, _neutral_color * 0.5)
		_sample_materials.append(mat)
		var sphere := SphereMesh.new()
		sphere.radius = sample_sphere_radius
		sphere.height = sample_sphere_radius * 2.0
		var mi: MeshInstance3D = _add_mesh(sphere, mat, _offsets[i])
		mi.name = "Sample_%d" % i
		_sample_meshes.append(mi)
	_apply_evidence()


func _build_leg(index: int) -> void:
	var root := Node3D.new()
	root.name = "Leg_%d" % index
	# Position legs at corners under the body
	var angle: float = (float(index) / 4.0) * TAU + PI / 4.0
	var x: float = cos(angle) * body_outer_radius * 0.7
	var z: float = sin(angle) * body_outer_radius * 0.7
	root.position = Vector3(x, -body_outer_radius * 0.5, z)
	_mesh_root.add_child(root)
	_leg_roots.append(root)

	var cyl := CylinderMesh.new()
	cyl.height = leg_length
	cyl.top_radius = leg_radius
	cyl.bottom_radius = leg_radius * 0.7
	var leg_mat := _make_material(Color(0.2, 0.2, 0.25), Color.BLACK)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, leg_mat)
	mi.position = Vector3(0, -leg_length * 0.5, 0)
	root.add_child(mi)
	_leg_meshes.append(mi)


func _process_visual(delta: float) -> void:
	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			var phase_offset: float = float(i) * PI * 0.5
			_leg_roots[i].rotation.x = sin(_walk_phase + phase_offset) * 0.3
			_leg_roots[i].rotation.z = cos(_walk_phase + phase_offset) * 0.15

	# Update sample sphere positions (orbit slowly). ONLY the ring orbits: an axial cross that
	# spins is a lie about what "coordinate-wise partials" means, and a shell that spins is a
	# lie about which points are distinct. Every other stencil is held where it was built.
	if stencil == "ring":
		for i in range(_sample_meshes.size()):
			var angle: float = (float(i) / float(sample_count)) * TAU + _state_time * 0.5
			var pos := Vector3(cos(angle) * sample_radius, sin(angle * 2.0) * 0.1, sin(angle) * sample_radius)
			_sample_meshes[i].position = pos
	else:
		for i in range(_sample_meshes.size()):
			if i < _offsets.size():
				_sample_meshes[i].position = _offsets[i]

	# Update arrow orientation to point in gradient direction
	if _gradient_dir.length() > 0.01 and is_instance_valid(_arrow_mesh):
		var local_dir := _gradient_dir
		_arrow_mesh.position = local_dir * 0.2
		# Align cylinder with gradient direction
		var up := Vector3.UP
		if abs(local_dir.dot(up)) > 0.95:
			up = Vector3.RIGHT
		_arrow_mesh.look_at_from_position(_arrow_mesh.position, _arrow_mesh.position + local_dir, up)
		_arrow_mesh.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# Update label. Under `axiom` the readout stops reporting this instant and states the rule
	# the instant is an instance of — a legend for the geometry that rung puts on the table.
	if _label:
		if evidence == "axiom":
			_label.text = "x ← x − lr·∇L   (∇L from %d probes)" % sample_count
		else:
			_label.text = "loss=%.2f, lr=%.1f" % [_current_loss, learning_rate]


func _process_chase(delta: float) -> void:
	if not is_instance_valid(_player_node):
		velocity = Vector3.ZERO
		return

	var dist := _get_player_distance()
	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	# ── Gradient descent step ────────────────────────────────────────
	_compute_gradient()

	# Move in gradient direction
	velocity.x = -_gradient_dir.x * learning_rate
	velocity.z = -_gradient_dir.z * learning_rate
	velocity.y = 0.0

	_face_direction(-_gradient_dir, delta * 3.0)

	# ── Stuck detection (local minimum) ──────────────────────────────
	var moved := global_position.distance_to(_last_position)
	if moved < _stuck_threshold * delta:
		_stuck_timer += delta
	else:
		_stuck_timer = max(0.0, _stuck_timer - delta * 0.5)

	if _stuck_timer > anneal_timeout:
		_anneal()
		_stuck_timer = 0.0

	_last_position = global_position


func _compute_gradient() -> void:
	if not is_instance_valid(_player_node):
		_gradient_dir = Vector3.ZERO
		return

	var best_loss: float = INF
	var worst_loss: float = -INF

	for i in range(sample_count):
		if i >= _offsets.size():
			break
		var sample_offset: Vector3 = _offsets[i]
		var sample_world_pos: Vector3 = global_position + sample_offset

		# Loss function = distance to player
		var loss: float = sample_world_pos.distance_to(_player_node.global_position)
		_sample_losses[i] = loss
		_sample_positions[i] = sample_offset

		if loss < best_loss:
			best_loss = loss
			_best_sample_idx = i
		if loss > worst_loss:
			worst_loss = loss
			_worst_sample_idx = i

	_current_loss = global_position.distance_to(_player_node.global_position)

	# Compute gradient as weighted average direction toward higher loss
	_gradient_dir = Vector3.ZERO
	for i in range(sample_count):
		var normalized_loss: float = 0.0
		if worst_loss - best_loss > 0.001:
			normalized_loss = (_sample_losses[i] - best_loss) / (worst_loss - best_loss)
		_gradient_dir += _sample_positions[i].normalized() * normalized_loss

	if _gradient_dir.length() > 0.01:
		_gradient_dir = _gradient_dir.normalized()

	# Update sample colors: best=green, worst=red, others=lerp
	for i in range(sample_count):
		if i < _sample_materials.size():
			if i == _best_sample_idx:
				_sample_materials[i].albedo_color = _best_color
				_sample_materials[i].emission = _best_color
				_sample_materials[i].emission_energy_multiplier = 2.0
			elif i == _worst_sample_idx:
				_sample_materials[i].albedo_color = _worst_color
				_sample_materials[i].emission = _worst_color
				_sample_materials[i].emission_energy_multiplier = 2.0
			else:
				var t: float = 0.5
				if worst_loss - best_loss > 0.001:
					t = (_sample_losses[i] - best_loss) / (worst_loss - best_loss)
				var c := _best_color.lerp(_worst_color, t)
				_sample_materials[i].albedo_color = c
				_sample_materials[i].emission = c * 0.5
				_sample_materials[i].emission_energy_multiplier = 1.0


func _anneal() -> void:
	# Simulated annealing: jump to random offset to escape local minimum
	var jump := Vector3(
		randf_range(-anneal_jump_radius, anneal_jump_radius),
		0,
		randf_range(-anneal_jump_radius, anneal_jump_radius)
	)
	global_position += jump

	# Visual feedback: flash sample points
	for mat in _sample_materials:
		mat.albedo_color = Color.WHITE
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 4.0


func _on_damaged(_amount: float) -> void:
	# Getting hit increases learning rate temporarily
	learning_rate = min(8.0, learning_rate + 1.0)
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.PATROL:
		_stuck_timer = 0.0
		learning_rate = 3.0
	elif new_state == BaseState.CHASE:
		_last_position = global_position
		_stuck_timer = 0.0
