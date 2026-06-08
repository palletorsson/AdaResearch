extends Node3D
class_name ForcePad

# @identity
# essence: a 1x1 m launch pad — step on it and it throws you UP and FORWARD on a
#          ballistic arc. A force vector you trigger with your feet.
# desire: to make impulse bodily — the instant you touch the plate, gravity hands
#         you a velocity (up + forward) and the room rushes past.
# critical_parameter: up_force + forward_force — the two components of the launch
#         velocity v0 = forward*f̂ + up*ŷ; together they set the arc and the range.
# triggers: Area3D on the player_body layer (mask 524288); on enter, set the VR
#           player CharacterBody3D's velocity (the jump_pad / human_catapult path).
# emerges: locomotion as a vector sum — the chevrons + the glowing arrow show the
#          exact direction you'll fly before you commit your feet.
# truth: a launch is just a velocity you're given; gravity does the rest.

const PLAYER_MASK := 524288   # player body physics layer 20

@export var forward_force: float = 6.0    # m/s along the pad's forward (+Z)
@export var up_force: float = 7.0          # m/s upward
@export var cooldown_time: float = 0.8
@export var pad_color: Color = Color(0.12, 0.92, 1.0)

var _pad_mat: StandardMaterial3D
var _arrow: Node3D
var _cooldown: float = 0.0
var _pulse_t: float = 0.0
var _accent_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	_build_pad()
	_build_arrow()
	_build_area()
	_refresh_arrow()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("forward_force"): forward_force = float(config["forward_force"])
	if config.has("up_force"): up_force = float(config["up_force"])
	if config.has("cooldown_time"): cooldown_time = float(config["cooldown_time"])
	for c in get_children():
		c.queue_free()
	_accent_mats.clear()
	call_deferred("_ready")


# ── Build ───────────────────────────────────────────────────────────────

func _build_pad() -> void:
	# Recessed dark base ring (a 1x1 m footprint).
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(1.0, 0.1, 1.0)
	base.mesh = bm; base.position.y = 0.05
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.08, 0.09, 0.12)
	base_mat.metallic = 0.7; base_mat.roughness = 0.4
	base.material_override = base_mat
	add_child(base)

	# Glowing top plate (slightly inset).
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new(); pm.size = Vector3(0.9, 0.06, 0.9)
	plate.mesh = pm; plate.position.y = 0.11
	_pad_mat = StandardMaterial3D.new()
	_pad_mat.albedo_color = pad_color.darkened(0.35)
	_pad_mat.emission_enabled = true
	_pad_mat.emission = pad_color
	_pad_mat.emission_energy_multiplier = 1.6
	plate.material_override = _pad_mat
	add_child(plate)
	_accent_mats.append(_pad_mat)

	# Neon edge frame.
	for off in [Vector3(0, 0, 0.46), Vector3(0, 0, -0.46), Vector3(0.46, 0, 0), Vector3(-0.46, 0, 0)]:
		var horiz: bool = absf(off.x) < 0.01
		var sz: Vector3 = Vector3(1.0, 0.09, 0.08) if horiz else Vector3(0.08, 0.09, 1.0)
		_emissive_box(sz, off + Vector3(0, 0.06, 0), pad_color.lightened(0.2), 2.4)

	# Three forward chevrons (flat cones pointing +Z) on the surface.
	for i in range(3):
		var chev := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0; cone.bottom_radius = 0.16; cone.height = 0.22; cone.radial_segments = 4
		chev.mesh = cone
		chev.rotation_degrees = Vector3(-90, 0, 0)   # point +Z, lying flat
		chev.position = Vector3(0, 0.15, -0.28 + i * 0.26)
		var cm := StandardMaterial3D.new()
		cm.albedo_color = pad_color
		cm.emission_enabled = true; cm.emission = pad_color
		cm.emission_energy_multiplier = 2.8 - i * 0.5
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		chev.material_override = cm
		add_child(chev)
		_accent_mats.append(cm)


func _build_area() -> void:
	var area := Area3D.new()
	area.name = "LaunchZone"
	area.collision_layer = 0
	area.collision_mask = PLAYER_MASK
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(1.0, 1.5, 1.0)
	col.shape = box
	col.position.y = 0.75
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


# ── Launch ──────────────────────────────────────────────────────────────

func _launch_velocity() -> Vector3:
	var fwd := global_transform.basis.z   # pad forward (+Z), rotates with placement
	fwd.y = 0.0
	if fwd.length() < 0.01:
		fwd = Vector3(0, 0, 1)
	return fwd.normalized() * forward_force + Vector3.UP * up_force


func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0:
		return
	if body.is_in_group("player_body") or body is CharacterBody3D:
		if "velocity" in body:
			body.set("velocity", _launch_velocity())
		_cooldown = cooldown_time
		_flash()


func _flash() -> void:
	for m in _accent_mats:
		m.emission_energy_multiplier = 6.0


# ── Indicator arrow (up + forward launch vector) ───────────────────────────

func _build_arrow() -> void:
	_arrow = _make_arrow(pad_color.lightened(0.25))
	add_child(_arrow)


func _refresh_arrow() -> void:
	if not is_instance_valid(_arrow):
		return
	var v := _launch_velocity()
	var dir := v.normalized() * clampf(v.length() * 0.13, 0.6, 1.6)
	# express in local space (so it ignores the node's own rotation correctly)
	var local_dir := global_transform.basis.inverse() * (dir)
	_position_arrow(_arrow, Vector3(0, 0.2, 0), local_dir)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	_pulse_t += delta
	var pulse: float = 1.3 + 0.7 * (0.5 + 0.5 * sin(_pulse_t * 3.2))
	if _cooldown <= 0.0 and _pad_mat:
		_pad_mat.emission_energy_multiplier = pulse


# ── Helpers ────────────────────────────────────────────────────────────────

func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = energy
	mi.material_override = m
	add_child(mi)
	_accent_mats.append(m)


func _make_arrow(color: Color) -> Node3D:
	var root := Node3D.new()
	var shaft := MeshInstance3D.new()
	var sm := CylinderMesh.new(); sm.top_radius = 0.03; sm.bottom_radius = 0.03; sm.height = 1.0
	shaft.mesh = sm; shaft.name = "Shaft"
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new(); hm.top_radius = 0.0; hm.bottom_radius = 0.09; hm.height = 0.2
	head.mesh = hm; head.name = "Head"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color; mat.emission_enabled = true; mat.emission = color
	mat.emission_energy_multiplier = 2.2; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft.material_override = mat; head.material_override = mat
	root.add_child(shaft); root.add_child(head)
	_accent_mats.append(mat)
	return root


func _position_arrow(arrow: Node3D, origin: Vector3, vec: Vector3) -> void:
	if not is_instance_valid(arrow):
		return
	var length: float = vec.length()
	arrow.position = origin
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true
	var dir := vec.normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var b := Basis.looking_at(dir, up)
	arrow.basis = Basis(b.x, dir, -b.z)
	var shaft: MeshInstance3D = arrow.get_node_or_null("Shaft")
	var head: MeshInstance3D = arrow.get_node_or_null("Head")
	if shaft:
		shaft.position = Vector3(0, length * 0.5, 0)
		shaft.scale = Vector3(1, length, 1)
	if head:
		head.position = Vector3(0, length, 0)
