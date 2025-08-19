extends Node2D

# Attractor types
enum AttractorType {
	LORENZ,
	CLIFFORD,
	DE_JONG,
	BEDHEAD,
	SVENSSON,
	IKEDA
}

# Current attractor
@export var attractor_type: AttractorType = AttractorType.LORENZ
@export var line_color: Color = Color(0.2, 0.6, 1.0, 0.8)
@export var point_color: Color = Color(1.0, 0.9, 0.2, 1.0)
@export var background_color: Color = Color(0.05, 0.05, 0.1, 1.0)
@export var point_size: float = 1.0
@export var line_width: float = 1.0
@export var max_points: int = 10000
@export var iterations_per_frame: int = 10
@export var scale_factor: float = 100.0
@export var offset: Vector2 = Vector2(0, 0)

# Current position and parameters
var current_position: Vector3 = Vector3.ZERO
var current_point_2d: Vector2 = Vector2.ZERO
var trail_points: Array[Vector2] = []

# Parameters for attractors
var lorenz_params: Dictionary = {
	"sigma": 10.0,
	"rho": 28.0,
	"beta": 8.0 / 3.0,
	"dt": 0.005
}

var clifford_params: Dictionary = {
	"a": -1.4,
	"b": 1.6,
	"c": 1.0,
	"d": 0.7
}

var de_jong_params: Dictionary = {
	"a": -2.0,
	"b": -2.0,
	"c": -1.2,
	"d": 2.0
}

var bedhead_params: Dictionary = {
	"a": -0.81,
	"b": -0.92
}

var svensson_params: Dictionary = {
	"a": 1.5,
	"b": -1.8,
	"c": 1.6,
	"d": 0.9
}

var ikeda_params: Dictionary = {
	"u": 0.918
}

func _ready():
	randomize()
	
	# Initialize the position with a small random offset
	_reset_position()
	
	# Create initial points
	for i in range(max_points):
		if attractor_type == AttractorType.LORENZ:
			# For Lorenz we use the 3D calculation
			current_position = _lorenz_attractor(current_position)
			# Project 3D to 2D (simple side view)
			current_point_2d = Vector2(current_position.x, current_position.z) * scale_factor
		else:
			# Update using the current 2D attractor
			current_point_2d = _calculate_next_point(current_point_2d)
		
		trail_points.append(current_point_2d + get_viewport_rect().size / 2 + offset)

func _process(_delta):
	# Calculate new points
	for i in range(iterations_per_frame):
		if attractor_type == AttractorType.LORENZ:
			# For Lorenz we use the 3D calculation
			current_position = _lorenz_attractor(current_position)
			# Project 3D to 2D (simple side view)
			current_point_2d = Vector2(current_position.x, current_position.z) * scale_factor
		else:
			# Update using the current 2D attractor
			current_point_2d = _calculate_next_point(current_point_2d)
		
		trail_points.append(current_point_2d + get_viewport_rect().size / 2 + offset)
		
		# Keep array at max size
		if trail_points.size() > max_points:
			trail_points.remove_at(0)
	
	# Force redraw
	queue_redraw()

func _draw():
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), background_color)
	
	# Draw grid lines
	var grid_color = Color(1, 1, 1, 0.1)
	var center = get_viewport_rect().size / 2
	draw_line(Vector2(0, center.y), Vector2(get_viewport_rect().size.x, center.y), grid_color)
	draw_line(Vector2(center.x, 0), Vector2(center.x, get_viewport_rect().size.y), grid_color)
	
	# Draw the attractor points and lines
	if trail_points.size() >= 2:
		# Draw lines connecting points
		for i in range(1, trail_points.size()):
			var color = line_color
			color.a = float(i) / trail_points.size() * line_color.a  # Fade out older lines
			draw_line(trail_points[i-1], trail_points[i], color, line_width)
		
		# Draw current point
		draw_circle(trail_points[trail_points.size() - 1], point_size, point_color)
	
	# Draw attractor name
	var font_color = Color(1, 1, 1, 0.8)
	var attractor_name = _get_attractor_name()
	draw_string(
		ThemeDB.fallback_font, 
		Vector2(20, 30), 
		attractor_name, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		16, 
		font_color
	)

