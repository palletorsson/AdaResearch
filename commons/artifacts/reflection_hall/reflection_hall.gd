# reflection_hall.gd
# A walk-in 5x5x3 m chamber that teaches the law of reflection through bouncing balls.
#
# @identity
# essence: r = d - 2(d.n̂)n̂. Every bounce is the same formula. The wall keeps the
#   component along itself and flips the component along its normal. Speed is
#   conserved; only the normal-direction sign changes.
# desire: To be hit. To take an incoming throw d, look up the wall's inward normal
#   n̂, and hand back the reflected ray r — drawn, named, and numbered at the exact
#   point of contact.
# critical_parameter: The dot product d.n̂ — the slice of the throw that points into
#   the wall. Double it, subtract it twice along n̂, and you have the bounce.
# triggers: throw/launch a glowing ball → it flies, leaves a fading trail, strikes a
#   wall → an annotation cluster blooms at the hit point (incident orange, normal
#   cyan, reflected magenta) with the live formula and a r ≈ v_out check.
# emerges: The felt sense that bouncing is not random — it is one deterministic
#   reflection, repeated, that the room performs for you six walls' worth of times.
# truth: A mirror does not change a vector's length. It changes the sign of one
#   component. Reflection is conservation with a flip.
extends Node3D
class_name ReflectionHall

# ── Tunable configuration (overridable via apply_grid_config) ───────────────
var room_width: float = 5.0           # X extent (interior, metres)
var room_depth: float = 5.0           # Z extent (interior, metres)
var room_height: float = 3.0          # Y extent (interior, metres)
var wall_thickness: float = 0.12
var door_width: float = 1.2           # entrance gap width (along X on -Z wall)
var door_height: float = 2.2          # entrance gap height
var ball_radius: float = 0.10
var ball_bounce: float = 0.92         # physics material restitution (engine bounces)
var ball_friction: float = 0.15
var gravity_scale: float = 0.45       # gentle gravity so balls keep bouncing
var max_live_balls: int = 6
var ball_lifetime: float = 14.0
var trail_samples: int = 64
var annotation_lifetime: float = 1.5
var auto_fire_interval: float = 3.0   # desktop/headless auto-launch cadence
var launch_speed: float = 6.0         # auto/console launch speed (m/s)

# Player body lives on physics layer 20 → mask 524288 (same as jump_pad / human_catapult).
# The doorway curtain uses this so the PLAYER passes through but BALLS do not.
const PLAYER_MASK: int = 524288
# Balls live on (and the curtain collides with) layer 2 (matches throw_ball_sphere).
const BALL_LAYER: int = 2
const WORLD_LAYER: int = 1            # walls + floor live here (balls collide with this)

# Annotation vector colours (mirror VectorProjectionReflection).
var incident_color: Color = Color(1.0, 0.5, 0.3, 1.0)   # orange  = d (incident)
var normal_color: Color = Color(0.3, 0.8, 1.0, 1.0)     # cyan    = n̂ (normal)
var reflected_color: Color = Color(1.0, 0.7, 1.0, 1.0)  # magenta = r (reflected)
var wall_color: Color = Color(0.16, 0.17, 0.22, 1.0)
var floor_color: Color = Color(0.10, 0.11, 0.14, 1.0)
var ball_color: Color = Color(0.95, 0.75, 0.25, 1.0)

const ARROW_THICKNESS: float = 0.02

# Grab-throw ball scene (primary VR interaction). Falls back gracefully if missing.
const THROW_BALL_SCENE_PATH: String = "res://algorithms/vectors/08_vector_throwing/throw_ball.tscn"

# ── Runtime state ───────────────────────────────────────────────────────────
# Each wall entry: { "body": StaticBody3D, "normal": Vector3 (inward, unit),
#                    "anchor": Vector3 (local, for labels), "name": String }
var _walls: Array = []
var _ball_container: Node3D = null
var _annotation_container: Node3D = null
var _trail_container: Node3D = null
var _rack_root: Node3D = null
var _console_root: Node3D = null
var _info_label: Label3D = null
var _bounce_counter_label: Label3D = null

var _throw_ball_scene: PackedScene = null
var _live_balls: Array = []           # Array of RigidBody3D (our launched/console balls)
var _auto_fire_timer: float = 0.0
var _have_controllers: bool = false
var _bounce_count: int = 0
var _console_dir: Vector3 = Vector3(0.4, 0.25, 1.0)  # console aim (set by sliders)
var _console_force: float = 6.0
var _angle_slider: Node3D = null
var _force_slider: Node3D = null
var _fire_button: Node3D = null

