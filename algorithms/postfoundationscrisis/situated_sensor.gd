# Situated Sensor — knowledge with a body, a place, a time
#
# A small instrument on a tripod, with a glowing readout that displays its own location
# coordinates. As the player moves around it, the readout updates — the sensor is aware
# of its position and reports its measurements *as relative to* that position. There is
# no view from nowhere; this knower is always located.
#
# Counters the universalist fantasy that computation is placeless. The sensor knows what
# it sees only from where it stands.
#
# @identity: First map where computation has coordinates.
# @qfep_term: Edge — situated, not abstract.
#
# ── Stage-2 DNA ────────────────────────────────────────────────────────────────
# One axis, `standpoint`, borrowed from the theory this artifact cites rather than
# invented for it. Before the pass the artifact reported its position honestly and
# never showed what HAVING a position costs: the field of view that makes a standpoint
# a standpoint, and the view from nowhere it exists to deny, lived only in this header
# and in a font-18 coordinate readout nobody reads from across a room.
#
#   located   the legacy tripod — one knower, standing somewhere            (default)
#   nowhere   the same instrument, legs deleted — a halo where they met the body, and on
#             the floor only the outline they left behind, with nothing in between
#   cone      the tripod plus the region it can actually see, as one solid
#   many      three complete tripods, aimed apart, with nothing reconciling them
#
# EVERY VALUE STANDS ON THE FLOOR BY ITSELF. GridInteractablesComponent._auto_ground_artifact()
# snaps an artifact's lowest geometry to the cell surface in every placement, and there is no
# per-value opt-out — so any value whose lowest point is not y = 0 gets silently shifted, and
# the map author is handed a bug dressed as a token. Both extremes now meet the grounder:
#
#   nowhere  hung its head at 1.65 m with nothing below it, so the grounder applied a -1.56 m
#            correction and put the unsupported head on the floor. It now leaves the erased
#            body's TRACE at floor level instead: three thin outlines exactly where the tripod
#            feet used to touch down, and nothing whatsoever between them and the head. That
#            pins the lowest geometry at y = 0, so the head genuinely stays at eye height in a
#            bare placement — and the mark of a body that is gone argues the view from nowhere
#            harder than a floating head did, because you can see what was removed.
#   cone     the mouth circle dipped 0.2 m under the floor, so the grounder LIFTED the whole
#            tripod while `located` and `many` stood on the ground. The mouth is now cut flat
#            where the floor is: the seen region stops at the ground, which is what happens to
#            a real sensor's view anyway. Reach (2.5 m) and mouth width (1.2 m) are untouched.
#
# `located` and `many` were already correct — lowest geometry is a tripod foot at y ~= 0.

extends Node3D
class_name SituatedSensor

@export var tripod_color: Color = Color(0.4, 0.42, 0.48, 1.0)
@export var lens_color: Color = Color(0.6, 0.95, 0.65, 1.0)
@export var readout_color: Color = Color(0.95, 0.85, 0.3, 1.0)

## Where the knowing happens from, and whether the limits of that position are shown.
## Worth varying because a situated knower and an unsituated one are the same box of
## electronics — the difference is entirely in what is built AROUND the box: legs that
## put it somewhere, a cone that says how far its somewhere reaches, or two more copies
## of it looking the other way. The axis moves legs, a 2.5 m volume and whole duplicate
## instruments, so it reads from across the room; a change in the readout font would not.
@export_enum("located", "nowhere", "cone", "many") var standpoint: String = "located"

const STANDPOINTS: PackedStringArray = ["located", "nowhere", "cone", "many"]

## The tripod, named rather than inlined so the `nowhere` foot traces can be placed exactly
## where these legs used to touch down. Values are the legacy ones — the legs converge
## slightly as they descend, so the feet land inside the 0.18 m mounting circle.
const LEG_RING_RADIUS: float = 0.18
const LEG_HALF_LEN: float = 0.45
const LEG_TILT: float = 0.15

## `nowhere`: how far the unsupported assembly hangs above the floor, and the halo ring
## that stands in for the legs. 0.55 m across is wider than the leg circle it replaces, so
## the silhouette changes shape and not just height.
const NOWHERE_LIFT: float = 0.65
const RING_OUTER: float = 0.275
const RING_INNER: float = 0.255

## `nowhere`: the trace the deleted body left. Thin flat outlines on the floor, one per
## missing foot, sitting exactly on y = 0 so the grounder has nothing to correct. They are
## not a support — nothing rises from them — they are the print of the legs that were taken
## away, which is the only thing an unsituated knower can honestly leave on a floor.
const FOOT_MARK_INNER: float = 0.045
const FOOT_MARK_OUTER: float = 0.06

## `cone`: the knowable region, issued from the lens along +z. 2.5 m long spreading to a
## 1.2 m mouth — big enough that the room is visibly divided into seen and unseen, which
## is the entire content of situated knowledge. A polite 0.3 m cone would have been a
## smudge on the lens.
const CONE_LENGTH: float = 2.5
const CONE_MOUTH: float = 1.2
const CONE_SEGMENTS: int = 8
const CONE_ALPHA: float = 0.15
## The lens height the cone issues from, and therefore how far the mouth may drop before it
## goes under the floor. Mouth vertices are clamped at -CONE_ORIGIN_Y, so the seen region is
## cut flat at ground level instead of hanging below it and making the grounder lift the
## tripod. Nothing about the reach or the width changes: only the bottom of the mouth moves,
## from y = -0.2 to y = 0.
const CONE_ORIGIN_Y: float = 1.0

