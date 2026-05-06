# effect_demo.gd
# Demo scene for previewing post-processing effects.
# Desktop camera with WASD + mouse look.
#
# Controls:
#   WASD           — move camera
#   QE             — move up/down
#   Right-click    — mouse look
#   [ ]            — cycle effects
#   +/-            — change intensity
#   R              — reset intensity to 0.5
#   Space          — toggle auto-animate intensity
#   1-6            — jump to effect by number
#   0              — no effect
#   Escape         — quit
extends Node3D

# ── Effect registry ──────────────────────────────────────────────────────────
# Each entry: { name, shader_path, description }
const EFFECTS: Array = [
	{
		"name": "None",
		"shader_path": "",
		"description": "No post-processing — raw scene"
	},
	{
		"name": "Mushroom Trip",
		"shader_path": "res://commons/resourses/shaders/mushroom_trip.gdshader",
		"description": "Psychedelic: wave distortion, chromatic aberration, hue shift, breathing vignette"
	},
	{
		"name": "Ripple",
		"shader_path": "res://commons/resourses/shaders/pp_ripple.gdshader",
		"description": "Concentric ripples emanating from center with wave distortion"
	},
	{
		"name": "Glitch",
		"shader_path": "res://commons/resourses/shaders/pp_glitch.gdshader",
		"description": "Digital corruption: scanlines, RGB split, block displacement, noise"
	},
	{
		"name": "Pixelate",
		"shader_path": "res://commons/resourses/shaders/pp_pixelate.gdshader",
		"description": "Mosaic pixelation with color quantization and edge detection"
	},
	{
		"name": "Night Vision",
		"shader_path": "res://commons/resourses/shaders/pp_night_vision.gdshader",
		"description": "Green phosphor night vision with scanlines, noise grain, vignette"
	},
	{
		"name": "Edge Detect",
		"shader_path": "res://commons/resourses/shaders/pp_edge_detect.gdshader",
		"description": "Sobel edge detection — outlines overlaid on scene"
	},
]

# ── State ────────────────────────────────────────────────────────────────────
var _current_effect: int = 0
var _intensity: float = 0.5
var _auto_animate: bool = false
var _animate_time: float = 0.0

# ── Nodes ────────────────────────────────────────────────────────────────────
var _camera: Camera3D = null
var _canvas_layer: CanvasLayer = null
var _color_rect: ColorRect = null
var _shader_mat: ShaderMaterial = null
var _label: Label = null
var _desc_label: Label = null

# ── Camera control ───────────────────────────────────────────────────────────
var _is_vr: bool = false
var _cam_yaw: float = 0.0
var _cam_pitch: float = -15.0
var _mouse_captured: bool = false
var _mouse_sensitivity: float = 0.2
var _move_speed: float = 8.0

func _ready() -> void:
	_build_scene_content()
	_build_lighting()
	_build_camera()
	_build_overlay()
	_build_ui()
	_apply_effect(0)
	print("[EffectDemo] Ready — [ ] cycle effects, +/- intensity, Space auto-animate")
	print("[EffectDemo] WASD move, right-click + mouse to look, 1-6 jump to effect")

func _input(event: InputEvent) -> void:
	# ── Desktop mouse look (hold right button) ──
	if not _is_vr:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event
			if mb.button_index == MOUSE_BUTTON_RIGHT:
				_mouse_captured = mb.pressed
				if mb.pressed:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				else:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		if event is InputEventMouseMotion and _mouse_captured:
			var mm: InputEventMouseMotion = event
			_cam_yaw -= mm.relative.x * _mouse_sensitivity
			_cam_pitch -= mm.relative.y * _mouse_sensitivity
			_cam_pitch = clamp(_cam_pitch, -89.0, 89.0)
			if _camera:
				_camera.rotation_degrees = Vector3(_cam_pitch, _cam_yaw, 0.0)

	# ── Keyboard controls (work in both desktop and VR) ──
	if event is InputEventKey and event.pressed:
		var key: InputEventKey = event
		match key.keycode:
			KEY_BRACKETLEFT:
				_cycle_effect(-1)
			KEY_BRACKETRIGHT:
				_cycle_effect(1)
			KEY_EQUAL:  # +/= key
				_intensity = min(_intensity + 0.05, 1.0)
				_update_intensity()
			KEY_MINUS:  # - key
				_intensity = max(_intensity - 0.05, 0.0)
				_update_intensity()
			KEY_R:
				_intensity = 0.5
				_update_intensity()
			KEY_SPACE:
				_auto_animate = not _auto_animate
				_update_ui()
			KEY_1:
				_apply_effect(1)
			KEY_2:
				_apply_effect(2)
			KEY_3:
				_apply_effect(3)
			KEY_4:
				_apply_effect(4)
			KEY_5:
				_apply_effect(5)
			KEY_6:
				_apply_effect(6)
			KEY_0:
				_apply_effect(0)
			KEY_ESCAPE:
				get_tree().quit()


