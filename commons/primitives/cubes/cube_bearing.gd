extends Node3D

# @identity
# essence: the MOUNTING a cube is caught in — the hardware around the body, never the body. A pad
#   and chocks, a spindle standing in its own wear ring, a linear rail with hard stops and a rubbed
#   bright stripe, a two-axis gimbal cage, or a clamp arm cranked off a post. Built in the host's
#   local space around a centre and a half-extent the host measures off its own CubeBaseMesh.
# desire: to make the difference between a cube that sits, a cube that turns and a cube that travels
#   legible in ONE STILL FRAME, by photographing the evidence of motion instead of the motion.
# critical_parameter: travel — what the mounting CONCEDES. none | seat | spindle | rail | gimbal |
#   armature. Every value is hardware; not one of them is a rate, a speed or a duration.
# triggers: build() from a host's _ready(); the node form reads config_travel off its own meta or
#   its parent's, then builds once.
# emerges: five cube tokens that were spelling static/rotating/transforming longhand as three
#   separate registry names collapse into ONE question asked of one body.
# needs: a host Node3D and a measured (centre, half) for the body [supplied by the caller]; nothing
#   else — no shader, no kit, no registry lookup.
# relationships: used by [[pickup_wrapper]] on the three pickup_cube_* tokens, and mounted as a
#   child node in rotating_cube.tscn and transformation_cube.tscn, whose roots already carry
#   [[cube_scene]]'s `grain` and must not be overridden.
# truth: rotation cannot be photographed. A worn ring can. An object that has been turning leaves
#   the same trace as an object that turned once, which is the honest limit of what a still knows.

## THE AXIS THIS FILE EXISTS FOR
##
## commons/artifacts/registry/primitives.json carries five tokens for this group:
##
##   pickup_cube_static · pickup_cube_rotating · pickup_cube_transforming
##   rotating_cube · transformation_cube
##
## They are not five objects. They are ONE body — cube_scene.tscn — wearing wrappers:
##
##   cube_scene.tscn                     the body (CubeBaseStaticBody3D/CubeBaseMesh)
##     rotating_cube.tscn                = body + RotationTween child
##     transformation_cube.tscn          = body + TransformationTween child (body raised 0.5)
##     pickup_cube_static.tscn           = pickup_wrapper.gd + Area3D + Visuals: cube_scene
##     pickup_cube_rotating.tscn         = pickup_wrapper.gd + Area3D + Visuals: rotating_cube
##     pickup_cube_transforming.tscn     = pickup_wrapper.gd + Area3D + Visuals: transformation_cube
##
## So "static / rotating / transforming" is ALREADY AN AXIS, spelled longhand as three registry
## names — the same shape curation_station had when 451 maps hand-spelled an unnamed enclosure
## axis as three booleans. The honest promotion is one axis whose values are the states.
##
## But the states themselves are RATES, and a rate is invisible to a still. So the axis is not
## the motion. It is what the MOUNTING concedes — a claim about what a graspable object owes you,
## carried entirely by hardware that holds still while it is photographed:
##
##   none      no mounting at all. The cube floats, unexplained. THE SHIPPED LOOK, all 31
##             placements, zero nodes added.
##   seat      nothing conceded. Bedded on a pad, four orange chocks wedged into the lower
##             corners, two posts and a keeper bar pinned across the top. It cannot turn and it
##             cannot lift. The honest still of `static`.
##   spindle   one rotation, and it has been used. A pin through the vertical axis with collars
##             and a thrust washer, standing on a base plate scored with a bright annular WEAR
##             RING. The ring is the evidence: this has turned. The honest still of `rotating`.
##   rail      one translation, bounded. A guide post beside the body, a carriage block and arm,
##             hard end stops top and bottom, and a polished bright stripe rubbed along the slot
##             showing exactly how far it goes. The honest still of `transforming`.
##   gimbal    orientation conceded entirely. Two trunnion rings on perpendicular axes in a yoke.
##             The body is held and its facing is given away — the value no token ever spelled.
##   armature  freedom already spent. A column, a knuckle, a cranked arm and a clamp gripping one
##             face, with a lock handle thrown. It is not at rest and it is not free: it is where
##             a previous hand put it.
##
## APPEARANCE ONLY. Every value is MeshInstance3D children under one "TravelMount" holder.
## Meshes do not collide. Nothing here reads or writes a collision layer, a collision mask, a
## CollisionShape3D, an Area3D, grab behaviour, mass, or the pickup path — these artifacts are
## grabbable and collectable and that must not move by a millimetre.
##
## NO RNG. Every dimension below is a literal multiple of the measured half-extent, so a variant
## renders identically on every boot and the critic measures the axis rather than the noise.

