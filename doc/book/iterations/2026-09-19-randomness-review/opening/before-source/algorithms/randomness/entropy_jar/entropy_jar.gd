# entropy_jar.gd
# Entropy Jar — VR grabbable jar of colored particles.
# Grab + shake → particles mix. Set down → they never unmix.
# Second law of thermodynamics felt physically.
#
# QFEP: Irreversibility — mixing is easy, unmixing is impossible.
# The arrow of time made tangible through embodied interaction.
#
# @identity
# essence: dS/dt >= 0 — the second law of thermodynamics
# desire: shake the jar and feel time's arrow in your hand — red and blue never separate again
# critical_parameter: shake_threshold — the velocity at which your hand movement registers as agitation
# triggers: _agitate_particles() on shake detection via accelerometer-derived velocity
# emerges: Shannon entropy measured across vertical bins converges to maximum and stays there
# needs: VR grab + shake [has], XRToolsPickable [has], haptic feedback [missing]
# relationships: depends on entropy_axiom (conceptual gradient); contrasts with prng_crank_machine (reversible vs irreversible)
# truth: The second law is not a prohibition — it is the statistical certainty that mixed states outnumber ordered ones.

extends Node3D

class_name EntropyJar

# ── Jar ─────────────────────────────────────────────────────────────────────
@export var jar_radius: float = 0.08
@export var jar_height: float = 0.20
@export var jar_wall_thickness: float = 0.004
@export var jar_mass: float = 0.3
@export var glass_color: Color = Color(0.85, 0.92, 0.95, 0.25)

# ── Particles ───────────────────────────────────────────────────────────────
@export var particle_count: int = 40  ## per color group
@export var particle_radius: float = 0.008
@export var color_a: Color = Color(0.9, 0.15, 0.1)   ## red
@export var color_b: Color = Color(0.1, 0.3, 0.9)     ## blue
@export var particle_mass: float = 0.005

# ── Pedestal ────────────────────────────────────────────────────────────────
@export var pedestal_height: float = 0.9
@export var pedestal_color: Color = Color(0.12, 0.1, 0.08)

## Housing (cabinet grammar). A jar is a SPECIMEN, so it gets the containment
## vocabulary rather than a kiosk — but an open DOCK, because this specimen is
## meant to be lifted out and shaken.
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "EJ-07"

# ── Shake Detection ─────────────────────────────────────────────────────────
@export var shake_threshold: float = 1.5  ## velocity magnitude to count as shake

# ── STAGE-2 DNA (promoted 2026-08-03) ───────────────────────────────────────
## The jar had fourteen exports and not one of them was an argument: radii,
## masses, colours, a shake threshold — the SIZE of the thing and the livery of
## the thing. The second law is not a claim about size. It is a claim about
## which state you are standing in front of, and the jar had only ever been
## found in one: red below, blue above, the low-entropy beginning, waiting for
## you to spend it. That is a strong position and it is not the only one.
##
##   sorted   red below, blue above. The beginning. Nothing has happened yet.
##   stirred  the two bodies interpenetrating at the interface. Mid-sentence.
##   mixed    uniform. You arrived too late; the arrow already ran, and the
##            jar's whole point is that you cannot put it back.
##   shelled  sorted RADIALLY — a red core inside a blue shell. Visibly as
##            ordered as `sorted`, and the readout says MAXIMUM ENTROPY,
##            because the measurement bins VERTICALLY. The order is real and
##            the instrument cannot see it. Entropy is relative to the
##            coarse-graining you happened to choose.
@export_enum("sorted", "stirred", "mixed", "shelled") var found_state: String = "sorted"

## And the second argument: whether the second law arrives as a measured
## number, as a verdict in words, or as nothing but the jar.
##   figures  S = 0.00 and the shake/status block (shipped)
##   number   the bare figure, no commentary
##   verdict  the words only — the law stated, not computed
##   none     no instrument at all; the jar has to carry it alone
@export_enum("figures", "number", "verdict", "none") var readout: String = "figures"

