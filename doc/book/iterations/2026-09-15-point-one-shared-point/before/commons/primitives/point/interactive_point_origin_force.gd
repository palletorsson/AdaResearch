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
const PBR := preload("res://commons/render/pbr_kit.gd")

# ── GRAIN SCALE, WHICH IS THE WHOLE GAME ────────────────────────────────
#
# The bead is a SPHERE OF RADIUS 0.03 — 60 mm across, the smallest subject
# anything in this render pass has been asked to finish. point_mesh.gd writes
# it into the host MeshInstance3D before this script's _ready runs, and the
# whole artifact at retention=none is that ball and nothing else.
#
# It is also photographed small. Measured off the published sweep frame, the
# subject's bounding box is 60 x 61 px in a 760 px capture, which is
#
#     1000 pixels per metre
#
# — because the harness fits ONE camera distance to all five values of the
# axis, and `archive` is 512 px wide. (That is a framing fact, not a materials
# fact; it is written up at the bottom of this block.)
#
# PbrKit's blob arithmetic, the same one exit_sign.gd uses:
#
#     blob_px  =  (px_per_m / tiles_per_m) / 24
#
# because GRAIN_MICRO's dominant octave is about 1/24 of a tile. Solving for a
# feature about SIX pixels wide — exit_sign measured 10-16 px as reading like
# dirt on a small part, and under ~3 px as television static:
#
#     tiles_per_m = 1000 / (6 * 24) = 6.9  ->  7.0
#
# One tile is then 0.143 m of surface arc, holding ~24 blobs, so a blob is
# about 6 mm of surface and roughly TEN of them span the visible face of the
# bead. A surface, not static.
#
# WHAT THE RULE OF THUMB WOULD HAVE DONE HERE, since this is the lesson that
# cost the most: PbrKit.scale_detail's docstring suggests factor ~= 1 /
# longest_dimension, which on a 0.06 m object is 16.7, applied on top of a kit
# default near 5 — about 83 tiles per metre, a blob of HALF A PIXEL. The rule
# of thumb is calibrated for parts in the 0.1-1 m band and inverts below it.
# On a bead it does not produce detail, it produces noise finer than the pixel
# grid, which is precisely the failure three rounds of critics blamed on six
# different post-process settings.
#
# The sphere's UV needs one more correction the triplanar path does not: u
# spans 2*pi*r of arc and v spans pi*r, so equal tiling in UV gives blobs twice
# as wide as they are tall. _apply_bead_finish multiplies each axis by its own
# arc length, which is why grain_uv is a vec2 and not a float.
#
# NOTHING ELSE ON THIS ARTIFACT NEEDS SCALING. The wax plate is 0.31 m across
# and PbrKit's own defaults land its blob at 6.7 px (hard_plastic, 5 tiles/m)
# and the clearing sheet's at 5.6 px (glass, 6 tiles/m) — the kit is tuned for
# objects that size, and reaching for scale_detail there would have been
# fiddling with a number that was already right.
#
# THE FRAMING FACT, LEFT ALONE ON PURPOSE. `none` occupies 0.50% of its frame,
# well under the linter's 6% "below measurable" floor, and the obvious fix is
# the registry's dna.framing key — the sibling interactive_point_origin carries
# framing 0.3 for exactly this. It does not work here. _framing in
# capture_config_sweep.gd scales ONE camera distance shared by every value of
# the axis, and this axis's values are not the same size: measured, `archive`
# already spans 512 px and `wax` 249 px of a 760 px frame, so any framing below
# about 1.0 crops archive out of its own picture. Two of five values would be
# destroyed to enlarge a third. The materials work below therefore has to
# survive at 60 px — which it does, because what fixes a flat sphere is the
# whole-object gradient a light draws across it, not the grain. The grain only
# has to avoid becoming static, which is what the number above is for.
const GRAIN_TILES_PER_M: float = 7.0

