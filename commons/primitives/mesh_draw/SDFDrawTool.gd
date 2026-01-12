extends "res://addons/godot-xr-tools/objects/pickable.gd"

# SDF Draw Tool (Digital Clay Brush)
# Interaction:
# - Pick up tool
# - Press Trigger (action_button_action) to draw
# - Drawing adds "Blobs" to the active TerrainGeneratorSculpt

@export var blob_radius: float = 0.1
@export var blob_density: float = 0.05 # Minimum distance between blobs

var _active_generator: TerrainGeneratorSculpt
var _last_blob_pos: Vector3 = Vector3.INF

# Draw Tip
@onready var draw_tip: Marker3D = $DrawTip

func _ready():
	super._ready()
	print("SDFDrawTool: Ready")

func _process(delta):
	# Handle VR Input (Trigger)
	# Assuming 'by_controller' is set when picked up (XRToolsPickable)
	var controller = get_picked_up_by_controller()
	if controller:
		var trigger_val = controller.get_float("trigger")
		if trigger_val > 0.5:
			_draw(delta)
		else:
			_last_blob_pos = Vector3.INF # Reset stroke

func _draw(delta):
	if not _active_generator:
		_spawn_generator()
		
	var tip_global = draw_tip.global_position
	# Convert to local space of generator (which is usually at 0,0,0 initially but might move)
	# Actually, terrain generator works in its own local space centered at 0 or 'center_position'.
	# Shader uses 'posX/Y/Z' to determine which chunk to render.
	# But wait, our 'blobs' in shader are subtracted from 'worldPos'.
	# 'worldPos' in shader is: coord / resolution * scale + centerSnapped.
	# So blob positions must be in WORLD SPACE if the shader assumes worldPos.
	# Or local space if the mesh node is transformed.
	# Usually MC mesh is at (0,0,0) global.
	
	# Let's assume World Space for simplicity in the shader. 
	# (Shader: float d = length(p - blob.xyz) - blob.w)
	# So we pass draw_tip.global_position directly.
	
	if tip_global.distance_to(_last_blob_pos) > blob_density:
		_active_generator.add_blob(tip_global, blob_radius)
		_last_blob_pos = tip_global
		# print("Tool: Added blob at ", tip_global)

func _spawn_generator():
	# Check if one exists nearby? Or just create one.
	# For prototype, check if any exists in scene called "Sculpture"
	var existing = get_tree().root.find_child("MC_Sculpture", true, false)
	if existing:
		var gen = existing.get_node_or_null("Generator")
		if gen and gen is TerrainGeneratorSculpt:
			_active_generator = gen
			return

	# Create new
	print("Tool: Spawning new MC_Sculpture...")
	var container = Node3D.new()
	container.name = "MC_Sculpture"
	get_tree().root.add_child(container)
	container.global_position = Vector3.ZERO
	
	var gen = TerrainGeneratorSculpt.new()
	gen.name = "Generator"
	# Configure
	gen.chunk_scale = 50.0 # Size of the volume box
	gen.center_position = draw_tip.global_position # Center on first draw
	gen.num_voxels_per_axis = 64 # Reasonable res
	gen.iso_level = 0.0
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.4, 0.2) # Clay color
	mat.roughness = 0.8
	gen.material_override = mat
	
	container.add_child(gen)
	_active_generator = gen