## 0 keeps the shipped behaviour exactly: particle placement draws on the global
## RNG, so every jar in every map is genuinely a different jar. Any non-zero
## value pins it, which is what the DNA bench needs — otherwise five variants
## are five different jars and the axis cannot be measured at all.
@export var particle_seed: int = 0

const FOUND_STATES := ["sorted", "stirred", "mixed", "shelled"]
const READOUTS := ["figures", "number", "verdict", "none"]

# ── Internal ────────────────────────────────────────────────────────────────
var _jar_body: RigidBody3D
var _jar_spawn_pos: Vector3
var _particles_a: Array[RigidBody3D] = []
var _particles_b: Array[RigidBody3D] = []
var _is_held: bool = false
var _entropy_label: Label3D
var _stats_label: Label3D
var _shake_count: int = 0
var _prev_velocity: Vector3 = Vector3.ZERO
var _shake_cooldown: float = 0.0
var _initial_entropy: float = 0.0
var _current_entropy: float = 0.0
var _rng: RandomNumberGenerator = null
var _built: bool = false


## Every random draw that decides what the jar LOOKS like routes through these
## two. With particle_seed left at 0 they call the same global functions the
## shipped code called, in the same order, so an unseeded jar draws exactly the
## sequence it always drew and nothing about the 18 existing placements moves.
func _rfu() -> float:
	if _rng != null:
		return _rng.randf()
	return randf()


func _rf(a: float, b: float) -> float:
	if _rng != null:
		return _rng.randf_range(a, b)
	return randf_range(a, b)


func _reseed_rng() -> void:
	if particle_seed != 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = particle_seed
	else:
		_rng = null

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const PICKABLE_SCENE = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const HIGHLIGHT_RING_SCENE = preload("res://addons/godot-xr-tools/objects/highlight/highlight_ring.tscn")


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_reseed_rng()
	_create_pedestal()
	_create_jar()
	_create_particles()
	_create_labels()
	_create_dock()
	_create_vr_controls()
	_settle_specimen()
	_initial_entropy = _measure_entropy()
	_current_entropy = _initial_entropy
	_update_display()
	_built = true


func _physics_process(delta: float) -> void:
	if not _jar_body:
		return

	# Shake detection while held
	if _is_held:
		_shake_cooldown -= delta
		var vel := _jar_body.linear_velocity
		var accel: float = (vel - _prev_velocity).length() / max(delta, 0.001)
		_prev_velocity = vel

		if accel > shake_threshold and _shake_cooldown <= 0.0:
			_shake_count += 1
			_shake_cooldown = 0.15
			_agitate_particles()

	# Measure entropy periodically
	_current_entropy = _measure_entropy()
	_update_display()


# ═════════════════════════════════════════════════════════════════════════════
# PEDESTAL
# ═════════════════════════════════════════════════════════════════════════════

func _create_pedestal() -> void:
	var body := StaticBody3D.new()
	body.name = "Pedestal"

	# Collision
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = jar_radius * 1.8
	shape.height = pedestal_height
	col.shape = shape
	body.add_child(col)

	# Mesh
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = jar_radius * 1.8
	cyl.bottom_radius = jar_radius * 2.0
	cyl.height = pedestal_height
	cyl.radial_segments = 24
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pedestal_color
	mat.metallic = 0.3
	mat.roughness = 0.6
	mesh.material_override = mat
	body.add_child(mesh)

	body.position = Vector3(0, pedestal_height / 2.0, 0)
	add_child(body)

	# Top surface for jar to rest on
	var top := StaticBody3D.new()
	top.name = "PedestalTop"
	var top_col := CollisionShape3D.new()
	var top_shape := CylinderShape3D.new()
	top_shape.radius = jar_radius * 1.8
	top_shape.height = 0.02
	top_col.shape = top_shape
	top.add_child(top_col)
	top.position = Vector3(0, pedestal_height + 0.01, 0)

	var phys := PhysicsMaterial.new()
	phys.friction = 0.9
	phys.bounce = 0.05
	top.physics_material_override = phys
	add_child(top)