func _process(delta: float) -> void:
	# Desktop camera movement (skip in VR — headset handles this)
	if not _is_vr:
		_process_camera_movement(delta)

	# Auto-animate intensity
	if _auto_animate:
		_animate_time += delta
		_intensity = (sin(_animate_time * 0.8) * 0.5 + 0.5)
		_update_intensity()

func _process_camera_movement(delta: float) -> void:
	if not _camera:
		return

	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		dir.z += 1.0
	if Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_Q):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_E):
		dir.y += 1.0

	if dir.length_squared() > 0.0:
		dir = dir.normalized()
		var forward: Vector3 = -_camera.global_transform.basis.z
		var right: Vector3 = _camera.global_transform.basis.x
		var up: Vector3 = Vector3.UP
		var move: Vector3 = (forward * dir.z * -1.0 + right * dir.x + up * dir.y) * _move_speed * delta
		_camera.global_position += move

# ═══════════════════════════════════════════════════════════════════════════════
# EFFECT MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

func _cycle_effect(direction: int) -> void:
	var new_idx: int = (_current_effect + direction) % EFFECTS.size()
	if new_idx < 0:
		new_idx += EFFECTS.size()
	_apply_effect(new_idx)

func _apply_effect(idx: int) -> void:
	_current_effect = clampi(idx, 0, EFFECTS.size() - 1)
	var effect: Dictionary = EFFECTS[_current_effect]

	if effect["shader_path"] == "":
		# No effect — hide overlay
		if _color_rect:
			_color_rect.visible = false
		_shader_mat = null
	else:
		# Load shader
		var shader: Shader = load(effect["shader_path"])
		if not shader:
			push_warning("[EffectDemo] Could not load shader: %s" % effect["shader_path"])
			_color_rect.visible = false
			_shader_mat = null
			_update_ui()
			return

		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = shader
		_shader_mat.set_shader_parameter("intensity", _intensity)

		if _color_rect:
			_color_rect.material = _shader_mat
			_color_rect.visible = true

	_update_ui()
	print("[EffectDemo] Effect: %s (intensity=%.2f)" % [effect["name"], _intensity])

func _update_intensity() -> void:
	if _shader_mat:
		_shader_mat.set_shader_parameter("intensity", _intensity)
	_update_ui()

# ═══════════════════════════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# HUD on a separate CanvasLayer above the effect overlay
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	hud_layer.layer = 110
	add_child(hud_layer)

	# Effect name label (top center)
	_label = Label.new()
	_label.name = "EffectLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.anchors_preset = Control.PRESET_TOP_WIDE
	_label.offset_top = 20
	_label.offset_bottom = 80
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	hud_layer.add_child(_label)

	# Description label (below name)
	_desc_label = Label.new()
	_desc_label.name = "DescLabel"
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.anchors_preset = Control.PRESET_TOP_WIDE
	_desc_label.offset_top = 55
	_desc_label.offset_bottom = 100
	_desc_label.add_theme_font_size_override("font_size", 16)
	_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_desc_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_desc_label.add_theme_constant_override("shadow_offset_x", 1)
	_desc_label.add_theme_constant_override("shadow_offset_y", 1)
	hud_layer.add_child(_desc_label)

	# Controls label (bottom left)
	var controls := Label.new()
	controls.name = "ControlsLabel"
	controls.anchors_preset = Control.PRESET_BOTTOM_LEFT
	controls.offset_left = 20
	controls.offset_bottom = -20
	controls.offset_top = -160
	controls.offset_right = 500
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	controls.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	controls.add_theme_constant_override("shadow_offset_x", 1)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	if _is_vr:
		controls.text = "Eat mushrooms to preview effects!"
	else:
		controls.text = (
			"[ ]  Cycle effects\n" +
			"+/-  Intensity up/down\n" +
			"R  Reset intensity\n" +
			"Space  Auto-animate\n" +
			"1-6  Jump to effect\n" +
			"0  No effect\n" +
			"WASD  Move  |  QE  Up/Down\n" +
			"Right-click + Mouse  Look\n" +
			"Esc  Quit"
		)
	hud_layer.add_child(controls)