## `many`: three located knowers on an arc, each yawed 40 degrees off its neighbour.
const MANY_OFFSETS: PackedFloat32Array = [-0.8, 0.0, 0.8]
const MANY_YAW_DEG: float = 40.0

var _lenses: Array[MeshInstance3D] = []
var _readouts: Array[Label3D] = []
## World-space offset each readout reports from, in artifact-local coordinates. Zero for
## every single-instrument standpoint, so the reported text is unchanged from the legacy
## build; three different values under `many`, which is the point of `many`.
var _report_offsets: Array[Vector3] = []
var _t: float = 0.0

## Every node THIS script parented to self. Rebuilds free these and only these — the grid
## system, the label framer and the packaging pass all add children of their own, and a
## rebuild that swept get_children() would eat them.
var _owned: Array[Node3D] = []
## False until _ready has built once. apply_grid_config runs BEFORE _ready on the normal
## grid path (GridInteractablesComponent applies config at line 1161, add_child is at 1187),
## so a config arriving early has nothing to rebuild — it just sets the value _ready builds.
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


func apply_grid_config(config_data: Dictionary) -> void:
	# Stage-2 DNA axis — #standpoint:cone
	var before_standpoint: String = standpoint
	if config_data.has("standpoint"):
		standpoint = _pick_axis(str(config_data["standpoint"]), STANDPOINTS, standpoint)

	if not _built:
		return
	if standpoint == before_standpoint:
		# Nothing geometric changed. Curated placements call us with dicts like
		# {"emissive": false} AFTER their own label framing has been applied; rebuilding
		# here would throw that framing away and restore billboarded, outlined labels.
		return

	_rebuild_now()
	print("[SituatedSensor] Config applied — standpoint=%s" % [standpoint])


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the legacy look — a half-recognised value would strand a
## placement with an instrument missing its legs for no stated reason.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Tear down what we built and build it again, synchronously and in place. No call_deferred
## anywhere in this path: remove_child leaves the tree immediately, so there is never a frame
## with two assemblies in it, and the new geometry exists before this returns — which is what
## the grid's label framing and auto-grounding, both queued after us, expect to measure.
func _rebuild_now() -> void:
	for node in _owned:
		if is_instance_valid(node) and node.get_parent() == self:
			remove_child(node)
			node.queue_free()
	_owned.clear()
	_lenses.clear()
	_readouts.clear()
	_report_offsets.clear()
	_build_all()


func _build_all() -> void:
	match standpoint:
		"nowhere":
			_build_unit(Vector3(0, NOWHERE_LIFT, 0), 0.0, false, false)
			_build_halo_ring()
			_build_foot_traces()
		"cone":
			_build_unit(Vector3.ZERO, 0.0, true, true)
		"many":
			for i in MANY_OFFSETS.size():
				var yaw: float = deg_to_rad(MANY_YAW_DEG * (float(i) - 1.0))
				_build_unit(Vector3(MANY_OFFSETS[i], 0.0, 0.0), yaw, true, false)
		_:
			_build_unit(Vector3.ZERO, 0.0, true, false)


func _process(delta: float) -> void:
	_t += delta
	for lens in _lenses:
		if is_instance_valid(lens):
			var mat := lens.material_override as StandardMaterial3D
			if mat:
				mat.emission_energy_multiplier = 1.4 + 0.4 * sin(_t * 2.0)
	# Update each readout to reflect the place ITS OWN instrument stands in.
	for i in _readouts.size():
		var readout: Label3D = _readouts[i]
		if is_instance_valid(readout):
			var gp: Vector3 = to_global(_report_offsets[i])
			readout.text = "I am here:\n  x = %.2f\n  y = %.2f\n  z = %.2f" % [gp.x, gp.y, gp.z]


## One complete instrument: optional legs, head, lens, readout, optional view cone.
## Everything hangs off a holder so a unit can be moved and yawed as a whole.
func _build_unit(origin: Vector3, yaw: float, with_legs: bool, with_cone: bool) -> void:
	var unit := Node3D.new()
	unit.position = origin
	unit.rotation.y = yaw
	add_child(unit)
	_owned.append(unit)
	if with_legs:
		_build_tripod(unit)
	_build_sensor_head(unit)
	_build_readout(unit, origin)
	if with_cone:
		_build_view_cone(unit)


func _build_tripod(unit: Node3D) -> void:
	for i in 3:
		var a: float = TAU * float(i) / 3.0
		var leg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.04, LEG_HALF_LEN * 2.0, 0.04)
		leg.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tripod_color
		mat.metallic = 0.6
		mat.roughness = 0.4
		leg.material_override = mat
		leg.position = Vector3(cos(a) * LEG_RING_RADIUS, LEG_HALF_LEN, sin(a) * LEG_RING_RADIUS)
		leg.rotation = Vector3(sin(a) * LEG_TILT, 0, -cos(a) * LEG_TILT)
		unit.add_child(leg)


