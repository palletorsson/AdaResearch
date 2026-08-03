extends Node3D

# @identity
# essence: F_ij = G*m_i*m_j/r^2. Three bodies, three mutual attractions, no closed-form solution. Deterministic rules, unpredictable trajectories.
# desire: To watch three glowing bodies dance — orbiting, swapping partners, ejecting one, recapturing — Poincare's impossibility made visible.
# critical_parameter: gravitational_constant (0.1) and initial conditions. Tiny changes in starting positions produce wildly different long-term behavior. This IS chaos.
# triggers: Auto-start — bodies attract pairwise, trails trace history. Reset button → return to initial positions. Pause → freeze the dance. Mass slider → all masses change.
# emerges: Figure-eight orbits (rare, unstable). Hierarchical pairs (two orbit closely, third orbits the pair). Ejection events (one body flung away). Sensitivity to initial conditions.
# needs: VR UI buttons [has], trail visualization [has], auto-rotate for 3D perspective [has], initial-condition families [has, configuration axis]. Missing: VR grabbable bodies to set initial conditions by hand, Lyapunov exponent display.
# relationships: Extends exercise_1_8 (two-body attraction → three-body chaos). Pairs with nbody_simulation (3 → N). Gateway to chaos_attractor (strange attractors from deterministic ODEs).
# truth: Three bodies under gravity have no formula. The future is computable but not predictable. Determinism and predictability are not the same thing.

class_name ThreeBodyProblem

# STAGE-2 DNA PROMOTION (2026-07-29). This artifact had zero exports. The three
# bodies' initial conditions were frozen in the .tscn — one pinwheel, forever — so
# the artifact could only ever make half its argument. Chaos is not the claim that
# three bodies are always a mess; it is the claim that the SAME law produces a
# rigid clockwork from one starting state and an ejection from a neighbouring one.
# You cannot see that from a single initial condition.
#
#   configuration   the initial conditions   pinwheel · figure_eight · lagrange
#                                            hierarchical · near_collision
#   evidence        what is drawn OF the     result · trace · longhand · axiom
#                   motion once it runs
#
# STAGE-2 DEEPENING (2026-08-03). configuration says which universe starts; it says
# nothing about what the room is allowed to SEE of it, and that was frozen too —
# three spheres and their fading trails, always. The two questions are independent:
# every configuration can be shown four ways and every way applies to all five
# configurations. `evidence` is the family word (example_2_8, example_2_9, koch_curve,
# wave_interference_tank and eighteen others already ask it with these four values);
# it is taken character for character rather than as a synonym. trace is its
# default and is the shipped build — trails on, and no overlay node ever built.
#
# pinwheel is the default and is a deliberate NO-OP: it leaves the positions and
# velocities authored in threebodyproblem.tscn exactly as they are, so the five
# existing placements render identically to before the promotion.
#
# Two of the values are the famous exceptions — the periodic solutions that DO
# have a closed form (Lagrange's rotating triangle, 1772; the Chenciner–Montgomery
# figure-eight choreography, 2000). Standing them next to near_collision is the
# whole point: determinism is constant across all five, predictability is not.
#
# Usage in map_data.json:
#   "three_body_problem#configuration:figure_eight"
#   "three_body_problem#evidence:axiom"
#   "three_body_problem#configuration:near_collision#evidence:longhand"

## Which initial conditions the three bodies start from.
@export_enum("pinwheel", "figure_eight", "lagrange", "hierarchical", "near_collision") var configuration: String = "pinwheel"

## What the exhibit offers as evidence of the motion. The physics is identical in
## all four — _apply_gravitational_forces, _update_bodies and the integrator are
## never touched. What changes is what is drawn.
##   result:   the three bodies and nothing else. Where they are, with no record of
##             how they got there — the answer with the working thrown away.
##   trace:    the shipped exhibit. Trails on: 200 fading samples of each body's
##             own history, the only evidence this artifact has ever offered.
##   longhand: no history at all, the instant's working instead. A line between
##             every pair with a crossbar sized by G m m / r^2, and on each body
##             the resultant of the two pulls it is actually under.
##   axiom:    the instance gives way to the rule. Trails off, a slate carrying the
##             law and Poincare's result, and the barycentre — with its own track,
##             which is a straight line no matter how violent the dance, because
##             total momentum is conserved. The one thing here that IS predictable.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "trace"

const EVIDENCE_VALUES := ["result", "trace", "longhand", "axiom"]

## How many barycentre samples the axiom track keeps. Capped so the overlay never
## outgrows the bodies' own extent and starves the capture framing.
const BARY_TRACK_MAX: int = 150

