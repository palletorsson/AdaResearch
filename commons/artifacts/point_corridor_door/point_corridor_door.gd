extends Node3D
## A threshold for the point corridor. Opens once on approach from either side.
## Reuses the museum sliding-door meshes; moves existing leaves and colliders
## together, without rebuilding geometry or closing on a returning visitor.
const DoorVisual := preload("res://commons/artifacts/sliding_door/sliding_door.gd")
const WIDTH := 4.0
const HEIGHT := 2.7
const OPEN_SECONDS := 1.2
const APPROACH := 3.0
var visual: Node3D
var opening := false
var progress := 0.0
var _closed_x: Array[float] = []

func _ready() -> void:
	set_meta("em_opens_on_approach", true)
	add_to_group("museum_approach_doors")
	visual = DoorVisual.new()
	visual.name = "Door"
	visual.door_width = WIDTH
	visual.door_height = HEIGHT
	visual.frame_color = Color(0.22,0.21,0.22)
	visual.panel_color = Color(0.91,0.90,0.86)
	visual.accent_color = Color(0.26,0.25,0.26)
	add_child(visual)
	for leaf: Node3D in [visual._panel_left,visual._panel_right]:
		_closed_x.append(leaf.position.x)
		var body := StaticBody3D.new()
		body.name = "LeafCollision"
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3((WIDTH-visual.gap_width)*0.5,HEIGHT,0.08)
		shape.shape = box
		body.add_child(shape)
		leaf.add_child(body)
	for part: MeshInstance3D in visual.get_node("Frame").get_children():
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = (part.mesh as BoxMesh).size
		shape.shape = box
		body.add_child(shape)
		part.add_child(body)
	for side in [-1.0,1.0]:
		var label := Label3D.new()
		label.text = "Point one"
		label.position = Vector3(0,HEIGHT+0.25,side*0.1)
		label.rotation.y = PI if side<0 else 0.0
		label.font_size = 64
		label.pixel_size = 0.0022
		label.modulate = Color(0.93,0.92,0.88)
		label.outline_size = 0
		add_child(label)

func _physics_process(delta: float) -> void:
	if not opening:
		var eye := get_viewport().get_camera_3d()
		if eye != null:
			var local_eye := to_local(eye.global_position)
			opening = absf(local_eye.x)<WIDTH*0.5 and absf(local_eye.z)<APPROACH and local_eye.y>0.15 and local_eye.y<HEIGHT+0.6
	if not opening:return
	progress = minf(1.0,progress+delta/OPEN_SECONDS)
	var amount := smoothstep(0.0,1.0,progress)
	var travel: float = (WIDTH-visual.gap_width)*0.5
	visual._panel_left.position.x = _closed_x[0]-amount*travel
	visual._panel_right.position.x = _closed_x[1]+amount*travel
	visual.panels_open_amount = amount
	if progress>=1.0:set_physics_process(false)

func museum_passage_bodies() -> Array[CollisionObject3D]:
	# Arrival validation may allow the moving leaves on the approach path,
	# while retaining the fixed frame and every other collision check.
	var bodies: Array[CollisionObject3D] = []
	if visual == null: return bodies
	for leaf: Node3D in [visual._panel_left,visual._panel_right]:
		bodies.append(leaf.get_node("LeafCollision") as CollisionObject3D)
	return bodies
