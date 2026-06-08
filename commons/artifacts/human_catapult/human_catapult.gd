extends Node3D
class_name HumanCatapult

# @identity
# essence: a catapult that launches YOU. Walk into the basket, set the angle and
#          force, pull FIRE, and the arm flings the VR player up and away on a
#          real ballistic arc — F=ma made personal.
# desire: to put the player inside the vector. The teaching catapult throws a
#         ball at the trajectory; this one throws the player ALONG it, so the
#         parabola is felt in the body, not watched from outside.
# critical_parameter: launch_force + launch_angle — the v0 of p(t)=p0+v0*t+½g*t².
#         Together they set where you land; the live arc previews it before you commit.
# triggers: player Area3D (mask 524288 / group player_body) arms the seat; the FIRE
#           button fires; _fire() sets the player CharacterBody3D's velocity and
#           swings the arm.
# emerges: locomotion as lesson — gravity owns you the instant you leave the cup.
# needs: a heavy frame + throwing arm + a player-sized basket you can stand in
#        [present]; ANGLE/FORCE sliders + a FIRE button reachable from the basket
#        [present]; a live launch-velocity arrow + predicted parabola [present].
# relationships: sibling of the teaching `catapult` (ball) — same physics, you are
#        the payload; reuses the jump_pad / spring_hopper player-launch pattern
#        (XRToolsPlayerBody.velocity); place in an open arena (ForcesArena).
# truth: the surest way to understand a launch vector is to BE the projectile.

const PushButtonScene := "res://commons/interactables/push_button.tscn"
const SliderScene := "res://commons/interactables/slider_horizontal.tscn"

# Player body lives on physics layer 20 → mask 524288 (same as jump_pad.gd).
const PLAYER_MASK := 524288

# ── DNA ────────────────────────────────────────────────────────────────
## Launch speed given to the player (m/s).
@export var launch_force: float = 12.0
## Launch angle above horizontal (deg).
@export var launch_angle: float = 52.0
## Gravity used for the trajectory preview (player body uses project gravity).
@export var gravity_magnitude: float = 9.8
@export var frame_color: Color = Color(0.33, 0.22, 0.13)   # timber
@export var metal_color: Color = Color(0.3, 0.32, 0.36)
@export var accent_color: Color = Color(0.98, 0.62, 0.12)

# ── Runtime ────────────────────────────────────────────────────────────
var _arm_pivot: Node3D
var _basket: Node3D
var _vel_arrow: Node3D
var _traj_mesh: MeshInstance3D
var _traj_mat: StandardMaterial3D
var _readout: Label3D
var _player_node: Node3D = null
var _armed: bool = false
var _firing: bool = false
var _fire_t: float = 0.0
var _angle_deg: float = 52.0
var _force: float = 12.0
var _accent_mats: Array[StandardMaterial3D] = []
var _elapsed: float = 0.0


func _ready() -> void:
	_angle_deg = launch_angle
	_force = launch_force
	_build_frame()
	_build_arm_and_basket()
	_build_player_zone()
	_build_console()
	_build_indicators()
	_refresh()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("launch_force"): launch_force = float(config["launch_force"])
	if config.has("launch_angle"): launch_angle = float(config["launch_angle"])
	if config.has("gravity_magnitude"): gravity_magnitude = float(config["gravity_magnitude"])
	for c in get_children(): c.queue_free()
	_accent_mats.clear(); _player_node = null; _armed = false; _firing = false
	call_deferred("_ready")


# ── Build: heavy timber frame ──────────────────────────────────────────

func _build_frame() -> void:
	# Two ground sills running fore-aft + a back cross-beam.
	_box(Vector3(0.18, 0.18, 3.2), Vector3(-0.9, 0.09, 0.2), frame_color)
	_box(Vector3(0.18, 0.18, 3.2), Vector3(0.9, 0.09, 0.2), frame_color)
	_box(Vector3(2.0, 0.18, 0.18), Vector3(0.0, 0.09, -1.2), frame_color)
	# Two A-uprights carrying the axle, around z=-0.4.
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.16, 1.5, 0.16), Vector3(sx * 0.9, 0.75, -0.4), frame_color)
		# diagonal brace
		var br := _box(Vector3(0.12, 1.3, 0.12), Vector3(sx * 0.9, 0.6, -0.85), frame_color)
		br.rotation_degrees = Vector3(34, 0, 0)
	# Steel axle along X at the top of the uprights.
	var axle := _cyl(2.0, 0.07, Vector3(0, 1.45, -0.4), metal_color)
	axle.rotation_degrees = Vector3(0, 0, 90)