const SLIDER_SCENE := preload("res://commons/interactables/slider_horizontal.tscn")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_console_force = launch_speed

	_ball_container = Node3D.new()
	_ball_container.name = "Balls"
	add_child(_ball_container)

	_annotation_container = Node3D.new()
	_annotation_container.name = "Annotations"
	add_child(_annotation_container)

	_trail_container = Node3D.new()
	_trail_container.name = "Trails"
	add_child(_trail_container)

	if ResourceLoader.exists(THROW_BALL_SCENE_PATH):
		_throw_ball_scene = load(THROW_BALL_SCENE_PATH)

	_build_room()
	_build_doorway_curtain()
	_build_info_panel()
	_build_ball_rack()
	_build_console()

	_have_controllers = _detect_controllers()


func _process(delta: float) -> void:
	# Update fading trails for every live ball.
	_update_trails()
	_age_annotations(delta)

	# Desktop / headless fallback: auto-launch a ball into the hall periodically so a
	# capture shows bounces + annotations + trails even without VR controllers.
	if not _have_controllers:
		_auto_fire_timer += delta
		if _auto_fire_timer >= auto_fire_interval:
			_auto_fire_timer = 0.0
			_launch_console_ball()


func _physics_process(_delta: float) -> void:
	# Cache each live ball's pre-collision velocity. By the time body_entered fires,
	# the engine has already reflected linear_velocity, so we need the value from the
	# frame BEFORE contact to recover the incident vector d.
	var i: int = _live_balls.size() - 1
	while i >= 0:
		var ball = _live_balls[i]
		if not is_instance_valid(ball):
			_live_balls.remove_at(i)
		else:
			var v: Vector3 = ball.linear_velocity
			# Only overwrite the cache while moving meaningfully; preserves the last
			# real incident velocity if the engine zeroes it on the contact frame.
			if v.length() > 0.05:
				ball.set_meta("prev_vel", v)
		i -= 1


# ═════════════════════════════════════════════════════════════════════════
# ROOM GEOMETRY — six walls, one with an entrance gap
# ═════════════════════════════════════════════════════════════════════════

## Build the 6 enclosing surfaces. Interior spans x∈[-W/2,W/2], z∈[-D/2,D/2],
## y∈[0,H]. Inward normals point toward the room centre.
func _build_room() -> void:
	var hw: float = room_width * 0.5
	var hd: float = room_depth * 0.5
	var t: float = wall_thickness

	# FLOOR (normal +Y)
	_add_wall(
		"Floor",
		Vector3(0.0, -t * 0.5, 0.0),
		Vector3(room_width + t * 2.0, t, room_depth + t * 2.0),
		Vector3(0.0, 1.0, 0.0),
		Vector3(0.0, 0.02, 0.0),
		floor_color)

	# CEILING (normal -Y)
	_add_wall(
		"Ceiling",
		Vector3(0.0, room_height + t * 0.5, 0.0),
		Vector3(room_width + t * 2.0, t, room_depth + t * 2.0),
		Vector3(0.0, -1.0, 0.0),
		Vector3(0.0, room_height - 0.05, 0.0),
		wall_color)

	# +X WALL (normal -X)
	_add_wall(
		"WallXPlus",
		Vector3(hw + t * 0.5, room_height * 0.5, 0.0),
		Vector3(t, room_height, room_depth),
		Vector3(-1.0, 0.0, 0.0),
		Vector3(hw - 0.05, room_height * 0.6, 0.0),
		wall_color)

	# -X WALL (normal +X)
	_add_wall(
		"WallXMinus",
		Vector3(-hw - t * 0.5, room_height * 0.5, 0.0),
		Vector3(t, room_height, room_depth),
		Vector3(1.0, 0.0, 0.0),
		Vector3(-hw + 0.05, room_height * 0.6, 0.0),
		wall_color)

	# +Z WALL (normal -Z) — solid far wall (player faces this on entry)
	_add_wall(
		"WallZPlus",
		Vector3(0.0, room_height * 0.5, hd + t * 0.5),
		Vector3(room_width, room_height, t),
		Vector3(0.0, 0.0, -1.0),
		Vector3(0.0, room_height * 0.6, hd - 0.05),
		wall_color)

	# -Z WALL — built as TWO side panels + a lintel, leaving a door gap in the middle.
	_build_entrance_wall(hw, hd, t)


