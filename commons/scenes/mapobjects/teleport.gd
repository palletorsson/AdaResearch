@tool
class_name Teleport
extends Node3D

## Emitted when the teleporter is activated by the player.
## SceneManager should connect to this to handle the actual transition.
signal teleport_activated(target_scene_path, target_map_name)

## Target scene file path (e.g., "res://commons/scenes/grid.tscn").
## This property will be set by your EnhancedUtilityHandler/_configure_teleporter function.
@export_file("*.tscn") var scene: String

## Target map name (e.g., "Tutorial_Single", "Lab", or special keywords like "MAIN_MENU_REQUEST").
## This property will be set by your EnhancedUtilityHandler/_configure_teleporter function.
var destination_map: String

@export_group("Display")
## Title texture for display on the teleporter.
@export var title: Texture2D: set = _set_title

## Can the Teleporter be used.
@export var active: bool = true: set = _set_active

## Is the teleport beam visible if the teleporter is inactive.
@export var inactive_beam_visible: bool = false: set = _set_inactive_beam_visible

## The beam color when the teleporter is active.
@export var active_beam_color: Color = Color("#2b40f8"): set = _set_active_beam_color

## The beam color when the teleporter is inactive.
@export var inactive_beam_color: Color = Color("#ad0400"): set = _set_inactive_beam_color

# Assuming your teleport_scene.tscn has an Area3D child node named "TeleportArea"
# for detecting player entry. Adjust the path if it's different.
@onready var teleport_area: Area3D = get_node_or_null("TeleportArea") as Area3D

# Assuming paths to visual components. Adjust if different in your scene.
@onready var top_mesh_node = get_node_or_null("Cylinder")
@onready var cylinder_mesh_node = get_node_or_null("Cylinder")


func _ready():
	_update_title_visuals()
	_update_teleport_visuals()

	if teleport_area:
		# Ensure the signal is connected. If already connected in editor, this might print a harmless error.
		if not teleport_area.is_connected("body_entered", Callable(self, "_on_teleport_area_body_entered")):
			var error_code = teleport_area.connect("body_entered", Callable(self, "_on_teleport_area_body_entered"))
			if error_code != OK:
				printerr("Teleport: Failed to connect body_entered signal for TeleportArea. Error code: %s" % error_code)
	else:
		printerr("Teleport: 'TeleportArea' node not found or is not an Area3D. Teleporter will not function.")


func _on_teleport_area_body_entered(body: Node3D):
	if not active:
		print_debug("Teleport: Player entered but teleporter is inactive.")
		return

	if not body.is_in_group("player_body"): # Make sure your player's physics body is in the "player_body" group
		print_debug("Teleport: Non-player body entered, ignoring.")
		return

	print_debug("Teleport: Player activated teleport. Target scene: '%s', Target map: '%s'" % [scene, destination_map])

	# Emit the signal with the destination details.
	# SceneManager (or UtilitySignalRouter) should be listening to this.
	if scene != null and destination_map != null: # Check for null, empty strings can be valid (e.g. for menu)
		emit_signal("teleport_activated", scene, destination_map)
	else:
		printerr("Teleport: 'scene' ('%s') or 'destination_map' ('%s') is not properly configured. Cannot teleport." % [scene, destination_map])


# --- Property Setters and Visual Update Logic (largely from your original script) ---

func _set_title(value: Texture2D):
	title = value
	if is_inside_tree():
		_update_title_visuals()

func _update_title_visuals():
	if title and top_mesh_node and top_mesh_node is MeshInstance3D:
		if top_mesh_node.get_surface_override_material_count() > 1:
			var material = top_mesh_node.get_surface_override_material(1) # Assuming ShaderMaterial
			if material is ShaderMaterial:
				material.set_shader_parameter("Title", title)
			elif material:
				print_debug("Teleport: Material for title is not a ShaderMaterial.")
		else:
			print_debug("Teleport: 'teleport/Top' does not have enough surface materials for title.")
	elif title and not top_mesh_node:
		print_debug("Teleport: 'teleport/Top' node not found for title.")


func _set_active(value: bool):
	active = value
	if is_inside_tree():
		_update_teleport_visuals()

func _set_active_beam_color(value: Color):
	active_beam_color = value
	if is_inside_tree():
		_update_teleport_visuals()

func _set_inactive_beam_color(value: Color):
	inactive_beam_color = value
	if is_inside_tree():
		_update_teleport_visuals()

func _set_inactive_beam_visible(value: bool):
	inactive_beam_visible = value
	if is_inside_tree():
		_update_teleport_visuals()

func _update_teleport_visuals():
	if cylinder_mesh_node and cylinder_mesh_node is MeshInstance3D:
		var material = cylinder_mesh_node.get_surface_override_material(0) # Assuming ShaderMaterial
		if material is ShaderMaterial:
			if active:
				material.set_shader_parameter("beam_color", active_beam_color)
				cylinder_mesh_node.visible = true
			else:
				material.set_shader_parameter("beam_color", inactive_beam_color)
				cylinder_mesh_node.visible = inactive_beam_visible
		elif material:
			print_debug("Teleport: Beam material is not a ShaderMaterial.")
	elif not cylinder_mesh_node:
		print_debug("Teleport: 'teleport/Cylinder' node not found for visuals.")

# The following functions from your original script might be unnecessary
# if 'scene' and 'destination_map' are the sole method of configuration
# set by _configure_teleporter, effectively replacing SpawnDataType logic.
# - _get_property_list()
# - _property_can_revert(property)
# - _property_get_revert(property)
# - _set_spawn_data(p_spawn_data)
# - set_collision_disabled(p_disable) # This might still be useful depending on your needs.