## Initial [position, velocity] per body, in the order the CelestialBodies node
## lists them. Tuned for this scene's G = 0.1 and body_mass = 1000.
## "pinwheel" is absent ON PURPOSE — it means "use what the scene authored".
const CONFIGURATIONS := {
	# Chenciner-Montgomery choreography: all three chase each other around one
	# figure-eight curve. Unit solution scaled to L = 6, v x sqrt(100 / 6).
	"figure_eight": [
		[Vector3(5.820, 0, -1.459), Vector3(1.903, 0, 1.765)],
		[Vector3(-5.820, 0, 1.459), Vector3(1.903, 0, 1.765)],
		[Vector3(0, 0, 0), Vector3(-3.806, 0, -3.530)],
	],
	# Lagrange's equilateral triangle, rotating rigidly. Circumradius 5,
	# omega = sqrt(3 G m / a^3) with side a = 8.66.
	"lagrange": [
		[Vector3(0, 0, 5), Vector3(-3.398, 0, 0)],
		[Vector3(-4.330, 0, -2.5), Vector3(1.699, 0, -2.943)],
		[Vector3(4.330, 0, -2.5), Vector3(1.699, 0, 2.943)],
	],
	# A tight binary with a distant third orbiting the pair. Stable-looking, and
	# the arrangement most real triple systems actually settle into.
	"hierarchical": [
		[Vector3(-1.5, 0, 0), Vector3(2.04, 0, 4.08)],
		[Vector3(1.5, 0, 0), Vector3(2.04, 0, -4.08)],
		[Vector3(0, 0, 12), Vector3(-4.08, 0, 0)],
	],
	# Nearly collinear, barely moving: they fall together, slingshot, and one is
	# usually flung out of the frame. Sensitivity to initial conditions, visible.
	"near_collision": [
		[Vector3(-6, 0, 0.25), Vector3(0, 0, 0.55)],
		[Vector3(0.4, 0, 0), Vector3(0, 0, 0)],
		[Vector3(6, 0, -0.25), Vector3(0, 0, -0.55)],
	],
}

var bodies = []
# The initial conditions as authored in the scene file, captured before any DNA is
# applied so "pinwheel" can always be restored to the byte.
var _authored: Array = []
var paused = false
var trails_enabled = true

# Evidence overlay. Nothing here is constructed at evidence = "trace" or "result",
# so the default scene tree — and the AABB the capture frames from — is the
# pre-deepening one, node for node.
var _evidence_root: Node3D = null
var _evidence_mesh: ImmediateMesh = null
var _evidence_instance: MeshInstance3D = null
var _slate: Label3D = null
var _bary_points: PackedVector3Array = PackedVector3Array()
var gravitational_constant = 0.1
var time_scale = 1.0
var rotation_time = 0.0

# Vibrant queer color palette for bodies
var queer_colors = [
	Color(1.0, 0.4, 0.7, 1.0),    # Hot pink
	Color(0.8, 0.3, 1.0, 1.0),    # Purple
	Color(0.3, 0.9, 1.0, 1.0),    # Cyan
	Color(1.0, 0.8, 0.2, 1.0),    # Gold
	Color(0.5, 1.0, 0.4, 1.0),    # Lime
	Color(1.0, 0.5, 0.3, 1.0)     # Coral
]

func _ready() -> void:
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_create_star_field()
	_initialize_bodies()
	_connect_ui()
	_apply_vibrant_colors()

	# Auto-start simulation
	paused = false
	# At evidence = "trace" this is exactly the `trails_enabled = true` that stood
	# here, and it builds nothing: the five existing placements are untouched.
	_apply_evidence()

func _create_star_field() -> void:
	# Create a background star field using a single MultiMeshInstance3D
	# instead of 200 individual CSGSphere3D nodes (saves ~200 RIDs).
	var star_field := get_node_or_null("StarField")
	if not star_field:
		return

	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.03
	star_mesh.height = 0.06
	star_mesh.radial_segments = 4
	star_mesh.rings = 2

	var star_material := StandardMaterial3D.new()
	star_material.albedo_color = Color.WHITE
	star_material.emission_enabled = true
	star_material.emission = Color.WHITE * 0.5
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = star_mesh
	mm.instance_count = 200

	# Seed star positions and random sizes via per-instance transforms
	for i in range(200):
		var angle1: float = randf_range(0, 2 * PI)
		var angle2: float = randf_range(0, PI)
		var radius: float = randf_range(50, 100)
		var pos := Vector3(
			radius * sin(angle2) * cos(angle1),
			radius * sin(angle2) * sin(angle1),
			radius * cos(angle2)
		)
		var s: float = randf_range(0.3, 1.5)  # Random scale variation
		var t := Transform3D(Basis().scaled(Vector3(s, s, s)), pos)
		mm.set_instance_transform(i, t)
		# Slight color variation for visual depth
		var brightness: float = randf_range(0.6, 1.0)
		mm.set_instance_color(i, Color(brightness, brightness, brightness + 0.1, 1.0))

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = star_material
	star_field.add_child(mmi)

