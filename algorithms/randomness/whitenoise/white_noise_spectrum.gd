@tool
extends Node3D

# Agent-WhiteNoise: 3D White Noise Spectrum Visualization
# Generates a field of thin lines where height represents random values.

@export var grid_size: Vector2i = Vector2i(50, 50)
@export var spacing: float = 0.2
@export var max_height: float = 2.0
@export var line_thickness: float = 0.02
@export var seed_value: int = 0:
    set(value):
        seed_value = value
        if is_inside_tree():
            generate_spectrum()

@export var color_gradient: Gradient

var _rng = RandomNumberGenerator.new()
var _multi_mesh_instance: MultiMeshInstance3D

func _ready():
    _setup_multimesh()
    generate_spectrum()

func _setup_multimesh():
    if _multi_mesh_instance:
        _multi_mesh_instance.queue_free()
    
    _multi_mesh_instance = MultiMeshInstance3D.new()
    add_child(_multi_mesh_instance)
    
    var mesh = BoxMesh.new()
    mesh.size = Vector3(line_thickness, 1.0, line_thickness) # Unit height, scaled later
    
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh.material = material
    
    _multi_mesh_instance.multimesh = MultiMesh.new()
    _multi_mesh_instance.multimesh.mesh = mesh
    _multi_mesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
    _multi_mesh_instance.multimesh.use_colors = true

func generate_spectrum():
    if not _multi_mesh_instance:
        return
        
    if seed_value == 0:
        _rng.randomize()
    else:
        _rng.seed = seed_value
        
    var count = grid_size.x * grid_size.y
    _multi_mesh_instance.multimesh.instance_count = count
    
    var idx = 0
    var offset_x = (grid_size.x * spacing) / 2.0
    var offset_z = (grid_size.y * spacing) / 2.0
    
    for x in range(grid_size.x):
        for z in range(grid_size.y):
            var random_val = _rng.randf() # 0.0 to 1.0
            var height = random_val * max_height
            
            # Position: Centered on XZ, Y based on height (growing up from 0)
            var pos = Vector3(x * spacing - offset_x, height / 2.0, z * spacing - offset_z)
            
            # Transform: Scale Y to match height
            var basis = Basis()
            basis = basis.scaled(Vector3(1.0, height, 1.0))
            var transform = Transform3D(basis, pos)
            
            _multi_mesh_instance.multimesh.set_instance_transform(idx, transform)
            
            # Color: Map random value to gradient or grayscale
            var color = Color.WHITE
            if color_gradient:
                color = color_gradient.sample(random_val)
            else:
                color = Color(random_val, random_val, random_val)
            
            _multi_mesh_instance.multimesh.set_instance_color(idx, color)
            idx += 1