## The entrance wall (-Z side). Inward normal is +Z for all three pieces. A central
## gap of door_width x door_height is left so the player can walk through.
func _build_entrance_wall(hw: float, hd: float, t: float) -> void:
	var z_center: float = -hd - t * 0.5
	var inward: Vector3 = Vector3(0.0, 0.0, 1.0)
	var half_door: float = door_width * 0.5
	# Side panel half-widths: each fills from the wall edge to the door edge.
	var side_w: float = hw - half_door
	if side_w < 0.05:
		side_w = 0.05
	var side_center_x: float = half_door + side_w * 0.5

	# Left side panel (-X side of the door)
	_add_wall(
		"EntranceLeft",
		Vector3(-side_center_x, room_height * 0.5, z_center),
		Vector3(side_w, room_height, t),
		inward,
		Vector3(-side_center_x, room_height * 0.6, z_center + 0.05),
		wall_color)

	# Right side panel (+X side of the door)
	_add_wall(
		"EntranceRight",
		Vector3(side_center_x, room_height * 0.5, z_center),
		Vector3(side_w, room_height, t),
		inward,
		Vector3(side_center_x, room_height * 0.6, z_center + 0.05),
		wall_color)

	# Lintel above the door gap (fills door_height..room_height across the gap)
	var lintel_h: float = room_height - door_height
	if lintel_h > 0.02:
		_add_wall(
			"EntranceLintel",
			Vector3(0.0, door_height + lintel_h * 0.5, z_center),
			Vector3(door_width, lintel_h, t),
			inward,
			Vector3(0.0, door_height + lintel_h * 0.5, z_center + 0.05),
			wall_color)


## Create one StaticBody3D wall (collision + visible mesh) and register it in _walls
## with its inward unit normal and a local label anchor.
func _add_wall(wall_name: String, center: Vector3, size: Vector3,
		inward_normal: Vector3, label_anchor: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.position = center
	# Walls on the world layer so balls (mask includes layer 1) collide with them.
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	add_child(body)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _make_material(color, 0.0, 0.85, 0.05)
	body.add_child(mesh)

	# Tag the wall body with its index into _walls so a ball's body_entered handler
	# can recover the normal. (StaticBody3D has no body_entered signal — the moving
	# RigidBody ball is the contact reporter, so the lookup happens on the ball side.)
	body.set_meta("wall_idx", _walls.size())
	_walls.append({
		"body": body,
		"normal": inward_normal.normalized(),
		"anchor": label_anchor,
		"name": wall_name,
	})


## Invisible "doorway curtain" across the entrance gap.
##
## The trick: collision is symmetric — two bodies interact only when EITHER masks
## the other's layer. The XR player body collides with the WORLD layer (1) for
## floors/walls but does NOT mask BALL_LAYER (2). Our balls DO mask BALL_LAYER.
## So a static curtain placed on BALL_LAYER *only* (not the world layer) is solid
## to balls (they keep their throws inside) and invisible to the player (who walks
## straight through the entrance). We also register it as a +Z reflective surface
## so a bounce off the curtain gets annotated like any wall.
func _build_doorway_curtain() -> void:
	var hd: float = room_depth * 0.5
	var t: float = wall_thickness
	var z_center: float = -hd - t * 0.5

	var curtain := StaticBody3D.new()
	curtain.name = "DoorwayCurtain"
	curtain.position = Vector3(0.0, door_height * 0.5, z_center)
	# BALL_LAYER only: balls mask this (blocked), the player does not (passes through).
	curtain.collision_layer = BALL_LAYER
	curtain.collision_mask = 0
	add_child(curtain)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(door_width, door_height, t)
	col.shape = shape
	curtain.add_child(col)

	# Register as a reflective surface (inward normal +Z) so a ball that bounces
	# off the curtain also gets annotated.
	var z_anchor: float = z_center + 0.05
	curtain.set_meta("wall_idx", _walls.size())
	_walls.append({
		"body": curtain,
		"normal": Vector3(0.0, 0.0, 1.0),
		"anchor": Vector3(0.0, door_height * 0.6, z_anchor),
		"name": "DoorwayCurtain",
	})


# ═════════════════════════════════════════════════════════════════════════
# INFO PANEL + RACK + CONSOLE (by the entrance)
# ═════════════════════════════════════════════════════════════════════════

## A persistent panel showing the static reflection formula, near the entrance,
## facing into the room.
func _build_info_panel() -> void:
	var hd: float = room_depth * 0.5
	var panel := Node3D.new()
	panel.name = "InfoPanel"
	# Mounted on the +X side near the entrance, facing -X into the room.
	panel.position = Vector3(room_width * 0.5 - 0.08, 1.6, -hd + 0.9)
	panel.rotation = Vector3(0.0, deg_to_rad(-90.0), 0.0)
	add_child(panel)

	var backing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.8, 1.0, 0.02)
	backing.mesh = box
	backing.material_override = _make_material(Color(0.04, 0.05, 0.07, 0.92), 0.0, 0.85, 0.1)
	panel.add_child(backing)

	var title := _make_label("LAW OF REFLECTION", Color(0.9, 0.95, 1.0), 26)
	title.position = Vector3(0.0, 0.36, 0.02)
	panel.add_child(title)

	_info_label = _make_label(
		"r = d - 2(d.n̂)n̂\n\nd : incident (orange)\nn̂ : wall normal (cyan)\nr : reflected (magenta)\n\nSpeed is conserved.\nOnly the normal sign flips.",
		Color(0.8, 0.9, 1.0), 18)
	_info_label.position = Vector3(0.0, -0.05, 0.02)
	panel.add_child(_info_label)

	# A small live bounce counter under the formula.
	_bounce_counter_label = _make_label("bounces: 0", Color(1.0, 0.85, 0.4), 16)
	_bounce_counter_label.position = Vector3(0.0, -0.42, 0.02)
	panel.add_child(_bounce_counter_label)


