extends Node3D
class_name KleeWalkingPoint

# @identity
# essence: a single luminous point that sets itself in motion and leaves a trail of points behind it — and the trail IS a line. Straight off the first page of Klee's Pedagogical Sketchbook: "an active line on a walk, moving freely, without a goal. A walk for a walk's sake." The point crosses an invisible sheet of paper hung in the lab, draws its line out of nothing, holds the finished line for a beat, dims, and walks again. The line is never given — it is always the RECORD of a point that moved.
# desire: the point wants to prove the line is not a primitive. The line is a biography. It wants the player to stop seeing "line" as a thing and start seeing it as a verb — a walk, a duration, a decision repeated. It wants to put Klee in drag: the walk that wanders (meander) against the walk marched to its destination (straight), and to make the wander obviously the richer line.
# critical_parameter: walk_style. "meander" is the queer line — the point wanders by summed sines, no goal, no shortest path. "straight" is the collapsed line — the normalized route that learned nothing on the way. "spiral" and "arc" sit between. Switching walk_style switches between difference and mode-collapse. trail_points sets how finely the walk quantises into its constituent points — the discrete pretending to be continuous.
# triggers: _ready builds the dim point-trail plus the bright walking head; _process advances the walk, lights each point as the head passes it, holds, loops; apply_grid_config rebuilds on DNA change.
# emerges: watched once it teaches point -> line. Watched as a loop it teaches that EVERY line in the whole VR world is a frozen walk. Place a "straight" one beside a "meander" one and the project's core dialectic is staged with no words: the straight line is the line that gave up.
# needs: an invisible drawing plane [the local XY plane]; a point that moves [head, present]; a trail that records the moving [point-string, present]; a loop so the becoming repeats [present]
# relationships: child of `origin` and `static_point` (they are the point at rest, this is the point in motion); ancestor of every line / curve / path / L-system downstream; cousin to `seurat_dot` (both build the continuous out of the discrete); the literal hinge of the Primitives sequence — the map Point_Line is this artifact made architecture.
# truth: a point is position without extension; a line is a point that refused to stay still. Klee knew drawing is time made visible. In a world built from Vector3 this is the most honest object in the lab: it shows you the geometry you walk through is not a set of shapes but a set of MOVES, and that the straightest move is the one that learned the least.

## Klee's walking point — the point that becomes a line.
##
## Built procedurally. Origin is the START of the walk. The line is
## drawn in the local XY plane, so hang it like a picture (front faces
## +Z by default). The trail is a string of small points that light up
## one by one as the bright head passes them: the line literally made
## of points, the discrete becoming the continuous.

# ── DNA ───────────────────────────────────────────────────────────────

# --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
# THE PROBLEM. This is the project's founding image, in 20 maps, and every one of
# the 20 is the same picture: an open ochre meander. walk_style was already an
# export and already this file's own declared critical_parameter, but it was a
# free String nothing enumerated, so the sweep read the artifact as having no
# turnable knob and no map ever named a value. The artifact argues that a line is
# a biography, and shipped exactly one biography.
#
# WHY THESE TWO AND NOT "how fast" or "how far". The evidence for an axis here is
# ONE STILL. Speed, hold, the loop, and the lit-up-to-here head are all time —
# a still cannot tell 0.32 from 0.9, so promoting them would produce a
# finished-looking experiment answering nothing. Both axes below are properties
# of the trail as a STANDING OBJECT: they survive the shutter.
#
# walk_style — WHAT THE WALK DID, the shape the line records. Unchanged in
#   meaning from the four branches _walk_path has always had; the promotion only
#   enumerates them so a map can name one:
#     meander   SHIPPED. Three summed sines, no goal, no shortest path.
#     straight  the collapsed line — the route that learned nothing on the way.
#     arc       a single hump: one decision, made once.
#     spiral    the walk that keeps turning inside its own territory.
#
# line — WHICH OF KLEE'S THREE LINE KINDS this is, taken from the Pedagogical
#   Sketchbook's own opening taxonomy rather than invented here. walk_style says
#   what the point DID; line says what the resulting mark IS, which is the
#   distinction Klee spends page one making and which this artifact has until now
#   only been able to state in half:
#     active   SHIPPED. The line that goes for a walk. Open, unresolved, and the
#              only kind whose two ends are not the same place.
#     medial   the line circumscribing a figure — the same walk closed on itself,
#              so it stops being a journey and becomes a boundary. The walk's own
#              deviation survives as the wobble of the enclosure, which is the
#              point: the medial line is not a circle, it is a walk that came back.
#     passive  the line as a plane's edge — the trail keeps its exact geometry and
#              a surface is raised to the floor beneath it, so the same points now
#              read as the top edge of something rather than as a path. Nothing
#              about the line changes; only what it is the boundary OF.
#   All three are one silhouette apart: open string, closed ring, filled field.
const WALK_STYLES: PackedStringArray = ["meander", "straight", "spiral", "arc"]
const LINE_KINDS: PackedStringArray = ["active", "medial", "passive"]

