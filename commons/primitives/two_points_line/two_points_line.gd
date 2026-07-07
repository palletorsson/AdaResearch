extends Node3D
class_name TwoPointsLine

# @identity
# essence: two luminous endpoints and the segment between them — Euclid's first postulate made into an object: "a straight line may be drawn between any two points." The two points are different colours (difference), and the line is nothing but their between. A small bright messenger travels A -> B and back along the segment, so the line reads not as a static bar but as a CHANNEL — the open relation along which one point can reach the other.
# desire: it wants to prove the line is pure relation. Without B, A is only a point; the line is what "near" means — it is the relationship itself, not a third thing added to the two. It wants the player to feel that connection is primary: that the most basic line in geometry is already a small social fact — two distinct things and the traffic between them.
# critical_parameter: the two endpoint positions (length) and their two colours. Collapse is A = B — no distance, no line, nothing to relate. The φ-move is two genuinely distinct points held apart and joined: difference that does not dissolve into sameness, bridged without being erased. The messenger makes the relation active rather than merely asserted.
# triggers: _ready builds endpoint A, endpoint B, and the segment tube; _process drives the messenger bead back and forth; apply_grid_config rebuilds on DNA change.
# emerges: one segment reads as "a line"; but watched, the travelling messenger turns it into orientation — A is oriented toward B, the line has a direction of address. Beside `klee_walking_point` (one point becoming a line by moving) this is two points becoming a line by RELATING. Together: a line is either a walk or a bond.
# needs: two distinct endpoints [present]; a segment that is only their between [present]; a sign that the relation is live, not frozen [messenger, present]; difference held without collapse [two colours, present]
# relationships: child of `origin` / `static_point` (the points it relates); twin to `klee_walking_point` (the two origin stories of the line — motion vs. relation); ancestor of every edge, vector, spring, and graph-link downstream — the segment is the atom of connection; cousin to `redline` (both are lines between, but this one joins and that one divides).
# truth: a point is position without extension; a line between two points is the first relation in all of geometry — and relation, not substance, is what the line teaches. Sara Ahmed: orientation is a question of what we are near, what we turn toward. The two-point line is that turning made minimal and visible: difference, distance, and the lit path that crosses it without making the two the same.

## Two points and the line between — Euclid's first postulate.
##
## Built procedurally. Origin at the midpoint. Endpoints sit on the
## local X axis; a messenger bead travels A -> B -> A along the segment.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Geometry")
@export var length: float = 1.4
@export var endpoint_radius: float = 0.05
@export var line_radius: float = 0.012

@export_group("Material")
@export var point_a_color: Color = Color(1.0, 0.45, 0.75)   # difference: warm
@export var point_b_color: Color = Color(0.35, 0.75, 1.0)   # difference: cool
@export var line_color: Color = Color(0.9, 0.9, 0.95)
@export var show_messenger: bool = true
@export var messenger_speed: float = 0.6

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _messenger: MeshInstance3D = null
var _t: float = 0.0


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
		_messenger = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_length"):
		length = float(str(get_meta("config_length")))
	if has_meta("config_point_a_color"):
		point_a_color = _parse_color(str(get_meta("config_point_a_color")), point_a_color)
	if has_meta("config_point_b_color"):
		point_b_color = _parse_color(str(get_meta("config_point_b_color")), point_b_color)
	if has_meta("config_line_color"):
		line_color = _parse_color(str(get_meta("config_line_color")), line_color)
	if has_meta("config_show_messenger"):
		var s: String = str(get_meta("config_show_messenger")).to_lower()
		show_messenger = s == "true" or s == "1" or s == "yes"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var half: float = length * 0.5

	# Segment tube — the between.
	var line := MeshInstance3D.new()
	line.name = "Segment"
	var lm := CylinderMesh.new()
	lm.top_radius = line_radius
	lm.bottom_radius = line_radius
	lm.height = length
	line.mesh = lm
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = line_color
	line_mat.emission_enabled = true
	line_mat.emission = line_color
	line_mat.emission_energy_multiplier = 0.7
	line_mat.roughness = 0.4
	line.material_override = line_mat
	line.rotation = Vector3(0, 0, PI * 0.5)   # cylinder Y -> X axis
	add_child(line)

	# Endpoint A (warm) and B (cool).
	_add_endpoint("PointA", Vector3(-half, 0, 0), point_a_color)
	_add_endpoint("PointB", Vector3(half, 0, 0), point_b_color)

	# Messenger bead — the live relation.
	if show_messenger:
		_messenger = MeshInstance3D.new()
		_messenger.name = "Messenger"
		var mm := SphereMesh.new()
		mm.radius = line_radius * 2.2
		mm.height = line_radius * 4.4
		_messenger.mesh = mm
		var mmat := StandardMaterial3D.new()
		mmat.albedo_color = Color(1, 1, 1)
		mmat.emission_enabled = true
		mmat.emission = Color(1, 1, 1)
		mmat.emission_energy_multiplier = 2.6
		mmat.roughness = 0.2
		_messenger.material_override = mmat
		_messenger.position = Vector3(-half, 0, 0)
		add_child(_messenger)

	_t = 0.0
	set_process(show_messenger)


func _add_endpoint(n: String, pos: Vector3, col: Color) -> void:
	var p := MeshInstance3D.new()
	p.name = n
	var sm := SphereMesh.new()
	sm.radius = endpoint_radius
	sm.height = endpoint_radius * 2.0
	p.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.0
	mat.roughness = 0.25
	p.material_override = mat
	p.position = pos
	add_child(p)


func _process(delta: float) -> void:
	if not show_messenger or _messenger == null:
		return
	_t += delta * messenger_speed
	# Ping-pong 0..1..0 along the segment.
	var u: float = 0.5 - 0.5 * cos(_t * TAU)
	var half: float = length * 0.5
	_messenger.position.x = -half + length * u
	# Messenger takes on the colour of the point it approaches.
	var col: Color = point_a_color.lerp(point_b_color, u)
	var mat := _messenger.material_override as StandardMaterial3D
	if mat:
		mat.emission = col.lerp(Color(1, 1, 1), 0.4)
