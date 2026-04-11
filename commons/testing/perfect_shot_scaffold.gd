# PerfectShotScaffold.gd — Reusable capture environment (camera, lights, ground)
#
# Extracts the duplicated scaffold setup from capture_all.gd and
# capture_multi_angle.gd into a single reusable class. Adapts background,
# ground plane size, and ambient lighting based on scene size class.
#
# Usage:
#   var scaffold := PerfectShotScaffold.new()
#   var scene_root: Node3D = scaffold.build(scene_tree)
#   scaffold.load_into_container(my_artifact_instance)
#   scaffold.apply_size_preset(_Framer.SizeClass.SMALL)
#   scaffold.position_camera(focus, yaw, pitch, distance)
#   # ... capture viewport ...
#   scaffold.clear_container()

class_name PerfectShotScaffold
extends RefCounted

const _Framer = preload("res://commons/testing/perfect_shot_framer.gd")


# ─────────────────────────────────────────────────────────────
#  Default settings (match proven values from capture_all.gd)
# ─────────────────────────────────────────────────────────────

const DEFAULT_BG_COLOR := Color(0.12, 0.12, 0.16)
const DEFAULT_AMBIENT_COLOR := Color(0.5, 0.5, 0.55)
const DEFAULT_AMBIENT_ENERGY: float = 0.6
const DEFAULT_FOV: float = 50.0
const DEFAULT_GROUND_COLOR := Color(0.15, 0.15, 0.18)
const DEFAULT_GROUND_SIZE := Vector2(20.0, 20.0)

## Key light settings.
const KEY_LIGHT_ROTATION := Vector3(-45.0, -30.0, 0.0)
const KEY_LIGHT_ENERGY: float = 1.2

## Fill light settings.
const FILL_LIGHT_ROTATION := Vector3(-20.0, 150.0, 0.0)
const FILL_LIGHT_ENERGY: float = 0.4


# ─────────────────────────────────────────────────────────────
#  Scene components
# ─────────────────────────────────────────────────────────────

var scene_root: Node3D = null
var camera: Camera3D = null
var world_env: WorldEnvironment = null
var environment: Environment = null
var key_light: DirectionalLight3D = null
var fill_light: DirectionalLight3D = null
var ground: MeshInstance3D = null
var ground_material: StandardMaterial3D = null
var instance_container: Node3D = null

## Reference to the SceneTree (for viewport access).
var _scene_tree: SceneTree = null


# ═══════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════

## Build the full scaffold in the given SceneTree. Returns the scene root.
func build(tree: SceneTree) -> Node3D:
	_scene_tree = tree

	scene_root = Node3D.new()
	scene_root.name = "PerfectShotScaffold"
	tree.root.add_child(scene_root)

	# World environment
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = DEFAULT_BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = DEFAULT_AMBIENT_COLOR
	environment.ambient_light_energy = DEFAULT_AMBIENT_ENERGY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	world_env = WorldEnvironment.new()
	world_env.environment = environment
	scene_root.add_child(world_env)

	# Camera
	camera = Camera3D.new()
	camera.name = "PerfectShotCamera"
	camera.current = true
	camera.fov = DEFAULT_FOV
	scene_root.add_child(camera)

	# Key light
	key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = KEY_LIGHT_ROTATION
	key_light.light_energy = KEY_LIGHT_ENERGY
	key_light.shadow_enabled = true
	scene_root.add_child(key_light)

	# Fill light
	fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.rotation_degrees = FILL_LIGHT_ROTATION
	fill_light.light_energy = FILL_LIGHT_ENERGY
	fill_light.shadow_enabled = false
	scene_root.add_child(fill_light)

	# Ground plane
	ground = MeshInstance3D.new()
	ground.name = "Ground"
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = DEFAULT_GROUND_SIZE
	ground.mesh = ground_mesh

	ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = DEFAULT_GROUND_COLOR
	ground.material_override = ground_material
	scene_root.add_child(ground)

	# Instance container — where loaded scenes go
	instance_container = Node3D.new()
	instance_container.name = "InstanceContainer"
	scene_root.add_child(instance_container)

	return scene_root


# ═══════════════════════════════════════════════════════════════
# SIZE-AWARE ADAPTATION
# ═══════════════════════════════════════════════════════════════

## Apply visual preset based on size class. Adjusts ground, ambient, etc.
func apply_size_preset(size_class: int, aabb: AABB = AABB()) -> void:
	if not environment or not ground:
		return

	# Ground size
	var ground_size: Vector2 = _Framer.get_ground_size(aabb, size_class)
	if ground.mesh is PlaneMesh:
		(ground.mesh as PlaneMesh).size = ground_size

	match size_class:
		_Framer.SizeClass.TINY, _Framer.SizeClass.SMALL:
			# Studio: slightly brighter ambient, subtle warm ground
			environment.ambient_light_energy = 0.7
			environment.background_color = Color(0.10, 0.10, 0.14)
			ground_material.albedo_color = Color(0.13, 0.12, 0.16)

		_Framer.SizeClass.MEDIUM:
			# Standard settings
			environment.ambient_light_energy = DEFAULT_AMBIENT_ENERGY
			environment.background_color = DEFAULT_BG_COLOR
			ground_material.albedo_color = DEFAULT_GROUND_COLOR

		_Framer.SizeClass.LARGE, _Framer.SizeClass.HUGE:
			# Environment: brighter overall, larger ground
			environment.ambient_light_energy = 0.8
			environment.background_color = Color(0.14, 0.14, 0.18)
			ground_material.albedo_color = Color(0.15, 0.15, 0.18)

		_Framer.SizeClass.FLAT:
			# Flat: clean background, minimal ground
			environment.ambient_light_energy = 0.65
			environment.background_color = Color(0.10, 0.10, 0.13)
			ground_material.albedo_color = Color(0.12, 0.12, 0.15)