# ═════════════════════════════════════════════════════════════════════════════
# JAR
# ═════════════════════════════════════════════════════════════════════════════

func _create_jar() -> void:
	var pickable: XRToolsPickable = PICKABLE_SCENE.instantiate() as XRToolsPickable
	if pickable == null:
		push_error("EntropyJar: Failed to instantiate XRTools pickable scene.")
		return

	_jar_body = pickable
	_jar_body.name = "Jar"
	pickable.press_to_hold = true
	pickable.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	_jar_body.mass = jar_mass
	_jar_body.gravity_scale = 1.2
	_jar_body.linear_damp = 0.5
	_jar_body.angular_damp = 0.8
	_jar_body.continuous_cd = true

	# Main collision — cylinder approximation
	var col := _jar_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		_jar_body.add_child(col)
	var shape := CylinderShape3D.new()
	shape.radius = jar_radius
	shape.height = jar_height
	col.shape = shape

	# Glass walls — transparent cylinder
	var wall_mesh := MeshInstance3D.new()
	wall_mesh.name = "JarWall"
	var wall_cyl := CylinderMesh.new()
	wall_cyl.top_radius = jar_radius
	wall_cyl.bottom_radius = jar_radius
	wall_cyl.height = jar_height
	wall_cyl.radial_segments = 24
	wall_mesh.mesh = wall_cyl
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = glass_color
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic = 0.1
	glass_mat.roughness = 0.05
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall_mesh.material_override = glass_mat
	_jar_body.add_child(wall_mesh)

	# Jar bottom — opaque disc
	var bottom := MeshInstance3D.new()
	bottom.name = "JarBottom"
	var disc := CylinderMesh.new()
	disc.top_radius = jar_radius - jar_wall_thickness
	disc.bottom_radius = jar_radius - jar_wall_thickness
	disc.height = 0.003
	disc.radial_segments = 24
	bottom.mesh = disc
	var bottom_mat := StandardMaterial3D.new()
	bottom_mat.albedo_color = Color(0.7, 0.75, 0.8, 0.5)
	bottom_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bottom_mat.roughness = 0.1
	bottom.material_override = bottom_mat
	bottom.position.y = -jar_height / 2.0 + 0.002
	_jar_body.add_child(bottom)

	# Lid — slightly opaque top
	var lid := MeshInstance3D.new()
	lid.name = "JarLid"
	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = jar_radius + 0.005
	lid_mesh.bottom_radius = jar_radius + 0.003
	lid_mesh.height = 0.012
	lid_mesh.radial_segments = 24
	lid.mesh = lid_mesh
	var lid_mat := StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.55, 0.5, 0.4)
	lid_mat.metallic = 0.5
	lid_mat.roughness = 0.4
	lid.material_override = lid_mat
	lid.position.y = jar_height / 2.0 + 0.004
	_jar_body.add_child(lid)

	# Highlight ring
	var highlight: Node3D = HIGHLIGHT_RING_SCENE.instantiate() as Node3D
	if highlight:
		highlight.position = Vector3(0, -jar_height * 0.46, 0)
		var ring_scale: float = jar_radius / 0.03
		if ring_scale < 1.0:
			ring_scale = 1.0
		highlight.scale = Vector3.ONE * ring_scale
		_jar_body.add_child(highlight)

	_jar_body.position = Vector3(0, pedestal_height + 0.02 + jar_height / 2.0, 0)

	if _jar_body.has_signal("dropped"):
		_jar_body.dropped.connect(_on_jar_dropped)
	if _jar_body.has_signal("picked_up"):
		_jar_body.picked_up.connect(_on_jar_picked_up)

	add_child(_jar_body)


