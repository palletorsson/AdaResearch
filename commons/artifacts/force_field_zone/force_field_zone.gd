extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ForceFieldZone

## @identity
## lineage: a force made into a place — a 4 m cube of space where one vector rules. Step in
##   (or throw a cube in) and gravity is replaced by whatever the vector machine is pointing;
##   the void below is only a void if the field lets you fall.
## essence: inside the cube the field is the only force. Point it down and everything drops
##   into the void; point it up-and-across and the same cube — and the same you — is carried
##   to the far side. The field lines and the central arrow show which way the world pushes.
## truth: "falling" isn't a property of the void, it's a property of the field over it; change
##   the vector and the impossible crossing becomes a step.
##
## An Area3D volume. Bodies inside have their gravity replaced by field_vector (RigidBodies:
## gravity_scale 0 + velocity += field·dt; the player_body: velocity += (field − its gravity)·dt).
## The vector_machine finds this via group "force_field" and calls set_field_vector().

## ─── STAGE-2 DNA (promoted 2026-08-05) ────────────────────────────────────────
##
##  law       — which constant vector rules the volume. force_field_visualizer's
##              word, taken because it answers the same question (which law is in
##              force in here) and shares its "gravity" value meaning the same
##              thing. Its OTHER three are REFUSED: a point charge, a dipole and a
##              vortex are position-dependent fields, and this zone is a UNIFORM
##              one by construction — one vector everywhere is the whole of what it
##              argues, and _physics_process adds the same `f` to every body in the
##              box. Taking those words would name a mechanism this object lacks.
##  boundary  — how the place declares its own edge before you step into it. The
##              word is vr_tile_editor's, for the same question; its value list
##              (none|edge|cell|lattice) is refused, because a 5 m volume of space
##              has no cells and no lattice. It has a wall, a stake, or nothing.
##
##  flow_time is NOT an axis — it is the capture fixture. The face chevrons stream
##  on TIME, so two variants photographed a fraction of a second apart differ by
##  the flow phase alone and an inert axis measures as a live one. 0.0 freezes
##  them. Default 1.0 is the shipped animation, line for line.
## ──────────────────────────────────────────────────────────────────────────────

const LAWS := {
	"gravity": Vector3(0.0, -9.8, 0.0),
	"lift": Vector3(0.0, 9.8, 0.0),
	"crossing": Vector3(7.0, 7.0, 0.0),
	"weightless": Vector3.ZERO,
}
const BOUNDARIES := ["flow", "cage", "corners", "open"]

@export_enum("gravity", "lift", "crossing", "weightless") var law: String = "gravity"
@export_enum("flow", "cage", "corners", "open") var boundary: String = "flow"
@export var flow_time: float = 1.0

@export var size: float = 5.0
@export var field_vector: Vector3 = Vector3(0.0, -9.8, 0.0)   # default: gravity, down
@export var edge_color: Color = Color(0.40, 0.78, 1.0)
@export var arrow_color: Color = Color(0.55, 0.90, 1.0)

const FLOW_SHADER := preload("res://commons/artifacts/force_field_zone/force_flow.gdshader")

var _area: Area3D
var _flow_mat: ShaderMaterial            # the force-flow shader on the six faces
var _central: Node3D
var _readout: Label3D
var _scale_mat: StandardMaterial3D
var _restore: Dictionary = {}            # body -> original gravity_scale
var _pb: CharacterBody3D                  # cached player body (the thing with .velocity)
var _built: bool = false


func _ready() -> void:
	add_to_group("force_field")
	_apply_law()
	_build()
	_built = true
	set_physics_process(not Engine.is_editor_hint())


# "gravity" SHORT-CIRCUITS: the shipped field_vector is handed back untouched, so a
# map that overrides field_vector alone still gets its own vector instead of being
# reset to the table's (0, -9.8, 0). The other three name a vector and take it.
func _apply_law() -> void:
	if law == "gravity" or not LAWS.has(law):
		return
	field_vector = LAWS[law]


