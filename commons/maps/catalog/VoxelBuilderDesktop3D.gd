# VoxelBuilderDesktop3D.gd — Minecraft-style desktop voxel editor
#
# Extends MapCatalogDesktop3D with WASD fly camera and click-to-edit cubes.
# Left click = add cube on face, right click = remove cube.
# Ctrl+S saves to map_data.json. Ctrl+Z/Y for undo/redo.
#
# Usage:
#   godot --path . --xr-mode off res://commons/maps/catalog/VoxelBuilderDesktop3D.tscn
#   godot --path . --xr-mode off res://commons/maps/catalog/VoxelBuilderDesktop3D.tscn -- --map=LSystems_Grammar_Lab

extends Node3D

const MAP_CATALOG_SCENE: String = "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

@export var fly_speed: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var crosshair_enabled: bool = true


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

var _camera: Camera3D = null
var _edit_controller: VoxelEditController = null
var _structure_component: GridStructureComponent = null
var _map_name: String = ""
var _mouse_captured: bool = false
var _fly_velocity: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _pitch: float = -0.3
var _hud: Label = null
var _crosshair: Control = null
var _catalog: Node = null
var _initialized: bool = false


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	# Parse command line for --map=
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			_map_name = arg.substr(6).strip_edges()

	# Load the catalog as a child (it brings GridSystem, cameras, etc.)
	_build_scene()


func _build_scene() -> void:
	# Create our own camera for fly mode
	_camera = Camera3D.new()
	_camera.name = "FlyCamera"
	_camera.current = true
	_camera.fov = 70.0
	_camera.position = Vector3(5, 4, -3)
	add_child(_camera)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.15, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Lights
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -30, 0)
	key.light_energy = 1.2
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_energy = 0.4
	add_child(fill)

	# Edit controller
	_edit_controller = VoxelEditController.new()
	_edit_controller.name = "VoxelEditController"
	add_child(_edit_controller)

	# HUD
	_build_hud()

	# Load map
	if not _map_name.is_empty():
		call_deferred("_load_map", _map_name)
	else:
		call_deferred("_load_map", "LSystems_Grammar_Lab")  # Default


func _load_map(map_name: String) -> void:
	_map_name = map_name
	print("[VoxelBuilder] Loading map: %s" % map_name)

	# Create a GridSystem to load the map
	var grid_system_scene := load("res://commons/grid/GridSystem.tscn")
	if not grid_system_scene:
		push_error("[VoxelBuilder] Cannot load GridSystem scene")
		return

	# Remove old grid if reloading
	var old_grid := get_node_or_null("GridSystem")
	if old_grid:
		old_grid.queue_free()
		await get_tree().process_frame

	var grid_system: Node = grid_system_scene.instantiate()
	grid_system.name = "GridSystem"
	# Set the map name before adding to tree
	if "map_name" in grid_system:
		grid_system.map_name = map_name
	add_child(grid_system)

	# Wait for map to load
	if grid_system.has_signal("map_generation_complete"):
		await grid_system.map_generation_complete
	else:
		# Fallback wait
		for _i in 10:
			await get_tree().process_frame

	# Find the structure component
	_structure_component = grid_system.find_child("GridStructureComponent", true, false) as GridStructureComponent
	if not _structure_component:
		push_warning("[VoxelBuilder] GridStructureComponent not found")
		return

	# Enable editing mode
	var data_component = grid_system.find_child("GridDataComponent", true, false)
	if data_component and data_component.has_method("get_structure_data"):
		_structure_component.enable_editing(data_component.get_structure_data())

	# Connect edit controller
	_edit_controller.structure_component = _structure_component
	_edit_controller.cube_size = _structure_component.cube_size

	# Position camera to see the map
	var dims: Vector3i = Vector3i(10, 6, 10)
	if data_component:
		dims = data_component.get_grid_dimensions()
	_camera.position = Vector3(float(dims.x) * 0.5, float(dims.y) + 2, -3.0)
	_yaw = 0.0
	_pitch = -0.3

	_initialized = true
	print("[VoxelBuilder] Ready to edit: %s (%dx%d)" % [map_name, dims.x, dims.z])