# ═════════════════════════════════════════════════════════════════════════════
# PARTICLES
# ═════════════════════════════════════════════════════════════════════════════

func _create_particles() -> void:
	var inner_r := jar_radius - jar_wall_thickness - particle_radius
	var half_h := jar_height / 2.0 - particle_radius * 2.0

	# Group A — start in bottom half (red)
	for i in range(particle_count):
		var p := _create_single_particle(color_a, i)
		var angle: float = _rfu() * TAU
		var r: float = _rfu() * inner_r
		var y: float = _rf(-half_h, 0.0)
		p.position = Vector3(cos(angle) * r, y, sin(angle) * r)
		_jar_body.add_child(p)
		_particles_a.append(p)

	# Group B — start in top half (blue)
	for i in range(particle_count):
		var p := _create_single_particle(color_b, i)
		var angle: float = _rfu() * TAU
		var r: float = _rfu() * inner_r
		var y: float = _rf(0.0, half_h)
		p.position = Vector3(cos(angle) * r, y, sin(angle) * r)
		_jar_body.add_child(p)
		_particles_b.append(p)

	# These positions are provisional: _settle_specimen() re-places every
	# particle through _place_particles() at the end of _ready, and THAT is what
	# a still photograph shows. The draws above are kept verbatim so the global
	# RNG stream is consumed in the shipped order.


func _create_single_particle(base_color: Color, idx: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "Particle_%d" % idx
	body.mass = particle_mass
	body.gravity_scale = 1.0
	body.linear_damp = 2.0
	body.angular_damp = 2.0
	body.continuous_cd = true

	var phys := PhysicsMaterial.new()
	phys.bounce = 0.3
	phys.friction = 0.2
	body.physics_material_override = phys

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = particle_radius
	col.shape = shape
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = particle_radius
	sphere.height = particle_radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	mesh.mesh = sphere

	var mat := StandardMaterial3D.new()
	# Slight color variation per particle
	var hue_shift: float = _rf(-0.03, 0.03)
	mat.albedo_color = Color(
		clamp(base_color.r + hue_shift, 0, 1),
		clamp(base_color.g + hue_shift, 0, 1),
		clamp(base_color.b - hue_shift, 0, 1)
	)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.4
	mat.metallic = 0.15
	mat.roughness = 0.35
	mesh.material_override = mat
	body.add_child(mesh)

	return body


func _agitate_particles() -> void:
	var all_particles := _particles_a + _particles_b
	for p in all_particles:
		if is_instance_valid(p):
			p.apply_impulse(Vector3(
				randf_range(-0.003, 0.003),
				randf_range(-0.002, 0.003),
				randf_range(-0.003, 0.003)
			))


# ═════════════════════════════════════════════════════════════════════════════
# ENTROPY MEASUREMENT
# ═════════════════════════════════════════════════════════════════════════════

func _measure_entropy() -> float:
	# Entropy = how mixed are the two groups?
	# Divide jar into vertical slices. In a separated state, top is all blue,
	# bottom is all red. In a mixed state, each slice has ~50/50.
	# Use Shannon entropy across vertical bins.
	var bin_count := 6
	var half_h := jar_height / 2.0
	var bins_a: Array[int] = []
	var bins_b: Array[int] = []
	bins_a.resize(bin_count)
	bins_b.resize(bin_count)
	bins_a.fill(0)
	bins_b.fill(0)

	for p in _particles_a:
		if is_instance_valid(p):
			var local_y := p.position.y
			var bin_idx := int(clamp((local_y + half_h) / jar_height * bin_count, 0, bin_count - 1))
			bins_a[bin_idx] += 1

	for p in _particles_b:
		if is_instance_valid(p):
			var local_y := p.position.y
			var bin_idx := int(clamp((local_y + half_h) / jar_height * bin_count, 0, bin_count - 1))
			bins_b[bin_idx] += 1

	# Per-bin mixing entropy
	var total_entropy := 0.0
	for i in range(bin_count):
		var na: float = bins_a[i]
		var nb: float = bins_b[i]
		var total: float = na + nb
		if total < 1.0:
			continue
		var pa: float = na / total
		var pb: float = nb / total
		var bin_ent := 0.0
		if pa > 0.001:
			bin_ent -= pa * log(pa) / log(2.0)
		if pb > 0.001:
			bin_ent -= pb * log(pb) / log(2.0)
		total_entropy += bin_ent * (total / float(particle_count * 2))

	return total_entropy


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

func _create_labels() -> void:
	# Title
	var title := Label3D.new()
	title.name = "TitleLabel"
	title.text = "ENTROPY JAR"
	title.pixel_size = 0.002
	title.font_size = 18
	title.modulate = Color(0.9, 0.9, 0.95)
	title.position = Vector3(0, pedestal_height + jar_height + 0.12, -jar_radius - 0.08)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Subtitle
	var sub := Label3D.new()
	sub.text = "Second Law of Thermodynamics"
	sub.pixel_size = 0.0014
	sub.font_size = 10
	sub.modulate = Color(0.6, 0.6, 0.7)
	sub.position = Vector3(0, pedestal_height + jar_height + 0.07, -jar_radius - 0.08)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Entropy display
	_entropy_label = Label3D.new()
	_entropy_label.name = "EntropyLabel"
	_entropy_label.text = "S = 0.00"
	_entropy_label.pixel_size = 0.003
	_entropy_label.font_size = 24
	_entropy_label.modulate = Color(1.0, 0.85, 0.3)
	_entropy_label.position = Vector3(jar_radius + 0.12, pedestal_height + jar_height * 0.7, 0)
	_entropy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_entropy_label)

	# Stats
	_stats_label = Label3D.new()
	_stats_label.name = "StatsLabel"
	_stats_label.text = "Shakes: 0\n\nGrab & shake\nthe jar!"
	_stats_label.pixel_size = 0.0012
	_stats_label.font_size = 10
	_stats_label.modulate = Color(0.8, 0.8, 0.85)
	_stats_label.position = Vector3(jar_radius + 0.12, pedestal_height + jar_height * 0.35, 0)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stats_label)