# Guarded twice. Before this pass the body of this function tore down every child
# and rebuilt on ANY call, including one naming nothing it owns — the force_pad
# trap. A word is taken only when it validates against the code's own list AND
# differs, and the rebuild fires only after _ready has built once, so the nine
# existing placements (which pass no keys at all) reach no assignment and no
# rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("law"):
		var l: String = str(config_data["law"]).to_lower()
		if LAWS.has(l) and l != law:
			law = l
			_apply_law()
			dirty = true
	if config_data.has("boundary"):
		var b: String = str(config_data["boundary"]).to_lower()
		if BOUNDARIES.has(b) and b != boundary:
			boundary = b
			dirty = true
	if config_data.has("size"):
		var s: float = float(config_data["size"])
		if not is_equal_approx(s, size):
			size = s
			dirty = true
	if config_data.has("emissive"):
		var e: bool = bool(config_data["emissive"])
		if e != emissive:
			emissive = e
			dirty = true
	if config_data.has("flow_time"):
		var t: float = float(config_data["flow_time"])
		if not is_equal_approx(t, flow_time):
			flow_time = t
			dirty = true
	if config_data.has("field_vector"):
		var v: Vector3 = _parse_vec(config_data["field_vector"])
		if v != field_vector:
			field_vector = v
			dirty = true
	if config_data.has("edge_color"):
		var col: Color = _parse_color(config_data["edge_color"], edge_color)
		if col != edge_color:
			edge_color = col
			dirty = true
	if not _built or not dirty:
		return
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var h := size * 0.5
	# --- the detection volume (cube sits from y=0 up to y=size, centred on x/z) --
	_area = Area3D.new()
	_area.name = "Field"
	_area.collision_layer = 0
	_area.collision_mask = 0xFFFFFFFF        # detect everything; we filter in code
	_area.position = Vector3(0, h, 0)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3.ONE * size
	cs.shape = box
	_area.add_child(cs)
	add_child(_area)

	# --- the wireframe cube edges -----------------------------------------------
	# boundary: "flow" and "cage" draw the twelve edges; "corners" leaves only the
	# eight marks that stake the volume out; "open" draws no edge at all and lets
	# the central vector be the only thing that says a place is here.
	var em := _glow_mat(edge_color, 1.4)
	var c := [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h),
		Vector3(-h, size, -h), Vector3(h, size, -h), Vector3(h, size, h), Vector3(-h, size, h)]
	var edges := [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	if boundary == "flow" or boundary == "cage":
		for e in edges:
			add_child(_cylinder_between(c[e[0]], c[e[1]], 0.025, em))
	if boundary != "open":
		for v in c:
			add_child(_sphere(v, 0.05, em))

	# --- the force shader on the six faces (chevrons stream the way F points) ----
	_flow_mat = null
	if boundary == "flow":
		_flow_mat = ShaderMaterial.new()
		_flow_mat.shader = FLOW_SHADER
		_flow_mat.set_shader_parameter("flow_color", arrow_color)
		_flow_mat.set_shader_parameter("time_scale", flow_time)
		var faces := MeshInstance3D.new()
		faces.name = "Faces"
		var bm := BoxMesh.new(); bm.size = Vector3.ONE * size
		faces.mesh = bm
		faces.material_override = _flow_mat
		faces.position = Vector3(0, h, 0)
		add_child(faces)

	# --- the big central vector + readout ---------------------------------------
	_central = Node3D.new(); _central.position = Vector3(0, h, 0); add_child(_central)
	_scale_mat = _glow_mat(arrow_color.lerp(Color.WHITE, 0.3), 2.0)
	_central.add_child(_arrow(Vector3.ZERO, Vector3(0, 1.0, 0), 0.05, _scale_mat))
	_readout = _billboard_label("", Vector3(0, size + 0.5, 0), 30, arrow_color.lerp(Color.WHITE, 0.4))
	add_child(_readout)

	_apply_vector()


# point all the arrows along the field, scale the central one by magnitude, update readout
func _apply_vector() -> void:
	var mag: float = field_vector.length()
	var dir: Vector3 = field_vector.normalized() if mag > 0.001 else Vector3.DOWN
	var b := Basis(_basis_y_to(dir))
	if _flow_mat:
		_flow_mat.set_shader_parameter("force_dir", dir)
		_flow_mat.set_shader_parameter("force_mag", mag)
	if _central:
		_central.basis = b
		_central.scale = Vector3.ONE * clampf(mag / 9.8, 0.3, 2.2)
	if _readout:
		var down: float = field_vector.dot(Vector3.UP)
		var verb: String = "FALL" if down < -1.0 else ("RISE" if down > 1.0 else "DRIFT")
		_readout.text = "FORCE FIELD\nF = (%.1f, %.1f, %.1f)\n|F| = %.1f   → %s" % [field_vector.x, field_vector.y, field_vector.z, mag, verb]


func set_field_vector(v: Vector3) -> void:
	field_vector = v
	_apply_vector()


# --- the field acts: inside, the field replaces gravity ----------------------
func _physics_process(delta: float) -> void:
	if _area == null:
		return
	var f := field_vector
	for body in _area.get_overlapping_bodies():
		if body is RigidBody3D and not (body as RigidBody3D).freeze:
			var rb := body as RigidBody3D
			if not _restore.has(rb):
				_restore[rb] = rb.gravity_scale
				rb.gravity_scale = 0.0                  # field is now the only force
			rb.linear_velocity += f * delta             # field as acceleration
	# restore gravity to bodies that have left
	for rb in _restore.keys():
		if not is_instance_valid(rb) or rb not in _area.get_overlapping_bodies():
			if is_instance_valid(rb):
				rb.gravity_scale = _restore[rb]
			_restore.erase(rb)
	# the player: while inside, net acceleration = the field (override its gravity)
	var pb := _player_body()
	if pb != null and _point_inside(pb.global_position):
		var pg := Vector3(0.0, -9.8, 0.0)
		var g = pb.get("gravity")
		if g is Vector3: pg = g
		pb.velocity += (f - pg) * delta


func _point_inside(world_pos: Vector3) -> bool:
	var local: Vector3 = to_local(world_pos) - Vector3(0, size * 0.5, 0)
	var h := size * 0.5
	return absf(local.x) < h and absf(local.y) < h and absf(local.z) < h


# The "player_body" group can hold the XROrigin3D (a plain Node3D, no .velocity) rather
# than the CharacterBody3D — so search for the body itself, then cache it.
func _player_body() -> CharacterBody3D:
	if is_instance_valid(_pb):
		return _pb
	for n in get_tree().get_nodes_in_group("player_body"):
		if n is CharacterBody3D:
			_pb = n as CharacterBody3D
			return _pb
	_pb = _find_charbody(get_tree().get_first_node_in_group("player_body"))
	return _pb


func _find_charbody(node: Node) -> CharacterBody3D:
	if node == null:
		return null
	if node is CharacterBody3D:
		return node as CharacterBody3D
	for c in node.get_children():
		var r := _find_charbody(c)
		if r != null:
			return r
	var par := node.get_parent()
	if par != null:
		for c in par.get_children():
			if c is CharacterBody3D:
				return c as CharacterBody3D
	return null


func _haze(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, 0.05)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true; m.emission = col
	m.emission_energy_multiplier = 0.15 if emissive else 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _parse_vec(v: Variant) -> Vector3:
	if v is Vector3: return v
	if v is Array and v.size() >= 3: return Vector3(float(v[0]), float(v[1]), float(v[2]))
	if v is String:
		var p: PackedStringArray = (v as String).split(",")
		if p.size() >= 3: return Vector3(float(p[0]), float(p[1]), float(p[2]))
	return field_vector
