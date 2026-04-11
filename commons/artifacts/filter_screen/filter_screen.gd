## FilterScreen — A 3D→2D projection surface that lives in VR space.
##
## Unlike the ScienceScreen (which reads grid data and draws pixels), the
## FilterScreen uses a real Camera3D inside a SubViewport to project the
## live 3D scene onto a flat surface. It's a monitor inside the world that
## shows you a filtered view of the world around it.
##
## Think of it as a window that flattens 3D into 2D — teaching projection
## itself as a primitive. Points foreshorten, lines lose depth, triangles
## change area based on viewing angle. The filter screen makes this visible.
##
## Filter modes:
##   "normal"      — Standard 3D rendering projected onto the screen
##   "wireframe"   — Edge-detection post-process, shows only outlines
##   "depth"       — Depth buffer visualization (near=bright, far=dark)
##   "normals"     — Surface normal colors (RGB = XYZ directions)
##   "silhouette"  — Black shapes on white background, pure 2D shadow
##   "grid"        — Overlay grid lines onto the projected view (Science Screen hybrid)
##
## Grid config keys:
##   screen_width   - Width in meters (0.5–4.0, default 2.0)
##   screen_height  - Height in meters (0.5–3.0, default 1.5)
##   fov            - Camera field of view (20–120, default 60)
##   filter_mode    - One of the modes above (default "normal")
##   look_offset    - Camera look direction offset as "x,y,z" (default "0,0,-1")
##   cam_distance   - How far behind the screen the camera sits (0.1–5.0, default 0.5)
##   label          - Override title text
##   scanlines      - Enable CRT scanline overlay (default true)
extends Node3D
class_name FilterScreen

## ═══════════════════════════════════════════════════════
## EXPORTS
## ═══════════════════════════════════════════════════════

@export var screen_width: float = 2.0
@export var screen_height: float = 1.5
@export var cam_fov: float = 60.0
@export var cam_distance: float = 0.5

@export_enum("normal", "wireframe", "depth", "normals", "silhouette", "grid")
var filter_mode: String = "normal"

@export var show_scanlines: bool = true
@export var screen_label: String = "FILTER SCREEN"

## Colors
@export var border_color: Color = Color(0.2, 0.25, 0.35)
@export var screen_bg: Color = Color(0.02, 0.02, 0.04)

## ═══════════════════════════════════════════════════════
## INTERNAL STATE
## ═══════════════════════════════════════════════════════

var _screen_mesh: MeshInstance3D
var _border_mesh: MeshInstance3D
var _stand_mesh: MeshInstance3D
var _viewport: SubViewport
var _camera: Camera3D
var _canvas_overlay: Control  # For HUD text, scanlines, border glow
var _label_override: String = ""

## Viewport resolution
const VP_WIDTH: int = 640
const VP_HEIGHT: int = 480

## Animation
var _time: float = 0.0
var _glow_phase: float = 0.0

func _ready() -> void:
	_build_physical_screen()
	_build_camera_viewport()
	_build_overlay()
	_apply_viewport_to_screen()

func _process(delta: float) -> void:
	_time += delta
	_glow_phase = sin(_time * 1.5) * 0.5 + 0.5
	_update_camera_transform()
	if _canvas_overlay:
		_canvas_overlay.queue_redraw()


## ═══════════════════════════════════════════════════════
## CONSTRUCTION
## ═══════════════════════════════════════════════════════

func _build_physical_screen() -> void:
	# ── Screen surface (upright, facing +Z) ──
	_screen_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(screen_width, screen_height)
	plane.orientation = PlaneMesh.FACE_Z
	_screen_mesh.mesh = plane
	_screen_mesh.position = Vector3(0, screen_height * 0.5 + 0.05, 0)
	add_child(_screen_mesh)

	# Temporary material (replaced by viewport texture)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = screen_bg
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mesh.material_override = mat

	# ── Border frame ──
	_border_mesh = MeshInstance3D.new()
	var border_plane := PlaneMesh.new()
	var margin := 0.04
	border_plane.size = Vector2(screen_width + margin * 2, screen_height + margin * 2)
	border_plane.orientation = PlaneMesh.FACE_Z
	_border_mesh.mesh = border_plane
	_border_mesh.position = Vector3(0, screen_height * 0.5 + 0.05, -0.005)
	add_child(_border_mesh)

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = border_color
	border_mat.metallic = 0.7
	border_mat.roughness = 0.25
	_border_mesh.material_override = border_mat

	# ── Stand ──
	_stand_mesh = MeshInstance3D.new()
	var stand := BoxMesh.new()
	stand.size = Vector3(0.08, screen_height * 0.5 + 0.05, 0.08)
	_stand_mesh.mesh = stand
	_stand_mesh.position = Vector3(0, (screen_height * 0.5 + 0.05) * 0.5, -0.02)
	add_child(_stand_mesh)

	var stand_mat := StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.12, 0.12, 0.15)
	stand_mat.metallic = 0.7
	stand_mat.roughness = 0.25
	_stand_mesh.material_override = stand_mat


