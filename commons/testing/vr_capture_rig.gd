# @identity
# essence: vr_scene(no_headset) -> player_figure + posed_hands + environment -> headless still
# desire: make VR-only gestures evaluable by the chamber/DNA pattern without needing a headset
# critical_parameter: hand_basis (orientation math), camera angle (elevated 3/4), capture-only visual aids (kept out of production)
# triggers: static calls from any capture_* script; returns built nodes for further composition
# emerges: the auto-research-DNA pattern extends to VR-only artifacts — gestures, two-handed interactions, controller-relative behaviours
# needs: XR Tools addon present [has]; hand GLTFs at known paths [has]; project boots headless [has]
# relationships: used by capture_orb_gesture.gd; intended for future capture_bracelet_*, capture_voxel_*, capture_wedge_* scripts
# truth: the headset remains the source of truth — this rig produces stills, not felt experience. What it cannot capture (presence, haptics, body-knowledge) is left explicitly outside its scope.

# VRCaptureRig.gd
# Reusable helpers for mocking VR scenes in headless Godot captures.
# Use from any SceneTree script that wants to produce still images of
# gestures, hand-interactions, or other VR-only systems.
#
# Lessons embedded (see doc/VR_CAPTURE_PATTERN.md for the long form):
#   1. Player rig is fakeable — head sphere + torso cylinder + posed hands
#   2. Hand meshes load if you skip their scripts — load the .gltf, not the .tscn
#   3. Mirrored meshes need mirrored bases — explicit yaw flip for right hand
#   4. Stop animation players — hand models default to mid-grip pose
#   5. Elevated 3/4 separates what front-on collapses
#   6. Capture-only visual aids are honest — keep them in the rig, not production

extends RefCounted
class_name VRCaptureRig

# ── Hand mesh paths ─────────────────────────────────────────────────────
# Load the .gltf directly. The lowpoly_*.tscn scenes carry hand.gd,
# which depends on XRToolsUserSettings autoload — won't compile headless.
const LEFT_HAND_GLTF := preload("res://addons/godot-xr-tools/hands/model/Hand_Nails_low_L.gltf")
const RIGHT_HAND_GLTF := preload("res://addons/godot-xr-tools/hands/model/Hand_Nails_low_R.gltf")

# ── Catalyst mode colours (shared between orb + cone-visual aids) ───────
const MODE_COLORS := {
	"primitives":     Color(0.40, 0.95, 0.60),
	"transformation": Color(0.50, 0.80, 1.00),
	"chromatic":      Color(1.00, 0.55, 0.85),
	"forces":         Color(0.90, 0.85, 0.40),
	"waveform":       Color(0.60, 0.50, 1.00),
	"chaos":          Color(1.00, 0.50, 0.30),
	"fractal":        Color(0.50, 1.00, 0.80),
	"cellular":       Color(0.95, 0.95, 0.95),
	"branching":      Color(0.45, 0.85, 0.50),
	"swarm":          Color(1.00, 0.75, 0.20),
}

const DEFAULT_MODE_COLOR := Color(0.90, 0.90, 0.95)


# ── Environment ─────────────────────────────────────────────────────────

## Build a standard floor + lights + sky environment under `root`.
## Use for any capture that needs a neutral ground-and-light setup.
static func build_environment(
	root: Node3D,
	floor_size: float = 6.0,
	floor_color: Color = Color(0.88, 0.85, 0.72),
	sky_color: Color = Color(0.40, 0.50, 0.48),
) -> void:
	# Floor
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(floor_size, floor_size)
	floor.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = floor_color
	floor_mat.roughness = 0.7
	floor.material_override = floor_mat
	root.add_child(floor)

	# Environment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = sky_color
	env.ambient_light_color = Color(0.85, 0.85, 0.90)
	env.ambient_light_energy = 0.55
	env_node.environment = env
	root.add_child(env_node)

	# Key + fill lights
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.96, 0.86)
	key.light_energy = 1.0
	key.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.78, 0.86, 1.0)
	fill.light_energy = 0.45
	fill.rotation = Vector3(deg_to_rad(-25), deg_to_rad(-130), 0)
	root.add_child(fill)


# ── Player figure ───────────────────────────────────────────────────────

## Build a head + torso silhouette under `root` to give the gesture a
## spatial referent. Hands you pose separately. The figure faces -Z.
static func build_player_figure(
	root: Node3D,
	head_pos: Vector3 = Vector3(0, 1.62, 0),
	skin_color: Color = Color(0.85, 0.75, 0.68),
	torso_color: Color = Color(0.30, 0.32, 0.36),
) -> void:
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = skin_color
	skin_mat.roughness = 0.7

	# Head
	var head_mesh := MeshInstance3D.new()
	var head_sphere := SphereMesh.new()
	head_sphere.radius = 0.105
	head_sphere.height = 0.21
	head_mesh.mesh = head_sphere
	head_mesh.material_override = skin_mat
	head_mesh.position = head_pos
	root.add_child(head_mesh)

	# Torso (centred 0.42 m below head)
	var torso := MeshInstance3D.new()
	var torso_mesh := CylinderMesh.new()
	torso_mesh.top_radius = 0.16
	torso_mesh.bottom_radius = 0.20
	torso_mesh.height = 0.65
	torso.mesh = torso_mesh
	var torso_mat := StandardMaterial3D.new()
	torso_mat.albedo_color = torso_color
	torso_mat.roughness = 0.8
	torso.material_override = torso_mat
	torso.position = head_pos + Vector3(0, -0.42, 0)
	root.add_child(torso)


