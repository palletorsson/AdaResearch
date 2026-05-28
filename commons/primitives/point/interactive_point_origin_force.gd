@tool
extends "res://commons/primitives/point/interactive_point_origin.gd"
class_name InteractivePointOriginForce

# @identity
# essence: pickable_point + held → vertex-shader morph into force field that drags nearby RigidBodies inward; held + two_hands_close → fires luminous projectile balls
# desire: the body learns the relation point↔force↔gesture — same single artifact passing through three states as the player engages
# critical_parameter: morph_t (0 = point, 1 = force-field shell); attraction_radius + attraction_strength (inverse-square pull); OrbGestureDetector two-handed trigger (balls only fire from a sustained two-hand pose)
# triggers: picked_up → _morph_target=1; dropped → _morph_target=0; orb_formed(two_handed=true) → spawn ball; _physics_process while held + morph_t>0.5 → attract nearby RigidBody3D
# emerges: capability-as-gesture — the artifact's force-field powers exist only WHILE you hold it AND keep both hands engaged. Drop it or part your hands and the field collapses back to a point.
# needs: parent class interactive_point_origin (XRToolsPickable + line-to-origin + position label); OrbGestureDetector node in tree (group "orb_gesture_detector") for two-hand gesture signals; force_catalyst.gdshader for the morph
# relationships: extends interactive_point_origin; listens to OrbGestureDetector; spawns its own RigidBody3D ball projectiles
# truth: a point is the seed of a force, a force is the seed of a gesture — same artifact, three nested capabilities, each emerging only when its embodied condition is met.

## Force-catalyst variant of interactive_point_origin.
##
## On pickup the spherical visual morphs (vertex displacement, color
## shift, brighter emission) into a "force-field" shell. While held
## with morph engaged, nearby RigidBody3D objects feel an inverse-
## square pull toward the artifact's position. When the player brings
## both hands close (the OrbGestureDetector two-hand gesture), the
## artifact spits a luminous projectile ball in the gesture's forward
## direction. Drop it → morph reverses, attraction stops, projectiles
## stop firing.

const FORCE_SHADER: Shader = preload("res://commons/primitives/point/force_catalyst.gdshader")

# ── Catalyst-mode palettes ──────────────────────────────────────────────
# Three-stop colour ramps borrowed from CatalystOrb.gd so the artifact's
# field shell + projectile balls + line-to-origin all line up visually
# with the rest of the catalyst system. Palette = [deepest, mid, lightest].
# Add new mode entries here; #mode:<name> in map_data tokens picks one.
const MODE_PALETTES := {
	"forces":    [Color(0.95, 0.65, 0.20), Color(0.95, 0.85, 0.30), Color(1.00, 1.00, 0.75)],
	"branching": [Color(0.30, 0.55, 0.30), Color(0.45, 0.85, 0.50), Color(0.85, 0.95, 0.70)],
	"swarm":     [Color(0.85, 0.45, 0.05), Color(1.00, 0.75, 0.20), Color(1.00, 0.95, 0.65)],
	"primitives":[Color(0.20, 0.50, 0.95), Color(0.45, 0.80, 1.00), Color(0.85, 0.95, 1.00)],
}

# Which catalyst-mode palette to apply. Empty = leave the @export-set
# colours alone. Driven from map_data tokens (#mode:forces) or set in
# the editor on a per-instance basis.
@export var mode: String = ""

# ── Morph state ──────────────────────────────────────────────────────────
@export var morph_speed: float = 1.4              # seconds 0 → 1
@export var morph_engage_threshold: float = 0.5   # attraction + projectile fire above this
var _morph_t: float = 0.0
var _morph_target: float = 0.0
var _force_shader_mat: ShaderMaterial = null

# ── Force-field attraction ──────────────────────────────────────────────
@export var attraction_radius: float = 1.5
@export var attraction_strength: float = 8.0      # force = k / max(d^2, 0.04)
@export var attraction_max_force: float = 40.0
@export var attractor_collision_mask: int = 0xFFFFFFFF