## The second axis: whether the law arrives as a measured number, as a verdict
## in words, or as nothing but the jar. At the default "figures" both labels are
## visible and both carry the shipped text, so this is a no-op for every map.
func _update_display() -> void:
	var show_number: bool = (readout == "figures" or readout == "number")
	var show_words: bool = (readout == "figures" or readout == "verdict")

	if _entropy_label:
		_entropy_label.visible = show_number
	if _stats_label:
		_stats_label.visible = show_words

	if _stats_label and readout == "verdict":
		# The law stated, not computed — no figure anywhere on the plinth.
		if _current_entropy > 0.85:
			_stats_label.text = "MAXIMUM ENTROPY\n\nCannot unmix"
		elif _current_entropy > 0.5:
			_stats_label.text = "MIXING\n\nKeep shaking"
		else:
			_stats_label.text = "ORDERED\n\nGrab & shake\nthe jar!"
		if _entropy_label:
			_entropy_label.text = "S = %.2f" % _current_entropy
		return

	if _entropy_label:
		_entropy_label.text = "S = %.2f" % _current_entropy
		# Color shifts from cool blue (ordered) to warm red (mixed)
		var t: float = clamp(_current_entropy, 0.0, 1.0)
		_entropy_label.modulate = Color(
			lerp(0.3, 1.0, t),
			lerp(0.7, 0.4, t),
			lerp(1.0, 0.2, t)
		)

	if _stats_label:
		var lines := "Shakes: %d\n" % _shake_count
		if _shake_count > 0:
			lines += "Entropy: %.3f bit\n" % _current_entropy
			if _current_entropy > 0.85:
				lines += "MAXIMUM ENTROPY\n"
				lines += "Cannot unmix!"
			elif _current_entropy > 0.5:
				lines += "Mixing...\n"
				lines += "Keep shaking!"
			else:
				lines += "Partially ordered\n"
		else:
			lines += "\nGrab & shake\nthe jar!"
		_stats_label.text = lines


