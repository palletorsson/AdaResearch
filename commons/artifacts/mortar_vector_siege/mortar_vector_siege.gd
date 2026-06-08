# MortarVectorSiege.gd
# A player-held VR mortar that area-bombs a swarm of flying drones.
#
# @identity
# essence: v0 = aim_dir * force, then p(t) = p0 + v0*t + 0.5*g*t^2. You set the
#   direction by TILTING your hand and the magnitude by HOLDING the trigger. The
#   shell's whole arc — and the patch of ground it will scorch — is already
#   written the instant you let go. Aim is prediction.
# desire: To lob. To tip the tube, feel the charge swell, release, and watch a
#   shell fall on a drone you could not have hit by pointing straight at it.
# critical_parameter: aim_dir (hand tilt) * _force (charge time). Direction and
#   magnitude together pick where the parabola crosses the floor — the AoE ring.
# triggers: tilt tube → live parabola + AoE ring sweep across the ground; hold
#   trigger → force bar fills + velocity arrow grows; release → RigidBody shell
#   flies the previewed arc and detonates; splash pops every drone in radius.
# emerges: The felt difference between a direct-fire vector (turret: point AT it)
#   and an indirect-fire vector (mortar: aim a parabola so its FOOT lands on it).
#   Gravity is not the enemy of the shot — it is the shot.
# truth: You aim the launch; gravity aims the landing. Hit the foot of the curve.
extends Node3D
class_name MortarVectorSiege

# ── Tunable configuration (overridable via apply_grid_config) ───────────────
var gravity_magnitude: float = 9.8          # m/s^2, downward
var min_force: float = 6.0                   # launch speed at start of charge
var max_force: float = 22.0                  # launch speed at full charge
var charge_time: float = 1.2                 # seconds min->max while holding trigger
var aoe_radius: float = 2.2                  # splash radius (metres) on the floor
var reload_cooldown: float = 1.4             # seconds before the cosmetic shell returns
var shell_lifetime: float = 7.0              # safety cull for live shells
var max_live_shells: int = 6                 # hard cap on simultaneous shells
var floor_y: float = 0.0                     # local-space floor height for analytic impact
var drone_count: int = 6                     # swarm size
var arena_radius: float = 9.0                # roam radius for the swarm + ground disc

# Desktop / headless fallback
var auto_fire_interval: float = 3.0          # seconds between auto-shots when no controller

# Colors
var tube_color: Color = Color(0.22, 0.24, 0.27)
var tube_accent: Color = Color(0.85, 0.55, 0.20)
var shell_color: Color = Color(0.90, 0.78, 0.30)
var velocity_arrow_color: Color = Color(0.20, 1.0, 0.55)   # green = the throw
var gravity_arrow_color: Color = Color(1.0, 0.30, 0.30)    # red = constant down
var trajectory_color: Color = Color(1.0, 0.95, 0.55)       # yellow parabola
var aoe_color: Color = Color(1.0, 0.45, 0.20)              # orange ground ring
var drone_color: Color = Color(0.55, 0.75, 1.0)            # cool blue swarm

# ── Geometry constants (local space of the tube) ────────────────────────────
const TUBE_LENGTH: float = 0.55
const TUBE_RADIUS: float = 0.07
const ARROW_THICKNESS: float = 0.016
const AOE_SEGMENTS: int = 40
const RING_SEGMENTS: int = 28

# ── Runtime state ───────────────────────────────────────────────────────────
var _force: float = 6.0
var _charging: bool = false
var _charge_t: float = 0.0
var _reload_t: float = 0.0
var _can_fire: bool = true
var _score: int = 0
var _drones_popped: int = 0
var _auto_timer: float = 0.0
var _prev_trigger: bool = false
var _prev_grip: bool = false

# Node references
var _tube: Node3D = null                     # grabbable tube (XRToolsPickable when in VR)
var _muzzle: Marker3D = null                 # tip of the tube (p0 origin)
var _loaded_shell: MeshInstance3D = null     # cosmetic shell in the tube
var _force_bar: MeshInstance3D = null        # charge fill indicator on the tube
var _force_bar_mat: StandardMaterial3D = null

var _velocity_arrow: Node3D = null
var _gravity_arrow: Node3D = null
var _velocity_label: Label3D = null
var _gravity_label: Label3D = null
var _readout_label: Label3D = null

var _trajectory_mesh: ImmediateMesh = null
var _trajectory_instance: MeshInstance3D = null
var _aoe_ring: Node3D = null                 # ground AoE preview ring (child cylinders)
var _aoe_segment_meshes: Array = []          # reusable segment MeshInstance3D nodes

var _shell_container: Node3D = null
var _drone_container: Node3D = null
var _drones: Array = []                      # live _MortarDrone nodes

# Held-controller acquisition (cached when grabbed)
var _controller: XRController3D = null

# Preloaded interactables (kept for parity with sibling artifacts; auto-charge is
# the primary control, but a console FIRE/RELOAD pair lives on the base too).
const SLIDER_SCENE := preload("res://commons/interactables/slider_horizontal.tscn")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")

signal fired(launch_velocity: Vector3)
signal detonated(impact: Vector3, hits: int)


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_force = min_force

	_shell_container = Node3D.new()
	_shell_container.name = "Shells"
	add_child(_shell_container)

	_drone_container = Node3D.new()
	_drone_container.name = "Drones"
	add_child(_drone_container)

	_build_ground_disc()
	_build_tube()
	_build_vector_indicators()
	_build_trajectory_preview()
	_build_aoe_ring()
	_build_console()
	_build_readout()
	_spawn_swarm()

	_refresh_visuals()


func _process(delta: float) -> void:
	_update_charge(delta)
	_poll_controller()
	_update_swarm(delta)
	_refresh_visuals()


# ═════════════════════════════════════════════════════════════════════════
# TUBE (grabbable) + MUZZLE + COSMETIC SHELL
# ═════════════════════════════════════════════════════════════════════════