# ── Hand posing ─────────────────────────────────────────────────────────

## Instantiate a VR hand mesh at `pos` with the given `basis`, stop any
## auto-playing animation so the rest pose is captured cleanly, and log
## the resulting transform.
static func pose_hand(parent: Node, scene: PackedScene, pos: Vector3, basis: Basis, verbose: bool = true) -> Node3D:
	var hand: Node3D = scene.instantiate()
	hand.position = pos
	hand.transform.basis = basis
	parent.add_child(hand)
	for child in hand.get_children():
		stop_animation_players(child)
	if verbose:
		print("[vr_capture_rig] %s at %s, basis_x=%s y=%s z=%s" % [
			hand.name, pos,
			basis.x.snapped(Vector3.ONE * 0.01),
			basis.y.snapped(Vector3.ONE * 0.01),
			basis.z.snapped(Vector3.ONE * 0.01),
		])
	return hand


## Recursively stop any AnimationPlayer to freeze the model in rest pose.
## Hand models default to a mid-grip animation that will otherwise drive
## the skeleton mid-capture.
static func stop_animation_players(node: Node) -> void:
	if node is AnimationPlayer:
		(node as AnimationPlayer).stop()
		(node as AnimationPlayer).process_mode = Node.PROCESS_MODE_DISABLED
	for c in node.get_children():
		stop_animation_players(c)


## Build a Basis for a VR hand pose.
##
##  point_dir — world direction along which fingers should point
##  roll      — palm-orientation along the fingers axis:
##                +1.0 → palm faces world +X (left hand cupping toward right)
##                -1.0 → palm faces world -X (right hand cupping toward left)
##                 0.0 → palm down (resting/presenting pose)
##  is_left   — true for the left-hand mesh. The right mesh is intrinsically
##              mirrored, so we apply a 180° yaw to bring its natural-side
##              palm to face the left-hand position.
##
## XR Tools hand model convention (verified empirically):
##   Identity basis → fingers along world -Z, palm facing world +Y.
##   local +X → thumb side
##   local +Y → palm-up direction
##   local -Z → fingers forward
static func hand_basis(point_dir: Vector3, roll: float, is_left: bool) -> Basis:
	var b := Basis.IDENTITY
	# Roll around the model's local -Z (fingers axis) to bring palm from
	# "up" to facing sideways. +90° turns palm to +X, -90° to -X.
	if abs(roll) > 0.01:
		b = b.rotated(Vector3.FORWARD, deg_to_rad(90.0 * roll))
	# Mirror right hand 180° around Y so the model's natural orientation
	# faces back toward the left hand for cupping gestures.
	if not is_left:
		b = b.rotated(Vector3.UP, PI)
	# Align local -Z to world point_dir.
	var current_forward := -b.z
	var target_forward := point_dir.normalized()
	var rot_axis := current_forward.cross(target_forward)
	if rot_axis.length_squared() > 0.0001:
		var ang := current_forward.angle_to(target_forward)
		b = Basis(rot_axis.normalized(), ang) * b
	return b.orthonormalized()


# ── Visual aids (capture-only) ──────────────────────────────────────────
# These exist to make stills legible. They do NOT belong in production
# scenes — the design choices for the actual VR experience stand on their
# own. Use these only in capture_* scripts.

## Build a translucent cone-shaped MeshInstance3D pointing from `origin`
## along `direction` for `length` metres, tinted by `color`. Returns the
## node so the caller can parent it where they want.
static func build_cone_visual(
	origin: Vector3,
	direction: Vector3,
	length: float,
	color: Color,
	radius_top: float = 0.35,
	radius_bottom: float = 0.05,
	alpha: float = 0.18,
	emission_energy: float = 0.45,
) -> MeshInstance3D:
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.height = length
	mesh.top_radius = radius_top
	mesh.bottom_radius = radius_bottom
	cone.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emission_energy
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone.material_override = mat
	# Orient cylinder so its +Y (height) aligns with direction.
	var up_dir := direction.normalized()
	var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := up_dir.cross(ref_v).normalized()
	var rz := rx.cross(up_dir).normalized()
	cone.transform.basis = Basis(rx, up_dir, rz)
	cone.position = origin + up_dir * (length * 0.5)
	return cone


## Resolve a catalyst mode id to its canonical colour. Falls back to a
## neutral catalyst hue for unknown modes.
static func color_for_mode(mode_id: String) -> Color:
	return MODE_COLORS.get(mode_id, DEFAULT_MODE_COLOR)


# ── Camera helpers ──────────────────────────────────────────────────────

## Build a Camera3D positioned at `pos` looking at `target`, without
## requiring the camera to be inside the SceneTree first (which look_at()
## demands). Returns the node so the caller can parent it.
static func build_camera(pos: Vector3, target: Vector3, fov: float = 50.0) -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.transform = Transform3D().looking_at(target - pos, Vector3.UP)
	cam.position = pos
	return cam


## Default elevated 3/4 camera framing a player-figure gesture at chest
## height. Good for two-handed captures where line-of-sight occlusion
## would otherwise hide one hand behind the other.
static func default_elevated_camera() -> Camera3D:
	return build_camera(
		Vector3(1.30, 2.10, 0.35),
		Vector3(-0.05, 0.85, -1.40),
		50.0,
	)
