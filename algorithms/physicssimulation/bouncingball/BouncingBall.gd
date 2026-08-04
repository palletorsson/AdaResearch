## Bouncing Ball — RigidBody3D balls with PhysicsMaterial bounce
## Godot handles ALL physics: gravity, collision, bouncing
## Visible wireframe cube containment so you can see the box
##
## @identity
## essence: Bounded chamber of bouncing balls — physics engine handles gravity, collision, restitution; we only set initial conditions
## desire: To let the player watch deterministic physics produce apparent randomness through accumulating collision micro-differences
## critical_parameter: ball_count and PhysicsMaterial.bounce — together they decide whether the box becomes still, periodic, or chaotic
## triggers: Low count and low bounce settles to floor; high count with high bounce becomes a pseudo-gas inside the cube
## emerges: Newton's laws as the engine, visible cube as the stage — the chamber's regularity reveals each ball's path as deviation
## needs: RigidBody3D physics [has], wireframe cube containment [has], spawn height tuning [has], the decay envelope [has, evidence axis]
## relationships: Companion to NewtonsLaws — same physics, different demonstration. Both anchor forces/Newton's_Laws map
## truth: A bounce is not random — it is the moment when constraint becomes visible, when geometry refuses to let the ball pass.
extends Node3D

# STAGE-2 DNA PROMOTION (2026-08-03). This artifact had zero exports the sweep
# could turn — ball_count and spawn_height are counts, not arguments — and was
# refused for NO TURNABLE KNOBS.
#
#   regime     what coefficient of      mixed · elastic · dead · inelastic
#              restitution the chamber
#              is actually running
#   evidence   what the chamber offers  result · trace · longhand · axiom
#              as PROOF of that
#
# WHY THESE TWO AND NOT `bounce` ALONE. The registry's own capacity line is
# "SEE that the bounce coefficient controls how much chaos (energy) survives
# each collision", and the description promises "at e=1.0 ... bounces forever.
# Below 1.0, each impact dissipates energy". Neither is visible in a still. A
# photograph of this chamber catches one arbitrary instant of six balls in
# flight; restitution is not a position, it is the ENVELOPE of successive apex
# heights, h(n+1) = e^2 h(n), and an envelope is a thing you have to draw.
#
# So `evidence` draws it — the same family word, with the same four values, that
# example_2_3, example_2_8, three_body_problem, koch_curve, sine_wave_controller
# and wave_interference_tank already use for "what does this exhibit offer as
# proof". And the envelope is PREDICTED at build time from each ball's own e,
# not accumulated from watching: it is on the geometry the moment the artifact
# exists, exactly as catapult's `foresight` draws the parabola before the throw.
# Nothing here waits for the simulation to produce it.
#
# `regime` then has something to turn. It is mass_spring_damper's question one
# artifact along — that bench asks which DAMPING regime the row is in, this one
# asks which RESTITUTION regime, and the value list cannot be shared because the
# named cases are different (there is no "critically bouncing"). The word is
# taken from the sibling; the values are this artifact's own.
#
# The physics is Godot's in all four regimes. _integrate_forces is not
# overridden, there is no per-frame code, and nothing here touches gravity.
# What changes is one float on a PhysicsMaterial.
#
# Usage in map_data.json:
#   "bouncing_ball#evidence:trace"
#   "bouncing_ball#regime:elastic#evidence:longhand"

@export var ball_count: int = 6
@export var spawn_height: float = 5.0

## Cube dimensions
const CUBE_HALF := 4.0   # half-width of containment cube
const CUBE_HEIGHT := 6.0  # total height of cube

## Edge style
@export var edge_color: Color = Color(0.4, 0.7, 1.0, 0.6)
@export var edge_thickness: float = 0.03