## The tube is the held object. We attach the XRToolsPickable script so a VR hand
## can grab it; when grabbed we read the holder controller for aim + trigger.
func _build_tube() -> void:
	# When the XRTools addon is present the tube must be a RigidBody3D (the
	# pickable script extends RigidBody3D); otherwise a plain Node3D is enough for
	# the desktop/headless auto-aim path. _tube is typed Node3D either way.
	var has_pickable := ResourceLoader.exists("res://addons/godot-xr-tools/objects/pickable.gd")
	if has_pickable:
		var body := RigidBody3D.new()
		body.freeze = true                      # held in place until a hand grabs it
		body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		body.collision_layer = 1 << 17          # grab layer, away from world/floor
		body.collision_mask = 0
		_tube = body
	else:
		_tube = Node3D.new()
	_tube.name = "MortarTube"
	# Sit the tube a little above the base, tilted up to a default ~55deg so a
	# headless capture shows a believable arc before any input arrives.
	_tube.position = Vector3(0.0, 0.95, 0.0)
	_tube.rotation = Vector3(deg_to_rad(-55.0), 0.0, 0.0)
	add_child(_tube)

	# Grab collision shape (only meaningful on the RigidBody path). Added BEFORE
	# the pickable script so its _ready() can discover a shape to grab by.
	if _tube is RigidBody3D:
		var grab_col := CollisionShape3D.new()
		var grab_shape := BoxShape3D.new()
		grab_shape.size = Vector3(0.18, 0.22, TUBE_LENGTH + 0.1)
		grab_col.shape = grab_shape
		grab_col.position = Vector3(0.0, 0.0, -TUBE_LENGTH * 0.5)
		_tube.add_child(grab_col)

	_attach_pickable(_tube)

	var tube_mat := _make_material(tube_color, 0.0, 0.45, 0.6)
	var accent_mat := _make_material(tube_accent, 0.4, 0.5, 0.3)

	# Barrel: a cylinder whose local -Z is the firing direction (matches the
	# becoming_catalyst aim convention: aim = -basis.z).
	var barrel := MeshInstance3D.new()
	barrel.name = "Barrel"
	var barrel_cyl := CylinderMesh.new()
	barrel_cyl.top_radius = TUBE_RADIUS
	barrel_cyl.bottom_radius = TUBE_RADIUS * 1.15
	barrel_cyl.height = TUBE_LENGTH
	barrel.mesh = barrel_cyl
	barrel.material_override = tube_mat
	# Cylinder's long axis is local +Y; rotate so it lies along local -Z.
	barrel.rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)
	barrel.position = Vector3(0.0, 0.0, -TUBE_LENGTH * 0.5)
	_tube.add_child(barrel)

	# Muzzle ring (accent) at the firing end.
	var ring := MeshInstance3D.new()
	var ring_cyl := CylinderMesh.new()
	ring_cyl.top_radius = TUBE_RADIUS * 1.25
	ring_cyl.bottom_radius = TUBE_RADIUS * 1.25
	ring_cyl.height = 0.04
	ring.mesh = ring_cyl
	ring.material_override = accent_mat
	ring.rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)
	ring.position = Vector3(0.0, 0.0, -TUBE_LENGTH)
	_tube.add_child(ring)

	# Grip handle (so the held object reads as a launcher).
	var grip := MeshInstance3D.new()
	var grip_box := BoxMesh.new()
	grip_box.size = Vector3(0.05, 0.16, 0.05)
	grip.mesh = grip_box
	grip.material_override = _make_material(Color(0.12, 0.12, 0.14), 0.0, 0.7, 0.2)
	grip.position = Vector3(0.0, -0.10, 0.10)
	_tube.add_child(grip)

	# Muzzle marker — p0 origin for the parabola, at the firing end.
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.0, 0.0, -TUBE_LENGTH)
	_tube.add_child(_muzzle)

	# Cosmetic loaded shell peeking from the muzzle (hidden while in flight).
	_loaded_shell = MeshInstance3D.new()
	_loaded_shell.name = "LoadedShell"
	var shell_sphere := SphereMesh.new()
	shell_sphere.radius = TUBE_RADIUS * 0.8
	shell_sphere.height = TUBE_RADIUS * 1.6
	_loaded_shell.mesh = shell_sphere
	_loaded_shell.material_override = _make_material(shell_color, 0.5, 0.5, 0.2)
	_loaded_shell.position = Vector3(0.0, 0.0, -TUBE_LENGTH * 0.85)
	_tube.add_child(_loaded_shell)

	# Charge fill bar riding the top of the barrel (grows as _force charges).
	_force_bar = MeshInstance3D.new()
	_force_bar.name = "ForceBar"
	var bar_box := BoxMesh.new()
	bar_box.size = Vector3(0.02, 0.02, 1.0)
	_force_bar.mesh = bar_box
	_force_bar_mat = _make_material(velocity_arrow_color, 0.6, 0.4, 0.1)
	_force_bar.material_override = _force_bar_mat
	_force_bar.position = Vector3(0.0, TUBE_RADIUS + 0.03, -TUBE_LENGTH * 0.5)
	_tube.add_child(_force_bar)


## Give the tube the XRTools pickable behaviour if the addon is present. We do not
## hard-fail without it: desktop/headless runs simply use the auto-fire fallback.
func _attach_pickable(node: Node3D) -> void:
	var path := "res://addons/godot-xr-tools/objects/pickable.gd"
	if ResourceLoader.exists(path):
		var pickable_script = load(path)
		node.set_script(pickable_script)
		node.set("enabled", true)
		node.set("press_to_hold", true)


# ═════════════════════════════════════════════════════════════════════════
# GROUND DISC + SWARM ARENA
# ═════════════════════════════════════════════════════════════════════════

