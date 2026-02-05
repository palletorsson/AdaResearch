# vector_normalize_demo.gd
# Interactive vector normalization visualization
# Same style as VectorBasics - uses vector_scene_base
#
# Shows: V̂ = V / |V| (unit vector in same direction)

extends "res://algorithms/vectors/shared/vector_scene_base.gd"

class_name VectorNormalizeDemo

var vector_v: Node3D
var unit_vector: Node3D
var unit_sphere: MeshInstance3D
var info_label: Label3D
var unit_label: Label3D

# Cached references
var _cached_vector_nodes: Dictionary = {}
var _cached_unit_nodes: Dictionary = {}

func _ready():
	super._ready()
	create_axes(1.5)
	
	# Create unit sphere (radius 1, transparent)
	_create_unit_sphere()
	
	# Main vector - faded (original)
	vector_v = spawn_vector(Vector3.ZERO, Vector3(1.2, 0.8, 0.4), Color(0.5, 0.5, 0.6, 0.6), "Vector V")
	
	# Unit vector - bright green
	unit_vector = spawn_vector(Vector3.ZERO, Vector3(1, 0, 0), Color(0.2, 1.0, 0.5, 1.0), "Unit V", false)
	
	# Info panel
	info_label = create_info_panel("Normalization", Vector3(0.6, 1.0, 0.0))
	
	# Unit vector label
	unit_label = Label3D.new()
	unit_label.pixel_size = 0.0025
	unit_label.font_size = 28
	unit_label.text = "V̂"
	unit_label.modulate = Color(0.2, 1.0, 0.5)
	unit_label.outline_size = 8
	unit_label.outline_modulate = Color(0, 0, 0, 0.8)
	unit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(unit_label)
	
	# Cache nodes
	_cache_vector_nodes(vector_v, _cached_vector_nodes)
	_cache_vector_nodes(unit_vector, _cached_unit_nodes)

func _create_unit_sphere():
	unit_sphere = MeshInstance3D.new()
	unit_sphere.name = "UnitSphere"
	
	var sphere = SphereMesh.new()
	sphere.radius = 1.0 * SCENE_SCALE
	sphere.height = 2.0 * SCENE_SCALE
	sphere.radial_segments = 32
	sphere.rings = 16
	unit_sphere.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.08)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	unit_sphere.material_override = mat
	
	environment_root.add_child(unit_sphere)
	
	# Add wireframe rings for visibility
	_create_wireframe_ring(Vector3.UP, Color(0.4, 0.4, 0.5, 0.25))
	_create_wireframe_ring(Vector3.RIGHT, Color(0.4, 0.4, 0.5, 0.25))
	_create_wireframe_ring(Vector3.FORWARD, Color(0.4, 0.4, 0.5, 0.25))

func _create_wireframe_ring(normal: Vector3, color: Color):
	var ring = Node3D.new()
	var segments = 48
	var radius = 1.0 * SCENE_SCALE
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	for i in range(segments):
		var angle1 = TAU * i / segments
		var angle2 = TAU * (i + 1) / segments
		
		var p1: Vector3
		var p2: Vector3
		
		if normal == Vector3.UP:
			p1 = Vector3(cos(angle1), 0, sin(angle1)) * radius
			p2 = Vector3(cos(angle2), 0, sin(angle2)) * radius
		elif normal == Vector3.RIGHT:
			p1 = Vector3(0, cos(angle1), sin(angle1)) * radius
			p2 = Vector3(0, cos(angle2), sin(angle2)) * radius
		else:
			p1 = Vector3(cos(angle1), sin(angle1), 0) * radius
			p2 = Vector3(cos(angle2), sin(angle2), 0) * radius
		
		var segment = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		var length = (p2 - p1).length()
		cylinder.top_radius = 0.003
		cylinder.bottom_radius = 0.003
		cylinder.height = length
		segment.mesh = cylinder
		segment.material_override = mat
		segment.position = (p1 + p2) / 2.0
		
		# Orient segment along direction (without look_at - node not in tree)
		var direction = p2 - p1
		if direction.length() > 0.001:
			var up = Vector3.UP
			if abs(direction.normalized().dot(up)) > 0.99:
				up = Vector3.FORWARD
			# Calculate rotation manually
			var basis = Basis.looking_at(direction, up)
			segment.basis = basis
			segment.rotate_object_local(Vector3.RIGHT, PI/2)
		
		ring.add_child(segment)
	
	environment_root.add_child(ring)

func _process(_delta):
	var vec = _get_vector_fast(vector_v, _cached_vector_nodes)
	_update_unit_vector(vec)
	_update_info(vec)
	_update_unit_label(vec)

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary):
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		return end.global_position - start.global_position
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(arrow: Node3D, vector: Vector3, cache_dict: Dictionary):
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		end_node.position = vector
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func _update_unit_vector(vec: Vector3):
	var magnitude = vec.length()
	if magnitude > 0.001:
		var unit = vec / magnitude
		_update_vector_fast(unit_vector, unit, _cached_unit_nodes)
	else:
		_update_vector_fast(unit_vector, Vector3.ZERO, _cached_unit_nodes)

func _update_info(vec: Vector3):
	var magnitude = vec.length()
	var unit = vec.normalized() if magnitude > 0.001 else Vector3.ZERO
	
	var builder := []
	builder.append("V = (%.2f, %.2f, %.2f)" % [vec.x, vec.y, vec.z])
	builder.append("|V| = %.3f" % magnitude)
	builder.append("")
	builder.append("V̂ = V / |V|")
	builder.append("V̂ = (%.2f, %.2f, %.2f)" % [unit.x, unit.y, unit.z])
	builder.append("|V̂| = 1.000")
	info_label.text = "\n".join(builder)

func _update_unit_label(vec: Vector3):
	var magnitude = vec.length()
	if magnitude > 0.001:
		var unit = vec.normalized()
		# Position at tip of unit vector, offset toward player
		unit_label.position = unit * 0.5 * SCENE_SCALE + Vector3(0, 0.06, 0.08)
		unit_label.visible = true
	else:
		unit_label.visible = false