@export_group("Walk")
## "meander" (queer wander), "straight" (collapsed), "spiral", "arc".
@export_enum("meander", "straight", "spiral", "arc") var walk_style: String = "meander"
## Klee's three line kinds: the walk (active), the enclosure (medial), the
## edge of a plane (passive). "active" is the shipped behaviour exactly.
@export_enum("active", "medial", "passive") var line: String = "active"
@export var walk_length: float = 1.6
@export var walk_height: float = 0.6
## How many points the line is quantised into.
@export var trail_points: int = 48
## Walk progress per second (≈ loops/sec). 0.3 ≈ one walk every ~3s.
@export var walk_speed: float = 0.32
## Seconds the completed line is held before it dims and re-walks.
@export var hold_seconds: float = 0.9
@export var loop: bool = true

@export_group("Material")
@export var trail_color: Color = Color(0.95, 0.85, 0.30)   # Klee ochre
@export var head_color: Color = Color(1.0, 0.97, 0.85)
@export var trail_radius: float = 0.018
@export var head_radius: float = 0.040
@export var dim_energy: float = 0.10
@export var lit_energy: float = 2.2
## Only used at line == "passive": the plane the trail is the upper edge of.
@export var plane_color: Color = Color(0.30, 0.26, 0.20)

@export_group("Placement")
## When TRUE (default) the whole walk is shifted up so its LOWEST point
## rests on the floor (artifact origin = floor). Without this the walk is
## centred on the origin, so on a floor-placed instance the bottom half of
## the trail sinks below the floor. Set FALSE to hang it like a picture
## (centred on origin) on a wall.
@export var lift_to_floor: bool = true
## Small gap (m) kept between the lowest trail point and the floor when
## lift_to_floor is on, so it reads as resting ON the floor, not in it.
@export var floor_clearance: float = 0.03

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _points: PackedVector3Array = PackedVector3Array()
var _dot_mats: Array = []
var _head: MeshInstance3D = null
var _t: float = 0.0
var _phase: String = "walking"   # "walking" | "holding"
var _hold_timer: float = 0.0


func _ready() -> void:
	_read_metadata_overrides()
	_build()


## Guarded rebuild. This used to tear the artifact down and build it again on ANY
## call, including a call that changed nothing — which on a placement that merely
## re-announces its config restarted the walk from zero for no reason. It now
## compares a signature of every value the build actually reads and returns early
## when they are identical, so all 20 existing placements are untouched (none of
## them names a key at all) and a real DNA change still rebuilds.
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
	_built = false
	_dot_mats.clear()
	_head = null
	_build()


## Every value _build() reads, in one string. Not the animation state — a change
## of walk_speed or hold_seconds is honoured live by _process and must NOT throw
## the geometry away mid-walk.
func _config_signature() -> String:
	return "%s|%s|%.4f|%.4f|%d|%.4f|%.4f|%s|%s|%s" % [
		walk_style, line, walk_length, walk_height, trail_points,
		trail_radius, head_radius, str(lift_to_floor),
		str(trail_color), str(plane_color)]