func _build_ground_disc() -> void:
	var disc := MeshInstance3D.new()
	disc.name = "GroundDisc"
	var plane := CylinderMesh.new()
	plane.top_radius = arena_radius
	plane.bottom_radius = arena_radius
	plane.height = 0.02
	disc.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.11, 0.13, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.9
	disc.material_override = mat
	disc.position = Vector3(0.0, floor_y - 0.01, 0.0)
	add_child(disc)


# ═════════════════════════════════════════════════════════════════════════
# VECTOR INDICATORS + TRAJECTORY + AoE RING
# ═════════════════════════════════════════════════════════════════════════

func _build_vector_indicators() -> void:
	_velocity_arrow = _create_arrow("VelocityArrow", velocity_arrow_color)
	add_child(_velocity_arrow)
	_gravity_arrow = _create_arrow("GravityArrow", gravity_arrow_color)
	add_child(_gravity_arrow)

	_velocity_label = _make_label("v0", velocity_arrow_color, 18)
	add_child(_velocity_label)
	_gravity_label = _make_label("g", gravity_arrow_color, 18)
	add_child(_gravity_label)


func _build_trajectory_preview() -> void:
	_trajectory_mesh = ImmediateMesh.new()
	_trajectory_instance = MeshInstance3D.new()
	_trajectory_instance.name = "TrajectoryPreview"
	_trajectory_instance.mesh = _trajectory_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = trajectory_color
	mat.emission_enabled = true
	mat.emission = trajectory_color
	mat.emission_energy_multiplier = 0.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_trajectory_instance.material_override = mat
	add_child(_trajectory_instance)


## Build an arrow (shaft cylinder + cone head). Mirrors catapult / hl_turret.
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
	mat.emission_energy_multiplier = 0.5
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