# ── Projectile fire — shared params ────────────────────────────────────
@export var ball_speed: float = 6.0
@export var ball_radius: float = 0.04
@export var ball_lifetime: float = 2.0
@export var ball_color: Color = Color(1.0, 0.62, 0.18)
@export var ball_emission_energy: float = 2.5
## Minimum time between projectile spawns from the orb_formed signal.
@export var ball_cooldown: float = 0.20
var _ball_cooldown_t: float = 0.0

# ── Fire-mode triggers (composable — leave them all on by default) ─────
## When TRUE, projectiles fire continuously while both hands hold the
## artifact (XRToolsPickable's SECOND mode). Releases the moment one
## hand lets go. This is the default trigger the user can test in VR.
@export var fire_on_double_grab: bool = true
## Balls / second while double-grabbed.
@export var double_grab_fire_rate: float = 4.0
## When TRUE, the OrbGestureDetector two-hand close gesture also fires
## a single ball per orb_formed. Leave on if you want both triggers
## composing; turn off to isolate the double-grab test.
@export var fire_on_orb_formed: bool = false

# Tracked between grab + released callbacks. Goes TRUE the frame a
# second hand joins, FALSE the frame either hand lets go.
var _double_grabbed: bool = false
var _double_grab_fire_t: float = 0.0

# ── XR rig + gesture-detector refs ──────────────────────────────────────
var _orb_detector: Node = null
var _orb_signal_connected: bool = false


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	_install_force_shader()
	# Apply the named-mode palette AFTER the shader is installed so the
	# force_color uniform is in scope, but BEFORE the orb detector
	# hooks fire so projectile balls also pick up the mode colour.
	if mode != "":
		_apply_mode(mode)
	_connect_orb_detector()
	# XRToolsPickable signals — grabbed/released fire for first AND
	# second hand. We re-check _grab_driver.secondary after each to
	# decide whether the artifact is double-grabbed RIGHT NOW.
	if has_signal("grabbed") and not grabbed.is_connected(_on_grabbed_any):
		grabbed.connect(_on_grabbed_any)
	if has_signal("released") and not released.is_connected(_on_released_any):
		released.connect(_on_released_any)


# Replace the base class's _glow_material with our shader material so the
# vertex morph runs on the SAME MeshInstance3D the base class set up.
func _install_force_shader() -> void:
	var mi: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mi == null:
		return
	_force_shader_mat = ShaderMaterial.new()
	_force_shader_mat.shader = FORCE_SHADER
	_force_shader_mat.set_shader_parameter("morph_t", 0.0)
	# Push the base look (white) and the force-field look (warm orange)
	# into the shader. Tweakable per-instance via export if needed.
	_force_shader_mat.set_shader_parameter("base_color", Color(0.95, 0.95, 0.92, 1.0))
	_force_shader_mat.set_shader_parameter("force_color", Color(1.0, 0.55, 0.10, 1.0))
	mi.material_override = _force_shader_mat


# Try to grab the OrbGestureDetector at startup. If it isn't in the
# scene yet (the rig finishes building a frame or two later in some
# maps), keep polling lazily inside _process.
func _connect_orb_detector() -> void:
	_orb_detector = get_tree().get_first_node_in_group("orb_gesture_detector")
	if _orb_detector and _orb_detector.has_signal("orb_formed") and not _orb_signal_connected:
		_orb_detector.orb_formed.connect(_on_orb_formed)
		_orb_signal_connected = true