func _reset_position():
	match attractor_type:
		AttractorType.LORENZ:
			# For Lorenz we need a 3D position
			current_position = Vector3(
				randf_range(-0.1, 0.1),
				randf_range(-0.1, 0.1),
				randf_range(-0.1, 0.1)
			)
			current_point_2d = Vector2(current_position.x, current_position.z) * scale_factor
		_:
			# For 2D attractors, initialize with a small random position
			current_point_2d = Vector2(
				randf_range(-0.1, 0.1),
				randf_range(-0.1, 0.1)
			)
	
	# Clear trail
	trail_points.clear()

func _calculate_next_point(point: Vector2) -> Vector2:
	var next_point = Vector2.ZERO
	
	match attractor_type:
		AttractorType.CLIFFORD:
			next_point = _clifford_attractor(point)
		AttractorType.DE_JONG:
			next_point = _de_jong_attractor(point)
		AttractorType.BEDHEAD:
			next_point = _bedhead_attractor(point)
		AttractorType.SVENSSON:
			next_point = _svensson_attractor(point)
		AttractorType.IKEDA:
			next_point = _ikeda_attractor(point)
		_:
			# Default to Clifford if unknown type
			next_point = _clifford_attractor(point)
	
	return next_point * scale_factor

func _lorenz_attractor(pos: Vector3) -> Vector3:
	var params = lorenz_params
	var dt = params.dt
	
	var dx = params.sigma * (pos.y - pos.x)
	var dy = pos.x * (params.rho - pos.z) - pos.y
	var dz = pos.x * pos.y - params.beta * pos.z
	
	return Vector3(
		pos.x + dx * dt,
		pos.y + dy * dt,
		pos.z + dz * dt
	)

func _clifford_attractor(point: Vector2) -> Vector2:
	var params = clifford_params
	
	var nx = sin(params.a * point.y) + params.c * cos(params.a * point.x)
	var ny = sin(params.b * point.x) + params.d * cos(params.b * point.y)
	
	return Vector2(nx, ny)

func _de_jong_attractor(point: Vector2) -> Vector2:
	var params = de_jong_params
	
	var nx = sin(params.a * point.y) - cos(params.b * point.x)
	var ny = sin(params.c * point.x) - cos(params.d * point.y)
	
	return Vector2(nx, ny)

func _bedhead_attractor(point: Vector2) -> Vector2:
	var params = bedhead_params
	
	var nx = sin(point.x * point.y / params.b) * point.y + cos(params.a * point.x - point.y)
	var ny = point.x + sin(point.y) / params.b
	
	return Vector2(nx, ny) * 0.1  # Scale down to avoid explosion

func _svensson_attractor(point: Vector2) -> Vector2:
	var params = svensson_params
	
	var nx = params.d * sin(params.a * point.x) - sin(params.b * point.y)
	var ny = params.c * cos(params.a * point.x) + cos(params.b * point.y)
	
	return Vector2(nx, ny)

func _ikeda_attractor(point: Vector2) -> Vector2:
	var params = ikeda_params
	
	var t = 0.4 - 6.0 / (1.0 + point.x * point.x + point.y * point.y)
	var sin_t = sin(t)
	var cos_t = cos(t)
	
	var nx = 1.0 + params.u * (point.x * cos_t - point.y * sin_t)
	var ny = params.u * (point.x * sin_t + point.y * cos_t)
	
	return Vector2(nx, ny) * 0.2  # Scale down to avoid explosion

func _get_attractor_name() -> String:
	match attractor_type:
		AttractorType.LORENZ:
			return "Lorenz Attractor"
		AttractorType.CLIFFORD:
			return "Clifford Attractor"
		AttractorType.DE_JONG:
			return "De Jong Attractor"
		AttractorType.BEDHEAD:
			return "Bedhead Attractor"
		AttractorType.SVENSSON:
			return "Svensson Attractor"
		AttractorType.IKEDA:
			return "Ikeda Attractor"
		_:
			return "Unknown Attractor"

func _change_attractor(new_type: AttractorType):
	attractor_type = new_type
	_reset_position()

func _input(event):
	# Handle input to change attractor type
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_change_attractor(AttractorType.LORENZ)
			KEY_2:
				_change_attractor(AttractorType.CLIFFORD)
			KEY_3:
				_change_attractor(AttractorType.DE_JONG)
			KEY_4:
				_change_attractor(AttractorType.BEDHEAD)
			KEY_5:
				_change_attractor(AttractorType.SVENSSON)
			KEY_6:
				_change_attractor(AttractorType.IKEDA)
			KEY_SPACE:
				_reset_position()  # Reset with same attractor