## Position an arrow from start to end (both in this node's local space). Mirrors
## catapult._position_arrow: converts dir to global basis so it stays correct when
## the artifact is placed rotated in a map.
func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3) -> void:
	var dir := end - start
	var length := dir.length()
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true

	arrow.transform = Transform3D.IDENTITY
	arrow.position = start

	var shaft: Node3D = arrow.get_node("Shaft")
	var head: Node3D = arrow.get_node("Head")

	var shaft_length: float = length - ARROW_THICKNESS * 5.0
	shaft.scale = Vector3(1, max(shaft_length, 0.01), 1)
	shaft.position = dir.normalized() * (shaft_length / 2.0)
	head.position = dir.normalized() * (length - ARROW_THICKNESS * 2.5)

	var parent := arrow.get_parent() as Node3D
	var world_dir := dir
	if parent:
		world_dir = parent.global_transform.basis * dir
	var up := Vector3.UP
	if world_dir.length() > 0.0001 and abs(world_dir.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	arrow.look_at(arrow.global_position + world_dir, up)
	arrow.rotate_object_local(Vector3.RIGHT, PI / 2.0)


## The AoE ring is a flat circle of small cylinder segments laid on the floor at
## the predicted impact. We build it once, then move/rescale it each frame.
func _build_aoe_ring() -> void:
	_aoe_ring = Node3D.new()
	_aoe_ring.name = "AoEPreview"
	add_child(_aoe_ring)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = aoe_color
	mat.emission_enabled = true
	mat.emission = aoe_color
	mat.emission_energy_multiplier = 0.7
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in range(AOE_SEGMENTS):
		var seg := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.02
		cyl.height = 1.0
		seg.mesh = cyl
		seg.material_override = mat
		_aoe_ring.add_child(seg)
		_aoe_segment_meshes.append(seg)

	# A crosshair dot at the centre of the predicted impact.
	var dot := MeshInstance3D.new()
	dot.name = "ImpactDot"
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.06
	dot_mesh.height = 0.12
	dot.mesh = dot_mesh
	dot.material_override = mat
	_aoe_ring.add_child(dot)


# ═════════════════════════════════════════════════════════════════════════
# CONSOLE (FIRE / RELOAD) + READOUT
# ═════════════════════════════════════════════════════════════════════════

func _build_console() -> void:
	var root := Node3D.new()
	root.name = "Console"
	root.position = Vector3(0.55, 0.85, -0.4)
	add_child(root)

	var panel := MeshInstance3D.new()
	var panel_box := BoxMesh.new()
	panel_box.size = Vector3(0.5, 0.28, 0.04)
	panel.mesh = panel_box
	panel.material_override = _make_material(Color(0.10, 0.11, 0.13), 0.05, 0.6, 0.4)
	panel.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	root.add_child(panel)

	# FIRE button — manual launch for desktop pointer users.
	var fire_button: Node3D = BUTTON_SCENE.instantiate()
	fire_button.position = Vector3(-0.12, -0.02, 0.07)
	fire_button.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	fire_button.set("pressed_color", Color(1.0, 0.35, 0.10))
	fire_button.set("released_color", Color(0.90, 0.85, 0.30))
	root.add_child(fire_button)
	if fire_button.has_signal("pressed"):
		fire_button.connect("pressed", Callable(self, "_on_fire_pressed"))
	else:
		var inner := fire_button.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_fire_button_inner"))
	if fire_button.has_method("update_colors"):
		fire_button.call_deferred("update_colors")

	# RELOAD button — refresh the cosmetic shell immediately.
	var reload_button: Node3D = BUTTON_SCENE.instantiate()
	reload_button.position = Vector3(0.12, -0.02, 0.07)
	reload_button.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	reload_button.set("pressed_color", Color(0.30, 0.65, 1.0))
	reload_button.set("released_color", Color(0.55, 0.80, 1.0))
	root.add_child(reload_button)
	if reload_button.has_signal("pressed"):
		reload_button.connect("pressed", Callable(self, "_on_reload_pressed"))
	else:
		var inner2 := reload_button.get_node_or_null("InteractableAreaButton")
		if inner2 and inner2.has_signal("button_pressed"):
			inner2.connect("button_pressed", Callable(self, "_on_reload_button_inner"))
	if reload_button.has_method("update_colors"):
		reload_button.call_deferred("update_colors")

	var fire_lbl := _make_label("FIRE", Color(1.0, 0.6, 0.3), 18)
	fire_lbl.position = Vector3(-0.12, 0.10, 0.06)
	root.add_child(fire_lbl)
	var reload_lbl := _make_label("RELOAD", Color(0.6, 0.85, 1.0), 18)
	reload_lbl.position = Vector3(0.12, 0.10, 0.06)
	root.add_child(reload_lbl)


func _build_readout() -> void:
	_readout_label = _make_label("", Color(0.7, 1.0, 0.7), 16)
	_readout_label.position = Vector3(0.0, 1.55, 0.0)
	add_child(_readout_label)


# ═════════════════════════════════════════════════════════════════════════
# CONTROLLER POLL — aim, charge, fire (becoming_catalyst convention)
# ═════════════════════════════════════════════════════════════════════════

## Each frame: if the tube is held, read the controller. Trigger held -> charge;
## trigger release -> fire; grip -> reload. If no controller, run the auto-fire
## fallback so a headless capture still shows the full flow.
func _poll_controller() -> void:
	var controller := _resolve_controller()
	if controller == null:
		_run_auto_fallback(get_process_delta_time())
		return

	# Live controller: stop the auto fallback from firing.
	_auto_timer = 0.0

	var trigger_down: bool = controller.is_button_pressed("trigger_click")
	var grip_down: bool = controller.is_button_pressed("grip_click")

	# Trigger pressed edge -> begin charging.
	if trigger_down and not _prev_trigger:
		_begin_charge()
	# Trigger released edge -> fire if we were charging.
	elif not trigger_down and _prev_trigger:
		_release_and_fire()

	# Grip pressed edge -> reload cosmetic shell.
	if grip_down and not _prev_grip:
		_reload_now()

	_prev_trigger = trigger_down
	_prev_grip = grip_down


## Resolve the controller currently holding the tube. Returns null on desktop.
func _resolve_controller() -> XRController3D:
	if _controller and is_instance_valid(_controller):
		return _controller
	if _tube == null:
		return null

	# The XRTools pickable exposes get_picked_up_by(); walk up to the controller.
	if _tube.has_method("get_picked_up_by"):
		var holder = _tube.call("get_picked_up_by")
		if holder:
			var node: Node = holder
			while node:
				if node is XRController3D:
					_controller = node
					return _controller
				node = node.get_parent()

	# Fallback: walk up from the tube itself (pickable may be reparented).
	var p: Node = _tube.get_parent()
	while p:
		if p is XRController3D:
			_controller = p
			return _controller
		p = p.get_parent()

	return null


## Current aim direction in world space: the tube's forward (-Z), per the
## becoming_catalyst held-controller convention.
func _aim_dir_world() -> Vector3:
	if _tube == null:
		return Vector3(0.0, 0.6, -0.8).normalized()
	var d: Vector3 = -_tube.global_transform.basis.z
	if d.length() < 0.0001:
		return Vector3.FORWARD
	return d.normalized()


## Muzzle position in world space (parabola origin p0).
func _muzzle_world() -> Vector3:
	if _muzzle:
		return _muzzle.global_position
	return global_transform.origin + Vector3(0.0, 0.95, 0.0)


# ═════════════════════════════════════════════════════════════════════════
# CHARGE STATE
# ═════════════════════════════════════════════════════════════════════════

func _begin_charge() -> void:
	if not _can_fire:
		return
	_charging = true
	_charge_t = 0.0
	_force = min_force


func _update_charge(delta: float) -> void:
	if not _charging:
		return
	_charge_t += delta
	var frac: float = clamp(_charge_t / max(charge_time, 0.001), 0.0, 1.0)
	_force = lerp(min_force, max_force, frac)


func _release_and_fire() -> void:
	if not _charging:
		return
	_charging = false
	_fire_shell()


# ═════════════════════════════════════════════════════════════════════════
# DESKTOP / HEADLESS FALLBACK
# ═════════════════════════════════════════════════════════════════════════

## With no controller, auto-aim the tube at a roaming drone and auto-fire on a
## timer. Keeps the live parabola + a shell + the swarm visible for capture.
func _run_auto_fallback(delta: float) -> void:
	_auto_aim_tube(delta)

	_auto_timer += delta
	if _auto_timer >= auto_fire_interval and _can_fire:
		_auto_timer = 0.0
		# Snap force to a mid-high charge so the arc clearly clears the ground.
		_force = lerp(min_force, max_force, 0.7)
		_fire_shell()


## Slowly tilt the tube so its predicted impact tracks a chosen target drone.
func _auto_aim_tube(delta: float) -> void:
	if _tube == null:
		return
	var target := _pick_auto_target()
	if target == null:
		# No drones: keep a pleasant default elevation.
		var rest := Vector3(deg_to_rad(-55.0), 0.0, 0.0)
		_tube.rotation = _tube.rotation.lerp(rest, clamp(delta * 1.5, 0.0, 1.0))
		return

	# Solve a launch elevation that lands near the target using a fixed force.
	var muzzle_local := to_local(_muzzle_world())
	var tgt_local := to_local(target.global_position)
	var want := _solve_aim_basis(muzzle_local, tgt_local)
	# Node3D has no bare `basis` setter — write through transform.basis instead.
	var cur := _tube.transform.basis.orthonormalized()
	var blended := cur.slerp(want.orthonormalized(), clamp(delta * 2.0, 0.0, 1.0))
	_tube.transform = Transform3D(blended.orthonormalized(), _tube.transform.origin)


## Build a tube basis whose -Z points along a launch direction that, at the
## fallback force, drops a shell near `tgt_local`. We pick the high-ish arc.
func _solve_aim_basis(muzzle_local: Vector3, tgt_local: Vector3) -> Basis:
	var to_tgt := tgt_local - muzzle_local
	var horiz := Vector3(to_tgt.x, 0.0, to_tgt.z)
	var range_h: float = horiz.length()
	var dir_h := Vector3.FORWARD
	if range_h > 0.0001:
		dir_h = horiz / range_h

	var f: float = lerp(min_force, max_force, 0.7)
	var g: float = max(gravity_magnitude, 0.001)
	# Projectile angle to hit a point at horizontal range R, height dy:
	# choose a default 50deg if the discriminant is negative (out of range).
	var elev: float = deg_to_rad(50.0)
	var dy: float = to_tgt.y
	var v2: float = f * f
	var disc: float = v2 * v2 - g * (g * range_h * range_h + 2.0 * dy * v2)
	if disc >= 0.0 and range_h > 0.0001:
		# High-arc solution (mortar): use the larger angle.
		elev = atan((v2 + sqrt(disc)) / (g * range_h))

	# Compose a launch direction in local space, then a look-at basis whose
	# -Z aligns with it (Godot basis: -Z is forward).
	var launch_dir := (dir_h * cos(elev) + Vector3.UP * sin(elev)).normalized()
	var fwd := -launch_dir
	var up := Vector3.UP
	if abs(fwd.dot(up)) > 0.99:
		up = Vector3.FORWARD
	var right := up.cross(fwd).normalized()
	var new_up := fwd.cross(right).normalized()
	return Basis(right, new_up, fwd)


func _pick_auto_target() -> Node3D:
	for d in _drones:
		if d and is_instance_valid(d):
			return d
	return null


# ═════════════════════════════════════════════════════════════════════════
# FIRE — spawn a RigidBody shell on the previewed arc
# ═════════════════════════════════════════════════════════════════════════

func _fire_shell() -> void:
	if not _can_fire:
		return
	_can_fire = false
	_reload_t = 0.0
	_set_loaded_shell_visible(false)

	_prune_shells()

	var p0_world := _muzzle_world()
	var v0_world := _aim_dir_world() * _force

	var shell := RigidBody3D.new()
	shell.name = "MortarShell"
	shell.gravity_scale = gravity_magnitude / 9.8
	shell.contact_monitor = true
	shell.max_contacts_reported = 4
	shell.collision_layer = 16    # hazard-ish layer, away from world cubes
	shell.collision_mask = 1      # collide with the world/floor (layer 1)
	shell.set_meta("aoe_radius", aoe_radius)
	shell.set_meta("detonated", false)

	# Visual
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = TUBE_RADIUS * 0.7
	sphere.height = TUBE_RADIUS * 1.4
	mesh.mesh = sphere
	mesh.material_override = _make_material(shell_color, 0.7, 0.4, 0.2)
	shell.add_child(mesh)

	# Collision
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = TUBE_RADIUS * 0.7
	col.shape = shape
	shell.add_child(col)

	# Riding velocity arrow (mirrors catapult ball overlay).
	var ride_arrow := _create_arrow("ShellVelocity", velocity_arrow_color)
	shell.add_child(ride_arrow)
	shell.set_meta("vel_arrow", ride_arrow)

	# Parent into the shell container (sibling of the tube) and place at muzzle.
	_shell_container.add_child(shell)
	shell.global_transform = Transform3D(Basis.IDENTITY, p0_world)
	shell.linear_velocity = v0_world

	# Detonate on floor contact OR analytically (whichever comes first).
	shell.body_entered.connect(_on_shell_body_entered.bind(shell))

	fired.emit(v0_world)

	# Orient the riding arrow once.
	_orient_shell_arrow(shell, v0_world)

	# Safety lifetime cull.
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = shell_lifetime
	shell.add_child(timer)
	timer.timeout.connect(func():
		if is_instance_valid(shell) and not bool(shell.get_meta("detonated", false)):
			_detonate(shell.global_position, shell)
	)
	timer.start()


func _orient_shell_arrow(shell: RigidBody3D, v_world: Vector3) -> void:
	if not is_instance_valid(shell):
		return
	if not shell.has_meta("vel_arrow"):
		return
	var arrow: Node3D = shell.get_meta("vel_arrow")
	if arrow == null or not is_instance_valid(arrow):
		return
	var local_dir: Vector3 = shell.global_transform.basis.inverse() * v_world
	var dir: Vector3 = local_dir.normalized() * clampf(v_world.length() * 0.05, 0.15, 0.6)
	_position_arrow(arrow, Vector3.ZERO, dir)


## Per-frame: enforce analytic floor detonation for shells that have fallen to or
## below the floor (so detonation never depends solely on physics contact).
func _check_shell_floors() -> void:
	if _shell_container == null:
		return
	var floor_world_y: float = to_global(Vector3(0.0, floor_y, 0.0)).y
	for shell in _shell_container.get_children():
		if not (shell is RigidBody3D):
			continue
		if bool(shell.get_meta("detonated", false)):
			continue
		if shell.global_position.y <= floor_world_y:
			_detonate(shell.global_position, shell)


func _on_shell_body_entered(_body: Node, shell: RigidBody3D) -> void:
	if not is_instance_valid(shell):
		return
	if bool(shell.get_meta("detonated", false)):
		return
	_detonate(shell.global_position, shell)


## Detonate at `impact` (world space): expanding ring + spark burst, then pop
## every drone whose ground (xz) distance to the impact is within aoe_radius.
func _detonate(impact: Vector3, shell: RigidBody3D) -> void:
	if shell and is_instance_valid(shell):
		if bool(shell.get_meta("detonated", false)):
			return
		shell.set_meta("detonated", true)

	var r: float = aoe_radius
	if shell and is_instance_valid(shell):
		r = float(shell.get_meta("aoe_radius", aoe_radius))

	_spawn_detonation_fx(impact, r)

	# AREA targeting: pop drones inside the splash by horizontal (xz) distance.
	var hits := 0
	for d in _drones:
		if d == null or not is_instance_valid(d):
			continue
		var flat := Vector2(d.global_position.x - impact.x, d.global_position.z - impact.z)
		if flat.length() < r:
			if d.has_method("take_damage"):
				d.take_damage(99)
			hits += 1

	detonated.emit(impact, hits)

	if shell and is_instance_valid(shell):
		shell.queue_free()


## Expanding orange ring + spark sphere burst at the impact (world space). Mirrors
## hl_turret_vectors hit-effect with a tweened ring scale and timed cleanup.
func _spawn_detonation_fx(impact: Vector3, r: float) -> void:
	var fx := Node3D.new()
	fx.name = "Detonation"
	var host: Node = get_tree().current_scene
	if host == null or not is_instance_valid(host):
		host = self  # headless/capture: no current_scene — parent to the artifact
	host.add_child(fx)
	fx.global_position = impact

	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = aoe_color
	ring_mat.emission_enabled = true
	ring_mat.emission = aoe_color
	ring_mat.emission_energy_multiplier = 1.5
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.05
	torus.outer_radius = 0.12
	ring.mesh = torus
	ring.material_override = ring_mat
	ring.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)  # lay flat on the ground
	fx.add_child(ring)

	# Expand the ring out to the AoE radius.
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector3.ONE * (r / 0.12), 0.35)

	# Spark burst.
	for j in range(10):
		var spark := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.04
		sm.height = 0.08
		spark.mesh = sm
		spark.material_override = ring_mat
		spark.position = Vector3(
			randf_range(-0.25, 0.25),
			randf_range(0.0, 0.4),
			randf_range(-0.25, 0.25))
		fx.add_child(spark)

	# Flash light.
	var light := OmniLight3D.new()
	light.light_color = aoe_color
	light.light_energy = 4.0
	light.omni_range = r
	fx.add_child(light)

	var t := get_tree().create_timer(0.5)
	t.timeout.connect(func():
		if is_instance_valid(fx):
			fx.queue_free())