func _initialize_bodies() -> void:
	var celestial = get_node_or_null("CelestialBodies")
	if not celestial:
		return
	bodies = celestial.get_children()

	# Remember what the scene authored, once, before any axis touches it.
	if _authored.is_empty():
		for body in bodies:
			_authored.append([body.initial_position, body.initial_velocity])

	_apply_configuration()

	# Initialize each body
	for body in bodies:
		body.initialize()


func _apply_configuration() -> void:
	"""Write the chosen initial conditions onto the bodies.

	pinwheel restores the scene-authored values, so it is behaviourally identical
	to never having been promoted — including if a map switches away and back.
	"""
	if configuration == "pinwheel" or not CONFIGURATIONS.has(configuration):
		for i in range(bodies.size()):
			if i >= _authored.size():
				continue
			var pair: Array = _authored[i]
			bodies[i].initial_position = pair[0]
			bodies[i].initial_velocity = pair[1]
		return

	var table: Array = CONFIGURATIONS[configuration]
	for i in range(bodies.size()):
		if i >= table.size():
			continue
		var entry: Array = table[i]
		bodies[i].initial_position = entry[0]
		bodies[i].initial_velocity = entry[1]

func _physics_process(delta: float) -> void:
	if paused:
		return

	# Auto-rotate for dynamic 3D view
	rotation_time += delta
	rotation.y = sin(rotation_time * 0.2) * 0.4
	rotation.x = cos(rotation_time * 0.15) * 0.15

	# Apply gravitational forces between all bodies
	_apply_gravitational_forces(delta)

	# Update body positions and velocities
	_update_bodies(delta)

	# Update trails
	if trails_enabled:
		_update_trails()

	# Evidence overlay. Two string compares at the default, and no further work.
	if evidence == "axiom":
		_record_barycentre()
		_update_evidence()
	elif evidence == "longhand":
		_update_evidence()

func _apply_gravitational_forces(_delta) -> void:
	# Calculate gravitational forces between all pairs of bodies
	for i in range(bodies.size()):
		for j in range(i + 1, bodies.size()):
			var body1 = bodies[i]
			var body2 = bodies[j]
			
			var distance_vector = body2.position - body1.position
			var distance = distance_vector.length()
			
			if distance > 0.1:  # Avoid division by zero
				var force_magnitude = gravitational_constant * body1.body_mass * body2.body_mass / (distance * distance)
				var force_direction = distance_vector.normalized()
				
				# Apply equal and opposite forces
				body1.apply_force(force_direction * force_magnitude)
				body2.apply_force(-force_direction * force_magnitude)

func _update_bodies(delta) -> void:
	# Update each body's physics
	for body in bodies:
		body.update_physics(delta * time_scale)

func _update_trails() -> void:
	# Update trails for each body
	for body in bodies:
		body.update_trail()

# ═════════════════════════════════════════════════════════════════════════
# EVIDENCE — what is drawn of the motion
# ═════════════════════════════════════════════════════════════════════════

## Put the chosen evidence into effect.
##
## "trace" is the else-of-everything: trails on, no overlay node in existence.
## That is the shipped exhibit, so calling this at the default is the single
## assignment `trails_enabled = true` and nothing more.
func _apply_evidence() -> void:
	trails_enabled = (evidence == "trace")
	if not trails_enabled:
		for body in bodies:
			if body.trail_points.size() > 0:
				body.trail_points.clear()
				body._rebuild_trail_mesh()
	_bary_points = PackedVector3Array()

	if evidence == "trace" or evidence == "result":
		if _evidence_root != null:
			_evidence_root.visible = false
		return

	_ensure_evidence_root()
	_evidence_root.visible = true
	_slate.visible = (evidence == "axiom")
	_update_evidence()