## Which coefficient of restitution the chamber is running.
##   mixed:     the shipped chamber. Every ball draws its own e from
##              randf_range(0.6, 0.95) and the box keeps floor 0.5 / walls 0.7,
##              so six different decay rates share one room. This is the ONLY
##              value that touches the random draw or leaves the container
##              materials alone, and it is the default.
##   elastic:   e = 1.0 everywhere, ball and box. Perfectly elastic — no energy
##              leaves the system, the envelope is a flat line, the balls never
##              come down for good. The limit case the description promises.
##   dead:      e = 0.0 everywhere. Perfectly inelastic: the first impact keeps
##              nothing. Six balls fall once and stay where they land.
##   inelastic: e = 0.55 everywhere. The textbook middle — every ball loses the
##              same fraction, so the six envelopes lie on top of each other and
##              the decay is legible as ONE curve instead of six.
@export_enum("mixed", "elastic", "dead", "inelastic") var regime: String = "mixed"

## What the chamber offers as proof of the restitution it is running.
##   result:   the shipped build. Six balls in a wireframe box and nothing else —
##            the answer with the working thrown away. Not one extra node is
##            constructed at this value.
##   trace:    the decay envelope, predicted from each ball's own e and drawn on
##            the back plane of the box: apex n against height h(n) = h0 e^(2n),
##            one polyline per ball in that ball's colour. The history the bounce
##            is going to have, drawn before it has it.
##   longhand: the working instead of the answer. Under each ball's column, the
##            pair of arrows the collision actually is — the incoming speed and
##            the outgoing speed, whose ratio IS e — and above them the first two
##            apex rungs, whose ratio is e^2. The squaring is on the geometry.
##   axiom:    no per-ball marks. A slate carrying v' = -e v and h(n+1) = e^2 h(n),
##            and the one line the chamber cannot cross: the height it started
##            from, which only e = 1 gets to keep.
@export_enum("result", "trace", "longhand", "axiom") var evidence: String = "result"

## Pins the unseeded draws (radius, restitution, spawn point, initial nudge) so a
## sweep measures the axes and not the paintwork. -1 is the shipped behaviour: the
## global RNG, a new chamber every launch.
@export var ball_seed: int = -1

const REGIME_VALUES := ["mixed", "elastic", "dead", "inelastic"]
const EVIDENCE_VALUES := ["result", "trace", "longhand", "axiom"]

## How many apexes the envelope predicts. Six is where h0 * 0.6^12 has already
## fallen below a pixel, and it keeps the chart inside the box's own extent so the
## capture framing never changes.
const BOUNCES: int = 6

var balls: Array[RigidBody3D] = []

var queer_colors := [
	Color(1.0, 0.4, 0.7),   # Hot pink
	Color(0.8, 0.3, 1.0),   # Purple
	Color(0.3, 0.9, 1.0),   # Cyan
	Color(1.0, 0.8, 0.2),   # Gold
	Color(0.5, 1.0, 0.4),   # Lime
	Color(1.0, 0.5, 0.3),   # Coral
	Color(0.4, 0.7, 1.0),   # Sky blue
	Color(1.0, 0.3, 0.5),   # Rose
]

## Per ball: {"x", "z", "h0", "e", "color"} — what the envelope is drawn FROM.
var _ball_specs: Array = []
var _container: Array = []
var _rng: RandomNumberGenerator = null
var _ev_root: Node3D = null
var _ev_mesh: ImmediateMesh = null
var _slate: Label3D = null
var _built: bool = false

func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_seed_rng()
	_create_containment()
	_create_visible_cube()
	_spawn_balls()
	_built = true
	_apply_evidence()

## Only when a seed was asked for. At -1 every _rf() call falls through to the
## global randf_range, which is character for character what shipped.
func _seed_rng() -> void:
	if ball_seed >= 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = ball_seed
	else:
		_rng = null

func _rf(a: float, b: float) -> float:
	if _rng != null:
		return _rng.randf_range(a, b)
	return randf_range(a, b)

## The restitution every surface runs at, outside `mixed`. Never called at the
## default: `mixed` is guarded at both call sites, so the shipped 0.5 floor,
## 0.7 walls and randf_range(0.6, 0.95) balls are untouched.
func _regime_bounce() -> float:
	match regime:
		"elastic":
			return 1.0
		"dead":
			return 0.0
		"inelastic":
			return 0.55
	return 0.5