func _read_metadata_overrides() -> void:
	if has_meta("config_walk_style"):
		var ws: String = str(get_meta("config_walk_style")).strip_edges().to_lower()
		if WALK_STYLES.has(ws):
			walk_style = ws
	if has_meta("config_line"):
		var lk: String = str(get_meta("config_line")).strip_edges().to_lower()
		if LINE_KINDS.has(lk):
			line = lk
	if has_meta("config_plane_color"):
		plane_color = _parse_color(str(get_meta("config_plane_color")), plane_color)
	if has_meta("config_hold_seconds"):
		hold_seconds = float(str(get_meta("config_hold_seconds")))
	if has_meta("config_loop"):
		# Parsed from a STRING on purpose. A typed bool export handed the token
		# parser's "true" rejects it before _ready ever runs; the conversion has
		# to happen here, where the value is still text.
		var lp: String = str(get_meta("config_loop")).strip_edges().to_lower()
		loop = lp == "true" or lp == "1" or lp == "yes"
	if has_meta("config_lift_to_floor"):
		var lf: String = str(get_meta("config_lift_to_floor")).strip_edges().to_lower()
		lift_to_floor = lf == "true" or lf == "1" or lf == "yes"
	if has_meta("config_walk_length"):
		walk_length = float(str(get_meta("config_walk_length")))
	if has_meta("config_walk_height"):
		walk_height = float(str(get_meta("config_walk_height")))
	if has_meta("config_trail_points"):
		trail_points = int(str(get_meta("config_trail_points")))
	if has_meta("config_walk_speed"):
		walk_speed = float(str(get_meta("config_walk_speed")))
	if has_meta("config_trail_color"):
		trail_color = _parse_color(str(get_meta("config_trail_color")), trail_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_points = _walk_path(walk_style)

	# Lift the whole walk so its lowest point sits ON the floor (artifact
	# origin = floor level). The walk is generated centred on the origin, so
	# without this the bottom half of the trail sinks below a floor-placed
	# instance. Shift by enough that even the larger head sphere clears.
	if lift_to_floor and _points.size() > 0:
		var min_y: float = _points[0].y
		for p in _points:
			min_y = minf(min_y, p.y)
		var shift: float = -min_y + floor_clearance + head_radius
		for i in range(_points.size()):
			_points[i] = _points[i] + Vector3(0.0, shift, 0.0)

	# Trail: one small sphere per sample point, each with its own
	# material so it can light independently as the head passes.
	var n: int = _points.size()
	for i in range(n):
		var dot := MeshInstance3D.new()
		dot.name = "Pt%d" % i
		var sm := SphereMesh.new()
		sm.radius = trail_radius
		sm.height = trail_radius * 2.0
		sm.radial_segments = 8
		sm.rings = 4
		dot.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = trail_color
		mat.emission_enabled = true
		mat.emission = trail_color
		mat.emission_energy_multiplier = dim_energy
		mat.roughness = 0.4
		dot.material_override = mat
		dot.position = _points[i]
		add_child(dot)
		_dot_mats.append(mat)

	# passive: Klee's third line kind — the line as the EDGE OF A PLANE. The trail
	# is not touched at all; a surface is raised underneath it, so exactly the same
	# points now read as a boundary rather than as a path. Built after the lift, so
	# the plane meets the floor instead of sinking through it.
	if line == "passive":
		_build_plane()

	# Head: the active point itself, brighter + larger.
	_head = MeshInstance3D.new()
	_head.name = "Head"
	var hm := SphereMesh.new()
	hm.radius = head_radius
	hm.height = head_radius * 2.0
	_head.mesh = hm
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = head_color
	head_mat.emission_enabled = true
	head_mat.emission = head_color
	head_mat.emission_energy_multiplier = lit_energy * 1.4
	head_mat.roughness = 0.2
	_head.material_override = head_mat
	if n > 0:
		_head.position = _points[0]
	add_child(_head)

	_t = 0.0
	_phase = "walking"
	_hold_timer = 0.0
	set_process(true)


# Generate the walk as a sequence of points in the local XY plane.
# All deterministic (summed sines) — no randf, no noise — so this is
# honest for sequence 1 (the grid is the only aesthetic this early).
func _walk_path(style: String) -> PackedVector3Array:
	if line == "medial":
		return _medial_path(style)
	var pts := PackedVector3Array()
	var n: int = maxi(2, trail_points)
	var half_l: float = walk_length * 0.5
	var amp: float = walk_height * 0.5
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		var x: float = -half_l + walk_length * t
		var y: float = 0.0
		match style:
			"straight":
				y = 0.0
			"arc":
				y = amp * sin(PI * t)
			"spiral":
				var r: float = (walk_length * 0.45) * t
				var ang: float = t * TAU * 2.0
				x = r * cos(ang)
				y = r * sin(ang)
			_:  # "meander" — Klee's wander, layered sines, no goal
				y = amp * (0.55 * sin(3.0 * PI * t)
					+ 0.30 * sin(7.0 * PI * t + 1.0)
					+ 0.18 * sin(11.0 * PI * t + 2.0))
		pts.append(Vector3(x, y, 0.0))
	return pts


# The MEDIAL line: the same walk, closed on itself so it circumscribes a figure.
# The walk's own deviation is kept and spent on the RADIUS, which is the whole
# point — a medial meander is not a circle, it is a walk that came back, and it
# still shows where it wandered. t runs i/n (not i/(n-1)) so the last point stops
# one step short of the first and the ring closes without two dots in one place.
# Deterministic summed sines, no randf and no noise: honest for sequence 1.
func _medial_path(style: String) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var n: int = maxi(3, trail_points)
	var base_r: float = walk_length * 0.30
	var amp: float = walk_height * 0.5
	for i in range(n):
		var t: float = float(i) / float(n)
		var dev: float = 0.0
		match style:
			"straight":
				dev = 0.0
			"arc":
				dev = amp * 0.5 * sin(TAU * t)
			"spiral":
				dev = amp * 0.7 * t
			_:  # "meander" — the wander, now spent on the enclosure's radius
				dev = amp * (0.35 * sin(3.0 * TAU * t)
					+ 0.18 * sin(7.0 * TAU * t + 1.0))
		var r: float = base_r + dev
		var ang: float = t * TAU
		pts.append(Vector3(r * cos(ang), r * sin(ang), 0.0))
	return pts


# The plane whose upper edge the trail is. One thin column per trail point, run
# down to the floor: at 48 points the columns touch and read as a filled field,
# and the eye stops seeing a line at all until it looks at the top of it.
func _build_plane() -> void:
	var n: int = _points.size()
	if n < 2:
		return
	var base_y: float = 0.0
	if not lift_to_floor:
		var min_y: float = _points[0].y
		for p in _points:
			min_y = minf(min_y, p.y)
		base_y = min_y - walk_height * 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = plane_color
	mat.emission_enabled = true
	mat.emission = plane_color
	mat.emission_energy_multiplier = 0.22
	mat.roughness = 0.9
	var step: float = walk_length / float(maxi(1, n - 1))
	for i in range(n):
		var h: float = _points[i].y - base_y
		if h <= 0.002:
			continue
		var col := MeshInstance3D.new()
		col.name = "Plane%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(step * 1.15, h, trail_radius * 0.8)
		col.mesh = bm
		col.material_override = mat
		col.position = Vector3(_points[i].x, base_y + h * 0.5, -trail_radius * 1.2)
		add_child(col)


func _process(delta: float) -> void:
	if not _built or _points.is_empty():
		return
	var n: int = _points.size()

	if _phase == "holding":
		_hold_timer -= delta
		if _hold_timer <= 0.0:
			if loop:
				_dim_all()
				_t = 0.0
				_phase = "walking"
			# if not looping, stay held forever
		return

	_t += delta * walk_speed
	if _t >= 1.0:
		_t = 1.0
		_light_up_to(n - 1)
		_head.position = _points[n - 1]
		_phase = "holding"
		_hold_timer = hold_seconds
		return

	var fpos: float = _t * float(n - 1)
	var idx: int = int(floor(fpos))
	var frac: float = fpos - float(idx)
	_light_up_to(idx)
	# Head interpolates smoothly between the last two lit points.
	if idx < n - 1:
		_head.position = _points[idx].lerp(_points[idx + 1], frac)
	else:
		_head.position = _points[n - 1]


func _light_up_to(idx: int) -> void:
	for i in range(_dot_mats.size()):
		var m: StandardMaterial3D = _dot_mats[i]
		m.emission_energy_multiplier = lit_energy if i <= idx else dim_energy


func _dim_all() -> void:
	for m in _dot_mats:
		(m as StandardMaterial3D).emission_energy_multiplier = dim_energy