func _build_arm_and_basket() -> void:
	# Arm pivots on the axle (z=-0.4, y=1.45). At rest the long end is DOWN at the
	# front so the player can step into the low basket; FIRE swings it up.
	_arm_pivot = Node3D.new()
	_arm_pivot.position = Vector3(0, 1.45, -0.4)
	add_child(_arm_pivot)

	# Long throwing beam reaching +Z to the basket.
	var beam := _box(Vector3(0.14, 0.14, 3.0), Vector3(0, 0, 1.4), frame_color.lightened(0.08))
	beam.get_parent().remove_child(beam); _arm_pivot.add_child(beam)
	# Short counterweight end (−Z).
	var cw := _box(Vector3(0.5, 0.5, 0.5), Vector3(0, 0, -0.7), metal_color.darkened(0.25))
	cw.get_parent().remove_child(cw); _arm_pivot.add_child(cw)

	# Basket at the beam tip — a player-sized cup you stand in.
	_basket = Node3D.new()
	_basket.position = Vector3(0, 0, 2.7)
	_arm_pivot.add_child(_basket)
	# floor (StaticBody so the player stands on it)
	var floor_body := StaticBody3D.new()
	_basket.add_child(floor_body)
	var fmi := _box(Vector3(1.3, 0.1, 1.3), Vector3(0, 0, 0), frame_color)
	fmi.get_parent().remove_child(fmi); floor_body.add_child(fmi)
	var fcol := CollisionShape3D.new()
	var fshape := BoxShape3D.new(); fshape.size = Vector3(1.3, 0.1, 1.3)
	fcol.shape = fshape; floor_body.add_child(fcol)
	# low walls
	for w in [Vector3(0, 0.35, 0.65), Vector3(0, 0.35, -0.65), Vector3(0.65, 0.35, 0), Vector3(-0.65, 0.35, 0)]:
		var horiz: bool = absf(w.x) < 0.01
		var sz: Vector3 = Vector3(1.3, 0.55, 0.08) if horiz else Vector3(0.08, 0.55, 1.3)
		_child_box(_basket, sz, w, frame_color.lightened(0.05))
	# a back rest / harness hint
	_child_box(_basket, Vector3(1.0, 0.7, 0.08), Vector3(0, 0.6, -0.62), accent_color)

	# Arm starts pitched down at the front (basket low/forward).
	_arm_pivot.rotation_degrees = Vector3(_rest_pitch(), 0, 0)


func _rest_pitch() -> float:
	# Pitch (deg about X) that drops the +Z basket to ~ground level for boarding.
	# basket_world_y = pivot_y(1.45) - 2.7*sin(pitch); 29° → ~0.14 m.
	return 29.0


# ── Player detection zone (inside the basket) ──────────────────────────

func _build_player_zone() -> void:
	var area := Area3D.new()
	area.name = "PlayerZone"
	area.collision_layer = 0
	area.collision_mask = PLAYER_MASK
	_basket.add_child(area)
	area.position = Vector3(0, 0.6, 0)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(1.2, 1.6, 1.2)
	col.shape = box
	area.add_child(col)
	area.body_entered.connect(_on_zone_entered)
	area.body_exited.connect(_on_zone_exited)


func _on_zone_entered(body: Node3D) -> void:
	if body.is_in_group("player_body") or body is CharacterBody3D:
		_player_node = body
		_armed = true
		_set_accent_energy(2.4)   # light up: armed


func _on_zone_exited(body: Node3D) -> void:
	if body == _player_node:
		_player_node = null
		_armed = false
		_set_accent_energy(0.8)


# ── Console: ANGLE + FORCE sliders, FIRE button ────────────────────────