# ═════════════════════════════════════════════════════════════════════════════
# VR INTERACTION
# ═════════════════════════════════════════════════════════════════════════════

## Seat the jar in the dock's cradle and freeze it — the specimen rests on
## display (no gravity drop) until it is grabbed. Without this the jar and its
## 80 particles simply fall: there is nothing under a pickable RigidBody in a
## static viewer, and even in a map it should read as SEATED, not fallen.
func _settle_specimen() -> void:
	var seat_y: float = pedestal_height + 0.07
	var dock: Node = get_node_or_null("SpecimenDock")
	if dock != null and dock.has_meta("seat_y"):
		seat_y = float(dock.get_meta("seat_y"))
	_jar_spawn_pos = Vector3(0, seat_y + jar_height / 2.0, 0)
	if _jar_body != null and is_instance_valid(_jar_body):
		_jar_body.global_position = global_position + _jar_spawn_pos
		_jar_body.global_rotation = Vector3.ZERO
		_jar_body.linear_velocity = Vector3.ZERO
		_jar_body.angular_velocity = Vector3.ZERO
		_jar_body.freeze = true
	_seed_particles()

## Place the particles inside the jar and freeze them, so the specimen is still
## until shaken. WHERE they go is the `found_state` axis.
func _seed_particles() -> void:
	_place_particles()


## THE AXIS. Which state of the second law you are standing in front of.
##
## Every branch draws in the shipped ORDER — group A fully, then group B, and
## per particle angle, then radius, then height — so at found_state "sorted"
## with particle_seed 0 the global RNG is consumed exactly as before and the
## placement is identical, particle for particle.
func _place_particles() -> void:
	var inner_r: float = jar_radius - jar_wall_thickness - particle_radius
	var half_h: float = jar_height / 2.0 - particle_radius * 2.0

	match found_state:
		"stirred":
			# The two bodies interpenetrating at the interface. Each group still
			# owns its half but reaches a third of the way into the other, so
			# there is a band in the middle where the question is live.
			_scatter(_particles_a, -half_h, half_h * 0.35, 0.0, inner_r)
			_scatter(_particles_b, -half_h * 0.35, half_h, 0.0, inner_r)
		"mixed":
			# Uniform. You arrived too late; the arrow already ran.
			_scatter(_particles_a, -half_h, half_h, 0.0, inner_r)
			_scatter(_particles_b, -half_h, half_h, 0.0, inner_r)
		"shelled":
			# Sorted RADIALLY: a red core inside a blue shell. Both groups span
			# the full height, so every vertical bin reads 50/50 and
			# _measure_entropy() — which coarse-grains along Y and only along Y —
			# reports MAXIMUM ENTROPY at a jar that is visibly, obviously sorted.
			# The order is real. The instrument cannot see it.
			_scatter(_particles_a, -half_h, half_h, 0.0, inner_r * 0.46)
			_scatter(_particles_b, -half_h, half_h, inner_r * 0.74, inner_r)
		_:
			# "sorted" — SHIPPED. Red below, blue above. The low-entropy
			# beginning, waiting for you to spend it.
			_scatter(_particles_a, -half_h, 0.0, 0.0, inner_r)
			_scatter(_particles_b, 0.0, half_h, 0.0, inner_r)


## One group into a cylindrical annulus: height in [y_lo, y_hi], radius in
## [r_lo, r_hi]. At r_lo = 0 the radius draw is `_rfu() * r_hi`, character for
## character the expression the shipped code used.
func _scatter(group: Array[RigidBody3D], y_lo: float, y_hi: float, r_lo: float, r_hi: float) -> void:
	for p in group:
		if is_instance_valid(p):
			p.freeze = true
			p.linear_velocity = Vector3.ZERO
			p.angular_velocity = Vector3.ZERO
			var angle: float = _rfu() * TAU
			var r: float = r_lo + _rfu() * (r_hi - r_lo)
			p.position = Vector3(cos(angle) * r, _rf(y_lo, y_hi), sin(angle) * r)