func _set_loaded_shell_visible(v: bool) -> void:
	if _loaded_shell:
		_loaded_shell.visible = v


func _prune_shells() -> void:
	if _shell_container == null:
		return
	var shells := _shell_container.get_children()
	while shells.size() >= max_live_shells and shells.size() > 0:
		var oldest = shells[0]
		shells.remove_at(0)
		if is_instance_valid(oldest):
			oldest.queue_free()


# ═════════════════════════════════════════════════════════════════════════
# RELOAD
# ═════════════════════════════════════════════════════════════════════════

func _update_reload(delta: float) -> void:
	if _can_fire:
		return
	_reload_t += delta
	if _reload_t >= reload_cooldown:
		_reload_now()


func _reload_now() -> void:
	_can_fire = true
	_reload_t = 0.0
	_set_loaded_shell_visible(true)


# ═════════════════════════════════════════════════════════════════════════
# DRONE SWARM
# ═════════════════════════════════════════════════════════════════════════

func _spawn_swarm() -> void:
	for i in range(drone_count):
		_spawn_one_drone()


func _spawn_one_drone() -> void:
	var drone := _MortarDrone.new()
	drone.arena_radius = arena_radius
	drone.body_color = drone_color
	drone.floor_y = floor_y
	_drone_container.add_child(drone)
	# Random roam anchor + start position inside the arena.
	var ang := randf() * TAU
	var rad := randf_range(arena_radius * 0.3, arena_radius * 0.85)
	var anchor := Vector3(cos(ang) * rad, randf_range(1.6, 3.2), sin(ang) * rad)
	drone.position = anchor
	drone.set_roam_anchor(anchor)
	drone.drone_destroyed.connect(_on_drone_destroyed)
	_drones.append(drone)


