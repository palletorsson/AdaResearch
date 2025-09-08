# VRMenuElement.gd - Thin slanted squashed cube for VR menu with text
extends Node3D

@export var base_color: Color = Color(1.0, 0.4, 0.7)  # Pink menu color
@export var menu_text: String = "MENU ITEM"
@export var text_color: Color = Color.WHITE
@export var hover_color: Color = Color(0.4, 0.8, 1.0)

var is_hovered: bool = false
var text_label: Label3D

func _ready():
	create_vr_menu_cube()
	create_text_element()

func create_vr_menu_cube():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# VR menu dimensions - parallelogram shape (slanted rectangle)
	var width = 1.0      # Width of the rectangle
	var height = 0.4     # Height of the rectangle
	var depth = 0.05     # Very shallow depth
	var skew = 0.3       # How much to slant the shape horizontally
	
	var vertices = [
		# Front face (parallelogram - slanted rectangle)
		Vector3(-width + skew, -height, depth),      # 0 - bottom left (shifted right)
		Vector3(width + skew, -height, depth),       # 1 - bottom right (shifted right)
		Vector3(width - skew, height, depth),        # 2 - top right (shifted left)
		Vector3(-width - skew, height, depth),       # 3 - top left (shifted left)
		# Back face (smaller parallelogram)
		Vector3(-width + skew * 0.8, -height * 0.9, -depth),   # 4 - bottom left back
		Vector3(width + skew * 0.8, -height * 0.9, -depth),    # 5 - bottom right back
		Vector3(width - skew * 0.8, height * 0.9, -depth),     # 6 - top right back
		Vector3(-width - skew * 0.8, height * 0.9, -depth)     # 7 - top left back
	]
	
	# Parallelogram faces
	var faces = [
		# Front parallelogram face
		[0, 1, 2], [0, 2, 3],
		# Back parallelogram face  
		[5, 4, 7], [5, 7, 6],
		# Side faces
		[4, 0, 3], [4, 3, 7],  # Left face
		[1, 5, 6], [1, 6, 2],  # Right face
		[3, 2, 6], [3, 6, 7],  # Top face
		[4, 5, 1], [4, 1, 0]   # Bottom face
	]
	
	# Add UV coordinates for better texturing
	for face in faces:
		add_triangle_with_normal_and_uv(st, vertices, face)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "VRMenuCube"
	apply_vr_menu_material(mesh_instance, base_color)
	add_child(mesh_instance)
	
	# Add collision for VR interaction - parallelogram shaped
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3((width + skew) * 2, height * 2, depth * 2)
	collision_shape.shape = box_shape
	
	var area = Area3D.new()
	area.add_child(collision_shape)
	area.name = "InteractionArea"
	add_child(area)
	
	# Connect hover signals for VR interaction
	area.mouse_entered.connect(_on_hover_start)
	area.mouse_exited.connect(_on_hover_end)

func create_text_element():
	text_label = Label3D.new()
	text_label.text = menu_text
	text_label.font_size = 48
	text_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	text_label.modulate = text_color
	text_label.outline_size = 2
	text_label.outline_modulate = Color.BLACK
	
	# Position text in front of the cube
	text_label.position = Vector3(0, 0, 0.08)
	text_label.name = "MenuText"
	add_child(text_label)

func add_triangle_with_normal_and_uv(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	# Simple UV mapping
	var uv0 = Vector2(0, 0)
	var uv1 = Vector2(1, 0)
	var uv2 = Vector2(1, 1)
	
	# Add vertices with normals and UVs
	st.set_normal(normal)
	st.set_uv(uv0)
	st.add_vertex(v0)
	
	st.set_normal(normal)
	st.set_uv(uv1)
	st.add_vertex(v1)
	
	st.set_normal(normal)
	st.set_uv(uv2)
	st.add_vertex(v2)

func apply_vr_menu_material(mesh_instance: MeshInstance3D, color: Color):
	# Use the SimpleGrid shader for wireframe effect
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	
	if shader:
		material.shader = shader
		
		# Set shader parameters using the SimpleGrid uniforms
 
		material.set_shader_parameter("wireframe_color", Color.DEEP_PINK)

		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader not found
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
		mesh_instance.material_override = standard_material

func _on_hover_start():
	is_hovered = true
	animate_hover(true)

func _on_hover_end():
	is_hovered = false
	animate_hover(false)

func animate_hover(hover: bool):
	var mesh_instance = get_node("VRMenuCube") as MeshInstance3D
	if not mesh_instance:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if hover:
		# Hover effects
		tween.tween_property(self, "scale", Vector3(1.1, 1.1, 1.1), 0.2)
		apply_vr_menu_material(mesh_instance, hover_color)
		if text_label:
			tween.tween_property(text_label, "modulate", Color.YELLOW, 0.2)
	else:
		# Return to normal
		tween.tween_property(self, "scale", Vector3.ONE, 0.2)
		apply_vr_menu_material(mesh_instance, base_color)
		if text_label:
			tween.tween_property(text_label, "modulate", text_color, 0.2)

func set_menu_text(new_text: String):
	menu_text = new_text
	if text_label:
		text_label.text = new_text

func set_base_color(color: Color):
	base_color = color
	var mesh_instance = get_node("VRMenuCube") as MeshInstance3D
	if mesh_instance and not is_hovered:
		apply_vr_menu_material(mesh_instance, base_color)

func set_text_color(color: Color):
	text_color = color
	if text_label and not is_hovered:
		text_label.modulate = color

# VR interaction methods
func activate():
	# Called when VR controller selects this menu item
	print("Menu item activated: ", menu_text)
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.9, 0.9, 0.9), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.1)
	
	# Emit custom signal for menu system
	menu_item_selected.emit(menu_text)

signal menu_item_selected(item_text: String)

# Helper function to position menu items in VR space
func set_vr_position(index: int, total_items: int, radius: float = 2.0):
	var angle = (float(index) / total_items) * TAU
	var x = cos(angle) * radius
	var z = sin(angle) * radius
	position = Vector3(x, 0, z)
	
	# Face toward center
	look_at(Vector3.ZERO, Vector3.UP)
