extends MeshInstance3D

@export var length: int = 30
@export var width: float = 0.2
@export var color: Color = Color(0.0, 1.0, 1.0, 0.5)

var history = []

func _ready():
	mesh = ImmediateMesh.new()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat
	
	# Trail must exist in Global Space to not rotate with the boid's instantaneous rotation
	set_as_top_level(true)
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO

func _process(_delta):
	var parent = get_parent()
	if not is_instance_valid(parent):
		queue_free()
		return
	
	# Add current transform to history
	history.append(parent.global_transform)
	if history.size() > length:
		history.pop_front()
	
	_draw_ribbon()

func _draw_ribbon():
	mesh.clear_surfaces()
	if history.size() < 2: return
	
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	for i in range(history.size()):
		var xform = history[i]
		var pos = xform.origin
		# Use the boid's 'Right' vector for the ribbon width
		var right = xform.basis.x.normalized()
		
		# Fade out tail (alpha) and taper size
		var fraction = float(i) / float(history.size() - 1)
		var w = width * fraction
		var c = color
		c.a = color.a * fraction # Fade out
		
		mesh.surface_set_color(c)
		mesh.surface_add_vertex(pos - right * w)
		
		mesh.surface_set_color(c)
		mesh.surface_add_vertex(pos + right * w)
		
	mesh.surface_end()