func _update_ui() -> void:
	if not _label:
		return
	var effect: Dictionary = EFFECTS[_current_effect]
	var anim_str: String = " [AUTO]" if _auto_animate else ""
	_label.text = "%s — Intensity: %.0f%%%s" % [
		effect["name"],
		_intensity * 100.0,
		anim_str
	]
	if _desc_label:
		_desc_label.text = effect["description"]

# ═══════════════════════════════════════════════════════════════════════════════
# POST-PROCESSING OVERLAY
# ═══════════════════════════════════════════════════════════════════════════════

func _build_overlay() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "EffectLayer"
	_canvas_layer.layer = 100

	_color_rect = ColorRect.new()
	_color_rect.name = "EffectRect"
	_color_rect.anchors_preset = Control.PRESET_FULL_RECT
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.visible = false

	_canvas_layer.add_child(_color_rect)
	add_child(_canvas_layer)

# ═══════════════════════════════════════════════════════════════════════════════
# SCENE CONTENT  (things to look at through the effects)
# ═══════════════════════════════════════════════════════════════════════════════

func _build_scene_content() -> void:
	# Floor
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.25, 0.25)
	floor_mat.roughness = 0.9
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)

	# Grid pattern on floor (for visual reference during effects)
	_add_grid_lines()

	# Colored spheres arranged in a circle
	var sphere_count: int = 8
	for i in range(sphere_count):
		var angle: float = TAU * float(i) / float(sphere_count)
		var radius: float = 6.0
		var sphere := MeshInstance3D.new()
		sphere.name = "Sphere_%d" % i
		var sm := SphereMesh.new()
		sm.radius = 0.6
		sm.height = 1.2
		sphere.mesh = sm
		sphere.position = Vector3(cos(angle) * radius, 0.8, sin(angle) * radius)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.from_hsv(float(i) / float(sphere_count), 0.8, 0.9)
		mat.metallic = 0.3
		mat.roughness = 0.4
		mat.emission_enabled = true
		mat.emission = Color.from_hsv(float(i) / float(sphere_count), 0.9, 1.0)
		mat.emission_energy_multiplier = 0.5
		sphere.material_override = mat
		add_child(sphere)

	# Central glowing torus (good for testing hue shift, edge detect, etc.)
	var torus := MeshInstance3D.new()
	torus.name = "CenterTorus"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.4
	tm.outer_radius = 1.0
	torus.mesh = tm
	torus.position = Vector3(0, 1.5, 0)
	var torus_mat := StandardMaterial3D.new()
	torus_mat.albedo_color = Color(0.9, 0.3, 0.6)
	torus_mat.metallic = 0.6
	torus_mat.roughness = 0.2
	torus_mat.emission_enabled = true
	torus_mat.emission = Color(1.0, 0.4, 0.7)
	torus_mat.emission_energy_multiplier = 1.5
	torus.material_override = torus_mat
	add_child(torus)

	# Rotating torus animation
	var tween := create_tween()
	tween.set_loops()
	tween.tween_method(
		func(a: float) -> void:
			torus.rotation = Vector3(a * 0.3, a, a * 0.5),
		0.0, TAU, 8.0
	)

	# Tall boxes (pillars) for depth testing
	for i in range(4):
		var box := MeshInstance3D.new()
		box.name = "Pillar_%d" % i
		var bm := BoxMesh.new()
		var h: float = 2.0 + float(i) * 1.5
		bm.size = Vector3(0.5, h, 0.5)
		box.mesh = bm
		var ax: float = TAU * float(i) / 4.0 + PI / 4.0
		box.position = Vector3(cos(ax) * 10.0, h * 0.5, sin(ax) * 10.0)
		var box_mat := StandardMaterial3D.new()
		box_mat.albedo_color = Color(0.5, 0.55, 0.6)
		box_mat.roughness = 0.7
		box.material_override = box_mat
		add_child(box)

	# Floating cubes at different heights (good for pixelate/edge testing)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(12):
		var cube := MeshInstance3D.new()
		cube.name = "FloatCube_%d" % i
		var cm := BoxMesh.new()
		var s: float = rng.randf_range(0.3, 0.8)
		cm.size = Vector3(s, s, s)
		cube.mesh = cm
		cube.position = Vector3(
			rng.randf_range(-12.0, 12.0),
			rng.randf_range(1.0, 5.0),
			rng.randf_range(-12.0, 12.0)
		)
		cube.rotation = Vector3(
			rng.randf() * TAU,
			rng.randf() * TAU,
			rng.randf() * TAU
		)
		var cube_mat := StandardMaterial3D.new()
		cube_mat.albedo_color = Color.from_hsv(rng.randf(), 0.5, 0.7)
		cube_mat.roughness = rng.randf_range(0.3, 0.8)
		cube.material_override = cube_mat
		add_child(cube)