func _update_swarm(_delta: float) -> void:
	# Drones self-update in their own _process; we only enforce shell floors here
	# and prune dead references.
	_check_shell_floors()
	_update_reload(_delta)
	var alive := []
	for d in _drones:
		if d and is_instance_valid(d):
			alive.append(d)
	_drones = alive


func _on_drone_destroyed(points: int, _drone: Node) -> void:
	_score += points
	_drones_popped += 1
	# Respawn to keep the swarm full after a short delay.
	var t := get_tree().create_timer(1.5)
	t.timeout.connect(func():
		if is_instance_valid(self) and _drones.size() < drone_count:
			_spawn_one_drone())


# ═════════════════════════════════════════════════════════════════════════
# CONSOLE CALLBACKS
# ═════════════════════════════════════════════════════════════════════════

func _on_fire_pressed() -> void:
	# Desktop FIRE: snap to a mid charge and lob immediately.
	if _can_fire:
		_force = lerp(min_force, max_force, 0.6)
		_fire_shell()


func _on_fire_button_inner(_button) -> void:
	_on_fire_pressed()


func _on_reload_pressed() -> void:
	_reload_now()


func _on_reload_button_inner(_button) -> void:
	_reload_now()


# ═════════════════════════════════════════════════════════════════════════
# VISUAL REFRESH (arrows, parabola, AoE ring, force bar, readout)
# ═════════════════════════════════════════════════════════════════════════

func _refresh_visuals() -> void:
	_update_vector_arrows()
	_update_trajectory_and_aoe()
	_update_force_bar()
	_update_readout()


