
# ===============================
# VORONOI SPACE - Territorial boundaries
# ===============================
extends TopologySpace
class_name VoronoiSpace

@export var num_points: int = 20
@export var height_variation: float = 2.0

var voronoi_points: Array[Vector2] = []
var point_heights: Array[float] = []

func _ready():
	generate_voronoi_points()
	super._ready()

func generate_voronoi_points():
	voronoi_points.clear()
	point_heights.clear()
	
	for i in range(num_points):
		var point = Vector2(
			randf_range(-space_size.x/2, space_size.x/2),
			randf_range(-space_size.y/2, space_size.y/2)
		)
		voronoi_points.append(point)
		point_heights.append(randf_range(-height_variation, height_variation))

func generate_space():
	var heights = []
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var world_x = (x / float(resolution)) * space_size.x - space_size.x/2
			var world_z = (z / float(resolution)) * space_size.y - space_size.y/2
			var pos = Vector2(world_x, world_z)
			
			# Find closest Voronoi point
			var closest_dist = INF
			var closest_height = 0.0
			
			for i in range(voronoi_points.size()):
				var dist = pos.distance_to(voronoi_points[i])
				if dist < closest_dist:
					closest_dist = dist
					closest_height = point_heights[i]
			
			heights.append(closest_height * height_scale)
	
	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	
	# Cellular material for territorial aesthetic
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.4, 0.6) # Organic pink
	material.roughness = 0.6
	mesh_instance.material_override = material
