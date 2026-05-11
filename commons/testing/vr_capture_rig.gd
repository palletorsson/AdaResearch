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
# Hand_low_L/R (no nails) avoids the doubled-geometry artifact that the
# Hand_Nails_low variants produce when their separate nails mesh isn't
# materialised correctly.
const LEFT_HAND_GLTF := preload("res://addons/godot-xr-tools/hands/model/Hand_low_L.gltf")
const RIGHT_HAND_GLTF := preload("res://addons/godot-xr-tools/hands/model/Hand_low_R.gltf")

# AnimationPlayer scenes — each holds 30+ named hand poses (Cup, OK,
# Peace, Pinch Tight, Pistol, Rounded, Sign_Point, etc.). Instance one
# of these as a child of the hand and play(pose_name) to apply a static
# gesture.
const LEFT_HAND_ANIM := preload("res://addons/godot-xr-tools/hands/animations/left/AnimationPlayer.tscn")
const RIGHT_HAND_ANIM := preload("res://addons/godot-xr-tools/hands/animations/right/AnimationPlayer.tscn")

# Default hand material (the same one base.tscn's hands use).
const HAND_MATERIAL := preload("res://addons/godot-xr-tools/hands/materials/caucasian_hand.tres")

# Curated subset of pose names from the AnimationPlayer — names suitable
# for orb / catalyst gestures. The full list (see AnimationPlayer.tscn)
# also has Pistol, OK, Peace, Sign_*, Horns, Metal, Surfer, etc.
const POSE_DEFAULT     := "Default pose"
const POSE_CUP         := "Cup"
const POSE_ROUNDED     := "Rounded"
const POSE_HOLD        := "Hold"
const POSE_PINCH_FLAT  := "Pinch Flat"
const POSE_PINCH_TIGHT := "Pinch Tight"
const POSE_PINCH_UP    := "Pinch Up"
const POSE_STRAIGHT    := "Straight"
const POSE_GRIP        := "Grip"
const POSE_GRIP_OPEN   := "Grip 5"
const POSE_PISTOL      := "Pistol"
const POSE_POINT       := "Sign_Point"
const POSE_OK          := "OK"
const POSE_PEACE       := "Peace"
const POSE_PINKY       := "Pinky"
const POSE_THUMB       := "Thumb"

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

# Per-mode 3-stop palettes for the orb's noise shader. Each palette
# tells the same story in three colours: a base, a deeper saturate,
# and a highlight that gives the orb its texture under noise mixing.
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

const DEFAULT_PALETTE := [Color(0.40, 0.95, 0.60), Color(0.55, 0.95, 0.70), Color(0.85, 1.00, 0.85)]

# The orb's noise+palette shader.
const ORB_NOISE_SHADER := preload("res://commons/hazards/becoming_catalyst/orb_noise.gdshader")


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

## Instantiate a VR hand mesh at `pos` with the given `basis`, apply the
## proper hand material, instance the AnimationPlayer that holds all the
## named poses, and play the requested pose (e.g. POSE_CUP, POSE_POINT).
## If pose_name is empty or unknown, holds the default pose.
static func pose_hand(
	parent: Node,
	scene: PackedScene,
	pos: Vector3,
	basis: Basis,
	pose_name: String = POSE_DEFAULT,
	is_left: bool = true,
	verbose: bool = true,
) -> Node3D:
	var hand: Node3D = scene.instantiate()
	hand.position = pos
	hand.transform.basis = basis
	parent.add_child(hand)

	# Material — without this the mesh renders washed-out / blown.
	_apply_material_to_meshes(hand, HAND_MATERIAL)

	# Stop any AnimationPlayers that came with the GLTF (rest skeletal
	# motion) before we attach our own pose player.
	for child in hand.get_children():
		stop_animation_players(child)

	# Pose: instance the pose AnimationPlayer scene and play(pose_name).
	# The animation tracks target Armature/Skeleton3D bone paths which
	# resolve once this player is a sibling of the GLTF's armature.
	var anim_scene: PackedScene = LEFT_HAND_ANIM if is_left else RIGHT_HAND_ANIM
	var anim_node: Node = anim_scene.instantiate()
	hand.add_child(anim_node)
	if anim_node is AnimationPlayer:
		var ap := anim_node as AnimationPlayer
		var target_pose := pose_name
		if not ap.has_animation(target_pose):
			target_pose = POSE_DEFAULT
		if ap.has_animation(target_pose):
			ap.play(target_pose)
			# Hand poses are mostly single-frame; advance to the end so
			# the skeleton settles on the target pose immediately.
			ap.advance(ap.current_animation_length)

	if verbose:
		print("[vr_capture_rig] %s at %s, pose=%s" % [hand.name, pos, pose_name])
	return hand


## Apply a material override to every MeshInstance3D under `root`.
## Uses material_override so the GLTF's surface materials are replaced
## without modifying the imported scene's resources.
static func _apply_material_to_meshes(root: Node, mat: Material) -> void:
	if mat == null:
		return
	if root is MeshInstance3D:
		(root as MeshInstance3D).material_override = mat
	for c in root.get_children():
		_apply_material_to_meshes(c, mat)


