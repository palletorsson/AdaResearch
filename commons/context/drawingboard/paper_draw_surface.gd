extends MeshInstance3D

@export var texture_size: Vector2i = Vector2i(1440, 1000)  # Resolution of the drawing texture
@export var default_brush_size: int = 10  # Default size of the brush stroke
@export var default_brush_color: Color = Color(0, 0, 0, 1)  # Default brush color
@export var default_snap_grid_size: int = 16  # Default snap grid size
@export var random_dot_colors: Array = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]  # Colors for the random dots

var drawing_texture: Image
var drawing_texture_data: ImageTexture
var last_uv_position: Vector2 = Vector2(-1, -1)  # Keeps track of the last UV position

# Active pen settings
var active_pen_properties = {
	"brush_size": 10,
	"brush_color": Color(0, 0, 0, 1),
	"snap_size": 16,
	"random_dots_active": false
}



@onready var debug_label: Label3D = $"../Label3D"

func _ready():
	# Create a blank drawing texture
	drawing_texture = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	drawing_texture.fill(Color(1, 1, 1, 0.2))  # White background
	drawing_texture_data = ImageTexture.create_from_image(drawing_texture)
	
	update_material(drawing_texture_data)
	debug_label.text = "Drawing initialized."

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
	drawing_texture.fill(Color(1, 1, 1, 0.2))  # White background
	drawing_texture_data = ImageTexture.create_from_image(drawing_texture)
	update_material(drawing_texture_data)
	debug_label.text = "Drawing reset."

# Snap a UV position to the nearest grid point
func snap_to_grid(uv_position: Vector2) -> Vector2:
	var grid_size = Vector2(1.0 / active_pen_properties["snap_grid_size"], 1.0 / active_pen_properties["snap_grid_size"])
	var snapped_x = round(uv_position.x / grid_size.x) * grid_size.x
	var snapped_y = round(uv_position.y / grid_size.y) * grid_size.y
	return Vector2(snapped_x, snapped_y)

# Draw a single point
func draw_point(uv_position: Vector2, color: Color):
	# Snap the UV position to the grid
	uv_position = snap_to_grid(uv_position)

	# Convert UV to pixel coordinates
	var x = int(uv_position.x * texture_size.x)
	var y = int(uv_position.y * texture_size.y)

	# Draw a circle for the brush stroke
	for offset_x in range(-active_pen_properties["brush_size"], active_pen_properties["brush_size"] + 1):
		for offset_y in range(-active_pen_properties["brush_size"], active_pen_properties["brush_size"] + 1):
			if offset_x * offset_x + offset_y * offset_y <= active_pen_properties["brush_size"] ** 2:
				var px = x + offset_x
				var py = y + offset_y
				if px >= 0 and px < texture_size.x and py >= 0 and py < texture_size.y:
					drawing_texture.set_pixel(px, py, color)

	# Update the texture
	drawing_texture_data.update(drawing_texture)

# Function to update the material's albedo texture
func update_material(tex: ImageTexture):
	if self.material_override is ShaderMaterial:
		var shader_material = self.material_override as ShaderMaterial
		shader_material.set_shader_parameter("texture_albedo", tex)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_texture = tex
		self.material_override = material

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



func draw_line(from_uv: Vector2, to_uv: Vector2, color: Color):
	# Snap the UV positions to the grid
	from_uv = snap_to_grid(from_uv)
	to_uv = snap_to_grid(to_uv)

	if from_uv == Vector2(-1, -1):  # No previous point to connect from
		draw_point(to_uv, color)
		return

	# Interpolate between the points and draw along the line
	var from_x = int(from_uv.x * texture_size.x)
	var from_y = int(from_uv.y * texture_size.y)
	var to_x = int(to_uv.x * texture_size.x)
	var to_y = int(to_uv.y * texture_size.y)

	# Use Bresenham's line algorithm to draw a line
	var delta_x = abs(to_x - from_x)
	var delta_y = abs(to_y - from_y)
	var sx = -1 if from_x > to_x else 1
	var sy = -1 if from_y > to_y else 1
	var err = delta_x - delta_y

	while true:
		# Draw a point at the current position
		for offset_x in range(-active_pen_properties["brush_size"], active_pen_properties["brush_size"] + 1):
			for offset_y in range(-active_pen_properties["brush_size"], active_pen_properties["brush_size"] + 1):
				if offset_x * offset_x + offset_y * offset_y <= active_pen_properties["brush_size"] ** 2:
					var px = from_x + offset_x
					var py = from_y + offset_y
					if px >= 0 and px < texture_size.x and py >= 0 and py < texture_size.y:
						drawing_texture.set_pixel(px, py, color)

		# Check if we have reached the end of the line
		if from_x == to_x and from_y == to_y:
			break

		# Calculate the next point
		var e2 = 2 * err
		if e2 > -delta_y:
			err -= delta_y
			from_x += sx
		if e2 < delta_x:
			err += delta_x
			from_y += sy

	# Update the texture
	drawing_texture_data.update(drawing_texture)


func _on_scribel_pen_pen_grabbed(pickable: Variant, by: Variant) -> void:

	var pentip_ray_cast = pickable.get_node("Pen/PentipRayCast")  # Adjust the path as needed
	if pentip_ray_cast:
		# Get the current snap_grid_size
		active_pen_properties["snap_grid_size"] = pentip_ray_cast.snap_grid_size
		debug_label.text = "Current Resolution: " + str(active_pen_properties["snap_grid_size"])
	else:
		debug_label.text = "PentipRayCast node not found!"
