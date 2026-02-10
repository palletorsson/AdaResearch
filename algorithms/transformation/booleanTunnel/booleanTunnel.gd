extends Node3D

@export var cube_scene: PackedScene = preload("res://algorithms/primitives/booleans/booleanHollowCube.tscn")
var teleport_scene: PackedScene = preload("res://commons/scenes/mapobjects/teleport_scene.tscn")
@export var num_segments: int = 18
@export var spacing: float = 3.0
@export var rotation_per_segment: float = 10.0  # degrees
@export var cube_height: float = 4.0  # height of the cube for pivot compensation
@export var cube_base_rotation_z: float = 0.0  # base rotation for each cube (degrees)

@export_group("Cone Taper")
@export var cone_mode: bool = false  # taper from start to end
@export var start_scale: float = 1.0  # scale at tunnel entrance
@export var end_scale: float = 0.4  # scale at tunnel exit (smaller = narrower)
@export_group("Tunnel Orientation")
@export var tunnel_rotation_x: float = 0.0  # rotate whole tunnel around X (degrees) - use -90 to stand up
@export var tunnel_rotation_z: float = 0.0  # rotate whole tunnel around Z (degrees) - turns sideways

@export_group("Burst Pattern")
@export var burst_mode: bool = false  # alternate between rotating and flat sections
@export var burst_rotate_count: int = 3  # cubes per rotating burst
@export var burst_flat_count: int = 3  # flat cubes between bursts

@export_group("End Teleporter")
@export var enable_teleporter: bool = false  # add teleporter at tunnel end
@export var teleport_destination: Vector3 = Vector3(0, 1, 0)  # where to send player
@export var teleporter_label: String = "Exit"  # label shown on teleporter

var _config_applied := false
var _generated := false

func _ready():
	# Wait multiple frames for apply_grid_config to potentially be called (it uses call_deferred)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if not _config_applied and not _generated:
		# No config was applied, generate with defaults
		print("BooleanTunnel: No config received, generating with defaults")
		generate_tunnel()

func apply_grid_config(config: Dictionary):
	print("BooleanTunnel: Applying grid config: %s" % str(config))
	_config_applied = true
	
	# Apply basic parameters
	if config.has("num_segments"):
		num_segments = int(config["num_segments"])
	if config.has("spacing"):
		spacing = float(config["spacing"])
	if config.has("rotation_per_segment"):
		rotation_per_segment = float(config["rotation_per_segment"])
	if config.has("cube_height"):
		cube_height = float(config["cube_height"])
	if config.has("cube_base_rotation_z"):
		cube_base_rotation_z = float(config["cube_base_rotation_z"])
	
	# Tunnel orientation
	if config.has("tunnel_rotation_x"):
		tunnel_rotation_x = float(config["tunnel_rotation_x"])
	if config.has("tunnel_rotation_z"):
		tunnel_rotation_z = float(config["tunnel_rotation_z"])
	
	# Burst pattern
	if config.has("burst_mode"):
		burst_mode = str(config["burst_mode"]).to_lower() == "true"
	if config.has("burst_rotate_count"):
		burst_rotate_count = int(config["burst_rotate_count"])
	if config.has("burst_flat_count"):
		burst_flat_count = int(config["burst_flat_count"])
	
	# Cone taper
	if config.has("cone_mode"):
		cone_mode = str(config["cone_mode"]).to_lower() == "true"
	if config.has("start_scale"):
		start_scale = float(config["start_scale"])
	if config.has("end_scale"):
		end_scale = float(config["end_scale"])
	
	# Teleporter
	if config.has("enable_teleporter"):
		enable_teleporter = str(config["enable_teleporter"]).to_lower() == "true"
	if config.has("teleporter_label"):
		teleporter_label = str(config["teleporter_label"])
	if config.has("teleport_destination"):
		var dest_str = str(config["teleport_destination"])
		var parts = dest_str.split(",")
		if parts.size() >= 3:
			teleport_destination = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	
	print("BooleanTunnel: Config applied - enable_teleporter=%s, destination=%s" % [enable_teleporter, teleport_destination])
	
	# Regenerate with new config
	generate_tunnel()