# ── Catalyst-mode factories ────────────────────────────────────────────
# Use the canonical mode_<name>.gd scripts (NOT the <name>_projectile.gd
# scripts directly). Each mode factory exposes a static
#   create_projectile(spawn_pos, fire_dir) -> CatalystProjectile
# that wraps a CatalystProjectile.new(), swaps in the projectile script,
# and applies the mode's tunings (speed, lifetime, colour, per-mode
# direction tweaks like chaos's 45° random cone).
#
# This is the same factory path becoming_catalyst.gd:_fire() takes when
# the player triggers the bracelet, so the firing behaviour here is
# identical to the trigger-shot in the Bracelet Zoo.
const MODE_FACTORIES := {
	"primitives":     preload("res://commons/hazards/becoming_catalyst/modes/mode_primitives.gd"),
	"transformation": preload("res://commons/hazards/becoming_catalyst/modes/mode_transformation.gd"),
	"chromatic":      preload("res://commons/hazards/becoming_catalyst/modes/mode_chromatic.gd"),
	"forces":         preload("res://commons/hazards/becoming_catalyst/modes/mode_forces.gd"),
	"waveform":       preload("res://commons/hazards/becoming_catalyst/modes/mode_waveform.gd"),
	"chaos":          preload("res://commons/hazards/becoming_catalyst/modes/mode_chaos.gd"),
	"fractal":        preload("res://commons/hazards/becoming_catalyst/modes/mode_fractal.gd"),
	"cellular":       preload("res://commons/hazards/becoming_catalyst/modes/mode_cellular.gd"),
	"branching":      preload("res://commons/hazards/becoming_catalyst/modes/mode_branching.gd"),
	"swarm":          preload("res://commons/hazards/becoming_catalyst/modes/mode_swarm.gd"),
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

## AXIS — WHAT A MARK PERSISTS AS once the hand that made it has gone. Adopted word for
## word from [[mystic_writing_pad]] and shared with [[draw_dot]],
## [[grab_sphere_point_snap]] and [[draw_triangle_faces]]. The mark this artifact makes is
## the LINE TO ORIGIN it inherits from interactive_point_origin — a measurement, drawn
## while held and hidden the instant you let go. So the question the family asks lands
## here as: does a reading survive the reader?
##
## The record is a DIAGRAM in the artifact's own local space, not a live line to world
## zero: a kept measurement runs to a small marker beside the point, so the record stays a
## hand-sized thing wherever the point is standing. It never touches the live
## line-to-origin, the morph, the attraction field or the projectile fire.
##
##   none      the legacy lineage, byte for byte. Let go and the reading is gone; the point
##             is a point again and space is as it was
##   trace     one dotted measurement stands after the hand leaves, ending in its marker —
##             the reading kept exactly as taken
##   lattice   a cubic field of pale nodes around the point, and the measurement admitted
##             only through them: a stair, not a diagonal. A reading must be legal to count
##   archive   seven readings kept at once, fanned to the same marker from seven past
##             positions. Every measurement ever made, and no way to say which was yours
##   wax       a dark plate under the point behind a pale sheet, with faint warm arcs of
##             past positions sunk between them — kept where the surface cannot show it
@export var retention: String = "none"
const RETENTIONS: PackedStringArray = ["none", "trace", "lattice", "archive", "wax"]

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
	# RETENTION last, so the shader install, the mode palette and the signal wiring above
	# are untouched. "none" is the legacy lineage and adds nothing at all.
	_ret_read_config()
	_ret_build()


# Replace the base class's _glow_material with our shader material so the
# vertex morph runs on the SAME MeshInstance3D the base class set up.
#
# Note this is the ONLY material the bead ever shows. The parent's _apply_glow
# / _restore_original_material pair writes to set_surface_override_material(0),
# and material_override outranks a surface override in Godot — so on this
# subclass the pickup glow swap has always been inert and the shader is what
# you see at every moment of the artifact's life. That is why the finish had to
# go into the shader rather than beside it.
func _install_force_shader() -> void:
	var mi: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mi == null:
		return
	_force_shader_mat = ShaderMaterial.new()
	_force_shader_mat.shader = FORCE_SHADER
	_force_shader_mat.set_shader_parameter("morph_t", 0.0)
	# SHINY BLACK VELVET at rest (Palle, 2026-08-27: "make this point a shiny
	# black velvet color"). Velvet is a rim phenomenon: near-black base with a
	# violet depth, emission all but out, and the grazing-edge rim turned UP -
	# the hard grain floor's tight specular supplies the "shiny". The force-field
	# look stays warm orange, so the bead rests as velvet and IGNITES under force.
	_force_shader_mat.set_shader_parameter("base_color", Color(0.030, 0.026, 0.036, 1.0))
	_force_shader_mat.set_shader_parameter("emission_base", 0.06)
	_force_shader_mat.set_shader_parameter("rim_amount", 0.85)
	_force_shader_mat.set_shader_parameter("force_color", Color(1.0, 0.55, 0.10, 1.0))
	_apply_bead_finish(mi)
	mi.material_override = _force_shader_mat


## The bead's surface finish: PbrKit's shared grain, tiled for a 60 mm ball.
##
## Both textures come out of PbrKit's static cache, so this costs no VRAM that
## the six already-migrated artifacts have not paid for — and it costs no new
## generation either if any of them built the same (kind, floor) pair first.
##
## LO_HARD is the roughness floor for a moulded hard surface, and its mean is
## what the shader divides the target roughness by, exactly as PbrKit._rough
## does for a StandardMaterial3D: Godot multiplies roughness by the map, so a
## texture averaging 0.85 silently makes everything 15% glossier than asked.
func _apply_bead_finish(mi: MeshInstance3D) -> void:
	if _force_shader_mat == null:
		return
	_force_shader_mat.set_shader_parameter(
		"grain_rough", PBR.grain(PBR.GRAIN_MICRO, PBR.LO_HARD))
	_force_shader_mat.set_shader_parameter(
		"grain_norm", PBR.grain_normal(PBR.GRAIN_MICRO, PBR.BUMP_FINE))
	_force_shader_mat.set_shader_parameter("grain_mean", (PBR.LO_HARD + 1.0) * 0.5)
	# Isotropic in metres of surface arc — see the GRAIN_TILES_PER_M block.
	var r: float = _bead_radius(mi)
	_force_shader_mat.set_shader_parameter("grain_uv", Vector2(
		TAU * r * GRAIN_TILES_PER_M,
		PI * r * GRAIN_TILES_PER_M))


## Measure the bead rather than hard-coding 0.03, so the grain stays sized to
## the object if point_mesh.gd's radius is ever changed in the scene. The child
## `Sphere` node is ready before this root is (Godot readies depth-first), so
## the SphereMesh is already in place by the time this runs.
func _bead_radius(mi: MeshInstance3D) -> float:
	var sphere: SphereMesh = mi.mesh as SphereMesh
	if sphere != null:
		return maxf(sphere.radius, 0.001)
	if mi.mesh != null:
		var ext: Vector3 = mi.mesh.get_aabb().size
		return maxf(maxf(ext.x, maxf(ext.y, ext.z)) * 0.5, 0.001)
	return 0.03


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
	# verb (chaos arcs, swarm flocks, chromatic paints, etc.) hand the
	# spawn to the same mode factory the bracelet's _fire() uses, so
	# the projectile's appearance + behaviour + initial direction tweak
	# (chaos's random cone, swarm's spread, etc.) match the trigger
	# shot from the Bracelet Zoo exactly.
	if mode != "" and MODE_FACTORIES.has(mode):
		_spawn_catalyst_projectile(origin, direction, MODE_FACTORIES[mode])
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

	# Same colour, same energy, same export — but PbrKit.emissive drops the
	# ALBEDO under the emission. A ball whose albedo AND emission are both full
	# value clips to white the instant any scene light lands on it, and a
	# clipped white projectile has lost the mode colour it was fired to show.
	var mat: StandardMaterial3D = PBR.emissive(ball_color, ball_emission_energy)
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


# Hand the spawn to a canonical mode factory — the same call signature
# becoming_catalyst.gd:_fire() uses for the bracelet's trigger shot:
#   create_projectile(spawn_pos, fire_dir) -> CatalystProjectile
# The factory configures the projectile's mode-specific tuning (visual,
# speed, lifetime, colour, any per-mode direction tweak). We just need
# to give it the right spawn position — the controller's tip, 15cm
# forward of the hand, so the projectile leaves where the player feels
# it ought to.
func _spawn_catalyst_projectile(_origin: Vector3, direction: Vector3, factory_script: GDScript) -> void:
	if factory_script == null:
		return
	var dir: Vector3 = direction.normalized() if direction.length_squared() > 0.0 else Vector3.FORWARD
	var spawn_pos: Vector3 = _fire_spawn_position(dir)
	var proj: Node = factory_script.create_projectile(spawn_pos, dir)
	if proj == null:
		return
	get_tree().current_scene.add_child(proj)
	if proj is Node3D:
		proj.global_position = spawn_pos


# Mirror of becoming_catalyst.gd:_fire's spawn-position rule: 15cm
# forward of the primary grabbing controller. Falls back to the
# artifact's own position offset by ball_radius if no controller is
# resolvable (e.g. test rig, mid-pickup transition).
func _fire_spawn_position(dir: Vector3) -> Vector3:
	if _grab_driver != null and is_instance_valid(_grab_driver):
		var primary = _grab_driver.get("primary")
		if primary != null and "controller" in primary:
			var ctrl = primary.controller
			if ctrl != null and ctrl is Node3D and is_instance_valid(ctrl):
				return ctrl.global_position + dir * 0.15
	return global_position + dir * (ball_radius * 2.5)


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
	if config_data.has("retention"):
		var r: String = str(config_data["retention"]).strip_edges().to_lower()
		if RETENTIONS.has(r) and r != retention:
			retention = r
			_ret_build()


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


# ── RETENTION ────────────────────────────────────────────────────────────────
# One axis, five claims about whether space remembers being touched, shared word for word
# with mystic_writing_pad, draw_dot, grab_sphere_point_snap and draw_triangle_faces.
# Appended LAST so the force shader, the mode palette and the grab wiring above are
# untouched, and built only in-game (the editor-hint return in _ready is above this).
#
# APPEARANCE ONLY, and that matters more here than anywhere else in the family: this is an
# XRToolsPickable. Nothing below reads or writes a collision layer, a mask, a mass, the
# grab driver, the morph, the attraction query or the projectile spawn. It adds
# MeshInstance3D children and nothing else, so what the artifact DOES is identical at
# every value. The record takes the mode palette's line colour, so a #mode:chaos point
# keeps a red record and a #mode:branching point keeps a green one.

const RET_DOT_R := 0.006
const RET_MARK := Vector3(-0.19, -0.13, 0.06)   # the datum the kept measurement runs to
const RET_STEP := 0.062                          # the lattice quantum

var _ret_node: Node3D = null


func _ret_read_config() -> void:
	if has_meta("config_retention"):
		var r: String = str(get_meta("config_retention")).strip_edges().to_lower()
		retention = r if RETENTIONS.has(r) else retention


func _ret_build() -> void:
	if Engine.is_editor_hint():
		return
	if is_instance_valid(_ret_node):
		_ret_node.queue_free()
	_ret_node = null

	match retention:
		"none":
			pass
		"trace":
			_ret_trace()
		"lattice":
			_ret_lattice()
		"archive":
			_ret_archive()
		"wax":
			_ret_wax()
		_:
			pass


func _ret_root() -> Node3D:
	if not is_instance_valid(_ret_node):
		_ret_node = Node3D.new()
		_ret_node.name = "RetentionRecord"
		add_child(_ret_node)
	return _ret_node


## TRACE — one kept reading. A dotted run from the point to its datum, and the datum left
## standing as a small cube: the measurement survives the measurer.
func _ret_trace() -> void:
	_ret_run(Vector3.ZERO, RET_MARK, line_color, 1.7, 20)
	_ret_datum(RET_MARK, line_color)


## LATTICE — a cubic field of pale nodes around the point, and the reading admitted only
## through them: the diagonal becomes a stair. A position had to be legal before it counted.
func _ret_lattice() -> void:
	var nodes := _ret_mm("LatticeNodes", _ret_emissive(Color(0.52, 0.62, 0.70), 0.5), RET_DOT_R * 0.6)
	var nm: MultiMesh = nodes.multimesh
	nm.instance_count = 4 * 4 * 4
	var k: int = 0
	for ix in range(4):
		for iy in range(4):
			for iz in range(4):
				nm.set_instance_transform(k, Transform3D(Basis(), Vector3(
					(float(ix) - 2.0) * RET_STEP,
					(float(iy) - 2.0) * RET_STEP,
					(float(iz) - 2.0) * RET_STEP)))
				k += 1
	_ret_root().add_child(nodes)
	# The stair: one axis at a time, node to node, from the point to the datum.
	var q: Vector3 = Vector3(
		round(RET_MARK.x / RET_STEP) * RET_STEP,
		round(RET_MARK.y / RET_STEP) * RET_STEP,
		round(RET_MARK.z / RET_STEP) * RET_STEP)
	var corner_a: Vector3 = Vector3(q.x, 0.0, 0.0)
	var corner_b: Vector3 = Vector3(q.x, q.y, 0.0)
	_ret_run(Vector3.ZERO, corner_a, line_color, 1.7, 7)
	_ret_run(corner_a, corner_b, line_color, 1.7, 6)
	_ret_run(corner_b, q, line_color, 1.7, 5)
	_ret_datum(q, line_color)


## ARCHIVE — seven readings kept at once, fanned to the same datum from seven past
## positions. Nothing was discarded, so nothing can be attributed.
func _ret_archive() -> void:
	for i in range(7):
		var a: float = -0.5 + 0.9 * float(i)
		var from: Vector3 = Vector3(sin(a) * 0.115, cos(a * 0.8) * 0.10, sin(a * 1.3) * 0.085)
		_ret_run(from, RET_MARK, line_color, 1.4, 14)
	_ret_datum(RET_MARK, line_color)


## WAX — the Wunderblock construction turned flat, because a hand-held point leaves its
## record in the ground it stood over: a matte dark plate under the artifact, a pale
## translucent sheet above it, and four faint warm arcs of past positions sunk between.
func _ret_wax() -> void:
	var root: Node3D = _ret_root()
	var y: float = -0.115

	var slab := MeshInstance3D.new()
	slab.name = "WaxPlate"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.155
	cm.bottom_radius = 0.155
	cm.height = 0.012
	cm.radial_segments = 32
	slab.mesh = cm
	# The wax. Was one albedo, one roughness, one metallic — the flat-plastic
	# signature on the largest surface the axis owns. hard_plastic at a low
	# gloss gives it a roughness map so the highlight breaks up, a micro normal
	# so it reads as a poured surface, and a faint waxy sheen instead of the old
	# dead 0.95 matte. Its kit default of 5 tiles/m lands the grain at about
	# 6.7 px across a 0.31 m plate, so this one needs no scale_detail.
	#
	# The albedo is lifted a hair off the shipped 0.10 for the reason PbrKit
	# spends a paragraph on: a surface with nothing left to shade reads as a
	# hole in the scene rather than as a dark object. `wear` is the ONLY
	# darkening applied — no AO map, no vertex wear, because three subtle
	# darkenings agree on black.
	var smat: StandardMaterial3D = PBR.hard_plastic(Color(0.115, 0.098, 0.108), 0.15, 0.18)
	slab.material_override = smat
	slab.position = Vector3(0, y, 0)
	root.add_child(slab)

	var warm := Color(0.95, 0.62, 0.35)
	for i in range(4):
		var f: float = float(4 - i) / 4.0
		var c: Color = warm.lerp(Color(0.10, 0.085, 0.095), 1.0 - f)
		var arc := _ret_mm("SunkArc%d" % i, _ret_emissive(c, 0.45 + 1.2 * f), RET_DOT_R * 0.9)
		var am: MultiMesh = arc.multimesh
		am.instance_count = 22
		var r: float = 0.045 + 0.028 * float(i)
		var ph: float = 0.7 * float(i)
		for j in range(22):
			var t: float = float(j) / 21.0
			var ang: float = ph + t * TAU * 0.62
			am.set_instance_transform(j, Transform3D(Basis(), Vector3(
				cos(ang) * r, y + 0.009 + 0.0015 * float(i), sin(ang) * r)))
		root.add_child(arc)

	var sheet := MeshInstance3D.new()
	sheet.name = "ClearingSheet"
	var pm := CylinderMesh.new()
	pm.top_radius = 0.155
	pm.bottom_radius = 0.155
	pm.height = 0.004
	pm.radial_segments = 32
	sheet.mesh = pm
	# The Wunderblock's celluloid. Same tint, same 0.30 opacity, same near-
	# roughness — but PbrKit.glass adds the Fresnel rim, which is the whole
	# difference between a sheet and a tinted ghost: real glass goes nearly
	# opaque at grazing angles, and without that this disc had no edges at all.
	# ONE transparent layer, which is the budget: overdraw is the Quest's
	# tightest, and screen-space refraction stays off (desktop_extras defaults
	# false). Kit tiling of 6/m puts its grain near 5.6 px here — no scaling.
	var pmat: StandardMaterial3D = PBR.glass(Color(0.62, 0.65, 0.70), 0.22, 0.30)
	sheet.material_override = pmat
	sheet.position = Vector3(0, y + 0.022, 0)
	root.add_child(sheet)


## A kept measurement, rendered as the points it is made of — no randf anywhere in the
## record path, so five variants differ by the axis and by nothing else.
func _ret_run(from: Vector3, to: Vector3, c: Color, energy: float, samples: int) -> void:
	var n: int = maxi(samples, 2)
	var mmi := _ret_mm("KeptRun", _ret_emissive(c, energy), RET_DOT_R)
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = n
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		mm.set_instance_transform(i, Transform3D(Basis(), from.lerp(to, t)))
	_ret_root().add_child(mmi)


## The datum a kept measurement runs to — a small cube, so the record has an end and reads
## as a reading rather than as decoration.
func _ret_datum(at: Vector3, c: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Datum"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.024, 0.024, 0.024)
	mi.mesh = bm
	mi.position = at
	mi.material_override = _ret_emissive(c, 2.0)
	_ret_root().add_child(mi)


func _ret_mm(nm: String, mat: Material, r: float) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dot := SphereMesh.new()
	dot.radius = r
	dot.height = r * 2.0
	dot.radial_segments = 6
	dot.rings = 3
	mm.mesh = dot
	mm.instance_count = 0
	mmi.multimesh = mm
	mmi.material_override = mat
	return mmi


func _ret_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
