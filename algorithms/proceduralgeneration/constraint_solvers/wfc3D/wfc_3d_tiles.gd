@tool
extends EditorScript

# Creates a set of 3D tiles with sockets for WFC
# Run this script (File -> Run) to generate "prototypes_3d.tscn"

const TILE_SIZE = 2.0
const TILE_HEIGHT = 1.0 # Half height for gentle slopes

func _run() -> void:
	var root = Node3D.new()
	root.name = "Prototypes3D"
	
	# Sockets Logic:
	# "rough" = General land surface (Dirt, Stone, Grass, Sand). Can stack.
	# "water_top" = Surface of water.
	# "sky" = High air.
	
	var spacing = 4.0
	
	# 1. AIR (Universal Empty Space)
	# ny="rough" (Sits on Land/Air). py="rough" (Supports Air/Stone? No, we trust gravity generation).
	# To prevent floating stone, we relying on the fact that Stone has weight 4 and Air has weight 10.
	# But technically, Stone COULD spawn on Air.
	# For this demo, robustness > strict gravity.
	create_tile(root, "Air", Color(0,0,0,0), {
		"px": "rough", "nx": "rough", 
		"py": "rough", "ny": "rough",  
		"pz": "rough", "nz": "rough"
	}, false, Vector3(0, 0, 0), 10.0)
	
	# 1.2 AIR OVER WATER (Adapter)
	create_tile(root, "Air_Water", Color(0,0,0,0), {
		"px": "rough", "nx": "rough", 
		"py": "rough", "ny": "water_top", 
		"pz": "rough", "nz": "rough"
	}, false, Vector3(0, 10, 0), 10.0)

	# 2. GRASS BLOCK
	var grass_meta = {
		"px": "rough", "nx": "rough",
		"py": "rough", "ny": "rough",
		"pz": "rough", "nz": "rough"
	}
	create_tile(root, "Grass", Color(0.2, 0.8, 0.2), grass_meta, true, Vector3(spacing * 1, 0, 0), 5.0)
	
	# 3. DIRT BLOCK
	var dirt_meta = {
		"px": "rough", "nx": "rough",
		"py": "rough", "ny": "rough",
		"pz": "rough", "nz": "rough"
	}
	create_tile(root, "Dirt", Color(0.4, 0.25, 0.1), dirt_meta, true, Vector3(spacing * 2, 0, 0), 2.0)
	
	# 4. WATER BLOCK
	var water_meta = {
		"px": "rough", "nx": "rough",
		"py": "water_top", "ny": "rough",
		"pz": "rough", "nz": "rough"
	}
	create_water_tile(root, "Water", Color(0.1, 0.3, 0.9, 0.8), water_meta, Vector3(spacing * 3, 0, 0), 5.0)
	
	# 4.5 SAND (Shore)
	var sand_meta = {
		"px": "rough", "nx": "rough",
		"py": "rough", "ny": "rough",
		"pz": "rough", "nz": "rough"
	}
	create_tile(root, "Sand", Color(0.76, 0.7, 0.5), sand_meta, true, Vector3(spacing * 3.5, 0, 0), 3.0)
	
	# 5. STONE/CLIFF
	var stone_meta = {
		"px": "rough", "nx": "rough",
		"py": "rough", "ny": "rough",
		"pz": "rough", "nz": "rough"
	}
	create_tile(root, "Stone", Color(0.5, 0.5, 0.5), stone_meta, true, Vector3(spacing * 4, 0, 0), 4.0)
	
	# 6. GRASS CLIFF
	var grass_cliff_meta = {
		"px": "rough", "nx": "rough",
		"py": "rough", "ny": "rough",
		"pz": "rough", "nz": "rough"
	}
	create_tile(root, "Grass_Cliff", Color(0.3, 0.7, 0.3), grass_cliff_meta, true, Vector3(spacing * 5, 0, 0), 1.0)
	
	# 7. STONE ANGLE/SLOPE
	# Updated to use "rough" everywhere for max compatibility
	
	# Slope_N (-Z High)
	create_slope(root, "Slope_N", Color(0.55, 0.55, 0.55), Vector3(0, 90, 0), 0.0, {
		"px": "rough", "nx": "rough",    
		"py": "rough", "ny": "rough",  
		"pz": "rough", "nz": "rough"   
	}, Vector3(spacing * 6, 0, 0), 0.5)

	# Slope_S (+Z High, -Z Low)
	create_slope(root, "Slope_S", Color(0.55, 0.55, 0.55), Vector3(0, -90, 0), 0.0, {
		"px": "rough", "nx": "rough",
		"py": "rough", "ny": "rough",
		"pz": "rough", "nz": "rough"     
	}, Vector3(spacing * 7, 0, 0), 0.5)
	
	# Slope_E (+X High, -X Low)
	create_slope(root, "Slope_E", Color(0.55, 0.55, 0.55), Vector3(0, 180, 0), 0.0, {
		"px": "rough", "nx": "rough",    
		"py": "rough", "ny": "rough",
		"pz": "rough", "nz": "rough"
	}, Vector3(spacing * 8, 0, 0), 0.5)
	
	# Slope_W (-X High, +X Low)
	create_slope(root, "Slope_W", Color(0.55, 0.55, 0.55), Vector3(0, 0, 0), 0.0, {
		"px": "rough", "nx": "rough",  
		"py": "rough", "ny": "rough",
		"pz": "rough", "nz": "rough"
	}, Vector3(spacing * 9, 0, 0), 0.5)

	# PACK AND SAVE
	var scene = PackedScene.new()
	scene.pack(root)
	var path = "res://algorithms/proceduralgeneration/wfc3D/prototypes_3d.tscn"
	var save_ok = ResourceSaver.save(scene, path)
	if save_ok == OK:
		print("✅ Saved 3D tiles to " + path)
	else:
		push_error("Failed to save tiles!")

