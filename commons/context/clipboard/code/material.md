# Configure a StandardMaterial3D

- Instantiate a StandardMaterial3D for runtime customization.
- Adjust albedo, roughness, and metallic values for the desired look.
- Assign the material to a MeshInstance3D via material_override.

```gdscript
# Create a glossy colored material
var material := StandardMaterial3D.new()
material.albedo_color = Color(0.2, 0.6, 1.0)
material.metallic = 0.2
material.roughness = 0.1
var mesh_instance := MeshInstance3D.new()
mesh_instance.mesh = SphereMesh.new()
mesh_instance.material_override = material
add_child(mesh_instance)
```
