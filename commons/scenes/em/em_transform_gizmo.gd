class_name EmTransformGizmo
extends Node3D
## Shared world-axis hand for the Endless Museum's perspective and isometric
## editors.  The museum remains the author of transforms: this node only shows
## and measures a drag; endless_museum.gd commits the result through its map or
## override rules.

const AXES := ["x", "y", "z"]
const AXIS_VECTORS := {
	"x": Vector3.RIGHT,
	"y": Vector3.UP,
	"z": Vector3.BACK,
}
const AXIS_COLORS := {
	"x": Color(1.0, 0.24, 0.18),
	"y": Color(0.28, 1.0, 0.42),
	"z": Color(0.18, 0.62, 1.0),
}

var _materials: Dictionary = {}
var _allow_y := true


func _ready() -> void:
	top_level = true
	_build()


func _build() -> void:
	if get_child_count() > 0:
		return
	for axis in AXES:
		var color: Color = AXIS_COLORS[axis]
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.8
		mat.no_depth_test = true
		_materials[axis] = mat

		var bar := MeshInstance3D.new()
		bar.name = axis.to_upper() + "Axis"
		var box := BoxMesh.new()
		box.size = Vector3(0.9, 0.055, 0.055)
		bar.mesh = box
		bar.material_override = mat
		bar.position = Vector3(0.45, 0.0, 0.0)
		if axis == "y":
			bar.rotation_degrees.z = 90.0
		elif axis == "z":
			bar.rotation_degrees.y = -90.0
		add_child(bar)

		var tip := MeshInstance3D.new()
		tip.name = axis.to_upper() + "Tip"
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.11
		cone.height = 0.27
		cone.radial_segments = 16
		tip.mesh = cone
		tip.material_override = mat
		tip.position = Vector3(1.035, 0.0, 0.0)
		if axis == "x":
			tip.rotation_degrees.z = -90.0
		elif axis == "z":
			tip.rotation_degrees.x = 90.0
		add_child(tip)

	# Rotation remains keyboard-authored, but the ring makes that affordance
	# visible beside the translation axes instead of hiding it in HUD prose.
	var ring := MeshInstance3D.new()
	ring.name = "TurnRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.66
	torus.outer_radius = 0.69
	torus.rings = 40
	torus.ring_segments = 5
	ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(1.0, 0.75, 0.18, 0.82)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.55, 0.08)
	ring_mat.emission_energy_multiplier = 1.25
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.no_depth_test = true
	ring.material_override = ring_mat
	ring.position.y = 0.025
	add_child(ring)


func place(world_position: Vector3, camera: Camera3D, allow_y: bool = true) -> void:
	if get_child_count() == 0:
		_build()
	global_position = world_position
	_allow_y = allow_y
	var y_bar := get_node_or_null("YAxis") as MeshInstance3D
	var y_tip := get_node_or_null("YTip") as MeshInstance3D
	if y_bar != null:
		y_bar.visible = allow_y
	if y_tip != null:
		y_tip.visible = allow_y
	visible = true
	update_for_camera(camera)


func update_for_camera(camera: Camera3D) -> void:
	if camera == null:
		return
	var apparent_scale: float
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		apparent_scale = clampf(camera.size * 0.105, 0.28, 6.0)
	else:
		apparent_scale = clampf(camera.global_position.distance_to(global_position) * 0.105, 0.28, 6.0)
	scale = Vector3.ONE * apparent_scale


func hit_axis(camera: Camera3D, mouse: Vector2, threshold_px: float = 14.0) -> String:
	if not visible or camera == null or camera.is_position_behind(global_position):
		return ""
	var origin_screen := camera.unproject_position(global_position)
	var best_axis := ""
	var best_distance := threshold_px
	for axis in AXES:
		if axis == "y" and not _allow_y:
			continue
		var endpoint := global_position + (AXIS_VECTORS[axis] as Vector3) * scale.x * 1.18
		if camera.is_position_behind(endpoint):
			continue
		var endpoint_screen := camera.unproject_position(endpoint)
		var distance := _point_segment_distance(mouse, origin_screen, endpoint_screen)
		if distance < best_distance:
			best_distance = distance
			best_axis = axis
	return best_axis


func screen_axis(camera: Camera3D, axis: String) -> Vector2:
	if camera == null or not AXIS_VECTORS.has(axis):
		return Vector2.ZERO
	var a := camera.unproject_position(global_position)
	# One WORLD metre, independent of how large the always-readable drawing is.
	# The caller can therefore turn pixels back into a persisted metre delta.
	var endpoint := global_position + (AXIS_VECTORS[axis] as Vector3)
	if camera.is_position_behind(endpoint):
		return Vector2.ZERO
	return camera.unproject_position(endpoint) - a


func set_hot_axis(hot: String) -> void:
	for axis in AXES:
		var mat := _materials.get(axis) as StandardMaterial3D
		if mat == null:
			continue
		var base: Color = AXIS_COLORS[axis]
		mat.albedo_color = Color.WHITE if axis == hot else base
		mat.emission = Color.WHITE if axis == hot else base
		mat.emission_energy_multiplier = 3.2 if axis == hot else 1.8


static func _point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	if denom < 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / denom, 0.0, 1.0)
	return point.distance_to(a + ab * t)