func generate_tunnel():
	_generated = true
	print("BooleanTunnel: Generating tunnel with settings:")
	print("  - num_segments: %d" % num_segments)
	print("  - burst_mode: %s" % burst_mode)
	print("  - burst_rotate_count: %d" % burst_rotate_count)
	print("  - burst_flat_count: %d" % burst_flat_count)
	print("  - tunnel_rotation_x: %.1f" % tunnel_rotation_x)
	print("  - cone_mode: %s (%.1f → %.1f)" % [cone_mode, start_scale, end_scale])
	print("  - enable_teleporter: %s" % enable_teleporter)
	
	# Clear existing children
	for child in get_children():
		child.queue_free()

	var accumulated_angle_deg: float = 0.0
	
	for i in range(num_segments):
		var cube_instance = cube_scene.instantiate()
		add_child(cube_instance)

		# Calculate rotation angle
		var angle_deg: float
		if burst_mode:
			# Determine which section we're in (rotating or flat)
			var cycle_length = burst_rotate_count + burst_flat_count
			var pos_in_cycle = i % cycle_length
			var is_rotating = pos_in_cycle < burst_rotate_count
			
			if is_rotating:
				# Add rotation during rotating burst
				if pos_in_cycle > 0:
					accumulated_angle_deg += rotation_per_segment
				angle_deg = accumulated_angle_deg
			else:
				# Hold angle during flat section
				angle_deg = accumulated_angle_deg
			
			# Advance accumulated angle at the end of rotating section
			if pos_in_cycle == burst_rotate_count - 1:
				accumulated_angle_deg += rotation_per_segment
		else:
			angle_deg = i * rotation_per_segment
		
		var angle_rad = deg_to_rad(angle_deg)

		# Position along z-axis
		var z_pos = i * spacing

		# Compensate for bottom pivot rotation
		# When rotating around Z-axis with pivot at bottom, the center moves
		# We need to offset X and Y to keep the tunnel aligned
		var half_height = cube_height / 2.0
		var x_offset = half_height * sin(angle_rad)
		var y_offset = half_height * (1.0 - cos(angle_rad))

		# Create transform with rotation around Z-axis
		var transform_3d = Transform3D()
		
		# Apply optional base rotation to each cube
		if cube_base_rotation_z != 0.0:
			transform_3d = transform_3d.rotated(Vector3(0, 0, 1), deg_to_rad(cube_base_rotation_z))
		
		transform_3d = transform_3d.rotated(Vector3(0, 0, 1), angle_rad)

		# Apply position with compensation
		transform_3d.origin = Vector3(x_offset, y_offset, z_pos)

		cube_instance.transform = transform_3d
		cube_instance.name = "Cube" + str(i)
		
		# Apply cone taper scaling
		if cone_mode and num_segments > 1:
			var t = float(i) / float(num_segments - 1)  # 0 at start, 1 at end
			var scale_factor = lerp(start_scale, end_scale, t)
			cube_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
	
	# Apply whole-tunnel rotation
	if tunnel_rotation_x != 0.0 or tunnel_rotation_z != 0.0:
		rotation_degrees.x = tunnel_rotation_x
		rotation_degrees.z = tunnel_rotation_z
	
	# Add teleporter at the end if enabled
	if enable_teleporter:
		_create_end_teleporter()

func _create_end_teleporter():
	var teleporter = teleport_scene.instantiate()
	teleporter.name = "EndTeleporter"
	
	# Position inside the last hollow cube
	var last_cube_z = (num_segments - 1) * spacing
	
	# Get the last cube's rotation to match position offset
	var last_angle_deg: float
	if burst_mode:
		var cycle_length = burst_rotate_count + burst_flat_count
		var full_cycles = (num_segments - 1) / cycle_length
		var remainder = (num_segments - 1) % cycle_length
		var rotating_segments = full_cycles * burst_rotate_count + min(remainder, burst_rotate_count)
		last_angle_deg = rotating_segments * rotation_per_segment
	else:
		last_angle_deg = (num_segments - 1) * rotation_per_segment
	
	var last_angle_rad = deg_to_rad(last_angle_deg)
	var half_height = cube_height / 2.0
	var x_offset = half_height * sin(last_angle_rad)
	var y_offset = half_height * (1.0 - cos(last_angle_rad))
	
	teleporter.position = Vector3(x_offset, y_offset, last_cube_z)
	
	# Configure the teleporter
	if teleporter_label != "":
		teleporter.scene_name = teleporter_label
	
	# Connect to its activation signal
	teleporter.teleporter_activated.connect(_on_teleporter_activated)
	
	add_child(teleporter)
	print("BooleanTunnel: Created end teleporter at z=%.1f, destination=%s" % [last_cube_z, teleport_destination])

func _on_teleporter_activated():
	# Find and teleport the player
	var player_root = _find_player_in_scene()
	if player_root:
		print("BooleanTunnel: Teleporting player to %s" % teleport_destination)
		player_root.global_position = teleport_destination
		
		# Reset velocity if possible
		if "velocity" in player_root:
			player_root.velocity = Vector3.ZERO
		if "linear_velocity" in player_root:
			player_root.linear_velocity = Vector3.ZERO
	else:
		print("BooleanTunnel: Could not find player to teleport")

func _find_player_in_scene() -> Node3D:
	# Try common player detection methods
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player
	
	player = get_tree().get_first_node_in_group("player_body")
	if player:
		return _find_player_root(player)
	
	# Look for XROrigin
	var root = get_tree().current_scene
	if root:
		var xr_origin = root.find_child("XROrigin3D", true, false)
		if xr_origin:
			return xr_origin
	
	return null

func _find_player_root(body: Node3D) -> Node3D:
	if not body:
		return null
	var current = body
	while current:
		if current.is_in_group("player") or current.name.contains("XROrigin"):
			return current
		current = current.get_parent()
	# Check if body itself is player-like
	if body is CharacterBody3D or body.is_in_group("player_body"):
		return body
	return null
