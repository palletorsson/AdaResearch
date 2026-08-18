class_name ConfigurablePortal
extends Node3D

## Fully configurable portal - size, rotation, destination all via config
## Usage in map: configurable_portal#width:2#height:3#dest_x:5#dest_y:1#dest_z:10
## Or to another map: configurable_portal#dest_map:Trans_Rotation_2

# ─────────────────────────────────────────────────────────────────────────────
#   tell   WHAT THE THRESHOLD DISCLOSES OF THE FAR SIDE   mark · none · ghost · exemplar
#
#   mark      the legacy lineage, byte for byte — a lit energy field and a name
#             plate over the frame. It tells you THAT it goes, and what it is called.
#   none      a sealed opening: the field dark and inert, the plate blank. You
#             cannot tell from this side whether it goes anywhere at all.
#   ghost     the far side as an apparition — a translucent vestibule standing out
#             of the doorway on your side: floor, jambs and lintel of somewhere else
#   exemplar  the far side built solid at the threshold: the first metre of the
#             destination standing here, with a step, walls and something on its floor
#
# A door is the most-shared object in the corpus and the strongest axis measured so
# far is lab_sliding_door.welcome, which asks this same question of a sliding door.
# `tell` is the puzzle-family word — chair_assembly_puzzle and balance_puzzle carry
# it too — because a portal IS a puzzle whose answer is a place: how much of the
# other side you are allowed to know before you commit your body to it.
#
# Deliberately NOT routed through tell: the destination, the Area3D, the cooldown
# and the teleport. Every value goes to exactly the same place at exactly the same
# size. Only the disclosure changes — a sealed portal still works, it just lies.
#
# MEASUREMENT NOTE: the surface runs PinkTeleport.gdshader off TIME, so two captures
# taken a second apart differ whatever the axis does. `still_surface` freezes the
# phase (speeds and distortion to zero) so a sweep measures the axis instead of the
# clock; it defaults false and changes nothing in a map.
# ─────────────────────────────────────────────────────────────────────────────

signal portal_entered(destination: Dictionary)

@export_group("Size")
@export var portal_width: float = 1.5
@export var portal_height: float = 2.5
@export var portal_depth: float = 0.5  # Collision depth

@export_group("Position Offset")
@export var pos_offset: Vector3 = Vector3.ZERO  # Additional position offset from grid placement

@export_group("Rotation")
@export var rotation_x: float = 0.0
@export var rotation_y: float = 0.0
@export var rotation_z: float = 0.0

@export_group("Destination")
@export var destination_position: Vector3 = Vector3.ZERO  # Where to teleport in current map
@export var destination_map: String = ""  # Map to load (empty = stay in current map)
@export var destination_spawn: String = ""  # Named spawn point in destination map

@export_group("Appearance")
@export var portal_color_1: Color = Color(0.2, 0.6, 1.0, 1.0)
@export var portal_color_2: Color = Color(0.0, 0.8, 0.8, 1.0)
@export var frame_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var energy: float = 1.5
@export var label_text: String = ""
@export var show_frame: bool = true

## AXIS — WHAT THE THRESHOLD DISCLOSES OF THE FAR SIDE. Shared word for word with
## [[chair_assembly_puzzle]] and [[balance_puzzle]]: one vocabulary for how much of the
## answer is shown in advance. The destination, the trigger volume and the teleport are
## identical at every value.
##
##   mark      the legacy lineage — a lit field and a name plate: it goes, and it is called this
##   none      sealed: a dark inert opening and a blank plate, telling you nothing
##   ghost     a translucent vestibule of the far side standing out of the doorway
##   exemplar  the first metre of the destination built solid on this side of the threshold
@export var tell: String = "mark"
const TELLS: PackedStringArray = ["mark", "none", "ghost", "exemplar"]

## Freeze the surface animation (shader speeds + distortion to zero). Default false = the
## legacy lineage. A still capture of an animated surface measures the clock, not the axis;
## a sweep should set this so the frames it compares differ only by what was swept.
@export var still_surface: bool = false

@export_group("Behavior")
@export var active: bool = true
@export var cooldown: float = 1.0  # Seconds before can teleport again

# Internal
var _can_teleport: bool = true
var _area: Area3D
var _portal_mesh: MeshInstance3D
var _frame_node: Node3D
var _label: Label3D
var _collision_shape: CollisionShape3D