## A small rack of grab-throw balls by the entrance (primary VR interaction).
func _build_ball_rack() -> void:
	_rack_root = Node3D.new()
	_rack_root.name = "BallRack"
	var hd: float = room_depth * 0.5
	# Just inside the entrance, on the floor.
	_rack_root.position = Vector3(-room_width * 0.5 + 0.6, 0.0, -hd + 0.7)
	add_child(_rack_root)

	# A simple shelf for the balls to rest on.
	var shelf := MeshInstance3D.new()
	var shelf_box := BoxMesh.new()
	shelf_box.size = Vector3(1.0, 0.05, 0.3)
	shelf.mesh = shelf_box
	shelf.material_override = _make_material(Color(0.2, 0.21, 0.25), 0.0, 0.7, 0.2)
	shelf.position = Vector3(0.0, 0.9, 0.0)
	_rack_root.add_child(shelf)

	var rack_label := _make_label("THROW ME", Color(0.95, 0.8, 0.3), 18)
	rack_label.position = Vector3(0.0, 1.25, 0.0)
	_rack_root.add_child(rack_label)

	# Instance up to 3 grab-throw balls resting on the shelf.
	if _throw_ball_scene != null:
		var offsets: Array = [-0.32, 0.0, 0.32]
		for ox in offsets:
			var b = _throw_ball_scene.instantiate()
			if b == null:
				continue
			b.position = Vector3(ox, 1.0, 0.0)
			if b.has_method("set_ball_color"):
				b.call("set_ball_color", ball_color)
			_rack_root.add_child(b)
			# The grab-throw ball masks world layer 1 (walls) by default; add
			# BALL_LAYER so it also collides with the doorway curtain and stays in.
			if b is RigidBody3D:
				var rb := b as RigidBody3D
				rb.collision_mask = rb.collision_mask | BALL_LAYER
				# Track it for bounce capture (prev_vel cache + trail + annotation).
				# It starts frozen; the _physics_process cache only writes while moving,
				# so prev_vel becomes valid once the player throws it.
				rb.set_meta("prev_vel", Vector3.ZERO)
				rb.set_meta("trail", PackedVector3Array())
				rb.set_meta("trail_mesh", _make_trail_mesh(rb))
				_register_ball(rb, false)


## An optional fixed launcher console (ANGLE / FORCE / FIRE) for desktop / headless.
func _build_console() -> void:
	_console_root = Node3D.new()
	_console_root.name = "Console"
	var hd: float = room_depth * 0.5
	# By the entrance, aimed into the hall (+Z / +X).
	_console_root.position = Vector3(room_width * 0.5 - 0.7, 0.0, -hd + 0.6)
	add_child(_console_root)

	var panel := MeshInstance3D.new()
	var panel_box := BoxMesh.new()
	panel_box.size = Vector3(0.7, 0.32, 0.04)
	panel.mesh = panel_box
	panel.material_override = _make_material(Color(0.10, 0.11, 0.13), 0.05, 0.6, 0.4)
	panel.position = Vector3(0.0, 1.0, 0.0)
	panel.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	_console_root.add_child(panel)

	# ANGLE slider (controls vertical aim component)
	_angle_slider = SLIDER_SCENE.instantiate()
	_angle_slider.position = Vector3(-0.18, 1.06, 0.05)
	_angle_slider.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	_console_root.add_child(_angle_slider)
	if _angle_slider.has_method("set_param_name"):
		_angle_slider.call("set_param_name", "ANGLE")
	if _angle_slider.has_method("set_normalized_value"):
		_angle_slider.call("set_normalized_value", 0.4)
	if _angle_slider.has_signal("slider_moved"):
		_angle_slider.connect("slider_moved", Callable(self, "_on_angle_slider_moved"))

	# FORCE slider
	_force_slider = SLIDER_SCENE.instantiate()
	_force_slider.position = Vector3(0.18, 1.06, 0.05)
	_force_slider.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	_console_root.add_child(_force_slider)
	if _force_slider.has_method("set_param_name"):
		_force_slider.call("set_param_name", "FORCE")
	if _force_slider.has_method("set_normalized_value"):
		_force_slider.call("set_normalized_value", 0.5)
	if _force_slider.has_signal("slider_moved"):
		_force_slider.connect("slider_moved", Callable(self, "_on_force_slider_moved"))

	# FIRE button
	_fire_button = BUTTON_SCENE.instantiate()
	_fire_button.position = Vector3(0.0, 0.92, 0.07)
	_fire_button.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	_fire_button.set("pressed_color", Color(1.0, 0.35, 0.10))
	_fire_button.set("released_color", Color(0.90, 0.85, 0.30))
	_console_root.add_child(_fire_button)
	if _fire_button.has_signal("pressed"):
		_fire_button.connect("pressed", Callable(self, "_on_fire_pressed"))
	else:
		var inner := _fire_button.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_fire_button_inner"))
	if _fire_button.has_method("update_colors"):
		_fire_button.call_deferred("update_colors")

	var fire_lbl := _make_label("FIRE", Color(1.0, 0.6, 0.3), 18)
	fire_lbl.position = Vector3(0.0, 0.78, 0.06)
	_console_root.add_child(fire_lbl)


