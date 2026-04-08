class_name ArtifactScenePresenter
extends RefCounted

## Standard presentation wrapper for standalone artifact scenes.
## Adds a 1m cube frame and fits the simulation root inside it.

const CUBE_FRAME_SCENE := preload("res://commons/primitives/line/cube_lines.tscn")
const _Framer := preload("res://commons/testing/perfect_shot_framer.gd")

const FRAME_NAME := "ArtifactCubeFrame"
const FRAME_CENTER := Vector3(0.0, 0.5, 0.0)
const CONTENT_TARGET_SIZE := 0.82
const FRAME_LINE_WIDTH := 0.005
const FRAME_COLOR := Color(0.22, 0.9, 1.0, 0.72)

static func present(host: Node3D, sim_root: Node3D) -> void:
	if host == null or sim_root == null:
		return

	_ensure_frame(host)
	_fit_sim_root(sim_root)

static func _ensure_frame(host: Node3D) -> void:
	var existing := host.get_node_or_null(FRAME_NAME)
	if existing is Node3D:
		return

	var frame := CUBE_FRAME_SCENE.instantiate() as Node3D
	if frame == null:
		return

	frame.name = FRAME_NAME
	frame.position = FRAME_CENTER
	host.add_child(frame)

	var frame_label := frame.get_node_or_null("Label3D") as Label3D
	if frame_label:
		frame_label.visible = false

	var frame_camera := frame.get_node_or_null("Camera3D")
	if frame_camera:
		frame_camera.queue_free()

	for i in range(1, 13):
		var line_node := frame.get_node_or_null("Line%d/lineContainer" % i)
		if line_node and line_node.has_method("set_line_properties"):
			line_node.call("set_line_properties", FRAME_LINE_WIDTH, FRAME_COLOR)

static func _fit_sim_root(sim_root: Node3D) -> void:
	var aabb := _Framer.get_combined_aabb(sim_root)
	if aabb.size.length() < 0.001:
		return

	var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dim < 0.001:
		return

	var fit_scale := CONTENT_TARGET_SIZE / max_dim
	fit_scale = clampf(fit_scale, 0.35, 3.0)
	sim_root.scale = Vector3.ONE * fit_scale

	var fitted_aabb := _Framer.get_combined_aabb(sim_root)
	if fitted_aabb.size.length() < 0.001:
		return

	var offset := FRAME_CENTER - fitted_aabb.get_center()
	sim_root.position += offset