func _update_vector_arrows() -> void:
	var p0 := to_local(_muzzle_world())
	var aim_local := global_transform.basis.inverse() * _aim_dir_world()
	var v0 := aim_local.normalized() * _force

	# Velocity arrow: scaled down so it reads as a direction handle (0.06 m per m/s).
	var vel_end := p0 + v0 * 0.06
	if _velocity_arrow:
		_position_arrow(_velocity_arrow, p0, vel_end)
	if _velocity_label:
		_velocity_label.text = "v0 = %.1f m/s" % _force
		_velocity_label.position = vel_end + Vector3(0.0, 0.12, 0.0)

	# Gravity arrow: constant downward, fixed visual length, near the muzzle.
	var g_start := p0 + Vector3(0.22, 0.0, 0.0)
	var g_end := g_start + Vector3(0.0, -0.45, 0.0)
	if _gravity_arrow:
		_position_arrow(_gravity_arrow, g_start, g_end)
	if _gravity_label:
		_gravity_label.text = "g = %.1f m/s^2" % gravity_magnitude
		_gravity_label.position = g_end + Vector3(0.0, -0.10, 0.0)


## Live parabola p(t)=p0+v0*t+0.5*g*t^2 (local space) AND the analytic floor
## crossing used to place the AoE ring. The preview never depends on physics.
func _update_trajectory_and_aoe() -> void:
	if _trajectory_mesh == null:
		return
	_trajectory_mesh.clear_surfaces()

	var p0 := to_local(_muzzle_world())
	var aim_local := global_transform.basis.inverse() * _aim_dir_world()
	var v0 := aim_local.normalized() * _force
	var g := Vector3(0.0, -gravity_magnitude, 0.0)

	# Dotted parabola, stopping at the floor crossing.
	_trajectory_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var steps := 96
	var dt := 0.04
	var prev := p0
	var have_prev := false
	var impact_local := p0
	var found_impact := false
	for i in range(1, steps + 1):
		var t := i * dt
		var pos := p0 + v0 * t + 0.5 * g * t * t
		var draw_segment := have_prev and (i % 2 == 0)
		if draw_segment:
			_trajectory_mesh.surface_set_color(trajectory_color)
			_trajectory_mesh.surface_add_vertex(prev)
			_trajectory_mesh.surface_set_color(trajectory_color)
			_trajectory_mesh.surface_add_vertex(pos)
		# Detect floor crossing between prev and pos.
		if not found_impact and have_prev and pos.y <= floor_y and prev.y > floor_y:
			var span: float = prev.y - pos.y
			var frac: float = 0.0
			if span > 0.0001:
				frac = (prev.y - floor_y) / span
			impact_local = prev.lerp(pos, clamp(frac, 0.0, 1.0))
			found_impact = true
		prev = pos
		have_prev = true
		if found_impact and t > dt:
			break
	_trajectory_mesh.surface_end()

	# If the parabola never dipped to the floor (shouldn't with downward g), use
	# the closed-form positive root of p0.y + v0.y*t - 0.5*g*t^2 = floor_y.
	if not found_impact:
		impact_local = _analytic_floor_impact(p0, v0)

	_position_aoe_ring(impact_local)


## Closed-form floor impact: solve p0.y + v0.y*t - 0.5*g*t^2 = floor_y for the
## later (positive) root, then evaluate x,z at that t. Local space.
func _analytic_floor_impact(p0: Vector3, v0: Vector3) -> Vector3:
	var g: float = max(gravity_magnitude, 0.001)
	var a: float = -0.5 * g
	var b: float = v0.y
	var c: float = p0.y - floor_y
	var disc: float = b * b - 4.0 * a * c
	if disc < 0.0:
		# No real crossing (firing upward forever in a weird config): project ahead.
		return Vector3(p0.x + v0.x, floor_y, p0.z + v0.z)
	var sq: float = sqrt(disc)
	var t1: float = (-b + sq) / (2.0 * a)
	var t2: float = (-b - sq) / (2.0 * a)
	var t: float = max(t1, t2)
	if t < 0.0:
		t = max(0.0, min(t1, t2))
	return Vector3(p0.x + v0.x * t, floor_y, p0.z + v0.z * t)


## Lay the AoE ring (a circle of segments) flat at `center_local` on the floor.
func _position_aoe_ring(center_local: Vector3) -> void:
	if _aoe_ring == null:
		return
	var c := Vector3(center_local.x, floor_y + 0.02, center_local.z)
	for i in range(AOE_SEGMENTS):
		var seg: MeshInstance3D = _aoe_segment_meshes[i]
		var a1: float = (float(i) / AOE_SEGMENTS) * TAU
		var a2: float = (float(i + 1) / AOE_SEGMENTS) * TAU
		var p1 := c + Vector3(cos(a1), 0.0, sin(a1)) * aoe_radius
		var p2 := c + Vector3(cos(a2), 0.0, sin(a2)) * aoe_radius
		var mid := (p1 + p2) * 0.5
		var dir := p2 - p1
		var seg_len: float = dir.length()
		seg.position = mid
		seg.scale = Vector3(1.0, max(seg_len, 0.01), 1.0)
		# CylinderMesh long axis is local +Y; aim it along the chord.
		if dir.length() > 0.0001:
			seg.look_at(seg.global_position + (global_transform.basis * dir), Vector3.UP)
			seg.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	var dot := _aoe_ring.get_node_or_null("ImpactDot")
	if dot:
		dot.position = c + Vector3(0.0, 0.04, 0.0)


func _update_force_bar() -> void:
	if _force_bar == null:
		return
	var frac: float = inverse_lerp(min_force, max_force, _force)
	frac = clamp(frac, 0.0, 1.0)
	# Grow the bar along the barrel as force charges.
	var length: float = lerp(0.05, TUBE_LENGTH * 0.9, frac)
	_force_bar.scale = Vector3(1.0, 1.0, length)
	_force_bar.position = Vector3(0.0, TUBE_RADIUS + 0.03, -length * 0.5)
	if _force_bar_mat:
		# Shift green -> hot orange as it fills.
		_force_bar_mat.albedo_color = velocity_arrow_color.lerp(aoe_color, frac)
		_force_bar_mat.emission = _force_bar_mat.albedo_color