## Recursively stop any AnimationPlayer to freeze the model in rest pose.
## Hand models default to a mid-grip animation that will otherwise drive
## the skeleton mid-capture.
static func stop_animation_players(node: Node) -> void:
	if node is AnimationPlayer:
		(node as AnimationPlayer).stop()
		(node as AnimationPlayer).process_mode = Node.PROCESS_MODE_DISABLED
	for c in node.get_children():
		stop_animation_players(c)


## Natural rest basis — palms down, thumbs pointing inward, fingers
## forward. This is the calibration baseline: every other gesture-pose
## rotation should be defined as a delta from here.
##
## XR Tools mesh axes (verified empirically): the left and right GLBs
## are MIRRORED versions of each other. Both have their fingers along
## intrinsic +X and palm-back along intrinsic +Z, BUT the right mesh's
## thumb is on its intrinsic -Y while the left's thumb is on +Y (or
## vice-versa — observed via the orientation research run on 2026-05-11).
##
## So the same target-world basis applied to both meshes yields the
## natural mirror-symmetric rest pose:
##   x_world = (0, 0, -1)   fingers forward (away from player)
##   y_world = (-1, 0, 0)   model +Y → world -X (mirror does the work)
##   z_world = (0, +1, 0)   palm-back up → palm faces down
static func natural_rest_basis(_is_left: bool = true) -> Basis:
	return Basis(
		Vector3(0, 0, -1),
		Vector3(-1, 0, 0),
		Vector3(0, 1, 0),
	)


## Build a Basis for a VR hand pose, composed off natural_rest_basis().
##
##  point_dir — world direction along which fingers should point
##              (e.g., orb_dir for "fingers aim at orb's projection")
##  roll      — palm-rotation around the fingers axis. Each unit is 90°:
##                roll = 0   → palm-down (natural rest, aimed along point_dir)
##                roll = +1  → +90° around fingers axis (palm rotates one way)
##                roll = -1  → -90° around fingers axis (opposite)
##              For two-handed cupping, pass roll_l=+1 / roll_r=-1
##              (or vice-versa; visually test).
##  is_left   — IGNORED. The L/R hand GLBs are already mirrored at the
##              geometry level, so the same basis produces natural
##              mirror-symmetric rest. (Kept in the signature for
##              backward compatibility with existing callers.)
##
## Verified 2026-05-11 (orientation research run):
##   XR Tools mesh has local +X = fingers, local +Z = palm-back.
##   natural_rest_basis() encodes that into a clean world-frame baseline.
static func hand_basis(point_dir: Vector3, roll: float = 0.0, _is_left: bool = true) -> Basis:
	var rest := natural_rest_basis()  # fingers world -Z, palm down

	# Rotate rest so fingers align with point_dir.
	var rest_fingers := Vector3(0, 0, -1)
	var target := point_dir.normalized()
	var b := rest
	if rest_fingers.distance_squared_to(target) > 0.000001:
		var axis := rest_fingers.cross(target)
		if axis.length_squared() > 0.000001:
			var ang := rest_fingers.angle_to(target)
			b = Basis(axis.normalized(), ang) * rest
		elif rest_fingers.dot(target) < 0:
			b = Basis(Vector3.UP, PI) * rest

	# Roll around the (newly-rotated) fingers axis.
	if abs(roll) > 0.01:
		b = Basis(target, deg_to_rad(90.0 * roll)) * b

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


## Resolve a catalyst mode id to its 3-stop palette (Array of 3 Colors).
## Used by the orb's noise+palette shader.
static func palette_for_mode(mode_id: String) -> Array:
	return MODE_PALETTES.get(mode_id, DEFAULT_PALETTE)


## Replace the orb's StandardMaterial3D with the noise+palette ShaderMaterial,
## using the per-mode palette. Walks the orb's MeshInstance3D children and
## swaps their material_override. Pass an empty mode_id to use the default
## palette. Capture-only — production VR uses the original material.
static func apply_orb_noise_shader(orb: Node3D, mode_id: String, noise_amount: float = 0.06, emission_energy: float = 1.8) -> void:
	var palette: Array = palette_for_mode(mode_id)
	var mat := ShaderMaterial.new()
	mat.shader = ORB_NOISE_SHADER
	# Pass Colors — Godot converts source_color hinted vec3 from Color.
	mat.set_shader_parameter("palette_a", palette[0] as Color)
	mat.set_shader_parameter("palette_b", palette[1] as Color)
	mat.set_shader_parameter("palette_c", palette[2] as Color)
	mat.set_shader_parameter("noise_scale", 5.0)
	mat.set_shader_parameter("noise_amount", noise_amount)
	mat.set_shader_parameter("time_scale", 0.6)
	mat.set_shader_parameter("emission_energy", emission_energy)
	mat.set_shader_parameter("halo_softness", 0.4)
	for c in orb.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).material_override = mat