func create_tile(parent, name, color, sockets, visible=true, pos=Vector3.ZERO, weight=1.0) -> void:
	var node = Node3D.new()
	node.name = name
	node.set_meta("sockets", sockets)
	node.set_meta("weight", weight)
	node.position = pos
	
	if visible:
		var csg = CSGBox3D.new()
		csg.size = Vector3(TILE_SIZE, TILE_HEIGHT, TILE_SIZE) # Half height
		csg.position = Vector3(0, 0, 0) # Center
		csg.use_collision = true # Enable collision for solid blocks
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		csg.material = mat
		node.add_child(csg)
		csg.owner = node 
	
	node.add_to_group("tile_3d")
	parent.add_child(node)
	node.owner = parent
	set_owner_params(node, parent)

func create_slope(parent, name, color, rotation_degrees, left_to_right, sockets, pos=Vector3.ZERO, weight=1.0) -> void:
	var node = Node3D.new()
	node.name = name
	node.set_meta("sockets", sockets)
	node.set_meta("weight", weight)
	node.position = pos
	
	var csg = CSGMesh3D.new()
	var mesh = PrismMesh.new()
	mesh.size = Vector3(TILE_SIZE, TILE_HEIGHT, TILE_SIZE) # Half height
	mesh.left_to_right = left_to_right
	csg.mesh = mesh
	csg.use_collision = true # Enable collision for slopes
	
	# Pure rotation from argument, no extra offsets.
	csg.rotation_degrees = rotation_degrees
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	csg.material = mat
	
	node.add_child(csg)
	node.add_to_group("tile_3d")
	parent.add_child(node)
	node.owner = parent
	set_owner_params(node, parent)


func create_water_tile(parent, name, color, sockets, pos=Vector3.ZERO, weight=1.0) -> void:
	var node = Node3D.new()
	node.name = name
	node.set_meta("sockets", sockets)
	node.set_meta("weight", weight)
	node.position = pos
	
	var csg = CSGBox3D.new()
	csg.size = Vector3(TILE_SIZE, TILE_HEIGHT * 0.8, TILE_SIZE) # Slightly lower
	csg.position = Vector3(0, -TILE_HEIGHT * 0.1, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	csg.material = mat
	
	node.add_child(csg)
	node.add_to_group("tile_3d")
	parent.add_child(node)
	node.owner = parent
	set_owner_params(node, parent)

func set_owner_params(node, owner_node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		set_owner_params(child, owner_node)


