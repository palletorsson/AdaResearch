extends Node3D
class_name CaptureRig

## Purpose-built camera rig for research-loop captures.
##
## NOT a player — no collision, no physics, no interaction. Just a
## Camera3D plus optional fill lights tuned for clean photographic
## snapshots of artifacts in their map context.
##
## Usage:
##   var rig = preload("res://commons/testing/capture_rig.tscn").instantiate()
##   root.add_child(rig)
##   rig.aim(camera_pos, look_at_world, fov)
##   rig.activate()  # makes the camera current
##
## Fill-light philosophy:
##   The map's own DirectionalLight3D + WorldEnvironment do most of the
##   work. We add a soft key fill from camera-front-up to lift the
##   artifact out of shadow without flattening the scene.

@onready var camera: Camera3D = $Camera
@onready var key_fill: OmniLight3D = $KeyFill
@onready var ambient_fill: OmniLight3D = $AmbientFill

var _last_target: Vector3 = Vector3.ZERO


func aim(camera_pos: Vector3, world_target: Vector3, fov: float = 60.0) -> void:
	"""Position the rig at camera_pos, point camera at world_target."""
	global_position = camera_pos
	# look_at requires source != target AND source-to-target not colinear with up.
	var t := world_target
	if (t - global_position).length_squared() < 0.0001:
		t = global_position + Vector3(0, 0, -1)
	# If we're directly above/below target (top-down/bottom-up), pick a
	# non-vertical up vector so basis isn't degenerate.
	var dir_to_t := (t - global_position).normalized()
	var up_vec := Vector3.UP
	if abs(dir_to_t.dot(up_vec)) > 0.999:
		up_vec = Vector3(0, 0, -1)  # face north for top-down
	look_at(t, up_vec)
	camera.fov = fov
	_last_target = t

	# Position the key fill slightly above + behind camera, aimed forward.
	# Distance scales with target distance so close-ups don't blow out.
	var dist := global_position.distance_to(t)
	var fwd := -global_transform.basis.z
	var up := global_transform.basis.y
	if key_fill:
		key_fill.global_position = global_position + up * 1.5 + fwd * 0.3
		key_fill.omni_range = max(8.0, dist * 1.6)
		key_fill.light_energy = 0.6
	if ambient_fill:
		# Very soft wraparound from below — kills harsh under-shadows on
		# floor pieces (mosaics, patterns).
		ambient_fill.global_position = t + Vector3(0, 0.6, 0)
		ambient_fill.omni_range = max(6.0, dist * 1.2)
		ambient_fill.light_energy = 0.25


func activate() -> void:
	"""Make this rig's camera the current one."""
	if camera:
		camera.make_current()


func set_clean_render() -> void:
	"""Tune camera attributes for crisp photographic stills.

	No motion blur, sharp focus, no DOF. We rely on the scene's
	environment for tone mapping but disable anything that would
	soften an artifact's silhouette.
	"""
	if not camera:
		return
	# In Godot 4, per-camera attributes live on CameraAttributesPractical.
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = false
	attrs.dof_blur_near_enabled = false
	attrs.exposure_multiplier = 1.0
	camera.attributes = attrs


func disable_fill_lights() -> void:
	"""Use only the map's own lighting (most authentic in-game look)."""
	if key_fill: key_fill.visible = false
	if ambient_fill: ambient_fill.visible = false