func _ready():
	_build_portal()
	
func _build_portal():
	# Clear existing children (for rebuild)
	for child in get_children():
		child.queue_free()
	# out-of-tree guard: get_tree() is null once a map is torn down mid-build
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	
	# Apply position offset
	position += pos_offset
	
	# Apply rotation to self
	rotation_degrees = Vector3(rotation_x, rotation_y, rotation_z)
	
	# Create Area3D for detection
	_area = Area3D.new()
	_area.name = "PortalArea"
	_area.collision_layer = 0
	_area.collision_mask = 524288  # Player layer
	_area.transform.origin = Vector3(0, portal_height / 2.0, 0)
	add_child(_area)
	
	# Collision shape
	_collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(portal_width, portal_height, portal_depth)
	_collision_shape.shape = box_shape
	_area.add_child(_collision_shape)
	
	# Connect signal
	_area.body_entered.connect(_on_body_entered)
	
	# Portal surface (quad with shader)
	_portal_mesh = MeshInstance3D.new()
	_portal_mesh.name = "PortalSurface"
	var quad = QuadMesh.new()
	quad.size = Vector2(portal_width - 0.1, portal_height - 0.1)
	_portal_mesh.mesh = quad
	_portal_mesh.transform.origin = Vector3(0, portal_height / 2.0, 0)
	
	# Try to load the portal shader
	var shader = load("res://commons/resourses/shaders/PinkTeleport.gdshader")
	if shader:
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("violet_color", portal_color_1)
		material.set_shader_parameter("pink_color", portal_color_2)
		material.set_shader_parameter("accent_color", Color.WHITE)
		material.set_shader_parameter("portal_speed", 1.0)
		material.set_shader_parameter("pulse_speed", 1.0)
		material.set_shader_parameter("wave_frequency", 2.0)
		material.set_shader_parameter("energy", energy)
		material.set_shader_parameter("transparency", 0.6)
		material.set_shader_parameter("rim_power", 2.0)
		material.set_shader_parameter("distortion_strength", 0.05)
		if still_surface:
			# Same picture every capture: the surface keeps its look and loses its clock.
			material.set_shader_parameter("portal_speed", 0.0)
			material.set_shader_parameter("pulse_speed", 0.0)
			material.set_shader_parameter("distortion_strength", 0.0)
		_portal_mesh.material_override = material
	else:
		# Fallback material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = portal_color_1
		mat.emission_enabled = true
		mat.emission = portal_color_1
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_portal_mesh.material_override = mat

	# TELL — `none` seals the opening: the field is replaced by a dark inert plate, so the
	# threshold stops advertising that it works. Every other value keeps the surface above.
	var sealed: bool = false
	if tell == "none":
		sealed = true
		var sealed_mat = StandardMaterial3D.new()
		sealed_mat.albedo_color = Color(0.045, 0.05, 0.06, 1.0)
		sealed_mat.roughness = 0.95
		sealed_mat.metallic = 0.0
		_portal_mesh.material_override = sealed_mat

	add_child(_portal_mesh)

	# Frame
	if show_frame:
		_build_frame()
	
	# Label
	_label = Label3D.new()
	_label.name = "PortalLabel"
	_label.transform.origin = Vector3(0, portal_height + 0.2, 0)
	_label.pixel_size = 0.005
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# A sealed threshold does not name where it goes, even when a map has told it.
	_label.text = "" if sealed else (label_text if label_text != "" else destination_map)
	_label.font_size = 32
	_label.outline_size = 8
	_label.modulate = Color.WHITE
	add_child(_label)

	# TELL dressing, appended LAST so every child index and position above is untouched
	# on the legacy path. "mark" falls through and adds nothing at all.
	match tell:
		"ghost":
			_tell_ghost()
		"exemplar":
			_tell_exemplar()
		_:
			pass                                  # "mark" / "none" — handled above

	print("ConfigurablePortal: Built portal %.1fx%.1f, dest=%s, map=%s" % [
		portal_width, portal_height, destination_position, destination_map
	])

