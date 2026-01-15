@tool
extends Node3D

## Interactive Color Mixing Demo
## Uses GrabDisks to mix colors based on proximity to a center point.

@export var max_mix_distance: float = 0.5
@export var output_mesh: MeshInstance3D

var _disks: Array[GrabDisk] = []
var _center_position: Vector3 = Vector3.ZERO
var _timer: float = 0.0

# Advanced Glitch Parameters (from AdvancedGlitch system)
var _glitch_time: float = 0.0
var _glitch_mode: bool = false # toggled if we detect "Advanced" disks

func _ready() -> void:
    _center_position = global_position
    
    # Simple setup checks
    if not output_mesh:
        var sphere = MeshInstance3D.new()
        sphere.mesh = SphereMesh.new()
        sphere.mesh.radius = 0.3
        sphere.mesh.height = 0.6
        sphere.position = Vector3(0, 0.5, 0)
        add_child(sphere)
        output_mesh = sphere

    output_mesh.material_override = StandardMaterial3D.new()

    # Find existing disks or wait for them
    _find_disks()

func _process(delta: float) -> void:
    _glitch_time += delta
    _update_mixing()

func _find_disks() -> void:
    # Look for disks that are children or siblings (for demo purpose, just search children or nearby nodes if specific group)
    # For this demo scene, we assume disks are children of a "Disks" node or direct children
    var potential_disks = find_children("*", "GrabDisk", true, false)
    _disks.clear()
    for node in potential_disks:
        if node is GrabDisk:
            _disks.append(node)

func _update_mixing() -> void:
    if not output_mesh or _disks.is_empty():
        return

    var final_color = Color(0, 0, 0, 1)
    var total_influence = 0.0
    var advanced_influence = 0.0
    
    # Mixing logic
    for disk in _disks:
        if not is_instance_valid(disk):
            continue
            
        var dist = disk.global_position.distance_to(global_position)
        var influence = clamp(1.0 - (dist / max_mix_distance), 0.0, 1.0)
        
        # Simple Additive Mixing
        final_color += disk.disk_color * influence
        total_influence += influence
        
        # Check for "Advanced" tag or property if we add it later
        # For now, let's say if it's a "Glitch" disk (we can check name)
        if "Glitch" in disk.name and influence > 0.1:
            advanced_influence += influence

    # Apply to material
    var mat = output_mesh.material_override as StandardMaterial3D
    if mat:
        if advanced_influence > 0.0:
            # Glitch Mode
            mat.albedo_color = _calculate_glitch_color(final_color, advanced_influence)
            # Maybe shake the mesh?
            output_mesh.position.x = sin(_glitch_time * 50) * 0.01 * advanced_influence
        else:
            # Normal Mode
            mat.albedo_color = final_color
            mat.emission_enabled = true
            mat.emission = final_color
            mat.emission_energy = total_influence # Glow more when more intense
            output_mesh.position.x = 0 # Reset shake

# Pseudo-random glitch color based on the "AdvancedGlitch" script ideas
func _calculate_glitch_color(base: Color, intensity: float) -> Color:
    var t = _glitch_time
    var r = base.r
    var g = base.g
    var b = base.b
    
    if randf() < intensity * 0.1:
        # Random channel swap
        var temp = r
        r = g
        g = temp
    
    if randf() < intensity * 0.05:
        # Invert
        r = 1.0 - r
        g = 1.0 - g
        b = 1.0 - b
        
    return Color(r, g, b, 1.0)
