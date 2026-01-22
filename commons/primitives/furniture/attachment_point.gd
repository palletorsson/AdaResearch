@tool
extends Area3D
class_name AttachmentPoint

## Attachment Point
##
## A surface attachment point for furniture assembly.
## Placed on cube faces, snaps to other attachment points when facing each other.
## Designed for the furniture assembly puzzle system.
##
## Key features:
## - Face-aligned snapping (only snaps when normals oppose)
## - Visual feedback showing attachment state
## - Compatible with scalable cubes (repositions with scale changes)
## - Supports male/female or universal attachment types

## Attachment type - determines what can connect to what
enum AttachmentType {
	UNIVERSAL,  ## Can connect to any other universal point
	MALE,       ## Can only connect to FEMALE points
	FEMALE      ## Can only connect to MALE points
}

## Face direction this attachment is on
enum FaceDirection {
	POSITIVE_X,  ## +X face (right)
	NEGATIVE_X,  ## -X face (left)
	POSITIVE_Y,  ## +Y face (top)
	NEGATIVE_Y,  ## -Y face (bottom)
	POSITIVE_Z,  ## +Z face (front)
	NEGATIVE_Z   ## -Z face (back)
}

## The face this attachment is placed on
@export var face: FaceDirection = FaceDirection.POSITIVE_Y

## Attachment type for connection rules
@export var attachment_type: AttachmentType = AttachmentType.UNIVERSAL

## Snap distance threshold (how close points must be to snap)
@export var snap_distance: float = 0.05

## Angle tolerance for normal alignment (degrees)
@export var angle_tolerance: float = 30.0

## Visual indicator size (radius of sphere)
@export var indicator_size: float = 0.015

## Show visual indicator
@export var show_indicator: bool = true

## Color when available for connection (red sphere)
@export var available_color: Color = Color(0.9, 0.2, 0.2, 0.9)

## Color when connected (green)
@export var connected_color: Color = Color(0.2, 0.9, 0.3, 0.9)

## Color when highlighted (nearby compatible point - bright yellow)
@export var highlight_color: Color = Color(1.0, 0.95, 0.2, 1.0)

## Signal when connection is made
signal connected(other_point: AttachmentPoint)

## Signal when connection is broken
signal disconnected(other_point: AttachmentPoint)

## Signal when a compatible point is nearby
signal nearby_point_detected(other_point: AttachmentPoint)

## Signal when nearby point leaves
signal nearby_point_lost(other_point: AttachmentPoint)

# Currently connected attachment point
var _connected_to: AttachmentPoint = null

# Nearby compatible points
var _nearby_points: Array[AttachmentPoint] = []

# Closest nearby point
var _closest_point: AttachmentPoint = null

# Visual indicator mesh
var _indicator: MeshInstance3D = null

# Parent pickable (for detecting when dropped)
var _parent_pickable: Node = null

# Is the parent currently held
var _parent_held: bool = false


func _ready() -> void:
	# Set up collision detection
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(20, true)  # Attachment points layer
	set_collision_mask_value(20, true)

	# Create collision shape if not present
	if not has_node("CollisionShape3D"):
		var collision = CollisionShape3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = snap_distance
		collision.shape = sphere
		add_child(collision)

	# Create visual indicator - always create it (even in editor for preview)
	if show_indicator:
		_create_indicator()
		print("AttachmentPoint: Created indicator for face %d" % face)

	# Add to group for easy finding
	add_to_group("attachment_points")

	# Connect area signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	# Find and connect to parent pickable
	_find_parent_pickable()

	# Set initial position based on face
	_update_position_for_face()

	print("AttachmentPoint: Ready at position %v (face %d)" % [position, face])


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Update closest point
	_update_closest_point()

	# Update visual indicator
	_update_indicator()


## Get the face normal in world space
func get_face_normal() -> Vector3:
	var local_normal = _get_local_face_normal()
	return global_transform.basis * local_normal


## Get local face normal
func _get_local_face_normal() -> Vector3:
	match face:
		FaceDirection.POSITIVE_X: return Vector3.RIGHT
		FaceDirection.NEGATIVE_X: return Vector3.LEFT
		FaceDirection.POSITIVE_Y: return Vector3.UP
		FaceDirection.NEGATIVE_Y: return Vector3.DOWN
		FaceDirection.POSITIVE_Z: return Vector3.FORWARD
		FaceDirection.NEGATIVE_Z: return Vector3.BACK
	return Vector3.UP


## Check if this point can connect to another
func can_connect_to(other: AttachmentPoint) -> bool:
	if other == null or other == self:
		return false

	# Already connected
	if _connected_to != null or other._connected_to != null:
		return false

	# Same parent object
	if get_parent() == other.get_parent():
		return false

	# Check attachment type compatibility
	if not _types_compatible(other):
		return false

	# Check distance
	var distance = global_position.distance_to(other.global_position)
	if distance > snap_distance:
		return false

	# Check normal alignment (normals should be opposing)
	var my_normal = get_face_normal()
	var other_normal = other.get_face_normal()
	var dot = my_normal.dot(other_normal)

	# Normals should be roughly opposite (dot product close to -1)
	# cos(180 - tolerance) = -cos(tolerance)
	var min_dot = -cos(deg_to_rad(angle_tolerance))
	if dot > min_dot:
		return false

	return true