func _build_frame():
	_frame_node = Node3D.new()
	_frame_node.name = "Frame"
	add_child(_frame_node)
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.metallic = 0.8
	frame_mat.roughness = 0.2
	
	var frame_thickness = 0.15
	
	# Left pillar
	var left = MeshInstance3D.new()
	left.mesh = BoxMesh.new()
	left.transform = Transform3D(
		Basis.IDENTITY.scaled(Vector3(frame_thickness, portal_height, frame_thickness)),
		Vector3(-portal_width / 2.0, portal_height / 2.0, 0)
	)
	left.material_override = frame_mat
	_frame_node.add_child(left)
	
	# Right pillar
	var right = MeshInstance3D.new()
	right.mesh = BoxMesh.new()
	right.transform = Transform3D(
		Basis.IDENTITY.scaled(Vector3(frame_thickness, portal_height, frame_thickness)),
		Vector3(portal_width / 2.0, portal_height / 2.0, 0)
	)
	right.material_override = frame_mat
	_frame_node.add_child(right)
	
	# Top bar
	var top = MeshInstance3D.new()
	top.mesh = BoxMesh.new()
	top.transform = Transform3D(
		Basis.IDENTITY.scaled(Vector3(portal_width + frame_thickness, frame_thickness, frame_thickness)),
		Vector3(0, portal_height, 0)
	)
	top.material_override = frame_mat
	_frame_node.add_child(top)
	
	# Bottom bar
	var bottom = MeshInstance3D.new()
	bottom.mesh = BoxMesh.new()
	bottom.transform = Transform3D(
		Basis.IDENTITY.scaled(Vector3(portal_width + frame_thickness, frame_thickness * 0.5, frame_thickness * 2)),
		Vector3(0, 0, 0)
	)
	bottom.material_override = frame_mat
	_frame_node.add_child(bottom)

func _on_body_entered(body: Node3D):
	if not active or not _can_teleport:
		return
	
	# Check if it's the player
	if not body.is_in_group("player_body"):
		return
	
	print("ConfigurablePortal: Player entered portal")
	
	# Start cooldown
	_can_teleport = false
	get_tree().create_timer(cooldown).timeout.connect(func(): _can_teleport = true)
	
	# Emit signal with destination info
	var dest_info = {
		"position": destination_position,
		"map": destination_map,
		"spawn": destination_spawn
	}
	portal_entered.emit(dest_info)
	
	# Handle teleportation
	if destination_map != "":
		# Load another map
		_load_destination_map()
	elif destination_position != Vector3.ZERO:
		# Teleport within current map
		_teleport_player(body)
	else:
		# Just emit signal, let external system handle it
		print("ConfigurablePortal: No destination set, signal emitted only")

func _teleport_player(body: Node3D):
	print("ConfigurablePortal: Teleporting to %s" % destination_position)
	
	# Find XRToolsPlayerBody which has the proper teleport method
	var player_body = _find_xr_player_body(body)
	
	if player_body and player_body.has_method("teleport"):
		print("ConfigurablePortal: Using XRToolsPlayerBody.teleport()")
		print("ConfigurablePortal: Player was at %s" % player_body.global_position)
		
		# Build target transform at destination
		var target_transform = Transform3D()
		target_transform.origin = destination_position
		target_transform.basis = player_body.global_transform.basis  # Keep current rotation
		
		# Use XR Tools proper teleport
		player_body.teleport(target_transform)
		
		# Reset velocity
		player_body.velocity = Vector3.ZERO
		
		print("ConfigurablePortal: Player now at %s" % player_body.global_position)
	else:
		# Fallback for non-XR or missing player body
		var player_root = _find_player_root(body)
		if player_root:
			print("ConfigurablePortal: Fallback - direct position set")
			print("ConfigurablePortal: Player was at %s" % player_root.global_position)
			player_root.global_position = destination_position
			print("ConfigurablePortal: Player now at %s" % player_root.global_position)
			
			if "velocity" in player_root:
				player_root.velocity = Vector3.ZERO

func _find_xr_player_body(body: Node3D) -> Node3D:
	# Find XRToolsPlayerBody in the tree
	# First check if the body itself is PlayerBody
	if body.has_method("teleport"):
		return body
	
	# Check parent chain
	var current = body.get_parent()
	while current:
		if current.has_method("teleport") and "PlayerBody" in current.name:
			return current
		current = current.get_parent()
	
	# Search in groups
	var player_bodies = get_tree().get_nodes_in_group("player_body")
	for pb in player_bodies:
		if pb.has_method("teleport"):
			return pb
	
	# Find by name in scene
	var root = get_tree().current_scene
	if root:
		var pb = root.find_child("PlayerBody", true, false)
		if pb and pb.has_method("teleport"):
			return pb
	
	return null