func _on_jar_picked_up(_pickable) -> void:
	_is_held = true
	_prev_velocity = Vector3.ZERO
	# wake the frozen display specimen so it can be shaken
	if _jar_body != null and is_instance_valid(_jar_body):
		_jar_body.freeze = false
	for p in (_particles_a + _particles_b):
		if is_instance_valid(p):
			p.set_deferred("freeze", false)


func _on_jar_dropped(_pickable) -> void:
	_is_held = false


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("", [
		[{"type": "button", "label": "RESET"}],
	])
	panel.position = Vector3(0, pedestal_height * 0.90, jar_radius * 2.4 + 0.012)
	panel.rotation_degrees = Vector3(-18, 0, 0)
	panel.scale = Vector3(0.78, 0.78, 0.78)
	add_child(panel)

	# RESET button (Btn_0)
	var reset_btn: Node = panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset_jar())


func _reset_jar() -> void:
	# Return jar to pedestal
	if _jar_body:
		_jar_body.freeze = true
		_jar_body.linear_velocity = Vector3.ZERO
		_jar_body.angular_velocity = Vector3.ZERO
		_jar_body.global_position = global_position + _jar_spawn_pos
		_jar_body.global_rotation = Vector3.ZERO

		# Restore the state the jar was FOUND in. At the default "sorted" this is
		# the shipped behaviour exactly — A back to the bottom, B back to the top
		# — and at any other value RESET still means "put it back how it was",
		# which is the only reading that keeps the button honest.
		_place_particles()
		for p in (_particles_a + _particles_b):
			if is_instance_valid(p):
				p.set_deferred("freeze", false)

		_jar_body.set_deferred("freeze", false)

	_shake_count = 0
	_is_held = false
	_current_entropy = _measure_entropy()
	_update_display()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Map/bench entry point. The sweep sets the @exports directly before add_child
## so _ready() builds with them; this is the path a map token takes, and the
## rescue path the capture harness uses.
func apply_grid_config(config: Dictionary) -> void:
	var restate: bool = false

	if config.has("found_state"):
		var v: String = str(config["found_state"])
		if v in FOUND_STATES and v != found_state:
			found_state = v
			restate = true

	if config.has("readout"):
		var r: String = str(config["readout"])
		if r in READOUTS and r != readout:
			readout = r
			restate = true

	if config.has("particle_seed"):
		var s: int = int(config["particle_seed"])
		if s != particle_seed:
			particle_seed = s
			_reseed_rng()
			restate = true

	# THE GUARD THAT MATTERS. An unguarded re-place here would re-draw all 80
	# particles in the 18 maps that place this jar with no config at all — a
	# visible change to shipped rooms in exchange for nothing. Act only when a
	# value actually moved, and only once _ready has built a jar to re-place.
	# Before _ready the exports are simply left set, and _ready honours them.
	if not restate or not _built:
		return

	_place_particles()
	_current_entropy = _measure_entropy()
	_update_display()