## Check if attachment types are compatible
func _types_compatible(other: AttachmentPoint) -> bool:
	if attachment_type == AttachmentType.UNIVERSAL or other.attachment_type == AttachmentType.UNIVERSAL:
		return true
	if attachment_type == AttachmentType.MALE and other.attachment_type == AttachmentType.FEMALE:
		return true
	if attachment_type == AttachmentType.FEMALE and other.attachment_type == AttachmentType.MALE:
		return true
	return false


## Attempt to connect to the closest compatible point
func attempt_connect() -> bool:
	if _closest_point == null:
		return false

	if not can_connect_to(_closest_point):
		return false

	# Perform connection
	_connect_to(_closest_point)
	return true


## Connect to another attachment point
func _connect_to(other: AttachmentPoint) -> void:
	if other == null:
		return

	_connected_to = other
	other._connected_to = self

	# Emit signals
	connected.emit(other)
	other.connected.emit(self)

	# Play feedback
	_play_connect_feedback()


## Disconnect from current attachment
func disconnect_attachment() -> void:
	if _connected_to == null:
		return

	var other = _connected_to
	_connected_to = null
	other._connected_to = null

	# Emit signals
	disconnected.emit(other)
	other.disconnected.emit(self)


## Check if connected to another attachment point
func is_attached() -> bool:
	return _connected_to != null


## Get connected point
func get_connected_point() -> AttachmentPoint:
	return _connected_to


## Update position based on face and parent scale
func _update_position_for_face() -> void:
	# This positions the attachment point on the face surface
	# The offset is based on the local face normal
	var normal = _get_local_face_normal()

	# Default offset (half of a 0.1 unit cube = 0.05)
	# This will be overridden by the scalable cube when it changes size
	position = normal * 0.05


## Update position when parent cube scales
func update_for_cube_size(cube_size: Vector3) -> void:
	var normal = _get_local_face_normal()
	# Position at the face surface (half the size in that axis direction)
	var offset = Vector3(
		normal.x * cube_size.x * 0.5,
		normal.y * cube_size.y * 0.5,
		normal.z * cube_size.z * 0.5
	)
	position = offset


func _on_area_entered(area: Area3D) -> void:
	if area is AttachmentPoint:
		var other = area as AttachmentPoint
		if other not in _nearby_points and other.get_parent() != get_parent():
			_nearby_points.append(other)
			nearby_point_detected.emit(other)


func _on_area_exited(area: Area3D) -> void:
	if area is AttachmentPoint:
		var other = area as AttachmentPoint
		if other in _nearby_points:
			_nearby_points.erase(other)
			nearby_point_lost.emit(other)
			if _closest_point == other:
				_closest_point = null


func _update_closest_point() -> void:
	var closest: AttachmentPoint = null
	var closest_dist: float = snap_distance

	for point in _nearby_points:
		if can_connect_to(point):
			var dist = global_position.distance_to(point.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = point

	_closest_point = closest


func _find_parent_pickable() -> void:
	var parent = get_parent()
	while parent != null:
		if parent.has_method("is_picked_up"):
			_parent_pickable = parent
			# Connect to pickup/release signals if available
			if parent.has_signal("picked_up"):
				parent.picked_up.connect(_on_parent_picked_up)
			if parent.has_signal("released"):
				parent.released.connect(_on_parent_released)
			break
		parent = parent.get_parent()


func _on_parent_picked_up(_by) -> void:
	_parent_held = true
	# Disconnect if we were connected
	if _connected_to != null:
		disconnect_attachment()


func _on_parent_released(_by) -> void:
	_parent_held = false
	# Attempt to connect on release
	attempt_connect()


func _create_indicator() -> void:
	_indicator = MeshInstance3D.new()
	_indicator.name = "Indicator"

	var sphere = SphereMesh.new()
	sphere.radius = indicator_size
	sphere.height = indicator_size * 2
	sphere.radial_segments = 12
	sphere.rings = 6
	_indicator.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = available_color
	material.emission_enabled = true
	material.emission = Color(available_color.r, available_color.g, available_color.b, 1.0)
	material.emission_energy_multiplier = 1.5  # Brighter glow
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED  # Solid sphere
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Always visible
	_indicator.material_override = material

	# Render on top of other geometry
	_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	add_child(_indicator)


func _update_indicator() -> void:
	if not _indicator:
		return

	var material = _indicator.material_override as StandardMaterial3D
	if not material:
		return

	var color: Color
	if _connected_to != null:
		color = connected_color
	elif _closest_point != null:
		color = highlight_color
	else:
		color = available_color

	material.albedo_color = color
	material.emission = Color(color.r, color.g, color.b, 1.0)

	# Show indicator based on state:
	# - Always show when not connected (red sphere visible)
	# - Show green when connected
	# - Pulse/highlight when near compatible point
	_indicator.visible = show_indicator


func _play_connect_feedback() -> void:
	# Haptic feedback if parent has controller reference
	if _parent_pickable and _parent_pickable.has_method("get") and _parent_pickable.get("_current_controller"):
		var controller = _parent_pickable._current_controller
		if controller and controller.has_method("trigger_haptic_pulse"):
			controller.trigger_haptic_pulse("haptic", 0.2, 0.5, 0.1, 0.0)
