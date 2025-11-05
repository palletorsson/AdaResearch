extends Node3D

@export var monitor_pivot_path: NodePath
@export var screen_mesh_path: NodePath
@export var screen_material: ShaderMaterial

var _screen_mesh: MeshInstance3D

func _ready() -> void:
    var monitor_pivot := get_node_or_null(monitor_pivot_path) as Node3D
    _screen_mesh = get_node_or_null(screen_mesh_path) as MeshInstance3D

    if monitor_pivot:
        monitor_pivot.rotation = Vector3.ZERO

    if _screen_mesh and screen_material:
        var mat := screen_material.duplicate() as ShaderMaterial
        _screen_mesh.material_override = mat