func _update_readout() -> void:
	if _readout_label == null:
		return
	var aim := _aim_dir_world()
	var elev_deg: float = rad_to_deg(asin(clamp(aim.y, -1.0, 1.0)))
	var state := "READY" if _can_fire else "RELOADING"
	if _charging:
		state = "CHARGING"
	_readout_label.text = "p(t) = p0 + v0*t + 0.5*g*t^2\nv0=%.1f m/s  elev=%d deg  g=%.1f\nAoE r=%.1fm   %s\ndrones popped: %d   score: %d" % [
		_force, int(round(elev_deg)), gravity_magnitude, aoe_radius, state, _drones_popped, _score]


# ═════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═════════════════════════════════════════════════════════════════════════

func _make_material(color: Color, emission_energy: float = 0.0,
		roughness: float = 0.6, metallic: float = 0.2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
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
	label.pixel_size = 0.0012
	label.no_depth_test = false
	return label


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════════

## Accept overrides from the map/grid system. Safe before or after _ready.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("gravity"):
		gravity_magnitude = float(config["gravity"])
	if config.has("gravity_magnitude"):
		gravity_magnitude = float(config["gravity_magnitude"])
	if config.has("min_force"):
		min_force = float(config["min_force"])
	if config.has("max_force"):
		max_force = float(config["max_force"])
	if config.has("aoe_radius"):
		aoe_radius = float(config["aoe_radius"])
	if config.has("charge_time"):
		charge_time = float(config["charge_time"])
	if config.has("reload_cooldown"):
		reload_cooldown = float(config["reload_cooldown"])
	if config.has("drone_count"):
		drone_count = int(config["drone_count"])
	if config.has("arena_radius"):
		arena_radius = float(config["arena_radius"])
	if config.has("auto_fire_interval"):
		auto_fire_interval = float(config["auto_fire_interval"])
	if config.has("shell_color") and config["shell_color"] is Color:
		shell_color = config["shell_color"]
	if config.has("drone_color") and config["drone_color"] is Color:
		drone_color = config["drone_color"]
	if config.has("aoe_color") and config["aoe_color"] is Color:
		aoe_color = config["aoe_color"]

	_force = clamp(_force, min_force, max_force)


# ═════════════════════════════════════════════════════════════════════════
# INNER CLASS — lightweight roaming target drone
# ═════════════════════════════════════════════════════════════════════════
#
# A self-contained flying target that borrows vector_drone's steering shape:
# chase/orbit a roam anchor, sinusoidal strafe, take_damage + drone_destroyed.
# Kept inner (no external scene deps) so the artifact is a single procedural file.
# Kamikaze is intentionally absent — this is about AREA targeting, not melee.

class _MortarDrone extends Node3D:
	signal drone_destroyed(points: int, drone: Node)

	var arena_radius: float = 9.0
	var floor_y: float = 0.0
	var body_color: Color = Color(0.55, 0.75, 1.0)
	var points_value: int = 25
	var move_speed: float = 2.0
	var strafe_amplitude: float = 0.8
	var strafe_frequency: float = 0.7

	var _roam_anchor: Vector3 = Vector3.ZERO
	var _retarget_t: float = 0.0
	var _phase: float = 0.0
	var _destroyed: bool = false
	var _mesh: MeshInstance3D = null
	var _mat: StandardMaterial3D = null
	var _spin: float = 0.0

	func _ready() -> void:
		_phase = randf() * TAU
		_build_visual()

	func _build_visual() -> void:
		_mesh = MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.4, 0.3, 0.4)
		_mesh.mesh = prism
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = body_color
		_mat.emission_enabled = true
		_mat.emission = body_color
		_mat.emission_energy_multiplier = 0.6
		_mat.metallic = 0.4
		_mat.roughness = 0.4
		_mesh.material_override = _mat
		add_child(_mesh)

		# A faint rotor ring so the swarm reads as drones.
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.22
		torus.outer_radius = 0.26
		ring.mesh = torus
		ring.material_override = _mat
		ring.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
		add_child(ring)

	func set_roam_anchor(anchor: Vector3) -> void:
		_roam_anchor = anchor

	func _process(delta: float) -> void:
		if _destroyed:
			return
		_spin += delta
		if _mesh:
			_mesh.rotation.y = _spin * 2.0

		# Periodically re-pick a roam anchor inside the arena (wandering swarm).
		_retarget_t -= delta
		if _retarget_t <= 0.0:
			_retarget_t = randf_range(2.0, 4.0)
			var ang := randf() * TAU
			var rad := randf_range(arena_radius * 0.3, arena_radius * 0.85)
			_roam_anchor = Vector3(cos(ang) * rad, randf_range(1.6, 3.2), sin(ang) * rad)

		# Steer toward the anchor (chase) with a sinusoidal strafe (orbit feel).
		var to_anchor := _roam_anchor - position
		var step := Vector3.ZERO
		if to_anchor.length() > 0.05:
			step = to_anchor.normalized() * move_speed * delta
		var t := float(Time.get_ticks_msec()) / 1000.0
		var strafe := Vector3(
			sin(t * strafe_frequency + _phase) * strafe_amplitude,
			cos(t * strafe_frequency * 0.6 + _phase) * strafe_amplitude * 0.4,
			cos(t * strafe_frequency * 0.8 + _phase) * strafe_amplitude) * delta
		position += step + strafe
		# Keep it airborne above the floor.
		if position.y < floor_y + 1.2:
			position.y = floor_y + 1.2

	func take_damage(_amount: int) -> void:
		if _destroyed:
			return
		_destroyed = true
		emit_signal("drone_destroyed", points_value, self)
		# Pop: flash white, expand, fade, free.
		if _mat:
			_mat.albedo_color = Color(1.0, 1.0, 1.0)
			_mat.emission = Color(1.0, 1.0, 1.0)
			_mat.emission_energy_multiplier = 3.0
		# Sequential pop: snap bigger, then shrink to nothing, then free.
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3.ONE * 1.8, 0.12)
		tw.tween_property(self, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_callback(queue_free)
