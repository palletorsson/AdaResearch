@tool
extends XRToolsPickable

# Wave Parameters
@export var speed: float = 0.5 # Radians per second
@export var radius_x: float = 15.0 # Long axis
@export var radius_z: float = 8.0 # Short axis
@export var track_height_offset: float = 2.0 # Height of track relative to stick
@export var start_delay: float = 5.0 # Wait 5s before moving
@export var draw_track: bool = true

# State
var time_accum: float = 0.0
var center_pos: Vector3
var start_angle: float = PI # Start at back of loop

# Movement State
var last_track_pos: Vector3 = Vector3.ZERO
var is_riding: bool = false
var last_origin: Node3D = null
var player_body: Node = null  # XRToolsPlayerBody - disabled while riding

# Child node for the track visual
var track_visual: MeshInstance3D



# Magic Carpet (Invisible Floor)
var magic_carpet: AnimatableBody3D

func _create_magic_carpet():
	if magic_carpet:
		return
		
	magic_carpet = AnimatableBody3D.new()
	magic_carpet.name = "MagicCarpet"
	magic_carpet.sync_to_physics = false # Disabled: Let manual XROrigin transport handle movement, not platform physics
	
	var shape = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = 1.5 # Enlarged from 0.5 to catch player reliably
	cylinder.height = 0.05
	shape.shape = cylinder
	
	magic_carpet.add_child(shape)
	
	# Debug Mesh (Visual Confirmation)
	# TODO: Remove or make invisible once confirmed working
	var mesh_inst = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 1.5
	mesh.bottom_radius = 1.5
	mesh.height = 0.05
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.0, 0.0, 0.3) # Translucent Red
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	magic_carpet.add_child(mesh_inst)
	
	# Add as child but set top_level so it ignores parent transform (prevents jitter)
	add_child(magic_carpet)
	magic_carpet.top_level = true
	
	# Initial pos
	_update_magic_carpet()

func _update_magic_carpet():
	if magic_carpet:
		# Place floor 1.2m below the stick (Reduced from 1.4m to be closer to feet)
		magic_carpet.global_position = global_position - Vector3(0, 1.2, 0)
		# Keep rotation flat
		magic_carpet.global_rotation = Vector3.ZERO

func _ready():
	super._ready()
	
	if Engine.is_editor_hint():
		return
		
	# Configure RigidBody for Kinematic-like movement (Frozen but moveable)
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	gravity_scale = 0.0
	
	# Create Safety Floor
	_create_magic_carpet()
	
	# Calculate center position so that current position is exactly at start_angle
	# P = Center + Offset
	# Center = P - Offset
	var initial_offset = _get_oval_offset(start_angle)
	center_pos = global_position - initial_offset
	
	if draw_track:
		_generate_track_visual()
		_generate_hanger_visual()
		
	# Connect signals to handle collision layers when held
	if has_signal("picked_up"):
		connect("picked_up", _on_picked_up)
	if has_signal("dropped"):
		connect("dropped", _on_dropped)

func _on_picked_up(_pickable):
	# Disable collision to prevent "standing on held object" physics loops
	collision_layer = 0
	collision_mask = 0

	# Initialise Ride State
	is_riding = true

	# Calculate where the stick SHOULD be on the track right now
	# We rely on time_accum being preserved or starting fresh?
	# Assuming continuous loop, time_accum continues.
	# We set last_track_pos to the CURRENT valid calculation, so delta starts from 0 next frame.
	var angle = start_angle + (time_accum * speed)
	last_track_pos = center_pos + _get_oval_offset(angle)

	# Find the player origin for transport
	var picker = get_picked_up_by()
	if picker and is_instance_valid(picker):
		last_origin = XRHelpers.get_xr_origin(picker)

		# Disable PlayerBody physics while riding (Option B: Seat Mode)
		player_body = _find_player_body(last_origin)
		if player_body:
			player_body.enabled = false

func _on_dropped(_pickable):
	# Restore collision
	collision_layer = 1
	collision_mask = 1
	is_riding = false
	last_origin = null

	# Re-enable PlayerBody physics
	if player_body and is_instance_valid(player_body):
		player_body.enabled = true
		player_body = null

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
		
	# Always update carpet position if it exists, so it stays with stick
	# Even if not riding, it should be there? Or only when riding?
	# User: "attach a invissblr small floor under the stick"
	# Best to keep it synced.
	_update_magic_carpet()
		
	# Only ride if held and valid state
	if not is_riding or not is_picked_up():
		return
		
	# 1. Advance Simulation Time
	time_accum += delta
	var angle = start_angle + (time_accum * speed)
	
	# 2. Calculate Pure Track Position (Target)
	var current_track_pos = center_pos + _get_oval_offset(angle)
	
	# 3. Calculate Delta from LAST frame's track position
	# This represents "How much did the track move since last frame?"
	# We rely on last_track_pos being accurate from internal logic, ignore physics drift.
	var delta_move = current_track_pos - last_track_pos
	
	# 4. Apply Delta to Stick (Force adherence to track)
	global_position = current_track_pos
	rotation = Vector3.ZERO 
	
	# 5. Apply Delta to Player Origin (Transport Player)
	if last_origin and is_instance_valid(last_origin):
		last_origin.global_position += delta_move
		
	# Update state
	last_track_pos = current_track_pos

func _get_oval_offset(angle: float) -> Vector3:
	var x = cos(angle) * radius_x
	var z = sin(angle) * radius_z
	return Vector3(x, 0, z)

func _generate_track_visual():
	# Create a static mesh for the track
	var mesh_inst = MeshInstance3D.new()
	var mesh = ImmediateMesh.new()
	
	# Create a high-visibility material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(1.0, 1.0, 1.0)
	# Thick lines not supported in Godot 4 standard/Vulkan easily, but we use lines.
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var segments = 120
	for i in range(segments + 1):
		var theta = (float(i) / segments) * TAU
		var p1 = _get_oval_offset(theta)
		p1.y += track_height_offset # Use export variable
		
		if i > 0:
			var theta_prev = (float(i-1) / segments) * TAU
			var p0 = _get_oval_offset(theta_prev)
			p0.y += track_height_offset # Use export variable
			
			mesh.surface_set_color(Color(0.8, 0.2, 0.8))
			mesh.surface_add_vertex(p0)
			mesh.surface_add_vertex(p1)
			
	mesh.surface_end()
	
	mesh_inst.mesh = mesh
	mesh_inst.material_override = material # Apply unshaded material
	
	add_child(mesh_inst)
	mesh_inst.top_level = true
	mesh_inst.global_position = center_pos

func _generate_hanger_visual():
	# Create a thin vertical cylinder connecting the stick to the track
	# Height = track_height_offset
	# Position.y = track_height_offset / 2.0 (since cylinder origin is center)

	if track_height_offset <= 0.1:
		return

	var hanger_mesh = CylinderMesh.new()
	hanger_mesh.top_radius = 0.01
	hanger_mesh.bottom_radius = 0.01
	hanger_mesh.height = track_height_offset

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = hanger_mesh
	mesh_inst.position.y = track_height_offset / 2.0

	# Add visually distinct material if desired, or default
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.5) # Grey metal rod
	material.metallic = 0.8
	material.roughness = 0.2
	mesh_inst.material_override = material

	add_child(mesh_inst)

func _find_player_body(origin: Node3D) -> Node:
	# Use XRToolsPlayerBody's static finder if available
	if origin:
		for child in origin.get_children():
			if child.has_method("is_xr_class") and child.is_xr_class("XRToolsPlayerBody"):
				return child
	return null


