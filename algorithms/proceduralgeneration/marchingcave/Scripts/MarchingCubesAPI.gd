class_name MarchingCubesAPI extends Object

# Mapping of string names to ShapeType enum indices in TerrainGeneratorShapes
# usage: var my_obj = MarchingCubesAPI.create("computer")

const SHAPE_MAP = {
	"human": 0,
	"chair": 1,
	"house": 2,
	"bottle": 3,
	"cup": 4,
	"computer": 5,
	"computerscreen": 5, # Alias
	"microscope": 6,
	"flask": 7,
	"dna": 8,
	"atom": 9,
	"sculpture": 10
}

static func create(shape_name: String, position: Vector3 = Vector3.ZERO, scale: float = 1.0, is_pickable: bool = false) -> Node3D:
	"""
	Creates a new Marching Cubes object by name.
	Returns the container Node3D containing the mesh.
	"""
	var key = shape_name.to_lower().replace("mc:", "")
	
	if not key in SHAPE_MAP:
		push_error("MarchingCubesAPI: Unknown shape '%s'. Available: %s" % [shape_name, SHAPE_MAP.keys()])
		return null
		
	var shape_id = SHAPE_MAP[key]
	
	# Load the generator script
	var generator_script = load("res://algorithms/proceduralgeneration/marchingcave/Scripts/TerrainGeneratorShapes.gd")
	
	# Create container
	var container
	
	if is_pickable:
		# Load GrabSphere scene as the reliable pickable container
		var pickable_scene = load("res://commons/primitives/point/grab_sphere_point.tscn")
		if pickable_scene:
			container = pickable_scene.instantiate()
			container.name = "MC_Pickable_" + shape_name.capitalize()
			# Pickable specific settings
			if "freeze" in container: 
				container.freeze = true # Freeze by default so it doesn't fall through floor
			
			# Ensure correct collision layers regarding XR Tools
			container.collision_layer = 4 
			container.collision_mask = 7
			
			# FORCE CONFIGURATION (Override GrabSphere defaults)
			# 1. Disable "Snap to Hand" (reset_transform_on_pickup) -> Allows grabbing by the edge/shape volume
			_try_set_property(container, "reset_transform_on_pickup", false)
			
			# 2. Configure Grab Method to "Snap" for distance, but combined with reset=false it acts as precision
			_try_set_property(container, "ranged_grab_method", 0) # 0=Snap, 1=Lerp
			
			if container is RigidBody3D:
				# 3. Unlock Rotation explicitly
				container.lock_rotation = false
				container.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
				
				# 4. Make it light so it's easy to rotate
				container.mass = 0.1
				container.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
				container.center_of_mass = Vector3.ZERO
				
				print("MarchingCubesAPI: Forced Pickable Config -> ResetT: %s, LockRot: %s" % [
					container.get("reset_transform_on_pickup"),
					container.lock_rotation
				])

		else:
			print("MarchingCubesAPI: ❌ Pickable scene not found, falling back to static Node3D")
			container = Node3D.new()
			container.name = "MC_" + shape_name.capitalize()
	else:
		container = Node3D.new()
		container.name = "MC_" + shape_name.capitalize()
		
	container.position = position
	container.scale = Vector3.ONE * scale
	
	# Create generator instance
	var terrain = MeshInstance3D.new()
	terrain.name = "Generator"
	terrain.set_script(generator_script)
	
	# Configure for single static object
	terrain.shape_type = shape_id
	terrain.chunk_scale = 120.0 # Standard size for complete objects
	terrain.iso_level = 0.0
	terrain.noise_scale = 1.0
	
	# Objects (chair, computer, etc.) need outward facing normals/colliders
	# unlike caves which are inward facing.
	terrain.invert_faces = true 
	
	# Add default nice material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.9) # Revert to Default Clay
	material.metallic = 0.1
	material.roughness = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	terrain.material_override = material
	
	container.add_child(terrain)
	
	return container

const MATERIALS = {
	"default": {
		"albedo": Color(0.8, 0.8, 0.9),
		"metallic": 0.1,
		"roughness": 0.5
	},
	"bakelite": {
		"albedo": Color(0.3, 0.1, 0.05), # Lighter reddish brown
		"metallic": 0.0,
		"roughness": 0.1, # Very shiny
		"specular": 0.5
	},
	"plastic_red": {
		"albedo": Color(0.8, 0.1, 0.1),
		"metallic": 0.0,
		"roughness": 0.2
	},
	"metal": {
		"albedo": Color(0.7, 0.7, 0.7),
		"metallic": 1.0,
		"roughness": 0.2
	},
	"gold": {
		"albedo": Color(1.0, 0.8, 0.0),
		"metallic": 1.0,
		"roughness": 0.1
	}
}

static func apply_material(object: Node3D, material_name: String):
	"""
	Applies a preset material to the Marching Cubes object.
	"""
	# Try direct child access first
	var generator = object.get_node_or_null("Generator")
	if not generator:
		# Fallback to search
		generator = object.find_child("Generator", true, false)
	
	if not generator:
		print("MarchingCubesAPI: ❌ ERROR - Could not find 'Generator' child in %s" % object.name)
		return
		
	var key = material_name.to_lower().strip_edges()
	if not key in MATERIALS:
		print("MarchingCubesAPI: Unknown material '%s'" % material_name)
		return
		
	var props = MATERIALS[key]
	var material = StandardMaterial3D.new()
	
	if "albedo" in props: material.albedo_color = props["albedo"]
	if "metallic" in props: material.metallic = props["metallic"]
	if "roughness" in props: material.roughness = props["roughness"]
	if "specular" in props: material.metallic_specular = props["specular"]
	
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	generator.material_override = material
	print("MarchingCubesAPI: ✅ Applied material '%s' to '%s'" % [key, object.name])

static func list_available_shapes() -> Array:
	return SHAPE_MAP.keys()

static func _try_set_property(obj: Object, prop: String, value) -> void:
	if obj == null:
		return
	var props = obj.get_property_list()
	for p in props:
		if typeof(p) == TYPE_DICTIONARY and p.has("name") and str(p["name"]) == prop:
			obj.set(prop, value)
			return