## THE SPECIMEN DOCK — a jar is a jar, so it gets the containment-tank idiom
## (Palle 2026-07-20, pointing at lab_specimen_4cf36): tapered base, lit
## cradle ring, strut cage, readout inset in the base. With the cap left OFF,
## because this specimen is an XRToolsPickable — a dome would seal shut the
## one thing the artifact is for.
func _create_dock() -> void:
	var dock: Node3D = HangarKit.specimen_dock(
		jar_radius * 2.4, jar_radius * 1.25, pedestal_height, jar_height * 0.55,
		finish, wear, Color(0.86, 0.34, 0.11), Color(0.35, 0.78, 0.95))
	if dock == null:
		return
	add_child(dock)

	# the old cylinder pedestal is replaced by the dock's own base
	var old: Node = get_node_or_null("Pedestal")
	if old != null:
		for c in old.get_children():
			if c is MeshInstance3D:
				c.queue_free()          # keep the collider, drop the plain cylinder

	# retire the floating title/subtitle — the base plate carries the name
	for n in ["TitleLabel"]:
		var t: Node = get_node_or_null(n)
		if t != null:
			t.queue_free()
	for c in get_children():
		if c is Label3D and str((c as Label3D).text).begins_with("Second Law"):
			c.queue_free()

	# the live figures move onto the dock's readout screen
	var panel: Node3D = dock.get_node_or_null("DockReadout")
	if panel != null:
		if _entropy_label != null and is_instance_valid(_entropy_label):
			_entropy_label.reparent(panel)
			_entropy_label.pixel_size = 0.0011
			_entropy_label.position = Vector3(0.0, 0.030, 0.022)
			_entropy_label.rotation_degrees = Vector3.ZERO
			_entropy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _stats_label != null and is_instance_valid(_stats_label):
			_stats_label.reparent(panel)
			_stats_label.pixel_size = 0.00100
			_stats_label.position = Vector3(0.0, -0.028, 0.022)
			_stats_label.rotation_degrees = Vector3.ZERO
			_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# The column was a single 0.9 m near-black mass, which reads as a bin.
	# Band it the way the station props band a tall body: a lighter mid
	# section between two dark collars, bolt rows, and a foot ring.
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_mid: StandardMaterial3D = HangarKit.finish_body(finish, pal["body"], wear)  # off-white body dominates (family signature)
	var col_dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.09, 0.09, 0.105), wear, 0.45, 0.5)
	var steel: StandardMaterial3D = HangarKit.worn_metal(pal["panel"])
	var br: float = jar_radius * 2.4
	var band := MeshInstance3D.new()
	var band_mesh := CylinderMesh.new()
	band_mesh.top_radius = br * 0.965
	band_mesh.bottom_radius = br * 0.985
	band_mesh.height = pedestal_height * 0.62   # widen the off-white body over the dark collars
	band_mesh.radial_segments = 32
	band.mesh = band_mesh
	band.material_override = col_mid
	band.position = Vector3(0, pedestal_height * 0.52, 0)
	add_child(band)
	for sy in [pedestal_height * 0.285, pedestal_height * 0.715]:
		var collar := MeshInstance3D.new()
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = br * 1.01
		cmesh.bottom_radius = br * 1.01
		cmesh.height = 0.022
		cmesh.radial_segments = 32
		collar.mesh = cmesh
		collar.material_override = col_dark
		collar.position = Vector3(0, sy, 0)
		add_child(collar)
	for i in range(4):
		var ang: float = TAU * (float(i) / 4.0) + 0.4
		add_child(HangarKit.bolts(
			Vector3(cos(ang) * br * 0.99, pedestal_height * 0.31, sin(ang) * br * 0.99),
			Vector3(cos(ang) * br * 0.99, pedestal_height * 0.69, sin(ang) * br * 0.99),
			4, 0.007, steel))
	# (no grime_band: it is a FLAT plate and this body is a cylinder — it
	#  would jut out as a slab. Round bodies take their age from banding.)

	# name plate on the base, read on approach
	var plate: MeshInstance3D = HangarKit.brand_patch("ENTROPY JAR",
		Vector2(0.20, 0.036), Color(0.07, 0.075, 0.09), Color(0.93, 0.94, 0.97))
	if plate:
		plate.position = Vector3(0.0, pedestal_height * 0.30, jar_radius * 2.4 - 0.004)
		add_child(plate)
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.075, 0.020),
		Color(0.86, 0.34, 0.11).lightened(0.25))
	if code:
		code.position = Vector3(0.0, pedestal_height * 0.16, jar_radius * 2.4 - 0.004)
		add_child(code)