func _clear_xr_fade(player_root: Node3D):
	# Reset the PlayerBody's internal fade state
	if player_root.has_method("get") and "XRToolsPlayerBody" in player_root.get_class():
		if "_fade_value" in player_root:
			player_root._fade_value = 0.0
	
	# Find PlayerBody in tree and reset its fade
	var player_body = player_root.find_child("PlayerBody", true, false)
	if not player_body:
		player_body = get_tree().get_first_node_in_group("player_body")
	if player_body and "_fade_value" in player_body:
		player_body._fade_value = 0.0
		print("ConfigurablePortal: Reset PlayerBody fade value")
	
	# Clear the actual fade overlay
	var fade_node = get_tree().get_first_node_in_group("xr_fade")
	if fade_node and fade_node.has_method("set_fade_level"):
		fade_node.set_fade_level(self, Color(0, 0, 0, 0))
		print("ConfigurablePortal: Cleared XR fade overlay")

func _find_player_root(body: Node3D) -> Node3D:
	var current = body
	while current:
		if current.is_in_group("player") or "XROrigin" in current.name:
			return current
		current = current.get_parent()
	return body

func _load_destination_map():
	# Find GridSystem or SceneManager to load the map
	var grid_system = _find_grid_system()
	if grid_system and grid_system.has_method("load_map"):
		print("ConfigurablePortal: Loading map '%s'" % destination_map)
		grid_system.load_map(destination_map)
	else:
		# Try to find a scene manager
		var scene_manager = get_tree().get_first_node_in_group("scene_manager")
		if scene_manager and scene_manager.has_method("load_scene"):
			scene_manager.load_scene(destination_map)
		else:
			push_warning("ConfigurablePortal: Cannot find system to load map '%s'" % destination_map)

func _find_grid_system() -> Node:
	var root = get_tree().current_scene
	if root:
		var grid = root.find_child("GridSystem", true, false)
		if grid:
			return grid
	return null

# ── TELL ─────────────────────────────────────────────────────────────────────
# What the threshold discloses of the far side. Both values build OUT of the doorway
# on the viewer's side rather than behind the surface — geometry built behind a
# semi-transparent field is geometry nobody sees.

## GHOST — the far side as an apparition. A translucent vestibule stands out of the opening:
## a floor plate, two jambs and a lintel, in the portal's own light. The shape of a place,
## with nothing in it — you are shown that there IS somewhere, and not what is there.
func _tell_ghost() -> void:
	var w: float = maxf(portal_width, 0.3)
	var h: float = maxf(portal_height, 0.5)
	var depth: float = maxf(w * 0.7, 0.6)

	var glass = StandardMaterial3D.new()
	glass.albedo_color = Color(portal_color_2.r, portal_color_2.g, portal_color_2.b, 0.22)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.emission_enabled = true
	glass.emission = Color(portal_color_2.r, portal_color_2.g, portal_color_2.b, 1.0)
	glass.emission_energy_multiplier = 0.55
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED

	add_child(_tell_box("Tell_ghost_floor", Vector3(0, 0.02, depth * 0.5),
		Vector3(w * 0.94, 0.02, depth), glass))
	for sx in [-1.0, 1.0]:
		add_child(_tell_box("Tell_ghost_jamb_%d" % int(sx), Vector3(sx * w * 0.47, h * 0.42, depth * 0.5),
			Vector3(0.02, h * 0.82, depth), glass))
	add_child(_tell_box("Tell_ghost_lintel", Vector3(0, h * 0.84, depth * 0.5),
		Vector3(w * 0.94, 0.02, depth), glass))
	add_child(_tell_box("Tell_ghost_sill", Vector3(0, 0.05, depth),
		Vector3(w * 0.98, 0.10, 0.03), glass))


