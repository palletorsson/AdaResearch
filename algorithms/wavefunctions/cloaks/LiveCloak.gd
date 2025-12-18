@tool
extends Node3D

# LiveCloak.gd
# Generates a flowing cloak effect using CSGPolygon3D in Path mode.
# The Path3D points are animated using wave functions to simulate "live" fabric.

@export_group("Dimensions")
@export var height: float = 2.0
@export var radius_top: float = 0.4
@export var radius_bottom: float = 0.8
@export var segments: int = 20
@export var layers: int = 3
@export var layer_spacing: float = 0.05

@export_group("Animation")
@export var speed: float = 2.0
@export var wave_frequency: float = 3.0
@export var wave_amplitude: float = 0.15
@export var spin_force: float = 0.5

@export_group("Visuals")
@export var layer_color: Color = Color(0.1, 0.8, 0.8, 0.3)
@export var emission_strength: float = 0.5

@onready var path_3d: Path3D = $Path3D
# We will manage CSG Polygons dynamically

var _time: float = 0.0
var _curve: Curve3D

func _ready():
	_setup_nodes()
	_initialize_curve()
	_update_material()

func _process(delta):
	_time += delta * speed
	_animate_curve()

func _setup_nodes():
	# Ensure Path3D exists
	if not path_3d:
		path_3d = Path3D.new()
		path_3d.name = "Path3D"
		add_child(path_3d)
	
	# Create Layers
	for i in range(layers):
		var node_name = "CloakLayer_%d" % i
		var layer = get_node_or_null(node_name)
		
		if not layer:
			layer = CSGPolygon3D.new()
			layer.name = node_name
			add_child(layer)
			
		# Configure CSG Polygon
		layer.mode = CSGPolygon3D.MODE_PATH
		layer.path_node = layer.get_path_to(path_3d)
		layer.path_interval_type = CSGPolygon3D.PATH_INTERVAL_SUBDIVIDE
		layer.path_interval = 2.0
		layer.path_simplify_angle = 0.0
		layer.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH
		layer.path_local = false
		layer.path_continuous_u = true
		
		# Offset profile for each layer to create volume
		var offset = i * layer_spacing
		var w = 0.02 # width
		
		var polygon = PackedVector2Array([
			Vector2(-w - offset, 0),
			Vector2(-w - offset, 1.0),
			Vector2(w + offset, 1.0),
			Vector2(w + offset, 0)
		])
		layer.polygon = polygon

func _update_material():
	for i in range(layers):
		var node_name = "CloakLayer_%d" % i
		var layer = get_node_or_null(node_name)
		
		if layer:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = layer_color
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED # Double sided
			mat.emission_enabled = true
			mat.emission = layer_color
			mat.emission_energy_multiplier = emission_strength
			layer.material = mat

func _initialize_curve():
	_curve = Curve3D.new()
	for i in range(segments + 1):
		# Start with a straight line or spiral
		var t = float(i) / float(segments)
		var y = -t * height
		
		# Create a basic spiral shape
		var angle = t * PI * 2.0 # Full circle layout if needed, or just a drape
		var r = lerp(radius_top, radius_bottom, t)
		
		var x = 0 # sin(angle) * r
		var z = 0 # cos(angle) * r
		
		_curve.add_point(Vector3(x, y, z))
	
	path_3d.curve = _curve

func _animate_curve():
	if not _curve: return
	
	for i in range(_curve.point_count):
		var t = float(i) / float(segments)
		
		# Base Helix/Spiral shape
		# This gives it volume and form
		var angle_base = t * PI * 1.5 + _time * spin_force * 0.1
		var r = lerp(radius_top, radius_bottom, t)
		
		# Wave displacement
		# Higher parts move less, lower parts ripple more
		var wave_mod = t * t # Increases towards bottom
		
		var w_x = sin(_time * wave_frequency + t * 10.0) * wave_amplitude * wave_mod
		var w_z = cos(_time * wave_frequency + t * 8.5) * wave_amplitude * wave_mod
		
		var base_x = sin(angle_base) * r
		var base_z = cos(angle_base) * r
		
		var pos = Vector3(base_x + w_x, -t * height, base_z + w_z)
		
		_curve.set_point_position(i, pos)
		
		# Optional: Twist control points for smoother curves
		# _curve.set_point_in(i, ...)
