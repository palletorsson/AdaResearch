# MaterialHelper.gd
extends Node
class_name MaterialHelper
# Sets the albedo texture of the mesh’s material.
# If the material is a ShaderMaterial, it updates the shader parameter.
# Otherwise, it creates a new StandardMaterial3D and assigns it.
static func set_material_texture(mesh: MeshInstance3D, tex: ImageTexture) -> void:
	if mesh.material_override is ShaderMaterial:
		var shader_material = mesh.material_override as ShaderMaterial
		shader_material.set_shader_parameter("texture_albedo", tex)
	else:
		var material = StandardMaterial3D.new()
		material.albedo_texture = tex
		mesh.material_override = material


# Updates the color of the panel mesh material
static func update_panel_material(panelMesh: Node3D, state: int) -> void:

	if panelMesh:
		var material = panelMesh.material_override as ShaderMaterial
		if material == null:
			material = StandardMaterial3D.new()
	
		#material.albedo_color = CellularAutomata.get_color_for_state(state)
		panelMesh.material_override = material
		


# ===============================
# 🎨 Updates the texture of a MeshInstance3D material
# ===============================

static func update_texture_material(mesh: MeshInstance3D, texture: ImageTexture) -> void:
	if not mesh:
		push_error("❌ No mesh provided!")
		return
	
	var material = mesh.get_surface_override_material(0) as StandardMaterial3D
	if material:
		material.albedo_texture = texture
	else:
		material = create_unique_material(texture)
	
	mesh.set_surface_override_material(0, material)


# ===============================
# 🎨 Creates a unique material per instance
# ===============================

static func create_unique_material(texture: ImageTexture) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	return material

# ===============================
# 🎨 Assigns a unique material with a texture to a MeshInstance3D
# ===============================

static func assign_unique_material(mesh: MeshInstance3D, texture: ImageTexture) -> void:
	if not mesh:
		push_error("❌ No mesh provided!")
		return
	
	var new_material = create_unique_material(texture)
	mesh.set_surface_override_material(0, new_material)

static func create_material(color: Color) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	return material
