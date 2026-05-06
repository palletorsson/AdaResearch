# MapInfoLabel.gd
# Shows "Loading..." during map load, then hides when done
# Attach to a Label3D under XRCamera3D
# Now with semi-transparent background for readability

extends Label3D

@export var loading_text: String = "Loading..."
@export var background_color: Color = Color(0.05, 0.05, 0.1, 0.75)  # Dark blue, semi-transparent
@export var background_padding: Vector2 = Vector2(0.02, 0.015)  # Padding around text

var is_loading: bool = true
var _background: MeshInstance3D
var _full_text_for_sizing: String = ""  # Store full text for background sizing

func _ready():
	text = loading_text
	modulate = Color(1, 1, 1, 0.9)
	visible = true

	# Create background panel
	_create_background()

	# Connect to GridSystem signals
	call_deferred("_connect_to_grid_system")

func _create_background():
	_background = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.5, 0.1)  # Will be resized based on text
	_background.mesh = quad

	# Semi-transparent dark material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = background_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_background.material_override = mat

	# Position slightly behind text
	_background.position.z = 0.001  # Behind text (text faces -Z)
	add_child(_background)

	# Initial size update
	call_deferred("_update_background_size")

func _update_background_size():
	if not _background:
		return

	# Use full text for sizing (for typewriter effect) or current text
	var sizing_text = _full_text_for_sizing if not _full_text_for_sizing.is_empty() else text

	# Get text bounds - use font metrics estimation
	# Label3D doesn't expose exact bounds, so estimate from text length and font size
	var char_width = pixel_size * font_size * 0.5  # Approximate character width
	var line_height = pixel_size * font_size * 1.2

	# Count lines (rough estimate based on autowrap)
	var max_width = width * pixel_size if width > 0 else 2.0
	var text_width = min(sizing_text.length() * char_width, max_width)
	var num_lines = max(1, ceil(sizing_text.length() * char_width / max_width))
	var text_height = num_lines * line_height

	# Apply padding
	var bg_width = text_width + background_padding.x * 2
	var bg_height = text_height + background_padding.y * 2

	# Update quad size
	var quad = _background.mesh as QuadMesh
	if quad:
		quad.size = Vector2(bg_width, bg_height)

	# Offset background to align with left-aligned text
	# Label3D horizontal_alignment 0 = left, text starts at origin
	_background.position.x = bg_width / 2.0 - background_padding.x
	_background.position.y = -bg_height / 2.0 + background_padding.y

func set_text_with_background(new_text: String):
	text = new_text
	call_deferred("_update_background_size")

func _connect_to_grid_system():
	var grid_system = _find_grid_system(get_tree().root)

	if grid_system:
		if grid_system.has_signal("map_generation_complete"):
			if not grid_system.map_generation_complete.is_connected(_on_map_loaded):
				grid_system.map_generation_complete.connect(_on_map_loaded)
				print("MapInfoLabel: Connected to GridSystem")
	else:
		# Retry after a delay
		await get_tree().create_timer(1.0).timeout
		_connect_to_grid_system()

func _find_grid_system(node: Node) -> Node:
	if node.get_script():
		var script_path = node.get_script().resource_path
		if "GridSystem" in script_path or "LabGridSystem" in script_path:
			return node
	
	for child in node.get_children():
		var result = _find_grid_system(child)
		if result:
			return result
	
	return null

func _on_map_loaded():
	is_loading = false
	visible = false
	if _background:
		_background.visible = false
	print("MapInfoLabel: Loading complete - hiding label")

# Called by SubtitleManager when showing subtitles
func show_subtitle_text(new_text: String):
	_full_text_for_sizing = new_text  # Store full text for background sizing
	visible = true
	if _background:
		_background.visible = true
	call_deferred("_update_background_size")

func hide_subtitle():
	text = ""
	_full_text_for_sizing = ""
	visible = false
	if _background:
		_background.visible = false

