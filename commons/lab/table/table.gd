# Table.gd - Procedural table using SurfaceTool
extends Node3D


# @identity
# essence: table = top_surface + legs[4] + frame, all from rounded box primitives
# desire: Provide a stable horizontal surface for laboratory instruments in VR
# critical_parameter: base_color — sets the wood tone that grounds the lab aesthetic
# triggers: create_table() builds the full furniture piece procedurally from box vertices
# emerges: the functional foundation — every experiment needs a table
# needs: VR object placement surface [has]
# relationships: depends on SurfaceTool mesh generation; supports all lab instruments (microscope, multimeter, scales); unlocks lab spatial organization
# truth: The table is the zero plane from which all measurement begins.

# --- DNA (stage 2, promoted 2026-07-29) --------------------------------------
# stance: what holds the zero plane up, and therefore what kind of claim the
#   surface makes. It was hard-coded to four corner legs plus a four-beam
#   ankle-height skirt — a braced workbench, furniture that expects weight and
#   hands. "pedestal" removes the legs for a single central column on a foot,
#   so the top reads as a display plinth: approach from any side, nothing
#   underneath, the object on it becomes the subject. "trestle" swaps the legs
#   for two end panels and one long stretcher — the demountable board, a
#   surface that admits it can be taken apart.
# finish: the material argument. base_color was fixed at Color(0.6,0.3,0.1),
#   a dark wood — the nineteenth-century bench where the experiment is craft.
#   "steel" is the clean room, "stone" the slab that outlasts the work,
#   "glass" the surface that refuses to hide what is under it.
# Defaults stance="bench" + finish="wood" rebuild the original mesh set and
# the original shader parameters exactly.
# -----------------------------------------------------------------------------

@export_enum("bench", "pedestal", "trestle") var stance: String = "bench"
@export_enum("wood", "steel", "stone", "glass") var finish: String = "wood"

var base_color: Color = Color(0.6, 0.3, 0.1)  # Dark wood

const STANCES := ["bench", "pedestal", "trestle"]

# "wood" is deliberately absent as an override — it IS the current base_color,
# so leaving it alone keeps set_base_color() authoritative on the default path.
var FINISH_COLORS: Dictionary = {
	"steel": Color(0.62, 0.66, 0.70),
	"stone": Color(0.55, 0.54, 0.50),
	"glass": Color(0.55, 0.72, 0.78),
}

# "wood" reproduces the original shader parameters verbatim.
var FINISH_SHADER: Dictionary = {
	"wood": {"edge_color": Color(0.9, 0.9, 1.0), "edge_width": 0.8, "edge_sharpness": 2.5, "emission_strength": 0.6},
	"steel": {"edge_color": Color(0.95, 0.97, 1.0), "edge_width": 1.2, "edge_sharpness": 3.0, "emission_strength": 0.85},
	"stone": {"edge_color": Color(0.85, 0.85, 0.82), "edge_width": 0.5, "edge_sharpness": 1.8, "emission_strength": 0.35},
	"glass": {"edge_color": Color(0.8, 0.95, 1.0), "edge_width": 1.6, "edge_sharpness": 3.5, "emission_strength": 1.2},
}

var _table_node: Node3D = null
var _built: bool = false
var _color_explicit: bool = false

func _ready():
	create_table()

func create_table():
	if not _color_explicit and finish != "wood" and FINISH_COLORS.has(finish):
		base_color = FINISH_COLORS[finish]

	var table_node = Node3D.new()
	table_node.name = "Table"

	# Create table components
	create_tabletop(table_node)
	match stance:
		"pedestal":
			create_pedestal(table_node)
		"trestle":
			create_trestle(table_node)
		_:
			create_table_legs(table_node)
			create_table_frame(table_node)  # Optional support frame

	add_child(table_node)
	_table_node = table_node
	_built = true

func create_tabletop(parent: Node3D):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top_size = Vector3(1.2, 0.05, 0.8)
	var top_pos = Vector3(0, 0.35, 0)  # Raised above ground
	var vertices = create_rounded_box_vertices(top_pos, top_size, 0.03)
	var faces = create_box_faces()

	# Add all triangles for the tabletop
	for face in faces:
		add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
		add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "Tabletop"
	apply_furniture_material(mesh_instance, base_color)
	parent.add_child(mesh_instance)

func create_table_legs(parent: Node3D):
	var leg_positions = [
		Vector3(-0.5, 0.175, -0.3),   # Front left
		Vector3(0.5, 0.175, -0.3),    # Front right
		Vector3(-0.5, 0.175, 0.3),    # Back left
		Vector3(0.5, 0.175, 0.3)      # Back right
	]

	for i in range(leg_positions.size()):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var leg_size = Vector3(0.06, 0.35, 0.06)  # Square legs
		var vertices = create_box_vertices(leg_positions[i], leg_size)
		var faces = create_box_faces()

		# Add triangles for leg
		for face in faces:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = st.commit()
		mesh_instance.name = "Leg_" + str(i)
		apply_furniture_material(mesh_instance, base_color * 0.8)
		parent.add_child(mesh_instance)