func _on_angle_slider_moved(_value) -> void:
	_refresh_console_dir()


func _on_force_slider_moved(_value) -> void:
	var norm: float = 0.5
	if _force_slider and _force_slider.has_method("get_normalized_value"):
		norm = float(_force_slider.call("get_normalized_value"))
	_console_force = lerp(3.0, launch_speed * 1.5, clampf(norm, 0.0, 1.0))


func _on_fire_pressed() -> void:
	_launch_console_ball()


func _on_fire_button_inner(_button) -> void:
	_launch_console_ball()


func _refresh_console_dir() -> void:
	var norm: float = 0.4
	if _angle_slider and _angle_slider.has_method("get_normalized_value"):
		norm = float(_angle_slider.call("get_normalized_value"))
	# Map slider to an elevation 5..55 deg, aimed into the hall (+Z, slight +X).
	var elev: float = deg_to_rad(lerp(5.0, 55.0, clampf(norm, 0.0, 1.0)))
	_console_dir = Vector3(0.35, sin(elev), cos(elev)).normalized()


# ═════════════════════════════════════════════════════════════════════════
# BALL LAUNCH (console / auto-fire) — RigidBody with bounce physics material
# ═════════════════════════════════════════════════════════════════════════

## Launch a glowing physics ball from the console into the hall. The engine handles
## the bounce (via the physics material); we only visualise it.
func _launch_console_ball() -> void:
	_prune_balls()
	if _console_root == null:
		return

	var ball := RigidBody3D.new()
	ball.name = "ReflectBall"
	ball.mass = 0.4
	ball.gravity_scale = gravity_scale
	ball.linear_damp = 0.0
	ball.angular_damp = 0.4
	ball.contact_monitor = true
	ball.max_contacts_reported = 6
	ball.continuous_cd = true
	# Ball on layer 2; collides with world (1) walls + the doorway curtain (layer 2).
	ball.collision_layer = BALL_LAYER
	ball.collision_mask = WORLD_LAYER | BALL_LAYER

	var phys := PhysicsMaterial.new()
	phys.bounce = ball_bounce
	phys.friction = ball_friction
	ball.physics_material_override = phys

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	mesh.mesh = sphere
	mesh.material_override = _make_material(ball_color, 0.6, 0.4, 0.1)
	ball.add_child(mesh)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = ball_radius
	col.shape = shape
	ball.add_child(col)

	# A velocity arrow riding the ball.
	var vel_arrow := _create_arrow("BallVelocity", reflected_color)
	ball.add_child(vel_arrow)
	ball.set_meta("vel_arrow", vel_arrow)

	# Spawn just inside the entrance, slightly above the console.
	var hd: float = room_depth * 0.5
	var spawn_local := Vector3(room_width * 0.5 - 0.7, 1.2, -hd + 0.8)
	_ball_container.add_child(ball)
	ball.transform = Transform3D(Basis.IDENTITY, spawn_local)

	var v_local: Vector3 = _console_dir * _console_force
	var v_world: Vector3 = global_transform.basis * v_local
	ball.linear_velocity = v_world
	ball.set_meta("prev_vel", v_world)
	ball.set_meta("trail", PackedVector3Array())
	ball.set_meta("trail_mesh", _make_trail_mesh(ball))

	_register_ball(ball)
	_orient_ball_arrow(ball, v_world)