func _create_containment() -> void:
	_container.clear()
	# Outside `mixed` the BOX has to agree with the balls. Godot combines the two
	# PhysicsMaterials, so leaving a 0.5 floor under a dead ball would still bounce
	# it — the axis would be declared and only half real.
	var floor_bounce: float = 0.5
	var wall_bounce: float = 0.7
	if regime != "mixed":
		floor_bounce = _regime_bounce()
		wall_bounce = _regime_bounce()

	# Floor
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(CUBE_HALF * 2, 0.2, CUBE_HALF * 2)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)

	var floor_mat := PhysicsMaterial.new()
	floor_mat.bounce = floor_bounce
	floor_body.physics_material_override = floor_mat
	add_child(floor_body)
	_container.append(floor_body)

	# Ceiling
	var ceil_body := StaticBody3D.new()
	var ceil_col := CollisionShape3D.new()
	var ceil_shape := BoxShape3D.new()
	ceil_shape.size = Vector3(CUBE_HALF * 2, 0.2, CUBE_HALF * 2)
	ceil_col.shape = ceil_shape
	ceil_body.add_child(ceil_col)
	ceil_body.position = Vector3(0, CUBE_HEIGHT + 0.1, 0)

	var ceil_mat := PhysicsMaterial.new()
	ceil_mat.bounce = wall_bounce
	ceil_body.physics_material_override = ceil_mat
	add_child(ceil_body)
	_container.append(ceil_body)

	# Walls (invisible collision)
	for wall_data in [
		[Vector3(CUBE_HALF, CUBE_HEIGHT / 2.0, 0), Vector3(0.2, CUBE_HEIGHT, CUBE_HALF * 2)],
		[Vector3(-CUBE_HALF, CUBE_HEIGHT / 2.0, 0), Vector3(0.2, CUBE_HEIGHT, CUBE_HALF * 2)],
		[Vector3(0, CUBE_HEIGHT / 2.0, CUBE_HALF), Vector3(CUBE_HALF * 2, CUBE_HEIGHT, 0.2)],
		[Vector3(0, CUBE_HEIGHT / 2.0, -CUBE_HALF), Vector3(CUBE_HALF * 2, CUBE_HEIGHT, 0.2)],
	]:
		var wall := StaticBody3D.new()
		var wcol := CollisionShape3D.new()
		var wshape := BoxShape3D.new()
		wshape.size = wall_data[1]
		wcol.shape = wshape
		wall.add_child(wcol)
		wall.position = wall_data[0]

		var wmat := PhysicsMaterial.new()
		wmat.bounce = wall_bounce
		wall.physics_material_override = wmat
		add_child(wall)
		_container.append(wall)

## Visible wireframe cube — 12 edges as thin glowing cylinders
func _create_visible_cube() -> void:
	var w := CUBE_HALF
	var h := CUBE_HEIGHT

	# Material for all edges
	var mat := StandardMaterial3D.new()
	mat.albedo_color = edge_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(edge_color.r, edge_color.g, edge_color.b)
	mat.emission_energy_multiplier = 0.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# The 8 corners of the cube: bottom y=0, top y=h
	var corners := [
		Vector3(-w, 0, -w), Vector3( w, 0, -w), Vector3( w, 0,  w), Vector3(-w, 0,  w),  # bottom
		Vector3(-w, h, -w), Vector3( w, h, -w), Vector3( w, h,  w), Vector3(-w, h,  w),  # top
	]

	# 12 edges: 4 bottom, 4 top, 4 vertical
	var edges := [
		# Bottom square
		[corners[0], corners[1]], [corners[1], corners[2]],
		[corners[2], corners[3]], [corners[3], corners[0]],
		# Top square
		[corners[4], corners[5]], [corners[5], corners[6]],
		[corners[6], corners[7]], [corners[7], corners[4]],
		# Vertical pillars
		[corners[0], corners[4]], [corners[1], corners[5]],
		[corners[2], corners[6]], [corners[3], corners[7]],
	]

	for i in range(edges.size()):
		var a: Vector3 = edges[i][0]
		var b: Vector3 = edges[i][1]
		_add_edge(a, b, mat, i)

	# Transparent floor panel so you can see the base
	var floor_vis := MeshInstance3D.new()
	floor_vis.name = "FloorPanel"
	var plane := PlaneMesh.new()
	plane.size = Vector2(w * 2, w * 2)
	floor_vis.mesh = plane

	var floor_vis_mat := StandardMaterial3D.new()
	floor_vis_mat.albedo_color = Color(0.2, 0.3, 0.5, 0.12)
	floor_vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_vis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_vis.material_override = floor_vis_mat
	floor_vis.position = Vector3(0, 0.01, 0)
	add_child(floor_vis)

