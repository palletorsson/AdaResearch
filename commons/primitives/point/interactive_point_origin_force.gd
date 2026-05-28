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

# ── Catalyst-mode projectile dispatch ──────────────────────────────────
# One CatalystProjectile subclass per canonical mode. Each defines its
# own firing behaviour ('verb') — chaos arcs, swarm flocks, chromatic
# paints, forces gathers. Map_data tokens use #mode:<name>, and when
# the artifact fires during double-grab it instantiates the matching
# projectile class instead of a plain emissive ball.
#
# Custom colours (hex / RGB / CSS name) still work — they fall through
# to the generic glowing-ball fallback in _spawn_projectile_ball.
const MODE_PROJECTILES := {
	"primitives":     preload("res://commons/hazards/becoming_catalyst/modes/primitives_projectile.gd"),
	"transformation": preload("res://commons/hazards/becoming_catalyst/modes/transformation_projectile.gd"),
	"chromatic":      preload("res://commons/hazards/becoming_catalyst/modes/chromatic_projectile.gd"),
	"forces":         preload("res://commons/hazards/becoming_catalyst/modes/forces_projectile.gd"),
	"waveform":       preload("res://commons/hazards/becoming_catalyst/modes/waveform_projectile.gd"),
	"chaos":          preload("res://commons/hazards/becoming_catalyst/modes/chaos_projectile.gd"),
	"fractal":        preload("res://commons/hazards/becoming_catalyst/modes/fractal_projectile.gd"),
	"cellular":       preload("res://commons/hazards/becoming_catalyst/modes/cellular_projectile.gd"),
	"branching":      preload("res://commons/hazards/becoming_catalyst/modes/branching_projectile.gd"),
	"swarm":          preload("res://commons/hazards/becoming_catalyst/modes/swarm_projectile.gd"),
}