func _build_console() -> void:
	var console := Node3D.new()
	console.position = Vector3(1.35, 0.0, 0.4)
	console.rotation_degrees = Vector3(0, -90, 0)
	add_child(console)
	_box_at(console, Vector3(0.9, 0.9, 0.08), Vector3(0, 0.95, 0), metal_color.darkened(0.3))
	_make_slider(console, Vector3(0, 1.18, 0.06), "ANGLE", 10.0, 80.0, _angle_deg, _on_angle)
	_make_slider(console, Vector3(0, 0.95, 0.06), "FORCE", 5.0, 18.0, _force, _on_force)
	# FIRE button — reachable from inside the basket (which rests near z~2.0).
	_make_button(Vector3(0.0, 0.95, 2.5), Color(0.85, 0.18, 0.15), _on_fire)


func _on_angle(norm: float) -> void:
	_angle_deg = lerpf(10.0, 80.0, norm); _refresh()

func _on_force(norm: float) -> void:
	_force = lerpf(5.0, 18.0, norm); _refresh()


func _make_slider(parent: Node3D, pos: Vector3, label: String, lo: float, hi: float, val: float, cb: Callable) -> void:
	if not ResourceLoader.exists(SliderScene):
		return
	var s: Node3D = load(SliderScene).instantiate()
	s.position = pos
	parent.add_child(s)
	if s.has_method("set_param_name"): s.call("set_param_name", label)
	if s.has_method("set_range"): s.call("set_range", lo, hi)
	if s.has_method("set_normalized_value"): s.call("set_normalized_value", clampf((val - lo) / (hi - lo), 0.0, 1.0))
	if s.has_signal("slider_moved"): s.connect("slider_moved", func(_v): cb.call(s.call("get_normalized_value") if s.has_method("get_normalized_value") else 0.5))


func _make_button(pos: Vector3, color: Color, cb: Callable) -> void:
	if not ResourceLoader.exists(PushButtonScene):
		return
	var b: Node3D = load(PushButtonScene).instantiate()
	b.position = pos
	b.scale = Vector3.ONE * 1.8
	b.set("released_color", color)
	b.set("pressed_color", color.lightened(0.3))
	add_child(b)
	if b.has_signal("pressed"):
		b.connect("pressed", cb)
	else:
		var inner := b.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", func(_x): cb.call())
	var lab := Label3D.new()
	lab.text = "FIRE"; lab.font_size = 48; lab.pixel_size = 0.0016
	lab.position = pos + Vector3(0, 0.18, 0)
	lab.modulate = color.lightened(0.4); lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.outline_size = 6; lab.outline_modulate = Color(0, 0, 0, 0.7)
	add_child(lab)


# ── Indicators: launch-velocity arrow + predicted parabola ─────────────

func _build_indicators() -> void:
	_vel_arrow = _make_arrow(accent_color)
	add_child(_vel_arrow)
	_traj_mesh = MeshInstance3D.new()
	_traj_mat = StandardMaterial3D.new()
	_traj_mat.albedo_color = accent_color
	_traj_mat.emission_enabled = true; _traj_mat.emission = accent_color
	_traj_mat.emission_energy_multiplier = 1.4
	_traj_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_traj_mesh.material_override = _traj_mat
	add_child(_traj_mesh)
	_readout = Label3D.new()
	_readout.font_size = 34; _readout.pixel_size = 0.0013
	_readout.position = Vector3(0, 2.3, 0.2)
	_readout.modulate = Color(0.95, 0.95, 0.98)
	_readout.outline_size = 6; _readout.outline_modulate = Color(0, 0, 0, 0.7)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_readout)


func _basket_world_pos() -> Vector3:
	if is_instance_valid(_basket):
		return _basket.global_position
	return global_position + Vector3(0, 0.8, 2.2)


func _launch_dir_local() -> Vector3:
	var a := deg_to_rad(_angle_deg)
	return Vector3(0.0, sin(a), cos(a)).normalized()   # forward(+Z) + up


func _refresh() -> void:
	# Velocity arrow from the basket along the launch direction.
	var origin := _basket_world_pos() - global_position + Vector3(0, 0.5, 0)
	var dir := _launch_dir_local() * clampf(_force * 0.12, 0.4, 2.2)
	_position_arrow(_vel_arrow, origin, dir)
	# Predicted parabola p(t)=p0+v0*t+0.5*g*t^2 in local space.
	var v0 := _launch_dir_local() * _force
	var p0 := origin
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	var t := 0.0
	while t < 4.0:
		var p := p0 + v0 * t + Vector3(0, -0.5 * gravity_magnitude * t * t, 0)
		if p.y < 0.0:
			break
		st.add_vertex(p)
		t += 0.08
	var m := st.commit()
	_traj_mesh.mesh = m
	var range_flat: float = (_force * _force) * sin(2.0 * deg_to_rad(_angle_deg)) / maxf(gravity_magnitude, 0.001)
	_readout.text = "angle %d°   force %.0f m/s\nrange ~ %.0f m" % [int(round(_angle_deg)), _force, range_flat]