func _build_sensor_head(unit: Node3D) -> void:
	var head := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.18, 0.25)
	head.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.27, 0.32, 1.0)
	mat.metallic = 0.5
	head.material_override = mat
	head.position = Vector3(0, 1.0, 0)
	unit.add_child(head)
	# Lens.
	var lens := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.08
	s.height = 0.16
	lens.mesh = s
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = lens_color
	lmat.emission_enabled = true
	lmat.emission = lens_color
	lmat.emission_energy_multiplier = 1.6
	lens.material_override = lmat
	lens.position = Vector3(0, 1.0, 0.18)
	unit.add_child(lens)
	_lenses.append(lens)


func _build_readout(unit: Node3D, origin: Vector3) -> void:
	var readout := Label3D.new()
	readout.text = "I am here:\n  x = 0.00\n  y = 0.00\n  z = 0.00"
	readout.font_size = 18
	readout.outline_size = 4
	readout.modulate = readout_color
	readout.position = Vector3(0, 1.35, 0)
	readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	unit.add_child(readout)
	_readouts.append(readout)
	_report_offsets.append(origin)


## `nowhere` — the halo that replaces the legs. An instrument with a ring instead of a
## place to stand: it has a claim on the room without touching it anywhere.
func _build_halo_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	# Inner first: TorusMesh ships with inner 0.5 / outer 1.0, and shrinking the outer
	# radius below the stale inner one first is how you get an empty mesh.
	torus.inner_radius = RING_INNER
	torus.outer_radius = RING_OUTER
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.88, 0.95, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = mat
	ring.position = Vector3(0, 1.0 + NOWHERE_LIFT, 0)
	add_child(ring)
	_owned.append(ring)


## `nowhere` — the trace of the body that was deleted. Three flat outlines on the floor at
## the exact radius the tripod feet used to stand at, and nothing above them: the head hangs
## clear over its own absent legs. This is also what keeps the value honest under the grid's
## auto-grounder, which measures the lowest geometry and would otherwise drag the head down
## to the floor. A mark is not a support — you can walk through the space it encloses.
func _build_foot_traces() -> void:
	var r: float = _foot_ground_radius()
	var lift: float = (FOOT_MARK_OUTER - FOOT_MARK_INNER) * 0.5
	for i in 3:
		var a: float = TAU * float(i) / 3.0
		var mark := MeshInstance3D.new()
		var torus := TorusMesh.new()
		# Inner before outer — see _build_halo_ring for why.
		torus.inner_radius = FOOT_MARK_INNER
		torus.outer_radius = FOOT_MARK_OUTER
		mark.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(tripod_color.r, tripod_color.g, tripod_color.b, 0.55)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mark.material_override = mat
		# lift puts the tube's underside exactly on y = 0, so the grounder corrects by nothing.
		mark.position = Vector3(cos(a) * r, lift, sin(a) * r)
		add_child(mark)
		_owned.append(mark)


## Where a splayed leg actually meets the floor. The legs tilt inward by LEG_TILT over their
## half length, so the contact circle is tighter than the mounting circle.
func _foot_ground_radius() -> float:
	return LEG_RING_RADIUS - LEG_HALF_LEN * sin(LEG_TILT)


## `cone` — the region this lens can see, built as a solid. Open at the mouth and
## uncapped on purpose: the cone is not an object in the room, it is the room, sorted
## into what this standpoint reaches and what it does not.
func _build_view_cone(unit: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apex := Vector3.ZERO
	for i in CONE_SEGMENTS:
		var a0: float = TAU * float(i) / float(CONE_SEGMENTS)
		var a1: float = TAU * float(i + 1) / float(CONE_SEGMENTS)
		var p0: Vector3 = _cone_mouth_point(a0)
		var p1: Vector3 = _cone_mouth_point(a1)
		st.add_vertex(apex)
		st.add_vertex(p0)
		st.add_vertex(p1)
	st.generate_normals()

	var cone := MeshInstance3D.new()
	cone.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(lens_color.r, lens_color.g, lens_color.b, CONE_ALPHA)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = lens_color
	mat.emission_energy_multiplier = 0.5
	cone.material_override = mat
	cone.position = Vector3(0, CONE_ORIGIN_Y, 0.18)
	unit.add_child(cone)


## One point on the rim of the seen region, cut off at the floor. The full circle would put
## its lowest vertex 0.2 m under the ground, and the grounder answers that by lifting the
## entire tripod — so `cone` would float while `located` and `many` stood on the floor. The
## clamp costs the cone nothing it should have had: a sensor cannot see through the ground,
## so its region ends there. Reach and width are the constants, untouched.
func _cone_mouth_point(a: float) -> Vector3:
	var y: float = sin(a) * CONE_MOUTH
	if y < -CONE_ORIGIN_Y:
		y = -CONE_ORIGIN_Y
	return Vector3(cos(a) * CONE_MOUTH, y, CONE_LENGTH)