# Pickup / drop are inherited from interactive_point_origin.gd, which
# sets _is_held. We use _process to drive the morph independently so
# the morph keeps animating even when the base class isn't drawing
# its line-to-origin (e.g. tool mode).
func _process(delta: float) -> void:
	super._process(delta)
	if Engine.is_editor_hint():
		return

	# Lazy-bind detector if it wasn't ready at _ready.
	if not _orb_signal_connected:
		_connect_orb_detector()

	# Target morph follows _is_held — the base class flips this on
	# picked_up / dropped.
	_morph_target = 1.0 if _is_held else 0.0
	if _morph_t != _morph_target:
		_morph_t = move_toward(_morph_t, _morph_target, morph_speed * delta)
		if _force_shader_mat:
			_force_shader_mat.set_shader_parameter("morph_t", _morph_t)

	# Tick the per-fire cooldown so two-hand bursts can be spaced.
	if _ball_cooldown_t > 0.0:
		_ball_cooldown_t = max(0.0, _ball_cooldown_t - delta)

	# Double-grab continuous fire. Gated on engaged morph so balls only
	# flow after the field has actually formed (avoids spawning balls
	# at pickup-instant before morph_t has climbed).
	if fire_on_double_grab and _double_grabbed and _is_held and _morph_t >= morph_engage_threshold:
		_double_grab_fire_t -= delta
		if _double_grab_fire_t <= 0.0:
			_double_grab_fire_t = 1.0 / max(double_grab_fire_rate, 0.1)
			var dir: Vector3 = _double_grab_fire_direction()
			_spawn_projectile_ball(global_position, dir)
	else:
		# Decay timer so the next double-grab fires immediately rather
		# than waiting out a half-tick from the previous session.
		_double_grab_fire_t = 0.0


# Apply the force-field pull every physics tick.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _is_held or _morph_t < morph_engage_threshold:
		return
	_attract_nearby_bodies()


func _attract_nearby_bodies() -> void:
	var world := get_world_3d()
	if world == null:
		return
	var space := world.direct_space_state
	if space == null:
		return
	var pos: Vector3 = global_position
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = attraction_radius
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, pos)
	query.collision_mask = attractor_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	# Exclude ourselves so we don't yank our own RigidBody.
	query.exclude = [self.get_rid()] if self.has_method("get_rid") else []
	var hits: Array = space.intersect_shape(query, 24)
	for h in hits:
		var collider = h.get("collider")
		if collider is RigidBody3D and collider != self:
			var to_us: Vector3 = pos - collider.global_position
			var dist: float = to_us.length()
			if dist < 0.01:
				continue
			# Inverse-square pull, clamped so very close objects don't
			# explode out of bounds.
			var mag: float = clamp(
				attraction_strength / max(dist * dist, 0.04),
				0.0, attraction_max_force)
			collider.apply_central_force(to_us.normalized() * mag)


# OrbGestureDetector fires this when the player closes both palms with
# the catalyst engaged. While THIS artifact is held with morph engaged,
# we treat it as our "fire" trigger and spawn a projectile.
func _on_orb_formed(_mode: String, origin: Vector3, direction: Vector3, two_handed: bool) -> void:
	if Engine.is_editor_hint():
		return
	if not fire_on_orb_formed:
		return
	if not _is_held or _morph_t < morph_engage_threshold:
		return
	if not two_handed:
		return
	if _ball_cooldown_t > 0.0:
		return
	_ball_cooldown_t = ball_cooldown
	_spawn_projectile_ball(origin, direction)


# XRToolsPickable fires `grabbed(self, by)` for first AND second hand.
# After the signal, _grab_driver.secondary is non-null iff this is
# the second hand. Track it so _process knows whether to fire.
func _on_grabbed_any(_pickable, _by) -> void:
	_double_grabbed = _is_currently_double_grabbed()
	if _double_grabbed:
		_double_grab_fire_t = 0.0  # fire immediately on engage


# `released(self, by)` fires for either hand letting go. If after this
# the secondary slot is null OR the whole grab driver is gone, we're
# no longer double-grabbed.
func _on_released_any(_pickable, _by) -> void:
	_double_grabbed = _is_currently_double_grabbed()


func _is_currently_double_grabbed() -> bool:
	# _grab_driver is the XRToolsGrabDriver instance from the addon.
	# Its .secondary field holds the second Grab when both hands are
	# engaged; otherwise it's null.
	if _grab_driver == null:
		return false
	if not is_instance_valid(_grab_driver):
		return false
	var sec = _grab_driver.get("secondary")
	return sec != null


# Forward direction for double-grab fire. The artifact's own basis
# follows the primary grab point's orientation, so -Z gives "where
# the hand is pointing" without needing to walk the rig manually.
func _double_grab_fire_direction() -> Vector3:
	var fwd: Vector3 = -global_transform.basis.z
	if fwd.length_squared() < 0.001:
		fwd = Vector3.FORWARD
	return fwd.normalized()


