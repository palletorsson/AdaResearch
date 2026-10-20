extends Node

const SAMPLE = preload("09_fabric_sample.gdshader")

func _process(_delta: float) -> void:
    var studio = get_parent() # The supplied FabricShaderStudio root.
    if not is_instance_valid(studio.wall) or not is_instance_valid(studio.preview):
        return
    var skirt: MeshInstance3D = studio.preview.outfit.get_node("Skirt")
    for surface in [studio.wall, skirt]:
        var material: ShaderMaterial = surface.material_override
        if material.shader != SAMPLE:
            material.shader = SAMPLE
    studio.code.text = "STUDY: UV -> repeat + offset -> sample\nUse PAINT / OFFSET / REPEAT\nFull shader features wait in the original studio"