## What the mounting concedes. `none` is the shipped look: build() returns before creating a
## single node.
@export_enum("none", "seat", "spindle", "rail", "gimbal", "armature") var travel: String = "none"

## Allow-list for the axis. A word outside it is a typo in a map token and keeps the value
## already held — which on a fresh instance is the shipped look.
const TRAVELS: PackedStringArray = ["none", "seat", "spindle", "rail", "gimbal", "armature"]

## Body frame overrides for the node form. Left at zero, _derive() measures the host's own
## CubeBaseMesh, which is correct for every scene in this family and is the only way to get
## pickup_cube_transforming right (its body sits at y = 0.75, not at the 0.5 the pickup base
## class assumes).
@export var body_center: Vector3 = Vector3.ZERO
@export var body_half: float = 0.0

## Where the body lives in every scene of this family.
const BODY_MESH_NAME: String = "CubeBaseMesh"

## Sign pairs for the symmetric hardware. Plain Array, and every loop variable is copied into an
## explicitly typed float before use — an untyped loop var assigned with `:=` does not compile.
const SIDES: Array = [-1.0, 1.0]


# ── node form ─────────────────────────────────────────────────────────
# Used by rotating_cube.tscn and transformation_cube.tscn, whose ROOT script is CubeScene and
# already carries `grain`. Overriding that root would destroy a finished axis across 155
# placements, so this rides as a sibling node instead.

## THE DEFAULT PATH. `none` returns after one string compare — the body is never measured, no
## node is created, nothing is hidden and no property is written. rotating_cube's 10 placements
## and transformation_cube's 6 render exactly the pixels they rendered before this node existed.
func _ready() -> void:
	_read_axis()
	if travel == "none":
		return
	_derive()
	build(self, travel, body_center, body_half)


## Grid config entry point for the node form. The grid writes config_* onto the ARTIFACT ROOT
## before add_child, so the read below happens in _ready with the value already present; this
## method only exists for callers that hand the dict straight to this node.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var before: String = travel
	_read_axis()
	if travel == before:
		return
	var old: Node = get_node_or_null("TravelMount")
	if old != null:
		remove_child(old)
		old.queue_free()
	_derive()
	build(self, travel, body_center, body_half)


## Read the axis off this node's own metadata, then off the parent's.
##
## Only the DIRECT parent, never a search up the tree. pickup_cube_rotating instances
## rotating_cube as its Visuals child, so this node exists nested one level down inside a
## pickup whose ROOT also owns a `travel`. A deep search would let both fire and build the
## mount twice; the direct-parent rule means the nested copy never sees the key and stays
## silent, which is correct — the pickup root owns that artifact's axis.
func _read_axis() -> void:
	if has_meta("config_travel"):
		travel = pick(str(get_meta("config_travel")), travel)
	var p: Node = get_parent()
	if p != null and p.has_meta("config_travel"):
		travel = pick(str(p.get_meta("config_travel")), travel)


## Measure the body this mount has to fit around, in this node's local space.
##
## Derived rather than hard-coded because the four scenes disagree about where the body sits:
## rotating_cube centres it on the origin, transformation_cube raises it half a metre, and the
## two under a pickup are half-scale on top of that.
func _derive() -> void:
	if body_half > 0.0:
		return
	var p: Node = get_parent()
	var mesh: MeshInstance3D = null
	if p != null:
		var n: Node = p.find_child(BODY_MESH_NAME, true, false)
		if n is MeshInstance3D:
			mesh = n as MeshInstance3D
	if mesh == null or not is_inside_tree():
		body_center = Vector3.ZERO
		body_half = 0.5
		return
	var frame: Array = measure(self, mesh)
	body_center = frame[0]
	body_half = frame[1]


# ── shared API ────────────────────────────────────────────────────────