func _spawn_projectile_ball(origin: Vector3, direction: Vector3) -> void:
	var ball := RigidBody3D.new()
	ball.name = "ForceBall"
	ball.gravity_scale = 0.3
	ball.continuous_cd = true
	ball.contact_monitor = false
	ball.linear_damp = 0.05

	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = ball_radius
	sm.height = ball_radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = ball_color
	mat.emission_enabled = true
	mat.emission = ball_color
	mat.emission_energy_multiplier = ball_emission_energy
	mat.metallic = 0.1
	mat.roughness = 0.25
	mi.material_override = mat
	ball.add_child(mi)

	var cs := CollisionShape3D.new()
	var ss := SphereShape3D.new()
	ss.radius = ball_radius
	cs.shape = ss
	ball.add_child(cs)

	# Spawn slightly forward of the artifact along the gesture direction
	# so the ball doesn't clip into the held mesh on first frame.
	var dir: Vector3 = direction.normalized() if direction.length_squared() > 0.0 else Vector3.FORWARD
	var spawn_pos: Vector3 = global_position + dir * (ball_radius * 2.5)
	# Fall back to the gesture origin if it's a reasonable place — gives
	# the player the sense the ball comes from between the hands.
	if origin.distance_to(global_position) < 0.6:
		spawn_pos = origin + dir * (ball_radius * 2.5)

	get_tree().current_scene.add_child(ball)
	ball.global_position = spawn_pos
	ball.linear_velocity = dir * ball_speed

	# Auto-cleanup so the world doesn't fill up with stale balls.
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = ball_lifetime
	t.timeout.connect(func(): if is_instance_valid(ball): ball.queue_free())
	ball.add_child(t)
	t.start()


# Allow per-instance tweaks from the lab editor / map_data tokens.
# Example token in interactables layer:
#   interactive_point_origin_force:0:1#mode:forces
#   interactive_point_origin_force:0:1#mode:branching#ball_speed:8.0
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("attraction_radius"):
		attraction_radius = float(config_data["attraction_radius"])
	if config_data.has("attraction_strength"):
		attraction_strength = float(config_data["attraction_strength"])
	if config_data.has("ball_speed"):
		ball_speed = float(config_data["ball_speed"])
	if config_data.has("ball_lifetime"):
		ball_lifetime = float(config_data["ball_lifetime"])
	if config_data.has("morph_speed"):
		morph_speed = float(config_data["morph_speed"])
	if config_data.has("mode"):
		mode = str(config_data["mode"])
		# Re-apply if we're already inside _ready / past the initial
		# call. _apply_mode is safe to call multiple times.
		_apply_mode(mode)


# Apply a named catalyst-mode palette to every colour-bearing channel
# the artifact owns: the force-field shader's deepest tone, the ball
# projectiles' mid tone, the omni-light glow's lightest tone, and the
# line-to-origin line for held mode. Unknown mode names log a warning
# and leave the existing colours alone.
func _apply_mode(mode_id: String) -> void:
	if mode_id == "":
		return
	if not MODE_PALETTES.has(mode_id):
		push_warning("interactive_point_origin_force: unknown mode '%s' (known: %s)"
			% [mode_id, str(MODE_PALETTES.keys())])
		return
	var palette: Array = MODE_PALETTES[mode_id]
	var deepest: Color = palette[0]
	var mid: Color = palette[1]
	var lightest: Color = palette[2]
	# Shader force-colour uniform — the morphed-field shell tone.
	if _force_shader_mat:
		_force_shader_mat.set_shader_parameter("force_color", deepest)
	# Projectile ball colour + emission tint.
	ball_color = mid
	# Held-line colour (inherited from interactive_point_origin). Set on
	# the actual material if it's already built.
	line_color = mid
	if _line_material:
		_line_material.albedo_color = mid
		_line_material.emission = mid
	# OmniLight glow (light_color on the inherited light, if present).
	var omni: OmniLight3D = get_node_or_null("MeshInstance3D/OmniLight3D")
	if omni:
		omni.light_color = lightest