## Built lazily, the first time a value other than trace/result asks for it.
func _ensure_evidence_root() -> void:
	if _evidence_root != null:
		return

	_evidence_root = Node3D.new()
	_evidence_root.name = "Evidence"
	add_child(_evidence_root)

	_evidence_mesh = ImmediateMesh.new()
	_evidence_instance = MeshInstance3D.new()
	_evidence_instance.name = "EvidenceLines"
	_evidence_instance.mesh = _evidence_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color.WHITE
	mat.no_depth_test = false
	_evidence_instance.material_override = mat
	_evidence_root.add_child(_evidence_instance)

	_slate = Label3D.new()
	_slate.name = "AxiomSlate"
	_slate.text = "F(i,j) = G m(i) m(j) / r^2\nno closed form for three  (Poincare, 1890)\nthe barycentre is the only straight line"
	_slate.font_size = 40
	_slate.pixel_size = 0.055
	_slate.outline_size = 8
	_slate.outline_modulate = Color.BLACK
	_slate.modulate = Color(1.0, 0.85, 0.35)
	_slate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_slate.position = Vector3(0.0, 0.0, 10.5)
	_slate.visible = false
	_evidence_root.add_child(_slate)


func _update_evidence() -> void:
	if _evidence_mesh == null:
		return
	_evidence_mesh.clear_surfaces()
	if bodies.size() < 2:
		return

	_evidence_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	if evidence == "longhand":
		_emit_longhand()
	else:
		_emit_axiom()
	_evidence_mesh.surface_end()


func _line(a: Vector3, b: Vector3, c: Color) -> void:
	_evidence_mesh.surface_set_color(c)
	_evidence_mesh.surface_add_vertex(a)
	_evidence_mesh.surface_set_color(c)
	_evidence_mesh.surface_add_vertex(b)


## An in-plane perpendicular to `d`. The bodies move in XZ, so UP is almost never
## parallel; FORWARD is the fallback for the case where it is.
func _perpendicular(d: Vector3) -> Vector3:
	var n: Vector3 = d.normalized()
	var p: Vector3 = n.cross(Vector3.UP)
	if p.length() < 0.01:
		p = n.cross(Vector3.FORWARD)
	return p.normalized()


## The working: every pair connected, each connector wearing a crossbar sized by
## the force in that pair, and on each body the resultant of the two pulls.
## Forces span four orders of magnitude as r closes, so the sizes are log-scaled —
## the bar reads as "which pull is winning", not as a metric length.
func _emit_longhand() -> void:
	var pair_color := Color(1.0, 1.0, 1.0, 0.30)
	for i in range(bodies.size()):
		for j in range(i + 1, bodies.size()):
			var a: Vector3 = bodies[i].position
			var b: Vector3 = bodies[j].position
			_line(a, b, pair_color)

			var d: Vector3 = b - a
			var r: float = maxf(d.length(), 0.001)
			var f: float = gravitational_constant * bodies[i].body_mass * bodies[j].body_mass / (r * r)
			var bar: float = clampf(log(1.0 + f) * 0.18, 0.15, 1.6)
			var mid: Vector3 = a + d * 0.5
			var perp: Vector3 = _perpendicular(d)
			_line(mid - perp * bar, mid + perp * bar, Color(1.0, 0.9, 0.5, 0.9))

	for i in range(bodies.size()):
		var net: Vector3 = Vector3.ZERO
		for j in range(bodies.size()):
			if i == j:
				continue
			var dv: Vector3 = bodies[j].position - bodies[i].position
			var rr: float = maxf(dv.length(), 0.001)
			var fm: float = gravitational_constant * bodies[i].body_mass * bodies[j].body_mass / (rr * rr)
			net += dv.normalized() * fm

		var mag: float = net.length()
		if mag < 0.0001:
			continue
		var dir: Vector3 = net / mag
		var arrow_len: float = clampf(log(1.0 + mag) * 0.42, 0.4, 5.0)
		var origin: Vector3 = bodies[i].position
		var tip: Vector3 = origin + dir * arrow_len
		var col: Color = bodies[i].body_color
		col.a = 0.95
		_line(origin, tip, col)
		var back: Vector3 = -dir * (arrow_len * 0.22)
		var side: Vector3 = _perpendicular(dir) * (arrow_len * 0.12)
		_line(tip, tip + back + side, col)
		_line(tip, tip + back - side, col)


## The rule the three of them are an instance of: the barycentre, its spokes, and
## its own track — which stays straight (or, when the total momentum is zero, a
## single point) through every configuration, including near_collision.
func _emit_axiom() -> void:
	var c: Vector3 = _barycentre()
	var gold := Color(1.0, 0.85, 0.35, 1.0)
	var s: float = 0.7
	_line(c - Vector3(s, 0.0, 0.0), c + Vector3(s, 0.0, 0.0), gold)
	_line(c - Vector3(0.0, s, 0.0), c + Vector3(0.0, s, 0.0), gold)
	_line(c - Vector3(0.0, 0.0, s), c + Vector3(0.0, 0.0, s), gold)

	for body in bodies:
		var col: Color = body.body_color
		col.a = 0.22
		_line(body.position, c, col)

	var n: int = _bary_points.size()
	if n >= 2:
		for i in range(n - 1):
			var t: float = float(i) / float(n - 1)
			_line(_bary_points[i], _bary_points[i + 1],
				Color(gold.r, gold.g, gold.b, 0.25 + t * 0.75))