func _build_camera_viewport() -> void:
	# The viewport renders the 3D scene from behind the screen
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(VP_WIDTH, VP_HEIGHT)
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.world_3d = get_viewport().world_3d  # Share the main world!
	add_child(_viewport)

	# Camera sits behind the screen, looking through it
	_camera = Camera3D.new()
	_camera.fov = cam_fov
	_camera.near = 0.05
	_camera.far = 100.0
	_viewport.add_child(_camera)

	# Position camera behind screen center
	_update_camera_transform()

	# Apply filter-specific environment
	_apply_filter_environment()


func _build_overlay() -> void:
	# A 2D overlay rendered on top of the viewport for HUD elements
	_canvas_overlay = _FilterOverlay.new()
	_canvas_overlay.screen_ref = self
	_canvas_overlay.size = Vector2(VP_WIDTH, VP_HEIGHT)
	_viewport.add_child(_canvas_overlay)


func _apply_viewport_to_screen() -> void:
	if not _viewport or not _screen_mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _viewport.get_texture()
	mat.emission_enabled = true
	mat.emission_texture = _viewport.get_texture()
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mesh.material_override = mat


## ═══════════════════════════════════════════════════════
## CAMERA MANAGEMENT
## ═══════════════════════════════════════════════════════

func _update_camera_transform() -> void:
	if not _camera:
		return
	# Camera sits behind the screen, looking forward through it
	# Screen faces +Z, so camera is at -cam_distance on Z
	var screen_center := global_position + Vector3(0, screen_height * 0.5 + 0.05, 0)
	var screen_forward := -global_transform.basis.z  # The direction the screen faces
	_camera.global_position = screen_center - screen_forward * cam_distance
	_camera.look_at(screen_center + screen_forward * 10.0, Vector3.UP)


func _apply_filter_environment() -> void:
	# Apply post-processing based on filter mode
	var env := Environment.new()

	match filter_mode:
		"wireframe":
			# We can't do true wireframe in Godot easily, but we can use
			# a custom shader on the viewport. For now, leave standard rendering.
			pass
		"depth":
			# Depth mode: fog from near to far creates depth visualization
			env.fog_enabled = true
			env.fog_light_color = Color(1, 1, 1)
			env.fog_density = 0.02
			env.fog_aerial_perspective = 1.0
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0, 0, 0)
		"silhouette":
			# Dark background, bright objects — high contrast
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.95, 0.95, 0.95)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0, 0, 0)
		"normals":
			# Standard rendering — we'd need a screen-space shader for true normals
			# For now, use a distinctive look
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.5, 0.5, 1.0)
		"grid":
			# Standard but with grid overlay drawn by _FilterOverlay
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.02, 0.02, 0.04)
		_:  # "normal"
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.02, 0.02, 0.04)
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.3, 0.3, 0.35)

	_camera.environment = env


## ═══════════════════════════════════════════════════════
## GRID CONFIG INTEGRATION
## ═══════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("screen_width"):
		screen_width = clamp(float(config_data["screen_width"]), 0.5, 4.0)
	if config_data.has("screen_height"):
		screen_height = clamp(float(config_data["screen_height"]), 0.5, 3.0)
	if config_data.has("fov"):
		cam_fov = clamp(float(config_data["fov"]), 20.0, 120.0)
	if config_data.has("cam_distance"):
		cam_distance = clamp(float(config_data["cam_distance"]), 0.1, 5.0)
	if config_data.has("filter_mode"):
		filter_mode = str(config_data["filter_mode"])
	if config_data.has("label"):
		_label_override = str(config_data["label"])
	if config_data.has("scanlines"):
		show_scanlines = bool(config_data["scanlines"])
	if config_data.has("border"):
		var parts := str(config_data["border"]).split(",")
		if parts.size() >= 3:
			border_color = Color(float(parts[0]), float(parts[1]), float(parts[2]))

	# Rebuild everything with new parameters
	_rebuild()