# ── Fire: launch the player ────────────────────────────────────────────

func _on_fire(_a = null) -> void:
	if _firing:
		return
	if not _armed or _player_node == null or not is_instance_valid(_player_node):
		_readout.text = "step into the basket first"
		return
	_fire()


func _fire() -> void:
	var world_dir: Vector3 = (global_transform.basis * _launch_dir_local()).normalized()
	var launch_vel: Vector3 = world_dir * _force
	# Launch the VR player body (CharacterBody3D); gravity arcs them down.
	if "velocity" in _player_node:
		_player_node.set("velocity", launch_vel)
	_firing = true
	_fire_t = 0.0
	_armed = false
	_set_accent_energy(3.0)


func _process(delta: float) -> void:
	_elapsed += delta
	# Arm swing on fire: rest pitch → flung up/back, then settle back.
	if _firing:
		_fire_t += delta
		var k: float = clampf(_fire_t / 0.5, 0.0, 1.0)
		var swung: float = lerpf(_rest_pitch(), -55.0, _smooth(k))
		if is_instance_valid(_arm_pivot):
			_arm_pivot.rotation_degrees.x = swung
		if _fire_t >= 1.4:
			# settle back to rest, ready to board again
			if is_instance_valid(_arm_pivot):
				_arm_pivot.rotation_degrees.x = lerpf(_arm_pivot.rotation_degrees.x, _rest_pitch(), 0.1)
			if absf(_arm_pivot.rotation_degrees.x - _rest_pitch()) < 1.0:
				_firing = false
				_set_accent_energy(0.8)
		_refresh()
	# Gentle armed pulse.
	var pulse := 1.6 + 0.8 * (0.5 + 0.5 * sin(_elapsed * 4.0))
	if _armed and not _firing:
		_set_accent_energy(pulse)


# ── Helpers ────────────────────────────────────────────────────────────

func _make_arrow(color: Color) -> Node3D:
	var root := Node3D.new()
	var shaft := MeshInstance3D.new()
	var sm := CylinderMesh.new(); sm.top_radius = 0.025; sm.bottom_radius = 0.025; sm.height = 1.0
	shaft.mesh = sm; shaft.name = "Shaft"
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new(); hm.top_radius = 0.0; hm.bottom_radius = 0.07; hm.height = 0.16
	head.mesh = hm; head.name = "Head"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color; mat.emission_enabled = true; mat.emission = color
	mat.emission_energy_multiplier = 1.6; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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
	var shaft: MeshInstance3D = arrow.get_node_or_null("Shaft")
	var head: MeshInstance3D = arrow.get_node_or_null("Head")
	var dir := vec.normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var b := Basis.looking_at(dir, up)
	# CylinderMesh axis is local Y; align Y to dir.
	var yb := Basis(b.x, dir, -b.z)
	arrow.basis = yb
	if shaft:
		shaft.position = Vector3(0, length * 0.5, 0)
		shaft.scale = Vector3(1, length, 1)
	if head:
		head.position = Vector3(0, length, 0)


func _set_accent_energy(e: float) -> void:
	for m in _accent_mats:
		m.emission_energy_multiplier = e


func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	return _box_at(self, size, pos, color)


func _child_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	return _box_at(parent, size, pos, color)


func _box_at(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.roughness = 0.7; m.metallic = 0.15
	if color == accent_color:
		m.emission_enabled = true; m.emission = accent_color; m.emission_energy_multiplier = 1.2
		_accent_mats.append(m)
	mi.material_override = m
	parent.add_child(mi)
	return mi


func _cyl(height: float, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius; cm.bottom_radius = radius; cm.height = height; cm.radial_segments = 16
	mi.mesh = cm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.metallic = 0.6; m.roughness = 0.4
	mi.material_override = m
	add_child(mi)
	return mi


func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
