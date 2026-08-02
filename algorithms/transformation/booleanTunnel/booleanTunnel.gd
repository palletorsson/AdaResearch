extends Node3D
class_name BooleanTunnel

# @identity
# essence: hollow_cube[i].rotation_z += i * rotation_per_segment — accumulating rotation carves a twisted corridor
# desire: learner walks through a tunnel whose walls rotate and understands rotation as spatial grammar
# critical_parameter: rotation_per_segment — how many degrees each segment adds; at 0° it is a straight box, at 10° a spiral
# triggers: burst mode toggle and cone taper parameters; optional teleporter at the end fires on entry
# emerges: the architectural experience of rotation as navigation — the body learns angles by moving through them
# needs: [has apply_grid_config [has], missing live VR slider for rotation_per_segment]
# relationships: used as boolean_tunnel in Trans_RotationSpectacle; sibling to hole_with_cones (Boolean topology)
# truth: accumulated rotation is non-linear — each segment adds to all previous, so the total diverges quickly

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

# ── STAGE-2 DNA ───────────────────────────────────────────────────────────────
## AXIS — ACCRUAL. How the local turn ADDS UP along the run. The tunnel's one claim is
## that a rule applied per segment becomes architecture; this axis is the rule, and it is
## the only thing here a still frame can hold, because the corridor never moves.
##
##   ramp      THE DEFAULT and the legacy lineage: every segment adds the same increment,
##             so the angle is i·Δ and the twist runs away — 130° of turn by the far end.
##             (Also the value that leaves `burst_mode` alone, whatever a map set it to.)
##   burst     rotate for three, hold for three: twisted stretches alternating with
##             straight ones. Accumulation with rests in it. Forces the existing
##             burst_mode on; the geometry is the one that export already built.
##   mirror    the increment reverses at the midpoint and the corridor unwinds back to
##             zero. You end facing exactly as you started, having turned the whole way —
##             a run that spends its transformation and returns the change.
##   plateau   each increment is three-quarters of the last, so the turn converges on a
##             limit (about 40°) instead of diverging. The corridor bends and then simply
##             stops bending: accumulation with an asymptote.
##   none      no rotation at all. A straight box run — repetition WITHOUT transformation,
##             which is the thing the other four are all being measured against.
##
## The teleporter, its destination and the collision cubes are untouched by this: what
## changes is which way the same fourteen boxes are turned.
@export_enum("ramp", "burst", "mirror", "plateau", "none") var accrual: String = "ramp"
const ACCRUALS: PackedStringArray = ["ramp", "burst", "mirror", "plateau", "none"]
## Ratio each successive increment is multiplied by under `plateau`. 0.75 → the total turn
## converges on 4·rotation_per_segment.
const PLATEAU_RATIO := 0.75

@export_group("End Teleporter")
@export var enable_teleporter: bool = false  # add teleporter at tunnel end
@export var teleport_destination: Vector3 = Vector3(0, 1, 0)  # where to send player
@export var teleporter_label: String = "Exit"  # label shown on teleporter

var _config_applied := false
var _generated := false

func _ready() -> void:
	# Wait multiple frames for apply_grid_config to potentially be called (it uses call_deferred)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if not _config_applied and not _generated:
		# No config was applied, generate with defaults
		print("BooleanTunnel: No config received, generating with defaults")
		generate_tunnel()

func apply_grid_config(config: Dictionary) -> void:
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

func generate_tunnel() -> void:
	_generated = true
	_read_dna()
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

		# ACCRUAL — an OVERRIDE appended after the legacy angle is computed, so the
		# ramp/burst path above is byte for byte what it always was. "ramp" and "burst"
		# fall through (burst is the legacy burst_mode, which _read_dna turned on).
		match accrual:
			"mirror":
				angle_deg = _angle_mirror(i)
			"plateau":
				angle_deg = _angle_plateau(i)
			"none":
				angle_deg = 0.0
			_:
				pass

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

	# Appended LAST, after every cube is placed: a zero-layer node that holds the
	# bounding box at the run's real extent. See _add_run_anchor for why.
	_add_run_anchor()


# ── ACCRUAL ───────────────────────────────────────────────────────────────────
# The axis is read from the map's config_<key> metadata (GridInteractablesComponent sets
# it BEFORE add_child) and normalised, so an unknown word keeps the default instead of
# silently rendering as one. Called from generate_tunnel, which is the single place both
# the deferred default path and apply_grid_config go through.
func _read_dna() -> void:
	if has_meta("config_accrual"):
		var a: String = str(get_meta("config_accrual")).strip_edges().to_lower()
		accrual = a if ACCRUALS.has(a) else accrual
	# `burst` IS the legacy burst_mode; the axis just names it. Nothing is turned OFF here,
	# so a map that already set burst_mode:true keeps it under the default `ramp`.
	if accrual == "burst":
		burst_mode = true


## MIRROR — the increment reverses at the midpoint, so the run winds up and unwinds back
## to zero. The far end faces exactly as the near end does, having turned the whole way.
func _angle_mirror(i: int) -> float:
	var last: int = maxi(num_segments - 1, 1)
	var half: float = float(last) * 0.5
	var step: float = float(i) if float(i) <= half else float(last - i)
	return step * rotation_per_segment * 2.0


## PLATEAU — each increment is PLATEAU_RATIO of the one before, so the total turn is a
## geometric series converging on rotation_per_segment / (1 - ratio). The corridor bends
## and then stops bending.
func _angle_plateau(i: int) -> float:
	var total: float = 0.0
	var step: float = rotation_per_segment
	for _k in range(i):
		total += step
		step *= PLATEAU_RATIO
	return total


## The capture rig fits the frame by the subtree's bounding-box DIAGONAL, and it walks the
## subtree for MeshInstance3D. This tunnel is built from CSGBox3D nested one level down
## inside instanced scenes, so that walk finds NOTHING and falls back to a 1 m box — a
## camera 5 m from the origin of a 42 m corridor, which is why the registry's measured
## aabb_size for this artifact is literally [0, 0, 0]. Every accrual value would have been
## photographed from inside the first cube.
##
## layers = 0, NOT visible = false: hiding a node hides its children with it, while a
## zero-layer VisualInstance3D is in no camera's cull mask, draws nothing, and still
## reports its AABB. The box is sized from num_segments and spacing alone, so it is
## IDENTICAL for all five accrual values — which is the point: the bite report must be a
## picture of the twist, not of a zoom.
##
## Its bottom sits exactly at y = 0 so GridInteractablesComponent._auto_ground_artifact
## reads "already grounded" and leaves the tunnel where it has always stood.
func _add_run_anchor() -> void:
	var run: float = float(maxi(num_segments - 1, 0)) * spacing + 4.0
	var anchor := MeshInstance3D.new()
	anchor.name = "RunAnchor"
	var box := BoxMesh.new()
	box.size = Vector3(10.0, 10.0, run)
	anchor.mesh = box
	anchor.position = Vector3(0.0, 5.0, run * 0.5 - 0.5)
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anchor)


func _create_end_teleporter() -> void:
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

func _on_teleporter_activated() -> void:
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