## Build a capture-only stand-in for the catalyst bracelet — a short
## cylindrical band wrapped around the wrist, with three gems showing the
## catalyst modes (centre gem = active). The real bracelet (capacity_bracelet)
## carries game logic; this is still-image visualisation only.
##
##   pos:               world position of the wrist
##   forearm_dir:       direction the forearm extends (away from hand). The
##                      band's cylinder axis aligns with this. For natural
##                      rest, this is ~Vector3(0.3, -0.1, 0.9).normalized().
##   active_mode_color: hue for the centre gem
static func build_bracelet(
	parent: Node,
	pos: Vector3,
	forearm_dir: Vector3 = Vector3(0.3, -0.1, 0.9),
	active_mode_color: Color = Color(0.40, 0.95, 0.60),
) -> Node3D:
	var root := Node3D.new()
	root.name = "BraceletStandin"
	root.position = pos
	# Orient root so its local +Y axis aligns with forearm direction —
	# then the cylinder's default Y-axis becomes the wrist axis.
	var up_dir := forearm_dir.normalized()
	var ref_v := Vector3.UP if abs(up_dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var rx := up_dir.cross(ref_v).normalized()
	var rz := rx.cross(up_dir).normalized()
	root.transform.basis = Basis(rx, up_dir, rz)
	parent.add_child(root)

	# Torus ring — bracelet body with a visible hole so it reads as
	# wrap-around rather than a solid disk. Torus default axis is local
	# +Y, which the root's basis has already aligned with the forearm
	# direction — so no inner rotation is needed.
	var band := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.036
	torus.outer_radius = 0.044
	torus.ring_segments = 36
	torus.rings = 12
	band.mesh = torus
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.18, 0.18, 0.22)
	band_mat.metallic = 0.7
	band_mat.roughness = 0.30
	band.material_override = band_mat
	root.add_child(band)

	# Three gems on top of the band — sit ON the surface (radius outward).
	var gem_colors := [
		Color(0.35, 0.32, 0.40),
		active_mode_color,
		Color(0.35, 0.32, 0.40),
	]
	for i in range(3):
		var gem := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.009
		sphere.height = 0.018
		gem.mesh = sphere
		var gem_mat := StandardMaterial3D.new()
		gem_mat.albedo_color = gem_colors[i]
		gem_mat.emission_enabled = true
		gem_mat.emission = gem_colors[i]
		gem_mat.emission_energy_multiplier = 3.0 if i == 1 else 0.8
		gem_mat.metallic = 0.4
		gem.material_override = gem_mat
		# Gems on the torus's outer ring, on the TOP-facing side.
		# Ring lies in local XZ plane; local +Z aligns with world +Y
		# (top of the wrist) given the root basis. So we place gems
		# clustered around local +Z direction.
		var angle := deg_to_rad((i - 1) * 22.0 + 90.0)
		var r := 0.044
		gem.position = Vector3(cos(angle) * r, 0, sin(angle) * r)
		if i == 1:
			gem.scale = Vector3.ONE * 1.4
		root.add_child(gem)

	# Subtle glow from the active gem. Pulled in close + low energy so
	# it lights only the gem itself, not the surrounding hand.
	var glow := OmniLight3D.new()
	glow.light_color = active_mode_color
	glow.light_energy = 0.10
	glow.omni_range = 0.05
	glow.position = Vector3(0, 0, 0.045)
	root.add_child(glow)

	return root


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


## First-person camera at the player's eye height, tilted to look at
## where the hands would be when extended forward. This is the view
## the player ACTUALLY HAS in VR — looking down at their own hands.
##
##   eye_height    — usually 1.62 m (matches XROrigin3D defaults)
##   look_at_target — where the player is gazing (the gesture origin)
##   fov           — 90° matches a generous VR FOV; 70° is more cinematic
static func first_person_camera(
	eye_height: float = 1.62,
	look_at_target: Vector3 = Vector3(0, 1.10, -0.80),
	fov: float = 80.0,
) -> Camera3D:
	return build_camera(
		Vector3(0.0, eye_height, 0.0),
		look_at_target,
		fov,
	)


## Add a head sphere + torso to root, but offset so the camera (at
## origin/eye height) doesn't see the figure's own head/torso clipping.
## For first-person captures, skip the head and put the torso below the
## camera so a sliver of shoulder/chest reads at the bottom of the frame.
static func build_first_person_figure(root: Node3D) -> void:
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.85, 0.75, 0.68)
	skin_mat.roughness = 0.7
	# Torso just below where the camera will be — barely visible as a hint
	# of chest/shoulders.
	var torso := MeshInstance3D.new()
	var torso_mesh := CylinderMesh.new()
	torso_mesh.top_radius = 0.18
	torso_mesh.bottom_radius = 0.22
	torso_mesh.height = 0.70
	torso.mesh = torso_mesh
	var torso_mat := StandardMaterial3D.new()
	torso_mat.albedo_color = Color(0.30, 0.32, 0.36)
	torso_mat.roughness = 0.8
	torso.material_override = torso_mat
	# Position so the top of the torso is just below eye level.
	torso.position = Vector3(0, 1.62 - 0.35 - 0.10, -0.05)
	root.add_child(torso)
