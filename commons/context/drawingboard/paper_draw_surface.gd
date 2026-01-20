extends MeshInstance3D

@export var texture_size: Vector2i = Vector2i(1440, 1000)  # Resolution of the drawing texture
@export var default_brush_size: int = 12  # Default size of the brush stroke
@export var default_brush_color: Color = Color(0, 0, 0, 1)  # Default brush color
@export var default_snap_grid_size: int = 8  # Default snap grid size
@export var random_dot_colors: Array = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]  # Colors for the random dots

# --- WET PAINT EFFECT (GPU) ---
@export var wet_paint: bool = false:
	set(value):
		wet_paint = value
		_update_paint_params()
		
@export var flow_speed: float = 0.0005:
	set(value):
		flow_speed = value
		_update_paint_params()

const WET_PAINT_SCENE = preload("res://commons/context/drawingboard/wet_paint_canvas.tscn")
var viewport: SubViewport
var brush_layer: Node2D
var simulation_rect: ColorRect

# Active pen settings
var active_pen_properties = {
	"brush_size": 10,
	"brush_color": Color(0, 0, 0, 1),
	"snap_size": 8,
	"random_dots_active": false
}

@onready var debug_label: Label3D = $"../Label3D"

func _ready():
	_setup_gpu_painting()
	
	# Initialize active properties from exports
	active_pen_properties["brush_size"] = default_brush_size
	active_pen_properties["brush_color"] = default_brush_color
	active_pen_properties["snap_size"] = default_snap_grid_size
	
	if debug_label:
		debug_label.text = "GPU Drawing initialized."

func _setup_gpu_painting():
	# Instance the viewport scene
	var canvas = WET_PAINT_SCENE.instantiate()
	canvas.name = "WetPaintCanvas"
	add_child(canvas)
	
	viewport = canvas
	brush_layer = canvas.get_node("BrushLayer")
	var sim_pass = canvas.get_node("SimulationPass")
	simulation_rect = sim_pass.get_node("SimulationRect")
	
	# Resize viewport to match texture size
	viewport.size = texture_size
	
	# Explicitly resize the ColorRect because it's inside a Node2D (BackBufferCopy)
	# and anchors won't work automatically to fill the Viewport
	simulation_rect.size = Vector2(texture_size)
	
	# Get the viewport texture
	var vp_tex = viewport.get_texture()
	
	# Assign to material
	var material = StandardMaterial3D.new()
	material.albedo_texture = vp_tex
	# Ensure material is local and unique
	self.material_override = material
	
	_update_paint_params()
	
	# Initial clear to white
	reset_canvas()

func _update_paint_params():
	if simulation_rect and simulation_rect.material:
		# If wet paint is off, set flow to 0
		var speed = flow_speed if wet_paint else 0.0
		simulation_rect.material.set_shader_parameter("flow_speed", speed)

# Draw random dots around the pen tip
func draw_random_dots(uv_position: Vector2):
	for i in range(4):  # Draw four random dots
		# Generate random offset
		var random_offset = Vector2(randf_range(-0.02, 0.02), randf_range(-0.02, 0.02))
		var dot_position = uv_position + random_offset

		# Pick a random color
		var random_color = random_dot_colors[randi() % random_dot_colors.size()]

		# Draw the dot
		draw_point(dot_position, random_color)

# Function to reset the canvas
func reset_canvas():
	# To reset a feedback loop viewport, we need to clear it.
	# The easiest way for a "Fade/Clear" is to draw a giant rect on the BrushLayer
	if brush_layer:
		brush_layer.add_splat(Vector2(texture_size.x/2, texture_size.y/2), max(texture_size.x, texture_size.y), Color(1, 1, 1, 1))
	
	if debug_label:
		debug_label.text = "Drawing reset."

# Snap a UV position to the nearest grid point
func snap_to_grid(uv_position: Vector2, snap_size: int = -1) -> Vector2:
	var s_size = snap_size if snap_size > 0 else active_pen_properties["snap_size"]
	
	var grid_size = Vector2(1.0 / s_size, 1.0 / s_size)
	var snapped_x = round(uv_position.x / grid_size.x) * grid_size.x
	var snapped_y = round(uv_position.y / grid_size.y) * grid_size.y
	return Vector2(snapped_x, snapped_y)