# ═══════════════════════════════════════════════════════════════
# CAMERA POSITIONING
# ═══════════════════════════════════════════════════════════════

## Position the camera using spherical orbit (for TINY/SMALL/MEDIUM/FLAT).
func position_camera(focus: Vector3, yaw: float, pitch: float, distance: float) -> void:
	if not camera:
		return
	camera.global_position = _Framer.compute_orbit_position(focus, yaw, pitch, distance)
	camera.look_at(focus, Vector3.UP)


## Position camera for environment angles (LARGE/HUGE with pitch_factor).
func position_camera_environment(
	focus: Vector3,
	yaw: float,
	pitch_factor: float,
	orbit_radius: float,
	orbit_height: float
) -> void:
	if not camera:
		return
	camera.global_position = _Framer.compute_environment_orbit_position(
		focus, yaw, pitch_factor, orbit_radius, orbit_height
	)
	camera.look_at(focus, Vector3.UP)


## Position camera from an angle dictionary (auto-detects orbit mode).
## After positioning, always look_at the AABB center to guarantee the object is in frame.
func position_camera_from_angle(angle: Dictionary, analysis: Dictionary) -> void:
	var focus: Vector3 = analysis.get("orbit_focus", Vector3.ZERO)
	var distance: float = analysis.get("orbit_distance", 5.0)
	var aabb: AABB = analysis.get("aabb", AABB())

	# The look-at target is the AABB center (offset by instance position = origin after centering)
	var look_target: Vector3 = focus

	if _Framer.is_environment_angle(angle):
		var orbit_radius: float = _Framer.get_environment_orbit_radius(aabb)
		var orbit_height: float = _Framer.get_environment_orbit_height(aabb)
		position_camera_environment(
			focus, angle["yaw"], angle["pitch_factor"],
			orbit_radius, orbit_height
		)
	else:
		position_camera(focus, angle["yaw"], angle["pitch"], distance)

	# Safety: always ensure camera looks at the center of mass
	if camera:
		camera.look_at(look_target, Vector3.UP)


# ═══════════════════════════════════════════════════════════════
# INSTANCE MANAGEMENT
# ═══════════════════════════════════════════════════════════════

## Add a scene instance to the container. Centers and scales it based on AABB.
func load_into_container(instance: Node3D) -> void:
	if not instance_container:
		return
	instance_container.add_child(instance)


## Center the instance at origin based on its AABB.
## Call AFTER the scene has settled (_ready finished, procedural geometry built).
func center_instance(instance: Node3D) -> void:
	# Reset position first so AABB is measured at origin
	instance.position = Vector3.ZERO

	var aabb: AABB = _Framer.get_combined_aabb(instance)
	if aabb.size.length() < 0.001:
		return

	# Move instance so AABB center sits at world origin
	var center: Vector3 = aabb.get_center()
	instance.position = -center
	# Lift so bottom of AABB sits at ground level (y=0)
	instance.position.y += -aabb.position.y


## Clear all instances from the container.
func clear_container() -> void:
	if not instance_container:
		return
	for child in instance_container.get_children():
		child.queue_free()


# ═══════════════════════════════════════════════════════════════
# SCREENSHOT
# ═══════════════════════════════════════════════════════════════

## Capture the current viewport and save as PNG.
func save_screenshot(output_path: String) -> bool:
	if not _scene_tree:
		return false

	var image: Image = _scene_tree.root.get_texture().get_image()
	if image == null:
		return false

	var absolute_path: String = output_path
	if output_path.begins_with("user://") or output_path.begins_with("res://"):
		absolute_path = ProjectSettings.globalize_path(output_path)

	var dir_path: String = absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	return image.save_png(absolute_path) == OK


# ═══════════════════════════════════════════════════════════════
# SCAFFOLD INTEGRITY (from capture_all.gd _ensure_scaffold pattern)
# ═══════════════════════════════════════════════════════════════

## Rebuild any scaffold components destroyed by an artifact's _ready().
func ensure_valid() -> void:
	if not is_instance_valid(scene_root):
		if _scene_tree:
			build(_scene_tree)
		return

	if not is_instance_valid(camera):
		camera = Camera3D.new()
		camera.name = "PerfectShotCamera"
		camera.current = true
		camera.fov = DEFAULT_FOV
		scene_root.add_child(camera)

	if not is_instance_valid(ground):
		ground = MeshInstance3D.new()
		ground.name = "Ground"
		var ground_mesh := PlaneMesh.new()
		ground_mesh.size = DEFAULT_GROUND_SIZE
		ground.mesh = ground_mesh
		ground_material = StandardMaterial3D.new()
		ground_material.albedo_color = DEFAULT_GROUND_COLOR
		ground.material_override = ground_material
		scene_root.add_child(ground)

	if not is_instance_valid(instance_container):
		instance_container = Node3D.new()
		instance_container.name = "InstanceContainer"
		scene_root.add_child(instance_container)

	if is_instance_valid(camera):
		camera.current = true


## Teardown the scaffold and free all resources.
func teardown() -> void:
	if is_instance_valid(scene_root):
		scene_root.queue_free()
	scene_root = null
	camera = null
	world_env = null
	environment = null
	key_light = null
	fill_light = null
	ground = null
	ground_material = null
	instance_container = null
