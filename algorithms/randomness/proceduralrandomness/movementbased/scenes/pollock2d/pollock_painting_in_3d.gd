extends Node3D

@export_group("Display")
@export var pixel_size: float = 0.0035
@export var frame_margin: float = 0.14
@export var frame_depth: float = 0.02
@export var frame_color: Color = Color(0.12, 0.09, 0.06, 1.0)
@export var backing_color: Color = Color(0.88, 0.85, 0.78, 1.0)
@export var place_on_floor: bool = true
@export var floor_height: float = 0.02

@export_group("Brush")
@export var simulate_brush_motion: bool = true
@export var brush_radius: float = 0.045
@export var brush_hover_height: float = 0.055

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var sub_viewport: SubViewport = $SubViewport

var _paint_2d: Node = null
var _brush_cursor: MeshInstance3D = null
var _brush_tween: Tween = null


func _ready() -> void:
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame

	_configure_floor_layout()
	sprite_3d.texture = sub_viewport.get_texture()
	sprite_3d.pixel_size = pixel_size
	_setup_sprite_material()
	_create_frame_panels()
	_connect_stroke_signal()
	_create_brush_cursor()


func _setup_sprite_material() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = sub_viewport.get_texture()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sprite_3d.material_override = material


func _configure_floor_layout() -> void:
	if not place_on_floor:
		return
	sprite_3d.rotation_degrees = Vector3(-90.0, 180.0, 0.0)
	sprite_3d.position = Vector3(0.0, floor_height, 0.0)


func _create_frame_panels() -> void:
	var content_size := Vector2(sub_viewport.size.x, sub_viewport.size.y) * pixel_size

	var backing := MeshInstance3D.new()
	backing.name = "BackingPanel"
	var backing_mesh := QuadMesh.new()
	backing_mesh.size = content_size + Vector2(frame_margin * 0.45, frame_margin * 0.45)
	backing.mesh = backing_mesh
	backing.transform = sprite_3d.transform
	backing.translate_object_local(Vector3(0.0, 0.0, -frame_depth - 0.001))
	backing.material_override = _panel_material(backing_color)
	add_child(backing)

	var frame := MeshInstance3D.new()
	frame.name = "FramePanel"
	var frame_mesh := QuadMesh.new()
	frame_mesh.size = content_size + Vector2(frame_margin, frame_margin)
	frame.mesh = frame_mesh
	frame.transform = sprite_3d.transform
	frame.translate_object_local(Vector3(0.0, 0.0, -frame_depth * 0.45))
	frame.material_override = _panel_material(frame_color)
	add_child(frame)


func _panel_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.metallic = 0.12
	return mat


func _connect_stroke_signal() -> void:
	if not simulate_brush_motion:
		return
	_paint_2d = sub_viewport.get_node_or_null("PollockPainting2D")
	if _paint_2d and _paint_2d.has_signal("stroke_path_generated"):
		_paint_2d.connect("stroke_path_generated", Callable(self, "_on_stroke_path_generated"))


func _create_brush_cursor() -> void:
	if not simulate_brush_motion:
		return

	_brush_cursor = MeshInstance3D.new()
	_brush_cursor.name = "BrushCursor"

	var mesh := SphereMesh.new()
	mesh.radius = brush_radius
	mesh.height = brush_radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_brush_cursor.mesh = mesh
	_brush_cursor.material_override = _brush_material(Color(0.2, 0.13, 0.07, 1.0))

	add_child(_brush_cursor)
	_brush_cursor.global_position = _canvas_pixel_to_world(
		Vector2(sub_viewport.size.x * 0.5, sub_viewport.size.y * 0.5),
		brush_hover_height
	)


func _brush_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.25
	mat.roughness = 0.45
	mat.emission_enabled = true
	mat.emission = color.lightened(0.2)
	mat.emission_energy_multiplier = 0.45
	return mat


func _on_stroke_path_generated(path: PackedVector2Array, stroke_color: Color, stroke_width: float, duration: float) -> void:
	if not simulate_brush_motion or _brush_cursor == null:
		return
	if path.size() < 2:
		return

	var brush_mat := _brush_cursor.material_override as StandardMaterial3D
	if brush_mat:
		brush_mat.albedo_color = stroke_color.darkened(0.2)
		brush_mat.emission = stroke_color
		brush_mat.emission_energy_multiplier = 0.7

	if _brush_tween and _brush_tween.is_running():
		_brush_tween.kill()

	var step_count: int = maxi(1, path.size() - 1)
	var step_duration: float = maxf(0.03, duration / float(step_count))
	_brush_tween = create_tween()
	_brush_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var hover: float = brush_hover_height + minf(stroke_width * 0.0015, 0.02)
	for point in path:
		var target_world := _canvas_pixel_to_world(point, hover)
		_brush_tween.tween_property(_brush_cursor, "global_position", target_world, step_duration)


func _canvas_pixel_to_world(pixel: Vector2, height_offset: float) -> Vector3:
	var width: float = float(sub_viewport.size.x)
	var height: float = float(sub_viewport.size.y)
	var half_w: float = width * 0.5
	var half_h: float = height * 0.5

	var local_x: float = (pixel.x - half_w) * pixel_size
	var local_y: float = (half_h - pixel.y) * pixel_size
	return sprite_3d.to_global(Vector3(local_x, local_y, height_offset))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