# Draw a single point
# Draw a single point
func draw_point(uv_position: Vector2, color: Color, size: int = -1, snap_size: int = -1):
	var b_size = size if size > 0 else active_pen_properties["brush_size"]
	
	# Snap the UV position to the grid
	uv_position = snap_to_grid(uv_position, snap_size)
	
	# Convert UV to pixel coordinates
	var x = uv_position.x * texture_size.x
	var y = uv_position.y * texture_size.y
	
	# Delegate to BrushLayer
	if brush_layer:
		brush_layer.add_splat(Vector2(x, y), b_size, color)


# Function to draw while tracking the pen tip position
func draw_with_pen(uv_position: Vector2):
	# Draw the main pen stroke
	draw_point(uv_position, active_pen_properties["brush_color"])
	# Draw random dots around the pen tip
	draw_random_dots(uv_position)


# Update the pen properties dynamically
func update_pen(brush_size: int, brush_color: Color, snap_size: int, random_dots_active: bool):
	active_pen_properties["brush_size"] = brush_size
	active_pen_properties["brush_color"] = brush_color
	active_pen_properties["snap_size"] = snap_size
	active_pen_properties["random_dots_active"] = random_dots_active



func draw_line(from_uv: Vector2, to_uv: Vector2, color: Color, size: int = -1, snap_size: int = -1):
	var b_size = size if size > 0 else active_pen_properties["brush_size"]

	# Snap the UV positions to the grid
	from_uv = snap_to_grid(from_uv, snap_size)
	to_uv = snap_to_grid(to_uv, snap_size)

	if from_uv == Vector2(-1, -1):  # No previous point to connect from
		draw_point(to_uv, color, size, snap_size)
		return

	# Interpolate between the points and draw along the line
	var from_pos = from_uv * Vector2(texture_size)
	var to_pos = to_uv * Vector2(texture_size)
	
	var steps = int(from_pos.distance_to(to_pos) / (b_size * 0.5))
	steps = max(1, steps)
	
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var p = from_pos.lerp(to_pos, t)
		if brush_layer:
			brush_layer.add_splat(p, b_size, color)


func _on_scribel_pen_pen_grabbed(pickable: Variant, by: Variant) -> void:

	var pentip_ray_cast = pickable.get_node("Pen/PentipRayCast")  # Adjust the path as needed
	if pentip_ray_cast:
		# Get the current snap_grid_size
		active_pen_properties["snap_size"] = pentip_ray_cast.snap_grid_size
		if debug_label:
			debug_label.text = "Current Resolution: " + str(active_pen_properties["snap_size"])
	else:
		if debug_label:
			debug_label.text = "PentipRayCast node not found!"

# Helper to convert world position to UV
func get_uv_from_world_pos(world_pos: Vector3) -> Vector2:
	# Get the canvas bounds from the parent DrawingCanvas transform
	# The canvas transform contains scale which determines the world-space size
	var parent = get_parent()
	if parent:
		var canvas_transform = parent.global_transform
		# The canvas scale in X and Y determines the canvas size
		# SharedCanvas has transform with 5.4 scale, so it covers -2.7 to +2.7
		var scale_x = canvas_transform.basis.x.length()
		var scale_y = canvas_transform.basis.y.length()
		var canvas_center = canvas_transform.origin
		
		# Map world position to UV (0-1)
		# World X maps to UV X, World Y maps to UV Y
		var half_width = scale_x / 2.0
		var half_height = scale_y / 2.0
		
		var uv_x = (world_pos.x - canvas_center.x + half_width) / scale_x
		var uv_y = (world_pos.y - canvas_center.y + half_height) / scale_y
		
		return Vector2(uv_x, uv_y)
	
	# Fallback: use local transform
	var local_pos = global_transform.affine_inverse() * world_pos
	var mesh_size = Vector2(2.0, 2.0)
	if mesh and mesh is PlaneMesh:
		mesh_size = mesh.size
	var half_size = mesh_size / 2.0
	var uv_x = (local_pos.x + half_size.x) / mesh_size.x
	var uv_y = (local_pos.z + half_size.y) / mesh_size.y
	return Vector2(uv_x, uv_y)

# Draw at a specific world position
func draw_at_world_position(world_pos: Vector3, color: Color = Color.BLACK):
	var uv = get_uv_from_world_pos(world_pos)
	if uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0:
		draw_point(uv, color)

func _process(delta):
	# GPU simulation runs automatically in the shader/viewport
	pass