func _add_edge(a: Vector3, b: Vector3, mat: StandardMaterial3D, idx: int) -> void:
	var edge := MeshInstance3D.new()
	edge.name = "Edge_%d" % idx

	var length := a.distance_to(b)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = edge_thickness
	cylinder.bottom_radius = edge_thickness
	cylinder.height = length
	cylinder.radial_segments = 4
	edge.mesh = cylinder
	edge.material_override = mat

	# Position at midpoint
	edge.position = (a + b) / 2.0

	# Orient cylinder along edge direction using Basis (same as cube_lines / line_static)
	var direction := (b - a).normalized()
	if direction.length() > 0.001:
		var up := Vector3.UP
		var right := direction.cross(up).normalized()
		if right.length() < 0.001:
			# Direction is parallel to UP — use a different reference
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()
		edge.transform.basis = Basis(right, direction, up)

	add_child(edge)

func _spawn_balls() -> void:
	_ball_specs.clear()
	for i in range(ball_count):
		var rb := RigidBody3D.new()
		rb.name = "Ball_%d" % i

		var radius := _rf(0.2, 0.4)
		rb.mass = radius * 3.0  # Heavier balls are bigger

		# Collision
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = radius
		col.shape = shape
		rb.add_child(col)

		# Visual
		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2.0
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		var color: Color = queer_colors[i % queer_colors.size()]
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.4
		mat.emission_energy_multiplier = 1.5
		mat.metallic = 0.3
		mat.roughness = 0.4
		mesh_inst.material_override = mat
		rb.add_child(mesh_inst)

		# Physics material — different bounce per ball
		#
		# The two draws happen at EVERY regime, spent or not, so the random stream
		# that positions the balls below is the same one it has always been.
		var phys_mat := PhysicsMaterial.new()
		var ball_bounce: float = _rf(0.6, 0.95)
		var ball_friction: float = _rf(0.1, 0.5)
		if regime != "mixed":
			ball_bounce = _regime_bounce()
			ball_friction = 0.2
		phys_mat.bounce = ball_bounce
		phys_mat.friction = ball_friction
		rb.physics_material_override = phys_mat

		# Random spawn position
		rb.position = Vector3(
			_rf(-2.5, 2.5),
			spawn_height + i * 0.8,
			_rf(-2.5, 2.5)
		)

		# Small random initial velocity
		rb.linear_velocity = Vector3(
			_rf(-1, 1),
			0,
			_rf(-1, 1)
		)

		add_child(rb)
		balls.append(rb)
		_ball_specs.append({
			"x": rb.position.x,
			"z": rb.position.z,
			"h0": rb.position.y,
			"e": ball_bounce,
			"color": color,
		})

func reset() -> void:
	for ball in balls:
		ball.queue_free()
	balls.clear()
	_spawn_balls()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ═════════════════════════════════════════════════════════════════════════
# EVIDENCE — the envelope the bounce is going to have
# ═════════════════════════════════════════════════════════════════════════

## Nothing exists at `result`. The overlay is built the first time a value other
## than result asks for it, so the six shipped placements construct exactly the
## nodes they always did.
func _apply_evidence() -> void:
	if evidence == "result":
		if _ev_root != null:
			_ev_root.visible = false
		return
	_ensure_ev_root()
	_ev_root.visible = true
	_slate.visible = (evidence == "axiom")
	_redraw_evidence()