func _barycentre() -> Vector3:
	var total: float = 0.0
	var acc: Vector3 = Vector3.ZERO
	for body in bodies:
		var m: float = maxf(body.body_mass, 0.0001)
		acc += body.position * m
		total += m
	if total <= 0.0:
		return Vector3.ZERO
	return acc / total


func _record_barycentre() -> void:
	var c: Vector3 = _barycentre()
	var n: int = _bary_points.size()
	if n > 0 and _bary_points[n - 1].distance_to(c) < 0.02:
		return
	_bary_points.append(c)
	if _bary_points.size() > BARY_TRACK_MAX:
		_bary_points = _bary_points.slice(1)


func _connect_ui() -> void:
	var reset_btn = get_node_or_null("UI/VBoxContainer/ResetButton")
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
	var pause_btn = get_node_or_null("UI/VBoxContainer/PauseButton")
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_pressed)
	var trail_btn = get_node_or_null("UI/VBoxContainer/TrailToggle")
	if trail_btn:
		trail_btn.pressed.connect(_on_trail_toggle_pressed)
	var mass_slider = get_node_or_null("UI/VBoxContainer/MassSlider")
	if mass_slider:
		mass_slider.value_changed.connect(_on_mass_changed)

func _on_reset_pressed() -> void:
	# Reset all bodies to initial positions (CelestialBody.reset_to_initial
	# already clears trail_points and rebuilds the ImmediateMesh)
	for body in bodies:
		body.reset_to_initial()
	# The barycentre track is history too, and resets with everything else.
	_bary_points = PackedVector3Array()

func _on_pause_pressed() -> void:
	paused = !paused
	var pause_btn = get_node_or_null("UI/VBoxContainer/PauseButton")
	if pause_btn:
		pause_btn.text = "Resume" if paused else "Pause"

func _on_trail_toggle_pressed() -> void:
	trails_enabled = !trails_enabled
	var trail_btn = get_node_or_null("UI/VBoxContainer/TrailToggle")
	if trail_btn:
		trail_btn.text = "Trails: " + ("ON" if trails_enabled else "OFF")
	
	if !trails_enabled:
		# Clear trails by resetting each body's trail data
		for body in bodies:
			body.trail_points.clear()
			body._rebuild_trail_mesh()

func _on_mass_changed(value: float) -> void:
	# Update mass of all bodies
	for body in bodies:
		body.body_mass = value

	# Update UI label
	var mass_label = get_node_or_null("UI/VBoxContainer/MassLabel")
	if mass_label:
		mass_label.text = "Mass: " + str(int(value))

func _apply_vibrant_colors() -> void:
	# Apply vibrant queer colors to celestial bodies.
	# CelestialBody.set_trail_color() handles both body mesh and trail material.
	for i in range(bodies.size()):
		var body: CelestialBody = bodies[i] as CelestialBody
		if body == null:
			continue
		var color: Color = queer_colors[i % queer_colors.size()]
		body.set_trail_color(color)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config_data: Dictionary) -> void:
	# Each axis is guarded on its own key AND on the value actually changing.
	# Reacting unconditionally here would restart the simulation of every existing
	# placement the moment any unrelated config key arrived.
	if config_data.has("configuration"):
		var wanted: String = str(config_data["configuration"])
		# An unknown value, or the value already in force, changes nothing.
		if wanted != configuration and (wanted == "pinwheel" or CONFIGURATIONS.has(wanted)):
			configuration = wanted
			# Before _ready: the export is enough, _initialize_bodies will read it.
			if not bodies.is_empty():
				_apply_configuration()
				for body in bodies:
					body.reset_to_initial()
				_bary_points = PackedVector3Array()

	if config_data.has("evidence"):
		var wanted_evidence: String = str(config_data["evidence"])
		if wanted_evidence != evidence and wanted_evidence in EVIDENCE_VALUES:
			evidence = wanted_evidence
			# Before _ready: the export is enough, _apply_evidence runs there.
			# After: this only turns trails on/off and redraws the overlay — no
			# body is moved and the simulation is not restarted.
			if not bodies.is_empty():
				_apply_evidence()
