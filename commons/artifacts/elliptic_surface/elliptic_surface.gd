# elliptic_surface.gd
# Dome/sphere-like surface demonstrating positive curvature

extends Node3D

class_name EllipticSurface

# @identity
# essence: K > 0 — positive Gaussian curvature; parallel lines converge, triangles have angle sum > 180°
# desire: touch a dome and feel space curve inward — lines that start parallel must eventually meet
# critical_parameter: radius — controls how tightly space curves
# triggers: static geometry; presence alone teaches that parallel lines can converge
# emerges: the realization that on a sphere there are NO parallel lines at all
# needs: VR controls [missing] — could add curvature_slider connection
# relationships: contrasts hyperbolic_surface (K<0, lines diverge); depends on curvature_slider; paired with angle_sum_triangle
# truth: on a positively curved surface, there is no room for parallel lines — all paths eventually meet

@export var radius: float = 0.4
@export var resolution: int = 24

var _mesh_instance: MeshInstance3D
var _label: Label3D

func _ready():
	_create_surface()
	_create_label()

func _create_surface():
	_mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.radial_segments = resolution
	sphere.rings = resolution / 2
	_mesh_instance.mesh = sphere
	
	# Only show upper hemisphere
	_mesh_instance.position.y = -radius * 0.3
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.5, 0.3)
	mat.metallic = 0.2
	mat.roughness = 0.6
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "ELLIPTIC SURFACE\nPositive curvature\nK > 0"
	_label.position = Vector3(0, -radius - 0.15, 0)
	add_child(_label)

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
