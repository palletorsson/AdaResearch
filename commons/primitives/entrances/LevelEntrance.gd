extends Node3D

signal entrance_activated(label_text: String)

@export var width_m: float = 1.0
@export var height_m: float = 3.0
@export var depth_m: float = 1.0

@export var frame_height_m: float = 2.0
@export var frame_width_m: float = 0.8

@export var label_text: String = "Level"
@export var yaw_degrees: float = 0.0

@onready var wall_mesh: MeshInstance3D = $StaticBody3D/Wall
@onready var plate_mesh: MeshInstance3D = $Plate
@onready var label3d: Label3D = $Label3D
@onready var frame_left: MeshInstance3D = $Frame/Left
@onready var frame_right: MeshInstance3D = $Frame/Right
@onready var frame_top: MeshInstance3D = $Frame/Top

func _ready():
	_apply_dimensions()
	_apply_label_and_rotation()
	_wire_trigger()

func _apply_dimensions():
	# Wall (full tile)
	var wall_box := wall_mesh.mesh as BoxMesh
	if wall_box:
		wall_box.size = Vector3(width_m, height_m, depth_m)
	position.y = height_m * 0.5

	# Frame parts
	var left_box := frame_left.mesh as BoxMesh
	if left_box:
		left_box.size = Vector3(0.05, frame_height_m, 0.1)
	frame_left.position = Vector3(-frame_width_m * 0.5, frame_height_m * 0.5, 0.45)

	var right_box := frame_right.mesh as BoxMesh
	if right_box:
		right_box.size = Vector3(0.05, frame_height_m, 0.1)
	frame_right.position = Vector3(frame_width_m * 0.5, frame_height_m * 0.5, 0.45)

	var top_box := frame_top.mesh as BoxMesh
	if top_box:
		top_box.size = Vector3(frame_width_m, 0.05, 0.1)
	frame_top.position = Vector3(0.0, frame_height_m + 0.05, 0.45)

	# Plate above door
	var plate_box := plate_mesh.mesh as BoxMesh
	if plate_box:
		plate_box.size = Vector3(min(frame_width_m + 0.1, 0.9), 0.15, 0.05)
	plate_mesh.position = Vector3(0.0, frame_height_m + 0.35, 0.45)

func _apply_label_and_rotation():
	label3d.text = label_text
	var rot = rotation_degrees
	rot.y = yaw_degrees
	rotation_degrees = rot

func _wire_trigger():
	var area: Area3D = $TriggerArea
	if area:
		area.body_entered.connect(_on_body_entered)

func _on_body_entered(_body):
	entrance_activated.emit(label_text)