## EXEMPLAR — the far side built solid on this side of the threshold. The first metre of the
## destination stands here in matte concrete: a step up, a floor, two walls, a lintel, and a
## block sitting on it. Not a picture of somewhere else — a piece of it, standing in the room.
func _tell_exemplar() -> void:
	var w: float = maxf(portal_width, 0.3)
	var h: float = maxf(portal_height, 0.5)
	var depth: float = maxf(w * 0.7, 0.6)

	var stone = StandardMaterial3D.new()
	stone.albedo_color = Color(0.55, 0.55, 0.58, 1.0)
	stone.roughness = 0.92
	var trim = StandardMaterial3D.new()
	trim.albedo_color = Color(0.40, 0.40, 0.43, 1.0)
	trim.roughness = 0.9

	add_child(_tell_box("Tell_exemplar_step", Vector3(0, 0.05, depth + 0.10),
		Vector3(w * 0.98, 0.10, 0.20), trim))
	add_child(_tell_box("Tell_exemplar_floor", Vector3(0, 0.09, depth * 0.5),
		Vector3(w * 0.94, 0.18, depth), stone))
	for sx in [-1.0, 1.0]:
		add_child(_tell_box("Tell_exemplar_wall_%d" % int(sx),
			Vector3(sx * w * 0.45, h * 0.45, depth * 0.5),
			Vector3(0.09, h * 0.9, depth), stone))
	add_child(_tell_box("Tell_exemplar_lintel", Vector3(0, h * 0.92, depth * 0.5),
		Vector3(w + 0.10, 0.16, depth), stone))
	# Something on that floor, so the far side reads as a place rather than a lining.
	add_child(_tell_box("Tell_exemplar_block", Vector3(w * 0.12, 0.18 + h * 0.11, depth * 0.42),
		Vector3(w * 0.3, h * 0.22, w * 0.26), trim))


func _tell_box(nm: String, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var mi = MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


# Config API for map loading
func apply_grid_config(config: Dictionary):
	print("ConfigurablePortal: Applying config: %s" % str(config))

	# AXIS — an unknown word keeps the current value rather than silently sealing a door.
	if config.has("tell"):
		var t: String = str(config["tell"]).strip_edges().to_lower()
		if TELLS.has(t):
			tell = t
	if config.has("still_surface"):
		still_surface = str(config["still_surface"]).to_lower() in ["true", "1", "yes", "on"]
	
	# Size
	if config.has("width"):
		portal_width = float(config["width"])
	if config.has("height"):
		portal_height = float(config["height"])
	if config.has("depth"):
		portal_depth = float(config["depth"])
	
	# Position offset (for placing portal at different Y level than grid)
	if config.has("pos_x") or config.has("pos_y") or config.has("pos_z"):
		pos_offset = Vector3(
			float(config.get("pos_x", 0)),
			float(config.get("pos_y", 0)),
			float(config.get("pos_z", 0))
		)
	
	# Rotation
	if config.has("rot_x"):
		rotation_x = float(config["rot_x"])
	if config.has("rot_y"):
		rotation_y = float(config["rot_y"])
	if config.has("rot_z"):
		rotation_z = float(config["rot_z"])
	
	# Destination position (can use dest_x,dest_y,dest_z or dest:x,y,z)
	if config.has("dest_x") or config.has("dest_y") or config.has("dest_z"):
		destination_position = Vector3(
			float(config.get("dest_x", 0)),
			float(config.get("dest_y", 0)),
			float(config.get("dest_z", 0))
		)
	if config.has("dest"):
		var parts = str(config["dest"]).split(",")
		if parts.size() >= 3:
			destination_position = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	
	# Destination map
	if config.has("dest_map"):
		destination_map = str(config["dest_map"])
	if config.has("map"):
		destination_map = str(config["map"])
	
	# Spawn point name
	if config.has("spawn"):
		destination_spawn = str(config["spawn"])
	
	# Appearance
	if config.has("color1"):
		portal_color_1 = Color.html(str(config["color1"]))
	if config.has("color2"):
		portal_color_2 = Color.html(str(config["color2"]))
	if config.has("energy"):
		energy = float(config["energy"])
	if config.has("label"):
		label_text = str(config["label"])
	if config.has("frame"):
		show_frame = str(config["frame"]).to_lower() == "true"
	
	# Behavior
	if config.has("active"):
		active = str(config["active"]).to_lower() == "true"
	if config.has("cooldown"):
		cooldown = float(config["cooldown"])
	
	# Rebuild with new settings
	_build_portal()