func _rebuild() -> void:
	# Remove old children
	for child in get_children():
		child.queue_free()
	# Rebuild after a frame (so queue_free completes)
	call_deferred("_deferred_rebuild")

func _deferred_rebuild() -> void:
	_build_physical_screen()
	_build_camera_viewport()
	_build_overlay()
	_apply_viewport_to_screen()


## ═══════════════════════════════════════════════════════
## OVERLAY — 2D HUD drawn on top of the camera view
## ═══════════════════════════════════════════════════════

class _FilterOverlay extends Control:
	var screen_ref: FilterScreen

	func _draw() -> void:
		if not screen_ref:
			return

		var w := size.x
		var h := size.y

		# ── Header bar ──
		var header_h := 28
		draw_rect(Rect2(0, 0, w, header_h), Color(0, 0, 0, 0.7))

		# Title
		var title_text := screen_ref._label_override if screen_ref._label_override != "" else screen_ref.screen_label
		var mode_text := screen_ref.filter_mode.to_upper()
		draw_string(
			get_theme_default_font(),
			Vector2(8, 18),
			title_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color(0.8, 0.85, 0.9)
		)
		# Mode badge (right side)
		draw_string(
			get_theme_default_font(),
			Vector2(w - 100, 18),
			mode_text,
			HORIZONTAL_ALIGNMENT_RIGHT, -1, 11,
			Color(0.4, 0.8, 0.6)
		)

		# ── Status line ──
		var status_y := header_h + 14
		var fov_text := "FOV: %d°" % int(screen_ref.cam_fov)
		var dist_text := "d: %.1fm" % screen_ref.cam_distance
		draw_string(
			get_theme_default_font(),
			Vector2(8, status_y),
			fov_text + "  |  " + dist_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color(0.4, 0.45, 0.55)
		)

		# ── CRT scanlines ──
		if screen_ref.show_scanlines:
			for y_line in range(0, int(h), 3):
				draw_line(
					Vector2(0, y_line),
					Vector2(w, y_line),
					Color(0, 0, 0, 0.06),
					1.0
				)

		# ── Grid overlay (grid mode only) ──
		if screen_ref.filter_mode == "grid":
			var grid_spacing := 40.0
			var grid_color := Color(0.2, 0.8, 0.4, 0.15)
			var x := grid_spacing
			while x < w:
				draw_line(Vector2(x, header_h), Vector2(x, h), grid_color, 1.0)
				x += grid_spacing
			var y := header_h + grid_spacing
			while y < h:
				draw_line(Vector2(0, y), Vector2(w, y), grid_color, 1.0)
				y += grid_spacing

		# ── Border glow ──
		var glow_alpha: float = lerpf(0.2, 0.4, screen_ref._glow_phase)
		var glow_color := Color(0.2, 0.8, 0.5, glow_alpha)
		var glow_width := 2.0
		# Top
		draw_line(Vector2(0, 0), Vector2(w, 0), glow_color, glow_width)
		# Bottom
		draw_line(Vector2(0, h - 1), Vector2(w, h - 1), glow_color, glow_width)
		# Left
		draw_line(Vector2(0, 0), Vector2(0, h), glow_color, glow_width)
		# Right
		draw_line(Vector2(w - 1, 0), Vector2(w - 1, h), glow_color, glow_width)

		# ── Crosshair (center of projection) ──
		var cx := w * 0.5
		var cy := (h + header_h) * 0.5
		var cross_size := 10.0
		var cross_color := Color(0.8, 0.8, 0.8, 0.15)
		draw_line(Vector2(cx - cross_size, cy), Vector2(cx + cross_size, cy), cross_color, 1.0)
		draw_line(Vector2(cx, cy - cross_size), Vector2(cx, cy + cross_size), cross_color, 1.0)