## Register a ball: track it, connect bounce reporting, and (for launched balls only)
## start a lifetime timer. Rack grab-balls pass with_lifetime=false so they persist.
func _register_ball(ball: RigidBody3D, with_lifetime: bool = true) -> void:
	_live_balls.append(ball)

	# The moving ball is the contact reporter. body_entered passes the OTHER body
	# (the wall it hit); we bind the ball itself so the handler has both. Called once
	# per ball at creation, so no duplicate-connection guard is needed.
	ball.connect("body_entered", Callable(self, "_on_ball_body_entered").bind(ball))

	if with_lifetime:
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = ball_lifetime
		ball.add_child(timer)
		timer.timeout.connect(ball.queue_free)
		timer.start()


## Remove oldest live balls (and their trail meshes) when over the cap.
func _prune_balls() -> void:
	# Drop invalid entries first.
	var j: int = _live_balls.size() - 1
	while j >= 0:
		if not is_instance_valid(_live_balls[j]):
			_live_balls.remove_at(j)
		j -= 1
	while _live_balls.size() >= max_live_balls and _live_balls.size() > 0:
		var oldest = _live_balls[0]
		_live_balls.remove_at(0)
		if is_instance_valid(oldest):
			if oldest.has_meta("trail_mesh"):
				var tm = oldest.get_meta("trail_mesh")
				if is_instance_valid(tm):
					tm.queue_free()
			oldest.queue_free()


# ═════════════════════════════════════════════════════════════════════════
# BOUNCE CAPTURE — the core: d, n̂, r annotation cluster at the hit point
# ═════════════════════════════════════════════════════════════════════════

## Bounce handler. `wall_body` is the surface the ball touched (passed by the ball's
## body_entered signal); `ball` is the bound moving body. If the touched body is one
## of our registered reflective surfaces, compute r = d - 2(d.n̂)n̂ and annotate.
func _on_ball_body_entered(wall_body: Node, ball: Node) -> void:
	if ball == null or not (ball is RigidBody3D):
		return
	if wall_body == null or not wall_body.has_meta("wall_idx"):
		return
	if not ball.has_meta("prev_vel"):
		return

	var wall_idx: int = int(wall_body.get_meta("wall_idx"))
	if wall_idx < 0 or wall_idx >= _walls.size():
		return

	var wall: Dictionary = _walls[wall_idx]
	var n_hat: Vector3 = wall.get("normal", Vector3.UP)
	# Incident in WORLD space (engine already reflected linear_velocity by now).
	var d_world: Vector3 = ball.get_meta("prev_vel")
	if d_world.length() < 0.05:
		return

	# The wall normal is stored in this node's LOCAL frame; express it in world space
	# (rotation only — a normal is a free direction).
	var n_world: Vector3 = (global_transform.basis * n_hat).normalized()

	# Reflection: r = d - 2(d.n̂)n̂  (the law of reflection)
	var d_dot_n: float = d_world.dot(n_world)
	var r_world: Vector3 = d_world - 2.0 * d_dot_n * n_world

	# The hit point: approximate by the ball's current global position (at contact).
	var hit_world: Vector3 = ball.global_position

	# Verification check: r should match the ball's post-bounce velocity.
	var v_out: Vector3 = ball.linear_velocity
	var ok: bool = false
	if v_out.length() > 0.05:
		var match_err: float = (r_world.normalized() - v_out.normalized()).length()
		ok = match_err < 0.3

	_spawn_annotation(hit_world, d_world, n_world, r_world, d_dot_n, ok)

	_bounce_count += 1
	if _bounce_counter_label:
		_bounce_counter_label.text = "bounces: %d" % _bounce_count

	# Re-orient the riding arrow along the new (reflected) velocity.
	if ball.has_meta("vel_arrow"):
		_orient_ball_arrow(ball, v_out)