# ── Catalyst-mode palettes ──────────────────────────────────────────────
# The ten canonical catalyst modes mirrored from
# commons/testing/vr_capture_rig.gd::MODE_PALETTES — the same palette
# the orb shader, the bracelet active-gem, and the cone visual aids
# already use. Keeping the source-of-truth single means a `#mode:chaos`
# token here lights the artifact the same colour the orb shows in the
# bracelet capture gallery. Palette tuples are [base, deeper, highlight].
const MODE_PALETTES := {
	"primitives":     [Color(0.20, 0.95, 0.55), Color(0.45, 1.00, 0.40), Color(0.85, 1.00, 0.65)],
	"transformation": [Color(0.25, 0.55, 1.00), Color(0.40, 0.78, 1.00), Color(0.75, 0.92, 1.00)],
	"chromatic":      [Color(0.95, 0.35, 0.78), Color(1.00, 0.55, 0.85), Color(1.00, 0.85, 0.92)],
	"forces":         [Color(0.95, 0.65, 0.20), Color(0.95, 0.85, 0.30), Color(1.00, 1.00, 0.75)],
	"waveform":       [Color(0.45, 0.30, 0.95), Color(0.65, 0.55, 1.00), Color(0.88, 0.82, 1.00)],
	"chaos":          [Color(0.95, 0.20, 0.20), Color(1.00, 0.50, 0.30), Color(1.00, 0.82, 0.55)],
	"fractal":        [Color(0.35, 0.95, 0.65), Color(0.55, 1.00, 0.85), Color(0.85, 1.00, 0.95)],
	"cellular":       [Color(0.70, 0.70, 0.75), Color(0.92, 0.92, 0.95), Color(1.00, 1.00, 1.00)],
	"branching":      [Color(0.30, 0.55, 0.30), Color(0.45, 0.85, 0.50), Color(0.85, 0.95, 0.70)],
	"swarm":          [Color(0.85, 0.45, 0.05), Color(1.00, 0.75, 0.20), Color(1.00, 0.95, 0.65)],
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


# Forward direction for double-grab fire.
#
# Prefer the actual primary-hand controller's forward (-Z of the
# XRController3D). The artifact's own basis follows the grab point's
# transform — which is *close* but not always identical to the
# controller's natural forward, because grab points are typically
# offset/rotated to land the artifact comfortably in the palm.
# Asking the controller directly means "where the hand is pointing"
# is genuinely where the projectile flies.
#
# Falls back to the artifact's local -Z if the controller can't be
# resolved (e.g. the grab driver hasn't fully wired up yet, or a
# non-XR caller is firing for testing).
func _double_grab_fire_direction() -> Vector3:
	if _grab_driver != null and is_instance_valid(_grab_driver):
		var primary = _grab_driver.get("primary")
		if primary != null and "controller" in primary:
			var ctrl = primary.controller
			if ctrl != null and ctrl is Node3D and is_instance_valid(ctrl):
				var hand_fwd: Vector3 = -ctrl.global_transform.basis.z
				if hand_fwd.length_squared() > 0.001:
					return hand_fwd.normalized()
	var fwd: Vector3 = -global_transform.basis.z
	if fwd.length_squared() < 0.001:
		fwd = Vector3.FORWARD
	return fwd.normalized()


func _spawn_projectile_ball(origin: Vector3, direction: Vector3) -> void:
	# Mode dispatch — if the current mode names a canonical catalyst
	# verb (chaos arcs, swarm flocks, chromatic paints, etc.) we
	# instantiate that mode's CatalystProjectile subclass instead of
	# the generic glowing ball. The projectile is responsible for its
	# own visual, behaviour, and hit-handling per the catalyst system.
	if mode != "" and MODE_PROJECTILES.has(mode):
		_spawn_catalyst_projectile(origin, direction, MODE_PROJECTILES[mode])
		return

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


# Spawn a CatalystProjectile subclass of the mode's choosing. The
# projectile's _ready() handles physics setup, visual, particles. We
# just need to configure direction + colour + speed before it enters
# the tree. The projectile uses its own gravity/trajectory rules
# (forces gathers with a parabolic arc, chaos sparks unpredictably,
# etc.) — those override the generic ball settings here.
func _spawn_catalyst_projectile(origin: Vector3, direction: Vector3, projectile_script: GDScript) -> void:
	var proj: Node = projectile_script.new()
	if proj == null:
		return
	# Configure shared fields exposed by CatalystProjectile.
	var dir: Vector3 = direction.normalized() if direction.length_squared() > 0.0 else Vector3.FORWARD
	if "direction" in proj:
		proj.direction = dir
	if "speed" in proj:
		proj.speed = ball_speed
	if "lifetime" in proj:
		proj.lifetime = ball_lifetime
	if "projectile_scale" in proj:
		proj.projectile_scale = max(0.5, ball_radius / 0.04)  # 0.04 is the default base
	if "color_primary" in proj:
		proj.color_primary = ball_color
	if "color_secondary" in proj:
		# Slightly darker secondary for two-tone projectiles.
		proj.color_secondary = Color(ball_color.r * 0.6, ball_color.g * 0.6, ball_color.b * 0.6, ball_color.a)
	if "emission_energy" in proj:
		proj.emission_energy = ball_emission_energy
	get_tree().current_scene.add_child(proj)
	# Position slightly forward along the gesture direction so the
	# projectile doesn't clip into the held mesh on its first frame.
	if proj is Node3D:
		var spawn_pos: Vector3 = global_position + dir * (ball_radius * 2.5)
		if origin.distance_to(global_position) < 0.6:
			spawn_pos = origin + dir * (ball_radius * 2.5)
		proj.global_position = spawn_pos


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


# Apply a catalyst-mode palette to every colour-bearing channel the
# artifact owns: the force-field shader's deepest tone, the ball
# projectiles' mid tone, the omni-light glow's lightest tone, and the
# line-to-origin material's albedo/emission while held.
#
# `mode_id` accepts three forms:
#   1. A named entry in MODE_PALETTES — e.g. "chaos", "branching".
#      Uses the canonical 3-stop palette.
#   2. A hex string — "#ff8800" or "ff8800". Generates a synthetic
#      [deeper, base, highlight] palette around the parsed colour.
#   3. A comma-separated RGB triple — "1,0,0" or "0.5,0.2,0.9".
#      Same synthetic ramp.
# Unparseable strings push a warning and leave the existing colours alone.
func _apply_mode(mode_id: String) -> void:
	if mode_id == "":
		return
	var palette: Array
	if MODE_PALETTES.has(mode_id):
		palette = MODE_PALETTES[mode_id]
	else:
		var custom_color: Variant = _parse_color_value(mode_id)
		if custom_color == null:
			push_warning("interactive_point_origin_force: unknown mode '%s' — pass a palette name (%s), a hex like #ff8800, or an RGB triple like 1,0.5,0" % [mode_id, str(MODE_PALETTES.keys())])
			return
		palette = _palette_from_color(custom_color)
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


# Try to parse `s` as a Color from one of three forms: a hex string
# (with or without leading #), a comma-separated RGB[A] triple of
# floats, or a Godot named colour like "red". Returns null on failure.
func _parse_color_value(s: String) -> Variant:
	var trimmed: String = s.strip_edges()
	if trimmed.is_empty():
		return null
	# Hex form.
	if trimmed.begins_with("#") or trimmed.length() in [6, 8] and trimmed.is_valid_hex_number(false):
		var hex: String = trimmed if trimmed.begins_with("#") else "#" + trimmed
		if Color.html_is_valid(hex):
			return Color.html(hex)
	# RGB[A] triple form.
	if trimmed.contains(","):
		var parts: PackedStringArray = trimmed.split(",", false)
		if parts.size() >= 3:
			var floats: Array[float] = []
			for p in parts:
				var v: String = p.strip_edges()
				if not v.is_valid_float():
					return null
				floats.append(clamp(float(v), 0.0, 1.0))
			if floats.size() >= 4:
				return Color(floats[0], floats[1], floats[2], floats[3])
			return Color(floats[0], floats[1], floats[2])
	# Named-colour fallback. Godot lacks a runtime named-colour table,
	# so we rely on Color.html which accepts named CSS colours.
	if Color.html_is_valid(trimmed):
		return Color.html(trimmed)
	return null


# Derive a 3-stop [base, mid, highlight] palette from a single user-
# supplied colour. The base is a darker / more saturated variant for
# the field shell, mid is the input colour itself for projectile balls
# and the line-to-origin, highlight is a brighter / desaturated tone
# for the OmniLight glow.
func _palette_from_color(c: Color) -> Array:
	var deeper := Color(c.r * 0.7, c.g * 0.7, c.b * 0.7, c.a)
	var brighter := Color(
		clamp(c.r * 0.4 + 0.6, 0.0, 1.0),
		clamp(c.g * 0.4 + 0.6, 0.0, 1.0),
		clamp(c.b * 0.4 + 0.6, 0.0, 1.0),
		c.a)
	return [deeper, c, brighter]
