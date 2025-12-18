@tool
extends Node3D

@export var cycle_duration: float = 8.0
@export var background_separation: float = 2.0
@export var target_size: float = 1.0

var time: float = 0.0
var _bg_left: MeshInstance3D
var _bg_right: MeshInstance3D
var _target_left: MeshInstance3D
var _target_right: MeshInstance3D
var _connector: MeshInstance3D

func _ready():
	_create_geometry()

func _process(delta):
	time += delta
	_animate()

func _create_geometry():
	# Clean up logic for tool mode updates
	for child in get_children():
		child.queue_free()
		
	# Left Background (Dark)
	_bg_left = _create_panel(Color(0.1, 0.1, 0.1), Vector3(-background_separation, 0, 0))
	_bg_left.name = "Background_Dark"
	
	# Right Background (White)
	_bg_right = _create_panel(Color(0.9, 0.9, 0.9), Vector3(background_separation, 0, 0))
	_bg_right.name = "Background_Light"
	
	# Targets (Same Mid-Gray Color)
	var gray = Color(0.5, 0.5, 0.5)
	_target_left = _create_sphere(gray, Vector3(-background_separation, 0, 0.5))
	_target_right = _create_sphere(gray, Vector3(background_separation, 0, 0.5))
	
	# Connector (Proof)
	_connector = _create_bar(gray)
	_connector.visible = false

func _create_panel(color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(3, 4, 0.2)
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED # Important for flat color illusion
	mi.material_override = mat
	
	add_child(mi)
	return mi

func _create_sphere(color: Color, pos: Vector3) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = target_size * 0.4
	mesh.height = target_size * 0.8
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	
	add_child(mi)
	return mi

func _create_bar(color: Color) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = Vector3(background_separation * 2.0, target_size * 0.2, 0.2)
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0, 0, 0.5)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	
	add_child(mi)
	return mi

func _animate():
	# 0.0 - 0.4: Targets move up/down
	# 0.4 - 0.5: Targets align
	# 0.5 - 0.9: Connector appears (Proof)
	# 0.9 - 1.0: Reset
	
	var phase = fmod(time / cycle_duration, 1.0)
	
	if phase < 0.5:
		# Separation Phase
		_connector.visible = false
		var y_offset = sin(phase * TAU * 2.0) * 1.5
		_target_left.position.y = y_offset
		_target_right.position.y = -y_offset # Opposite motion emphasizes separation
	else:
		# Connection Phase
		_target_left.position.y = lerp(_target_left.position.y, 0.0, 0.1)
		_target_right.position.y = lerp(_target_right.position.y, 0.0, 0.1)
		
		# Show connector to prove they are same color
		if abs(_target_left.position.y) < 0.1:
			_connector.visible = true
			