## Spawn a short-lived annotation cluster at the hit point (world space): incident
## d (orange), normal n̂ (cyan), reflected r (magenta) arrows + a live-formula label.
func _spawn_annotation(hit_world: Vector3, d_world: Vector3, n_world: Vector3,
		r_world: Vector3, d_dot_n: float, ok: bool) -> void:
	var cluster := Node3D.new()
	cluster.name = "BounceAnnotation"
	_annotation_container.add_child(cluster)
	# Place the cluster at the hit point. Container is a child of self, so convert
	# the world hit point into the container's local frame.
	cluster.global_position = hit_world

	# Visual scale: arrows are direction handles, not full metric length.
	var vscale: float = 0.12

	# Incident d: drawn arriving INTO the hit point (from -d back to the point).
	# We draw it as an arrow pointing along d, tail offset back along -d.
	var inc_arrow := _create_arrow("Incident", incident_color)
	cluster.add_child(inc_arrow)
	_position_arrow(inc_arrow, -d_world * vscale, Vector3.ZERO)

	# Normal n̂: short fixed-length arrow along the inward normal.
	var norm_arrow := _create_arrow("Normal", normal_color)
	cluster.add_child(norm_arrow)
	_position_arrow(norm_arrow, Vector3.ZERO, n_world * 0.5)

	# Reflected r: leaving the hit point along r.
	var refl_arrow := _create_arrow("Reflected", reflected_color)
	cluster.add_child(refl_arrow)
	_position_arrow(refl_arrow, Vector3.ZERO, r_world * vscale)

	# Live-formula label with numbers + verification check.
	var check_str: String = "✓ r ≈ v_out" if ok else "~ r vs v_out"
	var label := _make_label(
		"r = d - 2(d.n̂)n̂\nd=(%.1f, %.1f, %.1f)\nn̂=(%.1f, %.1f, %.1f)\nd·n̂=%.2f\nr=(%.1f, %.1f, %.1f)\n%s" % [
			d_world.x, d_world.y, d_world.z,
			n_world.x, n_world.y, n_world.z,
			d_dot_n,
			r_world.x, r_world.y, r_world.z,
			check_str],
		Color(0.9, 0.95, 1.0), 14)
	label.position = Vector3(0.0, 0.35, 0.0)
	cluster.add_child(label)

	# Age the cluster so it fades and frees itself.
	cluster.set_meta("age", 0.0)


## Fade and free annotation clusters over annotation_lifetime.
func _age_annotations(delta: float) -> void:
	if _annotation_container == null:
		return
	for cluster in _annotation_container.get_children():
		if not (cluster is Node3D):
			continue
		var age: float = float(cluster.get_meta("age", 0.0)) + delta
		cluster.set_meta("age", age)
		var u: float = clampf(age / annotation_lifetime, 0.0, 1.0)
		var alpha: float = 1.0 - u
		_fade_node_tree(cluster, alpha)
		if age >= annotation_lifetime:
			cluster.queue_free()


## Recursively set albedo/emission alpha on every mesh + label under a node.
func _fade_node_tree(node: Node, alpha: float) -> void:
	if node is Label3D:
		var lbl := node as Label3D
		var m: Color = lbl.modulate
		m.a = alpha
		lbl.modulate = m
	elif node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat = mi.material_override
		if mat is StandardMaterial3D:
			var sm := mat as StandardMaterial3D
			sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var c: Color = sm.albedo_color
			c.a = alpha
			sm.albedo_color = c
	for child in node.get_children():
		_fade_node_tree(child, alpha)


# ═════════════════════════════════════════════════════════════════════════
# FADING TRAILS — per-ball ring buffer → ImmediateMesh line strip
# ═════════════════════════════════════════════════════════════════════════

## Build a dedicated trail mesh instance for a ball (lives under _trail_container,
## drawn in this node's local space).
func _make_trail_mesh(_ball: RigidBody3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Trail"
	var im := ImmediateMesh.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = ball_color
	mat.emission_energy_multiplier = 0.6
	mi.material_override = mat
	_trail_container.add_child(mi)
	return mi


## Each frame: append the ball's position to its ring buffer and redraw the trail
## as a line strip whose alpha fades from tail (old, faint) to head (new, bright).
func _update_trails() -> void:
	var k: int = _live_balls.size() - 1
	while k >= 0:
		var ball = _live_balls[k]
		if not is_instance_valid(ball):
			_live_balls.remove_at(k)
			k -= 1
			continue
		if not ball.has_meta("trail") or not ball.has_meta("trail_mesh"):
			k -= 1
			continue

		var buf: PackedVector3Array = ball.get_meta("trail")
		# Store in this node's local space so the mesh (a child) draws correctly.
		buf.append(to_local(ball.global_position))
		while buf.size() > trail_samples:
			buf.remove_at(0)
		ball.set_meta("trail", buf)

		var tm = ball.get_meta("trail_mesh")
		if is_instance_valid(tm):
			_redraw_trail(tm, buf)
		k -= 1


func _redraw_trail(mesh_instance: MeshInstance3D, buf: PackedVector3Array) -> void:
	var im := mesh_instance.mesh as ImmediateMesh
	if im == null:
		return
	im.clear_surfaces()
	if buf.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var count: int = buf.size()
	for idx in range(count):
		# Fade from faint tail (idx 0) to bright head (idx count-1).
		var frac: float = float(idx) / float(max(count - 1, 1))
		var c: Color = ball_color
		c.a = frac
		im.surface_set_color(c)
		im.surface_add_vertex(buf[idx])
	im.surface_end()


# ═════════════════════════════════════════════════════════════════════════
# ARROWS (map-rotation-safe) — mirror catapult._create_arrow/_position_arrow
# ═════════════════════════════════════════════════════════════════════════

func _create_arrow(arrow_name: String, color: Color) -> Node3D:
	var arrow := Node3D.new()
	arrow.name = arrow_name

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = ARROW_THICKNESS
	cylinder.bottom_radius = ARROW_THICKNESS
	cylinder.height = 1.0
	shaft.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft.material_override = mat
	arrow.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = ARROW_THICKNESS * 2.5
	cone.height = ARROW_THICKNESS * 5.0
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)

	return arrow


