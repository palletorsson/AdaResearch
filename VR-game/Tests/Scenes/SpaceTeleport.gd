@tool
class_name SpaceTeleport
extends Node3D

## Type of destination data
enum DestinationDataType {
	## No data provided
	NONE,
	
	## Space ID and position provided
	SPACE_POSITION,
	
	## Space ID and transform provided
	SPACE_TRANSFORM,
	
	## Exit to main menu
	EXIT_GAME
}

@export_group("Teleport")

## Target space ID
@export var target_space_id: String = ""

## Destination data type
@export var destination_data := DestinationDataType.SPACE_POSITION: set = _set_destination_data

@export_group("Display")

## Title texture
@export var title: Texture2D: set = _set_title

## Can Teleporter be used
@export var active: bool = true: set = _set_active

## Is teleport beam visible if inactive
@export var inactive_beam_visible: bool = false: set = _set_inactive_beam_visible

## The beam color in active state
@export var active_beam_color: Color = Color("#2b40f8"): set = _set_active_beam_color

## The beam color in inactive state
@export var inactive_beam_color: Color = Color("#ad0400"): set = _set_inactive_beam_color

# Destination position
var destination_position := Vector3.ZERO

# Destination transform
var destination_transform := Transform3D.IDENTITY

# WorldBuilder reference
var _world_builder: WorldBuilder

func _ready():
	# Find the WorldBuilder
	_world_builder = _find_world_builder()
	
	# Connect to the TeleportArea
	if has_node("TeleportArea"):
		var teleport_area = get_node("TeleportArea")
		if teleport_area.has_signal("body_entered"):
			teleport_area.connect("body_entered", _on_TeleportArea_body_entered)
	
	_update_title()
	_update_teleport()

# Find the WorldBuilder in the scene
func _find_world_builder() -> WorldBuilder:
	# First check if we're in a group
	var builders = get_tree().get_nodes_in_group("world_builder")
	if builders.size() > 0:
		return builders[0]
	
	# Then check for parent or ancestor
	var current = self
	while current:
		if current is WorldBuilder:
			return current
		current = current.get_parent()
	
	# Fallback to searching the entire tree
	var root = get_tree().root
	for child in root.get_children():
		if child is WorldBuilder:
			return child
	
	# No WorldBuilder found
	return null

# Called when the player enters the teleport area
func _on_TeleportArea_body_entered(body: Node3D):
	# Skip if world builder is not known
	if not _world_builder:
		print("WARNING: WorldBuilder not found for teleport")
		return

	# Skip if not the player body
	if not body.is_in_group("player_body"):
		return

	# Skip if not active
	if not active:
		return

	# Teleport
	match destination_data:
		DestinationDataType.EXIT_GAME:
			# Handle exit game logic
			print("Exiting game")
			
			get_tree().quit()
				
		DestinationDataType.SPACE_POSITION:
			print("Teleporting to space '%s' at position %s" % [target_space_id, destination_position])
			_world_builder.change_space(target_space_id)
			# Move player to destination
			body.global_position = destination_position
			
		DestinationDataType.SPACE_TRANSFORM:
			print("Teleporting to space '%s' with transform" % target_space_id)
			_world_builder.change_space(target_space_id)
			# Apply transform to player
			body.global_transform = destination_transform
			
		_:
			print("Teleporting to space '%s' with default position" % target_space_id)
			_world_builder.change_space(target_space_id)

# Provide custom property information
func _get_property_list() -> Array[Dictionary]:
	# Return extra properties
	return [
		{
			"name": "destination_position",
			"type": TYPE_VECTOR3,
			"usage": PROPERTY_USAGE_DEFAULT \
					if destination_data == DestinationDataType.SPACE_POSITION \
					else PROPERTY_USAGE_NO_EDITOR
		},
		{
			"name": "destination_transform",
			"type": TYPE_TRANSFORM3D,
			"usage": PROPERTY_USAGE_DEFAULT \
					if destination_data == DestinationDataType.SPACE_TRANSFORM \
					else PROPERTY_USAGE_NO_EDITOR
		}
	]

# Allow revert of custom properties
func _property_can_revert(property: StringName) -> bool:
	match property:
		"destination_position":
			return true
		"destination_transform":
			return true
		_:
			return false

# Provide revert values for custom properties
func _property_get_revert(property: StringName): # Variant
	match property:
		"destination_position":
			return Vector3.ZERO
		"destination_transform":
			return Transform3D.IDENTITY

func _set_destination_data(p_destination_data: DestinationDataType) -> void:
	destination_data = p_destination_data
	notify_property_list_changed()

func _set_title(value):
	title = value
	if is_inside_tree():
		_update_title()

func _update_title():
	if title:
		if has_node("teleport/Top"):
			var top_node = get_node("teleport/Top")
			if top_node.get_surface_override_material_count() > 1:
				var material = top_node.get_surface_override_material(1)
				if material is ShaderMaterial:
					material.set_shader_parameter("Title", title)

func _set_active(value):
	active = value
	if is_inside_tree():
		_update_teleport()

func _set_active_beam_color(value):
	active_beam_color = value
	if is_inside_tree():
		_update_teleport()

func _set_inactive_beam_color(value):
	inactive_beam_color = value
	if is_inside_tree():
		_update_teleport()

func _set_inactive_beam_visible(value):
	inactive_beam_visible = value
	if is_inside_tree():
		_update_teleport()

func _update_teleport():
	if has_node("teleport/Cylinder"):
		var cylinder = get_node("teleport/Cylinder")
		if cylinder.get_surface_override_material_count() > 0:
			var mat = cylinder.get_surface_override_material(0)
			if mat:
				if active:
					mat.set_shader_parameter("beam_color", active_beam_color)
					cylinder.visible = true
				else:
					mat.set_shader_parameter("beam_color", inactive_beam_color)
					cylinder.visible = inactive_beam_visible
