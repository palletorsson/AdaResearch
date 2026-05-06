extends Node3D
class_name FoldingCubeInteractive

## Interactive Folding Cube - Grab edges to fold manually
## Or use the fold handle to animate

@export var face_size: float = 0.5
@export var face_color: Color = Color(0.9, 0.85, 0.8, 1.0)
@export var handle_color: Color = Color(0.2, 0.6, 0.9, 1.0)

var _folding_cube: FoldingCube
var _fold_handle: Node3D
var _is_grabbed: bool = false
var _grab_start_y: float = 0.0
var _grab_start_progress: float = 0.0

func _ready() -> void:
	_setup_folding_cube()
	_setup_fold_handle()

func _setup_folding_cube() -> void:
	_folding_cube = FoldingCube.new()
	_folding_cube.face_size = face_size
	_folding_cube.face_color = face_color
	_folding_cube.fold_duration = 1.5
	add_child(_folding_cube)

func _setup_fold_handle() -> void:
	# Create a grabbable handle that controls fold progress
	var handle_scene = load("res://addons/godot-xr-tools/objects/pickable.tscn")
	
	if handle_scene:
		_fold_handle = handle_scene.instantiate()
		_fold_handle.name = "FoldHandle"
		
		# Position handle above the cube
		_fold_handle.position = Vector3(0, face_size + 0.2, 0)
		
		# Add visual
		var mesh = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		mesh.mesh = sphere
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = handle_color
		mat.emission_enabled = true
		mat.emission = handle_color
		mat.emission_energy_multiplier = 0.5
		mesh.material_override = mat
		
		_fold_handle.add_child(mesh)
		
		# Add collision
		var collision = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.08
		collision.shape = shape
		_fold_handle.add_child(collision)
		
		# Connect signals
		if _fold_handle.has_signal("picked_up"):
			_fold_handle.picked_up.connect(_on_handle_grabbed)
		if _fold_handle.has_signal("dropped"):
			_fold_handle.dropped.connect(_on_handle_released)
		
		add_child(_fold_handle)
	else:
		# Fallback: simple Area3D for clicking
		_fold_handle = Area3D.new()
		_fold_handle.name = "FoldHandle"
		_fold_handle.position = Vector3(0, face_size + 0.2, 0)
		
		var collision = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.1
		collision.shape = shape
		_fold_handle.add_child(collision)
		
		var mesh = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.06
		mesh.mesh = sphere
		_fold_handle.add_child(mesh)
		
		_fold_handle.input_event.connect(_on_handle_clicked)
		
		add_child(_fold_handle)

func _process(_delta: float) -> void:
	if _is_grabbed and _fold_handle:
		# Map handle Y position to fold progress
		var handle_y = _fold_handle.global_position.y - global_position.y
		var min_y = 0.1  # Flat position
		var max_y = face_size + 0.3  # Folded position
		
		var progress = inverse_lerp(max_y, min_y, handle_y)
		_folding_cube.fold_progress = clamp(progress, 0.0, 1.0)

func _on_handle_grabbed(_pickable = null) -> void:
	_is_grabbed = true
	_grab_start_y = _fold_handle.global_position.y
	_grab_start_progress = _folding_cube.fold_progress

func _on_handle_released(_pickable = null) -> void:
	_is_grabbed = false
	# Snap to nearest state (flat or folded)
	if _folding_cube.fold_progress > 0.5:
		_folding_cube.animate_fold(0.3)
	else:
		_folding_cube.animate_unfold(0.3)

func _on_handle_clicked(_camera, event, _position, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		_folding_cube.toggle_fold()

# Public API
func fold() -> void:
	_folding_cube.animate_fold()

func unfold() -> void:
	_folding_cube.animate_unfold()

func toggle() -> void:
	_folding_cube.toggle_fold()

func get_fold_progress() -> float:
	return _folding_cube.fold_progress

func set_fold_progress(p: float) -> void:
	_folding_cube.fold_progress = p
