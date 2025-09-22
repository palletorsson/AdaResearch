@tool
class_name Teleport
extends Node3D

## Emitted when the teleporter is activated by the player.
## SceneManager should connect to this to advance the current sequence.
signal teleporter_activated()

const AUDIO_CLEANUP_GROUP := "audio_emitters"

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
@onready var top_mesh_node = get_node_or_null("Cube")
@onready var cylinder_mesh_node = get_node_or_null("Cube")

# Audio component
@onready var teleport_audio = get_node_or_null("TeleportAudio")


func _ready():
	_update_title_visuals()
	_update_teleport_visuals()

	# Debug audio setup
	if teleport_audio:
		print("Teleport: Audio component found - Volume: %s dB, Max distance: %s" % [teleport_audio.volume_db, teleport_audio.max_distance])
		
		# Check if we're in VR mode
		var xr_interface = XRServer.get_primary_interface()
		if xr_interface and xr_interface.is_initialized():
			print("Teleport: VR Mode detected - Interface: %s" % xr_interface.get_name())
			
			# Check and boost Master bus volume
			var master_bus_index = AudioServer.get_bus_index("Master")
			var master_volume = AudioServer.get_bus_volume_db(master_bus_index)
			var master_mute = AudioServer.is_bus_mute(master_bus_index)
			print("Teleport: Master bus - Volume: %s dB, Muted: %s" % [master_volume, master_mute])
			
			# Temporarily boost Master bus for testing
			if master_volume < 0.0:
				AudioServer.set_bus_volume_db(master_bus_index, 0.0)
				print("Teleport: Boosted Master bus to 0dB for testing")
			
			# Unmute if muted
			if master_mute:
				AudioServer.set_bus_mute(master_bus_index, false)
				print("Teleport: Unmuted Master bus")
		else:
			print("Teleport: Desktop mode - No VR interface active")
			
			# Check Master bus in desktop mode too
			var master_bus_index = AudioServer.get_bus_index("Master")
			var master_volume = AudioServer.get_bus_volume_db(master_bus_index)
			var master_mute = AudioServer.is_bus_mute(master_bus_index)
			print("Teleport: Master bus - Volume: %s dB, Muted: %s" % [master_volume, master_mute])
			
			# Boost Master bus for testing
			if master_volume < 0.0:
				AudioServer.set_bus_volume_db(master_bus_index, 0.0)
				print("Teleport: Boosted Master bus to 0dB for testing")
			
			# Unmute if muted
			if master_mute:
				AudioServer.set_bus_mute(master_bus_index, false)
				print("Teleport: Unmuted Master bus")
		
		# Start continuous teleporter ambient sound
		print("Teleport: Starting continuous ambient teleporter sound...")
		await get_tree().create_timer(0.5).timeout  # Brief delay for setup
		#teleport_audio.set_volume(-6.0)  # Moderate ambient volume
		teleport_audio.play_secondary_sound(true)  # Play ghost drone spatially
		print("Teleport: Ambient ghost drone now running continuously")
	else:
		print("Teleport: ❌ Audio component not found!")

	if teleport_area:
		print("Teleport: TeleportArea found - Collision layer: %s, mask: %s" % [teleport_area.collision_layer, teleport_area.collision_mask])
		
		# Ensure the signal is connected. If already connected in editor, this might print a harmless error.
		if not teleport_area.is_connected("body_entered", Callable(self, "_on_teleport_area_body_entered")):
			var error_code = teleport_area.connect("body_entered", Callable(self, "_on_teleport_area_body_entered"))
			if error_code != OK:
				printerr("Teleport: Failed to connect body_entered signal for TeleportArea. Error code: %s" % error_code)
			else:
				print("Teleport: Successfully connected body_entered signal")
		else:
			print("Teleport: body_entered signal already connected")
	else:
		printerr("Teleport: 'TeleportArea' node not found or is not an Area3D. Teleporter will not function.")


func _on_teleport_area_body_entered(body: Node3D):
	print("Teleport: Body entered teleporter: %s (groups: %s)" % [body.name, body.get_groups()])
	
	if not active:
		print("Teleport: Player entered but teleporter is inactive.")
		return

	if not body.is_in_group("player_body"): # Make sure your player's physics body is in the "player_body" group
		print("Teleport: Non-player body entered, ignoring. Body: %s" % body.name)
		return

	print("Teleport: Player activated teleporter - advancing sequence")

	# Request any active audio scenes to wind down before teleporting
	if get_tree():
		get_tree().call_group(AUDIO_CLEANUP_GROUP, "shutdown_audio")

	# The ambient sound is already playing - just emit the activation signal
	emit_signal("teleporter_activated")


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
			print_debug("Teleport: 'Cube' does not have enough surface materials for title.")
	elif title and not top_mesh_node:
		print_debug("Teleport: 'Cube' node not found for title.")


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
		print_debug("Teleport: 'Cube' node not found for visuals.")

# The following functions from your original script might be unnecessary
# if 'scene' and 'destination_map' are the sole method of configuration
# set by _configure_teleporter, effectively replacing SpawnDataType logic.
# - _get_property_list()
# - _property_can_revert(property)
# - _property_get_revert(property)
# - _set_spawn_data(p_spawn_data)
# - set_collision_disabled(p_disable) # This might still be useful depending on your needs.