## Position an arrow from start to end (both in the arrow's PARENT local space).
## Uses parent global basis for a correct world look_at — stays correct under map
## rotation/scale. Mirrors catapult._position_arrow.
func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3) -> void:
	var dir: Vector3 = end - start
	var length: float = dir.length()
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true

	arrow.transform = Transform3D.IDENTITY
	arrow.position = start

	var shaft: Node3D = arrow.get_node_or_null("Shaft")
	var head: Node3D = arrow.get_node_or_null("Head")
	if shaft == null or head == null:
		return

	var shaft_length: float = length - ARROW_THICKNESS * 5.0
	if shaft_length < 0.01:
		shaft_length = 0.01
	shaft.scale = Vector3(1.0, shaft_length, 1.0)
	shaft.position = dir.normalized() * (shaft_length / 2.0)
	head.position = dir.normalized() * (length - ARROW_THICKNESS * 2.5)

	var parent := arrow.get_parent() as Node3D
	var world_dir: Vector3 = dir
	if parent:
		world_dir = parent.global_transform.basis * dir
	var up: Vector3 = Vector3.UP
	if world_dir.length() > 0.0001 and absf(world_dir.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	if world_dir.length() > 0.0001:
		arrow.look_at(arrow.global_position + world_dir, up)
		arrow.rotate_object_local(Vector3.RIGHT, PI / 2.0)


## Orient a ball's riding velocity arrow along v_world (clamped visual length).
func _orient_ball_arrow(ball: RigidBody3D, v_world: Vector3) -> void:
	if not is_instance_valid(ball) or not ball.has_meta("vel_arrow"):
		return
	var arrow = ball.get_meta("vel_arrow")
	if arrow == null or not is_instance_valid(arrow):
		return
	if v_world.length() < 0.05:
		arrow.visible = false
		return
	var local_dir: Vector3 = ball.global_transform.basis.inverse() * v_world
	var dir: Vector3 = local_dir.normalized() * clampf(v_world.length() * 0.06, 0.15, 0.6)
	_position_arrow(arrow, Vector3.ZERO, dir)


# ═════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═════════════════════════════════════════════════════════════════════════

func _detect_controllers() -> bool:
	# Guarded controller detection: look for an active XRController3D in the tree.
	if not is_inside_tree():
		return false
	var tree := get_tree()
	if tree == null:
		return false
	var root: Window = tree.get_root()
	if root == null:
		return false
	return _find_active_controller(root)


func _find_active_controller(node: Node) -> bool:
	if node is XRController3D:
		var c := node as XRController3D
		# has_method guard mirrors vector_arena.gd — robust to stale trackers.
		if c.has_method("get_is_active") and c.get_is_active():
			return true
	for child in node.get_children():
		if _find_active_controller(child):
			return true
	return false


func _make_material(color: Color, emission_energy: float = 0.0,
		roughness: float = 0.6, metallic: float = 0.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	return mat


func _make_label(text: String, color: Color, font_size: int = 22) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.outline_size = max(2, font_size / 6)
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0014
	label.no_depth_test = false
	return label


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════════

## Accept overrides from the map/grid system. Safe to call before or after _ready.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("room_width"):
		room_width = float(config["room_width"])
	if config.has("room_depth"):
		room_depth = float(config["room_depth"])
	if config.has("room_height"):
		room_height = float(config["room_height"])
	if config.has("door_width"):
		door_width = float(config["door_width"])
	if config.has("door_height"):
		door_height = float(config["door_height"])
	if config.has("ball_bounce"):
		ball_bounce = float(config["ball_bounce"])
	if config.has("gravity_scale"):
		gravity_scale = float(config["gravity_scale"])
	if config.has("launch_speed"):
		launch_speed = float(config["launch_speed"])
		_console_force = launch_speed
	if config.has("auto_fire_interval"):
		auto_fire_interval = float(config["auto_fire_interval"])
	if config.has("max_live_balls"):
		max_live_balls = int(config["max_live_balls"])
	if config.has("ball_color") and config["ball_color"] is Color:
		ball_color = config["ball_color"]


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