func _ensure_ev_root() -> void:
	if _ev_root != null:
		return
	_ev_root = Node3D.new()
	_ev_root.name = "Evidence"
	add_child(_ev_root)

	_ev_mesh = ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.name = "EnvelopeLines"
	mi.mesh = _ev_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color.WHITE
	mi.material_override = mat
	_ev_root.add_child(mi)

	_slate = Label3D.new()
	_slate.name = "AxiomSlate"
	_slate.text = "v' = -e v\nh(n+1) = e^2 h(n)\ne = 1 keeps everything, e = 0 keeps nothing"
	_slate.font_size = 40
	_slate.pixel_size = 0.0075
	_slate.outline_size = 8
	_slate.outline_modulate = Color.BLACK
	_slate.modulate = Color(1.0, 0.85, 0.35)
	_slate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_slate.position = Vector3(0.0, CUBE_HEIGHT * 0.66, -CUBE_HALF * 0.5)
	_slate.visible = false
	_ev_root.add_child(_slate)

func _redraw_evidence() -> void:
	if _ev_mesh == null:
		return
	_ev_mesh.clear_surfaces()
	if _ball_specs.is_empty():
		return
	_ev_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_emit_baseline()
	match evidence:
		"trace":
			_emit_trace()
		"longhand":
			_emit_longhand()
		"axiom":
			_emit_axiom()
	_ev_mesh.surface_end()

func _line(a: Vector3, b: Vector3, c: Color) -> void:
	_ev_mesh.surface_set_color(c)
	_ev_mesh.surface_add_vertex(a)
	_ev_mesh.surface_set_color(c)
	_ev_mesh.surface_add_vertex(b)

## The tallest ball, so the chart normalises into the box it is drawn on and the
## capture AABB never grows past the wireframe that was already there.
func _tallest() -> float:
	var m: float = 0.001
	for s in _ball_specs:
		var spec: Dictionary = s
		m = maxf(m, float(spec["h0"]))
	return m

func _chart_z() -> float:
	return -CUBE_HALF + 0.08

func _chart_w() -> float:
	return CUBE_HALF * 0.88

func _chart_top() -> float:
	return CUBE_HEIGHT * 0.9

## The floor of the chart. Every value gets it: without a zero line an envelope
## is a shape, and with one it is a measurement.
func _emit_baseline() -> void:
	var w: float = _chart_w()
	var z: float = _chart_z()
	_line(Vector3(-w, 0.02, z), Vector3(w, 0.02, z), Color(0.55, 0.62, 0.75, 0.5))

## Apex n against apex height, h(n) = h0 * e^(2n), one polyline per ball.
func _emit_trace() -> void:
	var w: float = _chart_w()
	var z: float = _chart_z()
	var top: float = _chart_top()
	var hmax: float = _tallest()
	for s in _ball_specs:
		var spec: Dictionary = s
		var e: float = float(spec["e"])
		var h0: float = float(spec["h0"])
		var col: Color = spec["color"]
		var prev := Vector3.ZERO
		for n in range(BOUNCES + 1):
			var t: float = float(n) / float(BOUNCES)
			var hn: float = h0 * pow(e * e, float(n))
			var p := Vector3(lerpf(-w, w, t), hn / hmax * top, z)
			# the apex mark: a short rung, so a flat envelope still reads as
			# SEVEN bounces at one height and not as one straight line
			_line(p - Vector3(0.12, 0.0, 0.0), p + Vector3(0.12, 0.0, 0.0), col)
			if n > 0:
				var faded := Color(col.r, col.g, col.b, 0.8)
				_line(prev, p, faded)
			prev = p