func _add_grid_lines() -> void:
	# Create visible grid lines on the floor for spatial reference
	var line_count: int = 20
	var spacing: float = 2.0
	var half: float = float(line_count) * spacing * 0.5

	for i in range(line_count + 1):
		var offset: float = float(i) * spacing - half
		# X-axis lines
		var line_x := MeshInstance3D.new()
		line_x.name = "GridLineX_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(half * 2.0, 0.005, 0.02)
		line_x.mesh = bm
		line_x.position = Vector3(0, 0.002, offset)
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color(0.35, 0.35, 0.35)
		lmat.roughness = 1.0
		line_x.material_override = lmat
		add_child(line_x)

		# Z-axis lines
		var line_z := MeshInstance3D.new()
		line_z.name = "GridLineZ_%d" % i
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(0.02, 0.005, half * 2.0)
		line_z.mesh = bm2
		line_z.position = Vector3(offset, 0.002, 0)
		var lmat2 := StandardMaterial3D.new()
		lmat2.albedo_color = Color(0.35, 0.35, 0.35)
		lmat2.roughness = 1.0
		line_z.material_override = lmat2
		add_child(line_z)

func _build_lighting() -> void:
	# Environment with sky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.15, 0.15, 0.3)
	sky_mat.sky_horizon_color = Color(0.3, 0.2, 0.35)
	sky_mat.ground_bottom_color = Color(0.1, 0.1, 0.15)
	sky_mat.ground_horizon_color = Color(0.2, 0.15, 0.25)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)

	# Directional light (sun)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.2
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	# Fill light from opposite side
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color(0.6, 0.65, 0.8)
	fill.light_energy = 0.4
	fill.rotation_degrees = Vector3(-30, -150, 0)
	fill.shadow_enabled = false
	add_child(fill)

	# Point light near center for warm glow
	var point := OmniLight3D.new()
	point.name = "CenterGlow"
	point.light_color = Color(1.0, 0.7, 0.4)
	point.light_energy = 2.0
	point.omni_range = 8.0
	point.position = Vector3(0, 3, 0)
	add_child(point)

func _build_camera() -> void:
	# Check if VR/XR is already active — if so, skip desktop camera
	var xr_origin: Node = get_tree().get_first_node_in_group("player")
	if xr_origin != null:
		_is_vr = true
		print("[EffectDemo] VR mode detected — use controller buttons to cycle effects")
		return

	var scene_root: Node = get_tree().current_scene
	if scene_root and scene_root.find_child("XROrigin3D", true, false):
		_is_vr = true
		print("[EffectDemo] XROrigin3D found — VR mode, no desktop camera")
		return

	# Desktop fallback camera
	_camera = Camera3D.new()
	_camera.name = "DemoCamera"
	_camera.position = Vector3(0, 4, 12)
	_camera.rotation_degrees = Vector3(-15, 0, 0)
	_cam_pitch = -15.0
	_cam_yaw = 0.0
	_camera.fov = 65.0
	_camera.current = true
	add_child(_camera)
	print("[EffectDemo] Desktop camera active")
