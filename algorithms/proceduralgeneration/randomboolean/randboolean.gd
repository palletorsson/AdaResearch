extends Node3D

@onready var subtract = $CSGCombiner3D_c_x/CSGSphere3D_substract
@onready var body = $CSGCombiner3D_c_x/CSGBox3D_body
@onready var combiner = $CSGCombiner3D_c_x

func _ready() -> void:
	print("🧪 Testing CSG carving - duplicating subtract sphere...")
	
	# Create a row of subtracting spheres along X axis
	var num_spheres = 5
	var spacing = 10.0  # Distance between spheres (increased for larger spheres)
	var start_x = body.transform.origin.x - (spacing * 2)
	var sphere_radius = 6.0  # Bigger spheres to carve visible holes (was 4.0)
	
	for i in range(num_spheres):
		# Duplicate the original subtract sphere (copies all properties)
		var new_sphere = subtract.duplicate()
		new_sphere.name = "CarveSphere_%d" % i
		new_sphere.radius = sphere_radius  # Make it bigger!
		
		# Position along X axis
		var x_pos = start_x + (i * spacing)
		new_sphere.transform.origin = Vector3(x_pos, body.transform.origin.y, body.transform.origin.z)
		
		# Add as child of CSGCombiner3D (sibling to body and original subtract)
		combiner.add_child(new_sphere)
		print("  ✓ Duplicated sphere at x=", x_pos, " radius=", sphere_radius)
		
	print("✅ Created ", num_spheres, " carving spheres in a row")