# ═══════════════════════════════════════════════════════════════
# INPUT
# ═══════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not _initialized:
		return

	# Toggle mouse capture with Escape
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_ESCAPE:
				if _mouse_captured:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					_mouse_captured = false
				return

			# Ctrl+S = save
			if key.keycode == KEY_S and key.ctrl_pressed:
				_save()
				return

			# Ctrl+Z = undo
			if key.keycode == KEY_Z and key.ctrl_pressed and not key.shift_pressed:
				if _edit_controller:
					_edit_controller.undo()
				return

			# Ctrl+Y or Ctrl+Shift+Z = redo
			if (key.keycode == KEY_Y and key.ctrl_pressed) or (key.keycode == KEY_Z and key.ctrl_pressed and key.shift_pressed):
				if _edit_controller:
					_edit_controller.redo()
				return

	# Mouse button — capture + edit
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if not _mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				_mouse_captured = true
				return

			# Left click = add cube
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if _edit_controller:
					_edit_controller.try_add()
				return

			# Right click = remove cube
			if mb.button_index == MOUSE_BUTTON_RIGHT:
				if _edit_controller:
					_edit_controller.try_remove()
				return

	# Mouse motion — look around (when captured)
	if event is InputEventMouseMotion and _mouse_captured:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * mouse_sensitivity
		_pitch -= motion.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, -PI * 0.49, PI * 0.49)


func _process(delta: float) -> void:
	if not _initialized:
		return

	# Fly camera movement
	if _mouse_captured:
		_update_fly_camera(delta)

	# Update edit controller raycast from camera center
	if _edit_controller and _camera:
		var center := get_viewport().get_visible_rect().size * 0.5
		var origin := _camera.project_ray_origin(center)
		var dir := _camera.project_ray_normal(center)
		_edit_controller.update_target_from_ray(origin, dir)

	_update_hud()


func _update_fly_camera(delta: float) -> void:
	if not _camera:
		return

	# Build direction from input
	var input_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.z -= 1
	if Input.is_key_pressed(KEY_S): input_dir.z += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	if Input.is_key_pressed(KEY_SPACE): input_dir.y += 1
	if Input.is_key_pressed(KEY_SHIFT): input_dir.y -= 1

	# Apply camera rotation
	var basis := Basis()
	basis = basis.rotated(Vector3.UP, _yaw)
	basis = basis.rotated(basis.x, _pitch)

	var move_dir := basis * input_dir.normalized()
	var speed := fly_speed * (2.0 if Input.is_key_pressed(KEY_CTRL) else 1.0)
	_camera.position += move_dir * speed * delta
	_camera.basis = basis


# ═══════════════════════════════════════════════════════════════
# SAVE
# ═══════════════════════════════════════════════════════════════

func _save() -> void:
	if not _structure_component or _map_name.is_empty():
		return
	var ok := VoxelSaveManager.save(_map_name, _structure_component)
	if ok:
		print("[VoxelBuilder] SAVED: %s" % _map_name)


# ═══════════════════════════════════════════════════════════════
# HUD
# ═══════════════════════════════════════════════════════════════

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "BuilderHUD"
	canvas.layer = 100
	add_child(canvas)

	_hud = Label.new()
	_hud.position = Vector2(16, 16)
	_hud.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.9))
	_hud.add_theme_font_size_override("font_size", 14)
	_hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_hud.add_theme_constant_override("shadow_offset_x", 1)
	_hud.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(_hud)

	# Crosshair
	if crosshair_enabled:
		_crosshair = Control.new()
		_crosshair.name = "Crosshair"
		_crosshair.set_anchors_preset(Control.PRESET_CENTER)
		_crosshair.custom_minimum_size = Vector2(20, 20)
		_crosshair.draw.connect(func():
			var center := _crosshair.size * 0.5
			_crosshair.draw_line(center + Vector2(-8, 0), center + Vector2(8, 0), Color.WHITE, 1.5)
			_crosshair.draw_line(center + Vector2(0, -8), center + Vector2(0, 8), Color.WHITE, 1.5)
		)
		canvas.add_child(_crosshair)


func _update_hud() -> void:
	if not _hud:
		return

	var target_info: String = "No target"
	if _edit_controller and _edit_controller.has_target:
		var tc := _edit_controller.target_cell
		var ac := _edit_controller.add_cell
		var h := 0
		if _structure_component:
			h = _structure_component.get_height_at(tc.x, tc.z)
		target_info = "Target: (%d,%d,%d) h=%d | Add: (%d,%d,%d)" % [
			tc.x, tc.y, tc.z, h, ac.x, ac.y, ac.z
		]

	var mode := "FLY" if _mouse_captured else "CURSOR"
	_hud.text = "VOXEL BUILDER: %s\n%s\nMode: %s | Click to capture mouse\nL-Click=Add R-Click=Remove | Ctrl+S=Save Ctrl+Z=Undo Esc=Release" % [
		_map_name, target_info, mode
	]
