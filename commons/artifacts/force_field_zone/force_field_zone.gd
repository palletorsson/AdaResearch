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

@export var size: float = 4.0
@export var field_vector: Vector3 = Vector3(0.0, -9.8, 0.0)   # default: gravity, down
@export var edge_color: Color = Color(0.40, 0.78, 1.0)
@export var arrow_color: Color = Color(0.55, 0.90, 1.0)
@export var grid_n: int = 3

var _area: Area3D
var _arrows: Array[Node3D] = []          # the field-line arrows (re-pointed on change)
var _central: Node3D
var _readout: Label3D
var _scale_mat: StandardMaterial3D
var _restore: Dictionary = {}            # body -> original gravity_scale


func _ready() -> void:
	add_to_group("force_field")
	_build()
	set_physics_process(not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("size"): size = float(config_data["size"])
	if config_data.has("grid_n"): grid_n = int(config_data["grid_n"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	field_vector = _parse_vec(config_data.get("field_vector", field_vector))
	edge_color = _parse_color(config_data.get("edge_color", edge_color), edge_color)
	for c in get_children():
		remove_child(c); c.queue_free()
	_arrows.clear()
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
	var em := _glow_mat(edge_color, 1.4)
	var c := [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h),
		Vector3(-h, size, -h), Vector3(h, size, -h), Vector3(h, size, h), Vector3(-h, size, h)]
	var edges := [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	for e in edges:
		add_child(_cylinder_between(c[e[0]], c[e[1]], 0.025, em))
	for v in c:
		add_child(_sphere(v, 0.05, em))
	# faint volume
	add_child(_box(Vector3(0, h, 0), Vector3.ONE * size, _haze(edge_color)))

	# --- the field-line arrows (a grid, re-pointed by the vector) ---------------
	var step := size / float(grid_n + 1)
	for ix in range(grid_n):
		for iy in range(grid_n):
			for iz in range(grid_n):
				var p := Vector3((ix + 1) * step - h, (iy + 1) * step, (iz + 1) * step - h)
				var a := Node3D.new()
				a.position = p
				add_child(a)
				a.add_child(_arrow(Vector3.ZERO, Vector3(0, step * 0.6, 0), 0.018, _glow_mat(arrow_color, 1.0)))
				_arrows.append(a)

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
	for a in _arrows:
		a.basis = b
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
	var pb := get_tree().get_first_node_in_group("player_body")
	if pb is Node3D and _point_inside((pb as Node3D).global_position):
		var pg := Vector3(0.0, -9.8, 0.0)
		var g = pb.get("gravity")
		if g is Vector3: pg = g
		pb.set("velocity", pb.get("velocity") + (f - pg) * delta)


func _point_inside(world_pos: Vector3) -> bool:
	var local: Vector3 = to_local(world_pos) - Vector3(0, size * 0.5, 0)
	var h := size * 0.5
	return absf(local.x) < h and absf(local.y) < h and absf(local.z) < h


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