## The working: the collision itself, drawn as the two speeds it relates.
## v_in = sqrt(2 g h0) and v_out = e * v_in, side by side under each ball's
## column — the ratio of the two arrows IS e. Above them the first two apex
## rungs, whose ratio is e squared. One squaring, drawn twice.
func _emit_longhand() -> void:
	var w: float = _chart_w()
	var z: float = _chart_z()
	var top: float = _chart_top()
	var hmax: float = _tallest()
	var n: int = _ball_specs.size()
	var vmax: float = sqrt(2.0 * 9.8 * hmax)
	for i in range(n):
		var spec: Dictionary = _ball_specs[i]
		var e: float = float(spec["e"])
		var h0: float = float(spec["h0"])
		var col: Color = spec["color"]
		var t: float = 0.5 if n < 2 else float(i) / float(n - 1)
		var x: float = lerpf(-w * 0.9, w * 0.9, t)

		var v_in: float = sqrt(2.0 * 9.8 * h0)
		var arrow_full: float = top * 0.42
		var down_len: float = v_in / vmax * arrow_full
		var up_len: float = down_len * e

		# incoming: an arrow falling INTO the floor, just left of the column
		_arrow(Vector3(x - 0.22, down_len, z), Vector3(x - 0.22, 0.03, z), col)
		# outgoing: what the collision gives back, just right of it
		var back := Color(col.r, col.g, col.b, 0.95)
		_arrow(Vector3(x + 0.22, 0.03, z), Vector3(x + 0.22, up_len, z), back)

		# and the consequence: two rungs whose ratio is e^2
		var y0: float = h0 / hmax * top
		var y1: float = y0 * e * e
		var rung := Color(1.0, 0.9, 0.55, 0.75)
		_line(Vector3(x - 0.34, y0, z), Vector3(x + 0.34, y0, z), rung)
		_line(Vector3(x - 0.34, y1, z), Vector3(x + 0.34, y1, z), rung)
		_line(Vector3(x, y1, z), Vector3(x, y0, z), Color(1.0, 0.9, 0.55, 0.28))

## The rule, not the instance: the slate, plus the one line the chamber cannot
## cross. Total mechanical energy at release is a ceiling; only e = 1 keeps it.
func _emit_axiom() -> void:
	var w: float = _chart_w()
	var z: float = _chart_z()
	var top: float = _chart_top()
	var gold := Color(1.0, 0.85, 0.35, 0.9)
	_line(Vector3(-w, top, z), Vector3(w, top, z), gold)
	var faint := Color(1.0, 0.85, 0.35, 0.3)
	var i: int = 0
	while i < 12:
		var x: float = lerpf(-w, w, float(i) / 11.0)
		_line(Vector3(x, top, z), Vector3(x, top - 0.18, z), faint)
		i += 1

func _arrow(from_p: Vector3, to_p: Vector3, col: Color) -> void:
	_line(from_p, to_p, col)
	var d: Vector3 = to_p - from_p
	var l: float = d.length()
	if l < 0.001:
		return
	var dir: Vector3 = d / l
	var head: float = minf(l * 0.3, 0.22)
	var side := Vector3(head * 0.6, 0.0, 0.0)
	_line(to_p, to_p - dir * head + side, col)
	_line(to_p, to_p - dir * head - side, col)


# ═════════════════════════════════════════════════════════════════════════
# CONFIG — guarded: nothing rebuilds unless a value actually changed
# ═════════════════════════════════════════════════════════════════════════

func _pick(value, allowed: Array, fallback: String) -> String:
	var s: String = str(value).strip_edges().to_lower()
	if allowed.has(s):
		return s
	return fallback

func apply_grid_config(config: Dictionary) -> void:
	var want_regime: String = regime
	var want_evidence: String = evidence
	var want_seed: int = ball_seed

	if config.has("regime"):
		want_regime = _pick(config["regime"], REGIME_VALUES, regime)
	if config.has("evidence"):
		want_evidence = _pick(config["evidence"], EVIDENCE_VALUES, evidence)
	if config.has("ball_seed"):
		want_seed = int(config["ball_seed"])
	var want_count: int = ball_count
	var want_height: float = spawn_height
	if config.has("ball_count"):
		want_count = int(config["ball_count"])
	if config.has("spawn_height"):
		want_height = float(config["spawn_height"])

	var regime_changed: bool = false
	if want_regime != regime:
		regime_changed = true
	if want_seed != ball_seed:
		regime_changed = true
	if want_count != ball_count:
		regime_changed = true
	if not is_equal_approx(want_height, spawn_height):
		regime_changed = true
	ball_count = want_count
	spawn_height = want_height
	var evidence_changed: bool = want_evidence != evidence
	regime = want_regime
	evidence = want_evidence
	ball_seed = want_seed

	# Before _ready the exports are enough — _ready builds once, with them.
	if not _built:
		return
	if not regime_changed and not evidence_changed:
		return

	if regime_changed:
		_seed_rng()
		# the box has to agree with the balls, so both are rebuilt
		for body in _container:
			if is_instance_valid(body):
				body.queue_free()
		_container.clear()
		_create_containment()
		reset()
	_apply_evidence()
