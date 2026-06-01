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

@export_group("Walk")
## "meander" (queer wander), "straight" (collapsed), "spiral", "arc".
@export var walk_style: String = "meander"
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


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_dot_mats.clear()
		_head = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_walk_style"):
		walk_style = str(get_meta("config_walk_style"))
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