## Normalise an axis token. Lower-cased and stripped; anything unrecognised keeps the value
## already held, exactly as station_wall does, so a typo is inert rather than disfiguring.
static func pick(raw: String, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if TRAVELS.has(v) else fallback


## The body's centre and half-extent expressed in `host`'s local space.
##
## Returns [Vector3 centre, float half]. Relative, not global, so the grid grounding the
## artifact afterwards cannot shift the mount off its body.
static func measure(host: Node3D, mesh: MeshInstance3D) -> Array:
	if host == null or mesh == null or not host.is_inside_tree() or not mesh.is_inside_tree():
		return [Vector3.ZERO, 0.5]
	var rel: Transform3D = host.global_transform.affine_inverse() * mesh.global_transform
	var ab: AABB = mesh.get_aabb()
	var centre: Vector3 = rel * ab.get_center()
	var sx: float = (rel.basis * Vector3(ab.size.x, 0.0, 0.0)).length()
	var sy: float = (rel.basis * Vector3(0.0, ab.size.y, 0.0)).length()
	var sz: float = (rel.basis * Vector3(0.0, 0.0, ab.size.z)).length()
	var half: float = maxf(maxf(sx, sy), sz) * 0.5
	if half <= 0.0:
		half = 0.5
	return [centre, half]


## Build the mounting. Returns the holder, or null when nothing was built.
##
## THE DEFAULT PATH: `none` (and an empty or unrecognised word, which degrades to it) returns
## after one string compare, having created no node, hidden nothing and written no property.
## All 31 existing placements land here and render exactly the pixels they rendered before.
static func build(host: Node3D, value: String, centre: Vector3, half: float) -> Node3D:
	if host == null:
		return null
	var v: String = value.to_lower().strip_edges()
	if v == "" or v == "none" or not TRAVELS.has(v):
		return null

	var h: float = maxf(half, 0.05)
	var holder: Node3D = Node3D.new()
	holder.name = "TravelMount"
	host.add_child(holder)

	match v:
		"seat":
			_seat(holder, centre, h)
		"spindle":
			_spindle(holder, centre, h)
		"rail":
			_rail(holder, centre, h)
		"gimbal":
			_gimbal(holder, centre, h)
		"armature":
			_armature(holder, centre, h)
	return holder


# ── the five mountings ────────────────────────────────────────────────

## SEAT — nothing conceded. A broad shallow bed pad, four safety-orange chocks driven into the
## lower corners, and two posts carrying a keeper bar pinned across the top. The silhouette
## gains mass below AND a hard horizontal above the body: the two places a restraint shows.
static func _seat(g: Node3D, c: Vector3, h: float) -> void:
	var steel: StandardMaterial3D = _steel()
	var warn: StandardMaterial3D = _warn()
	var bot: float = c.y - h
	var top: float = c.y + h

	_box(g, Vector3(h * 3.0, h * 0.24, h * 3.0), Vector3(c.x, bot - h * 0.12, c.z), steel)

	for sx in SIDES:
		for sz in SIDES:
			var px: float = c.x + sx * h * 1.02
			var pz: float = c.z + sz * h * 1.02
			_box(g, Vector3(h * 0.64, h * 0.54, h * 0.64), Vector3(px, bot + h * 0.27, pz), warn)

	for ax in SIDES:
		var qx: float = c.x + ax * h * 1.34
		_box(g, Vector3(h * 0.24, h * 2.3, h * 0.24), Vector3(qx, c.y + h * 0.12, c.z), steel)
		_cyl(g, h * 0.14, h * 0.2, Vector3(qx, top + h * 0.34, c.z), steel)

	_box(g, Vector3(h * 3.0, h * 0.18, h * 0.36), Vector3(c.x, top + h * 0.22, c.z), steel)


## SPINDLE — one rotation, evidenced. A pin through the vertical axis with a collar under the
## body and a thrust washer over it, standing on a base plate carrying a bright annular WEAR
## RING. The ring is the whole argument: it is what a still can hold of a turning thing.
static func _spindle(g: Node3D, c: Vector3, h: float) -> void:
	var steel: StandardMaterial3D = _steel()
	var bright: StandardMaterial3D = _bright()
	var dark: StandardMaterial3D = _dark()
	var bot: float = c.y - h
	var top: float = c.y + h

	_cyl(g, h * 1.7, h * 0.18, Vector3(c.x, bot - h * 0.22, c.z), steel)
	_cyl(g, h * 1.74, h * 0.06, Vector3(c.x, bot - h * 0.34, c.z), dark)

	# The rub track: a scored ring polished bright by something that has been going round.
	_ring(g, h * 1.04, h * 1.3, Vector3(c.x, bot - h * 0.11, c.z), bright)
	_ring(g, h * 0.5, h * 0.62, Vector3(c.x, bot - h * 0.11, c.z), bright)

	_cyl(g, h * 0.17, h * 0.42, Vector3(c.x, bot - h * 0.06, c.z), steel)
	_cyl(g, h * 0.36, h * 0.14, Vector3(c.x, bot - h * 0.02, c.z), dark)

	_cyl(g, h * 0.38, h * 0.12, Vector3(c.x, top + h * 0.06, c.z), dark)
	_cyl(g, h * 0.17, h * 0.6, Vector3(c.x, top + h * 0.42, c.z), steel)
	_cyl(g, h * 0.24, h * 0.16, Vector3(c.x, top + h * 0.8, c.z), steel)


## RAIL — one translation, bounded. A guide post to one side with a recessed slot, a carriage
## block and arm reaching the body, hard end stops top and bottom, and a bright stripe rubbed
## into the slot between them. The stripe says how far this goes; the stops say where it ends.
static func _rail(g: Node3D, c: Vector3, h: float) -> void:
	var steel: StandardMaterial3D = _steel()
	var bright: StandardMaterial3D = _bright()
	var dark: StandardMaterial3D = _dark()
	var warn: StandardMaterial3D = _warn()
	var px: float = c.x - h * 1.62
	var bot: float = c.y - h

	_box(g, Vector3(h * 0.9, h * 0.18, h * 0.9), Vector3(px, bot - h * 0.09, c.z), steel)
	_box(g, Vector3(h * 0.3, h * 3.5, h * 0.3), Vector3(px, c.y, c.z), steel)
	_box(g, Vector3(h * 0.12, h * 2.9, h * 0.34), Vector3(px, c.y, c.z + h * 0.16), dark)
	# the polished extent of travel
	_box(g, Vector3(h * 0.06, h * 1.6, h * 0.36), Vector3(px, c.y, c.z + h * 0.18), bright)

	for sy in SIDES:
		var qy: float = c.y + sy * h * 1.6
		_box(g, Vector3(h * 0.5, h * 0.16, h * 0.5), Vector3(px, qy, c.z), warn)

	_box(g, Vector3(h * 0.54, h * 0.46, h * 0.54), Vector3(px, c.y, c.z), steel)
	_box(g, Vector3(h * 1.3, h * 0.18, h * 0.18), Vector3(c.x - h * 0.98, c.y, c.z), steel)
	_cyl(g, h * 0.13, h * 0.34, Vector3(c.x - h * 0.98, c.y + h * 0.2, c.z), steel)


## GIMBAL — orientation conceded entirely. Two trunnion rings on perpendicular axes, carried in
## a yoke off a base plate. The rings are the largest silhouette change in the family: this is
## the value you can name from the far side of a room, which is the point of an axis.
static func _gimbal(g: Node3D, c: Vector3, h: float) -> void:
	var steel: StandardMaterial3D = _steel()
	var dark: StandardMaterial3D = _dark()
	var bot: float = c.y - h

	# Both ring radii clear the cube's half-diagonal (1.414 h), so neither ring intersects a
	# corner of the body it is supposed to be carrying.

	# Outer ring standing in the XY plane (pivoting about Z), centre radius 1.78 h.
	var outer: MeshInstance3D = _ring(g, h * 1.70, h * 1.86, c, steel)
	outer.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	# Inner ring standing in the ZY plane (pivoting about X), centre radius 1.51 h.
	var inner: MeshInstance3D = _ring(g, h * 1.44, h * 1.58, c, dark)
	inner.rotation_degrees = Vector3(90.0, 90.0, 0.0)

	# Outer-to-inner trunnions, on Z, bridging radius 1.51 h to 1.78 h.
	for sz in SIDES:
		var tz: float = c.z + sz * h * 1.645
		var pin: MeshInstance3D = _cyl(g, h * 0.12, h * 0.34, Vector3(c.x, c.y, tz), steel)
		pin.rotation_degrees = Vector3(90.0, 0.0, 0.0)

	# Yoke-to-outer trunnions, on X, bridging radius 1.78 h to the uprights at 1.99 h.
	for sx in SIDES:
		var tx: float = c.x + sx * h * 1.87
		var pin2: MeshInstance3D = _cyl(g, h * 0.12, h * 0.30, Vector3(tx, c.y, c.z), steel)
		pin2.rotation_degrees = Vector3(0.0, 0.0, 90.0)

	# The yoke: two uprights from a base plate up to the outer ring's pivot height.
	for ax in SIDES:
		var ux: float = c.x + ax * h * 1.99
		_box(g, Vector3(h * 0.26, h * 2.0, h * 0.26), Vector3(ux, c.y - h * 0.5, c.z), steel)
	_box(g, Vector3(h * 4.5, h * 0.2, h * 1.1), Vector3(c.x, bot - h * 0.6, c.z), steel)


## ARMATURE — freedom already spent. A column, a knuckle, a cranked arm and a clamp gripping one
## face, with the lock handle thrown. The only asymmetric value in the family: the body is not
## resting and it is not free, it is where somebody else left it.
static func _armature(g: Node3D, c: Vector3, h: float) -> void:
	var steel: StandardMaterial3D = _steel()
	var dark: StandardMaterial3D = _dark()
	var warn: StandardMaterial3D = _warn()
	var bot: float = c.y - h
	var cx: float = c.x + h * 2.0
	var ay: float = c.y + h * 1.05

	_box(g, Vector3(h * 1.2, h * 0.2, h * 1.2), Vector3(cx, bot - h * 0.1, c.z), steel)
	_box(g, Vector3(h * 0.34, h * 2.5, h * 0.34), Vector3(cx, (bot + ay) * 0.5, c.z), steel)
	_ball(g, h * 0.36, Vector3(cx, ay, c.z), dark)

	# Arm from the column knuckle out to the wrist, which stands directly over the clamp's
	# backing plate — every link in the chain overlaps the next, so the clamp reads as carried
	# by the post rather than as loose hardware floating beside it.
	_box(g, Vector3(h * 1.14, h * 0.22, h * 0.22), Vector3(c.x + h * 1.55, ay, c.z), steel)
	_ball(g, h * 0.28, Vector3(c.x + h * 1.14, ay, c.z), dark)
	_box(g, Vector3(h * 0.2, h * 0.95, h * 0.2),
		Vector3(c.x + h * 1.14, ay - h * 0.52, c.z), steel)

	# Jaws closed on the +X face, on a backing plate the drop link lands in.
	_box(g, Vector3(h * 0.16, h * 1.1, h * 1.0), Vector3(c.x + h * 1.14, c.y, c.z), steel)
	for sy in SIDES:
		var jy: float = c.y + sy * h * 0.46
		_box(g, Vector3(h * 0.55, h * 0.18, h * 1.0), Vector3(c.x + h * 0.88, jy, c.z), warn)

	# The lock handle, thrown.
	_cyl(g, h * 0.09, h * 0.7, Vector3(cx, ay + h * 0.5, c.z), steel)
	_ball(g, h * 0.15, Vector3(cx, ay + h * 0.86, c.z), warn)


# ── primitives ────────────────────────────────────────────────────────

static func _box(g: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _put(g, mesh, pos, mat)


static func _cyl(g: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 1
	return _put(g, mesh, pos, mat)


static func _ring(g: Node3D, inner: float, outer: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 28
	mesh.ring_segments = 10
	return _put(g, mesh, pos, mat)


static func _ball(g: Node3D, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return _put(g, mesh, pos, mat)


static func _put(g: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	g.add_child(mi)
	return mi


# ── materials ─────────────────────────────────────────────────────────
# Deliberately NOT the cube's magenta Grid shader. The mounting is not the body: it is shop
# hardware standing around the body, and it has to read as a different order of thing or the
# variant looks like a differently-shaped cube rather than a cube in a fixture.

static func _steel() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.57, 0.60)
	m.roughness = 0.34
	m.metallic = 0.85
	return m


static func _dark() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.13, 0.14, 0.16)
	m.roughness = 0.72
	return m


## The wear evidence. Emissive on purpose: the sweep stage is a dark room, and a rub mark that
## does not survive the exposure is an argument that did not get made.
static func _bright() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.92, 0.94, 0.97)
	m.roughness = 0.12
	m.metallic = 0.9
	m.emission_enabled = true
	m.emission = Color(0.86, 0.90, 0.96)
	m.emission_energy_multiplier = 0.4
	return m


static func _warn() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.93, 0.44, 0.06)
	m.roughness = 0.6
	return m
