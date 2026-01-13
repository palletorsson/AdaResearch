@tool
extends Node3D

## Select which set of primitives to display (0-3)
@export var active_set: int = 0:
	set(value):
		active_set = clamp(value, 0, 3)
		if Engine.is_editor_hint() or is_inside_tree():
			_update_display()

## Grid layout settings
@export var grid_spacing: float = 2.0
@export var grid_columns: int = 8
@export var primitive_scale: float = 0.5

# All primitive scenes organized into 4 sets
var primitive_sets: Array[Array] = []

func _ready():
	_setup_primitive_sets()
	_update_display()

func _setup_primitive_sets():
	# Set 0: Basic geometric shapes
	primitive_sets.append([
		"res://commons/primitives/cube/cube.tscn",
		"res://commons/primitives/sphere/sphere.tscn",
		"res://commons/primitives/cylinder/cylinder.tscn",
		"res://commons/primitives/cylinder/cone.tscn",
		"res://commons/primitives/pyramid/pyramid.tscn",
		"res://commons/primitives/tetrahedron/tetrahedron.tscn",
		"res://commons/primitives/octahedron/octahedron.tscn",
		"res://commons/primitives/icosahedron/icosahedron.tscn",
		"res://commons/primitives/dodecahedron/dodecahedron.tscn",
		"res://commons/primitives/trihedron/trihedron.tscn",
		"res://commons/primitives/triangularprism/triangularprism.tscn",
		"res://commons/primitives/torus/torus.tscn",
		"res://commons/primitives/capsule/capsule.tscn",
		"res://commons/primitives/diamond/diamond.tscn",
		"res://commons/primitives/star/star.tscn",
		"res://commons/primitives/truncatedtetrahedron/truncatedtetrahedron.tscn",
		"res://commons/primitives/bipyramid/bipyramid.tscn",
		"res://commons/primitives/steppedpyramid/steppedpyramid.tscn",
		"res://commons/primitives/mengersponge/mengersponge.tscn",
		"res://commons/primitives/kochsnowflake/kochsnowflake.tscn",
		"res://commons/primitives/arch/arch.tscn",
		"res://commons/primitives/arrow/arrow.tscn",
		"res://commons/primitives/plane/plane.tscn",
		"res://commons/primitives/quad/quad.tscn",
		"res://commons/primitives/triangle/triangle.tscn",
		"res://commons/primitives/lefttriangle/lefttriangle.tscn",
		"res://commons/primitives/righttriangle/righttriangle.tscn",
		"res://commons/primitives/pillar/pillar.tscn",
		"res://commons/primitives/prism/prism.tscn",
		"res://commons/primitives/prismblock/prismblock.tscn",
		"res://commons/primitives/triangularblock/triangularblock.tscn",
		"res://commons/primitives/unitcube/unitcube.tscn",
	])
	
	# Set 1: Modified cubes and blocks
	primitive_sets.append([
		"res://commons/primitives/roundedcube/roundedcube.tscn",
		"res://commons/primitives/slantedcube/slantedcube.tscn",
		"res://commons/primitives/rectcube/rectcube.tscn",
		"res://commons/primitives/walledcube/walledcube.tscn",
		"res://commons/primitives/halocube/halocube.tscn",
		"res://commons/primitives/boxbeam/boxbeam.tscn",
		"res://commons/primitives/lshape/lshape.tscn",
		"res://commons/primitives/lshape/l_shape.tscn",
		"res://commons/primitives/prismes/prism_block.tscn",
		"res://commons/primitives/prismes/rotating_prisme.tscn",
		"res://commons/primitives/johnsonsolids/square_pyramid.tscn",
		"res://commons/primitives/johnsonsolids/triangular_cupola.tscn",
		"res://commons/primitives/modernpolysolid/modernpolysolid.tscn",
	])
	
	# Set 2: Organic and procedural shapes
	primitive_sets.append([
		"res://commons/primitives/crystal/crystal.tscn",
		"res://commons/primitives/crystalcluster/crystalcluster.tscn",
		"res://commons/primitives/rock/rock.tscn",
		"res://commons/primitives/roughrock/roughrock.tscn",
		"res://commons/primitives/hollowrock/hollowrock.tscn",
		"res://commons/primitives/proceduralrock/proceduralrock.tscn",
		"res://commons/primitives/cave/cave.tscn",
		"res://commons/primitives/fish_tank/fish_tank.tscn",
		"res://commons/primitives/triangleprofiles/triangleprofiles.tscn",
		"res://commons/primitives/zigzagprofile/zigzagprofile.tscn",
		"res://commons/primitives/foldedpaper/foldedpaper.tscn",
		"res://commons/primitives/folded_strip/folded_strip.tscn",
	])
	
	# Set 3: Parametric and mathematical surfaces
	primitive_sets.append([
		"res://commons/primitives/parametric/parametric.tscn",
		"res://commons/primitives/parametric/mobius_strip.tscn",
		"res://commons/primitives/parametric/klein_bottle.tscn",
		"res://commons/primitives/parametric/seashell.tscn",
		"res://commons/primitives/parametric/wave_torus.tscn",
		"res://commons/primitives/parametric/dini_surface.tscn",
		"res://commons/primitives/parametric/enneper_order3.tscn",
		"res://commons/primitives/parametric/double_enneper.tscn",
		"res://commons/primitives/parametric/math_objects.tscn",
		"res://commons/primitives/booleans/dome.tscn",
		"res://commons/primitives/origin/origin.tscn",
		"res://commons/primitives/portal/portal.tscn",
		"res://commons/primitives/entrances/level_entrance.tscn",
		"res://commons/primitives/menu/menu.tscn",
		"res://commons/primitives/chair/chair.tscn",
		"res://commons/primitives/chair/chair_modern.tscn",
		"res://commons/primitives/chair/chair_throne.tscn",
		"res://commons/primitives/modernchair/modernchair.tscn",
		"res://commons/primitives/sofa/sofa.tscn",
		"res://commons/primitives/mesh_draw/SDFDrawTool.tscn",
		"res://commons/primitives/positionlabel/positionlabel.tscn",
	])

func _update_display():
	# Clear existing instances
	for child in get_children():
		if child.name.begins_with("Primitive_"):
			child.queue_free()
	
	# Wait for cleanup
	await get_tree().process_frame
	
	# Get the active set
	if active_set < 0 or active_set >= primitive_sets.size():
		return
	
	var primitives = primitive_sets[active_set]
	if primitives.is_empty():
		return
	
	# Create grid layout
	var row = 0
	var col = 0
	
	for i in range(primitives.size()):
		var scene_path = primitives[i]
		
		# Check if scene exists
		if not ResourceLoader.exists(scene_path):
			print("Warning: Scene not found: ", scene_path)
			continue
		
		# Load and instance the scene
		var scene = load(scene_path) as PackedScene
		if not scene:
			print("Warning: Could not load scene: ", scene_path)
			continue
		
		var instance = scene.instantiate()
		if not instance:
			print("Warning: Could not instantiate scene: ", scene_path)
			continue
		
		instance.name = "Primitive_%d_%d" % [row, col]
		
		# Calculate grid position
		var x = col * grid_spacing
		var z = row * grid_spacing
		instance.position = Vector3(x, 0, z)
		instance.scale = Vector3(primitive_scale, primitive_scale, primitive_scale)
		
		add_child(instance)
		
		# Move to next grid position
		col += 1
		if col >= grid_columns:
			col = 0
			row += 1
	
	print("Shapes Test: Displayed set %d with %d primitives" % [active_set, primitives.size()])