func create_table_frame(parent: Node3D):
	# Create support beams between legs
	var beam_configs = [
		# Horizontal beams (lower)
		{
			"start": Vector3(-0.5, 0.1, -0.3),
			"end": Vector3(0.5, 0.1, -0.3),
			"size": Vector3(1.0, 0.03, 0.03)
		},
		{
			"start": Vector3(-0.5, 0.1, 0.3),
			"end": Vector3(0.5, 0.1, 0.3),
			"size": Vector3(1.0, 0.03, 0.03)
		},
		{
			"start": Vector3(-0.5, 0.1, -0.3),
			"end": Vector3(-0.5, 0.1, 0.3),
			"size": Vector3(0.03, 0.03, 0.6)
		},
		{
			"start": Vector3(0.5, 0.1, -0.3),
			"end": Vector3(0.5, 0.1, 0.3),
			"size": Vector3(0.03, 0.03, 0.6)
		}
	]

	for i in range(beam_configs.size()):
		var config = beam_configs[i]
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var center = (config.start + config.end) * 0.5
		var vertices = create_box_vertices(center, config.size)
		var faces = create_box_faces()

		# Add triangles for beam
		for face in faces:
			add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
			add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])

		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = st.commit()
		mesh_instance.name = "Beam_" + str(i)
		apply_furniture_material(mesh_instance, base_color * 0.7)
		parent.add_child(mesh_instance)

# --- stance variants ---------------------------------------------------------

# One central column on a footplate. Nothing under the top, approachable from
# every side: the surface stops being a workbench and becomes a plinth.
func create_pedestal(parent: Node3D):
	_add_box(parent, "Column", Vector3(0, 0.175, 0), Vector3(0.16, 0.35, 0.16), base_color * 0.8)
	_add_box(parent, "Foot", Vector3(0, 0.025, 0), Vector3(0.55, 0.05, 0.45), base_color * 0.7)

# Two end panels plus one long stretcher — the board that can come apart.
func create_trestle(parent: Node3D):
	_add_box(parent, "Panel_0", Vector3(-0.5, 0.175, 0), Vector3(0.06, 0.35, 0.66), base_color * 0.8)
	_add_box(parent, "Panel_1", Vector3(0.5, 0.175, 0), Vector3(0.06, 0.35, 0.66), base_color * 0.8)
	_add_box(parent, "Stretcher", Vector3(0, 0.13, 0), Vector3(0.95, 0.05, 0.06), base_color * 0.7)

func _add_box(parent: Node3D, box_name: String, center: Vector3, size: Vector3, color: Color) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices = create_box_vertices(center, size)
	var faces = create_box_faces()
	for face in faces:
		add_triangle_with_normal(st, vertices, [face[0], face[1], face[2]])
		add_triangle_with_normal(st, vertices, [face[0], face[2], face[3]])

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = box_name
	apply_furniture_material(mesh_instance, color)
	parent.add_child(mesh_instance)

func create_rounded_box_vertices(center: Vector3, size: Vector3, bevel: float) -> Array:
	# For simplicity, just return regular box vertices
	# In a full implementation, you'd add rounded corners
	return create_box_vertices(center, size)

func create_box_vertices(center: Vector3, size: Vector3) -> Array:
	var half_size = size * 0.5
	return [
		center + Vector3(-half_size.x, -half_size.y, -half_size.z),  # 0
		center + Vector3(half_size.x, -half_size.y, -half_size.z),   # 1
		center + Vector3(half_size.x, half_size.y, -half_size.z),    # 2
		center + Vector3(-half_size.x, half_size.y, -half_size.z),   # 3
		center + Vector3(-half_size.x, -half_size.y, half_size.z),   # 4
		center + Vector3(half_size.x, -half_size.y, half_size.z),    # 5
		center + Vector3(half_size.x, half_size.y, half_size.z),     # 6
		center + Vector3(-half_size.x, half_size.y, half_size.z)     # 7
	]

func create_box_faces() -> Array:
	return [
		[0, 1, 2, 3],  # Front
		[5, 4, 7, 6],  # Back
		[4, 0, 3, 7],  # Left
		[1, 5, 6, 2],  # Right
		[3, 2, 6, 7],  # Top
		[4, 5, 1, 0]   # Bottom
	]

func add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]

	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()

	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_furniture_material(mesh_instance: MeshInstance3D, color: Color):
	# Create shader material using the same approach as dodecahedron
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	var look: Dictionary = FINISH_SHADER.get(finish, FINISH_SHADER["wood"])
	if shader:
		material.shader = shader

		# Set shader parameters for table
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", look["edge_color"])
		material.set_shader_parameter("edge_width", look["edge_width"])
		material.set_shader_parameter("edge_sharpness", look["edge_sharpness"])
		material.set_shader_parameter("emission_strength", look["emission_strength"])

		mesh_instance.material_override = material
	else:
		# Fallback to standard material
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.roughness = 0.8
		standard_material.metallic = 0.1
		mesh_instance.material_override = standard_material

func set_base_color(color: Color):
	base_color = color
	_color_explicit = true
	# Update all child materials
	for child in get_children():
		update_child_materials(child, color)

func update_child_materials(node: Node, color: Color):
	if node is MeshInstance3D:
		apply_furniture_material(node, color)
	for child in node.get_children():
		update_child_materials(child, color)

# --- grid config -------------------------------------------------------------

# Guarded: only rebuilds when a declared axis actually changed AND the first
# build has already happened. A placement that passes no config never rebuilds.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false

	if config_data.has("stance"):
		var s: String = str(config_data["stance"])
		if STANCES.has(s) and s != stance:
			stance = s
			dirty = true

	if config_data.has("finish"):
		var f: String = str(config_data["finish"])
		if FINISH_SHADER.has(f) and f != finish:
			finish = f
			dirty = true

	if config_data.has("base_color"):
		var c: Color = _color_from(config_data["base_color"], base_color)
		_color_explicit = true
		if c != base_color:
			base_color = c
			dirty = true

	if dirty and _built:
		_rebuild()

func _color_from(value, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String and Color.html_is_valid(value):
		return Color.html(value)
	return fallback

func _rebuild() -> void:
	if is_instance_valid(_table_node):
		remove_child(_table_node)
		_table_node.queue_free()
	_table_node = null
	_built = false
	create_table()
