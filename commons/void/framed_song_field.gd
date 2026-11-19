extends "res://commons/void/song_field.gd"
## A listening place aimed at an actual work, including after a floor rebuild.
const Frame := preload("res://commons/void/opera_view_frame.gd")
const SETTLE_SECONDS := 0.25
var frame := Frame.new()
var floor_root: Node3D
var target_path: NodePath
var target_offset: Vector3
var focus_seconds := 0.0
var authored: Dictionary = {}

func configure_frame(host: Node3D, spec: Dictionary) -> void:
	floor_root = host
	target_path = NodePath(spec.get("target", ""))
	var aim: Array = spec.get("aim", [0,0,0])
	target_offset = Vector3(aim[0], aim[1], aim[2])
	frame.name = "OperaFrame"
	frame.caption = spec.title
	frame.aperture = Vector2(spec.width, spec.height) / 2.0
	if spec.has("position"):
		authored = spec
	else:
		frame.position = Vector3(spec.offset[0], spec.offset[1], spec.offset[2])

func _build_indicator() -> void:
	frame.hide()
	add_child(frame)
	if not authored.is_empty(): frame.apply_floor_pose(floor_root, authored)

func _physics_process(_delta: float) -> void:
	var aligned := false
	# Acquire the work as it streams in, even during the voice's opening silence.
	var target := floor_root.get_node_or_null(target_path) as Node3D if not target_path.is_empty() else null
	frame.visible = target != null or (target_path.is_empty() and not authored.is_empty())
	if frame.is_visible_in_tree():
		var aim := target.to_global(target_offset) if target != null else frame.to_global(Vector3.FORWARD * 0.1)
		if authored.is_empty() and Vector2(aim.x-frame.global_position.x, aim.z-frame.global_position.z).length_squared() > 0.0001:
			frame.look_at(aim)
		aligned = frame.sees(get_viewport().get_camera_3d(), aim, target)
	frame.illuminate(aligned)

func update_presence(_feet: Vector3, delta: float, allowed: bool) -> void:
	enabled = allowed
	if frame.lit and is_visible_in_tree():
		focus_seconds += delta
		outside_seconds = 0.0
	else:
		focus_seconds = 0.0
		outside_seconds += delta
		if outside_seconds >= REARM_SECONDS: consumed = false
	inside = focus_seconds >= SETTLE_SECONDS

func show_state(_available: bool, _playing: bool) -> void:
	# The pink corners acknowledge the sightline even before the action is earned.
	pass
